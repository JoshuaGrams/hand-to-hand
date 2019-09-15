local Enemy = require 'enemy'

local Block = Enemy:extend()

local directions = {{1, 0}, {0, 1}}

function Block.set(self, x, y)
	Enemy.set(self, frames.block, x, y, 0, 1, 5)
	self.r = 52
	local col, row = blocks:fromPixel(self.x, self.y)
	local s, c, r
	for _,dir in ipairs(directions) do
		s, c, r = 0, unpack(dir)
		if not blocks:at(col + c, row + r) then
			s = s + 1
		end
		if not blocks:at(col - c, row - r) then
			s = s + 1
			col, row = col - c, row - r
		end
		if s > 0 then break end
	end
	col = col - 0.25 * c
	row = row - 0.25 * r
	c, r = (s + 0.5) * c, (s + 0.5) * r
	self.start = {blocks:toPixel(col, row)}
	self.finish = {blocks:toPixel(col + c, row + r)}
	self.speed = 250
end

function Block.ai(self, dt)
	if self.wait then
		self.wait = self.wait - dt
		if self.wait <= 0 then
			self.wait = nil
			self.start, self.finish = self.finish, self.start
		end
	else
		local x, y = unpack(self.finish)
		local dx, dy = x - self.x, y - self.y
		if dx*dx + dy*dy < self.speed * 10 * dt then
			self.wait = 0.5
		else
			local s = 1 / math.sqrt(dx*dx + dy*dy)
			dx, dy = s * dx, s * dy
			self.x = self.x + dx * self.speed * dt
			self.y = self.y + dy * self.speed * dt
		end
	end
end

return Block
