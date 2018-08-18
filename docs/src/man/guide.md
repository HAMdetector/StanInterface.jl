```@meta
CurrentModule = Jstan
```

# Package Guide

## Installation

Jstan can be installed via the `Pkg.clone`. Afterwards, `Pkg.build("Jstan")` is required to build the necessary dependencies.

```julia
Pkg.clone("gogs@132.252.170.166:DanielHa/Jstan.jl.git")
Pkg.build("Jstan")
```
If SSH access to the repository is unwanted (or no SSH key is setup), use:

```julia
Pkg.clone("http://132.252.170.166:8000/DanielHa/Jstan.jl.git")
Pkg.build("Jstan")
```

Though this requires typing in your Gogs credentials for each `Pkg.update`.

## Usage

# Minimal working example

Jstan is intended to be a simple wrapper for CmdStan that simplifies file handling.
To start, consider this simple bernoulli model with a single parameter `theta`:

```
data {
    int<lower=0> N;
    int<lower=0,upper=1> y[N];
}
parameters {
    real<lower=0,upper=1> theta;
}
model {
    theta ~ beta(1,1);
    y ~ bernoulli(theta);
}
```

To run a model, Jstan provides the `stan` function, which requires the path to the Stan model and a dictionary containg the data as input arguments. The input variables of the Stan model are provided as simple String keys to the dictionary:

```julia
julia> using Jstan

julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" = [0,0,0,1,1]))
```

This function call automatically compiles the .stan file and runs the model with the provided data. The `stan` function returns an object of type `::Stanfit`. To retrieve the MCMC results, call the function `extract` on the returned `::Stanfit` object. Results from different chains are merged:

```julia
julia> extract(sf)

Dict{String,Array{Float64,1}} with 8 entries:
  "treedepth__"   => [1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0  …  1.0,…
  "n_leapfrog__"  => [1.0, 3.0, 1.0, 1.0, 1.0, 3.0, 3.0, 3.0, 1.0, 3.0  …  3.0,…
  "theta"         => [0.458652, 0.48066, 0.721026, 0.605692, 0.40698, 0.40698, …
  "energy__"      => [5.22223, 4.8696, 7.05694, 6.90516, 5.23482, 5.39365, 4.36…
  "lp__"          => [-4.62739, -4.74118, -7.03734, -5.65588, -4.41062, -4.4106…
  "accept_stat__" => [1.0, 0.987203, 0.466092, 1.0, 1.0, 0.73413, 1.0, 0.983674…
  "divergent__"   => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  …  0.0,…
  "stepsize__"    => [0.959187, 0.959187, 0.959187, 0.959187, 0.959187, 0.95918…
```
 
 This returns a dictionary of the MCMC results. Among `theta`, several other parameters are also reported, like the log-posterior `lp__` and the stepsize `stepsize__`. If one is just interested in a subset of parameters, the `extract` function can be called with an optional vector of parameters of interest:

 ```julia
 julia> extract(sf, ["theta", "lp__"])

 Dict{String,Array{Float64,1}} with 2 entries:
  "lp__"          => [-4.62739, -4.74118, -7.03734, -5.65588, -4.41062, -4.4106…
  "theta"         => [0.458652, 0.48066, 0.721026, 0.605692, 0.40698, 0.40698, …
 ```

By default, Stan is run with 2000 iterations and 4 chains. If possible, chains are run in parallel using Julia's implementation of message passing, so simpling adding workers with `Base.addprocs(n)` or calling julia with `julia -p n` enables parallel sampling.
```
## Accessing the content of Stanfit objects

A `::Stanfit` object has the fields `:model`, `:data`, `:iter`, `:chains`, `:result`, `:diagnostics`. 
`:model` contains the path to the stan model, `:data` contains the input dictionary, and `:iter` and `:chains` the number of chains and iterations of the MCMC run.
The field `:result` contains a vector of dictionaires of MCMC results (one for each chain). Normally, it is not needed to access this field directly, as `extract` is provided as a convenience function to merge the different chains automatically.
`:diagnostics` contains a String with possible sampling problems or an empty string (`""`) if no problems were found. The diagnostics are done using CmdStan's built-in diagnose tool, which is described in the [CmdStan Interface User's Guide](https://github.com/stan-dev/cmdstan/releases/download/v2.17.1/cmdstan-guide-2.17.1.pdf).
It checks for the following potential problems (from the CmdStan manual):

- Transitions that hit the maximum treedepth
- Divergent transitions
- Low E-BFMI values
- Low effective ssample sizes
- High R̂ values

## Additional keyword arguments

The `stan` function also provides the optional keyword parameters `save_binary`, `save_result`, `save_data` and `save_diagnostics` to save output files at a specific path. For example,

```julia
sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,0,1,1]), 
          save_binary = "~/Desktop/bernoulli_binary")
```
saves the compiled stan binary at the user's desktop for Unix systems. Please note that executable files need to have an ".exe" file extension in Windows systems.
To avoid recompiling the same model repeatedly, the `stan` function also accepts an executable binary:

```julia
sf = stan("bernoulli_binary", Dict("N" => 5, "y" = [0,0,0,1,1]))
```

An execuatable binary can also be built by using the `build_binary(model, path)` function.

`save_result` saves the input data in CmdStans dump data format, which is almost identical to the Rdump data format.

## Providing CmdStan commandline arguments

Most of the models do not require changing Stan's sampling parameters. If it is necessary to change some sampling parameters, the `stan` function provides the optional keyword argument `stan_args' as a hook into CmdStan's command line interface. For example to change the target acceptance rate (which can be tried if divergent transitions occur during sampling) to a value of 0.99, call:

```julia
sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,0,1,1]), 
          stan_args = "adapt delta=0.95")
```

CmdStan's arguments are hierarchical, which means changing one of the lower level parameters requires setting some parameters before. For example, to change the maximum tree depth of the NUTS sampler, it is required to set `stan_args = "algorithm=hmc engine=nuts max_depth=20"`. For a full description of possible command line arguments, please refer to the [CmdStan Interface User's Guide](https://github.com/stan-dev/cmdstan/releases/download/v2.17.1/cmdstan-guide-2.17.1.pdf).

## Parameter optimization and approximate sampling from the posterior

CmdStan can also find the posterior mode or fit a variational approximation to the posterior. To access these functions, call `stan` with the additional argument `"optimize"` or `"variational"`:

```julia
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,0,0,1]), "optimize")
julia> extract(sf)

Dict{String,Array{Float64,1}} with 2 entries:
  "theta" => [0.200004]
  "lp__"  => [-2.50201]
```

The value of `theta` corresponds to the posterior mode of 0.2 (1 "success" out of 5 attepts).
`stan_args` can be used to set additional Stan parameters and files can be saved via the `save_` keyword arguments.

To get 1 million samples from the approximate posterior:

```julia
julia> sf = stan("bernoulli.stan", Dict("N" => 5, "y" => [0,0,0,0,1]), "variational",
                 stan_args="algorithm=meanfield iter=1000000")
```

Note that the hierarchical structure of CmdStan parameters requires setting "algorithm=meanfield" in order to access the "iter" parameter.