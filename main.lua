local Camera = require 'camera'
local Enemy = require 'enemy'
local Fly = require 'enemy-fly'
local kb = require 'scancode'
local Music = require 'music'
local Player = require 'player'
local Segment = require 'segment'
local TileMap = require 'tilemap'

TURN = 2*math.pi

local function quad(img, x, y, w, h, ox, oy)
	ox, oy = ox or 0.5, oy or 0.5
	local iw, ih = img:getDimensions()
	local q = love.graphics.newQuad(x, y, w, h, iw, ih)
	return { img = img, quad = q, ox = ox*w, oy = oy*h }
end

local function generateSeedFromClock()
	local seed = os.time() + math.floor(1000 * os.clock())
	seed = seed * seed % 1000000
	seed = seed * seed % 1000000
	return seed
end

function nextLevel()
	shards = {}
	enemies = {}
	rescues = {}
	level = math.min(level + 1, #levels)
	local head = player:head()
	if not head then
		head = Segment(0, 0, -TURN/4)
		player:addSegment(head)
		camera.cx, camera.cy = 0, 0
	end
	levels[level]:generate(blocks, blocks:fromPixel(head.x, head.y))
	t = 0
	message = messages[level]
end

function love.load()
	math.randomseed(generateSeedFromClock())

	hasFocus = true

	font = love.graphics.newFont('font/RobotoSlab-Regular.ttf', 48)
	love.graphics.setFont(font)

	music = Music('audio/Arroz Con Pollo.mp3', 'audio/Cuban Sandwich.mp3')

	image = {
		blocks = love.graphics.newImage('img/blocks.png'),
		star = love.graphics.newImage('img/star.png'),
		shard = love.graphics.newImage('img/shard.png'),
		alien = {
			green = love.graphics.newImage('img/alien-green.png'),
			blue = love.graphics.newImage('img/alien-blue.png'),
			pink = love.graphics.newImage('img/alien-pink.png'),
		},
		enemies = love.graphics.newImage('img/enemies.png')
	}

	local img = image.enemies
	frames = {
		fly = {
			quad(img, 0, 0, 148, 75, 0.41, 0.6),
			quad(img, 148, 0,  154, 75,  0.4, 0.6)
		},
		fish = {
			quad(img, 6, 77, 136, 85, 0.29, 0.62),
			quad(img, 162, 75, 127, 87, 0.305, 0.595)
		},
		block = {quad(img, 21, 162, 106, 106)}
	}

	local w, h = love.graphics.getDimensions()
	unit = math.min(w, h) / 3.5
	noiseUnit = 43/17

	camera = Camera.new(0, 0, 1.8*w*h)

	shards = {}
	enemies = {}

	Segment.images = {image.alien.blue, image.alien.green, image.alien.pink}
	Segment.shardImage = image.shard
	player = Player(0, 0, -TURN/4)

	blocks = TileMap(image.blocks, 256, 32, {
		'sand', 'soil', 'grass',
		'ice', 'purple', 'zigzag'
	})

	levels = {
		require 'levels/1',
		require 'levels/2',
		require 'levels/3',
		require 'levels/4',
		require 'levels/5',
		require 'levels/6'
	}
	messages = {'Rescue your comrades. Arrows move, space shoots.'}
	messages[6] = 'Congratulations! You win!'

	level = 0
	nextLevel()
end

local function updateFlyingShards(dt)
	local delete = {}
	for i,shard in ipairs(shards) do
		shard:update(dt)
		if #blocks:circleOverlaps(shard.x, shard.y, shard.r) > 0 then
			table.insert(delete, i)
		end
		for _,enemy in ipairs(enemies) do
			local dx, dy = enemy.x - shard.x, enemy.y - shard.y
			local r = enemy.r + shard.r
			if not enemy.dead and dx*dx + dy*dy <= r*r then
				enemy:hit(1)
				table.insert(delete, i)
			end
		end

		shard.t = shard.t - dt
		if shard.t <= 0 then table.insert(delete, i) end
	end
	for _,i in ipairs(delete) do
		table.remove(shards, i)
	end
end

function love.update(dt)
	if not hasFocus then return end
	t = t + dt
	music:update()

	local turn, accel = kb.stick('right', 'left', 'up', 'down')
	local control = {
		turn = turn, accel = accel,
		fire = love.keyboard.isScancodeDown('space')
	}
	player:update(dt, control, blocks)
	for i=#rescues,1,-1 do
		local rescue = rescues[i]
		rescue.th = rescue.th + math.pi/2 * dt
		if rescue.t then
			rescue.t = rescue.t - dt * rescue.dt
			if rescue.t <= 0 then
				table.remove(rescues, i)
			end
		end
	end

	local head = player:head()
	if head then
		camera:follow(head.x, head.y, dt, 0.4, 0.95)
	end

	updateFlyingShards(dt)

	for i=#enemies,1,-1 do
		local enemy = enemies[i]
		if enemy.delete then
			table.remove(enemies, i)
		else
			enemy:update(dt)
		end
	end
end

local function drawStars()
	local img = image.star
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
			love.graphics.draw(image.star, (x+dx)*unit, (y+dy)*unit, th, sc, sc, ox, oy)
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

	for _,enemy in ipairs(enemies) do
		enemy:draw()
	end
	
	player:draw()
	for _,rescue in ipairs(rescues) do
		if rescue.t then
			local x, y = rescue.x, rescue.y
			local k = 20 * (1 - rescue.t)
			rescue.x = rescue.x + k * (math.random() - 0.5)
			rescue.y = rescue.y + k * (math.random() - 0.5)
			rescue:draw()
			rescue.x, rescue.y = x, y
		else
			rescue:draw()
		end
	end

	for _,shard in ipairs(shards) do
		shard:draw()
	end

	if message then
		if t < 5 then
			local mw = font:getWidth(message)
			local h = camera.bounds.yMax - camera.bounds.yMin
			local x = camera.cx - mw/2
			local y = camera.cy - h * 0.3
			love.graphics.setColor(1, 1, 0.3)
			love.graphics.print(message, x, y)
		else
			if #player.segments == 0 then
				level = 0
				nextLevel()
			end
		end
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
	elseif k == 'f11' or (alt and k == 'return') then
		toggleFullscreen()
	end
end

function love.focus(focus)
	hasFocus = focus
	if focus then
		if pausedSources then
			love.audio.play(pausedSources)
			pausedSources = nil
		end
	else
		pausedSources = love.audio.pause()
	end
end
