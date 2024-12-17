# between-chain variance
function B_variance(x)
    chain_means = [mean(chain) for chain in x]
    mean_chain_means = mean(chain_means)

    N = length(x[1])
    M = length(x)

    return (N / (M - 1)) * sum((m - mean_chain_means)^2 for m in chain_means)
end

# within-chain variance
function W_variance(x)
    return mean(var(chain) for chain in x)
end

function R_hat(x)
    split_chains = Vector{Vector{Float64}}()

    for (i, chain) in enumerate(x)
        half_N = floor(Int, length(chain) / 2)

        push!(split_chains, chain[1:half_N])
        push!(split_chains, chain[(half_N + 1):end])
    end

    N = length(split_chains[1])
    W = W_variance(split_chains)
    B = B_variance(split_chains)

    variance_estimator = ((N - 1) / N) * W + (B / N)

    return sqrt(variance_estimator / W)
end

function R_hat(sf::Stanfit)
    f = x -> Dict((string(p[1]), collect(skipmissing(p[2]))) for p in pairs(x))
    res = [CSV.read(codeunits(x), comment = "#", f) for x in sf.results]

    parameters = collect(keys(res[1]))

    excluded_parameters = [
        "stepsize__", "treedepth__", "n_leapfrog__", "energy__", "accept_stat__",
        "divergent__"
    ]

    filter!(x -> x ∉ excluded_parameters, parameters)
    d = Dict{String, Float64}()

    if fixed_param_(sf)
        for p in parameters
            d[p] = Inf
        end
    else
        for p in parameters
            v = [r[p] for r in res]
            d[p] = R_hat(v)
        end
    end

    return d
end
