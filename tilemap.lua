local G = require 'geometry'
local Grid = require 'grid'

local TileMap = Grid:extend()

function TileMap.set(self, img, unit, radius, names)
	Grid.set(self, unit)
	self.img = img
	self.radius = self.radius or 0
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

local function circleOverlapsTile(self, col, row, cx, cy, r)
	local dx, dy = self:toPixel(col, row)
	dx, dy = cx - dx, cy - dy
	r = r + self.radius
	local s = self.unit - 2 * self.radius
	return G.circleOverlapsSquare(dx, dy, r, s)
end

local nineDirections = {
	{-1,-1}, {0,-1}, {1,-1},
	{-1,0},  {0,0},  {1,0},
	{-1,1},  {0,1},  {1,1}
}

function TileMap.circleOverlaps(self, cx, cy, r)
	local collisions = {}
	local col0, row0 = self:fromPixel(cx, cy)
	for _,dir in ipairs(nineDirections) do
		local col, row = col0 + dir[1], row0 + dir[2]
		if self:at(col, row) then
			local hit = {circleOverlapsTile(self, col, row, cx, cy, r)}
			if hit[1] then table.insert(collisions, hit) end
		end
	end
	return collisions
end

return TileMap
