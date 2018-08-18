using StanInterface, Test

@testset "run cmdstan bernoulli example" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(dirname(pathof(StanInterface)), "..", "deps", "cmdstan-2.17.1", 
                          "examples", "bernoulli", "bernoulli.stan")
                         
    sf = stan(normpath(model_path), data)
    @test isa(sf, StanInterface.Stanfit)
end
