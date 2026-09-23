--------------------------------------------------------------------------------
-- Gera os goldens de um lab do pacote LuccME (tests/functional/labNN.lua)
-- sem editar o script do lab. Roda dentro da imagem terrame-luccme:
--
--   docker run --rm -e LAB=lab01 -e OUT=/work/out/lab01 -v "$PWD":/work \
--       terrame-luccme -autoclose harness.lua
--
-- Saídas em OUT:
--   <lab>.csv                   estado de todas as células ao fim de cada ano:
--                               year,id,col,row,<classe>_out...,<classe>_pot...
--   <Lab>_<anoFinal>.{shp,dbf,...}  a saída original do lab (save do próprio script)
--
-- O que o arnês muda em relação ao teste original:
--   * NÃO mexe no save do modelo. No LuccME, os anos listados em save.saveYears
--     alteram a simulação (a alocação troca os valores pelos do ano inicial antes
--     de cs:synchronize(), e cell.past fica errado no ano seguinte). Por isso os
--     anos intermediários são lidos aqui, só em leitura, depois de cada run();
--   * mantém o print() do LuccME (os labs o silenciam), para o log ir junto;
--   * guarda a saída do ano final antes que o lab a apague;
--   * unitTest é um stub: nenhum assert/snapshot é executado.
-- Parâmetros do modelo (demanda, coeficientes, maxDifference etc.) ficam intactos.
--------------------------------------------------------------------------------

import("luccme")

local lab = assert(os.getenv("LAB"), "defina LAB, ex.: LAB=lab01")
local out = assert(os.getenv("OUT"), "defina OUT, ex.: OUT=/work/out/lab01")
os.execute('mkdir -p "' .. out .. '"')

local pkg = tostring(packageInfo("luccme").path)
local testFile = pkg .. "/tests/functional/" .. lab .. ".lua"
local dataDir = pkg .. "/data/test"

local function listDir(dir)
	local set = {}
	local p = io.popen('ls -1 "' .. dir .. '"')
	for name in p:lines() do set[name] = true end
	p:close()
	return set
end

-- 12 casas decimais (precisão absoluta 1e-12): o LuccME soma em ordem de pairs(),
-- que varia entre execuções e muda o último bit (~1e-16). Arredondado, o arquivo
-- sai idêntico a cada execução.
local function fmt(v)
	if type(v) == "number" then
		if v == math.floor(v) and math.abs(v) < 1e15 then return string.format("%d", v) end
		local s = string.format("%.12f", v):gsub("0+$", ""):gsub("%.$", "")
		if s == "-0" then s = "0" end
		return s
	end
	if v == nil then return "" end
	return tostring(v)
end

-- Grava o estado das células depois de cada run() do modelo (somente leitura)
local csvFile, columns

local function dump(model, year)
	if not csvFile then
		columns = {}
		for _, lu in ipairs(model.landUseTypes) do columns[#columns + 1] = lu .. "_out" end
		for _, lu in ipairs(model.landUseTypes) do columns[#columns + 1] = lu .. "_pot" end
		csvFile = assert(io.open(out .. "/" .. lab .. ".csv", "w"))
		csvFile:write("year,id,col,row," .. table.concat(columns, ",") .. "\n")
		print(string.format("[harness] %s: %s, anos %d..%d, colunas %s", lab, model.name,
			model.startTime, model.endTime, table.concat(columns, ",")))
	end
	for _, cell in ipairs(model.cs.cells) do
		-- col/row: atributos da camada de entrada (o y do TerraME é invertido)
		local row = {year, cell:getId(), fmt(cell.col or cell.x), fmt(cell.row or cell.lin or cell.y)}
		for _, c in ipairs(columns) do row[#row + 1] = fmt(cell[c]) end
		csvFile:write(table.concat(row, ","), "\n")
	end
end

local originalModel = LuccMEModel
local function patchedModel(t)
	local m = originalModel(t)
	local run = m.run
	m.run = function(self, event, ...)
		local r = run(self, event, ...)
		dump(self, event:getTime())
		return r
	end
	return m
end

-- Os labs apagam a saída do ano final ao terminar: neutraliza só esses delete()
local function patchedFilePath(f, p)
	local r = filePath(f, p)
	if type(f) == "string" and f:match("^test/Lab") then
		r.delete = function() end
	end
	return r
end

local env = setmetatable({
	LuccMEModel = patchedModel,
	filePath = patchedFilePath,
}, {
	__index = _G,
	__newindex = function(t, k, v)
		if k ~= "print" then rawset(t, k, v) end -- ignora print = function() end
	end,
})

local before = listDir(dataDir)

local chunk = assert(loadfile(testFile, "t", env))
local tests = chunk()
local unitTest = setmetatable({}, {__index = function() return function() end end})
-- Usa a única função do arquivo: lab17.lua do pacote a declara como "lab10"
local names = {}
for name in pairs(tests) do names[#names + 1] = name end
assert(#names == 1, lab .. ".lua deveria ter uma única função de teste")
if names[1] ~= lab then
	print(string.format("[harness] aviso: %s.lua declara a função '%s'", lab, names[1]))
end
tests[names[1]](unitTest)

if csvFile then csvFile:close() end

-- Move a saída original do lab (arquivos novos na pasta de dados) para OUT
local moved = 0
for name in pairs(listDir(dataDir)) do
	if not before[name] then
		os.execute('mv "' .. dataDir .. "/" .. name .. '" "' .. out .. '/"')
		moved = moved + 1
	end
end
print(string.format("[harness] %s: CSV + %d arquivos da saída original em %s", lab, moved, out))
