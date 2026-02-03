# I/O utilities for Schelling Network ABM

using DataFrames
using CSV

# Column names for different experiment types
const TOLERANCE_COLUMNS = [
    "tolerance",
    "run",
    "dimension",
    "similarity_ratio",
    "happy_proportion",
    "coherence"
]

const ASYMMETRIC_COLUMNS = [
    "group1_tolerance",
    "group2_tolerance",
    "run",
    "dimension",
    "similarity_ratio",
    "happy_proportion",
    "coherence",
    "group1_similarity",
    "group2_similarity"
]

const GROUP_SIZE_COLUMNS = [
    "tolerance",
    "group1_fraction",
    "run",
    "dimension",
    "similarity_ratio",
    "happy_proportion",
    "coherence",
    "group1_similarity",
    "group2_similarity"
]

const WEAK_MINORITY_COLUMNS = [
    "group1_tolerance",
    "group2_tolerance",
    "run",
    "dimension",
    "similarity_ratio",
    "happy_proportion",
    "coherence",
    "group1_similarity",
    "group2_similarity"
]

"""
    results_to_dataframe(results::Vector, experiment_type::Symbol)

Convert a vector of result tuples to a DataFrame with appropriate column names.

# Arguments
- `results`: Vector of named tuples from experiments
- `experiment_type`: One of :tolerance, :asymmetric, :group_size, :weak_minority
"""
function results_to_dataframe(results::Vector, experiment_type::Symbol)
    columns = if experiment_type == :tolerance
        TOLERANCE_COLUMNS
    elseif experiment_type == :asymmetric
        ASYMMETRIC_COLUMNS
    elseif experiment_type == :group_size
        GROUP_SIZE_COLUMNS
    elseif experiment_type == :weak_minority
        WEAK_MINORITY_COLUMNS
    else
        error("Unknown experiment type: " * string(experiment_type))
    end

    # Build matrix from results
    nrows = length(results)
    ncols = length(columns)
    data = Matrix{Float64}(undef, nrows, ncols)

    for (i, r) in enumerate(results)
        if experiment_type == :tolerance
            data[i, :] = [
                r.tolerance,
                r.run,
                r.dimension,
                r.similarity_ratio,
                r.happy_proportion,
                r.coherence
            ]
        elseif experiment_type == :asymmetric
            data[i, :] = [
                r.group1_tolerance,
                r.group2_tolerance,
                r.run,
                r.dimension,
                r.similarity_ratio,
                r.happy_proportion,
                r.coherence,
                r.similarity_group1,
                r.similarity_group2
            ]
        elseif experiment_type == :group_size
            data[i, :] = [
                r.tolerance,
                r.group1_fraction,
                r.run,
                r.dimension,
                r.similarity_ratio,
                r.happy_proportion,
                r.coherence,
                r.similarity_group1,
                r.similarity_group2
            ]
        elseif experiment_type == :weak_minority
            data[i, :] = [
                r.group1_tolerance,
                r.group2_tolerance,
                r.run,
                r.dimension,
                r.similarity_ratio,
                r.happy_proportion,
                r.coherence,
                r.similarity_group1,
                r.similarity_group2
            ]
        end
    end

    return DataFrame(data, columns)
end

"""
    save_results(df::DataFrame, filename::String)

Save a DataFrame to CSV file.
"""
function save_results(df::DataFrame, filename::String)
    CSV.write(filename, df)
    return filename
end

"""
    load_results(filename::String)

Load results from a CSV file into a DataFrame.
"""
function load_results(filename::String)
    return CSV.read(filename, DataFrame)
end

"""
    append_results(df::DataFrame, filename::String)

Append DataFrame rows to an existing CSV file.
"""
function append_results(df::DataFrame, filename::String)
    CSV.write(filename, df; append = true)
    return filename
end
