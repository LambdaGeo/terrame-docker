# Goldens do LuccME

Resultados de referência (goldens) anuais do TerraME/LuccME, para validar ports do
LuccME (como o [disslucc](https://github.com/dissmodel/disslucc)) algoritmo por
algoritmo. Há 23 goldens:

- os 21 testes funcionais do pacote (`luccme/tests/functional/lab01.lua` … `lab21.lua`),
  com a numeração do pacote;
- 2 referências em `references/` (`lab01_md1643`, `lab15_md10`), que exercitam o laço de
  convergência (ver abaixo).

Todos foram gerados pelos scripts **sem edição**, na imagem deste repositório
(TerraME 2.0.1, TerraLib 5.5.1, LuccME `6244dd4`).

```
benchmark/
├── generate.sh      # gera goldens/<nome>/ (todos ou alguns)
├── harness.lua      # roda um lab ou um script solto e grava o estado anual das células
├── finalize.py      # comprime, confere e escreve o manifest.json
├── references/      # scripts de referência + saída original do TerraME
└── goldens/         # 23 goldens: <nome>.csv.gz, terrame.log, manifest.json
```

## Conteúdo de `goldens/<lab>/`

| Arquivo | Conteúdo |
|---|---|
| `<lab>.csv.gz` | estado de cada célula **ao fim de cada ano**: `year,id,col,row`, `<classe>_out` (resultado da alocação) e `<classe>_pot` (potencial) de todas as classes, com 12 casas decimais |
| `terrame.log` | saída do TerraME: demanda e área alocada por ano, iterações e erro máximo (contínuos) |
| `manifest.json` | origem (script e SHA-256), versões, colunas, anos, SHA-256 do CSV e a verificação cruzada |

`col`/`row` são os atributos das células de entrada (`luccme/data/test/csAC.shp` e
`cs_moju.shp`; no disslucc, `data/input/csAC.zip` e `cs_moju.zip` têm os mesmos valores,
com a coluna `row` do cs_moju chamada `lin`), então alinham direto com uma grade raster.

Ter os `_pot` separados permite validar o componente de potencial antes da alocação.

## Labs e componentes

| Lab | Dados | Anos | Demanda | Potencial | Alocação |
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

### Referências que exercitam a convergência

Os labs do pacote aceitam a primeira alocação em todos os anos (ver abaixo), então não
testam o laço de convergência. Para isso há duas referências em `references/`: scripts
do LuccMe Model Configurator (2017) com os mesmos coeficientes e a mesma demanda de
lab01/lab15, mas `maxDifference` menor. Origem em `references/README.md`.

| Golden | Script | `maxDifference` | Iterações por ano | Confere com a saída original |
|---|---|---|---|---|
| `lab01_md1643` | `lab1_main.lua` + `lab1_submodel.lua` | 1643 (pacote: 5000) | 0, 0, 8, 26, 18, 17, 17 (2008–2014) | `LUCCME_Lab1_2014.zip` (máx. 5e-13) |
| `lab15_md10` | `lab6_main.lua` + `lab6_submodel.lua` | 10 (pacote: 300) | 0, 67, 56, 56, 61, 61 (1999–2004) | `Lab15_2004.zip` (idêntico) |

As saídas mudam de fato em relação aos labs do pacote: `d_out` difere em 20.075 das
46.018 células-ano (lab01) e em 681 das 35.484 (lab15), a partir do primeiro ano em
que há iteração. O número de iterações de cada ano está no `manifest.json`
(`iterations_per_year`) e serve para comparar com o disslucc.

## Limites destes goldens (leia antes de usar como prova)

- **Nos labs do pacote a alocação não itera.** Nos contínuos com log de iterações
  (lab01, 02, 04, 05, 07, 08, 09) e nos discretos CLUE-S (lab14–21), todos os anos são
  aceitos na primeira passada. Esses goldens validam a primeira alocação, **não** o
  laço de convergência; para isso use `lab01_md1643` e `lab15_md10`.
- **O `correctCellChange` do CClueLike nunca roda.** A condição dele é
  `if (cell.regionregionAloc == rNumber)` (`luccme/lua/AllocationCClueLike.lua:503`,
  erro de digitação de `regionAloc`), sempre falsa. Os goldens contínuos com
  `CClueLike` refletem o LuccME **sem** essa correção; um port que a implemente vai
  divergir a partir do primeiro ano com mudança. `CClueLikeSaturation` escreve o nome
  certo e executa a correção.
- **lab15, lab16, lab17 e lab20 têm `*_out` idênticos**; lab15–17 também têm `*_pot`
  idênticos. As demandas `ComputeTwoDates`/`ComputeThreeDates` e o potencial com
  atração/repulsão não mudam o resultado nesses dados. Bater com um deles não
  distingue os outros.
- Os goldens são de engenharia (o port reproduz o TerraME), não de validação
  científica (ajuste a dados observados).

## Como foram gerados

```bash
docker build -t terrame-luccme .           # a imagem deste repositório
benchmark/generate.sh                      # os 23 (cerca de 3 minutos)
benchmark/generate.sh lab01 lab15_md10     # só alguns
```

As referências rodam a partir da própria pasta, com `../data/cs_ac/` e `../data/cs_moju/`
montados a partir de `luccme/data/test/`; o `reference.conf` de cada uma diz qual é o
script principal, a saída que ele grava e a saída original do TerraME usada na
verificação cruzada.

`harness.lua` carrega o script do lab (`LAB=labNN`) ou um script solto
(`SCRIPT=... NAME=...`, rodado na pasta dele) num ambiente próprio e:

- **lê o estado das células depois de cada `run()` do modelo, sem escrever nada**. Não
  se usa o `save` do LuccME para os anos intermediários porque **no LuccME os anos
  listados em `save.saveYears` alteram a simulação**: nesses anos a alocação troca os
  valores das classes pelos do ano inicial antes de `cs:synchronize()`, e no ano seguinte
  `cell.past` fica com os valores errados. Salvar todos os anos pelo `save` muda o
  `d_out` de 2014 do lab01 em até 0,20 por célula. As saídas originais em
  `references/` salvam só o ano final e não são afetadas;
- mantém o `print()` do LuccME, que os labs silenciam, para gerar o log;
- impede que o lab apague a própria saída do ano final e a usa na verificação cruzada:
  o último ano do CSV tem que bater com o shapefile salvo pelo script e, nas
  referências, com a saída original do TerraME guardada em `references/<nome>/`
  (tolerância 1e-9, campo `crosscheck_vs_original_output` do manifesto);
- executa a única função do arquivo mesmo se o nome estiver errado: `lab17.lua` do
  pacote a declara como `lab10` (fica um aviso no log).

**Reprodutibilidade:** o LuccME soma em ordem de `pairs()`, que muda entre execuções e
altera o último bit (~1e-16). O CSV é gravado com 12 casas decimais, então duas gerações
coincidem até 1e-12: de uma geração para outra, poucas células (de 0 a 3 por lab nas
gerações feitas) caem na fronteira do arredondamento e mudam na 12ª casa. **Compare
sempre com tolerância** (1e-9 basta), não pelo SHA-256 do arquivo, que serve só para
integridade.

## Uso

```python
import pandas as pd

golden = pd.read_csv("benchmark/goldens/lab01_md1643/lab01_md1643.csv.gz")
ref_2014 = golden[golden["year"] == 2014].set_index(["row", "col"])["d_out"]
```

O disslucc guarda uma cópia de `goldens/` em `benchmark/goldens/` e a usa nos testes;
para atualizá-la, gere aqui e copie a pasta.
