# Model initialization for Schelling Network ABM

using Agents
using SimpleWeightedGraphs
using Graphs
using Random

"""
    random_excluded(rng, min_val, max_val, excluded)

Generate a random integer in [min_val, max_val] that is not equal to `excluded`.
"""
function random_excluded(rng::AbstractRNG, min_val::Int, max_val::Int, excluded::Int)
    k = rand(rng, min_val:max_val)
    while k == excluded
        k = rand(rng, min_val:max_val)
    end
    return k
end

# Placeholder step function - actual logic is in simulation.jl
# This is needed for Agents.jl v6 model construction
function _placeholder_step!(agent, model)
    return nothing
end

"""
    initialize_model(config::SimulationConfig)

Create and initialize a Schelling segregation model on a social network.

Returns a StandardABM with:
- Agents assigned to groups based on `config.group1_fraction`
- Random social network with `config.initial_edges` per agent
- Initial mood set based on neighbor composition
"""
function initialize_model(config::SimulationConfig)
    rng = Xoshiro(config.seed)

    # Create model properties
    properties = (
        social = SimpleWeightedGraph(config.total_agents),
        config = config,
        stats = StepStatistics()
    )

    # Create model with placeholder step function (Agents.jl v6 requirement)
    model = StandardABM(
        SchellingAgent;
        properties = properties,
        rng = rng,
        container = Vector,
        scheduler = Schedulers.Randomly(),
        agent_step! = _placeholder_step!
    )

    # Calculate group sizes
    group1_count = floor(Int, config.total_agents * config.group1_fraction)

    # Create random group assignments (not sequential!)
    # This is critical for networks like Watts-Strogatz where node IDs have spatial meaning
    group_assignments = shuffle(rng, vcat(
        fill(1, group1_count),
        fill(2, config.total_agents - group1_count)
    ))

    # Add agents
    # Note: seg = 1 - tolerance, because seg is the minimum fraction of same-group
    # neighbors needed to be happy. High tolerance means accepting more out-group,
    # so seg should be low.
    for n in 1:config.total_agents
        group = group_assignments[n]
        tolerance = group == 1 ? config.group1_tolerance : config.group2_tolerance
        seg_value = 1.0 - tolerance
        add_agent!(model; seg = seg_value, mood = false, group = group)
    end

    # Create initial social network based on network_type
    model_rng = abmrng(model)
    create_initial_network!(model, config, model_rng)

    # Set initial mood based on neighbor composition
    for agent in allagents(model)
        update_initial_mood!(agent, model)
    end

    return model
end

"""
    update_initial_mood!(agent, model)

Update agent's initial mood based on current neighbor composition.
"""
function update_initial_mood!(agent, model)
    neigh = Graphs.neighbors(model.social, agent.id)
    if isempty(neigh)
        agent.mood = false
        return
    end

    same_group_count = count(i -> model[i].group == agent.group, neigh)
    ratio = same_group_count / length(neigh)
    agent.mood = ratio >= agent.seg
end

"""
    create_initial_network!(model, config, rng)

Create the initial social network based on config.network_type.
"""
function create_initial_network!(model, config::SimulationConfig, rng::AbstractRNG)
    n = config.total_agents

    if config.network_type == :erdos_renyi
        # Original behavior: each agent adds initial_edges random connections
        for agent in allagents(model)
            for _ in 1:config.initial_edges
                friend = random_excluded(rng, 1, n, agent.id)
                add_edge!(model.social, agent.id, friend)
            end
        end

    elseif config.network_type == :watts_strogatz
        # Small-world: start with ring lattice, rewire with probability beta
        # WS gives degree = k, so use k = initial_edges * 2 to match ER density
        k = config.initial_edges * 2
        beta = 0.1  # rewiring probability
        g = watts_strogatz(n, k, beta; rng=rng)
        for e in edges(g)
            add_edge!(model.social, src(e), dst(e))
        end

    elseif config.network_type == :barabasi_albert
        # Scale-free: preferential attachment
        # BA gives average degree ≈ 2k, so use k = initial_edges to match ER density
        k = config.initial_edges
        g = barabasi_albert(n, k; rng=rng)
        for e in edges(g)
            add_edge!(model.social, src(e), dst(e))
        end

    elseif config.network_type == :random_regular
        # All nodes have exactly the same degree
        # Degree must be even and < n
        k = min(config.initial_edges, n - 1)
        if isodd(k)
            k = k - 1
        end
        g = random_regular_graph(n, k; rng=rng)
        for e in edges(g)
            add_edge!(model.social, src(e), dst(e))
        end

    elseif config.network_type == :geometric
        # Random geometric graph: nodes in 2D unit square, connected if distance < radius
        # To match ER density (~148 degree for n=1000), use radius ≈ 0.22
        # Expected degree ≈ n * π * r²
        target_degree = config.initial_edges * 2  # ER gives ~2x initial_edges
        radius = sqrt(target_degree / (n * π))

        # Generate random positions
        positions = [(rand(rng), rand(rng)) for _ in 1:n]

        # Connect nodes within radius
        for i in 1:n
            for j in (i+1):n
                dx = positions[i][1] - positions[j][1]
                dy = positions[i][2] - positions[j][2]
                if dx*dx + dy*dy < radius*radius
                    add_edge!(model.social, i, j)
                end
            end
        end

    else
        error("Unknown network_type: " * string(config.network_type))
    end

    return nothing
end
