struct StanIO
    model::String
    data::Dict{String, Any}
    binary_file::String
    data_file::String
    result_file::String
end

function StanIO(
    model::String,
    data::Dict{String, <: Any},
    n_result_files::Int,
)

    result_file = tempname()
    binary_file = joinpath(tempdir(), string(hash(read(model, String)), base = 62))
    data_file = tempname() * ".json"

    StanIO(cleanpath(model), data, binary_file, data_file, result_file)
end

function cleanpath(path::AbstractString)
    path != "" && return path |> expanduser |> normpath |> abspath

    return path
end

function setupfiles(io::StanIO)
    if !isfile(io.binary_file)
        build_binary(io.model, io.binary_file)
    end

    save_json(io.data_file, io.data)
end

function copyfiles(io::StanIO)
    if io.save_result != ""
        combine_stan_csv(io.save_result, io.result_file)
    end

    if io.save_diagnostics != ""
        cp(io.diagnostics_file, io.save_diagnostics)
    end
end

function removefiles(io::StanIO; cache_binary::Bool = true)
    rm(io.data_file, force = true)

    tmp_files = readdir(dirname(io.result_file), join = true)
    result_files = filter(x -> startswith(x, io.result_file), tmp_files)
    rm.(result_files, force = true)

    cache_binary || rm(io.binary_file, force = true)
end

function save_json(path::AbstractString, d::Dict{String, <: Any})
    rowmajor_d = Dict{String, Any}()

    for (k, v) in pairs(d)
        if v isa Array
            rowmajor_d[k] = permutedims(v, ndims(v):-1:1)
        else
            rowmajor_d[k] = v
        end
    end

    open(cleanpath(path), "w") do io
        write(io, JSON.json(rowmajor_d))
    end

    return nothing
end
