# Plot asymmetric tolerance results by network type
# Supports multiple G1 tolerance values (matching paper Section 3.2)

using Pkg
Pkg.activate(".")

using CSV
using DataFrames
using CairoMakie
using Statistics

# Load data
df = CSV.read("asymmetric_network_results.csv", DataFrame)

# Network types and labels
network_types = ["erdos_renyi", "watts_strogatz", "barabasi_albert", "geometric"]
network_labels = ["Erdős-Rényi", "Watts-Strogatz", "Barabási-Albert", "Geometric"]
colors = [:steelblue, :coral, :green, :purple]

# Get unique G1 tolerances
g1_tolerances = sort(unique(df.group1_tolerance))

# Compute summaries
function summarize_asymmetric(df, col, g1_tol)
    rows = NamedTuple[]
    for net in network_types
        ndf = filter(row -> string(row.network_type) == net && row.group1_tolerance == g1_tol, df)
        for g2t in sort(unique(ndf.group2_tolerance))
            tdf = filter(row -> row.group2_tolerance == g2t, ndf)
            push!(rows, (
                network = net,
                g2_tolerance = g2t,
                mean_val = mean(tdf[!, col]),
                std_val = std(tdf[!, col])
            ))
        end
    end
    return DataFrame(rows)
end

# Create figure with rows for each G1 tolerance
n_g1 = length(g1_tolerances)
fig = Figure(size=(1400, 450 * n_g1))

for (row_idx, g1_tol) in enumerate(g1_tolerances)
    sim_g1 = summarize_asymmetric(df, :similarity_group1, g1_tol)
    sim_g2 = summarize_asymmetric(df, :similarity_group2, g1_tol)

    # Panel A: Group 1 similarity
    ax1 = Axis(fig[row_idx, 1],
        xlabel="Group 2 Tolerance",
        ylabel="Similarity (Group 1)",
        title="G1 tol=" * string(g1_tol) * ": Group 1 Similarity")

    for (i, (net, label)) in enumerate(zip(network_types, network_labels))
        ndf = filter(row -> row.network == net, sim_g1)
        if nrow(ndf) > 0
            sort!(ndf, :g2_tolerance)
            band!(ax1, ndf.g2_tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
                  color=(colors[i], 0.2))
            lines!(ax1, ndf.g2_tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
            scatter!(ax1, ndf.g2_tolerance, ndf.mean_val, color=colors[i], markersize=8)
        end
    end

    if row_idx == 1
        axislegend(ax1, position=:rt)
    end

    # Panel B: Group 2 similarity
    ax2 = Axis(fig[row_idx, 2],
        xlabel="Group 2 Tolerance",
        ylabel="Similarity (Group 2)",
        title="G1 tol=" * string(g1_tol) * ": Group 2 Similarity")

    for (i, (net, label)) in enumerate(zip(network_types, network_labels))
        ndf = filter(row -> row.network == net, sim_g2)
        if nrow(ndf) > 0
            sort!(ndf, :g2_tolerance)
            band!(ax2, ndf.g2_tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
                  color=(colors[i], 0.2))
            lines!(ax2, ndf.g2_tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
            scatter!(ax2, ndf.g2_tolerance, ndf.mean_val, color=colors[i], markersize=8)
        end
    end

    # Panel C: Difference between groups
    ax3 = Axis(fig[row_idx, 3],
        xlabel="Group 2 Tolerance",
        ylabel="Similarity difference (G1 - G2)",
        title="G1 tol=" * string(g1_tol) * ": Asymmetry")

    for (i, (net, label)) in enumerate(zip(network_types, network_labels))
        ndf1 = filter(row -> row.network == net, sim_g1)
        ndf2 = filter(row -> row.network == net, sim_g2)
        if nrow(ndf1) > 0 && nrow(ndf2) > 0
            sort!(ndf1, :g2_tolerance)
            sort!(ndf2, :g2_tolerance)
            diff = ndf1.mean_val .- ndf2.mean_val
            lines!(ax3, ndf1.g2_tolerance, diff, color=colors[i], linewidth=2, label=label)
            scatter!(ax3, ndf1.g2_tolerance, diff, color=colors[i], markersize=8)
        end
    end

    hlines!(ax3, [0], color=:gray, linestyle=:dash, linewidth=1)
end

# Save
save("figures/asymmetric_tolerance_comparison.png", fig, px_per_unit=2)
println("Saved to figures/asymmetric_tolerance_comparison.png")

# Print summary
println("\n" * "=" ^ 60)
println("ASYMMETRIC TOLERANCE SUMMARY")
println("=" ^ 60)

for g1_tol in g1_tolerances
    println("\n--- Group 1 tolerance = ", g1_tol, " ---")
    sim_g1 = summarize_asymmetric(df, :similarity_group1, g1_tol)
    sim_g2 = summarize_asymmetric(df, :similarity_group2, g1_tol)

    for (net, label) in zip(network_types, network_labels)
        println("\n  ", label, ":")
        ndf1 = filter(row -> row.network == net, sim_g1)
        ndf2 = filter(row -> row.network == net, sim_g2)

        if nrow(ndf1) > 0 && nrow(ndf2) > 0
            sort!(ndf1, :g2_tolerance)
            sort!(ndf2, :g2_tolerance)

            for g2t in [0.1, 0.5, 0.9]
                r1 = filter(row -> row.g2_tolerance == g2t, ndf1)
                r2 = filter(row -> row.g2_tolerance == g2t, ndf2)
                if nrow(r1) > 0 && nrow(r2) > 0
                    diff = r1[1, :mean_val] - r2[1, :mean_val]
                    println("    g2_tol=", g2t, ": g1=", round(r1[1, :mean_val], digits=2),
                            ", g2=", round(r2[1, :mean_val], digits=2),
                            ", diff=", round(diff, digits=2))
                end
            end
        end
    end
end
