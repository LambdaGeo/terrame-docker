-- Hello world do TerraME: confirma que a imagem funciona.
-- Uso: docker run --rm -v "$PWD/models":/work terrame-luccme hello_world.lua

print("TerraME " .. packageInfo("base").version .. " rodando no Docker")

-- Espaço celular 10x10 em que cada célula começa com valor aleatório
local cs = CellularSpace{
	xdim = 10,
	instance = Cell{
		value = Random{min = 0, max = 1},
		execute = function(cell)
			cell.value = cell.value * 0.9 -- decai 10% por passo
		end
	}
}

local soma = function()
	local total = 0
	forEachCell(cs, function(cell) total = total + cell.value end)
	return total
end

print(string.format("Soma inicial: %.2f", soma()))

Timer{Event{action = cs}}:run(10)

print(string.format("Soma após 10 passos: %.2f", soma()))
print("OK!")
