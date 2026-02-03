# Research Learnings and Findings

This document captures key findings, insights, and technical notes discovered during development and analysis of the Schelling Network ABM.

---

## Tolerance Parameter Semantics

**Issue discovered:** The parameter originally called "tolerance" was semantically inverted.

- The internal parameter `seg` represents the *minimum fraction of same-group neighbors* required for an agent to be happy
- High `seg` = agent needs many same-group neighbors = **intolerant**
- Low `seg` = agent accepts few same-group neighbors = **tolerant**

**Fix:** We now define `tolerance = 1 - seg` in the model initialization, so:
- High tolerance = accepting of diversity, happy with mixed neighborhoods
- Low tolerance = wants homogeneous neighborhood, drives segregation

This makes the parameter semantically intuitive.

---

## Spectral Dimension Analysis

### The `d_elbow` metric

The `d_elbow` function from DotProductGraphs estimates intrinsic dimensionality from the singular value spectrum by finding the "elbow" where values drop off.

**Observation:** `d_elbow` returns discrete integer values (1 or 2 in our case) and shows a sharp phase transition:
- Tolerance < 0.27: dimension = 2 (network splits into two clusters)
- Tolerance >= 0.27: dimension = 1 (network stays unified)

**Problem:** Zero variance within tolerance levels - every run at the same tolerance gives identical dimension. This is because `d_elbow` discretizes a continuous underlying change.

### The sigma ratio (σ₁/σ₂) as alternative metric

The ratio of the first two singular values provides a **continuous measure** of network structure:

| Tolerance | σ₁/σ₂ ratio | Interpretation |
|-----------|-------------|----------------|
| 0.20 | 1.53 | Two strong components |
| 0.25 | 1.81 | Transition region |
| 0.30 | 2.21 | Single dominant component |
| 0.35 | 2.83 | Strongly unified |

This metric shows the gradual structural change that `d_elbow` discretizes.

---

## Variance in Simulation Outcomes

### Initial network variance

All initial networks are Erdős-Rényi random graphs with identical parameters, so they have similar spectral properties:
- Initial σ₁/σ₂ ≈ 6.45 (std ≈ 0.038)

### Dynamics reduce variance

The simulation dynamics act as a "homogenizing funnel":
- Final σ₁/σ₂ ≈ 1.81 (std ≈ 0.004) at tolerance 0.25
- **Final variance is ~10x smaller than initial variance**

This means:
1. Different random initial networks converge to similar final states
2. The tolerance parameter dominates the final structure
3. The system "forgets" initial condition details

---

## Key Simulation Results (Tolerance Sweep)

With corrected tolerance semantics:

| Tolerance | Convergence | Similarity | Dimension | Interpretation |
|-----------|-------------|------------|-----------|----------------|
| Low (0-0.25) | Slow (~45 steps) | High (~1.0) | 2 | Intolerant agents segregate |
| High (0.65+) | Immediate (1 step) | ~0.5 | 1 | Tolerant agents preserve diversity |

The transition occurs around tolerance 0.25-0.30, where:
- Network structure shifts from two-cluster to unified
- Convergence time drops sharply
- Similarity ratio drops from segregated (~1.0) to random (~0.5)

---

## Technical Notes

### Agents.jl v6 Migration

Key API changes from v5 to v6:
- Use `@agent struct Name(NoSpaceAgent)` for non-spatial agents
- Pass `agent_step!` at model construction time
- Use `abmrng(model)` instead of `model.rng` to access RNG
- Use `StandardABM` with `container = Vector`

### Boxplot Categorical Axes

CairoMakie's `boxplot!` requires categorical x-positions. When using continuous values (like tolerance 0.05, 0.10, ...), must:
1. Create integer index mapping: `tol_to_idx = Dict(t => i for (i, t) in enumerate(tolerances))`
2. Convert values to indices for plotting
3. Set custom xticks: `xticks = (1:length(tolerances), string.(tolerances))`

### Floating Point Precision

When computing `1.0 - x` for tolerance values, floating point noise can produce values like `0.050000000000000044`. Always round to appropriate precision:
```julia
df.tolerance = round.(df.tolerance, digits=2)
```

---

## Network Topology Effects

**Major finding:** Initial network topology dramatically affects whether segregation occurs at all.

### Experiment Setup
- 4 network types: Erdős-Rényi, Watts-Strogatz (small-world), Barabási-Albert (scale-free), Geometric (spatial)
- Tolerance range: 0.1-0.9 (wide range to capture all behaviors)
- 50 runs per combination
- **Density matched** across all network types (mean degree ~130-160)

### Results by Network Type

| Network | Mean degree | Degree std | σ₁/σ₂ range | Dimension | Segregates? |
|---------|-------------|------------|-------------|-----------|-------------|
| Erdős-Rényi | 148 | 8 | 1.2 → 6.5 | 2 → 1 | **Yes** - classic transition |
| Watts-Strogatz | 160 | 4 | 1.1 → 1.2 | 7-8 | **No** - structure preserved |
| Barabási-Albert | 147 | 77 | 3.8 → 5.6 | always 1 | **No** - hubs maintain bridges |
| Geometric | 131 | 32 | 1.1 → 1.2 | 10-17 | **No** - spatial locality resists |

### Key Insights

1. **Only Erdős-Rényi shows classic Schelling transition**
   - σ₁/σ₂ jumps from ~1 (two balanced components) to ~6 (one dominant)
   - Dimension transitions from 2 to 1 around tolerance 0.2-0.3
   - Similarity drops from ~0.95 (segregated) to ~0.5 (random) with increasing tolerance
   - Convergence slow at low tolerance (~65 steps), fast at high tolerance (~5 steps)

