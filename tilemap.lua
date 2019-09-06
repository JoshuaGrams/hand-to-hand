local Grid = require 'grid'

local TileMap = Grid:extend()

function TileMap.set(self, img, unit, names)
	Grid.set(self, unit)
	self.img = img
	self.names = names

	-- Generate quads.
	local iw, ih = img:getDimensions()
	self.iw, self.ih = iw, ih
	self.quads = {}
	for x=0,iw-1,unit do
		for y=0,ih-1,unit do
			local q = love.graphics.newQuad(x, y, unit, unit, iw, ih)
			table.insert(self.quads, q)
		end
	end
end

function TileMap.draw(self)
	local img, q, u = self.img, self.quads, self.unit
	self:foreach(function(t, col, row)
		love.graphics.draw(img, q[t], u*col, u*row, 0,  1, 1,  u/2, u/2)
	end)
end

function TileMap.random(self)
	if not self.count then
		self.quad = math.random(#self.quads)
		self.count = math.random(20)
	end
	self.count = self.count - 1
	if self.count <= 0 then self.count = nil end
	return self.quad
end

function TileMap.at(self, col, row, tile)
	if tile then
		if type(tile) == 'string' then
			local t = self.names[tile]
			if not t then
				error("No such tile \"" .. tile .. "\".")
			end
			tile = t
		end

		if not self.quads[tile] then
			error("Bad tile index " .. tile .. ".")
		end
	end

	return Grid.at(self, col, row, tile)
end

return TileMap
