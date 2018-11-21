using StanInterface, Test, Distributed, SharedArrays
addprocs(10)
@everywhere using StanInterface

@testset "run cmdstan bernoulli example" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(dirname(pathof(StanInterface)), "..", "deps", "cmdstan-2.17.1", 
                          "examples", "bernoulli", "bernoulli.stan")
                         
    sf = stan(model_path, data)
    @test sf isa Stanfit
end

@testset "build stan binary" begin
    model_path = joinpath(dirname(@__DIR__), "deps", "cmdstan-2.17.1", "examples", 
                          "bernoulli", "bernoulli.stan")
    binary_path = joinpath(dirname(@__DIR__), "deps", "cmdstan-2.17.1", "examples",
                           "bernoulli", "bernoulli")
    
    rm(binary_path, force = true)
    @test !isfile(binary_path)
    build_binary(model_path, binary_path)
    @test isfile(binary_path)
end