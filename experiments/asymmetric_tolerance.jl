#!/usr/bin/env julia
#
# Asymmetric Tolerance Experiment (Section 3.2)
#
# Tests different tolerance values for each group while
# maintaining equal group sizes.
#

import Pkg
Pkg.activate(dirname(dirname(@__FILE__)))

# Add src to load path and load module
pushfirst!(LOAD_PATH, joinpath(dirname(dirname(@__FILE__)), "src"))
using SchellingNetwork

include("common.jl")

# ============================================================================
# EXPERIMENT PARAMETERS - Edit these as needed
# ============================================================================

# Group 1 tolerances (fixed values to compare)
const G1_TOLERANCES = [0.5, 0.9]

# Group 2 tolerances (sweep)
const G2_TOLERANCES = [
    0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5,
    0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0
]

const RUNS_PER_COMBINATION = 100
const MAX_STEPS = 1000
const OUTPUT_FILE = "asymmetric_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function main()
    println("Starting asymmetric tolerance experiment...")
    println("  Group 1 tolerances: ", G1_TOLERANCES)
    println("  Group 2 tolerances: ", length(G2_TOLERANCES), " values")
    println("  Runs per combination: ", RUNS_PER_COMBINATION)
    println("  Max steps: ", MAX_STEPS)
    println()

    # Run the sweep
    time_elapsed = @elapsed begin
        results = run_asymmetric_sweep(
            G1_TOLERANCES,
            G2_TOLERANCES,
            RUNS_PER_COMBINATION;
            max_steps = MAX_STEPS,
            progress = true
        )
    end

    println()
    println("Completed in ", round(time_elapsed, digits = 2), " seconds")

    # Convert to DataFrame and save
    df = results_to_dataframe(results, :asymmetric)

    output_path = joinpath(dirname(dirname(@__FILE__)), OUTPUT_FILE)
    save_results(df, output_path)
    println("Results saved to: ", output_path)

    # Generate figures
    figures_dir = joinpath(dirname(dirname(@__FILE__)), "figures", "asymmetric")
    generate_asymmetric_figures(df, figures_dir)
    println("Figures saved to: ", figures_dir)

    return df
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
