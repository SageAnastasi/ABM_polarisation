# Diagnostic script to verify random group assignment
# After fix: all network types should have ~50% initial similarity

using Pkg
Pkg.activate(".")

pushfirst!(LOAD_PATH, "src")
using SchellingNetwork
using Graphs
using Statistics

function measure_initial_similarity(model)
    total_sim = 0.0
    for agent in allagents(model)
        neigh = Graphs.neighbors(model.social, agent.id)
        if !isempty(neigh)
            same = count(i -> model[i].group == agent.group, neigh)
            total_sim += same / length(neigh)
        end
    end
    return total_sim / model.config.total_agents
end

function count_cross_group_edges(model)
    cross = 0
    total = 0
    for e in edges(model.social)
        total += 1
        if model[src(e)].group != model[dst(e)].group
            cross += 1
        end
    end
    return cross, total, cross / total
end

function check_group_distribution(model)
    # Check that groups are randomly distributed, not sequential
    g1_ids = [a.id for a in allagents(model) if a.group == 1]
    g2_ids = [a.id for a in allagents(model) if a.group == 2]
    return (
        g1_count = length(g1_ids),
        g2_count = length(g2_ids),
        g1_mean_id = mean(g1_ids),
        g2_mean_id = mean(g2_ids)
    )
end

println("=" ^ 60)
println("INITIAL NETWORK STRUCTURE ANALYSIS (WITH RANDOM GROUP ASSIGNMENT)")
println("=" ^ 60)
println("Expected: ~50% similarity for ALL network types")
println()

for net_type in [:erdos_renyi, :watts_strogatz, :barabasi_albert, :geometric]
    println(net_type, ":")

    sims = Float64[]
    cross_fracs = Float64[]
    degrees = Float64[]

    for seed in 1:10
        config = SimulationConfig(
            total_agents = 1000,
            group1_tolerance = 0.5,
            group2_tolerance = 0.5,
            network_type = net_type,
            seed = seed,
            max_steps = 0
        )

        model = initialize_model(config)

        sim = measure_initial_similarity(model)
        cross, total, cross_frac = count_cross_group_edges(model)
        deg = mean(degree(model.social))

        push!(sims, sim)
        push!(cross_fracs, cross_frac)
        push!(degrees, deg)
    end

    status = abs(mean(sims) - 0.5) < 0.05 ? "✓" : "✗ PROBLEM"
    println("  Similarity: ", round(mean(sims), digits=3), " ± ", round(std(sims), digits=3), "  ", status)
    println("  Cross-group edges: ", round(mean(cross_fracs) * 100, digits=1), "%")
    println("  Mean degree: ", round(mean(degrees), digits=1))
    println()
end

println("=" ^ 60)
println("VERIFYING GROUP ASSIGNMENT IS RANDOM")
println("=" ^ 60)

config = SimulationConfig(total_agents = 1000, network_type = :watts_strogatz, seed = 42)
model = initialize_model(config)
dist = check_group_distribution(model)

println("\nGroup distribution check:")
println("  Group 1 count: ", dist.g1_count, " (expected: 500)")
println("  Group 2 count: ", dist.g2_count, " (expected: 500)")
println("  Group 1 mean agent ID: ", round(dist.g1_mean_id, digits=1), " (if random: ~500)")
println("  Group 2 mean agent ID: ", round(dist.g2_mean_id, digits=1), " (if random: ~500)")

# Show first 20 agent groups to verify randomness
println("\nFirst 20 agents' groups (should be mixed, not 1,1,1...2,2,2):")
groups = [model[i].group for i in 1:20]
println("  ", join(groups, ", "))
