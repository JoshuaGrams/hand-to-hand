local Grid = require 'grid'
local Object = require 'base-class'
local Segment = require 'segment'
local U = require 'util'

local function randomChoice(chances)
	local rnd, cur = math.random(), 0
	for i,chance in ipairs(chances) do
		cur = cur + chance
		if rnd < cur then return i end
	end
	return #chances
end

local function normalizedChances(chances)
	local sum, c = 0, {}
	for i=1,#chances do sum = sum + chances[i] end
	local scale = 1 / sum
	for i=1,#chances do c[i] = chances[i] * scale end
	return c
end

------------------------------------------------------------------------

local Map = Object:extend()

function Map.set(self, limit, branchChance, dirChances, rooms, spawns)
	self.limit = limit
	self.branchChancePerStep = branchChance or 0
	self.dirChances = normalizedChances(dirChances or {})
	self.rooms = rooms or {}
	local roomChances = {}
	for i,r in ipairs(self.rooms) do
		roomChances[i] = r.chance
	end
	self.roomChances = normalizedChances(roomChances)
	self.spawns = spawns or {}
end

local function Walker(w, x, y, dir)
	return {
		x = x or w.x, y = y or w.y, dir = dir or w.dir,
		dirChances = w.dirChances,
		rooms = w.rooms,
		roomChances = w.roomChances,
		exits = w.exits
	}
end

local directions = { {1, 0}, {0, 1}, {-1, 0}, {0, -1} }
local nineDirections = {
	{-1,-1}, {0,-1}, {1,-1},
	{-1,0},  {0,0},  {1,0},
	{-1,1},  {0,1},  {1,1}
}

local function rotate(dir, x, y)
	local fx, fy = unpack(directions[dir+1])
	local rx, ry = -fy, fx
	return x*fx + y*rx,  x*fy + y*ry
end

local function addFloor(self, col, row)
	local wasFloor = self.floor:at(col, row, true)
	if not wasFloor then
		self.floorCount = self.floorCount + 1
	end
end

local function addRoom(self, room, walker)
	local floor = self.floor
	for _,t in ipairs(room) do
		local tx, ty = rotate(walker.dir, unpack(t))
		addFloor(self, walker.x + tx, walker.y + ty)
	end
end

local function addRandomRoom(self, walker)
	local room = walker.rooms[randomChoice(walker.roomChances)]
	addRoom(self, room, walker)
	walker.exits = room.exits
end

local function exitRandomly(walker)
	local turn = randomChoice(walker.dirChances) - 1
	local oldDir = walker.dir
	if walker.absoluteDirections then
		walker.dir = turn
	else
		walker.dir = (walker.dir + turn) % 4
	end
	-- Choose exit in the new direction.
	local exit = walker.exits[(walker.dir - oldDir) % 4 + 1]
	-- But the room was oriented in the old direction.
	local ex, ey = rotate(oldDir, unpack(exit))
	walker.x, walker.y = walker.x + ex, walker.y + ey
end

local function stepWalkers(self)
	local branch = false
	if math.random() < self.branchChancePerStep then
		branch = self.walkers[math.random(#self.walkers)]
	end

	for _,w in ipairs(self.walkers) do
		addRandomRoom(self, w)
		if w == branch then
			table.insert(self.walkers, Walker(w))
		end
		exitRandomly(w)
	end
end

function generateWalls(self, tilemap)
	tilemap:reset()
	self.floor:foreach(function(floor, col, row)
		for _,dir in ipairs(nineDirections) do
			local x, y = unpack(dir)
			x, y = col + x, row + y
			if not (self.floor:at(x, y) or tilemap:at(x, y)) then
				tilemap:at(x, y, tilemap:random())
			end
		end
	end)
end

local function generateSpawns(self, tilemap)
	local spawns = {}
	for _,spawn in ipairs(self.spawns) do
		for i=1,spawn[1] do
			table.insert(spawns, {unpack(spawn, 2)})
		end
	end
	U.shuffle(spawns)

	local env = getfenv(0)
	for _,spawn in ipairs(spawns) do
		local Spawn, r, dest = unpack(spawn)
		local x, y = tilemap:randomFloor(r)
		if x then
			local obj = Spawn(x, y)
			if env[dest] then
				table.insert(env[dest], obj)
			else
				env[dest] = obj
			end
		end
	end
end

function Map.generate(self, wallTilemap, col, row)
	local unit = wallTilemap.unit
	col, row = col or 0, row or 0
	local x, y = col * unit, row * unit
	self.walkers = {Walker(self, col, row, 0)}
	self.floor = Grid(unit)
	self.floorCount = 0

	if self.limit > 0 then
		for dCol = -1,1 do
			for dRow = -1,1 do
				addFloor(self, col + dCol, row + dRow)
			end
		end
	end

	while(self.floorCount < self.limit) do
		stepWalkers(self)
	end
	generateWalls(self, wallTilemap)

	local tiles = {}
	self.floor:foreach(function(_, col, row)
		local x, y = self.floor:toPixel(col, row)
		table.insert(tiles, {x, y})
	end)
	wallTilemap.floors = tiles
	wallTilemap:removeNear(x, y, 5)

	local rx, ry = wallTilemap:farthestFloor(x, y)
	if rx then table.insert(rescues, Segment(rx, ry)) end
	generateSpawns(self, wallTilemap)

	self.walkers = nil
	self.floor = nil
end

return Map
