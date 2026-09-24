# LuccME goldens

Year-by-year reference results (goldens) of TerraME/LuccME, used to validate ports of
LuccME (such as [disslucc](https://github.com/DisSModel/disslucc)) one algorithm at a
time. There are 23 goldens:

- the 21 functional tests of the package (`luccme/tests/functional/lab01.lua` …
  `lab21.lua`), with the package's numbering;
- 2 references in `references/` (`lab01_md1643`, `lab15_md10`) that exercise the
  convergence loop (see below).

All of them were generated from the scripts **unedited**, in this repository's image
(TerraME 2.0.1, TerraLib 5.5.1, LuccME `6244dd4`).

```
benchmark/
├── generate.sh      # generates goldens/<name>/ (all or some)
├── harness.lua      # runs a lab or a standalone script and records the yearly cell state
├── finalize.py      # compresses, cross-checks and writes manifest.json
├── references/      # reference scripts + original TerraME output
└── goldens/         # 23 goldens: <name>.csv.gz, terrame.log, manifest.json
```

## Contents of `goldens/<name>/`

| File | Contents |
|---|---|
| `<name>.csv.gz` | state of every cell **at the end of every year**: `year,id,col,row`, `<class>_out` (allocation result) and `<class>_pot` (potential) of every class, 12 decimal places |
| `terrame.log` | TerraME output: demand and allocated area per year, iterations, maximum error |
| `manifest.json` | source (script and SHA-256), versions, columns, years, SHA-256 of the CSV, iterations per year and the cross-check |

`col`/`row` are the attributes of the input cells (`luccme/data/test/csAC.shp` and
`cs_moju.shp`; in disslucc, `data/input/csAC.zip` and `cs_moju.zip` hold the same values,
with cs_moju's `row` column named `lin`), so they map directly onto a raster grid.

Having `_pot` separately makes it possible to validate the potential component before
the allocation.

## Labs and components

| Lab | Data | Years | Demand | Potential | Allocation |
|---|---|---|---|---|---|
| lab01 | csAC | 2008–2014 | PreComputedValues | CLinearRegression | CClueLike |
| lab02 | csAC | 2008–2014 | PreComputedValues | CSpatialLagRegression | CClueLike |
| lab03 | csAC | 2008–2014 | PreComputedValues | CSpatialLagRegression | CClueLikeSaturation |
| lab04 | csAC | 2008–2014 | ComputeTwoDates | CSpatialLagRegression | CClueLike |
| lab05 | csAC | 2008–2014 | ComputeThreeDates | CSpatialLagRegression | CClueLike |
| lab06 | csAC | 2008–2014 | PreComputedValues | CSpatialLagRegression | CClueLikeSaturation |
| lab07 | csAC | 2008–2025 | PreComputedValues | CSpatialLagRegression | CClueLike |
| lab08 | csAC | 2008–2014 | PreComputedValues | CSpatialLagLinearRegressionMix | CClueLike |
| lab09 | csAC | 2008–2014 | PreComputedValues | CSampleBased | CClueLike |
| lab10 | cs_moju | 1999–2004 | PreComputedValues | DNeighSimpleRule | DSimpleOrdering |
| lab11 | cs_moju | 1999–2004 | PreComputedValues | DInverseDistanceRule | DSimpleOrdering |
| lab12 | cs_moju | 1999–2004 | PreComputedValues | DNeighInverseDistanceRule | DSimpleOrdering |
| lab13 | cs_moju | 1999–2004 | PreComputedValues | DLogisticRegression | DSimpleOrdering |
| lab14 | cs_moju | 1999–2004 | PreComputedValues | DLogisticRegressionNeighAttract | DClueSLike |
| lab15 | cs_moju | 1999–2004 | PreComputedValues | DLogisticRegression | DClueSLike |
| lab16 | cs_moju | 1999–2004 | ComputeTwoDates | DLogisticRegression | DClueSLike |
| lab17 | cs_moju | 1999–2004 | ComputeThreeDates | DLogisticRegression | DClueSLike |
| lab18 | cs_moju | 1999–2004 | PreComputedValues | DSampleBased | DClueSLike |
| lab19 | cs_moju | 1999–2004 | ComputeTwoDates | DLogisticRegressionNeighAttractRepulsion | DClueSNeighOrdering |
| lab20 | cs_moju | 1999–2004 | ComputeTwoDates | DLogisticRegressionNeighAttractRepulsion | DClueSLike |
| lab21 | cs_moju | 1999–2004 | PreComputedValues | DLogisticRegression | DClueSNeighOrdering |

### References that exercise the convergence loop

The package labs accept the first allocation in every year (see below), so they do not
test the convergence loop. For that there are two references in `references/`: LuccMe
Model Configurator scripts (2017) with the same coefficients and demand as lab01/lab15,
but a smaller `maxDifference`. Provenance in `references/README.md`.

| Golden | Script | `maxDifference` | Iterations per year | Matches the original output |
|---|---|---|---|---|
| `lab01_md1643` | `lab1_main.lua` + `lab1_submodel.lua` | 1643 (package: 5000) | 0, 0, 8, 26, 18, 17, 17 (2008–2014) | `LUCCME_Lab1_2014.zip` (max. 5e-13) |
| `lab15_md10` | `lab6_main.lua` + `lab6_submodel.lua` | 10 (package: 300) | 0, 67, 56, 56, 61, 61 (1999–2004) | `Lab15_2004.zip` (identical) |

Their outputs really do differ from the package labs: `d_out` differs in 20,075 of the
46,018 cell-years (lab01) and in 681 of the 35,484 (lab15), from the first year with
iterations on. The iteration count of each year is in `manifest.json`
(`iterations_per_year`), for comparison with a port.

## Limits of these goldens (read before using them as evidence)

- **In the package labs the allocation does not iterate.** In the continuous labs that
  log iterations (lab01, 02, 04, 05, 07, 08, 09) and in the discrete CLUE-S labs
  (lab14–21), every year is accepted at the first pass. These goldens validate the first
  allocation, **not** the convergence loop; use `lab01_md1643` and `lab15_md10` for that.
- **CClueLike's `correctCellChange` never runs.** Its guard is
  `if (cell.regionregionAloc == rNumber)` (`luccme/lua/AllocationCClueLike.lua:503`, a
  typo for `regionAloc`), which is always false. The continuous goldens with `CClueLike`
  reflect LuccME **without** that correction; a port that implements it will diverge from
  the first year with change on. `CClueLikeSaturation` spells it correctly and does run
  the correction.
- **lab15, lab16, lab17 and lab20 have identical `*_out`**; lab15–17 also have identical
  `*_pot`. The `ComputeTwoDates`/`ComputeThreeDates` demands and the attraction/repulsion
  potential do not change the result on these data. Matching one of them does not tell
  them apart.
- These goldens are engineering validation (the port reproduces TerraME), not scientific
  validation (fit to observed data).

## How they were generated

```bash
docker build -t terrame-luccme .           # this repository's image
benchmark/generate.sh                      # all 23 (about 3 minutes)
benchmark/generate.sh lab01 lab15_md10     # only some
```

The references run from their own folder, with `../data/cs_ac/` and `../data/cs_moju/`
assembled from `luccme/data/test/`; each one's `reference.conf` names the main script,
the output it writes and the original TerraME output used for the cross-check.

`harness.lua` loads the lab script (`LAB=labNN`) or a standalone script
(`SCRIPT=... NAME=...`, run from its own folder) in its own environment and:

- **reads the state of the cells after each `run()` of the model, writing nothing**. The
  LuccME `save` is not used for intermediate years because **in LuccME the years listed
  in `save.saveYears` change the simulation**: in those years the allocation swaps the
  class values for those of the start year before `cs:synchronize()`, and in the
  following year `cell.past` holds the wrong values. Saving every year through `save`
  changes lab01's 2014 `d_out` by up to 0.20 per cell. The original outputs in
  `references/` save only the final year and are not affected;
- keeps LuccME's `print()`, which the labs silence, to produce the log;
- stops the lab from deleting its own final-year output and uses it for the cross-check:
  the last year of the CSV must match the shapefile saved by the script and, for the
  references, the original TerraME output kept in `references/<name>/` (tolerance 1e-9,
  field `crosscheck_vs_original_output` of the manifest);
- runs the file's only function even if it is misnamed: the package's `lab17.lua`
  declares it as `lab10` (a warning goes to the log).

**Reproducibility:** LuccME sums in `pairs()` order, which changes between runs and
alters the last bit (~1e-16). The CSV is written with 12 decimal places, so two
generations agree up to 1e-12: from one generation to the next, a few cells (0 to 3 per
lab in the generations made so far) fall on a rounding boundary and change in the 12th
decimal place. **Always compare with a tolerance** (1e-9 is enough), not by the file's
SHA-256, which is only an integrity check.

## Usage

```python
import pandas as pd

golden = pd.read_csv("benchmark/goldens/lab01_md1643/lab01_md1643.csv.gz")
ref_2014 = golden[golden["year"] == 2014].set_index(["row", "col"])["d_out"]
```

disslucc keeps in its `benchmark/goldens/` a copy of only the goldens its tests use;
each new golden goes there together with the component and the test that use it.
