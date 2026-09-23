# Goldens dos labs do pacote LuccME

Resultados de referência (goldens) dos 21 testes funcionais do pacote LuccME
(`tests/functional/lab01.lua` … `lab21.lua`), para validar cada algoritmo do
disslucc à medida que ele for implementado. A numeração é a do pacote.

Todos foram gerados pelo script do lab **sem edição**, na imagem Docker
[`LambdaGeo/terrame-docker`](https://github.com/LambdaGeo/terrame-docker)
(TerraME 2.0.1, TerraLib 5.5.1, LuccME `6244dd4`).

## Conteúdo de `goldens/<lab>/`

| Arquivo | Conteúdo |
|---|---|
| `<lab>.csv.gz` | estado de cada célula **ao fim de cada ano**: `year,id,col,row`, `<classe>_out` (resultado da alocação) e `<classe>_pot` (potencial) de todas as classes, com 12 casas decimais |
| `terrame.log` | saída do TerraME: demanda e área alocada por ano, iterações e erro máximo (contínuos) |
| `manifest.json` | origem (script e SHA-256), versões, colunas, anos, SHA-256 do CSV e a verificação cruzada |

`col`/`row` são os atributos das células de entrada (`data/input/csAC.zip`,
`data/input/cs_moju.zip`, idênticos aos do pacote, com a coluna `lin` do cs_moju
chamada `row` no pacote), então alinham direto com a grade raster do disslucc.

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

Hoje o disslucc implementa PreComputedValues, CLinearRegression/DLogisticRegression,
CClueLike e DClueSLike, ou seja, **lab01** e **lab15**.

## Limites destes goldens (leia antes de usar como prova)

- **Nos labs contínuos (lab01–lab09) a alocação nunca itera.** Em todos os anos o log
  mostra `Number of iterations: 0`: o `maxDifference` do pacote (1643–5000) é folgado
  demais, e o primeiro palpite já é aceito. Esses goldens validam o cálculo da primeira
  alocação, **não** o ajuste de elasticidade do CLUE. Para exercitar a convergência é
  preciso um cenário com `maxDifference` menor (o `benchmark/reference/lab1_*.lua`, com
  1643 e regressão linear, itera 17 vezes em 2014).
- **lab15, lab16, lab17 e lab20 têm `*_out` idênticos**; lab15–17 também têm `*_pot`
  idênticos. As demandas `ComputeTwoDates`/`ComputeThreeDates` e o potencial com
  atração/repulsão não mudam o resultado nesses dados. Bater com um deles não
  distingue os outros.
- Os goldens são de engenharia (o port reproduz o TerraME), não de validação
  científica (ajuste a dados observados).

## Como foram gerados

```bash
# 1. Imagem (uma vez): github.com/LambdaGeo/terrame-docker
docker build -t terrame-luccme .

# 2. Goldens (cerca de 3 minutos para os 21)
benchmark/luccme/generate_goldens.sh              # todos
benchmark/luccme/generate_goldens.sh lab01 lab15  # só alguns
```

`harness.lua` carrega o script do lab num ambiente próprio e:

- **lê o estado das células depois de cada `run()` do modelo, sem escrever nada**. Não
  se usa o `save` do LuccME para os anos intermediários porque **no LuccME os anos
  listados em `save.saveYears` alteram a simulação**: nesses anos a alocação troca os
  valores das classes pelos do ano inicial antes de `cs:synchronize()`, e no ano seguinte
  `cell.past` fica com os valores errados. Salvar todos os anos pelo `save` muda o
  `d_out` de 2014 do lab01 em até 0,20 por célula. Os goldens antigos em
  `benchmark/data/` salvam só o ano final e não são afetados;
- mantém o `print()` do LuccME, que os labs silenciam, para gerar o log;
- impede que o lab apague a própria saída do ano final e a usa na verificação cruzada:
  o último ano do CSV tem que bater com o shapefile salvo pelo lab (tolerância 1e-9,
  campo `crosscheck_vs_original_output` do manifesto);
- executa a única função do arquivo mesmo se o nome estiver errado: `lab17.lua` do
  pacote a declara como `lab10` (fica um aviso no log).

**Reprodutibilidade:** o LuccME soma em ordem de `pairs()`, que muda entre execuções e
altera o último bit (~1e-16). Com 12 casas decimais, duas gerações completas dos 21 labs
produziram arquivos idênticos byte a byte.

## Uso no disslucc

```python
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
golden = pd.read_csv(ROOT / "benchmark" / "luccme" / "goldens" / "lab01" / "lab01.csv.gz")

g2014 = golden[golden["year"] == 2014]
ref = g2014.set_index(["row", "col"])["d_out"]
# compare com backend.get("d")[rows, cols] ano a ano (pontius_millones etc.)
```
