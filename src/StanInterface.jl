module StanInterface

export stan, extract, build_binary, Stanfit, R_hat, N_eff

using DelimitedFiles, Distributed, Test, Suppressor, Statistics, StatsBase, Mmap, CSV

include("StanIO.jl")

CMDSTAN_PATH = ENV["JULIA_CMDSTAN_HOME"]

struct Stanfit
    model::String
    data::Dict{String, Any}
    iter::Int
    chains::Int
    result::Array{Dict{String, Any}}
    diagnostics::String	
end

"""
```
    build_binary(model, path)

Build a stan executable binary from a .stan file.
```
"""
function build_binary(model::AbstractString, path::AbstractString)
    temppath = tempname()
    cp(model, temppath * ".stan")

    try        
        cd(() -> run(`make $temppath`), CMDSTAN_PATH)
        cp(temppath, expanduser(path), force = true)

        rm.(temppath .* [".hpp", ".stan"], force = true)
    finally
        rm.(temppath .* [".hpp", ".stan"], force = true)
    end
end

function build_binary(model::AbstractString)
    build_binary(model, splitext(model)[1])
end

function parse_stan_csv(stan_csv::AbstractString)
    @assert isfile(stan_csv)

    parameters = String[]
    n_samples = -1 # offset 1 additional parameter line
    mmap_file = splitext(stan_csv)[1] * "_mem.bin"
    
    try
        open(mmap_file, "w+") do io
            for line in readlines(stan_csv)
                startswith(line, '#') && continue
                n_samples += 1
                
                if startswith(line, "lp__")
                    parameters = split(line, ',')
                else
                    # Mmaped elements are written in column-major order!
                    write(io, parse.(Float64, split(line, ',')))
                end
            end
        end
 
        sample_dict = Dict{String, SubArray}()
        M = Mmap.mmap(mmap_file, Matrix{Float64}, (length(parameters), n_samples)) |>
            permutedims # transpose M as it was initially written in column-major order

        for i = 1:size(M, 2)
            sample_dict[parameters[i]] = @view M[:,i]
        end

        return sample_dict
    finally
        rm(splitext(stan_csv)[1] * "_mem.bin", force = true)
    end
end

function parse_stan_options(stan_csv::AbstractString)
    @assert isfile(stan_csv)
    s = ""

    open(stan_csv) do io
        for line in eachline(io)
            startswith(line, '#') || continue
            s = s * line * "\n"
        end
    end

    return s
end

function combine_stan_csv(outputfile::AbstractString, 
                          stan_csv_files::AbstractVector{T}) where T <: AbstractString
    stan_csv_1 = stan_csv_files[1]
    run(pipeline(`grep lp__ $stan_csv_1`, stdout = outputfile))
    run(pipeline(`sed '/^[#l]/d' $stan_csv_files`, stdout = outputfile, append = true))
end

function combine_stan_csv(outputfile::AbstractString, stan_csv_file::AbstractString)
    run(pipeline(`grep lp__ $stan_csv_file`, stdout = outputfile))
    run(pipeline(`sed '/^[#l]/d' $stan_csv_file`, stdout = outputfile, append = true)) 
end

"""
    stan(model, data::Dict; <keyword arguments>)

Run a stan model (.stan file or executable) located at `model` 
with the data present at 'data'.

# Arguments
- `model::AbstractString`: path leading to a .stan file or stan executable.
- `data::Dict{String, T} where T`: dictionary containing data for the stan model.
- `ìter::Int=2000`: number of sampling iterations.
- `chains::Int=4`: number of seperate chains, each with `iter` sampling iterations.
- `wp::WorkerPool`: WorkerPool containing a vector of workers for parallel MCMC runs.
- `stan_args::AbstractString`: arguments passed to the CmdStan Interface, see Details.
- `save_binary::AbstractString=""`: save the compiled stan binary.
- `save_data::AbstractString=""`: save the input data in .Rdump format.
- `save_result::AbstractString=""`: save stan results in .csv format, chains are merged.
- `save_diagnostics::AbstractString=""`: save eventual sampling problems (e.g. low R̂).

# Examples
```julia-repl
julia> stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]))
StanInterface.Stanfit

julia> stan("bernoulli_binary", Dict("N" => 5, "y" => [1,1,1,1,1]),
            iter = 20000, chains = 10)
StanInterface.Stanfit

julia> stan("bernoulli_binary", Dict("N" => 5, "y" => [1,1,1,1,1]), 
            stan_args = "adapt delta=0.9")
StanInterface.Stanfit
```

```
"""
function stan(model::AbstractString, data::Dict; iter::Int = 2000, chains::Int = 4,
              warmup::Int = 1000, ntasks = chains, 
              nthreads::Int = -1, 
              refresh::Int = 100,  seed::Int = rand(1:9999999),
			  wp::AbstractWorkerPool = default_worker_pool(),
              stan_args::AbstractString = "", save_binary::AbstractString = "",
              save_data::AbstractString = "", save_result::AbstractString = "",
              save_diagnostics::AbstractString = "")

    io = StanIO(model, data, chains, save_binary, save_data, save_result, save_diagnostics)
    setupfiles(io)

    try
        function launch_stan(i::Int)
	        @assert isfile(io.binary_file)
            @assert isfile(io.data_file)

            run(`env STAN_NUM_THREADS=$nthreads $(io.binary_file)
                sample num_samples=$iter $(split(stan_args)) 
                num_warmup=$warmup
                data file=$(io.data_file) random seed=$(seed) 
                output refresh=$refresh file=$(io.result_file[i]) 
                id=$i`, wait = true)
        end
        
		if length(wp) == 0
        	asyncmap(launch_stan, 1:chains, ntasks = ntasks)
		else
			pmap(launch_stan, wp, 1:chains)
		end

        result = parse_stan_csv.(io.result_file)

        diagnose_binary = joinpath(CMDSTAN_PATH, "bin/diagnose")
        diagnose_output = read(`$diagnose_binary $(io.result_file)`, String)
        
        diagnostics = ""
        for file in io.result_file
            diagnostics = diagnostics * parse_stan_options(file)
        end
        diagnostics = diagnostics * diagnose_output

        copyfiles(io)

        sf = Stanfit(model, data, iter, chains, result, diagnostics)
        removefiles(io) 
        
        return sf
    finally
        removefiles(io)
    end
