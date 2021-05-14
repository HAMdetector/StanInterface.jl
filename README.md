# Installation

1. Install [CmdStan](https://github.com/stan-dev/cmdstan/tags).
2. set the JULIA_CMDSTAN_HOME environment variable to point to the CmdStan root directory
    (= the directory containing the bin, lib, and make folder)

3. start julia
4. executing `ENV["JULIA_CMDSTAN_HOME"]` in the Julia REPL should show the correct
    path to the CmdStan root directory.
5. switch to Pkg mode (hotkey `]`) and `add https://github.com/HAMdetector/StanInterface.jl.git`.
6. hopefully `test StanInterface` in Pkg mode should run without any problems.