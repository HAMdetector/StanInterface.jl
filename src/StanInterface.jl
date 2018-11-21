module StanInterface

using DelimitedFiles, Distributed

include("StanIO.jl")

export stan, extract, build_binary, Stanfit
cmdstan_path = joinpath(dirname(pathof(StanInterface)), "..", "deps", "cmdstan-2.17.1")

struct Stanfit
    model::String
    data::Dict{String, Any}
    iter::Int
    chains::Int
    result::Array{Dict{String, Vector{Float64}}}
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
    cwd = pwd()

    try
        cd(cmdstan_path)
        run(`make $temppath`)
        cp(temppath, expanduser(path), force = true)
    finally
        rm.(temppath .* [".hpp", ".stan"])
        cd(cwd)
    end
end

function parse_stan_csv(stan_csv::AbstractString)
    isfile(stan_csv) || error("parse_stan_csv error")
    samples, parameters = readdlm(expanduser(stan_csv), ',', header = true, comments = true)
    
    sample_dict = Dict{String, Array{Float64, 1}}()
    for i = 1:size(samples,2)
        sample_dict[parameters[i]] = samples[:,i]
    end

    return sample_dict
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
- `processes::Int=length(workers())`: number of parallel processes used for MCMC sampling.
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
              processes::Int = length(workers()), refresh::Int = 100,
              stan_args::AbstractString = "", save_binary::AbstractString = "",
              save_data::AbstractString = "", save_result::AbstractString = "",
              save_diagnostics::AbstractString = "")
    @assert processes <= length(workers())

    io = StanIO(model, data, chains, save_binary, save_data, save_result, save_diagnostics)
    setupfiles(io)

    try
        function run_stan(i::Int)
	    if !isfile(io.binary_file)
		error("binary file not found")
	    end
	    if !isfile(io.data_file)
		error("data file not found")
	    end

            run(`chmod +x $(io.binary_file)`)
            run(`$(io.binary_file) sample num_samples=$iter $(split(stan_args)) 
                data file=$(io.data_file) random seed=$(rand(1:9999999)) 
                output refresh=$refresh file=$(io.result_file[i]) 
                id=$i`)
        end
        
        pmap(run_stan, WorkerPool(workers()), 1:chains)
        
        while !all(isfile.(io.result_file))
            @warn "$(io.result_file) not yet created"
            sleep(1)
        end

        result = parse_stan_csv.(io.result_file)

        diagnose_binary = joinpath(cmdstan_path, "bin/diagnose")
        diagnose_output = read(`$diagnose_binary $(io.result_file)`, String)
    
        copyfiles(io)

        sf = Stanfit(model, data, iter, chains, result, diagnose_output)
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
#function stan(model::AbstractString, data::Dict, method::AbstractString;
#              stan_args::AbstractString = "", save_binary::AbstractString = "",
#              save_data::AbstractString = "", save_result::AbstractString = "",
#              save_diagnostics::AbstractString = "")
#    
#    io = StanIO(model, data, 1, save_binary, save_data, save_result, save_diagnostics)
#    setupfiles(io)
#
#    try
#        run(`chmod +x $(io.binary_file)`)
#        run(`$(io.binary_file) $method $(split(stan_args))
#            data file=$(io.data_file) output file=$(io.result_file)`)
#
#        diagnose_binary = joinpath(cmdstan_path, "bin/diagnose")
#        diagnose_output = readstring(`$diagnose_binary $(io.result_file)`)
#        result = parse_stan_csv.(io.result_file)
#
#        copyfiles(io)
#        sf = Stanfit(model, data, )
#        return Stanfit(model, data, 0, 0, result, diagnose_output)
#        
#    finally
#        removefiles(io)
#    end
#end
#

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
    d = merge(vcat, filter.((k,v)->k in pars, sf.result)...)
    return d
end

end # module
