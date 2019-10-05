using StanInterface, Test, Statistics, Suppressor, Random, Distributions

@testset "run cmdstan bernoulli example" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(dirname(pathof(StanInterface)), "..", "deps", "cmdstan-2.20.0", 
                          "examples", "bernoulli", "bernoulli.stan")
                         
    sf = @suppress stan(model_path, data)
    @test sf isa Stanfit
end

@testset "build stan binary" begin
    model_path = joinpath(dirname(@__DIR__), "deps", "cmdstan-2.20.0", "examples", 
                          "bernoulli", "bernoulli.stan")
    binary_path = joinpath(tempdir(), "bernoulli")
    
    rm(binary_path, force = true)
    @test !isfile(binary_path)
    @suppress build_binary(model_path, binary_path)
    @test isfile(binary_path)
end

include("r_hat.jl")
include("n_eff.jl")