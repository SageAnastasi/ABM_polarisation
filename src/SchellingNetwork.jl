"""
    SchellingNetwork

Agent-Based Model (ABM) simulating Schelling segregation dynamics on social network graphs.

Supports the paper "Schelling segregation dynamics in densely-connected social network graphs"
by Sage Anastasi & Giulio Dalla Riva.

## Quick Start

```julia
using SchellingNetwork

# Create a configuration
config = SimulationConfig(
    total_agents = 1000,
    group1_tolerance = 0.5,
    group2_tolerance = 0.5,
    max_steps = 100
)

# Run a single experiment
result = run_single_experiment(config)

# Or run parameter sweeps using the experiments
```

## Module Structure

- `types.jl`: Agent, configuration, and result type definitions
- `model.jl`: Model initialization
- `simulation.jl`: Step functions and simulation runners
- `analysis.jl`: Metrics computation (spectral dimension, etc.)
- `io.jl`: CSV reading/writing utilities
- `visualization.jl`: CairoMakie plotting functions
"""
module SchellingNetwork

# External dependencies
using Agents
using CairoMakie
using CSV
using DataFrames
using DotProductGraphs
using GraphMakie
using Graphs
using LinearAlgebra
using PROPACK
using ProgressMeter
using Random
using SimpleWeightedGraphs
using SparseArrays

# Import specific functions
import DotProductGraphs: d_elbow
import Agents: nagents, allagents

# Include submodules in dependency order
include("types.jl")
include("analysis.jl")
include("model.jl")
include("simulation.jl")
include("io.jl")
include("visualization.jl")
include("network_visualization.jl")

# Export types
export SchellingAgent
export SimulationConfig
export StepStatistics
export SimulationResult

# Export model functions
export initialize_model
export random_excluded

# Export simulation functions
export schelling_step!
export run_simulation!
export run_single_experiment
export reset!

# Export analysis functions
export get_giant_component
export get_sigmas
export participation_entropy
export spectral_gap
export compute_dimension
export blocks
export adjm_from_edge_list

# Export I/O functions
export results_to_dataframe
export save_results
export load_results
export append_results
export TOLERANCE_COLUMNS
export ASYMMETRIC_COLUMNS
export GROUP_SIZE_COLUMNS
export WEAK_MINORITY_COLUMNS

# Export visualization functions
export plot_tolerance_stabilisation
export plot_tolerance_dimension
export plot_tolerance_similarity
export plot_comparison_grid
export plot_asymmetric_similarity
export plot_group_size_metrics
export plot_weak_minority_paradox
export generate_tolerance_figures
export generate_asymmetric_figures
export generate_group_size_figures
export generate_weak_minority_figures

# Export network visualization functions
export NetworkSnapshot
export run_simulation_with_snapshots!
export take_snapshot
export plot_network_snapshot
export plot_network_evolution
export save_network_evolution
export get_edge_colors

# Re-export useful Agents.jl functions
export nagents, allagents

# Re-export Makie save function
import CairoMakie: save
export save

end # module
