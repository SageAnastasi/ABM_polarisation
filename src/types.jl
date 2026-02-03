# Type definitions for Schelling Network ABM

using Agents

"""
    SchellingAgent

Agent in the Schelling segregation model on a social network.

# Fields
- `id::Int`: Unique agent identifier (managed by Agents.jl)
- `seg::Float64`: Segregation tolerance threshold (proportion of same-group neighbors needed to be happy)
- `mood::Bool`: Whether the agent is happy (true) or unhappy (false)
- `group::Int`: Group membership (1 or 2)
"""
@agent struct SchellingAgent(NoSpaceAgent)
    seg::Float64
    mood::Bool
    group::Int
end

"""
    SimulationConfig

Configuration parameters for a Schelling network simulation.

# Fields
- `total_agents::Int`: Total number of agents (default: 1000)
- `initial_edges::Int`: Number of random edges per agent at initialization (default: 80)
- `min_neighbors::Int`: Minimum number of neighbors an agent should maintain (default: 40)
- `max_steps::Int`: Maximum simulation steps before stopping (default: 100)
- `group1_fraction::Float64`: Fraction of agents in group 1 (default: 0.5)
- `group1_tolerance::Float64`: Tolerance threshold for group 1 agents (default: 0.5)
- `group2_tolerance::Float64`: Tolerance threshold for group 2 agents (default: 0.5)
- `seed::Int`: Random seed for reproducibility (default: 125)
- `network_type::Symbol`: Initial network topology (default: :erdos_renyi)
    - `:erdos_renyi` - Random graph, low degree variance
    - `:watts_strogatz` - Small-world (high clustering, short paths)
    - `:barabasi_albert` - Scale-free (power-law degrees, hubs)
    - `:random_regular` - All nodes have same degree
    - `:geometric` - Random geometric graph (2D spatial, local connections)
"""
Base.@kwdef struct SimulationConfig
    total_agents::Int = 1000
    initial_edges::Int = 80
    min_neighbors::Int = 40
    max_steps::Int = 100
    group1_fraction::Float64 = 0.5
    group1_tolerance::Float64 = 0.5
    group2_tolerance::Float64 = 0.5
    seed::Int = 125
    network_type::Symbol = :erdos_renyi
end

"""
    StepStatistics

Mutable statistics accumulated during simulation steps.

# Fields
- `happy_agents::Int`: Count of happy agents in current step
- `similarity_sum::Float64`: Sum of similarity ratios across agents
- `similarity_group1::Float64`: Sum of similarity ratios for group 1
- `similarity_group2::Float64`: Sum of similarity ratios for group 2
- `coherence::Int`: Step number when all agents became happy (0 if not converged)
"""
mutable struct StepStatistics
    happy_agents::Int
    similarity_sum::Float64
    similarity_group1::Float64
    similarity_group2::Float64
    coherence::Int

    StepStatistics() = new(0, 0.0, 0.0, 0.0, 0)
end

"""
    reset!(stats::StepStatistics)

Reset all statistics to zero for a new step.
"""
function reset!(stats::StepStatistics)
    stats.happy_agents = 0
    stats.similarity_sum = 0.0
    stats.similarity_group1 = 0.0
    stats.similarity_group2 = 0.0
    return stats
end

"""
    SimulationResult

Results from a completed simulation run.

# Fields
- `tolerance::Float64`: Tolerance value used (group1 for symmetric, or specific)
- `group1_tolerance::Float64`: Group 1 tolerance
- `group2_tolerance::Float64`: Group 2 tolerance
- `group1_fraction::Float64`: Fraction of agents in group 1
- `run_id::Int`: Run identifier
- `dimension::Float64`: Spectral dimension estimate
- `similarity_ratio::Float64`: Final average similarity ratio
- `similarity_group1::Float64`: Final similarity ratio for group 1
- `similarity_group2::Float64`: Final similarity ratio for group 2
- `happy_proportion::Float64`: Proportion of happy agents at end
- `coherence::Int`: Steps to reach full happiness (0 if not reached)
"""
struct SimulationResult
    tolerance::Float64
    group1_tolerance::Float64
    group2_tolerance::Float64
    group1_fraction::Float64
    run_id::Int
    dimension::Float64
    similarity_ratio::Float64
    similarity_group1::Float64
    similarity_group2::Float64
    happy_proportion::Float64
    coherence::Int
end
