import Pkg

Pkg.activate(".")
Pkg.instantiate()

__proj_directory__ = realpath(dirname(@__FILE__))
@show __proj_directory__

using Agents
using CairoMakie # choosing a plotting backend
using SimpleWeightedGraphs 
using Graphs
using GraphMakie
using SparseArrays: findnz
using Random 
using Revise
using LinearAlgebra
using Random
using DotProductGraphs
using PROPACK
using SparseArrays
using StatsBase
using DataFrames, CSV

import DotProductGraphs: d_elbow

include(joinpath(__proj_directory__,"99_functions.jl"))

@agent SchellingAgent GridAgent{2} begin
    seg::Float64 #the number of neighbours in the same group that the agent needs to be happy
    mood::Bool # whether the agent is happy in its position. (true = happy)
    group::Int # The group of the agent, determines mood as it interacts with neighbors
    
end

function randomExcluded(min,max,excluded)
    k = rand(min:max)
    while k  == excluded
        k = rand(min:max)

    return k

    end

    return k

end

global small_group_size = 0.5 #not used in this model, size is hardcoded in model initialiation
global total_agents = 1000
global steps = 100
global runs = 100
global happy_agents = 0
global similarity_ratio_sum = 0
global tolerances = [0.05,0.1,0.15,0.2,0.25,0.3,0.35,0.4,0.45,0.5,0.55,0.6,0.65,0.7,0.75,0.8,0.85,0.9,0.95,1]


results = Matrix{Float32}(undef,20000,6)

idx = 1
 
#START LOOP HERE
time = @elapsed begin
        for t in tolerances, r in 1:runs
        tolerance = t
        print(tolerance)
        run_id = r
        print(r)

        function initialize(; 
            total_agents = total_agents, 
            griddims = (1000, 1000),#we aren't using the grid so it just needs to be larger than the number of agents 
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
                agent = SchellingAgent(n, (1, 1), tolerance, false, n < total_agents / 2 ? 1 : 2)
                add_agent_single!(agent, model)
            end

            for agent in model.agents
                which_agent = agent.id
                agent_group = agent.group
                for n in 1:80
                    friend = randomExcluded(1,total_agents,which_agent) 
                    add_edge!(model.social, agent.id, friend)
                end

                #if  agent_group > 1
                    #agent.seg = seg_tolerance_2 #changes the second group's tolerance
                # end

                count_neighbours = 0
                count_neighbors_same_group = 0
                count_neighbours_other_group = 0
                which_agent = agent.id
                neigh = Graphs.neighbors(model.social, which_agent)
                for i in neigh
                    if model[which_agent].group == model[i].group
                        count_neighbors_same_group += 1
                        count_neighbours +=1 
                    else 
                        count_neighbours_other_group += 1
                        count_neighbours +=1
                    end
                    #print(count_neighbors_same_group)
                end

                if count_neighbors_same_group/count_neighbours ≥ agent.seg
                    agent.mood = true

                end

            end

            return model
        end

        model = initialize()

        function agent_step!(agent, model)
            count_neighbors_same_group = 0
            count_neighbours_other_group = 0
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
                    count_neighbours_other_group += 1
                end
                #print(count_neighbors_same_group)
            end
            # After counting the neighbors, decide whether or not to move the agent.
            # If count_neighbors_same_group is at least the min_to_be_happy, set the
            # mood to true. Otherwise, move the agent to a random position, and set
            # mood to false.
            if count_neighbors_same_group/count_neighbours ≥ agent.seg
                agent.mood = true
                global happy_agents += 1
            else
                agent.mood = false
                cutoff = rand(neighbours_other_group)
                rem_edge!(model.social, which_agent, cutoff)
                count_neighbours -=1
                count_neighbours_other_group -=1
            end

            while count_neighbours ≤ 40 #half the beginning density
                friend = randomExcluded(1,total_agents,which_agent)    
                add_edge!(model.social, which_agent, friend)
                count_neighbours += 1
            end

            global similarity_ratio_sum = similarity_ratio_sum + (count_neighbors_same_group/count_neighbours)

            return
        end


        for i in 1:steps
            global similarity_ratio_sum = 0
            global happy_agents = 0
            global coherence = 0
            step_number = i
            
            step!(model,agent_step!)
            happy_proportion = happy_agents/ total_agents
            if happy_proportion == 1
                coherence = step_number
                break
            
            end

        end



        similarity_ratio = similarity_ratio_sum/ total_agents
        happy_proportion = happy_agents/ total_agents
        σs = model.social |> get_σs
        results[idx,1] = t
        results[idx,2] = r
        results[idx,3] = σs |> d_elbow
        results[idx,4] = similarity_ratio
        results[idx,5] = happy_proportion
        results[idx,6] = coherence


        global idx += 1
        end
    end

print(time)
sbm_dim = DataFrame(
    results,
    ["Tolerance","Run", "Dimension","Similaity_ratio","Happy_proportion","Coherence"]
)

CSV.write(joinpath(__proj_directory__,"tolerance_results.csv"),sbm_dim)    

