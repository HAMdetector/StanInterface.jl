using Distributions
using Random
using StableRNGs
using StanInterface
using Statistics
using Suppressor
using Test

@testset "StanInterface.jl" begin
    include("Stanfit.jl")
    include("r_hat.jl")
    include("n_eff.jl")
end
