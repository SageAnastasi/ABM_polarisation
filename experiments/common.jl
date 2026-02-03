# Common utilities for running experiment sweeps

using ProgressMeter

# Include the module from src
const PROJECT_ROOT = dirname(dirname(@__FILE__))

function load_module()
    pushfirst!(LOAD_PATH, joinpath(PROJECT_ROOT, "src"))
    @eval using SchellingNetwork
end

"""
    run_tolerance_sweep(tolerances, runs; seed_offset=0, progress=true)

Run experiments sweeping over tolerance values with equal group sizes.

# Arguments
- `tolerances`: Vector of tolerance values to test
- `runs`: Number of runs per tolerance value
- `seed_offset`: Offset added to run number for seeds (default: 0)
- `progress`: Show progress bar (default: true)

Returns a vector of named tuples with results.
"""
function run_tolerance_sweep(
    tolerances::Vector{Float64},
    runs::Int;
    seed_offset::Int = 0,
    progress::Bool = true,
    max_steps::Int = 100
)
    total = length(tolerances) * runs
    results = Vector{NamedTuple}(undef, total)

    iter = progress ? Progress(total, desc = "Tolerance sweep: ") : nothing

    idx = 1
    for tol in tolerances
        for run_id in 1:runs
            config = SimulationConfig(
                total_agents = 1000,
                initial_edges = 80,
                min_neighbors = 40,
                max_steps = max_steps,
                group1_fraction = 0.5,
                group1_tolerance = tol,
                group2_tolerance = tol,
                seed = 125 + run_id + seed_offset
            )

            exp_result = run_single_experiment(config)

            results[idx] = (
                tolerance = tol,
                run = run_id,
                dimension = exp_result.dimension,
                similarity_ratio = exp_result.similarity_ratio,
                happy_proportion = exp_result.happy_proportion,
                coherence = exp_result.coherence
            )

            idx += 1
            progress && next!(iter)
        end
    end

    return results
end

"""
    run_asymmetric_sweep(g1_tolerances, g2_tolerances, runs; seed_offset=0, progress=true)

Run experiments with different tolerances for each group.

# Arguments
- `g1_tolerances`: Vector of tolerance values for group 1
- `g2_tolerances`: Vector of tolerance values for group 2
- `runs`: Number of runs per parameter combination
- `seed_offset`: Offset added to run number for seeds
- `progress`: Show progress bar

Returns a vector of named tuples with results.
"""
function run_asymmetric_sweep(
    g1_tolerances::Vector{Float64},
    g2_tolerances::Vector{Float64},
    runs::Int;
    seed_offset::Int = 0,
    progress::Bool = true,
    max_steps::Int = 1000
)
    total = length(g1_tolerances) * length(g2_tolerances) * runs
    results = Vector{NamedTuple}(undef, total)

    iter = progress ? Progress(total, desc = "Asymmetric sweep: ") : nothing

    idx = 1
    for g1t in g1_tolerances
        for g2t in g2_tolerances
            for run_id in 1:runs
                config = SimulationConfig(
                    total_agents = 1000,
                    initial_edges = 80,
                    min_neighbors = 40,
                    max_steps = max_steps,
                    group1_fraction = 0.5,
                    group1_tolerance = g1t,
                    group2_tolerance = g2t,
                    seed = 125 + run_id + seed_offset
                )

                exp_result = run_single_experiment(config)

                results[idx] = (
                    group1_tolerance = g1t,
                    group2_tolerance = g2t,
                    run = run_id,
                    dimension = exp_result.dimension,
                    similarity_ratio = exp_result.similarity_ratio,
                    happy_proportion = exp_result.happy_proportion,
                    coherence = exp_result.coherence,
                    similarity_group1 = exp_result.similarity_group1,
                    similarity_group2 = exp_result.similarity_group2
                )

                idx += 1
                progress && next!(iter)
            end
        end
    end

    return results
end

