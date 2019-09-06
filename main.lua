local Camera = require 'camera'
local kb = require 'scancode'
local Level = require 'level'
local Sprite = require 'sprite'
local TileMap = require 'tilemap'
local U = require 'util'

TURN = 2*math.pi

function love.load()
	images = {
		blocks = love.graphics.newImage('img/blocks.png'),
		star = love.graphics.newImage('img/star.png'),
		shard = love.graphics.newImage('img/shard.png'),
		alien = {
			green = love.graphics.newImage('img/alien-green.png'),
			blue = love.graphics.newImage('img/alien-blue.png'),
			pink = love.graphics.newImage('img/alien-pink.png'),
		},
		gem = {
			green = love.graphics.newImage('img/gem-green.png'),
			red = love.graphics.newImage('img/gem-red.png'),
			blue = love.graphics.newImage('img/gem-blue.png'),
			yellow = love.graphics.newImage('img/gem-yellow.png'),
		}
	}

	unit = math.min(love.graphics.getDimensions()) / 3.5
	noiseUnit = 43/17

	camera = Camera.new(0, 0)

	player = Sprite(images.alien.blue, 0, 0, -TURN/4, 0.42, 0.5)
	player.dx, player.dy = 0, 0  -- linear velocity
	player.vMax = 500
	player.vMin = 5
	player.vDecay = 3
	player.aMax = player.vMax / 0.6
	player.om = 0  -- angular velocity (omega)
	player.omMax = 0.9 * TURN
	player.omMin = 0.01 * TURN
	player.omDecay = 0.8
	player.alMax = player.omMax / 0.2

	blocks = TileMap(images.blocks, 256, {
		'sand', 'soil', 'grass',
		'ice', 'purple', 'zigzag'
	})

	level1 = Level(200, 0.05, {4, 1, 0.5, 0}, {
		{ {0,0}, chance = 5, exits = {{1,0}, {0,1}, {-1,0}, {0,-1}} },
		{
			{0,0}, {1, 0}, {0,1}, {1,1},
			chance = 2,
			exits = {{2,0}, {0,2}, {-1,0}, {0,-1}}
		}
	})
	level1:generate(blocks)
end

function love.update(dt)
	local cx, cy = kb.stick('right', 'left', 'up', 'down')

	-- Turning
	local om = player.om + cx * player.alMax * dt
	local om0, om1 = math.abs(player.om), math.abs(om)
	if om1 <= player.omMax or om1 < om0 then player.om = om end
	player.om = player.om * U.smoothOver(dt, player.omDecay)
	if math.abs(player.om) < player.omMin then player.om = 0 end
	player.th = U.wrapAngle(player.th + player.om * dt)

	local fx, fy = math.cos(player.th), math.sin(player.th)
	local dv = math.max(0, cy) * player.aMax * dt
	local dx = player.dx + dv * fx
	local dy = player.dy + dv * fy
	local v0 = player.dx*player.dx + player.dy * player.dy
	local v1 = dx*dx + dy*dy
	if v1 < player.vMax * player.vMax or v1 < 0 then
		player.dx, player.dy = dx, dy
	end
	local decay = U.smoothOver(dt, player.vDecay)
	player.dx, player.dy = player.dx * decay, player.dy * decay
	if player.dx * player.dx + player.dy * player.dy < player.vMin * player.vMin then
		player.dx, player.dy = 0, 0
	end
	player.x = player.x + player.dx * dt
	player.y = player.y + player.dy * dt

	camera:follow(player.x, player.y, dt, 0.4, 0.95)
end

local function drawStars()
	local img = images.star
	local iw, ih = img:getDimensions()
	local ox, oy = 0.5 * iw, 0.5 * ih
	local b = camera.bounds
	local x0, y0 = math.floor(b.xMin/unit), math.floor(b.yMin/unit)
	local x1, y1 = math.ceil(b.xMax/unit), math.ceil(b.yMax/unit)
	for y=y0-1,y1+1 do
		for x=x0-1,x1+1 do
			local nx, ny = x*noiseUnit, y*noiseUnit
			local dx = 0.8 * love.math.noise(nx + 0.2*noiseUnit, ny - 0.2*noiseUnit)
			local dy = 0.8 * love.math.noise(nx - 0.3*noiseUnit, ny + 0.1*noiseUnit)
			local th = (2*dx - 1) * TURN/10
			local sc = 0.5 + math.abs(dy)
			love.graphics.draw(images.star, (x+dx)*unit, (y+dy)*unit, th, sc, sc, ox, oy)
		end
	end
end

function love.draw()
	love.graphics.setBackgroundColor(0.05, 0.05, 0.1)
	camera:use()

	love.graphics.setColor(0.3, 0.3, 0.3)
	drawStars()

	love.graphics.setColor(1, 1, 1)
	blocks:draw()
	
	love.graphics.setColor(1, 1, 1)
	player:draw()
end

function love.keypressed(k, s)
	if k == 'escape' then
		love.event.quit()
	elseif k == 'space' then
		level1:generate(blocks)
	end
end
