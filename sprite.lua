local Object = require 'base-class'

local Sprite = Object:extend()

function Sprite.set(self, img, x, y, radians, ox, oy)
	self.img = img
	self.x, self.y = x or 0, y or 0
	self.th = radians or 0
	self.sc = 1
	local iw, ih = img:getDimensions()
	self.ox, self.oy = iw * (ox or 0.5), ih * (oy or 0.5)
end

function Sprite.draw(self)
	local x, y, th = self.x, self.y, self.th
	local sc, ox, oy = self.scale, self.ox, self.oy
	love.graphics.draw(self.img, x, y, th, sc, sc, ox, oy)
end

return Sprite
