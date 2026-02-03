# Network Topology Sweep Experiment
# Tests how different initial network structures affect segregation dynamics
# Focuses on the critical tolerance zone

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

# Tolerance values - wider range to capture all transitions
const TOLERANCES = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9]

# Network types to test
const NETWORK_TYPES = [:erdos_renyi, :watts_strogatz, :barabasi_albert, :geometric]

# Runs per combination
const RUNS_PER_COMBO = 50

# Output file
const OUTPUT_FILE = "network_topology_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function run_network_topology_sweep()
    results = DataFrame(
        network_type = Symbol[],
        tolerance = Float64[],
        run = Int[],
        dimension = Float64[],
        sigma_ratio = Float64[],
        sigma1 = Float64[],
        sigma2 = Float64[],
        similarity_ratio = Float64[],
        coherence = Int[],
        initial_sigma_ratio = Float64[],
        mean_degree = Float64[],
        degree_std = Float64[]
    )

    total = length(NETWORK_TYPES) * length(TOLERANCES) * RUNS_PER_COMBO

    @showprogress "Network topology sweep: " for net_type in NETWORK_TYPES
        for tol in TOLERANCES
            for run in 1:RUNS_PER_COMBO
                seed = hash((net_type, tol, run)) % 1000000

                config = SimulationConfig(
                    total_agents = 1000,
                    group1_tolerance = tol,
                    group2_tolerance = tol,
                    network_type = net_type,
                    seed = seed,
                    max_steps = 100
                )

                model = initialize_model(config)

                # Measure initial network properties
                initial_sigmas = get_sigmas(model.social)
                initial_ratio = initial_sigmas[1] / initial_sigmas[2]
                degrees = degree(model.social)

                # Run simulation
                run_simulation!(model)

                # Measure final network properties
                final_sigmas = get_sigmas(model.social)
                final_ratio = final_sigmas[1] / final_sigmas[2]
                dim = d_elbow(final_sigmas)

                # Compute similarity
                stats = model.stats
                similarity = stats.similarity_sum / config.total_agents

                push!(results, (
                    net_type,
                    tol,
                    run,
                    dim,
                    final_ratio,
                    final_sigmas[1],
                    final_sigmas[2],
                    similarity,
                    stats.coherence,
                    initial_ratio,
                    mean(degrees),
                    std(degrees)
                ))
            end
        end
    end

    return results
end

# ============================================================================
# MAIN
# ============================================================================

println("Starting network topology sweep experiment...")
println("Network types: ", NETWORK_TYPES)
println("Tolerances: ", TOLERANCES)
println("Runs per combination: ", RUNS_PER_COMBO)
println("Total runs: ", length(NETWORK_TYPES) * length(TOLERANCES) * RUNS_PER_COMBO)
println()

start_time = time()
results = run_network_topology_sweep()
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
    ndf = filter(row -> row.network_type == net_type, results)

    println("  Initial σ₁/σ₂: ", round(mean(ndf.initial_sigma_ratio), digits=2),
            " ± ", round(std(ndf.initial_sigma_ratio), digits=2))
    println("  Mean degree: ", round(mean(ndf.mean_degree), digits=1),
            " ± ", round(mean(ndf.degree_std), digits=1))

    for tol in TOLERANCES[1:2:end]  # Every other tolerance
        tdf = filter(row -> row.tolerance == tol, ndf)
        println("    tol=", tol, ": σ₁/σ₂=", round(mean(tdf.sigma_ratio), digits=2),
                " dim=", round(mean(tdf.dimension), digits=1))
    end
end
