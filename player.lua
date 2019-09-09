local Object = require 'base-class'
local Sprite = require 'sprite'
local Trail = require 'trail'
local U = require 'util'

local Player = Object:extend()

function Player.set(self, x, y, radians, segmentImages, shardImage)
	self.segmentImages = segmentImages
	self.shardImage = shardImage

	self.segments = {}
	self.maxSegments = 6
	self:addSegment(x, y, radians)

	self.separation = 100
	self.trail = Trail(10, self.maxSegments * self.separation)

	self.r = 35  -- collision radius of segments

	self.vx, self.vy = 0, 0  -- linear velocity
	self.vMin, self.vMax = 1, 500  -- pixels per second
	self.aMax = self.vMax / 0.6  -- zero to full speed in x seconds
	self.vDecay = 5  -- seconds to reduce velocity by 95%

	self.om = 0  -- angular velocity (omega)
	self.omMin, self.omMax = 0.01 * TURN, 0.9 * TURN  -- radians per second
	self.alMax = self.omMax / 0.2  -- zero to full speed in x seconds
	self.omDecay = 0.8  -- seconds to reduce rotation by 95%
end

function Player.addSegment(self, x, y, radians)
	if #self.segments >= self.maxSegments then
		error("You may only have " .. self.maxSegments .. " aliens in your chain.")
	end
	local img = self.segmentImages[math.random(#self.segmentImages)]
	local sprite = Sprite(img, x, y, radians, 0.45, 0.5)
	table.insert(self.segments, sprite)
end

local function turnHead(self, control, dt)
	local head = self.segments[1]
	local om = self.om + control * self.alMax * dt
	local om0, om1 = math.abs(self.om), math.abs(om)
	if om1 <= self.omMax or om1 < om0 then self.om = om end
	self.om = self.om * U.smoothOver(dt, self.omDecay)
	if math.abs(self.om) < self.omMin then self.om = 0 end
	head.th = U.wrapAngle(head.th + self.om * dt)
end

local function accelerateHead(self, control, dt)
	local head = self.segments[1]
	local fx, fy = math.cos(head.th), math.sin(head.th)
	if control < 0 then control = 0.3 * control end
	local dv = control * self.aMax * dt
	local vx, vy = self.vx + dv * fx, self.vy + dv * fy

	-- Limit max speed.
	local v0 = self.vx*self.vx + self.vy*self.vy
	local v1 = vx*vx + vy*vy
	if v1 < self.vMax * self.vMax or v1 < v0 then
		self.vx, self.vy = vx, vy
	end

	-- Speed decays over time.
	local decay = U.smoothOver(dt, self.vDecay)
	self.vx, self.vy = self.vx * decay, self.vy * decay

	-- Stop drifting when speed is less than vMin.
	if self.vx*self.vx + self.vy*self.vy < self.vMin*self.vMin then
		self.vx, self.vy = 0, 0
	end
end

local function bounceHead(self, map)
	local head = self.segments[1]
	local e = 0.6  -- elasticity (0 to 1)
	local collisions = map:circleOverlaps(head.x, head.y, self.r)
	for _,c in ipairs(collisions) do
		local nx, ny, ov = unpack(c)
		head.x = head.x + nx * ov
		head.y = head.y + ny * ov

		local away = self.vx * nx + self.vy * ny
		if away < 0 then
			self.vx = self.vx - (1+e) * away * nx
			self.vy = self.vy - (1+e) * away * ny
		end
	end
end

local function updateOtherSegments(self, dt)
	local k = 1 - U.smoothOver(dt, 0.5)
	for i=2,#self.segments do
		local th
		local seg = self.segments[i]
		seg.x, seg.y, th = self.trail:at(100*(i-1))
		-- Interpolate angle toward trail direction.
		local dth = k * U.wrapAngle(th - seg.th)
		dth = U.clamp(dth, -self.omMax, self.omMax) -- but limit max speed
		seg.th = seg.th + dth
	end
end

function Player.update(self, dt, turn, accel, map)
	turnHead(self, turn, dt)
	accelerateHead(self, accel, dt)

	local head = self.segments[1]
	head.x, head.y = head.x + self.vx * dt, head.y + self.vy * dt
	bounceHead(self, map)
	
	self.trail:add(head.x, head.y)
	updateOtherSegments(self, dt)
end

function Player.head(self)
	return self.segments[1]
end

function Player.draw(self)
	for i=#self.segments,1,-1 do
		self.segments[i]:draw()
	end
end

return Player
