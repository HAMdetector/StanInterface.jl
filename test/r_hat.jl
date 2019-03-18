@testset "B_variance(::AbstractVector{AbstractVector{<: Real}})" begin
    a = [1, 1, 1, 1, 0, 0, 0, 0, 1]
    b = [0, 1, 0, 1, 1, 1, 1, 1, 1]
    c = [0, 1, 1, 1, 1, 1, 1, 1, 1]
    d = [1, 0, 1, 0, 1, 0, 1, 0, 1]

    theta_m = mean([mean(a), mean(b), mean(c), mean(d)])
    B_expected = 9/3 * ((mean(a) - theta_m)^2 + (mean(b) - theta_m)^2 + 
                        (mean(c) - theta_m)^2 + (mean(d) - theta_m)^2)

    @test StanInterface.B_variance([a, b, c, d]) ≈ B_expected
end

@testset "W_variance(::AbstractVector{AbstractVector{<: Real}})" begin
    a = [1, 1, 1, 1, 0, 0, 0, 0, 1]
    b = [0, 1, 0, 1, 1, 1, 1, 1, 1]
    c = [0, 1, 1, 1, 1, 1, 1, 1, 1]
    d = [1, 0, 1, 0, 1, 0, 1, 0, 1]

    variances = [var(a), var(b), var(c), var(d)]
    W_expected = mean(variances)

    @test StanInterface.W_variance([a, b, c, d]) ≈ W_expected
end

@testset "R_hat(::AbstractVector{AbstractVector{<: Real}})" begin
    x = [[0.1, 0.2, 0.3, 0.4], [0.1, 0.2, 0.3, 0.4], [0.1, 0.2, 0.3, 0.4]]

    expected_R_hat = 1.7029386365926393
    @test StanInterface.R_hat(x) ≈ expected_R_hat
end

@testset "R_hat(::Stanfit)" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(dirname(pathof(StanInterface)), "..", "deps", "cmdstan-2.17.1", 
                          "examples", "bernoulli", "bernoulli.stan")
                         
    sf = @suppress stan(model_path, data)

    r_hats = R_hat(sf)
    @test r_hats isa Dict{String, Float64}
    @test length(r_hats) == 2
end