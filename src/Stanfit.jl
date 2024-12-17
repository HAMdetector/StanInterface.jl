struct Stanfit
    model::String
    data::String
    results::Vector{String}
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
"""
function stan(
    model::AbstractString, data::Dict{String, <: Any};
    method::String = "sample",
    iter::Int = 2000,
    chains::Int = 4,
    warmup::Int = 1000,
    ntasks = chains,
    nthreads::Int = 4,
    refresh::Int = 100,
    seed::Int = -1,
    sig_figs::Int = -1,
    init = 2,
    stan_args::AbstractString = "",
    cache_binary::Bool = true,
    suppress::Bool = false
)
    stream = suppress ? devnull : stdout
    io = StanIO(model, data, chains)
    setupfiles(io)

    try
        stream = suppress ? devnull : stdout
        if method == "sample"
            run(pipeline(
                `$(io.binary_file)
                sample num_chains=$chains num_samples=$iter $(split(stan_args))
                num_warmup=$warmup
                data file=$(io.data_file) init=$init random seed=$(seed)
                output sig_figs=$sig_figs refresh=$refresh file=$(io.result_file)
                num_threads=$nthreads`, stdout = stream), wait = true
            )

            if chains == 1
                result_file = [io.result_file * ".csv"]
            else
                result_file = io.result_file .* '_' .* string.(1:chains) .* ".csv"
            end

            sf = Stanfit(
                read(model, String),
                string(data),
                read.(result_file, String),
            )
            removefiles(io; cache_binary = cache_binary)

            return sf
        end

        if method == "optimize"
            run(pipeline(
                `$(io.binary_file)
                optimize data file=$(io.data_file) init=$init random seed=$(seed)
                output sig_figs=$sig_figs refresh=$refresh file=$(io.result_file)`,
                stdout = stream),
                wait = true
            )

            sf = Stanfit(
                read(model, String),
                string(data),
                [read(io.result_file * ".csv", String)]
            )
            removefiles(io; cache_binary = cache_binary)

            return sf
        end
    finally
        removefiles(io)
    end
end

"""
    diagnose(::Stanfit)
"""
function diagnose(sf::Stanfit)
    result_files = [tempname() for res in sf.results]
    write.(result_files, sf.results)

    diagnose_path = joinpath(cmdstan_path(), "bin", "diagnose")
    diagnose_output = read(`$diagnose_path $result_files`, String)

    rm.(result_files, force = true)

    print(diagnose_output[findfirst('\n', diagnose_output) + 2:end])

    return nothing
end

"""
    build_binary(model, path)

Build a stan executable binary from a .stan file.
"""
function build_binary(model::AbstractString, path::AbstractString)
    temppath = tempname()
    cp(model, temppath * ".stan")

    try
        run(`$(joinpath(cmdstan_path(), "..", "cmdstan_model")) $temppath CXX=$(find_cxx_compiler()) STAN_THREADS=true`)
        cp(temppath, expanduser(path), force = true)
        rm.(temppath .* [".hpp", ".stan"], force = true)
    finally
        rm.(temppath .* [".hpp", ".stan"], force = true)
    end
end

function find_cxx_compiler()
    bin_path = abspath(joinpath(cmdstan_path(), ".."))
    executables = readdir(bin_path)

    if Sys.iswindows()
        cxx_compiler_idx = findfirst(x -> endswith(x, "g++.exe"), executables)
    else
        cxx_compiler_idx = findfirst(x -> endswith(x, "g++"), executables)
    end

    if isnothing(cxx_compiler_idx)
        error("no C++ compiler found, please check conda installation.")
    end

    cxx_compiler = joinpath(bin_path, executables[cxx_compiler_idx])

    return cxx_compiler
end

function build_binary(model::AbstractString)
    build_binary(model, splitext(model)[1])
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
function extract(
    sf::Stanfit,
    sink = x -> Dict((string(p[1]), collect(skipmissing(p[2]))) for p in pairs(x))
)
    res = CSV.read(codeunits.(sf.results), comment = "#", sink)
end

"""
    stan_model(::Stanfit)

Accessor function to retrieve the underlying Stan source code of a fitted model.

# Examples

```julia-repl
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]))
StanInterface.Stanfit

julia>stan_model(sf)
"data {\n  int<lower=0> N;\n  array[N] int<lower=0,upper=1> y; // or int<lower=0,upper=1> y[N];\n}\nparameters {\n  real<lower=0,upper=1> theta;\n}\nmodel {\n  theta ~ beta(1,1);  // uniform prior on interval 0,1\n  y ~ bernoulli(theta);\n}\n"
```
"""
function stan_model(sf::Stanfit)
    return sf.model
end

"""
    stan_data(::Stanfit)

Accessor function to retrieve the underlying data of a fitted Stan model.

# Examples

```julia-repl
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,1,1,1]))
StanInterface.Stanfit

julia>stan_data(sf)
Dict{String, Any} with 2 entries:
  "N" => 2
  "y" => [0, 1]
```
"""
function stan_data(sf::Stanfit)
    return eval(Meta.parse(sf.data))
end
