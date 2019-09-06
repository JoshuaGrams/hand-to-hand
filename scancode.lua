local U = require 'util'

local function button(s, ...)
	local b
	if type(s) == 'table' then
		b = love.keyboard.isScancodeDown(unpack(s))
	else
		b = love.keyboard.isScancodeDown(s, ...)
	end
	return U.boolToNum(b)
end

local function axis(pos, neg)
	return button(pos) - button(neg)
end

local function stick(xPos, xNeg, yPos, yNeg)
	local x = axis(xPos, xNeg)
	local y = axis(yPos, yNeg)
	return U.limitLength(x, y, 1)
end

return {
	button = button,
	axis = axis,
	stick = stick
}
