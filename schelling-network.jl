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

total_agents = 10000
seg_tolerance_1 = 0.3
seg_tolerance_2 = 0.5



@agent SchellingAgent GridAgent{2} begin
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    
end

function randomExcluded(min,max,excluded)
    n = rand(min:max)
    while n  == excluded
        n = rand(min:max)

    return n

    end

end




function initialize(; 
    total_agents = total_agents, 
    griddims = (1000, 1000), 
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

    for agent in model.agents
        which_agent = agent.id
        agent_group = agent.group
        for n in 100
            friend = randomExcluded(1,99,which_agent) #randomexcluded will push    
            add_edge!(model.social, agent.id, friend)
        end

        if  agent_group > 1
            agent.seg = seg_tolerance_2 #changes the second group's tolerance
        end
        print(agent.seg)
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
    neighbours_same_group = []
    neighbours_other_group = []
    for i in neigh
        count_neighbours += 1
        if model[which_agent].group == model[i].group
            count_neighbors_same_group += 1
            push!(neighbours_same_group,model[i].id)
        else 
            push!(neighbours_other_group,model[i].id)
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
        cutoff = rand(neighbours_other_group)
        rem_edge!(model.social, which_agent, cutoff)
        #create a for i in neight get friends of friends then link to friend in same group
        #move_agent_single!(agent, model)
        count_neighbours -=1
    end

    while count_neighbours ≤ 4 #each node should have at least 8 friends, this can be disrupted by incoming links being broken
        friend = randomExcluded(1,26,which_agent)    
        add_edge!(model.social, agent.id, friend)
        count_neighbours += 1
    end

    return
    print(debug)
end



graphplot(model.social) 

