local Object = require 'base-class'

local Enemy = Object:extend()

function Enemy.set(self, quads, x, y, radians, scale, frameDelay)
	self.img = img
	self.frames = quads
	self.x, self.y = x or 0, y or 0
	self.th = radians or 0
	self.sc = scale or 1
	self.frame = 1
	self.frameDelay = frameDelay or 0.1
	self.frameTimer = self.frameDelay
	self.health = 1
	self.r = 0
	self.deadTime = 1
end

function Enemy.update(self, dt)
	if self.dead then
		self.dead = self.dead - dt
		if self.dead <= 0 then
			self.delete = true
		else
			self.sc = math.max(0, self.sc - dt)
			self.th = self.th + dt * 10*math.pi
		end
	end

	if self.ai then self:ai(dt) end

	if self.vx then
		self.x = self.x + self.vx * dt
		self.y = self.y + self.vy * dt
	end
	if self.om then
		self.th = self.th + self.om * dt
	end

	self.frameTimer = self.frameTimer - dt
	if self.frameTimer <= 0 then
		self.frameTimer = self.frameDelay
		self.frame = self.frame + 1
		if self.frame > #self.frames then self.frame = 1 end
	end
end

function Enemy.hit(self, damage)
	self.health = self.health - 1
	if self.health <= 0 then self.dead = self.deadTime end
end

function Enemy.draw(self)
	local x, y, th, sc = self.x, self.y, self.th, self.sc
	local f = self.frames[self.frame]
	love.graphics.draw(f.img, f.quad, x, y, th, sc, sc, f.ox, f.oy)
end

return Enemy
