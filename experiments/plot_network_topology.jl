# Plot network topology comparison from corrected experiment results

using Pkg
Pkg.activate(".")

using CSV
using DataFrames
using CairoMakie
using Statistics

# Load data
df = CSV.read("network_topology_results.csv", DataFrame)

# Prepare data by network type
network_types = ["erdos_renyi", "watts_strogatz", "barabasi_albert", "geometric"]
network_labels = ["Erdős-Rényi", "Watts-Strogatz", "Barabási-Albert", "Geometric"]
colors = [:steelblue, :coral, :green, :purple]

# Compute means and std for each network type and tolerance
function summarize_by_network(df, col)
    rows = NamedTuple[]
    for net in network_types
        ndf = filter(row -> string(row.network_type) == net, df)
        for tol in sort(unique(ndf.tolerance))
            tdf = filter(row -> row.tolerance == tol, ndf)
            push!(rows, (
                network = net,
                tolerance = tol,
                mean_val = mean(tdf[!, col]),
                std_val = std(tdf[!, col])
            ))
        end
    end
    return DataFrame(rows)
end

sim_summary = summarize_by_network(df, :similarity_ratio)
sigma_summary = summarize_by_network(df, :sigma_ratio)
dim_summary = summarize_by_network(df, :dimension)
coh_summary = summarize_by_network(df, :coherence)

# Create figure
fig = Figure(size=(1400, 1000))

# Panel A: Similarity ratio
ax1 = Axis(fig[1, 1],
    xlabel="Tolerance",
    ylabel="Similarity ratio",
    title="A) Similarity by Network Type")

for (i, (net, label)) in enumerate(zip(network_types, network_labels))
    ndf = filter(row -> row.network == net, sim_summary)
    sort!(ndf, :tolerance)

    # Plot with error band
    band!(ax1, ndf.tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
          color=(colors[i], 0.2))
    lines!(ax1, ndf.tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
    scatter!(ax1, ndf.tolerance, ndf.mean_val, color=colors[i], markersize=8)
end

axislegend(ax1, position=:rt)

# Panel B: Sigma ratio
ax2 = Axis(fig[1, 2],
    xlabel="Tolerance",
    ylabel="σ₁/σ₂ ratio",
    title="B) Spectral Ratio by Network Type")

for (i, (net, label)) in enumerate(zip(network_types, network_labels))
    ndf = filter(row -> row.network == net, sigma_summary)
    sort!(ndf, :tolerance)

    band!(ax2, ndf.tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
          color=(colors[i], 0.2))
    lines!(ax2, ndf.tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
    scatter!(ax2, ndf.tolerance, ndf.mean_val, color=colors[i], markersize=8)
end

# Panel C: Dimension
ax3 = Axis(fig[2, 1],
    xlabel="Tolerance",
    ylabel="Dimension (d_elbow)",
    title="C) Spectral Dimension by Network Type")

for (i, (net, label)) in enumerate(zip(network_types, network_labels))
    ndf = filter(row -> row.network == net, dim_summary)
    sort!(ndf, :tolerance)

    band!(ax3, ndf.tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
          color=(colors[i], 0.2))
    lines!(ax3, ndf.tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
    scatter!(ax3, ndf.tolerance, ndf.mean_val, color=colors[i], markersize=8)
end

# Panel D: Coherence (steps to converge)
ax4 = Axis(fig[2, 2],
    xlabel="Tolerance",
    ylabel="Steps to convergence",
    title="D) Convergence Time by Network Type")

for (i, (net, label)) in enumerate(zip(network_types, network_labels))
    ndf = filter(row -> row.network == net, coh_summary)
    sort!(ndf, :tolerance)

    band!(ax4, ndf.tolerance, ndf.mean_val .- ndf.std_val, ndf.mean_val .+ ndf.std_val,
          color=(colors[i], 0.2))
    lines!(ax4, ndf.tolerance, ndf.mean_val, color=colors[i], linewidth=2, label=label)
    scatter!(ax4, ndf.tolerance, ndf.mean_val, color=colors[i], markersize=8)
end

# Save
save("figures/network_topology_comparison.png", fig, px_per_unit=2)
println("Saved to figures/network_topology_comparison.png")

# Also print summary
println("\n" * "="^60)
println("SUMMARY (CORRECTED - Random Group Assignment)")
println("="^60)
for (net, label) in zip(network_types, network_labels)
    println("\n", label, ":")
    ndf = filter(row -> row.network == net, sim_summary)
    sort!(ndf, :tolerance)
    for row in eachrow(ndf)
        if row.tolerance in [0.1, 0.5, 0.9]
            println("  tol=", row.tolerance, ": similarity=", round(row.mean_val, digits=2))
        end
    end
end
