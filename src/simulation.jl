# Simulation logic for Schelling Network ABM

using Agents
using Graphs

"""
    schelling_step!(agent, model)

Execute one step for a single agent in the Schelling model.

1. Count same-group vs different-group neighbors
2. If ratio of same-group neighbors >= tolerance: happy
3. If unhappy: remove a random different-group edge
4. Add new edges until min_neighbors is reached
5. Track statistics in model.stats
"""
function schelling_step!(agent, model)
    which_agent = agent.id
    config = model.config
    stats = model.stats

    # Get neighbors and classify by group
    neigh = Graphs.neighbors(model.social, which_agent)
    neighbors_same_group = Int[]
    neighbors_other_group = Int[]

    for neighbor_id in neigh
        if model[neighbor_id].group == agent.group
            push!(neighbors_same_group, neighbor_id)
        else
            push!(neighbors_other_group, neighbor_id)
        end
    end

    count_neighbors = length(neigh)
    count_same = length(neighbors_same_group)

    # Get the RNG from model (Agents.jl v6 API)
    model_rng = abmrng(model)

    # Check happiness and handle unhappy case
    if count_neighbors > 0 && count_same / count_neighbors >= agent.seg
        agent.mood = true
        stats.happy_agents += 1
    else
        agent.mood = false
        # If unhappy and have different-group neighbors, cut one
        if !isempty(neighbors_other_group)
            cutoff = rand(model_rng, neighbors_other_group)
            rem_edge!(model.social, which_agent, cutoff)
            count_neighbors -= 1
        end
    end

    # Maintain minimum neighbor count
    while count_neighbors <= config.min_neighbors
        friend = random_excluded(model_rng, 1, config.total_agents, which_agent)
        add_edge!(model.social, which_agent, friend)
        count_neighbors += 1
    end

    # Update final neighbor count for similarity calculation
    neigh_final = Graphs.neighbors(model.social, which_agent)
    final_same = count(i -> model[i].group == agent.group, neigh_final)
    final_total = length(neigh_final)

    if final_total > 0
        similarity = final_same / final_total
        stats.similarity_sum += similarity
        if agent.group == 1
            stats.similarity_group1 += similarity
        else
            stats.similarity_group2 += similarity
        end
    end

    return nothing
end

"""
    run_simulation!(model; max_steps=nothing)

Run the simulation until all agents are happy or max_steps is reached.

Returns the step number when convergence occurred (or 0 if not converged).
"""
function run_simulation!(model; max_steps::Union{Int, Nothing} = nothing)
    config = model.config
    steps = isnothing(max_steps) ? config.max_steps : max_steps
    coherence = 0

    for step_num in 1:steps
        reset!(model.stats)

        # Run one step for all agents
        for agent in allagents(model)
            schelling_step!(agent, model)
        end

        # Check for convergence
        happy_proportion = model.stats.happy_agents / config.total_agents
        if happy_proportion >= 1.0
            coherence = step_num
            model.stats.coherence = coherence
            break
        end
    end

    model.stats.coherence = coherence
    return coherence
end

"""
    run_single_experiment(config::SimulationConfig)

Run a single simulation with the given configuration and return results.
"""
function run_single_experiment(config::SimulationConfig)
    model = initialize_model(config)
    run_simulation!(model)

    # Compute metrics
    stats = model.stats
    total = config.total_agents
    group1_count = floor(Int, total * config.group1_fraction)
    group2_count = total - group1_count

    similarity_ratio = stats.similarity_sum / total
    similarity_g1 = group1_count > 0 ? stats.similarity_group1 / group1_count : 0.0
    similarity_g2 = group2_count > 0 ? stats.similarity_group2 / group2_count : 0.0
    happy_proportion = stats.happy_agents / total

    # Compute dimension
    dimension = compute_dimension(model.social)

    return (
        dimension = dimension,
        similarity_ratio = similarity_ratio,
        similarity_group1 = similarity_g1,
        similarity_group2 = similarity_g2,
        happy_proportion = happy_proportion,
        coherence = stats.coherence
    )
end
