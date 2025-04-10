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

global small_group = [0.15] #use a decimal for the percentage of the network
global total_agents = 1000
global steps = 1000
global runs = 100
global happy_agents = 0
global similarity_ratio_sum = 0
global group1_tolerance = [0.2]
global group2_tolerance = [0.9]


#global group1_tolerance = [0.5,0.5,0.9,0.9,0.15,0.15,0.2,0.2]
#global group2_tolerance = [0.5,0.9,0.5,0.9,0.85,0.9,0.85,0.9] run by individual entry so that the data saves correctly

idx = 1
 
#START LOOP HERE
time = @elapsed begin
        for t in group1_tolerance, g in group2_tolerance, r in 1:runs
        g1_t = t
        run_id = r
        g2_t = g
        results = []

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
                agent = SchellingAgent(n, (1, 1), g1_t, false, n ≤ total_agents * 0.15 ? 1 : 2)
                add_agent_single!(agent, model)
            end

            for agent in model.agents
                which_agent = agent.id
                agent_group = agent.group
                for n in 1:80
                    friend = randomExcluded(1,total_agents,which_agent) 
                    add_edge!(model.social, agent.id, friend)
                end

                if  agent_group > 1
                    agent.seg = g2_t #changes the second group's tolerance
                    print(agent.seg)
                end

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

            if agent.group == 1
                global similarity_group_1 =  similarity_group_1 + (count_neighbors_same_group/count_neighbours)
             elseif agent.group == 2  
                global similarity_group_2 =  similarity_group_2 + (count_neighbors_same_group/count_neighbours)
            end
 
             global similarity_ratio_sum = similarity_ratio_sum + (count_neighbors_same_group/count_neighbours)

            return
        end


        for i in 1:steps
            global similarity_ratio_sum = 0
            global happy_agents = 0
            global coherence = 0
            global similarity_group_1 = 0
            global similarity_group_2 = 0
            step_number = i
            
            step!(model,agent_step!)
            happy_proportion = happy_agents/ total_agents
            if happy_proportion == 1
                coherence = step_number
                break
            
            end

        end

        similarity_ratio = similarity_ratio_sum/total_agents
        similarity_ratio_1 = similarity_group_1/(total_agents*0.15)
        similarity_ratio_2 = similarity_group_2/(total_agents*(1-0.15))
        happy_proportion = happy_agents/ total_agents
        σs = model.social |> get_σs

        push!(results,t)
        push!(results,g)
        push!(results,r)
        push!(results,σs |> d_elbow)
        push!(results, similarity_ratio)
        push!(results,happy_proportion)
        push!(results, coherence)
        push!(results,similarity_ratio_1)
        push!(results,similarity_ratio_2)



        open("data.csv", "a") do io
            df = DataFrame(permutedims(results), :auto)
            CSV.write(io, df, header=false,append=true)
        end

        print(idx)
        global idx += 1
        end
    end