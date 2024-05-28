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

function defaut_friending_probability(my_group, your_group)
    prob_of_friend = 1 - abs(my_group - your_group)
    return prob_of_friend
end

function experimenting_friending_probability(my_group, your_group)
    prob_of_friend = abs(my_group - your_group)
    return prob_of_friend
end


function probability_add_edge(which_agent, friending_probability)
    new_prob_friend = rand(1:320)
    prob_of_friend = friending_probability(model[which_agent].group,model[new_prob_friend].group)
    #prob_of_friend = 1 - abs(model[which_agent].group - model[new_prob_friend].group)
    if rand(Bernoulli(prob_of_friend))
        add_edge!()
    end

    # do we want to iterate above until we add something?
end

function defaut_unfriending_probability(my_group, your_group)
    prob_of_friend = 1 - abs(my_group - your_group)
    return prob_of_friend
end

function experimenting_unfriending_probability(my_group, your_group)
    prob_of_friend = abs(my_group - your_group)
    return prob_of_friend
end


function probability_remove_edge(which_agent, friending_probability)

    neigh = Graphs.neighbors(model.social, which_agent)
    for i in neigh
        #compute friending probability
        #append friending probability to each node
        #if discrete select from group 0 friends at random
        #if continuous ???
        #break link between that node and which_agent
        if model[which_agent].group == model[i].group
            count_neighbours_same_group += 1
            push!(neighbours_same_group,model[i].id)
        else 
            push!(neighbours_other_group,model[i].id)
        end
    end #keeping track of the agent's same and different group links to select from later

    if count_neighbours_same_group/count_neighbours ≥ agent.seg
        agent.mood = true
    else
        agent.mood = false
        cutoff = rand(neighbours_other_group)
        rem_edge!(model.social, which_agent, cutoff)
        count_neighbours -=1
    end #if unhappy, cut off a link from a different group

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
    