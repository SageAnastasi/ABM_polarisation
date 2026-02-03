#!/usr/bin/env julia
#
# Group Size Sweep Experiment (Section 3.3)
#
# Varies the minority group size while using symmetric tolerances.
# Extended to test across different network topologies.
#

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

# Tolerance values to test (paper uses seg, we use tolerance = 1 - seg)
# Paper tested seg = 0.85, 0.95 → tolerance = 0.15, 0.05
# Also include moderate values for comparison
const TOLERANCES = [0.05, 0.15, 0.25, 0.5]  # seg = 0.95, 0.85, 0.75, 0.5

# Minority (group 1) fractions to test
const GROUP_FRACTIONS = [0.05, 0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50]

const RUNS_PER_COMBINATION = 30
const MAX_STEPS = 1000
const OUTPUT_FILE = "group_size_network_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function run_group_size_network_sweep()
    results = DataFrame(
        network_type = String[],
        tolerance = Float64[],
        group1_fraction = Float64[],
        run = Int[],
        dimension = Float64[],
        sigma_ratio = Float64[],
        similarity_ratio = Float64[],
        similarity_group1 = Float64[],
        similarity_group2 = Float64[],
        coherence = Int[]
    )

    total = length(NETWORK_TYPES) * length(TOLERANCES) * length(GROUP_FRACTIONS) * RUNS_PER_COMBINATION

    @showprogress "Group size sweep: " for net_type in NETWORK_TYPES
        for tol in TOLERANCES
            for frac in GROUP_FRACTIONS
                for run in 1:RUNS_PER_COMBINATION
                    seed = hash((net_type, tol, frac, run)) % 1000000

                    config = SimulationConfig(
                        total_agents = 1000,
                        group1_tolerance = tol,
                        group2_tolerance = tol,
                        group1_fraction = frac,
                        network_type = net_type,
                        seed = seed,
                        max_steps = MAX_STEPS
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
                        tol,
                        frac,
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

println("Starting group size × network topology experiment...")
println("Network types: ", NETWORK_TYPES)
println("Tolerances: ", TOLERANCES)
println("Group fractions: ", GROUP_FRACTIONS)
println("Runs per combination: ", RUNS_PER_COMBINATION)
println("Total runs: ", length(NETWORK_TYPES) * length(TOLERANCES) * length(GROUP_FRACTIONS) * RUNS_PER_COMBINATION)
println()

start_time = time()
results = run_group_size_network_sweep()
elapsed = time() - start_time

CSV.write(OUTPUT_FILE, results)
println("\nCompleted in ", round(elapsed, digits=1), " seconds")
println("Results saved to: ", OUTPUT_FILE)

# Print summary
println("\n" * "="^60)
println("SUMMARY")
println("="^60)

for net_type in NETWORK_TYPES
    println("\n", net_type, ":")
    ndf = filter(row -> row.network_type == string(net_type), results)

    for tol in TOLERANCES
        tdf = filter(row -> row.tolerance == tol, ndf)
        for frac in [0.1, 0.25, 0.5]
            fdf = filter(row -> row.group1_fraction == frac, tdf)
            if nrow(fdf) > 0
                println("  tol=", tol, ", frac=", frac,
                        ": sim_g1=", round(mean(fdf.similarity_group1), digits=2),
                        ", sim_g2=", round(mean(fdf.similarity_group2), digits=2))
            end
        end
    end
end
