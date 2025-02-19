# Gets the stability of the rescaled homogeneous equations
using JSON

in_parallel = true

if in_parallel
    using Base.Threads, IntervalArithmetic, IntervalRootFinding, StaticArrays, LinearAlgebra
else
    using IntervalArithmetic, IntervalRootFinding, StaticArrays, LinearAlgebra
end

unzip(a) = map(x->getfield.(a, x), fieldnames(eltype(a)))
include("src/opiniondisparity.jl")


function vary_beta2_beta3(beta2, beta3, epsilon2, epsilon3, parallel)
    m = length(beta2)
    n = length(beta3)

    psi = zeros(m, n)
    nu = zeros(m, n)

    if parallel
        println("Started running beta2 vs. beta3 in parallel:")
        Threads.@threads for (i, j) in collect(Iterators.product(1:m, 1:n))
            b2 = beta2[i]
            b3 = beta3[j]
            psi[i, j], nu[i, j] = get_opinion_disparity(epsilon2, epsilon3, b2, b3)
            print("$i, $j\n")
        end
    else
        println("Started running beta2 vs. beta3 sequentially:")
        for (i, j) in Iterators.product(1:m, 1:n)
            b2 = beta2[i]
            b3 = beta3[j]
            psi[i, j], nu[i, j] = get_opinion_disparity(epsilon2, epsilon3, b2, b3)
            print("$i, $j\n")
        end
    end

    return psi, nu
end

k = 5
l = 5

epsilon2 = LinRange(0.0, 1.0, k)
epsilon3 = LinRange(0.95, 1.0, l)

m = 301
n = 301

beta2 = LinRange(0, 1.1, m)
beta3 = LinRange(0.5, 6.0, n)


data1 = Dict("beta2"=>beta2, "beta3"=>beta3, "epsilon2"=>epsilon2, "epsilon3"=>1.0)
data2 = Dict("beta2"=>beta2, "beta3"=>beta3, "epsilon2"=>1.0, "epsilon3"=>epsilon3)

for e2 in epsilon2
    psi, nu = vary_beta2_beta3(beta2, beta3, e2, 1.0, in_parallel)
    data1["psi-$e2"] = psi
    data1["nu-$e2"] = nu
end

for e3 in epsilon3
    psi, nu = vary_beta2_beta3_distributed(beta2, beta3, 1.0, e3, in_parallel)
    data2["psi-$e3"] = psi
    data2["nu-$e3"] = nu
end

open("Data/opiniondisparity/mean-field_opinion_disparity_boundaries_epsilon2.json","w") do f
  JSON.print(f, data1)
end

open("Data/opiniondisparity/mean-field_opinion_disparity_boundaries_epsilon3.json","w") do f
    JSON.print(f, data2)
end