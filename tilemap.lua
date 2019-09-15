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

function TileMap.removeNear(self, x, y, r)
	r = r * self.unit
	local d2 = r * r
	for i=#self.floors,1,-1 do
		local fx, fy = unpack(self.floors[i])
		local dx, dy = fx - x, fy - y
		if dx*dx + dy*dy <= d2 then
			table.remove(self.floors, i)
		end
	end
end

function TileMap.randomFloor(self, removeWithin)
	local floors = self.floors
	if floors and #floors > 0 then
		local x, y = unpack(floors[math.random(#floors)])
		self:removeNear(x, y, removeWithin or 0.5)
		return x, y
	end
end

function TileMap.farthestFloor(self, x, y, removeWithin)
	local floors = self.floors or {}
	local farthest, dist2 = false
	for _,floor in ipairs(floors) do
		local fx, fy = unpack(floor)
		local dx, dy = fx - x, fy - y
		local d2 = dx*dx + dy*dy
		if not farthest or d2 > dist2 then
			farthest, dist2 = floor, d2
		end
	end
	if farthest then
		local fx, fy = unpack(farthest)
		self:removeNear(fx, fy, removeWithin or 0.5)
		return unpack(farthest)
	end
end

return TileMap
