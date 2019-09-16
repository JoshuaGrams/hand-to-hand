local Enemy = require 'enemy'
local G = require 'geometry'
local U = require 'util'

local Fish = Enemy:extend()

function Fish.set(self, x, y)
	Enemy.set(self, frames.fish, x, y, 0, 1, 1/5)
	self.r = 38
	self.spinSpeed = 0.6 * math.pi
	self.waitTime = 0.4
	self.dashTime = 0.8
	self.dashSpeed = 250
	self.dash = 0
end

function Fish.ai(self, dt)
	local c = blocks:circleOverlaps(self.x, self.y, self.r)
	if #c > 0 then
		G.bounceAlong(self, c, 0)
	end

	if self.spin then
		self.spin = self.spin - dt
		local aimed, near
		local head = player:head()
		if head then
			local dx, dy = head.x - self.x, head.y - self.y
			local dth = U.wrapAngle(math.atan2(dy, dx) - (self.th + math.pi))
			aimed = math.abs(dth) < math.pi/30
			near = dx*dx + dy*dy <= 640*640
		end
		local chase = self.chase and aimed and near
		local c
		if self.spin <= 0 or chase then
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
			self.chase = math.random() < 0.5
		end
	end
end

return Fish
