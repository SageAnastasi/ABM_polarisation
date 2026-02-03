# Data Pipeline Documentation

This document maps the Julia scripts to the data files and figures used in the paper "Schelling segregation dynamics in densely-connected social network graphs" (arXiv:2504.16307).

## Model Parameters (Common)

- **Agents:** 1000
- **Initial connections:** 80 random edges per agent
- **Minimum neighbors:** 40 (maintained throughout simulation)
- **Runs:** 100 per parameter combination
- **Convergence:** Model runs until all agents happy or max steps reached

## Pipeline Overview

```
Julia Scripts → CSV Data → R Script → PNG Figures → LaTeX Paper
```

---

## 1. Symmetrical Tolerances (Paper Section 3.1)

**Script:** `tolerance-change-testing.jl`

| Parameter | Value |
|-----------|-------|
| Group size (s) | 0.5 (equal groups) |
| Tolerance (t) | 0.05 to 1.0 (steps of 0.05) |
| Max steps | 100 |
| Runs | 100 |

**Output:** `tolerance_results.csv`
**Renamed to:** `ABM data/tolerance-test-100-runs.csv`

**CSV Columns:**
- Tolerance, Run, Dimension, Similaity_ratio, Happy_proportion, Coherence

**Figures Generated:**
- **Fig 1:** `tolerance_stabilisation.png` - Steps to stabilise vs tolerance
- **Fig 2:** `tolerance_similarity.png` - Same-group neighbor proportion vs tolerance

**Table:** Table 1

---

## 2. Asymmetrical Tolerances (Paper Section 3.2)

**Script:** `asymmetric-tolerance-testing.jl`

| Parameter | Value |
|-----------|-------|
| Group size (s) | 0.5 (equal groups) |
| Group 1 tolerance (g1_t) | 0.5 or 0.9 (fixed) |
| Group 2 tolerance (g2_t) | 0.05 to 1.0 (steps of 0.05) |
| Max steps | 1000 |
| Runs | 100 |

**Output:** `asymmetric_results.csv`
**Renamed to:** `ABM data/asymmetric-tolerance.csv`

**CSV Columns:**
- g1_t, g2_t, Run, Dimension, Similaity_ratio, Happy_proportion, Coherence, g1_similarity, g2_similarity

**Figures Generated:**
- **Fig 3:** `asymmetric_stabilisation.png` - Steps to stabilise
- **Fig 4:** `asymmetric_similarity_all.png` - Overall similarity ratio
- **Fig 5:** `asymmetric_dimension.png` - Embedded dimensionality

**Table:** Table 2

---

## 3. Group Size Variation (Paper Section 3.3)

**Script:** `group-size-change-testing.jl`

| Parameter | Value |
|-----------|-------|
| Group size (s) | 0.01 to 0.5 (steps of 0.05) |
| Tolerance (t) | 0.25, 0.5, 0.85, 0.95 |
| Max steps | 1000 |
| Runs | 100 |

**Output:** Appends to `data.csv` (requires blank template)
**Renamed to:** `ABM data/group_size_1000_steps.csv`

**CSV Columns:**
- Tolerance, Size, Run, Dimension, Similarity, Happy_proportion, Coherence, Group1_similarity, Group2_similarity

**Figures Generated:**
- **Fig 6:** `size_stabilisation.png` - Steps to stabilise by group size
- **Fig 7:** `size-similarity-by-group.png` - Similarity by group (small vs large)

**Table:** Table 3

---

## 4. Weak Minority Preferences (Paper Section 3.4)

**Script:** `weak-minority-preferences.jl`

| Parameter | Value |
|-----------|-------|
| Group size (s) | 0.15 (15% minority) |
| Group 1 tolerance (g1_t) | Varies (see below) |
| Group 2 tolerance (g2_t) | Varies (see below) |
| Max steps | 1000 |
| Runs | 100 |

**Large difference test:** g1_t ∈ {0.5, 0.9}, g2_t ∈ {0.5, 0.9}
**Small difference test:** g1_t ∈ {0.15, 0.2}, g2_t ∈ {0.85, 0.9}

**Output:** Appends to `data.csv` (requires blank template)
**Renamed to:** `ABM data/weak_minority_preferences.csv`

**CSV Columns:**
- g1_t, g2_t, Run, Dimension, Similarity, Happy_proportion, Coherence, Group1_similarity, Group2_similarity

**Figures Generated:**
- **Fig 8:** `minority_stabilisation_large.png` - Stabilisation (large tolerance diff)
- **Fig 9:** `minority_similarity_large_difference.png` - Similarity (large tolerance diff)
- **Fig 10:** `minority_stabilisation_small.png` - Stabilisation (small tolerance diff)
- **Fig 11:** `minority-similarity-small-difference.png` - Similarity (small tolerance diff)

**Tables:** Table 4, Table 5

---

## R Visualization Script

**Script:** `ABM data/ABM_graphing.R`

**Input files expected:**
1. `tolerance-test-100-runs.csv`
2. `asymmetric-tolerance.csv`
3. `group_size_1000_steps.csv`
4. `weak_minority_preferences.csv`

**Output:** All PNG figures listed above

**Warning:** Running this script overwrites existing plots.

---

## Current Workflow Issues

1. **Manual file renaming required** - Scripts output different filenames than R expects
2. **Append-mode scripts** - `group-size-change-testing.jl` and `weak-minority-preferences.jl` require:
   - Copy blank template to `data.csv`
   - Run script
   - Rename `data.csv` to final name
3. **Typo in column name** - "Similaity_ratio" (missing 'r') appears in multiple files
4. **Inconsistent column naming** - "Similarity" vs "Similaity_ratio" across different CSVs
