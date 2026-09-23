# Scripts de referência (origem)

Scripts do "LuccMe Model Configurator" guardados **sem alteração** (conteúdo idêntico
byte a byte aos originais), junto com a saída que o TerraME gerou com eles. Até esta
mudança ficavam no disslucc (`benchmark/reference/` e `benchmark/data/`), onde os números
de `docs/validation.md` (citados no artigo do JOSS) foram obtidos.

| Pasta | Scripts | `LuccMEModel.name` | Saída original | Gerado em |
|---|---|---|---|---|
| `lab01_md1643/` | `lab1_main.lua` + `lab1_submodel.lua` | `Lab1` | `LUCCME_Lab1_2014.zip` (`Lab1_2014.*`) | scripts de 2017-09-25, LuccME 3.1 |
| `lab15_md10/` | `lab6_main.lua` + `lab6_submodel.lua` | `Lab6` | `Lab15_2004.zip` (`Lab15_2004.*`, originalmente `Lab6_2004.*`) | scripts de 2017-05-11, LuccME 3.0 |

## Relação com os labs do pacote

Os labs públicos `luccme/tests/functional/lab01.lua` e `lab15.lua` têm os mesmos
coeficientes de regressão e a mesma demanda, mas outro `maxDifference`:

| Cenário | Aqui | `maxDifference` aqui | Lab do pacote | `maxDifference` no pacote |
|---|---|---|---|---|
| contínuo (csAC, 2008–2014) | `lab01_md1643` | 1643 | `lab01` | 5000 |
| discreto (cs_moju, 1999–2004) | `lab15_md10` | 10 | `lab15` | 300 |

Com o `maxDifference` do pacote a alocação é aceita na primeira passada em todos os anos;
com os daqui ela itera (8–26 vezes por ano no contínuo, 56–67 no discreto). Por isso os
nomes: o número do lab do pacote mais o `maxDifference`.

O script discreto se chama `lab6` porque foi exportado como "Lab6" em 2017; no disslucc
ele era chamado de "Lab15". Aqui ele mantém o nome original, e a pasta leva o número do
lab do pacote que ele corresponde.

## Arquivos auxiliares

- `reference.conf`: lido por `benchmark/generate.sh` (script principal, camada de
  entrada, saída gravada e saída original para a verificação cruzada).
- Os scripts leem `../data/cs_ac/csAC.shp` e `../data/cs_moju/cs_moju.shp`; o gerador
  monta essas pastas a partir de `luccme/data/test/`, que tem os mesmos dados.
- `lab1_main.lua` tem um bloco de `print` de depuração e um evento `Map`, que exige tela;
  sem tela, o gerador roda com `-autoclose`. Nenhum dos dois altera o resultado: a saída
  reproduz `LUCCME_Lab1_2014.zip` (máx. 5e-13).
