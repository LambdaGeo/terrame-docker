-- TerraME hello world: checks that the image works.
-- Usage: docker run --rm -v "$PWD/models":/work terrame-luccme hello_world.lua

print("TerraME " .. packageInfo("base").version .. " running in Docker")

-- 10x10 cellular space; every cell starts with a random value
local cs = CellularSpace{
	xdim = 10,
	instance = Cell{
		value = Random{min = 0, max = 1},
		execute = function(cell)
			cell.value = cell.value * 0.9 -- decays 10% per step
		end
	}
}

local total_value = function()
	local total = 0
	forEachCell(cs, function(cell) total = total + cell.value end)
	return total
end

print(string.format("Initial sum: %.2f", total_value()))

Timer{Event{action = cs}}:run(10)

print(string.format("Sum after 10 steps: %.2f", total_value()))
print("OK!")
