#!/usr/bin/env julia
#
# Tolerance Sweep Experiment (Section 3.1)
#
# Varies segregation tolerance symmetrically for both groups
# with equal group sizes (50/50 split).
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

const TOLERANCES = [
    0.05, 0.1, 0.15, 0.2, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5,
    0.55, 0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 1.0
]

const RUNS_PER_TOLERANCE = 100
const MAX_STEPS = 100
const OUTPUT_FILE = "tolerance_results.csv"

# ============================================================================
# RUN EXPERIMENT
# ============================================================================

function main()
    println("Starting tolerance sweep experiment...")
    println("  Tolerances: ", length(TOLERANCES), " values")
    println("  Runs per tolerance: ", RUNS_PER_TOLERANCE)
    println("  Max steps: ", MAX_STEPS)
    println()

    # Run the sweep
    time_elapsed = @elapsed begin
        results = run_tolerance_sweep(
            TOLERANCES,
            RUNS_PER_TOLERANCE;
            max_steps = MAX_STEPS,
            progress = true
        )
    end

    println()
    println("Completed in ", round(time_elapsed, digits = 2), " seconds")

    # Convert to DataFrame and save
    df = results_to_dataframe(results, :tolerance)

    output_path = joinpath(dirname(dirname(@__FILE__)), OUTPUT_FILE)
    save_results(df, output_path)
    println("Results saved to: ", output_path)

    # Generate figures
    figures_dir = joinpath(dirname(dirname(@__FILE__)), "figures", "tolerance")
    generate_tolerance_figures(df, figures_dir)
    println("Figures saved to: ", figures_dir)

    return df
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
