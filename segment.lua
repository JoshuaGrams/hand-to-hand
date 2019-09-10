local Sprite = require 'sprite'
local U = require 'util'

local Segment = Sprite:extend()

function Segment.set(self, img, x, y, radians, shardImg)
	Sprite.set(self, img, x, y, radians, 0.45, 0.5)
	self.shardImg = shardImg
	self.shards = {}
	self.rightHanded = math.random() < 0.7
	self.handDelay = 0.3  -- seconds
	self.generateEvery = math.ceil(1.9 / self.handDelay)
	self.handTimer = self.handDelay * math.random() 
	self.handTimes = math.random(self.generateEvery) - 1
end

local function handPosition(self, dominant, shard)
	local forward, right = -20, 30
	if self.img == image.alien.blue then
		forward = forward - 7
	end
	local fx, fy = math.cos(self.th), math.sin(self.th)
	local x, y = self.x + forward * fx, self.y + forward * fy

	local rx, ry = -fy, fx
	if dominant ~= self.rightHanded then rx, ry = -rx, -ry end
	x, y = x + right * rx, y + right * ry

	if shard and shard.t then
		x = U.lerp(shard.t, shard.x0, x)
		y = U.lerp(shard.t, shard.y0, y)
	end

	return x, y
end

function Segment.shard(self)
	for s,shard in ipairs(self.shards) do
		if not shard.t then
			table.remove(self.shards, s)
			return shard
		end
	end
end

function Segment.update(self, dt, ahead)
	for _,shard in ipairs(self.shards) do
		if shard.t then
			shard.t = shard.t + dt / (0.5 * self.handDelay)
			if shard.t >= 1 then
				shard.t, shard.x0, shard.y0 = nil
			end
		end
	end

	self.handTimer = self.handTimer - dt
	if self.handTimer <= 0 then
		self.handTimer = self.handDelay
		self.handTimes = self.handTimes + 1

		-- Pass shards up.
		if ahead and #ahead.shards < 2 then
			local shard = self:shard()
			if shard then
				shard.t, shard.x0, shard.y0 = 0, shard.x, shard.y
				table.insert(ahead.shards, shard)
			end
		end

		-- Generate a new shard.
		if self.handTimes >= self.generateEvery and #self.shards < 2 then
			self.handTimes = 0
			local x, y = handPosition(self, #self.shards == 0)
			local th = math.random() * 2*math.pi
			local shard = Sprite(self.shardImg, x, y, th)
			table.insert(self.shards, shard)
		end
	end

	if #self.shards == 2 and (not ahead or #ahead.shards == 2) then
		self.handTimer = self.handDelay
	end
end

function Segment.draw(self)
	Sprite.draw(self)
	for i,shard in ipairs(self.shards) do
		local th = shard.th
		shard.th = shard.th + self.th
		shard.x, shard.y = handPosition(self, i == 1, shard)
		shard:draw()
		shard.th = th
	end
end

return Segment