end

"""
    stan(model, data::Dict, method::AbstractString; <keyword arguments>)

Provide access to Stan's optimization and approximate sampling interface.

`method` is one of `"sample"`, `"optimize"` or `"variational"`.
Additional command-line arguments can be supplied via the `stan_args` argument.

# Examples

#```julia-repl
#julia> stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]), "optimize",
#            stan_args = "algorithm=newton")
#StanInterface.Stanfit
#```
#"""
function stan(model::AbstractString, data::Dict, method::AbstractString;
              seed::Int = rand(1:9999999),
              stan_args::AbstractString = "", save_binary::AbstractString = "",
              save_data::AbstractString = "", save_result::AbstractString = "",
              save_diagnostics::AbstractString = "")
   
   io = StanIO(model, data, 1, save_binary, save_data, save_result, save_diagnostics)
   
   setupfiles(io)

   try
       run(`chmod +x $(io.binary_file)`)
       run(`$(io.binary_file) $method $(split(stan_args)) random seed=$(seed) 
           data file=$(io.data_file) output file=$(io.result_file)`)

       diagnose_output = ""
       result = parse_stan_csv.(io.result_file)

       copyfiles(io)
       sf = Stanfit(model, data, 0, 0, result, diagnose_output)
       removefiles(io)

       return sf
    
   finally
       removefiles(io)
   end
end


"""
    extract(::Stanfit)

Extract the results from a Stanfit object.

# Examples

```julia-repl
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]))
StanInterface.Stanfit

julia> extract(sf)
Dict{String,Array{Float64,1}} with 8 entries:
  "treedepth__"   => [2.0, 2.0, 2.0, 1.0, 1.0, 1.0, 2.0, 2.0,…
  "n_leapfrog__"  => [3.0, 3.0, 3.0, 3.0, 3.0, 1.0, 3.0, 3.0,…
  "theta"         => [0.728654, 0.564211, 0.777617, 0.393488,…
  "energy__"      => [5.17937, 5.13451, 5.59839, 6.70578, 5.6…
  "lp__"          => [-5.17931, -4.7811, -5.51614, -5.23091, …
  "accept_stat__" => [0.980242, 1.0, 0.890734, 0.890749, 0.94…
  "divergent__"   => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,…
  "stepsize__"    => [0.93671, 0.93671, 0.93671, 0.93671, 0.9…
```
"""
function extract(sf::Stanfit)
    d = merge(vcat, sf.result...)
end

"""
    extract(::Stanfit, pars::AbstractVector{T}) where T <: AbstractString

Restrict extracted results to a subset of parameters.

# Examples

```julia-repl
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]))
StanInterface.Stanfit

julia> extract(sf, ["lp__", "theta])
Dict{String,Array{Float64,1}} with 2 entries:
  "lp__"          => [-5.17931, -4.7811, -5.51614, -5.23091, …
  "theta"         => [0.728654, 0.564211, 0.777617, 0.393488,…
```
"""
function extract(sf::Stanfit, pars::AbstractVector{T}) where T <: AbstractString
    d = merge(vcat, filter.((k,v) -> k in pars, sf.result)...)
    return d
end

include("r_hat.jl")
include("n_eff.jl")
end # module
