local Enemy = require 'enemy'
local G = require 'geometry'
local U = require 'util'

local Fly = Enemy:extend()

local function changeDirection(self)
	local lo, hi = 100, 250
	self.speed = U.randomIn(100, 250)
	lo, hi = 0.25 * math.pi, 0.75 * math.pi
	self.om = U.randomIn(0.25, 0.75) * math.pi
	if math.random() < 0.5 then self.om = -self.om end
	self.seconds = 2*math.pi / math.abs(self.om)
	self.seconds = self.seconds * U.randomIn(0.75, 1)
end

function Fly.set(self, x, y)
	Enemy.set(self, frames.fly, x, y, 0, 0.7, 1/30)
	changeDirection(self)
end

function Fly.ai(self, dt)
	local fwd = U.wrapAngle(self.th + math.pi)
	local fx, fy = math.cos(fwd), math.sin(fwd)
	self.vx, self.vy = self.speed * fx, self.speed * fy

	local c = blocks:circleOverlaps(self.x, self.y, 20)
	if #c > 0 then
		G.bounceAlong(self, c, 1)
		self.th = U.wrapAngle(math.atan2(self.vy, self.vx) + math.pi)
		changeDirection(self)
	else
		self.seconds = self.seconds - dt
		if self.seconds <= 0 then changeDirection(self) end
	end
end


return Fly
