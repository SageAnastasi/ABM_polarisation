using Graphs
using Random
using SparseArrays
using PROPACK
using LinearAlgebra

function get_giant_component(g::G) where G<:AbstractGraph
    ccomponents = connected_components(g)
    idxes = ccomponents .|> length |> argmax
    return g[ccomponents[idxes]]
end

function vertex_sample_graph(g::G) where G<:AbstractGraph
    idxs = rand(vertices(g),
                nv(g)) |> unique
    return g[idxs]
end

vertex_sample_connected_graph(g::G) where G<:AbstractGraph = g |>
                        get_giant_component |>
                        vertex_sample_graph |>
                        get_giant_component

function subsample_graph(g::G) where G<:AbstractGraph
    
    N = nv(g)
    E = ne(g)
    sample_g = SimpleDiGraph()
    add_vertices!(sample_g, N)

    test_edges = collect(edges(g))[rand(1:E,E) |> unique]

    for edge in test_edges
        add_edge!(sample_g, edge)
    end

    return sample_g

end



subsample_connected_graph(g::G) where G<:AbstractGraph = g |>
                        get_giant_component |>
                        subsample_graph |>
                        get_giant_component

function get_σs(g::G; nonzero = true, increase_diag = true) where G<:AbstractGraph
    adja = adjacency_matrix(g, Float32)
    if increase_diag
        adja[diagind(adja)] .= one(Float32)
    end
    max_k = floor(nv(g)/10) |> Int32
    σs = tsvdvals(adja; k = max_k)
    if nonzero
         σs = σs[1][σs[2] .< 10*eps(Float32)]
    end
    return σs
end

safelog(x) = x > zero(x) ? log2(x) : zero(x)
safediv(x, y) = y == zero(y) ? zero(y) : x / y
entropy(s) = -sum(s .* safelog.(s))

function Pentropy(g::G) where G<:AbstractGraph
    σs = get_σs(g)
   
    return Pentropy(σs)
end

function Pentropy(σs::S; normalize::Bool = true) where S<:AbstractArray
    s = σs
    if normalize
        s /= sum(σs)
    end

    k =length(σs)
    
    return -log2(k)^-1 * entropy(s)
end

function spectral_gap(g::G) where G<:AbstractGraph

    σs = get_σs(g)

    return spectral_gap(σs)
end

function spectral_gap(σs::S; normalize::Bool=true) where S<:AbstractArray

    s = σs

    if normalize
        s /= sum(s)
    end

    gap = s[1] - s[2]

    return gap
end

function blocks(p::Real)
    start = 1000
    block1 = 1000*p
    block2 = start - block1
    return Int32.([block1,block2])
end

function adjm_from_edge_list(filename; giant_component::Bool = false)
    g = giant_component ? loadgraph(filename, EdgeListFormat()) |>
                            get_giant_component : 
                            loadgraph(filename, EdgeListFormat())
    adjacency_matrix(g,Float32)
end