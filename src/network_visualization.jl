# Network visualization functions for Schelling Network ABM

using CairoMakie
using GraphMakie
using GraphMakie.NetworkLayout: Spring
using Graphs
using SimpleWeightedGraphs
using Random

"""
    NetworkSnapshot

A snapshot of the social network at a specific simulation step.

# Fields
- `step::Int`: The simulation step number
- `graph::SimpleWeightedGraph`: Copy of the social network
- `groups::Vector{Int}`: Group membership for each agent
- `moods::Vector{Bool}`: Happiness state for each agent
"""
struct NetworkSnapshot
    step::Int
    graph::SimpleWeightedGraph
    groups::Vector{Int}
    moods::Vector{Bool}
end

"""
    group_layout(snapshot::NetworkSnapshot; spread=1.0, jitter=0.3, seed=42)

Create a layout that positions nodes by group membership.
Group 1 on the left, Group 2 on the right, with random jitter within each group.

This makes edge changes between groups clearly visible across time steps.
"""
function group_layout(snapshot::NetworkSnapshot; spread::Float64=1.0, jitter::Float64=0.3, seed::Int=42)
    rng = Xoshiro(seed)
    n = length(snapshot.groups)
    positions = Vector{Point2f}(undef, n)

    for i in 1:n
        # X position: Group 1 on left (-spread), Group 2 on right (+spread)
        base_x = snapshot.groups[i] == 1 ? -spread : spread

        # Add jitter
        x = base_x + jitter * (rand(rng) - 0.5) * 2
        y = jitter * 2 * (rand(rng) - 0.5) * 2

        positions[i] = Point2f(x, y)
    end

    return positions
end

"""
    group_layout_function(snapshot::NetworkSnapshot; kwargs...)

Returns a layout function compatible with GraphMakie that uses group-based positioning.
"""
function group_layout_function(snapshot::NetworkSnapshot; kwargs...)
    positions = group_layout(snapshot; kwargs...)
    return g -> positions
end

"""
    run_simulation_with_snapshots!(model; max_steps=nothing, snapshot_steps=nothing)

Run simulation and record network snapshots at specified steps.

# Arguments
- `model`: The ABM model
- `max_steps`: Maximum steps (defaults to config.max_steps)
- `snapshot_steps`: Vector of step numbers to record (defaults to [1, 10, 25, 50, 100])

# Returns
- `snapshots::Vector{NetworkSnapshot}`: Network snapshots at requested steps
- `coherence::Int`: Step when convergence occurred (0 if not)
"""
function run_simulation_with_snapshots!(
    model;
    max_steps::Union{Int, Nothing} = nothing,
    snapshot_steps::Union{Vector{Int}, Nothing} = nothing
)
    config = model.config
    steps = isnothing(max_steps) ? config.max_steps : max_steps

    # Default snapshot steps
    if isnothing(snapshot_steps)
        snapshot_steps = [1, 10, 25, 50, min(100, steps)]
        snapshot_steps = unique(filter(s -> s <= steps, snapshot_steps))
    end

    snapshots = NetworkSnapshot[]
    coherence = 0

    # Record initial state (step 0)
    if 0 in snapshot_steps || 1 in snapshot_steps
        push!(snapshots, take_snapshot(model, 0))
    end

    for step_num in 1:steps
        reset!(model.stats)

        # Run one step for all agents
        for agent in allagents(model)
            schelling_step!(agent, model)
        end

        # Record snapshot if requested
        if step_num in snapshot_steps
            push!(snapshots, take_snapshot(model, step_num))
        end

        # Check for convergence
        happy_proportion = model.stats.happy_agents / config.total_agents
        if happy_proportion >= 1.0
            coherence = step_num
            model.stats.coherence = coherence

            # Record final state if we converged early and haven't recorded it
            if !(step_num in snapshot_steps)
                push!(snapshots, take_snapshot(model, step_num))
            end
            break
        end
    end

    model.stats.coherence = coherence
    return snapshots, coherence
end

"""
    take_snapshot(model, step)

Create a snapshot of the current network state.
"""
function take_snapshot(model, step::Int)
    # Deep copy the graph
    g = SimpleWeightedGraph(nv(model.social))
    for e in edges(model.social)
        add_edge!(g, src(e), dst(e), weight(e))
    end

    # Record agent states
    n = nagents(model)
    groups = [model[i].group for i in 1:n]
    moods = [model[i].mood for i in 1:n]

    return NetworkSnapshot(step, g, groups, moods)
