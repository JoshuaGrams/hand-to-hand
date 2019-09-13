local abs, sqrt = math.abs, math.sqrt
local function sign(x)  return x < 0 and -1 or 1  end

local function bounceAlong(obj, collisions, e, vel)
	vel = vel or obj
	for _,c in ipairs(collisions) do
		local nx, ny, ov = unpack(c)
		obj.x = obj.x + nx * ov
		obj.y = obj.y + ny * ov

		if vel.vx and vel.vy then
			local away = vel.vx * nx + vel.vy * ny
			if away < 0 then
				vel.vx = vel.vx - (1+e) * away * nx
				vel.vy = vel.vy - (1+e) * away * ny
			end
		end
	end
end

-- dx and dy are circle center minus square center.
-- r is circle radius, s is length of square side.
local function circleOverlapsSquare(dx, dy, r, s)
	s = s / 2
	local S = r + s
	local adx, ady = abs(dx), abs(dy)
	local nx, ny, d
	if adx > S or ady > S then return false
	elseif adx > s and ady > s then  -- corner
		local rx, ry = adx - s, ady - s
		local d2 = rx*rx + ry*ry
		if d2 > r*r then return false end
		d = sqrt(d2)
		local sc = 1 / d
		nx, ny, d = rx * sc, ry * sc, r - d
	elseif ady > s or (ady <= s and adx < ady) then  -- top/bottom
		nx, ny, d = 0, 1, S - ady
	else  -- left/right
		nx, ny, d = 1, 0, S - adx
	end
	nx, ny = nx * sign(dx), ny * sign(dy)
	return nx, ny, d
end

return {
	bounceAlong = bounceAlong,
	circleOverlapsSquare = circleOverlapsSquare
}
