local G = require 'geometry'
local Object = require 'base-class'
local Segment = require 'segment'
local Trail = require 'trail'
local U = require 'util'

local Player = Object:extend()

function Player.set(self, x, y, radians)
	self.segments = {}
	self.maxSegments = 6
	self:addSegment(Segment(x, y, radians))

	self.separation = 100
	self.trail = Trail(10, self.maxSegments * self.separation)

	self.r = 35  -- collision radius of segments

	self.vx, self.vy = 0, 0  -- linear velocity
	self.vMin, self.vMax = 1, 500  -- pixels per second
	self.aMax = self.vMax / 0.55  -- zero to full speed in x seconds
	self.vDecay = 5  -- seconds to reduce velocity by 95%

	self.om = 0  -- angular velocity (omega)
	self.omMin, self.omMax = 0.01 * TURN, 0.75 * TURN  -- radians per second
	self.alMax = self.omMax / 0.3  -- zero to full speed in x seconds
	self.omDecay = 0.5  -- seconds to reduce rotation by 95%

	self.shardSpeed = 700
	self.fireDelay = 0.2
end

function Player.addSegment(self, seg)
	if #self.segments >= self.maxSegments then
		error("You may only have " .. self.maxSegments .. " aliens in your chain.")
	end
	table.insert(self.segments, seg)
end

local function turnHead(self, control, dt)
	local head = self.segments[1]
	local om = self.om + control * self.alMax * dt
	local om0, om1 = math.abs(self.om), math.abs(om)
	if om1 <= self.omMax or om1 < om0 then self.om = om end
	if math.abs(control) < 0.1 then
		self.om = self.om * U.smoothOver(dt, self.omDecay)
	end
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
	if v1 > self.vMax*self.vMax then
		local s = self.vMax / math.sqrt(v1)
		vx, vy = s * vx, s * vy
	end
	self.vx, self.vy = vx, vy

	-- Speed decays over time.
	if math.abs(control) < 0.1 then
		local decay = U.smoothOver(dt, self.vDecay)
		self.vx, self.vy = self.vx * decay, self.vy * decay
	end

	-- Stop drifting when speed is less than vMin.
	if self.vx*self.vx + self.vy*self.vy < self.vMin*self.vMin then
		self.vx, self.vy = 0, 0
	end
end

local function bounceHead(head, player, map)
	local e = 0.6  -- elasticity (0 to 1)
	local collisions = map:circleOverlaps(head.x, head.y, player.r)
	G.bounceAlong(head, collisions, 0.6, player)
end

local function turnTowards(seg, th, k, omMax)
	local dth = k * U.wrapAngle(th - seg.th)
	dth = U.clamp(dth, -omMax, omMax) -- but limit max speed
	seg.th = seg.th + dth
end

local function circlesOverlap(a, b, R)
	local dx, dy = b.x - a.x, b.y - a.y
	return dx*dx + dy*dy <= R*R
end

local function performRescue(self, seg)
	for i=#rescues,1,-1 do
		local rescue = rescues[i]
		if circlesOverlap(seg, rescue, 2*self.r) then
			if rescue.wait == nil then
				table.remove(rescues, i)
				self:addSegment(rescue)
				if #rescues == 0 then nextLevel() end
			else
				rescue.wait = false
			end
		elseif rescue.wait == false then
			rescue.wait = nil
		end
	end
end

local function hitEnemy(self, seg)
	for i=#enemies,1,-1 do
		local enemy = enemies[i]
		if not enemy.dead and circlesOverlap(seg, enemy, self.r + enemy.r) then
			enemy:hit(enemy.health)
			return true
		end
	end
	return false
end

function Player.update(self, dt, control, map)
	if #self.segments == 0 then return end

	turnHead(self, control.turn, dt)
	accelerateHead(self, control.accel, dt)

	local k = 1 - U.smoothOver(dt, 0.5)
	local hit = {}
	for s,seg in ipairs(self.segments) do
		if s == 1 then  -- leader
			seg.x, seg.y = seg.x + self.vx * dt, seg.y + self.vy * dt
			bounceHead(seg, self, map)
			self.trail:add(seg.x, seg.y)
			performRescue(self, seg)
		else  -- follower
			local x, y, th = self.trail:at(100 * (s-1))
			seg.x, seg.y = x, y
			turnTowards(seg, th, k, self.omMax)
		end
		if hitEnemy(self, seg) then
			table.insert(hit, s)
		else
			seg:update(dt, self.segments[s-1])
		end
	end

	for i=#hit,1,-1 do
		local s = hit[i]
		local seg = table.remove(self.segments, s)
		seg.t, seg.dt = 1, 1/5
		if s == 1 then seg.wait = true end
		table.insert(rescues, seg)
	end
	if #self.segments == 0 then
		t = 2
		message = 'You died!'
		self.vx, self.vy, self.om = 0, 0, 0
		return
	end

	if self.fireTimer then
		self.fireTimer = self.fireTimer - dt
		if self.fireTimer <= 0 then
			self.fireTimer = nil
		end
	end
	if control.fire and not self.fireTimer then
		local head = self.segments[1]
		local shard = head:shard()
		if shard then
			local fx, fy = math.cos(head.th), math.sin(head.th)
			shard.vx = self.vx + self.shardSpeed * fx
			shard.vy = self.vy + self.shardSpeed * fy
			shard.om = U.randomIn(-7*math.pi, 7*math.pi)
			table.insert(shards, shard)
			self.fireTimer = self.fireDelay
		end
	end
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
