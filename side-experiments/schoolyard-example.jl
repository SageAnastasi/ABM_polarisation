using Agents
using SimpleWeightedGraphs: SimpleWeightedDiGraph # will make social network
using SparseArrays: findnz                        # for social network connections
using Random: MersenneTwister                     # reproducibility

const Student = ContinuousAgent{2}

function schoolyard(;
    numStudents = 50,
    teacher_attractor = 0.15,
    noise = 0.1,
    max_force = 1.7,
    spacing = 4.0,
    seed = 6998,
    velocity = (0, 0),
)
    model = ABM(
        Student,
        ContinuousSpace((100, 100); spacing=spacing, periodic=false);
        properties = Dict(
            :teacher_attractor => teacher_attractor,
            :noise => noise,
            :buddies => SimpleWeightedDiGraph(numStudents),
            :max_force => max_force,
        ),
        rng = MersenneTwister(seed)
    )
    for student in 1:numStudents
        # Students begin near the school building
        position = model.space.extent .* 0.5 .+ Tuple(rand(model.rng, 2)) .- 0.5
        add_agent!(position, model, velocity)

        # Add one friend and one foe to the social network
        friend = rand(model.rng, filter(s -> s != student, 1:numStudents))
        add_edge!(model.buddies, student, friend, rand(model.rng))
        foe = rand(model.rng, filter(s -> s != student, 1:numStudents))
        add_edge!(model.buddies, student, foe, -rand(model.rng))
    end
    model
end

distance(pos) = sqrt(pos[1]^2 + pos[2]^2)
scale(L, force) = (L / distance(force)) .* force

function agent_step!(student, model)
    # place a teacher in the center of the yard, so we don’t go too far away
    teacher = (model.space.extent .* 0.5 .- student.pos) .* model.teacher_attractor

    # add a bit of randomness
    noise = model.noise .* (Tuple(rand(model.rng, 2)) .- 0.5)

    # Adhere to the social network
    network = model.buddies.weights[student.id, :]
    tidxs, tweights = findnz(network)
    network_force = (0.0, 0.0)
    for (widx, tidx) in enumerate(tidxs)
        buddiness = tweights[widx]
        force = (student.pos .- model[tidx].pos) .* buddiness
        if buddiness >= 0
            # The further I am from them, the more I want to go to them
            if distance(force) > model.max_force # I'm far enough away
                force = scale(model.max_force, force)
            end
        else
            # The further I am away from them, the better
            if distance(force) > model.max_force # I'm far enough away
                force = (0.0, 0.0)
            else
                L = model.max_force - distance(force)
                force = scale(L, force)
            end
        end
        network_force = network_force .+ force
    end

    # Add all forces together to assign the students next position
    new_pos = student.pos .+ noise .+ teacher .+ network_force
    move_agent!(student, new_pos, model)
end