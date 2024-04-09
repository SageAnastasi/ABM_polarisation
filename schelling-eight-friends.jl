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

function schelling_step!(agent, model)
    count_neighbours_same_group = 0
    count_neighbours = 0
    which_agent = agent.id
    
    neigh = Graphs.neighbors(model.social, which_agent)
    neighbours_same_group = []
    neighbours_other_group = []
    for i in neigh
        count_neighbours += 1
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

    while count_neighbours ≤ 8 #each node should have at least 4 friends, this can be disrupted by incoming links being broken
        if length(neighbours_same_group) > 0
            network_link = rand(neighbours_same_group)
            friends_of_friend = Graphs.neighbors(model.social, network_link) 
            friends_of_friend = setdiff(friends_of_friend,which_agent)
            new_friend = rand(friends_of_friend) 
            add_edge!(model.social,which_agent,new_friend)
            count_neighbours +=1    #if there are friends in the same group, select new freind from their friends at random
        else
            random_friend = randomExcluded(1,49,which_agent)
            add_edge!(model.social,which_agent,random_friend)
            count_neighbours +=1    #else select a friend from the whole graph at random
        end
    end
    
    return
end

function initialize(; total_agents = 320, gridsize = (20, 20), seed = 125)
    space = GridSpaceSingle(gridsize; periodic = false)
    properties = Dict(:social => SimpleWeightedGraph(total_agents))
    rng = Xoshiro(seed)
    model = StandardABM(
        SchellingAgent, space;
        agent_step! = schelling_step!, properties, rng,
        container = Vector, # agents are not removed, so we us this
        scheduler = Schedulers.Randomly() # all agents are activated once at random
    )
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model. At the start all agents are unhappy.
    for n in 1:total_agents
        add_agent_single!(model; mood = false, group = n < total_agents / 2 ? 1 : 2, seg = 0.375)
    end

    return model

   

    
end

model = initialize()

function probability_add_edge(which_agent, friending_probability)
    new_prob_friend = rand(1:320)
    prob_of_friend = friending_probability(model[which_agent].group,model[new_prob_friend].group)
    #prob_of_friend = 1 - abs(model[which_agent].group - model[new_prob_friend].group)
    if rand(Bernoulli(prob_of_friend))
        add_edge!()
    end

    # do we want to iterate above until we add something?
end

function defaut_friending_probability(my_group, your_group)
    prob_of_friend = 1 - abs(my_group - your_group)
    return prob_of_friend
end

function experimenting_friending_probability(my_group, your_group)
    prob_of_friend = abs(my_group - your_group)
    return prob_of_friend
end

for n in 1:319 #populate the model with graph edges
    starter_agent = n
    for n in 1:8
        friend = randomExcluded(1,319,starter_agent)
        add_edge!(model.social, starter_agent, friend)
    end
end

graphplot(model.social)

