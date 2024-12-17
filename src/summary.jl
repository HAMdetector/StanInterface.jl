function Base.show(io::IO, sf::Stanfit)
    s = summary(sf)

    s[2:end, 2:end] .= round.(s[2:end, 2:end], digits = 2)

    hl_odd = Highlighter(
        f = (data, i, j) -> i % 2 == 0,
        crayon = Crayon(background = :dark_gray)
    )

    pretty_table(
        s[2:end, :],
        header = string.(s[1, :]),
        highlighters = hl_odd,
        tf = tf_borderless,
        crop = :none,
        alignment = :c
    )
end

function summary(sf::Stanfit)
    f = x -> Dict((string(p[1]), collect(skipmissing(p[2]))) for p in pairs(x))
    res = extract(sf, f)

    blacklist = [
        "treedepth__", "n_leapfrog__", "energy__", "accept_stat__", "divergent__",
        "stepsize__", "lp__"
    ]

    parameters = sort(filter(x -> !(x in blacklist), collect(keys(res))))

    data_summaries = (
        mean = mean, median = median, sd = std, mad = x -> median(abs.(x .- median(x))),
        q5 = x -> quantile(x, 0.05), q95 = x -> quantile(x, 0.95),
    )

    m = Matrix{Any}(undef, length(parameters) + 1, length(data_summaries) + 1)

    m[1, :] .= [""; string.(keys(data_summaries))...]

    for (i, p) in enumerate(parameters)
        m[i + 1, 1] = string(p)
        m[i + 1, 2:end] .= map(x -> x(res[p]), values(data_summaries))
    end

    return m
end

# Given a vector of posterior draws, return the corresponding value of R_hat
function r_hat_(r_hats::Dict, res, x)
    pairs = collect(res)
    idx = findfirst(pair -> pair[2] == x, pairs)

    pairs[idx][1] in keys(r_hats) || return missing
    r_hat = r_hats[pairs[idx][1]]

    return r_hat
end

# Given a vector of posterior draws, return the corresponding value of N_eff
function n_eff_(n_effs::Dict, res, x)
    pairs = collect(res)
    idx = findfirst(pair -> pair[2] == x, pairs)

    pairs[idx][1] in keys(n_effs) || return missing
    n_eff = n_effs[pairs[idx][1]]

    return n_eff
end

# Return true when Stan is run without any sampling parameters.
function fixed_param_(sf)
    f = x -> Dict((string(p[1]), p[2]) for p in pairs(x))
    res = [CSV.read(codeunits(x), comment = "#", f) for x in sf.results]

    if all(.!isempty.(res))
        return false
    else
        return true
    end
end
