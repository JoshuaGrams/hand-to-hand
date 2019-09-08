local Object = require 'base-class'

local Trail = Object:extend()

function Trail.set(self, minDist, maxLength)
	self.d = minDist
	self.n = 2 * math.ceil(maxLength / minDist)
end

local function segmentComplete(self)
	if #self < 4 then return true end
	local x0, y0, x1, y1 = unpack(self, #self-3)
	local dx, dy = x1 - x0, y1 - y0
	local d2 = dx*dx + dy*dy
	local complete = d2 >= self.d*self.d
	if complete then
		local s = self.d / math.sqrt(d2)
		self[#self-1], self[#self] = x0 + s*dx, y0 + s*dy
	end
	return complete
end

function Trail.add(self, x, y)
	if segmentComplete(self) then
		if #self >= self.n then
			table.remove(self, 1)
			table.remove(self, 1)
		end
		table.insert(self, x)
		table.insert(self, y)
	else
		self[#self-1], self[#self] = x, y
	end
end

local function dist(x0, y0, x1, y1)
	local dx, dy = x1 - x0, y1 - y0
	return math.sqrt(dx*dx + dy*dy)
end

function Trail.length(self)
	if #self < 4 then return 0 end
	local x0, y0, x1, y1 = unpack(self, #self-3)
	local d = dist(unpack(self, #self-3))
	return d + self.d * (#self - 4)/2
end

function Trail.at(self, d)
	if #self == 0 then return end
	d = math.max(0, self:length() - d)
	local iMax = #self - 1
	local i0 = math.min(iMax, 1 + 2*math.floor(d/self.d))
	local i1 = math.min(iMax, i0 + 2)
	local x0, y0 = unpack(self, i0, i0+1)
	local x1, y1 = unpack(self, i1, i1+1)
	local dx, dy = x1 - x0, y1 - y0
	local t = (d % self.d) / math.sqrt(dx*dx + dy*dy)
	local th = math.atan2(dy, dx)
	return x0 + dx * t, y0 + dy * t, th
end

return Trail
