using BinDeps

@BinDeps.setup

cmdstan_src = joinpath(@__DIR__, "downloads", "cmdstan-2.21.0.tar.gz")
cmdstan_dir = joinpath(@__DIR__, "cmdstan-2.21.0")

if Sys.isunix()
    install_cmdstan = @build_steps begin
        FileUnpacker(cmdstan_src, @__DIR__, "")
        @build_steps begin
            ChangeDirectory(cmdstan_dir)

            FileRule(joinpath(cmdstan_dir, "bin", "stanc"), @build_steps begin
                `echo "CXXFLAGS += -DSTAN_THREADS" > make/local`
                `make build`
            end)
        end
    end

    run(install_cmdstan)
end