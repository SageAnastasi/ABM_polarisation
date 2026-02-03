# Plot weak minority results - matching paper's Figure 8-11 format
# Fig 8/10: Stabilisation boxplots
# Fig 9/11: Similarity scatter plots (two panels: minority & majority)

using Pkg
Pkg.activate(".")

using CSV
using DataFrames
using CairoMakie
using Statistics

# Load data
df = CSV.read("weak_minority_network_results.csv", DataFrame)

# Convert tolerance to seg for x-axis labels (paper uses seg)
df.g1_seg = 1.0 .- df.group1_tolerance
df.g2_seg = 1.0 .- df.group2_tolerance

# Network types
network_types = ["erdos_renyi", "watts_strogatz", "barabasi_albert", "geometric"]
network_labels = ["ER", "WS", "BA", "Geo"]
colors = [:steelblue, :coral, :green, :purple]

# ============================================================================
# LARGE DIFFERENCE PLOTS (Fig 8 & 9)
# ============================================================================

large_diff = filter(row -> row.test_type == "large_diff", df)

# Fig 8: Stabilisation boxplot
fig1 = Figure(size=(800, 500))
ax1 = Axis(fig1[1, 1],
    xlabel="Required proportion of same-group neighbours for group 1 (seg)",
    ylabel="Steps to stabilise",
    title="Steps required for model to stabilise (Large difference test)",
    xticks=([1, 2], ["0.5", "0.9"]))

# Group by g1_seg and g2_seg
for (g2_idx, g2_seg) in enumerate([0.5, 0.9])
    for (g1_idx, g1_seg) in enumerate([0.5, 0.9])
        subset = filter(row ->
            isapprox(row.g1_seg, g1_seg, atol=0.05) &&
            isapprox(row.g2_seg, g2_seg, atol=0.05), large_diff)

        if nrow(subset) > 0
            x_pos = g1_idx + (g2_idx - 1.5) * 0.3
            color = g2_idx == 1 ? :salmon : :cyan
            boxplot!(ax1, fill(x_pos, nrow(subset)), subset.coherence,
                     color=color, width=0.25)
        end
    end
end

# Legend
Legend(fig1[1, 2],
    [PolyElement(color=:salmon), PolyElement(color=:cyan)],
    ["Group 2 seg = 0.5", "Group 2 seg = 0.9"],
    "Group 2 Tolerance")

save("figures/weak_minority_stabilisation_large.png", fig1, px_per_unit=2)
println("Saved: figures/weak_minority_stabilisation_large.png")

# Fig 9: Similarity plots (two panels)
fig2 = Figure(size=(1000, 400))

# Panel A: Minority (Group 1) similarity
ax2a = Axis(fig2[1, 1],
    xlabel="Group 1 seg",
    ylabel="Proportion of same-group neighbours",
    title="A) Minority (15%) similarity",
    xticks=([1, 2], ["0.5", "0.9"]))

# Panel B: Majority (Group 2) similarity
ax2b = Axis(fig2[1, 2],
    xlabel="Group 1 seg",
    ylabel="Proportion of same-group neighbours",
    title="B) Majority (85%) similarity",
    xticks=([1, 2], ["0.5", "0.9"]))

for (g2_idx, g2_seg) in enumerate([0.5, 0.9])
    for (g1_idx, g1_seg) in enumerate([0.5, 0.9])
        subset = filter(row ->
            isapprox(row.g1_seg, g1_seg, atol=0.05) &&
            isapprox(row.g2_seg, g2_seg, atol=0.05), large_diff)

        if nrow(subset) > 0
            x_pos = g1_idx + (g2_idx - 1.5) * 0.15
            color = g2_idx == 1 ? :salmon : :cyan
            marker = g2_idx == 1 ? :circle : :utriangle

            # Minority
            scatter!(ax2a, [x_pos], [mean(subset.similarity_group1)],
                    color=color, marker=marker, markersize=15)
            # Majority
            scatter!(ax2b, [x_pos], [mean(subset.similarity_group2)],
                    color=color, marker=marker, markersize=15)
        end
    end
end

Legend(fig2[1, 3],
    [MarkerElement(color=:salmon, marker=:circle, markersize=15),
     MarkerElement(color=:cyan, marker=:utriangle, markersize=15)],
    ["G2 seg = 0.5", "G2 seg = 0.9"],
    "Group 2")

save("figures/weak_minority_similarity_large.png", fig2, px_per_unit=2)
println("Saved: figures/weak_minority_similarity_large.png")

