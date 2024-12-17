module StanInterface

export stan, extract, build_binary, Stanfit, R_hat, N_eff, stan_model, stan_data, diagnose

using MicroMamba
using CSV
using JSON
using PrettyTables
using Scratch
using Statistics
using StatsBase

scratch_dir = ""

function __init__()
    global scratch_dir = @get_scratch!("scratch_dir")
end

function cmdstan_path()
    if isempty(readdir(scratch_dir))
        cmd = `create -y -p $(joinpath(scratch_dir, "cmdstan")) cmdstan -c conda-forge`
        run(MicroMamba.cmd(cmd))
    end

    path = joinpath(scratch_dir, "cmdstan", "bin", "cmdstan")

    return path
end

include("StanIO.jl")
include("Stanfit.jl")
include("r_hat.jl")
include("n_eff.jl")
include("summary.jl")

end # module