"""
    run_group_size_sweep(tolerances, group_fractions, runs; seed_offset=0, progress=true)

Run experiments varying the minority group size.

# Arguments
- `tolerances`: Vector of tolerance values to test
- `group_fractions`: Vector of group 1 (minority) fractions
- `runs`: Number of runs per parameter combination
- `seed_offset`: Offset added to run number for seeds
- `progress`: Show progress bar

Returns a vector of named tuples with results.
"""
function run_group_size_sweep(
    tolerances::Vector{Float64},
    group_fractions::Vector{Float64},
    runs::Int;
    seed_offset::Int = 0,
    progress::Bool = true,
    max_steps::Int = 1000
)
    total = length(tolerances) * length(group_fractions) * runs
    results = Vector{NamedTuple}(undef, total)

    iter = progress ? Progress(total, desc = "Group size sweep: ") : nothing

    idx = 1
    for tol in tolerances
        for frac in group_fractions
            for run_id in 1:runs
                config = SimulationConfig(
                    total_agents = 1000,
                    initial_edges = 80,
                    min_neighbors = 40,
                    max_steps = max_steps,
                    group1_fraction = frac,
                    group1_tolerance = tol,
                    group2_tolerance = tol,
                    seed = 125 + run_id + seed_offset
                )

                exp_result = run_single_experiment(config)

                results[idx] = (
                    tolerance = tol,
                    group1_fraction = frac,
                    run = run_id,
                    dimension = exp_result.dimension,
                    similarity_ratio = exp_result.similarity_ratio,
                    happy_proportion = exp_result.happy_proportion,
                    coherence = exp_result.coherence,
                    similarity_group1 = exp_result.similarity_group1,
                    similarity_group2 = exp_result.similarity_group2
                )

                idx += 1
                progress && next!(iter)
            end
        end
    end

    return results
end

"""
    run_weak_minority_sweep(g1_tolerances, g2_tolerances, minority_fraction, runs; ...)

Run experiments for weak minority preferences paradox.

# Arguments
- `g1_tolerances`: Vector of tolerance values for minority (group 1)
- `g2_tolerances`: Vector of tolerance values for majority (group 2)
- `minority_fraction`: Fraction for minority group (default: 0.15)
- `runs`: Number of runs per parameter combination
- `seed_offset`: Offset added to run number for seeds
- `progress`: Show progress bar

Returns a vector of named tuples with results.
"""
function run_weak_minority_sweep(
    g1_tolerances::Vector{Float64},
    g2_tolerances::Vector{Float64},
    runs::Int;
    minority_fraction::Float64 = 0.15,
    seed_offset::Int = 0,
    progress::Bool = true,
    max_steps::Int = 1000
)
    total = length(g1_tolerances) * length(g2_tolerances) * runs
    results = Vector{NamedTuple}(undef, total)

    iter = progress ? Progress(total, desc = "Weak minority sweep: ") : nothing

    idx = 1
    for g1t in g1_tolerances
        for g2t in g2_tolerances
            for run_id in 1:runs
                config = SimulationConfig(
                    total_agents = 1000,
                    initial_edges = 80,
                    min_neighbors = 40,
                    max_steps = max_steps,
                    group1_fraction = minority_fraction,
                    group1_tolerance = g1t,
                    group2_tolerance = g2t,
                    seed = 125 + run_id + seed_offset
                )

                exp_result = run_single_experiment(config)

                results[idx] = (
                    group1_tolerance = g1t,
                    group2_tolerance = g2t,
                    run = run_id,
                    dimension = exp_result.dimension,
                    similarity_ratio = exp_result.similarity_ratio,
                    happy_proportion = exp_result.happy_proportion,
                    coherence = exp_result.coherence,
                    similarity_group1 = exp_result.similarity_group1,
                    similarity_group2 = exp_result.similarity_group2
                )

                idx += 1
                progress && next!(iter)
            end
        end
    end

    return results
end
