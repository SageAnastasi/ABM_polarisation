# Visualization functions for Schelling Network ABM

using CairoMakie
using DataFrames

# Set consistent theme
const ABM_THEME = Theme(
    fontsize = 14,
    Axis = (
        xlabelsize = 16,
        ylabelsize = 16,
        titlesize = 18
    ),
    Legend = (
        framevisible = false,
        labelsize = 12
    )
)

"""
    plot_tolerance_stabilisation(df::DataFrame; output_path=nothing)

Create boxplot of steps to stabilisation vs tolerance.
"""
function plot_tolerance_stabilisation(df::DataFrame; output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        # Filter out non-converged runs (coherence == 0)
        df_conv = filter(row -> row.coherence > 0, df)

        if nrow(df_conv) == 0
            fig = Figure(size = (700, 550))
            ax = Axis(fig[1, 1], title = "No converged runs")
            return fig
        end

        # Get unique tolerance values and create categorical mapping
        tolerances = sort(unique(df_conv.tolerance))
        tol_to_idx = Dict(t => i for (i, t) in enumerate(tolerances))

        # Map tolerance values to categorical indices
        x_positions = [tol_to_idx[t] for t in df_conv.tolerance]

        fig = Figure(size = (700, 550))
        ax = Axis(fig[1, 1],
            xlabel = "Tolerance",
            ylabel = "Steps to stabilise",
            title = "Convergence time by tolerance",
            xticks = (1:length(tolerances), string.(tolerances))
        )

        boxplot!(ax, x_positions, df_conv.coherence,
            color = :steelblue)

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_tolerance_dimension(df::DataFrame; output_path=nothing)

Create scatter plot of dimension vs tolerance.
"""
function plot_tolerance_dimension(df::DataFrame; output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        fig = Figure(size = (700, 550))
        ax = Axis(fig[1, 1],
            xlabel = "Tolerance",
            ylabel = "Dimension",
            title = "Spectral dimension by tolerance",
            yticks = [1, 2],
            limits = (nothing, nothing, 0.5, 2.5)
        )

        scatter!(ax, df.tolerance, df.dimension,
            color = :steelblue,
            markersize = 8,
            alpha = 0.6)

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_tolerance_similarity(df::DataFrame; output_path=nothing)

Create scatter plot of similarity ratio vs tolerance.
"""
function plot_tolerance_similarity(df::DataFrame; output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        fig = Figure(size = (700, 550))
        ax = Axis(fig[1, 1],
            xlabel = "Tolerance",
            ylabel = "Similarity ratio",
            title = "Final similarity by tolerance"
        )

        scatter!(ax, df.tolerance, df.similarity_ratio,
            color = :steelblue,
            markersize = 8,
            alpha = 0.6)

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_comparison_grid(df::DataFrame, xcol::Symbol, ycols::Vector{Symbol}, groupcol::Symbol;
                         labels=["A", "B"], output_path=nothing)

Create a grid of scatter plots comparing metrics across groups.
"""
function plot_comparison_grid(
    df::DataFrame,
    xcol::Symbol,
    ycols::Vector{Symbol},
    groupcol::Symbol;
    labels::Vector{String} = ["A", "B"],
    output_path::Union{String, Nothing} = nothing
)
    with_theme(ABM_THEME) do
        ncols = length(ycols)
        fig = Figure(size = (500 * ncols + 150, 550))

        axes = Axis[]
        for (i, ycol) in enumerate(ycols)
            ax = Axis(fig[1, i],
                xlabel = string(xcol),
                ylabel = string(ycol)
            )
            push!(axes, ax)

            # Add panel label
            Label(fig[1, i, TopLeft()], labels[i],
                fontsize = 18,
                font = :bold,
                halign = :left,
                valign = :top)

            # Plot each group
            groups = unique(df[!, groupcol])
            colors = [:steelblue, :coral, :forestgreen, :purple]

            for (gi, g) in enumerate(sort(groups))
                gdf = filter(row -> row[groupcol] == g, df)
                scatter!(ax, gdf[!, xcol], gdf[!, ycol],
                    label = string(g),
                    color = colors[mod1(gi, length(colors))],
                    markersize = 8,
                    alpha = 0.6)
            end
        end

        # Add legend
        Legend(fig[1, ncols + 1], axes[1])

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_asymmetric_similarity(df::DataFrame; output_path=nothing)

Plot similarity ratio for asymmetric tolerance experiments.
"""
function plot_asymmetric_similarity(df::DataFrame; output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        fig = Figure(size = (1200, 550))

        # Plot for each group1 tolerance value
        g1_tolerances = sort(unique(df.group1_tolerance))

        for (i, g1t) in enumerate(g1_tolerances)
            ax = Axis(fig[1, i],
                xlabel = "Group 2 tolerance",
                ylabel = "Similarity ratio",
                title = "Group 1 tol = " * string(g1t)
            )

            gdf = filter(row -> row.group1_tolerance == g1t, df)

            scatter!(ax, gdf.group2_tolerance, gdf.group1_similarity,
                label = "Group 1",
                color = :steelblue,
                markersize = 8,
                alpha = 0.6)

            scatter!(ax, gdf.group2_tolerance, gdf.group2_similarity,
                label = "Group 2",
                color = :coral,
                markersize = 8,
                alpha = 0.6)

            if i == length(g1_tolerances)
                Legend(fig[1, i + 1], ax)
            end
        end

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_group_size_metrics(df::DataFrame, tolerance::Float64; output_path=nothing)

Plot metrics vs group size for a specific tolerance.
"""
function plot_group_size_metrics(df::DataFrame, tolerance::Float64;
    output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        tdf = filter(row -> row.tolerance == tolerance, df)

        fig = Figure(size = (1200, 900))

        # Dimension vs group size
        ax1 = Axis(fig[1, 1],
            xlabel = "Minority fraction",
            ylabel = "Dimension",
            title = "Tolerance = " * string(tolerance)
        )
        scatter!(ax1, tdf.group1_fraction, tdf.dimension,
            color = :steelblue, markersize = 8, alpha = 0.6)
        Label(fig[1, 1, TopLeft()], "A", fontsize = 18, font = :bold)

        # Similarity vs group size
        ax2 = Axis(fig[1, 2],
            xlabel = "Minority fraction",
            ylabel = "Similarity ratio"
        )
        scatter!(ax2, tdf.group1_fraction, tdf.group1_similarity,
            label = "Minority", color = :steelblue, markersize = 8, alpha = 0.6)
        scatter!(ax2, tdf.group1_fraction, tdf.group2_similarity,
            label = "Majority", color = :coral, markersize = 8, alpha = 0.6)
        Legend(fig[1, 3], ax2)
        Label(fig[1, 2, TopLeft()], "B", fontsize = 18, font = :bold)

        # Coherence vs group size
        cdf = filter(row -> row.coherence > 0, tdf)
        if nrow(cdf) > 0
            # Create categorical mapping for group1_fraction
            fractions = sort(unique(cdf.group1_fraction))
            frac_to_idx = Dict(f => i for (i, f) in enumerate(fractions))
            x_positions = [frac_to_idx[f] for f in cdf.group1_fraction]

            ax3 = Axis(fig[2, 1],
                xlabel = "Minority fraction",
                ylabel = "Steps to stabilise",
                xticks = (1:length(fractions), string.(fractions))
            )
            boxplot!(ax3, x_positions, cdf.coherence,
                color = :steelblue)
        else
            ax3 = Axis(fig[2, 1],
                xlabel = "Minority fraction",
                ylabel = "Steps to stabilise"
            )
        end
        Label(fig[2, 1, TopLeft()], "C", fontsize = 18, font = :bold)

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    plot_weak_minority_paradox(df::DataFrame; output_path=nothing)

Plot the weak minority preferences paradox results.
"""
function plot_weak_minority_paradox(df::DataFrame; output_path::Union{String, Nothing} = nothing)
    with_theme(ABM_THEME) do
        fig = Figure(size = (900, 550))

        ax1 = Axis(fig[1, 1],
            xlabel = "Group 1 tolerance",
            ylabel = "Similarity ratio",
            title = "Weak minority paradox"
        )

        # Group by g2 tolerance
        g2_tolerances = sort(unique(df.group2_tolerance))
        colors = [:steelblue, :coral, :forestgreen, :purple]

        for (i, g2t) in enumerate(g2_tolerances)
            gdf = filter(row -> row.group2_tolerance == g2t, df)
            scatter!(ax1, gdf.group1_tolerance, gdf.group1_similarity,
                label = "G1 (G2 tol=" * string(g2t) * ")",
                color = colors[mod1(i, length(colors))],
                markersize = 8,
                alpha = 0.6)
        end

        Legend(fig[1, 2], ax1)

        if !isnothing(output_path)
            save(output_path, fig)
        end

        return fig
    end
end

"""
    generate_tolerance_figures(df::DataFrame, output_dir::String)

Generate all figures for tolerance sweep experiment.
"""
function generate_tolerance_figures(df::DataFrame, output_dir::String)
    mkpath(output_dir)

    plot_tolerance_stabilisation(df;
        output_path = joinpath(output_dir, "tolerance_stabilisation.png"))
    plot_tolerance_dimension(df;
        output_path = joinpath(output_dir, "tolerance_dimension.png"))
    plot_tolerance_similarity(df;
        output_path = joinpath(output_dir, "tolerance_similarity.png"))

    return output_dir
end

"""
    generate_asymmetric_figures(df::DataFrame, output_dir::String)

Generate all figures for asymmetric tolerance experiment.
"""
function generate_asymmetric_figures(df::DataFrame, output_dir::String)
    mkpath(output_dir)

    plot_asymmetric_similarity(df;
        output_path = joinpath(output_dir, "asymmetric_similarity.png"))

    return output_dir
end

"""
    generate_group_size_figures(df::DataFrame, output_dir::String)

Generate all figures for group size sweep experiment.
"""
function generate_group_size_figures(df::DataFrame, output_dir::String)
    mkpath(output_dir)

    tolerances = sort(unique(df.tolerance))
    for tol in tolerances
        plot_group_size_metrics(df, tol;
            output_path = joinpath(output_dir, "group_size_tol_" * string(tol) * ".png"))
    end

    return output_dir
end

"""
    generate_weak_minority_figures(df::DataFrame, output_dir::String)

Generate all figures for weak minority experiment.
"""
function generate_weak_minority_figures(df::DataFrame, output_dir::String)
    mkpath(output_dir)

    plot_weak_minority_paradox(df;
        output_path = joinpath(output_dir, "weak_minority_paradox.png"))

    return output_dir
end
