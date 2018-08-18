var documenterSearchIndex = {"docs": [

{
    "location": "home.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "home.html#Jstan.jl-1",
    "page": "Home",
    "title": "Jstan.jl",
    "category": "section",
    "text": "A CmdStan wrapper for Julia."
},

{
    "location": "home.html#Package-Feautures-1",
    "page": "Home",
    "title": "Package Feautures",
    "category": "section",
    "text": "Interface similar to Rstan\nParallel execution of chains via Julia's worker mechanism.\nEasily retrieve MCMC results as simple Vectors.\nUses CmdStan's diagnose tool for automatic convergence diagnostics."
},

{
    "location": "home.html#Manual-Outline-1",
    "page": "Home",
    "title": "Manual Outline",
    "category": "section",
    "text": "Package Guide\nSetting CmdStan commandine arguments\nLibrary"
},

{
    "location": "man/guide.html#",
    "page": "Guide",
    "title": "Guide",
    "category": "page",
    "text": "CurrentModule = Jstan"
},

{
    "location": "man/guide.html#Package-Guide-1",
    "page": "Guide",
    "title": "Package Guide",
    "category": "section",
    "text": ""
},

{
    "location": "man/guide.html#Installation-1",
    "page": "Guide",
    "title": "Installation",
    "category": "section",
    "text": "Jstan can be installed via the Pkg.clone. Afterwards, Pkg.build(\"Jstan\") is required to build the necessary dependencies.Pkg.clone(\"gogs@132.252.170.166:DanielHa/Jstan.jl.git\")\nPkg.build(\"Jstan\")If SSH access to the repository is unwanted (or no SSH key is setup), use:Pkg.clone(\"http://132.252.170.166:8000/DanielHa/Jstan.jl.git\")\nPkg.build(\"Jstan\")Though this requires typing in your Gogs credentials for each Pkg.update."
},

{
    "location": "man/guide.html#Usage-1",
    "page": "Guide",
    "title": "Usage",
    "category": "section",
    "text": ""
},

{
    "location": "man/guide.html#Minimal-working-example-1",
    "page": "Guide",
    "title": "Minimal working example",
    "category": "section",
    "text": "Jstan is intended to be a simple wrapper for CmdStan that simplifies file handling. To start, consider this simple bernoulli model with a single parameter theta:data {\n    int<lower=0> N;\n    int<lower=0,upper=1> y[N];\n}\nparameters {\n    real<lower=0,upper=1> theta;\n}\nmodel {\n    theta ~ beta(1,1);\n    y ~ bernoulli(theta);\n}To run a model, Jstan provides the stan function, which requires the path to the Stan model and a dictionary containg the data as input arguments. The input variables of the Stan model are provided as simple String keys to the dictionary:julia> using Jstan\n\njulia> sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" = [0,0,0,1,1]))This function call automatically compiles the .stan file and runs the model with the provided data. The stan function returns an object of type ::Stanfit. To retrieve the MCMC results, call the function extract on the returned ::Stanfit object. Results from different chains are merged:julia> extract(sf)\n\nDict{String,Array{Float64,1}} with 8 entries:\n  \"treedepth__\"   => [1.0, 2.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0  …  1.0,…\n  \"n_leapfrog__\"  => [1.0, 3.0, 1.0, 1.0, 1.0, 3.0, 3.0, 3.0, 1.0, 3.0  …  3.0,…\n  \"theta\"         => [0.458652, 0.48066, 0.721026, 0.605692, 0.40698, 0.40698, …\n  \"energy__\"      => [5.22223, 4.8696, 7.05694, 6.90516, 5.23482, 5.39365, 4.36…\n  \"lp__\"          => [-4.62739, -4.74118, -7.03734, -5.65588, -4.41062, -4.4106…\n  \"accept_stat__\" => [1.0, 0.987203, 0.466092, 1.0, 1.0, 0.73413, 1.0, 0.983674…\n  \"divergent__\"   => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0  …  0.0,…\n  \"stepsize__\"    => [0.959187, 0.959187, 0.959187, 0.959187, 0.959187, 0.95918…This returns a dictionary of the MCMC results. Among theta, several other parameters are also reported, like the log-posterior lp__ and the stepsize stepsize__. If one is just interested in a subset of parameters, the extract function can be called with an optional vector of parameters of interest: julia> extract(sf, [\"theta\", \"lp__\"])\n\n Dict{String,Array{Float64,1}} with 2 entries:\n  \"lp__\"          => [-4.62739, -4.74118, -7.03734, -5.65588, -4.41062, -4.4106…\n  \"theta\"         => [0.458652, 0.48066, 0.721026, 0.605692, 0.40698, 0.40698, …\n ```\n\nBy default, Stan is run with 2000 iterations and 4 chains. If possible, chains are run in parallel using Julia's implementation of message passing, so simpling adding workers with `Base.addprocs(n)` or calling julia with `julia -p n` enables parallel sampling."
},

