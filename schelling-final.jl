import Pkg

Pkg.activate(".")
Pkg.instantiate()

__proj_directory__ = realpath(dirname(@__FILE__)*"/..")

using Agents
using CairoMakie # choosing a plotting backend
using SimpleWeightedGraphs 
using Graphs
using GraphMakie
using SparseArrays: findnz
using Random 
using Revise
using LinearAlgebra
using Random
using DotProductGraphs
using PROPACK
using SparseArrays
using StatsBase
using DataFrames, CSV

import DotProductGraphs: d_elbow

include(joinpath(__proj_directory__,"99_functions.jl"))

@agent SchellingAgent GridAgent{2} begin
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    
end

function randomExcluded(min,max,excluded)
    k = rand(min:max)
    while k  == excluded
        k = rand(min:max)

    return k

    end

    return k

end

small_group_size = 0.2 #use a decimal for the percentage of the network
total_agents = 100
seg_tolerance_1 = 0.3
seg_tolerance_2 = 0.5
steps = 10
entries = steps + 1
happy_agents = 0
similarity_ratio = 0
similarity_ratio_sum = 0


function initialize(; 
    total_agents = total_agents, 
    griddims = (1000, 1000),#we aren't using the grid so it just needs to be larger than the number of agents 
    seed = 125
)
    space = GridSpaceSingle(griddims, periodic = false)
    properties = Dict(:social => SimpleWeightedGraph(total_agents))
    rng = Random.Xoshiro(seed)
    model = UnremovableABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.Randomly()
    )
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:total_agents
        agent = SchellingAgent(n, (1, 1), seg_tolerance_1, false, n < total_agents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end

    similarity_ratio_sum = 0

    for agent in model.agents
        which_agent = agent.id
        agent_group = agent.group
        for n in 1:10
            friend = randomExcluded(1,total_agents,which_agent) 
            add_edge!(model.social, agent.id, friend)
        end

        if  agent_group > 1
            agent.seg = seg_tolerance_2 #changes the second group's tolerance
        end

        count_neighbours = 0
        count_neighbors_same_group = 0
        count_neighbours_other_group = 0
        which_agent = agent.id
        neigh = Graphs.neighbors(model.social, which_agent)
        for i in neigh
            if model[which_agent].group == model[i].group
                count_neighbors_same_group += 1
                count_neighbours +=1 
            else 
                count_neighbours_other_group += 1
                count_neighbours +=1
            end
            #print(count_neighbors_same_group)
        end

        if count_neighbors_same_group/count_neighbours ≥ agent.seg
            agent.mood = true
            happy_agents +=1
        end
        similarity_ratio_sum = similarity_ratio_sum + (count_neighbors_same_group/count_neighbours_other_group)

    end
    similarity_ratio = similarity_ratio_sum/total_agents
    happy_proportion = happy_agents/total_agents
    return model
end

model = initialize()

function agent_step!(agent, model)
    count_neighbors_same_group = 0
    count_neighbours_other_group = 0
    count_neighbours = 0
    which_agent = agent.id
    

    # For each neighbor, get group and compare to current agent's group
    # and increment `count_neighbors_same_group` as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid point away, which are at most 8.
    neigh = Graphs.neighbors(model.social, which_agent)
    neighbours_same_group = []
    neighbours_other_group = []
    for i in neigh
        count_neighbours += 1
        if model[which_agent].group == model[i].group
            count_neighbors_same_group += 1
            push!(neighbours_same_group,model[i].id)
        else 
            push!(neighbours_other_group,model[i].id)
            count_neighbours_other_group += 1
        end
        #print(count_neighbors_same_group)
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random position, and set
    # mood to false.
    if count_neighbors_same_group/count_neighbours ≥ agent.seg
        agent.mood = true
        happy_agents += 1
    else
        agent.mood = false
        cutoff = rand(neighbours_other_group)
        rem_edge!(model.social, which_agent, cutoff)
        count_neighbours -=1
        count_neighbours_other_group -=1
    end

    while count_neighbours ≤ 5 #each node should have at least 50 friends, this can be disrupted by incoming links being broken
        friend = randomExcluded(1,total_agents,which_agent)    
        add_edge!(model.social, which_agent, friend)
        count_neighbours += 1
    end

    similarity_ratio_sum = similarity_ratio_sum + (count_neighbors_same_group/count_neighbours_other_group)

    return
end

results = Matrix{Float32}(undef,entries,4)

idx = 0
σs = model.social |> get_σs
results[idx,1] = idx
results[idx,2] = σs |> d_elbow
results[idx,3] = similarity_ratio
results[idx,4] = happy_proportion

for i in steps
    @show idx
    global  idx += 1
    similarity_ratio_sum = 0
    happy_agents = 0
    step!(model,agent!step)
    similarity_ratio = similarity_ratio_sum / total_agents
    happy_proportion = happy_agents / total_agents
    σs = model.social |> get_σs
    results[idx,1] = idx
    results[idx,2] = σs |> r_elbow
    results[idx,3] = similarity_ratio
    results[idx,4] = happy_proportion
end
    
sbm_dim = DataFrame(
    results,
    ["Dimension", "Entropy","Predominance","Cint"]
)

CSV.write(joinpath(__proj_directory__,"Results","sbm_growth_dim.csv"),sbm_dim)    

