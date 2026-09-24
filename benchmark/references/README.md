# Reference scripts (provenance)

"LuccMe Model Configurator" scripts kept **unchanged** (byte-for-byte identical to the
originals), together with the output TerraME produced from them. Until this move they
lived in disslucc (`benchmark/reference/` and `benchmark/data/`), where the numbers in
its `docs/validation.md` (cited in the JOSS paper) were obtained.

| Folder | Scripts | `LuccMEModel.name` | Original output | Created |
|---|---|---|---|---|
| `lab01_md1643/` | `lab1_main.lua` + `lab1_submodel.lua` | `Lab1` | `LUCCME_Lab1_2014.zip` (`Lab1_2014.*`) | scripts of 2017-09-25, LuccME 3.1 |
| `lab15_md10/` | `lab6_main.lua` + `lab6_submodel.lua` | `Lab6` | `Lab15_2004.zip` (`Lab15_2004.*`, originally `Lab6_2004.*`) | scripts of 2017-05-11, LuccME 3.0 |

## Relation to the package labs

The public labs `luccme/tests/functional/lab01.lua` and `lab15.lua` have the same
regression coefficients and the same demand, but a different `maxDifference`:

| Scenario | Here | `maxDifference` here | Package lab | `maxDifference` in the package |
|---|---|---|---|---|
| continuous (csAC, 2008–2014) | `lab01_md1643` | 1643 | `lab01` | 5000 |
| discrete (cs_moju, 1999–2004) | `lab15_md10` | 10 | `lab15` | 300 |

With the package's `maxDifference` the allocation is accepted at the first pass in every
year; with the ones here it iterates (up to 26 times per year in the continuous case, 56–67
in the discrete one). Hence the names: the package lab number plus the `maxDifference`.

The discrete script is called `lab6` because it was exported as "Lab6" in 2017; disslucc
used to call it "Lab15". Here it keeps its original name, and the folder takes the number
of the package lab it corresponds to.

## Auxiliary files

- `reference.conf`: read by `benchmark/generate.sh` (main script, input layer, output it
  writes, and original output for the cross-check).
- The scripts read `../data/cs_ac/csAC.shp` and `../data/cs_moju/cs_moju.shp`; the
  generator assembles those folders from `luccme/data/test/`, which holds the same data.
- `lab1_main.lua` has a debugging `print` block and a `Map` event, which needs a display;
  without one, the generator runs with `-autoclose`. Neither changes the result: the
  output reproduces `LUCCME_Lab1_2014.zip` (max. 5e-13).
