-- Currently in alphabetical order.

local function boolToNum(b)  return b and 1 or 0  end

local function ceilTo(x, unit)
	return math.ceil(x/unit) * unit
end

local function clamp(x, lo, hi)
	return math.max(lo, math.min(x, hi))
end

local function floorTo(x, unit)
	return math.floor(x/unit) * unit
end

local function lerp(t, a, b)
	return a + t * (b - a)
end

local function limitLength(x, y, l)
	l = l or 1
	local d2, l2 = x*x + y*y, l*l
	if d2 > l2 then
		local s = l / math.sqrt(d2)
		x, y = x*s, y*s
	end
	return x, y
end

local function mergeAxes(...)
	local pos, neg = math.max(0, ...), math.min(0, ...)
	return pos + neg
end

local function randomIn(lo, hi)
	return lo + (hi - lo) * math.random()
end

local function roundTo(x, unit)
	return math.floor(0.5 + x/unit) * unit
end

-- Fisher-Yates shuffle (in-place).
local function shuffle(l)
	for i = #l, 2, -1 do
		-- Note that `j == i` is a valid choice since a random
		-- shuffle may leave some items in their original places.
		local j = math.random(i)
		l[j], l[i] = l[i], l[j]
	end
	return l
end

local function smoothOver(dt, t)
	return 0.05^(dt/t)
end

local function wrapAngle(radians)
	return math.pi - (math.pi - radians) % (2 * math.pi)
end

return {
	boolToNum = boolToNum,
	ceilTo = ceilTo,
	clamp = clamp,
	floorTo = floorTo,
	lerp = lerp,
	limitLength = limitLength,
	mergeAxes = mergeAxes,
	randomIn = randomIn,
	roundTo = roundTo,
	shuffle = shuffle,
	smoothOver = smoothOver,
	wrapAngle = wrapAngle
}
