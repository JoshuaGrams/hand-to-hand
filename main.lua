local Camera = require 'camera'
local G = require 'geometry'
local kb = require 'scancode'
local Level = require 'level'
local Shard = require 'shard'
local Sprite = require 'sprite'
local TileMap = require 'tilemap'
local Trail = require 'trail'
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

	local w, h = love.graphics.getDimensions()
	unit = math.min(w, h) / 3.5
	noiseUnit = 43/17

	camera = Camera.new(0, 0, 1.8*w*h)

	player = Sprite(images.alien.blue, 0, 0, -TURN/4, 0.45, 0.5)
	player.r = 35  -- collision radius
	player.dx, player.dy = 0, 0  -- linear velocity
	player.vMax = 500
	player.vMin = 1
	player.vDecay = 5
	player.aMax = player.vMax / 0.6
	player.om = 0  -- angular velocity (omega)
	player.omMax = 0.9 * TURN
	player.omMin = 0.01 * TURN
	player.omDecay = 0.8
	player.alMax = player.omMax / 0.2

	segments = {}
	shards = {}
	local aliens = {images.alien.blue, images.alien.green, images.alien.pink}
	for i=1,5 do
		local img = aliens[math.random(#aliens)]
		local segment = Sprite(img, 0, 0, -TURN/4, 0.45, 0.5)
		table.insert(segments, segment)
		table.insert(shards, Shard(segment, math.random() < 0.5))
	end

	playerTrail = Trail(10, 550)

	blocks = TileMap(images.blocks, 256, 32, {
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

local function collidePlayer(p, map)
	local e = 0.6  -- elasticity (0 to 1)
	local collisions = map:circleOverlaps(p.x, p.y, p.r)
	for _,c in ipairs(collisions) do
		local nx, ny, ov = unpack(c)
		player.x = player.x + nx * ov
		player.y = player.y + ny * ov

		local away = player.dx * nx + player.dy * ny
		if away < 0 then
			player.dx = player.dx - (1+e) * away * nx
			player.dy = player.dy - (1+e) * away * ny
		end
	end
end

local function turnPlayer(player, control, dt)
	local om = player.om + control * player.alMax * dt
	local om0, om1 = math.abs(player.om), math.abs(om)
	if om1 <= player.omMax or om1 < om0 then player.om = om end
	player.om = player.om * U.smoothOver(dt, player.omDecay)
	if math.abs(player.om) < player.omMin then player.om = 0 end
	player.th = U.wrapAngle(player.th + player.om * dt)
end

local function acceleratePlayer(player, control, dt)
	local fx, fy = math.cos(player.th), math.sin(player.th)
	if control < 0 then control = 0.3 * control end
	local dv = control * player.aMax * dt
	local dx, dy = player.dx + dv * fx, player.dy + dv * fy

	-- Limit max speed.
	local v0 = player.dx*player.dx + player.dy*player.dy
	local v1 = dx*dx + dy*dy
	if v1 < player.vMax * player.vMax or v1 < v0 then
		player.dx, player.dy = dx, dy
	end

	-- Speed decays over time.
	local decay = U.smoothOver(dt, player.vDecay)
	player.dx, player.dy = player.dx * decay, player.dy * decay

	-- Stop drifting when speed is less than vMin.
	if player.dx*player.dx + player.dy*player.dy < player.vMin*player.vMin then
		player.dx, player.dy = 0, 0
	end
end

function love.update(dt)
	local cx, cy = kb.stick('right', 'left', 'up', 'down')
	turnPlayer(player, cx, dt)
	acceleratePlayer(player, cy, dt)

	player.x = player.x + player.dx * dt
	player.y = player.y + player.dy * dt
	collidePlayer(player, blocks)

	playerTrail:add(player.x, player.y)
	local k = 1 - U.smoothOver(dt, 0.5)
	local dthMax = player.omMax
	for i=#segments,1,-1 do
		local th
		local seg = segments[i]
		seg.x, seg.y, th = playerTrail:at(100 * i)
		local dth = k * U.wrapAngle(th - seg.th)
		dth = U.clamp(dth, -dthMax, dthMax)
		seg.th = seg.th + dth
	end

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
	for i=#segments,1,-1 do segments[i]:draw() end

	player:draw()

	for _,shard in ipairs(shards) do
		shard:draw()
	end
end

local function toggleFullscreen()
	local fullscreen = love.window.getFullscreen()
	love.window.setFullscreen(not fullscreen, 'desktop')
end

function love.keypressed(k, s)
	local alt = love.keyboard.isDown('lalt', 'ralt')
	if k == 'escape' then
		love.event.quit()
	elseif k == 'space' then
		level1:generate(blocks)
	elseif k == 'f11' or (alt and k == 'return') then
		toggleFullscreen()
	end
end
