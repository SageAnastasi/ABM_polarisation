@@ -1,20 +1,15 @@
cd("C:\\Users\\admin\\Documents\\GitHub\\ABM_polarisation")

import Pkg
#Pkg.add("Agents")
#Pkg.add("Graphs")
#Pkg.add("SimpleWeightedGraphs")
#Pkg.add("SparseArrays")
#Pkg.add("Random")
#Pkg.add("Makie")
#Pkg.add("GraphMakie")
#Pkg.add("InteractiveDynamics")

Pkg.activate(".")
Pkg.instantiate()

using Agents
using CairoMakie # choosing a plotting backend
using SimpleWeightedGraphs 
using Graphs
using GraphMakie
using SparseArrays: findnz
using Random: MersenneTwister
using Random # for reproducibility
using InteractiveDynamics

@agent SchellingAgent GridAgent{2} begin
@ -24,7 +19,6 @@ using InteractiveDynamics
    
end

using Random # for reproducibility
function initialize(; 
    total_agents = 320, 
    griddims = (20, 20), 
@ -33,7 +27,7 @@ function initialize(;
    space = GridSpaceSingle(griddims, periodic = false)
    properties = Dict(:social => SimpleWeightedGraph(total_agents))
    rng = Random.Xoshiro(seed)
    model = ABM(
    model = UnremovableABM(
        SchellingAgent, space;
        properties, rng, scheduler = Schedulers.Randomly()
    )
@ -43,11 +37,21 @@ function initialize(;
        agent = SchellingAgent(n, (1, 1), 3, false, n < total_agents / 2 ? 1 : 2)
        add_agent_single!(agent, model)
    end

    # intialise the graph adding an edge to spatial neighbors
    for agent in model.agents
        for neighbor in nearby_agents(agent, model)
                add_edge!(model.social, agent.id, neighbor.id)
        end
    end

    return model
end

model = initialize()



function agent_step!(agent, model)
    count_neighbors_same_group = 0
    # For each neighbor, get group and compare to current agent's group
@ -76,7 +80,7 @@ function model_step!(model)
    for agent in allagents(model)
        #check whether the agent has a graph edge with its neighbours, and if not add an edge.
        for neighbor in nearby_agents(agent, model)
            if has_edge(model.social, neighbor, agent) == false
            if has_edge(model.social, neighbor.id, agent.id) == false
                #ERROR: MethodError: Cannot `convert` an object of type SchellingAgent to an object of type Int64
                print("ding!")
                #add_edge!(model.social, i, j)
@ -85,13 +89,10 @@ function model_step!(model)
    end
end

using CairoMakie # choosing a plotting backend

groupcolor(a) = a.group == 1 ? :blue : :orange
groupmarker(a) = a.group == 1 ? :circle : :rect
figure, _ = abmplot(model; ac = groupcolor, am = groupmarker, as = 10)
figure # returning the figure displays it

using GraphMakie
graphplot(model.social) 
