--------------------------------------------------------------------------------
-- Generates the goldens of a LuccME package lab (tests/functional/labNN.lua)
-- without editing the lab script. Runs inside the terrame-luccme image:
--
--   docker run --rm -e LAB=lab01 -e OUT=/work/out/lab01 -v "$PWD":/work \
--       terrame-luccme -autoclose /work/harness.lua
--
-- Or a standalone LuccME script (e.g. benchmark/references/lab01_md1643/lab1_main.lua),
-- run from its own folder; NAME names the CSV:
--
--   docker run --rm -e SCRIPT=/work/references/lab01_md1643/lab1_main.lua -e NAME=lab01_md1643 \
--       -e OUT=/work/out/lab01_md1643 -v "$PWD":/work terrame-luccme -autoclose /work/harness.lua
--
-- Outputs in OUT:
--   <lab>.csv                         state of every cell at the end of every year:
--                                     year,id,col,row,<class>_out...,<class>_pot...
--   <Lab>_<finalYear>.{shp,dbf,...}   the lab's own output (its own save)
--
-- What the harness changes relative to the original test:
--   * it does NOT touch the model's save. In LuccME, the years listed in
--     save.saveYears change the simulation (the allocation swaps the values for
--     those of the start year before cs:synchronize(), and cell.past is wrong in
--     the following year). So intermediate years are read here, read-only, after
--     each run();
--   * it keeps LuccME's print() (the labs silence it), so the log is kept;
--   * it keeps the final-year output before the lab deletes it;
--   * unitTest is a stub: no assert/snapshot runs.
-- Model parameters (demand, coefficients, maxDifference, etc.) are untouched.
--------------------------------------------------------------------------------

import("luccme")

local script = os.getenv("SCRIPT")
local lab = script and assert(os.getenv("NAME"), "with SCRIPT, set NAME")
	or assert(os.getenv("LAB"), "set LAB (e.g. lab01) or SCRIPT + NAME")
local out = assert(os.getenv("OUT"), "set OUT, e.g. OUT=/work/out/lab01")
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

-- 12 decimal places (absolute precision 1e-12): LuccME sums in pairs() order, which
-- varies between runs and changes the last bit (~1e-16). Rounded, two runs agree
-- up to 1e-12.
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

-- Writes the state of the cells after each run() of the model (read-only)
local csvFile, columns

local function dump(model, year)
	if not csvFile then
		columns = {}
		for _, lu in ipairs(model.landUseTypes) do columns[#columns + 1] = lu .. "_out" end
		for _, lu in ipairs(model.landUseTypes) do columns[#columns + 1] = lu .. "_pot" end
		csvFile = assert(io.open(out .. "/" .. lab .. ".csv", "w"))
		csvFile:write("year,id,col,row," .. table.concat(columns, ",") .. "\n")
		print(string.format("[harness] %s: %s, years %d..%d, columns %s", lab, model.name,
			model.startTime, model.endTime, table.concat(columns, ",")))
	end
	for _, cell in ipairs(model.cs.cells) do
		-- col/row: attributes of the input layer (TerraME's y is flipped)
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

-- The labs delete their final-year output when they finish: neutralise only those delete()
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
		if k ~= "print" then rawset(t, k, v) end -- ignores print = function() end
	end,
})

local unitTest = setmetatable({}, {__index = function() return function() end end})

if script then
	-- Standalone script: runs in its own folder (its relative paths keep working)
	local dir = script:match("^(.*)/[^/]*$") or "."
	local cwd = currentDir()
	Directory(dir):setCurrentDir()
	local chunk = assert(loadfile(script, "t", env))
	chunk()
	cwd:setCurrentDir()
else
	local before = listDir(dataDir)
	local chunk = assert(loadfile(testFile, "t", env))
	local tests = chunk()
	-- Uses the file's only function: the package's lab17.lua declares it as "lab10"
	local names = {}
	for name in pairs(tests) do names[#names + 1] = name end
	assert(#names == 1, lab .. ".lua should hold a single test function")
	if names[1] ~= lab then
		print(string.format("[harness] warning: %s.lua declares the function '%s'", lab, names[1]))
	end
	tests[names[1]](unitTest)

	-- Moves the lab's own output (new files in the data folder) to OUT
	local moved = 0
	for name in pairs(listDir(dataDir)) do
		if not before[name] then
			os.execute('mv "' .. dataDir .. "/" .. name .. '" "' .. out .. '/"')
			moved = moved + 1
		end
	end
	print(string.format("[harness] %s: %d files of the lab's own output in %s", lab, moved, out))
end

if csvFile then csvFile:close() end
print(string.format("[harness] %s: CSV written to %s", lab, out))
