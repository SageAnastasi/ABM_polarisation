import Pkg

Pkg.activate(".")
Pkg.instantiate()

using Agents
using CairoMakie # choosing a plotting backend
using SimpleWeightedGraphs 
using Graphs
using GraphMakie
using SparseArrays: findnz
using Random # for reproducibility
#using InteractiveDynamics -- no longer needed, abmplot is in Agents

function randomExcluded(min, max, excluded)
      
    n = rand(min:max)
    if (n ≥ excluded) 
        n += 1
   #else
    #    n += 0
    end

    # return n

end #function needed for generating random graph edges without node selecting itself

@agent struct SchellingAgent(GridAgent{2}) begin
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    # friending_prob_function 
end
end

function compute_happyness_discrete(model.social, which_agent)
    neigh = Graphs.neighbors(model.social, which_agent)
    count_neighbours_same_group = 0
    for i in neigh
        count_neighbours += 1
        if model[which_agent].group == model[i].group
            count_neighbours_same_group += 1
        end
    end

    return count_neighbours_same_group/count_neighbours
end

function compute_happyness_continuous(model.social, which_agent)
    neigh = Graphs.neighbors(model.social, which_agent)
    count_neighbours_same_group = 0
    for i in neigh
        count_neighbours += 1
        dist_to_neigh = abs(model[which_agent].group - model[i].group)
        count_neighbours_same_group += (1 - dist_to_neigh)
        end
    end

    return count_neighbours_same_group/count_neighbours
end

function is_happy(happyness, segregation_threshold)
    happyness > segregation_threshold
end

