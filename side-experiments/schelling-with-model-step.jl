cd("C:\\Users\\admin\\Documents\\GitHub\\ABM_polarisation")

import Pkg
Pkg.add("Agents")
Pkg.add("Random")
Pkg.add("Makie")
Pkg.add("InteractiveDynamics")

using Agents
using InteractiveDynamics

space = GridSpaceSingle((10, 10); periodic = false)
using Random: MersenneTwister


@agent SchellingAgent GridAgent{2} begin
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
end

using Random # for reproducibility
function initialize(; total_agents = 320, griddims = (20, 20), min_to_be_happy = 3, seed = 125)
    space = GridSpaceSingle(griddims, periodic = false)
    properties = Dict(:min_to_be_happy => min_to_be_happy)
    rng = Random.Xoshiro(seed)
    model = UnremovableABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.Randomly()
    )
    # populate the model with agents, adding equal amount of the two types of agents
    # at random positions in the model
    for n in 1:total_agents
        agent = SchellingAgent(n, (1, 1), false, n < total_agents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end
    return model
end

model = initialize()

function model_step!(model)
    for agent in allagents(model)
        minhappy = model.min_to_be_happy
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
        if count_neighbors_same_group ≥ minhappy
            agent.mood = true
        else
            agent.mood = false
            move_agent_single!(agent, model)
        end
    end
    
end

using CairoMakie # choosing a plotting backend

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect
figure, _ = Agents.abmplot(model; ac = groupcolor, am = groupmarker, as = 10)
figure 