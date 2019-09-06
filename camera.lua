local abs = math.abs
local sqrt = math.sqrt
local sin, cos, pi = math.sin, math.cos, math.pi

local function bounds(self, aspect)
	-- Get width and height from area and aspect.
	local w = sqrt(self.area * aspect)
	local h = sqrt(self.area / aspect)
	-- Use angle to get rotated width and height
	local c, s = cos(self.angle), sin(self.angle)
	local ac, as = abs(c), abs(s)
	local rw = w * ac + h * as
	local rh = w * as + h * ac
	-- Center of bounding box.
	local dx, dy = w * (0.5 - self.ox), h * (0.5 - self.oy)
	local rx = self.cx + (dx * c - dy * s)
	local ry = self.cy + (dx * s + dy * c)

	-- Return bounds.
	return {
		xMin = rx - 0.5 * rw, xMax = rx + 0.5 * rw,
		yMin = ry - 0.5 * rh, yMax = ry + 0.5 * rh
	}
end

local function fit(self, w, h)
	return sqrt(w*h / self.area)
end

local function use(self)
	local w, h = love.graphics.getDimensions()
	self.scale = self:fit(w, h)
	self.bounds = bounds(self, w/h)
	love.graphics.translate(w*self.ox, h*self.oy)
	love.graphics.rotate(self.angle)
	love.graphics.scale(self.scale)
	love.graphics.translate(-self.cx, -self.cy)
end

local function toWorld(self, xWindow, yWindow)
	local w, h = love.graphics.getDimensions()
	local scale = 1 / self:fit(w, h)
	local c, s = cos(self.angle), sin(self.angle)
	local x = (xWindow - w*self.ox) * scale
	local y = (yWindow - h*self.oy) * scale
	local xWorld = self.cx + x*c + y*s
	local yWorld = self.cy - x*s + y*c
	return xWorld, yWorld
end

local function toWindow(self, xWorld, yWorld)
	local w, h = love.graphics.getDimensions()
	local scale = self:fit(w, h)
	local c, s = cos(-self.angle), sin(-self.angle)
	local x = (xWorld - self.cx) * scale
	local y = (yWorld - self.cy) * scale
	local xWindow = w*self.ox + x * c + y * s
	local yWindow = h*self.oy - x * s + y * c
	return xWindow, yWindow
end

local function follow(self, x, y, dt, time, convergence)
	local k = 1
	if time and convergence then
		k = 1 - (1 - convergence)^(dt/time)
	end
	self.cx = self.cx + k * (x - self.cx)
	self.cy = self.cy + k * (y - self.cy)
end

local methods = {
	use = use,
	toWorld = toWorld,
	toWindow = toWindow,
	follow = follow,
	fit = fit
}
local class = { __index = methods }

local function new(cx, cy, area, angle)
	local w, h = love.graphics.getDimensions()
	local ox, oy = 0.5, 0.5
	local camera = setmetatable({
		ox = ox, oy = oy,
		cx = cx or w*ox,  cy = cy or h*oy,
		area = area or w*h,
		angle = angle or 0
	}, class)
	camera.bounds = bounds(camera, w/h)
	return camera
end

return { new = new, methods = methods, class = class }
