local Enemy = require 'enemy'
local G = require 'geometry'
local U = require 'util'

local Fish = Enemy:extend()

function Fish.set(self, x, y)
	Enemy.set(self, frames.fish, x, y, 0, 1, 1/5)
	self.r = 38
	self.spinSpeed = 0.4 * math.pi
	self.waitTime = 0.5
	self.dashTime = 0.8
	self.dashSpeed = 250
	self.dash = 0
end

function Fish.ai(self, dt)
	local c = blocks:circleOverlaps(self.x, self.y, self.r)
	if #c > 0 then
		G.bounceAlong(self, c, 1)
	end

	if self.spin then
		self.spin = self.spin - dt
		if self.spin <= 0 then
			self.spin = nil
			self.om = 0
			self.wait = self.waitTime
		end
	elseif self.wait then
		self.wait = self.wait - dt
		if self.wait <= 0 then
			self.wait = nil
			self.om = 0
			self.dash = self.dashTime
			local th = self.th + math.pi
			local dx, dy = math.cos(th), math.sin(th)
			self.vx = self.dashSpeed * dx
			self.vy = self.dashSpeed * dy
		end
	elseif self.dash then
		self.dash = self.dash - dt
		if self.dash <= 0 then
			self.dash = 0
			self.vx, self.vy = 0, 0
			local sign = math.random() < 0.5 and -1 or 1
			self.spinSign = sign
			self.om = self.spinSpeed * sign
			local turn = U.randomIn(math.pi, 2*math.pi)
			self.spin = turn / self.spinSpeed
		end
	end
end

return Fish
