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
    neighbours_ratio = count_neighbours_same_group/count_neighbours
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

    neighbours_ratio = count_neighbours_same_group/count_neighbours
    return count_neighbours_same_group/count_neighbours
end

function is_happy(happyness, segregation_threshold)
    happyness > segregation_threshold
end

function schelling_step!(agent, model)
    count_neighbours_same_group = 0
    count_neighbours = 0
    which_agent = agent.id
    
    happyness = compute_happyness_discrete(model.social,which_agent)
    #COMPUTE IF AGENT IS HAPPY
    if is_happy(happyness,agent.seg) = true
        agent.mood = true
    else
        agent.mood = false
    end

    #IF AGENT IS NOT HAPPY BREAK LINK
    if agent.mood = false

        #MAKE NEW LINK BREAKING BEHAVIOUR
        #go through and get group for every friend, then find most different friends and randomly break from among them
        #max_value, index = findmax(arr) or min_value for the experimental friender

    end

    

    #IF AGENT HAS TOO FEW LINKS MAKE NEW

    while length(Graphs.neighbors(model.social, which_agent) < 10

    end
    