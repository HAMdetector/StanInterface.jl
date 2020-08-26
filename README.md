# Installation

1. Install [CmdStan](https://github.com/stan-dev/cmdstan/tags).
2. set the JULIA_CMDSTAN_HOME environment variable to the CmdStan root directory
    (= the directory containing the bin, lib, and make folder)
3. clone the respository to a location you prefer:
    `git clone --depth 1 gogs@gogs.zmb.uni-due.de:habermann/StanInterface.jl.git StanInterface`

4. start julia
5. executing `ENV["JULIA_CMDSTAN_HOME"]` in the Julia REPL should show the correct
    path to the CmdStan root directory.
6. switch to Pkg mode (hotkey `]`) and `activate` the just cloned package.
7. run `instantiate` in Pkg mode to install the required dependencies.
8. hopefully `test` in Pkg mode should run without any problems.