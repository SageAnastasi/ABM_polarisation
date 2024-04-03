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
    else
        n += 0
    end

end #function needed for generating random graph edges without node selecting itself

@agent struct SchellingAgent(GridAgent{2}) begin
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    
end
end

function schelling_step!(agent, model)
    count_neighbors_same_group = 0
    count_neighbours = 0
    which_agent = agent.id
    
    neigh = Graphs.neighbors(model.social, which_agent)
    friendlies = []
    enemies = []
    for i in neigh
        count_neighbours += 1
        if model[which_agent].group == model[i].group
            count_neighbors_same_group += 1
            push!(friendlies,model[i].id)
        else 
            push!(enemies,model[i].id)
        end
    end #keeping track of the agent's same and different group links to select from later

    if count_neighbors_same_group/count_neighbours ≥ agent.seg
        agent.mood = true
    else
        agent.mood = false
        cutoff = rand(enemies)
        rem_edge!(model.social, which_agent, cutoff)
        count_neighbours -=1
    end #if unhappy, cut off a link from a different group

    while count_neighbours ≤ 4 #each node should have at least 4 friends, this can be disrupted by incoming links being broken
        if length(friendlies) > 0
            networkLink = rand(friendlies)
            FoF = Graphs.neighbors(model.social, networkLink) 
            FoF = setdiff(FoF,which_agent)
            newFriend = rand(FoF) 
            add_edge!(model.social,which_agent,newFriend)
            count_neighbours +=1    #if there are friends in the same group, select new freind from their friends at random
        else
            random_friend = randomExcluded(1,49,which_agent)
            add_edge!(model.social,which_agent,random_friend)
            count_neighbours +=1    #else select a friend from the whole graph at random
        end
    end
    
    return
end

function initialize(; total_agents = 50, gridsize = (20, 20), seed = 125)
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
        add_agent_single!(model; mood = false, group = n < total_agents / 2 ? 1 : 2, seg = 0.2)
    end

    return model

   

    
end

model = initialize()

for n in 1:50 #populate the model with graph edges
    starter_agent = n
    for n in 1:4
        friend = randomExcluded(1,49,starter_agent)
        add_edge!(model.social, starter_agent, friend)
    end
end

graphplot(model.social)

