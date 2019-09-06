local Object = require 'base-class'

local Grid = Object:extend()

function Grid.set(self, unit)
	self.unit = unit
	self:reset()
end

function Grid.reset(self)
	self.cells = {}
end

function Grid.at(self, col, row, cell)
	if cell then
		if not self.cells[col] then self.cells[col] = {} end
		cell, self.cells[col][row] = self.cells[col][row], cell
	else
		cell = self.cells[col] and self.cells[col][row]
	end
	return cell
end

function Grid.foreach(self, action)
	for col,cells in pairs(self.cells) do
		for row,cell in pairs(cells) do
			action(cell, col, row)
		end
	end
end

-- Grid cells are centered on integer multiples of the unit,
-- e.g. (0, 0) is the center of a grid cell.
function Grid.fromPixel(self, x, y)
	local col = math.floor(0.5 + x/self.unit)
	local row = math.floor(0.5 + y/self.unit)
	return col, row
end

-- Return center of grid cell.
function Grid.toPixel(self, col, row)
	local x = self.unit * col
	local y = self.unit * row
	return x, y
end

return Grid
