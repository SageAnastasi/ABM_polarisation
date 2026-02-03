# Analysis and metrics for Schelling Network ABM

using Graphs
using SparseArrays
using LinearAlgebra
using PROPACK
using DotProductGraphs: d_elbow

"""
    get_giant_component(g::AbstractGraph)

Extract the largest connected component from graph `g`.
"""
function get_giant_component(g::G) where G <: AbstractGraph
    ccomponents = connected_components(g)
    idx = argmax(length.(ccomponents))
    return g[ccomponents[idx]]
end

"""
    get_sigmas(g::AbstractGraph; nonzero=true, increase_diag=true)

Compute truncated singular values of the adjacency matrix.

# Arguments
- `g`: Input graph
- `nonzero`: Filter to non-zero singular values
- `increase_diag`: Add ones to diagonal before SVD
"""
function get_sigmas(g::G; nonzero::Bool = true, increase_diag::Bool = true) where G <: AbstractGraph
    adja = adjacency_matrix(g, Float32)
    if increase_diag
        adja[diagind(adja)] .= one(Float32)
    end
    max_k = floor(Int32, nv(g) / 10)
    sigmas = tsvdvals(adja; k = max_k)
    if nonzero
        # Filter based on tolerance
        sigmas = sigmas[1][sigmas[2] .< 10 * eps(Float32)]
    end
    return sigmas
end

"""
    safelog(x)

Safe log2 that returns 0 for non-positive values.
"""
safelog(x) = x > zero(x) ? log2(x) : zero(x)

"""
    safediv(x, y)

Safe division that returns 0 when dividing by zero.
"""
safediv(x, y) = y == zero(y) ? zero(y) : x / y

"""
    entropy(s)

Compute Shannon entropy (base 2) of distribution `s`.
"""
entropy(s) = -sum(s .* safelog.(s))

"""
    participation_entropy(g::AbstractGraph)

Compute participation entropy from the singular value spectrum.
"""
function participation_entropy(g::G) where G <: AbstractGraph
    sigmas = get_sigmas(g)
    return participation_entropy(sigmas)
end

"""
    participation_entropy(sigmas::AbstractArray; normalize=true)

Compute participation entropy from singular values.
"""
function participation_entropy(sigmas::S; normalize::Bool = true) where S <: AbstractArray
    s = normalize ? sigmas / sum(sigmas) : sigmas
    k = length(sigmas)
    return -log2(k)^-1 * entropy(s)
end

"""
    spectral_gap(g::AbstractGraph)

Compute gap between largest and second-largest normalized singular values.
"""
function spectral_gap(g::G) where G <: AbstractGraph
    sigmas = get_sigmas(g)
    return spectral_gap(sigmas)
end

"""
    spectral_gap(sigmas::AbstractArray; normalize=true)

Compute spectral gap from singular values.
"""
function spectral_gap(sigmas::S; normalize::Bool = true) where S <: AbstractArray
    s = normalize ? sigmas / sum(sigmas) : sigmas
    return s[1] - s[2]
end

"""
    blocks(p::Real)

Generate group sizes for 1000 agents with fraction `p` in group 1.
"""
function blocks(p::Real)
    start = 1000
    block1 = Int32(1000 * p)
    block2 = Int32(start - block1)
    return [block1, block2]
end

"""
    compute_dimension(g::AbstractGraph)

Compute spectral dimension estimate using d_elbow method.
Returns 0.0 if the graph is too small or produces invalid results.
"""
function compute_dimension(g::AbstractGraph)
    if nv(g) < 20
        return 0.0  # Graph too small for meaningful dimension estimate
    end
    try
        sigmas = get_sigmas(g)
        if isempty(sigmas) || any(isnan, sigmas) || any(isinf, sigmas)
            return 0.0
        end
        dim = d_elbow(sigmas)
        return isnan(dim) || isinf(dim) ? 0.0 : dim
    catch
        return 0.0
    end
end

"""
    adjm_from_edge_list(filename; giant_component=false)

Load a graph from an edge list file and return its adjacency matrix.
"""
function adjm_from_edge_list(filename; giant_component::Bool = false)
    g = giant_component ?
        loadgraph(filename, EdgeListFormat()) |> get_giant_component :
        loadgraph(filename, EdgeListFormat())
    return adjacency_matrix(g, Float32)
end
