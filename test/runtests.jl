using Test

# Add src to load path
pushfirst!(LOAD_PATH, joinpath(dirname(dirname(@__FILE__)), "src"))
using SchellingNetwork

@testset "SchellingNetwork" begin

    @testset "Types" begin
        # Test SimulationConfig defaults
        config = SimulationConfig()
        @test config.total_agents == 1000
        @test config.initial_edges == 80
        @test config.min_neighbors == 40
        @test config.max_steps == 100
        @test config.group1_fraction == 0.5
        @test config.group1_tolerance == 0.5
        @test config.group2_tolerance == 0.5
        @test config.seed == 125

        # Test StepStatistics
        stats = StepStatistics()
        @test stats.happy_agents == 0
        @test stats.similarity_sum == 0.0
        @test stats.coherence == 0

        # Test reset!
        stats.happy_agents = 100
        stats.similarity_sum = 50.0
        reset!(stats)
        @test stats.happy_agents == 0
        @test stats.similarity_sum == 0.0
    end

    @testset "Model Initialization" begin
        config = SimulationConfig(
            total_agents = 100,
            initial_edges = 10,
            seed = 42
        )
        model = initialize_model(config)

        # Check agent count
        @test nagents(model) == 100

        # Check group assignment
        agents = collect(allagents(model))
        group1_count = count(a -> a.group == 1, agents)
        group2_count = count(a -> a.group == 2, agents)
        @test group1_count == 50  # 0.5 * 100
        @test group2_count == 50

        # Check tolerance assignment
        for agent in agents
            @test agent.seg == 0.5  # default tolerance
        end

        # Check social graph exists
        @test nv(model.social) == 100
        @test ne(model.social) > 0  # Should have edges
    end

    @testset "random_excluded" begin
        using Random
        rng = Xoshiro(123)

        # Test that excluded value is never returned
        for _ in 1:100
            val = random_excluded(rng, 1, 10, 5)
            @test val != 5
            @test 1 <= val <= 10
        end

        # Test edge cases
        val = random_excluded(rng, 1, 2, 1)
        @test val == 2

        val = random_excluded(rng, 1, 2, 2)
        @test val == 1
    end

    @testset "Simulation Step" begin
        config = SimulationConfig(
            total_agents = 50,
            initial_edges = 5,
            min_neighbors = 3,
            max_steps = 5,
            seed = 42
        )
        model = initialize_model(config)

        # Run a few steps
        initial_edges = ne(model.social)
        run_simulation!(model; max_steps = 3)

        # Stats should be updated
        @test model.stats.happy_agents >= 0
        @test model.stats.similarity_sum >= 0.0
    end

    @testset "Analysis Functions" begin
        using Graphs
        using SimpleWeightedGraphs

        # Create a simple test graph
        g = SimpleWeightedGraph(10)
        for i in 1:9
            add_edge!(g, i, i + 1)
        end
        add_edge!(g, 1, 10)  # Close the cycle

        # Test get_sigmas runs without error
        sigmas = get_sigmas(g)
        @test length(sigmas) > 0
        @test all(s -> s >= 0, sigmas)

        # Test compute_dimension
        dim = compute_dimension(g)
        @test dim >= 0

        # Test blocks
        b = blocks(0.3)
        @test sum(b) == 1000
        @test b[1] == 300
        @test b[2] == 700
    end

    @testset "Single Experiment" begin
        config = SimulationConfig(
            total_agents = 50,
            initial_edges = 5,
            min_neighbors = 3,
            max_steps = 10,
            seed = 42
        )

        result = run_single_experiment(config)

        # Check result structure
        @test haskey(result, :dimension)
        @test haskey(result, :similarity_ratio)
        @test haskey(result, :happy_proportion)
        @test haskey(result, :coherence)

        # Check value ranges
        @test 0.0 <= result.similarity_ratio <= 1.0
        @test 0.0 <= result.happy_proportion <= 1.0
        @test result.coherence >= 0
        @test result.dimension >= 0
    end

    @testset "I/O Functions" begin
        # Test results_to_dataframe for tolerance type
        results = [
            (tolerance = 0.5, run = 1, dimension = 2.0, similarity_ratio = 0.6,
             happy_proportion = 1.0, coherence = 10),
            (tolerance = 0.5, run = 2, dimension = 2.1, similarity_ratio = 0.65,
             happy_proportion = 1.0, coherence = 12)
        ]

        df = results_to_dataframe(results, :tolerance)
        @test size(df, 1) == 2
        @test size(df, 2) == 6
        @test "tolerance" in names(df)
        @test "similarity_ratio" in names(df)  # Fixed typo from original
    end

end