# ============================================================================
# SMALL DIFFERENCE PLOTS (Fig 10 & 11)
# ============================================================================

small_diff = filter(row -> row.test_type == "small_diff", df)

# Fig 10: Stabilisation boxplot
fig3 = Figure(size=(800, 500))
ax3 = Axis(fig3[1, 1],
    xlabel="Group 1 seg (minority intolerance)",
    ylabel="Steps to stabilise",
    title="Steps required for model to stabilise (Small difference test)",
    xticks=([1, 2], ["0.15", "0.2"]))

for (g2_idx, g2_seg) in enumerate([0.85, 0.9])
    for (g1_idx, g1_seg) in enumerate([0.15, 0.2])
        subset = filter(row ->
            isapprox(row.g1_seg, g1_seg, atol=0.05) &&
            isapprox(row.g2_seg, g2_seg, atol=0.05), small_diff)

        if nrow(subset) > 0
            x_pos = g1_idx + (g2_idx - 1.5) * 0.3
            color = g2_idx == 1 ? :salmon : :cyan
            boxplot!(ax3, fill(x_pos, nrow(subset)), subset.coherence,
                     color=color, width=0.25)
        end
    end
end

Legend(fig3[1, 2],
    [PolyElement(color=:salmon), PolyElement(color=:cyan)],
    ["G2 seg = 0.85", "G2 seg = 0.9"],
    "Group 2")

save("figures/weak_minority_stabilisation_small.png", fig3, px_per_unit=2)
println("Saved: figures/weak_minority_stabilisation_small.png")

# Fig 11: Similarity plots (two panels)
fig4 = Figure(size=(1000, 400))

ax4a = Axis(fig4[1, 1],
    xlabel="Group 1 seg",
    ylabel="Proportion of same-group neighbours",
    title="A) Minority (15%) similarity",
    xticks=([1, 2], ["0.15", "0.2"]))

ax4b = Axis(fig4[1, 2],
    xlabel="Group 1 seg",
    ylabel="Proportion of same-group neighbours",
    title="B) Majority (85%) similarity",
    xticks=([1, 2], ["0.15", "0.2"]))

for (g2_idx, g2_seg) in enumerate([0.85, 0.9])
    for (g1_idx, g1_seg) in enumerate([0.15, 0.2])
        subset = filter(row ->
            isapprox(row.g1_seg, g1_seg, atol=0.05) &&
            isapprox(row.g2_seg, g2_seg, atol=0.05), small_diff)

        if nrow(subset) > 0
            x_pos = g1_idx + (g2_idx - 1.5) * 0.15
            color = g2_idx == 1 ? :salmon : :cyan
            marker = g2_idx == 1 ? :circle : :utriangle

            scatter!(ax4a, [x_pos], [mean(subset.similarity_group1)],
                    color=color, marker=marker, markersize=15)
            scatter!(ax4b, [x_pos], [mean(subset.similarity_group2)],
                    color=color, marker=marker, markersize=15)
        end
    end
end

Legend(fig4[1, 3],
    [MarkerElement(color=:salmon, marker=:circle, markersize=15),
     MarkerElement(color=:cyan, marker=:utriangle, markersize=15)],
    ["G2 seg = 0.85", "G2 seg = 0.9"],
    "Group 2")

save("figures/weak_minority_similarity_small.png", fig4, px_per_unit=2)
println("Saved: figures/weak_minority_similarity_small.png")

# ============================================================================
# SUMMARY
# ============================================================================

println("\n" * "="^60)
println("WEAK MINORITY SUMMARY (15% minority, values shown as seg)")
println("="^60)

for test_type in ["large_diff", "small_diff"]
    println("\n--- ", uppercase(test_type), " ---")
    tdf = filter(row -> row.test_type == test_type, df)

    # Summarize
    for g1_seg in sort(unique(round.(tdf.g1_seg, digits=2)))
        for g2_seg in sort(unique(round.(tdf.g2_seg, digits=2)))
            subset = filter(row ->
                isapprox(row.g1_seg, g1_seg, atol=0.05) &&
                isapprox(row.g2_seg, g2_seg, atol=0.05), tdf)
            if nrow(subset) > 0
                println("  g1_seg=", g1_seg, ", g2_seg=", g2_seg,
                        ": minority_sim=", round(mean(subset.similarity_group1), digits=2),
                        ", majority_sim=", round(mean(subset.similarity_group2), digits=2),
                        ", steps=", round(mean(subset.coherence), digits=0))
            end
        end
    end
end
