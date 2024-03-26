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

@agent struct Schelling(GridAgent{2}) begin
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    
end
end

function initialize(; 
    total_agents = 320, 
    griddims = (20, 20), 
    seed = 125
)
    space = GridSpaceSingle(griddims, periodic = false)
    properties = Dict(:social => SimpleWeightedGraph(total_agents))
    rng = Random.Xoshiro(seed)
    model = StandardABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.Randomly()
    )
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:total_agents
        agent = SchellingAgent(n, (1, 1), 0.375, false, n < total_agents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end

    for agent in model.agents
        for n in 1:8
            friend = rand(1:320)    
            add_edge!(model.social, agent.id, friend)
        end
    end

    return model
end

model = initialize()



function agent_step!(agent, model)
    count_neighbors_same_group = 0
    count_neighbours = 0
    which_agent = agent.id
    

    # For each neighbor, get group and compare to current agent's group
    # and increment `count_neighbors_same_group` as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid point away, which are at most 8.
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
        #print(count_neighbors_same_group)
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random position, and set
    # mood to false.
    if count_neighbors_same_group/count_neighbours ≥ agent.seg
        agent.mood = true
    else
        agent.mood = false
        cutoff = rand(enemies)
        rem_edge!(model.social, which_agent, cutoff)
        #create a for i in neight get friends of friends then link to friend in same group
        #move_agent_single!(agent, model)
        count_neighbours -=1
    end

    while count_neighbours ≤ 8 #each node should have at least 8 friends, this can be disrupted by incoming links being broken
        networkLink = rand(friendlies)
        FoF = Graphs.neighbors(model.social, networkLink)
        newFriend = rand(FoF)
        add_edge!(model.social,which_agent,newFriend)
    end

    return
    print(debug)
end


graphplot(model.social)