{
    "location": "man/guide.html#Accessing-the-content-of-Stanfit-objects-1",
    "page": "Guide",
    "title": "Accessing the content of Stanfit objects",
    "category": "section",
    "text": "A ::Stanfit object has the fields :model, :data, :iter, :chains, :result, :diagnostics.  :model contains the path to the stan model, :data contains the input dictionary, and :iter and :chains the number of chains and iterations of the MCMC run. The field :result contains a vector of dictionaires of MCMC results (one for each chain). Normally, it is not needed to access this field directly, as extract is provided as a convenience function to merge the different chains automatically. :diagnostics contains a String with possible sampling problems or an empty string (\"\") if no problems were found. The diagnostics are done using CmdStan's built-in diagnose tool, which is described in the CmdStan Interface User's Guide. It checks for the following potential problems (from the CmdStan manual):Transitions that hit the maximum treedepth\nDivergent transitions\nLow E-BFMI values\nLow effective ssample sizes\nHigh R̂ values"
},

{
    "location": "man/guide.html#Additional-keyword-arguments-1",
    "page": "Guide",
    "title": "Additional keyword arguments",
    "category": "section",
    "text": "The stan function also provides the optional keyword parameters save_binary, save_result, save_data and save_diagnostics to save output files at a specific path. For example,sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,0,1,1]), \n          save_binary = \"~/Desktop/bernoulli_binary\")saves the compiled stan binary at the user's desktop for Unix systems. Please note that executable files need to have an \".exe\" file extension in Windows systems. To avoid recompiling the same model repeatedly, the stan function also accepts an executable binary:sf = stan(\"bernoulli_binary\", Dict(\"N\" => 5, \"y\" = [0,0,0,1,1]))An execuatable binary can also be built by using the build_binary(model, path) function.save_result saves the input data in CmdStans dump data format, which is almost identical to the Rdump data format."
},

{
    "location": "man/guide.html#Providing-CmdStan-commandline-arguments-1",
    "page": "Guide",
    "title": "Providing CmdStan commandline arguments",
    "category": "section",
    "text": "Most of the models do not require changing Stan's sampling parameters. If it is necessary to change some sampling parameters, the stan function provides the optional keyword argument `stan_args' as a hook into CmdStan's command line interface. For example to change the target acceptance rate (which can be tried if divergent transitions occur during sampling) to a value of 0.99, call:sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,0,1,1]), \n          stan_args = \"adapt delta=0.95\")CmdStan's arguments are hierarchical, which means changing one of the lower level parameters requires setting some parameters before. For example, to change the maximum tree depth of the NUTS sampler, it is required to set stan_args = \"algorithm=hmc engine=nuts max_depth=20\". For a full description of possible command line arguments, please refer to the CmdStan Interface User's Guide."
},

{
    "location": "man/guide.html#Parameter-optimization-and-approximate-sampling-from-the-posterior-1",
    "page": "Guide",
    "title": "Parameter optimization and approximate sampling from the posterior",
    "category": "section",
    "text": "CmdStan can also find the posterior mode or fit a variational approximation to the posterior. To access these functions, call stan with the additional argument \"optimize\" or \"variational\":julia> sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,0,0,1]), \"optimize\")\njulia> extract(sf)\n\nDict{String,Array{Float64,1}} with 2 entries:\n  \"theta\" => [0.200004]\n  \"lp__\"  => [-2.50201]The value of theta corresponds to the posterior mode of 0.2 (1 \"success\" out of 5 attepts). stan_args can be used to set additional Stan parameters and files can be saved via the save_ keyword arguments.To get 1 million samples from the approximate posterior:julia> sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,0,0,1]), \"variational\",\n                 stan_args=\"algorithm=meanfield iter=1000000\")Note that the hierarchical structure of CmdStan parameters requires setting \"algorithm=meanfield\" in order to access the \"iter\" parameter."
},

{
    "location": "lib/lib.html#",
    "page": "Library",
    "title": "Library",
    "category": "page",
    "text": ""
},

