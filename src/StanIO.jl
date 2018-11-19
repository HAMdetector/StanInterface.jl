struct StanIO{T<:AbstractString, S<:AbstractVector}
    model::T
    data::Dict{T, R} where R <: Any
    binary_file::T
    data_file::T
    result_file::S
    diagnostics_file::T
    save_binary::T
    save_data::T
    save_result::T
    save_diagnostics::T
end

function StanIO(model::T, data::Dict{T, S} where S, n_result_files::Int, save_binary::T, 
                save_data::T, save_result::T, 
                save_diagnostics::T) where {T<:AbstractString}
        
    result_file = [tempname() for i = 1:n_result_files]
    binary_file, data_file, diagnostics_file = [tempname() for i = 1:3]

    StanIO(cleanpath(model), data, binary_file, data_file, result_file, 
           diagnostics_file, cleanpath(save_binary), cleanpath(save_data), 
           cleanpath(save_result), cleanpath(save_diagnostics))
end

function cleanpath(path::AbstractString)
    path != "" && return path |> expanduser |> normpath |> abspath
    return path
end

function setupfiles(io::StanIO)
    if splitext(io.model)[2] == ".stan"
        build_binary(io.model, io.binary_file)
    else
        cp(io.model, io.binary_file)
    end
    
    io.save_data != "" && save_rdump(io.save_data, io.data)
    io.save_data == "" && save_rdump(io.data_file, io.data)
end

function copyfiles(io::StanIO)
    io.save_result != "" && combine_stan_csv(io.save_result, io.result_file)
    io.save_diagnostics != "" && cp(io.diagnostics_file, io.save_diagnostics)
end

function removefiles(io::StanIO)
    rm(io.data_file, force = true)
    rm(io.binary_file, force = true)
    rm(io.diagnostics_file, force = true)
    rm.(io.result_file, force = true)
end
 
function save_rdump(path::AbstractString, d::Dict{String, T}) where T <: Any
    # isfile(path) && rm(path)
    strmout = open(expanduser(path), "w")
    str = ""
    for entry in d
        str = "\"" * entry[1] * "\" <- "
        val = entry[2]
        if length(val)==1 && length(size(val))==0
            # Scalar
            str = str*"$(val)\n"
         #elseif length(val)==1 && length(size(val))==1
            # Single element vector
            #str = str*"$(val[1])\n"
        elseif length(val)>=1 && length(size(val))==1
            # Vector
            str = str*"structure(c("
            write(strmout, str)
            str = ""
            writedlm(strmout, val', ',')
            str = str*"), .Dim=c($(length(val))))\n"
        elseif length(val)>1 && length(size(val))>1
            # Array
            str = str*"structure(c("
            write(strmout, str)
            str = ""
            writedlm(strmout, val[:]', ',')
            dimstr = "c"*string(size(val))
            str = str*"), .Dim=$(dimstr))\n"
        end
        write(strmout, str)
    end
  close(strmout)
end