end

"""
    get_edge_colors(snapshot::NetworkSnapshot; same_color=:steelblue, cross_color=:red, alpha=0.4)

Get colors for each edge based on whether it connects same-group or cross-group nodes.
"""
function get_edge_colors(
    snapshot::NetworkSnapshot;
    same_color = :gray,
    cross_color = :red,
    alpha::Float64 = 0.4
)
    g = snapshot.graph
    colors = Vector{Any}(undef, ne(g))

    for (i, e) in enumerate(edges(g))
        s, d = src(e), dst(e)
        if snapshot.groups[s] == snapshot.groups[d]
            colors[i] = (same_color, alpha)
        else
            colors[i] = (cross_color, alpha)
        end
    end

    return colors
end

"""
    plot_network_snapshot(snapshot::NetworkSnapshot; layout=nothing, kwargs...)

Plot a single network snapshot.

# Arguments
- `snapshot`: NetworkSnapshot to visualize
- `layout`: Layout algorithm (default: Spring with iterations based on graph size)
- `show_edges`: Whether to show edges (default: true for small graphs)
- `color_edges_by_group`: Color edges by same-group (gray) vs cross-group (red)
- `node_size`: Size of nodes (default: 10)

# Returns
- `fig`: Makie Figure
"""
function plot_network_snapshot(
    snapshot::NetworkSnapshot;
    layout = nothing,
    show_edges::Bool = nv(snapshot.graph) <= 200,
    color_edges_by_group::Bool = true,
    node_size::Real = 10,
    title::Union{String, Nothing} = nothing
)
    g = snapshot.graph
    n = nv(g)

    # Default layout
    if isnothing(layout)
        layout = Spring(; iterations = min(1000, n * 10))
    end

    # Node colors based on group
    node_colors = [snapshot.groups[i] == 1 ? :steelblue : :coral for i in 1:n]

    # Edge colors
    if color_edges_by_group
        edge_colors = get_edge_colors(snapshot; same_color=:gray, cross_color=:red, alpha=0.5)
    else
        edge_colors = (:gray, 0.3)
    end

    # Create figure
    fig = Figure(size = (700, 700))

    plot_title = isnothing(title) ? "Step " * string(snapshot.step) : title
    ax = Axis(fig[1, 1], title = plot_title)
    hidedecorations!(ax)
    hidespines!(ax)

    # Plot graph
    if show_edges
        graphplot!(ax, g;
            node_color = node_colors,
            node_size = node_size,
            edge_color = edge_colors,
            edge_width = 0.5,
            layout = layout
        )
    else
        # For large graphs, just plot nodes at their layout positions
        pos = layout(g)
        scatter!(ax, [p[1] for p in pos], [p[2] for p in pos];
            color = node_colors,
            markersize = node_size
        )
    end

    # Add legend
    legend_elements = [
        MarkerElement(color = :steelblue, marker = :circle, markersize = 15),
        MarkerElement(color = :coral, marker = :circle, markersize = 15)
    ]
    legend_labels = ["Group 1", "Group 2"]

    if color_edges_by_group && show_edges
        push!(legend_elements, LineElement(color = :gray, linewidth = 2))
        push!(legend_elements, LineElement(color = :red, linewidth = 2))
        push!(legend_labels, "Same-group edge")
        push!(legend_labels, "Cross-group edge")
    end

    Legend(fig[1, 2], legend_elements, legend_labels)

    return fig
end