2. **Small-world networks create a segregation floor** ✓
   - After bug fix, WS starts at 50% similarity like all others
   - At low tolerance: segregates to 94% (similar to ER)
   - At high tolerance: **floors at 87%** - cannot fully de-segregate!
   - σ₁/σ₂ stays near 1 (no bifurcation into two components)
   - Dimension stable at 7-8
   - **Interpretation:** Small-world clustering traps agents in local neighborhoods; even tolerant agents cannot escape to mix with the other group

3. **Scale-free networks never bifurcate**
   - Dimension always 1 (single dominant component)
   - σ₁/σ₂ *increases* with tolerance (opposite direction to ER)
   - Hubs (high-degree nodes) maintain cross-group connections
   - Even very intolerant agents stay connected through hub bridges

4. **Geometric networks behave like small-world**
   - σ₁/σ₂ stays flat near 1 (like Watts-Strogatz)
   - High dimension (10-17) indicates complex spatial structure
   - Spatial locality creates similar resistance to segregation as clustering
   - Similarity stays near 0.5-0.6 even at very low tolerance

### Critical Bug Fix: Sequential Group Assignment

**Bug discovered:** Groups were assigned sequentially (agents 1-500 = group 1, 501-1000 = group 2). This caused artificial pre-segregation in networks where node IDs have structural meaning.

**Impact by network type (BEFORE fix):**
| Network | Initial Similarity | Cross-group edges | Affected? |
|---------|-------------------|-------------------|-----------|
| Erdős-Rényi | 50% | 50% | No - random connections |
| Watts-Strogatz | **87%** | **13%** | **YES - ring lattice** |
| Barabási-Albert | 50.5% | 43% | Slight (hub bias) |
| Geometric | 50% | 50% | No - random positions |

**Root cause for WS:** In a ring lattice with k=160, each node connects to 80 neighbors on each side. With sequential IDs, agent 250 connects to agents 170-330 (all group 1), giving 97% same-group neighbors by construction.

**Fix applied:** Groups are now randomly shuffled across agent IDs:
```julia
group_assignments = shuffle(rng, vcat(fill(1, group1_count), fill(2, group2_count)))
```

**After fix:** All network types start at ~50% similarity as expected.

### Implications (FINAL - after bug fix and re-run)

**Major revision:** After fixing the sequential group assignment bug, ALL network types behave similarly:

| Network | Low tolerance (0.1) | High tolerance (0.9) |
|---------|---------------------|----------------------|
| **ER** | 92% segregated | 50% random |
| **WS** | 92% segregated | 50% random |
| **BA** | 94% segregated | 50% random |
| **Geometric** | 93% segregated | 50% random |

**Key insight:** The apparent "WS 87% floor" was entirely an artifact of sequential group assignment in the ring lattice. With proper random group assignment, network topology has **minimal effect** on segregation dynamics in dense networks.

All network types:
- Segregate similarly at low tolerance
- De-segregate fully at high tolerance
- Show no structural barriers to mixing

This suggests that in **dense networks** (mean degree ~150), the specific topology matters less than agent preferences. The high connectivity provides enough pathways for agents to find suitable neighbors regardless of network structure.

---

---

## Asymmetric Tolerance Results (CORRECTED)

### The "intolerant group dominates" effect CONFIRMED

With corrected random group assignment, the paper's key finding still holds:

| G2 tolerance | G1=0.5 (moderate) | G1=0.9 (tolerant) |
|--------------|-------------------|-------------------|
| 0.1 (intolerant) | g1=0.91, g2=0.90 | g1=0.91, g2=0.90 |
| 0.5 (moderate) | g1=0.52, g2=0.52 | g1=0.52, g2=0.52 |
| 0.9 (tolerant) | g1=0.51, g2=0.52 | g1=0.50, g2=0.50 |

**Key findings:**
1. **Intolerant group drives segregation for BOTH groups** - when G2 is intolerant (0.1), both groups end up at ~90% similarity regardless of G1's tolerance
2. **G1's tolerance doesn't protect against G2's intolerance** - even very tolerant G1 (0.9) gets pulled into segregation
3. **Mutual tolerance required for mixing** - only when both groups are tolerant do we see ~50% similarity
4. **All network types show the same pattern** - no topology-specific effects

**Implication:** One group's intolerance is sufficient to drive network-wide segregation. The tolerant group cannot "escape" - they end up with segregated neighborhoods because the intolerant group cuts cross-group edges that both groups share.

---

## Open Questions

1. How does the σ₁/σ₂ transition sharpness depend on network size?
2. Is there a critical tolerance value that can be predicted theoretically?
3. How do asymmetric tolerances affect the spectral structure? (Re-running with corrected data)
4. What happens with more than 2 groups?
5. ~~Can we characterize the "hub bridging" effect in scale-free networks more precisely?~~ **REVISED**: BA behaves like other networks with random group assignment
6. ~~Does rewiring probability (β) in Watts-Strogatz affect segregation resistance?~~ **REVISED**: WS effect was artifact of sequential assignment
7. What radius threshold in geometric networks triggers the transition to ER-like behavior?
8. How does the spatial dimension (2D vs 3D) affect geometric network segregation?
9. ~~If groups are randomly assigned to WS nodes, does clustering still affect segregation dynamics?~~ **ANSWERED**: No - WS behaves like ER with random assignment
10. **NEW**: Why do all dense network topologies behave similarly? Is it purely due to high connectivity providing alternative pathways?
11. **NEW**: At what density threshold do topology effects become significant?

---

*Last updated: 2026-02-03 (corrected after random group assignment bug fix)*
