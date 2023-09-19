cd("C:\\Users\\admin\\Documents\\Julia")

import Pkg
Pkg.add("Agents")
Pkg.add("Graphs")
Pkg.add("SimpleWeightedGraphs")
Pkg.add("SparseArrays")
Pkg.add("Random")
Pkg.add("CairoMakie")

using Agents
using SimpleWeightedGraphs
using Graphs
using SparseArrays: findnz
using Random: MersenneTwister

@agent SchellingAgent GridAgent{2} begin
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    seg::Int
end

using Random # for reproducibility
function initialize(; total_agents = 320, griddims = (20, 20), seed = 125)
    space = GridSpaceSingle(griddims, periodic = false)
    rng = Random.Xoshiro(seed)
    model = UnremovableABM(
        SchellingAgent, space;
        rng, scheduler = Schedulers.Randomly()
        properties = Dict(
            :friends => SimpleWeightedDiGraph(total_agents)
    )
    )
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:total_agents
        agent = SchellingAgent(n, (1, 1), false, n < total_agents / 2 ? 1 : 2,rand(1:8))
        add_agent_single!(agent, model)
    end
    return model
end

model = initialize()

function agent_step!(agent, model)
    count_neighbors_same_group = 0
    # For each neighbor, get group and compare to current agent's group
    # and increment `count_neighbors_same_group` as appropriately.
    # Here `nearby_agents` (with default arguments) will provide an iterator
    # over the nearby agents one grid point away, which are at most 8.
    for neighbor in nearby_agents(agent, model)
        if agent.group == neighbor.group
            count_neighbors_same_group += 1
        end
    end
    # After counting the neighbors, decide whether or not to move the agent.
    # If count_neighbors_same_group is at least the min_to_be_happy, set the
    # mood to true. Otherwise, move the agent to a random position, and set
    # mood to false.
    if count_neighbors_same_group ≥ agent.seg
        agent.mood = true
    else
        agent.mood = false
        move_agent_single!(agent, model)
    end
    return
end

using CairoMakie # choosing a plotting backend

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect
figure, _ = abmplot(model; ac = groupcolor, am = groupmarker, as = 10)
figure # returning the figure displays it