using BinDeps

@BinDeps.setup

cmdstan_src = joinpath(@__DIR__, "downloads", "cmdstan-2.17.1.tar.gz")
cmdstan_dir = joinpath(@__DIR__, "cmdstan-2.17.1")
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
