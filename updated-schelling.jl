using Pkg

Pkg.add("Agents")
Pkg.add("CairoMakie")
Pkg.add("SimpleWeightedGraphs")
Pkg.add("Graphs")
Pkg.add("GraphMakie")
Pkg.add("SparseArrays")
Pkg.add("Random")

using Agents # bring package into scope
using CairoMakie # choosing a plotting backend
using SimpleWeightedGraphs 
using Graphs
using GraphMakie
using SparseArrays: findnz
using Random


# make the space the agents will live in
space = GridSpace((20, 20)) # 20×20 grid cells

# make an agent type appropriate to this space and with the
# properties we want based on the ABM we will simulate
@agent struct Schelling(GridAgent{2}) # inherit all properties of `GridAgent{2}`
    mood::Bool = false # all agents are sad by default :'(
    group::Int # the group does not have a default value!
    seg::Float16
end

# define the evolution rule: a function that acts once per step on
# all activated agents (acts in-place on the given agent)
function schelling_step!(agent, model)
    # Here we access a model-level property `min_to_be_happy`
    # This will have an assigned value once we create the model
    count_neighbors_same_group = 0
    count_neighbours = 0
    which_agent = agent.id
    # For each neighbor, get group and compare to current agent's group
    # and increment `count_neighbors_same_group` as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid cell away, which are at most 8.
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
end

# make a container for model-level properties


# Create the central `AgentBasedModel` that stores all simution information
model = StandardABM(
    Schelling, # type of agents
    space; # space they live in
    agent_step! = schelling_step!,
    properties = Dict(:social => SimpleWeightedGraph(300))
)

# populate the model with agents by automatically creating and adding them
# to random position in the space
for n in 1:300
    add_agent_single!(model; group = n < 300 / 2 ? 1 : 2, seg = 0.375)
end

for n in 1:300
    this_agent = n
    for n in 1:8
        friend = rand(1:300)    
        add_edge!(model.social, this_agent, friend)
    end
end

graphplot(model.social) 