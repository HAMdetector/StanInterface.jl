using StanInterface, Documenter

makedocs(format = :html, sitename = "StanInterface.jl", authors = "Daniel Habermann",
         pages = [
                  "Home" => "home.md",
                  "Manual" => Any[
                      "Guide" => "man/guide.md"],
                  "Library" => "lib/lib.md"
                 ])

deploydocs(
    repo = "http://132.252.170.166:8000/DanielHa/StanInterface.jl.git"
)