{
    "location": "lib/lib.html#Jstan.stan",
    "page": "Library",
    "title": "Jstan.stan",
    "category": "Function",
    "text": "stan(model, data::Dict; <keyword arguments>)\n\nRun a stan model (.stan file or executable) located at model  with the data present at 'data'.\n\nArguments\n\nmodel::AbstractString: path leading to a .stan file or stan executable.\ndata::Dict{String, T} where T: dictionary containing data for the stan model.\nìter::Integer=2000: number of sampling iterations.\nchains::Integer=4: number of seperate chains, each with iter sampling iterations.\nstan_args::AbstractString: arguments passed to the CmdStan Interface, see Details.\nsave_binary::AbstractString=\"\": save the compiled stan binary.\nsave_data::AbstractString=\"\": save the input data in .Rdump format.\nsave_result::AbstractString=\"\": save stan results in .csv format, chains are merged.\nsave_diagnostics::AbstractString=\"\": save eventual sampling problems (e.g. low R̂).\n\nExamples\n\njulia> stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,1,1,1]))\nJstan.Stanfit\n\njulia> stan(\"bernoulli_binary\", Dict(\"N\" => 5, \"y\" => [1,1,1,1,1]),\n            iter = 20000, chains = 10)\nJstan.Stanfit\n\njulia> stan(\"bernoulli_binary\", Dict(\"N\" => 5, \"y\" => [1,1,1,1,1]), \n            stan_args = \"adapt delta=0.9\")\nJstan.Stanfit\n\n```\n\n\n\nstan(model, data::Dict, method::AbstractString; <keyword arguments>)\n\nProvide access to Stan's optimization and approximate sampling interface.\n\nmethod is one of \"sample\", \"optimize\" or \"variational\". Additional command-line arguments can be supplied via the stan_args argument.\n\nExamples\n\njulia> stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,1,1,1]), \"optimize\",\n            stan_args = \"algorithm=newton\")\nJstan.Stanfit\n\n\n\n"
},

{
    "location": "lib/lib.html#Jstan.extract",
    "page": "Library",
    "title": "Jstan.extract",
    "category": "Function",
    "text": "extract(::Stanfit)\n\nExtract the results from a Stanfit object.\n\nExamples\n\njulia> sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,1,1,1]))\nJstan.Stanfit\n\njulia> extract(sf)\nDict{String,Array{Float64,1}} with 8 entries:\n  \"treedepth__\"   => [2.0, 2.0, 2.0, 1.0, 1.0, 1.0, 2.0, 2.0,…\n  \"n_leapfrog__\"  => [3.0, 3.0, 3.0, 3.0, 3.0, 1.0, 3.0, 3.0,…\n  \"theta\"         => [0.728654, 0.564211, 0.777617, 0.393488,…\n  \"energy__\"      => [5.17937, 5.13451, 5.59839, 6.70578, 5.6…\n  \"lp__\"          => [-5.17931, -4.7811, -5.51614, -5.23091, …\n  \"accept_stat__\" => [0.980242, 1.0, 0.890734, 0.890749, 0.94…\n  \"divergent__\"   => [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,…\n  \"stepsize__\"    => [0.93671, 0.93671, 0.93671, 0.93671, 0.9…\n\n\n\nextract(::Stanfit, pars::AbstractVector{T}) where T <: AbstractString\n\nRestrict extracted results to a subset of parameters.\n\nExamples\n\njulia> sf = stan(\"bernoulli.stan\", Dict(\"N\" => 5, \"y\" => [0,0,1,1,1]))\nJstan.Stanfit\n\njulia> extract(sf, [\"lp__\", \"theta])\nDict{String,Array{Float64,1}} with 2 entries:\n  \"lp__\"          => [-5.17931, -4.7811, -5.51614, -5.23091, …\n  \"theta\"         => [0.728654, 0.564211, 0.777617, 0.393488,…\n\n\n\n"
},

{
    "location": "lib/lib.html#Jstan.build_binary",
    "page": "Library",
    "title": "Jstan.build_binary",
    "category": "Function",
    "text": "build_binary(model, path)\n\nBuild a stan executable binary from a .stan file. ```\n\n\n\n"
},

{
    "location": "lib/lib.html#Functions-1",
    "page": "Library",
    "title": "Functions",
    "category": "section",
    "text": "stan\nextract\nbuild_binary"
},

{
    "location": "lib/lib.html#Index-1",
    "page": "Library",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
