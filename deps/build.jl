using BinDeps

@BinDeps.setup

cmdstan_src = joinpath(@__DIR__, "downloads", "cmdstan-2.19.1.tar.gz")
cmdstan_dir = joinpath(@__DIR__, "cmdstan-2.19.1")
cmdstan_mpi_dir = joinpath(dirname(cmdstan_dir), basename(cmdstan_dir) * "_mpi")

if Sys.isunix()
    install_cmdstan = @build_steps begin
        FileUnpacker(cmdstan_src, @__DIR__, "")
        @build_steps begin
            ChangeDirectory(cmdstan_dir)
            FileRule(joinpath(cmdstan_dir, "bin", "stanc"), @build_steps begin
                `make build`
            end)
        end
    end

    run(install_cmdstan)
end

# mpi_enabled = try success(`mpicxx -show`) 
#     true 
# catch 
#     false 
# end
mpi_enabled = true

if mpi_enabled
    if Sys.isunix()
        cp_mpi_dir = @build_steps begin
        BinDeps.DirectoryRule(cmdstan_mpi_dir, @build_steps begin
            `cp -r $cmdstan_dir $cmdstan_mpi_dir`
        end)
        @build_steps begin
            ChangeDirectory(cmdstan_mpi_dir)
            `rm -f make/local`
            ``
        end
    end

    clean_mpi_dir = @build_steps begin
        ChangeDirectory(cmdstan_mpi_dir)
        `make clean-all`
    end

    run(cp_mpi_dir)

    io = open(joinpath(cmdstan_mpi_dir, "make", "local"), "w")
    println(io, "STAN_MPI=true")
    println(io, "CXX=mpicxx")
    close(io)

    run(clean_mpi_dir)

    end
end