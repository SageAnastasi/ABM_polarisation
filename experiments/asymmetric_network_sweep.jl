# Asymmetric Tolerance × Network Topology Experiment
# Tests how different network structures affect asymmetric tolerance dynamics

using Pkg
Pkg.activate(".")

pushfirst!(LOAD_PATH, "src")
using SchellingNetwork
using DotProductGraphs: d_elbow
using CSV
using DataFrames
using Graphs
using ProgressMeter
using Statistics

# ============================================================================
# EXPERIMENT PARAMETERS
# ============================================================================

# Network types
const NETWORK_TYPES = [:erdos_renyi, :watts_strogatz, :barabasi_albert, :geometric]

# Group 1 tolerances (fixed values to compare, matching paper Section 3.2)
const G1_TOLERANCES = [0.5, 0.9]

# Group 2 tolerances (sweep)
const G2_TOLERANCES = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

# Runs per combination
const RUNS_PER_COMBO = 30

# Output file
const OUTPUT_FILE = "asymmetric_network_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function run_asymmetric_network_sweep()
    results = DataFrame(
        network_type = String[],
        group1_tolerance = Float64[],
        group2_tolerance = Float64[],
        run = Int[],
        dimension = Float64[],
        sigma_ratio = Float64[],
        similarity_ratio = Float64[],
        similarity_group1 = Float64[],
        similarity_group2 = Float64[],
        coherence = Int[]
    )

    total = length(NETWORK_TYPES) * length(G1_TOLERANCES) * length(G2_TOLERANCES) * RUNS_PER_COMBO

    @showprogress "Asymmetric sweep: " for net_type in NETWORK_TYPES
        for g1_tol in G1_TOLERANCES
            for g2_tol in G2_TOLERANCES
                for run in 1:RUNS_PER_COMBO
                    seed = hash((net_type, g1_tol, g2_tol, run)) % 1000000

                    config = SimulationConfig(
                        total_agents = 1000,
                        group1_tolerance = g1_tol,
                        group2_tolerance = g2_tol,
                        network_type = net_type,
                        seed = seed,
                        max_steps = 100
                    )

                model = initialize_model(config)
                run_simulation!(model)

                # Compute metrics
                final_sigmas = get_sigmas(model.social)
                final_ratio = final_sigmas[1] / final_sigmas[2]
                dim = d_elbow(final_sigmas)

                stats = model.stats
                total_agents = config.total_agents
                group1_count = floor(Int, total_agents * config.group1_fraction)
                group2_count = total_agents - group1_count

                similarity = stats.similarity_sum / total_agents
                sim_g1 = group1_count > 0 ? stats.similarity_group1 / group1_count : 0.0
                sim_g2 = group2_count > 0 ? stats.similarity_group2 / group2_count : 0.0

                push!(results, (
                    string(net_type),
                    g1_tol,
                    g2_tol,
                    run,
                    dim,
                    final_ratio,
                    similarity,
                    sim_g1,
                    sim_g2,
                    stats.coherence
                ))
                end
            end
        end
    end

    return results
end

# ============================================================================
# MAIN
# ============================================================================

println("Starting asymmetric tolerance × network topology experiment...")
println("Network types: ", NETWORK_TYPES)
println("Group 1 tolerances: ", G1_TOLERANCES)
println("Group 2 tolerances: ", G2_TOLERANCES)
println("Runs per combination: ", RUNS_PER_COMBO)
println("Total runs: ", length(NETWORK_TYPES) * length(G1_TOLERANCES) * length(G2_TOLERANCES) * RUNS_PER_COMBO)
println()

start_time = time()
results = run_asymmetric_network_sweep()
elapsed = time() - start_time

CSV.write(OUTPUT_FILE, results)
println("\nCompleted in ", round(elapsed, digits=1), " seconds")
println("Results saved to: ", OUTPUT_FILE)

# Print summary
println("\n" * "="^60)
println("SUMMARY")
println("="^60)

for g1t in G1_TOLERANCES
    println("\n--- Group 1 tolerance = ", g1t, " ---")
    for net_type in NETWORK_TYPES
        println("\n  ", net_type, ":")
        ndf = filter(row -> row.network_type == string(net_type) && row.group1_tolerance == g1t, results)

        for g2t in G2_TOLERANCES[1:3:end]  # Every third tolerance
            tdf = filter(row -> row.group2_tolerance == g2t, ndf)
            println("    g2_tol=", g2t,
                    ": sim_g1=", round(mean(tdf.similarity_group1), digits=2),
                    ", sim_g2=", round(mean(tdf.similarity_group2), digits=2),
                    ", dim=", round(mean(tdf.dimension), digits=1))
        end
    end
end