"""
    plot_network_evolution(snapshots::Vector{NetworkSnapshot}; kwargs...)

Plot network evolution as a grid of snapshots.

# Arguments
- `snapshots`: Vector of NetworkSnapshot
- `ncols`: Number of columns in grid (default: auto)
- `node_size`: Size of nodes (default: 6)
- `show_edges`: Whether to show edges (default: auto based on size)
- `color_edges_by_group`: Color edges by same-group (gray) vs cross-group (red)
- `fixed_layout`: If true, use layout from final graph for all (default: false)

# Returns
- `fig`: Makie Figure
"""
function plot_network_evolution(
    snapshots::Vector{NetworkSnapshot};
    ncols::Union{Int, Nothing} = nothing,
    node_size::Real = 6,
    show_edges::Union{Bool, Nothing} = nothing,
    color_edges_by_group::Bool = true,
    figsize::Union{Tuple{Int, Int}, Nothing} = nothing,
    fixed_layout::Bool = false
)
    n_snapshots = length(snapshots)

    if isnothing(ncols)
        ncols = min(n_snapshots, 3)
    end
    nrows = ceil(Int, n_snapshots / ncols)

    # Determine if we should show edges
    if isnothing(show_edges)
        show_edges = nv(snapshots[1].graph) <= 150
    end

    # Figure size
    if isnothing(figsize)
        figsize = (400 * ncols, 400 * nrows)
    end

    fig = Figure(size = figsize)

    # Precompute layouts for each snapshot
    layouts = Vector{Vector{Point2f}}(undef, n_snapshots)

    if fixed_layout
        # Use layout from final graph for all snapshots
        final_graph = snapshots[end].graph
        spring = Spring(; iterations = min(1000, nv(final_graph) * 10))
        final_positions = spring(final_graph)
        for i in 1:n_snapshots
            layouts[i] = final_positions
        end
    else
        # Compute independent layout for each snapshot
        for (i, snapshot) in enumerate(snapshots)
            spring = Spring(; iterations = min(1000, nv(snapshot.graph) * 10))
            layouts[i] = spring(snapshot.graph)
        end
    end

    for (idx, snapshot) in enumerate(snapshots)
        row = div(idx - 1, ncols) + 1
        col = mod(idx - 1, ncols) + 1

        ax = Axis(fig[row, col],
            title = "Step " * string(snapshot.step),
            aspect = DataAspect()
        )
        hidedecorations!(ax)
        hidespines!(ax)

        g = snapshot.graph
        node_colors = [snapshot.groups[i] == 1 ? :steelblue : :coral
                       for i in 1:nv(g)]

        # Edge colors
        if color_edges_by_group
            edge_colors = get_edge_colors(snapshot; same_color=:gray, cross_color=:red, alpha=0.4)
        else
            edge_colors = (:gray, 0.2)
        end

        positions = layouts[idx]
        layout_func(g) = positions

        if show_edges
            graphplot!(ax, g;
                node_color = node_colors,
                node_size = node_size,
                edge_color = edge_colors,
                edge_width = 0.3,
                layout = layout_func
            )
        else
            scatter!(ax, [p[1] for p in positions], [p[2] for p in positions];
                color = node_colors,
                markersize = node_size
            )
        end
    end

    # Add legend at the bottom
    if color_edges_by_group && show_edges
        Legend(fig[nrows + 1, 1:ncols],
            [
                [MarkerElement(color = :steelblue, marker = :circle, markersize = 15),
                 MarkerElement(color = :coral, marker = :circle, markersize = 15)],
                [LineElement(color = :gray, linewidth = 3),
                 LineElement(color = :red, linewidth = 3)]
            ],
            [["Group 1", "Group 2"], ["Same-group", "Cross-group"]],
            ["Nodes", "Edges"],
            orientation = :horizontal,
            tellheight = true,
            tellwidth = false
        )
    else
        Legend(fig[nrows + 1, 1:ncols],
            [MarkerElement(color = :steelblue, marker = :circle, markersize = 15),
             MarkerElement(color = :coral, marker = :circle, markersize = 15)],
            ["Group 1", "Group 2"],
            orientation = :horizontal,
            tellheight = true,
            tellwidth = false
        )
    end

    return fig
end

"""
    save_network_evolution(model_or_config, output_path; snapshot_steps=nothing, kwargs...)

Run a simulation, record snapshots, and save the evolution plot.

# Arguments
- `model_or_config`: Either an initialized model or a SimulationConfig
- `output_path`: Path to save the figure
- `snapshot_steps`: Steps to record (default: [0, 5, 10, 25, 50])
- Additional kwargs passed to plot_network_evolution

# Returns
- `fig`: The generated figure
- `snapshots`: The recorded snapshots
"""
function save_network_evolution(
    config::SimulationConfig,
    output_path::String;
    snapshot_steps::Vector{Int} = [0, 5, 10, 25, 50],
    kwargs...
)
    model = initialize_model(config)
    snapshots, coherence = run_simulation_with_snapshots!(model;
        snapshot_steps = snapshot_steps)

    fig = plot_network_evolution(snapshots; kwargs...)
    save(output_path, fig)

    return fig, snapshots
end
