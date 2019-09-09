local Sprite = require 'sprite'

local Shard = Sprite:extend()

local function position(self)
	local alien, right = self.alien, self.right
	local offset = 30
	local ox, oy = -math.sin(alien.th), math.cos(alien.th)
	ox, oy = offset * ox, offset * oy
	if not right then ox, oy = -ox, -oy end
	x, y = alien.x + ox, alien.y + oy
	return x, y
end

function Shard.set(self, alien, right)
	self.alien, self.right = alien, right
	local x, y = position(self)
	local th = math.random() * 2*math.pi
	Sprite.set(self, image.shard, x, y, th)
end

function Shard.draw(self)
	local oldAngle = self.th
	self.x, self.y = position(self)
	self.th = self.th + self.alien.th
	Sprite.draw(self)
	self.th = oldAngle
end

return Shard
