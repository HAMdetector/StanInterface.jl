function N_eff(sf::Stanfit)
    f = x -> Dict((string(p[1]), collect(skipmissing(p[2]))) for p in pairs(x))
    res = [CSV.read(codeunits(x), comment = "#", f) for x in sf.results]

    parameters = collect(keys(res[1]))
    excluded_parameters = [
        "stepsize__", "treedepth__", "n_leapfrog__", "energy__", "accept_stat__",
        "divergent__"
    ]
    filter!(x -> !(x in excluded_parameters), parameters)
    d = Dict{String, Float64}()

    if fixed_param_(sf)
        for p in parameters
            d[p] = -Inf
        end
    else
        for p in parameters
            v = [r[p] for r in res]
            d[string(p)] = N_eff(v)
        end
    end

    return d
end

function N_eff(x::AbstractVector{T}) where T <: AbstractVector{<: Real}
    N = length(x[1])
    M = length(x)
    W = W_variance(x)
    B = B_variance(x)
    combined_variance = ((N - 1) / N) * W + (B / N)

    rho_hat(t) = 1 - (W - mean(autocov(m, [t - 1])[1] for m in x)) / combined_variance

    rho_sum = 0
    for t in 2:N
        rho = rho_hat(t)

        if rho < 0
            break
        end

        rho_sum = rho_sum + rho
    end

    N_eff = (N * M) / (1 + 2 * rho_sum)

    return N_eff
end
