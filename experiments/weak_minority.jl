#!/usr/bin/env julia
#
# Weak Minority Preferences Experiment (Section 3.4)
#
# Tests the paradox where weak minority preferences can lead
# to strong segregation outcomes.
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

# Minority fraction (15% minority, 85% majority)
const MINORITY_FRACTION = 0.15

# Two test conditions from the paper (paper uses seg, we use tolerance = 1 - seg):
# Large difference: seg ∈ {0.5, 0.9} → tolerance ∈ {0.5, 0.1}
# Small difference: g1 seg ∈ {0.15, 0.2} → tol ∈ {0.85, 0.8}
#                   g2 seg ∈ {0.85, 0.9} → tol ∈ {0.15, 0.1}

const G1_TOLERANCES_LARGE = [0.5, 0.1]  # seg = 0.5, 0.9
const G2_TOLERANCES_LARGE = [0.5, 0.1]  # seg = 0.5, 0.9

const G1_TOLERANCES_SMALL = [0.85, 0.8]  # seg = 0.15, 0.2 (minority tolerant)
const G2_TOLERANCES_SMALL = [0.15, 0.1]  # seg = 0.85, 0.9 (majority intolerant)

const RUNS_PER_COMBINATION = 30
const MAX_STEPS = 1000
const OUTPUT_FILE = "weak_minority_network_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function run_weak_minority_network_sweep()
    results = DataFrame(
        network_type = String[],
        test_type = String[],
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

    # Combine both test conditions
    test_configs = [
        ("large_diff", G1_TOLERANCES_LARGE, G2_TOLERANCES_LARGE),
        ("small_diff", G1_TOLERANCES_SMALL, G2_TOLERANCES_SMALL)
    ]

    total = 0
    for (_, g1s, g2s) in test_configs
        total += length(NETWORK_TYPES) * length(g1s) * length(g2s) * RUNS_PER_COMBINATION
    end

    prog = Progress(total, desc="Weak minority sweep: ")

    for (test_type, g1_tols, g2_tols) in test_configs
        for net_type in NETWORK_TYPES
            for g1_tol in g1_tols
                for g2_tol in g2_tols
                    for run in 1:RUNS_PER_COMBINATION
                        seed = hash((net_type, test_type, g1_tol, g2_tol, run)) % 1000000

                        config = SimulationConfig(
                            total_agents = 1000,
                            group1_tolerance = g1_tol,
                            group2_tolerance = g2_tol,
                            group1_fraction = MINORITY_FRACTION,
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
                            test_type,
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

                        next!(prog)
                    end
                end
            end
        end
    end

    return results
end

# ============================================================================
# MAIN
# ============================================================================

println("Starting weak minority × network topology experiment...")
println("Network types: ", NETWORK_TYPES)
println("Minority fraction: ", MINORITY_FRACTION)
println("Large difference test: g1 ∈ ", G1_TOLERANCES_LARGE, ", g2 ∈ ", G2_TOLERANCES_LARGE)
println("Small difference test: g1 ∈ ", G1_TOLERANCES_SMALL, ", g2 ∈ ", G2_TOLERANCES_SMALL)
println("Runs per combination: ", RUNS_PER_COMBINATION)

total_runs = length(NETWORK_TYPES) * (
    length(G1_TOLERANCES_LARGE) * length(G2_TOLERANCES_LARGE) +
    length(G1_TOLERANCES_SMALL) * length(G2_TOLERANCES_SMALL)
) * RUNS_PER_COMBINATION
println("Total runs: ", total_runs)
println()

start_time = time()
results = run_weak_minority_network_sweep()
elapsed = time() - start_time

CSV.write(OUTPUT_FILE, results)
println("\nCompleted in ", round(elapsed, digits=1), " seconds")
println("Results saved to: ", OUTPUT_FILE)

# Print summary
println("\n" * "="^60)
println("SUMMARY")
println("="^60)

for test_type in ["large_diff", "small_diff"]
    println("\n--- ", uppercase(test_type), " ---")
    tdf = filter(row -> row.test_type == test_type, results)

    for net_type in NETWORK_TYPES
        println("\n  ", net_type, ":")
        ndf = filter(row -> row.network_type == string(net_type), tdf)

        for g1t in unique(ndf.group1_tolerance)
            for g2t in unique(ndf.group2_tolerance)
                gdf = filter(row -> row.group1_tolerance == g1t && row.group2_tolerance == g2t, ndf)
                if nrow(gdf) > 0
                    println("    g1=", g1t, ", g2=", g2t,
                            ": sim_g1=", round(mean(gdf.similarity_group1), digits=2),
                            ", sim_g2=", round(mean(gdf.similarity_group2), digits=2),
                            ", coh=", round(mean(gdf.coherence), digits=0))
                end
            end
        end
    end
end
