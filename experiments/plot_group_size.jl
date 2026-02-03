# Plot group size results - focusing on dimension vs group size
# Tests whether unequal group sizes prevent polarization

using Pkg
Pkg.activate(".")

using CSV
using DataFrames
using CairoMakie
using Statistics

# Load data
df = CSV.read("group_size_network_results.csv", DataFrame)

# Network types and labels
network_types = ["erdos_renyi", "watts_strogatz", "barabasi_albert", "geometric"]
network_labels = ["Erdős-Rényi", "Watts-Strogatz", "Barabási-Albert", "Geometric"]
colors = [:steelblue, :coral, :green, :purple]

# Get unique values
tolerances = sort(unique(df.tolerance))
fractions = sort(unique(df.group1_fraction))

# Summarize by network, tolerance, fraction
function summarize_group_size(df, col)
    rows = NamedTuple[]
    for net in network_types
        for tol in tolerances
            for frac in fractions
                subset = filter(row ->
                    string(row.network_type) == net &&
                    row.tolerance == tol &&
                    row.group1_fraction == frac, df)
                if nrow(subset) > 0
                    push!(rows, (
                        network = net,
                        tolerance = tol,
                        fraction = frac,
                        mean_val = mean(subset[!, col]),
                        std_val = std(subset[!, col])
                    ))
                end
            end
        end
    end
    return DataFrame(rows)
end

dim_summary = summarize_group_size(df, :dimension)
sim_g1_summary = summarize_group_size(df, :similarity_group1)
sim_g2_summary = summarize_group_size(df, :similarity_group2)

# Create figure: Dimension vs Group Fraction for each tolerance
fig = Figure(size=(1400, 800))

# Panel layout: 2 rows x 2 cols for 4 tolerances
for (idx, tol) in enumerate(tolerances)
    row = div(idx - 1, 2) + 1
    col = mod(idx - 1, 2) + 1

    seg = round(1.0 - tol, digits=2)
    ax = Axis(fig[row, col],
        xlabel="Minority fraction",
        ylabel="Dimension (d̂)",
        title="seg = " * string(seg) * " (tolerance = " * string(tol) * ")")

    for (i, (net, label)) in enumerate(zip(network_types, network_labels))
        ndf = filter(row -> row.network == net && row.tolerance == tol, dim_summary)
        if nrow(ndf) > 0
            sort!(ndf, :fraction)
            lines!(ax, ndf.fraction, ndf.mean_val, color=colors[i], linewidth=2, label=label)
            scatter!(ax, ndf.fraction, ndf.mean_val, color=colors[i], markersize=8)
        end
    end

    # Add reference line at d=2 (polarization threshold)
    hlines!(ax, [2], color=:gray, linestyle=:dash, linewidth=1)

    if idx == 1
        axislegend(ax, position=:rt)
    end
end

Label(fig[0, :], "Network Dimension vs Minority Fraction", fontsize=20, font=:bold)

save("figures/group_size_dimension.png", fig, px_per_unit=2)
println("Saved to figures/group_size_dimension.png")

# Also create similarity plot
fig2 = Figure(size=(1400, 800))

for (idx, tol) in enumerate(tolerances)
    row = div(idx - 1, 2) + 1
    col = mod(idx - 1, 2) + 1

    seg2 = round(1.0 - tol, digits=2)
    ax = Axis(fig2[row, col],
        xlabel="Minority fraction",
        ylabel="Similarity",
        title="seg = " * string(seg2) * " (tolerance = " * string(tol) * ")")

    for (i, (net, label)) in enumerate(zip(network_types, network_labels))
        # Minority (group 1)
        ndf1 = filter(row -> row.network == net && row.tolerance == tol, sim_g1_summary)
        # Majority (group 2)
        ndf2 = filter(row -> row.network == net && row.tolerance == tol, sim_g2_summary)

        if nrow(ndf1) > 0
            sort!(ndf1, :fraction)
            lines!(ax, ndf1.fraction, ndf1.mean_val, color=colors[i], linewidth=2,
                   linestyle=:solid, label=label * " (minority)")
        end
        if nrow(ndf2) > 0
            sort!(ndf2, :fraction)
            lines!(ax, ndf2.fraction, ndf2.mean_val, color=colors[i], linewidth=2,
                   linestyle=:dash)
        end
    end

    if idx == 1
        axislegend(ax, position=:rt)
    end
end

Label(fig2[0, :], "Similarity by Group vs Minority Fraction (solid=minority, dashed=majority)", fontsize=18, font=:bold)

save("figures/group_size_similarity.png", fig2, px_per_unit=2)
println("Saved to figures/group_size_similarity.png")

# Print summary
println("\n" * "="^60)
println("DIMENSION SUMMARY")
println("="^60)

for tol in tolerances
    seg3 = round(1.0 - tol, digits=2)
    println("\nseg = ", seg3, " (tolerance = ", tol, "):")
    for net in network_types
        ndf = filter(row -> row.network == net && row.tolerance == tol, dim_summary)
        if nrow(ndf) > 0
            sort!(ndf, :fraction)
            dims = [round(r.mean_val, digits=1) for r in eachrow(ndf)]
            fracs = [r.fraction for r in eachrow(ndf)]
            # Find where dimension first reaches 2
            polarized = findfirst(d -> d >= 1.9, dims)
            if isnothing(polarized)
                println("  ", net, ": No polarization (dim stays at ", minimum(dims), ")")
            else
                println("  ", net, ": Polarizes at fraction >= ", fracs[polarized])
            end
        end
    end
end
