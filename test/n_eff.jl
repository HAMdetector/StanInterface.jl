@testset "N_eff(::AbstractVector{AbstractVector{<: Real}})" begin
    rng = StableRNG(1234)

    x = Vector{Vector{Float64}}()
    for c in 1:4
        push!(x, Float64[])
        for i in 1:100
            push!(x[c], rand(rng, Normal(0.01 * i, 1)))
        end
    end

    @test N_eff(x) ≈ 204.53432331826636
end

@testset "N_eff(::Stanfit)" begin
    data = Dict("N" => 5, "y" => [1,1,1,1,1])
    model_path = joinpath(StanInterface.cmdstan_path(), 
        "examples", "bernoulli", "bernoulli.stan")

    sf = @suppress stan(model_path, data)

    n_eff = N_eff(sf)
    @test n_eff isa Dict{String, Float64}
    @test length(n_eff) == 2
end
