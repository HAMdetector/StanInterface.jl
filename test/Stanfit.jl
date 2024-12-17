@testset "build stan binary" begin
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")
    binary_path = joinpath(tempdir(), "bernoulli")

    rm(binary_path, force = true)
    @test !isfile(binary_path)
    @suppress build_binary(model_path, binary_path)
    @test isfile(binary_path)
    rm(binary_path, force = true)
end

@testset "run cmdstan bernoulli example" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data)
    @test sf isa Stanfit

    sf = @suppress stan(model_path, data, chains = 1)
    @test sf isa Stanfit
end

@testset "run cmdstan optimizer" begin
    data = Dict("N" => 5, "y" => [0, 0, 1, 1, 1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data, method = "optimize")
    @test sf isa Stanfit
end

@testset "stan(; suppress = true)" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    output = @capture_out begin
        sf = stan(model_path, data)
    end

    @test output != ""

    output = @capture_out begin
        sf = stan(model_path, data, suppress = true)
    end

    @test output == ""
end

@testset "pass multidimensional array data" begin
    data = Dict(
        "X_1" => rand(2, 3),
        "X_2" => rand(2, 3),
        "X_3" => rand(2, 3, 4),
        "y" => [1, 2, 3]
    )

    sf = @suppress stan(joinpath(@__DIR__, "data", "multidimensional_inputs.stan"), data)
    res = extract(sf)

    @test round(data["X_1"][2, 3], digits = 6) == round(res["X_1_.2.3"][1], digits = 6)
    @test round(data["X_2"][2, 3], digits = 6) == round(res["X_2_.2.3"][1], digits = 6)
    @test round(data["X_3"][1, 2, 3], digits = 6) == round(res["X_3_.1.2.3"][1], digits = 6)
end

@testset "stan_model(::Stanfit)" begin
    data = Dict("N" => 5, "y" => [1, 1, 1, 1, 1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data)

    @test stan_model(sf) == read(model_path, String)
end

@testset "data(::Stanfit)" begin
    data = Dict("N" => 5, "y" => [1, 1, 1, 1, 1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data)

    @test stan_data(sf) == data
end

@testset "diagnose(::Stanfit)" begin
    data = Dict("N" => 5, "y" => [1, 1, 1, 1, 1])
    model_path = joinpath(StanInterface.cmdstan_path(),
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data)
    @capture_out @test isnothing(diagnose(sf))
end
