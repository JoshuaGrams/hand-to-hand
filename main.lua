local Camera = require 'camera'
local Enemy = require 'enemy'
local Fly = require 'enemy-fly'
local kb = require 'scancode'
local Music = require 'music'
local Player = require 'player'
local TileMap = require 'tilemap'

TURN = 2*math.pi

local function quad(img, x, y, w, h, ox, oy)
	ox, oy = ox or 0.5, oy or 0.5
	local iw, ih = img:getDimensions()
	local q = love.graphics.newQuad(x, y, w, h, iw, ih)
	return { img = img, quad = q, ox = ox*w, oy = oy*h }
end

function generateSeedFromClock(debug)
	local seed = os.time() + math.floor(1000 * os.clock())
	seed = seed * seed % 1000000
	seed = seed * seed % 1000000
	if debug then print('Seed:', seed) end
	return seed
end

function love.load()
	math.randomseed(generateSeedFromClock())

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
		gem = {
			green = love.graphics.newImage('img/gem-green.png'),
			red = love.graphics.newImage('img/gem-red.png'),
			blue = love.graphics.newImage('img/gem-blue.png'),
			yellow = love.graphics.newImage('img/gem-yellow.png'),
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

	local aliens = {image.alien.blue, image.alien.green, image.alien.pink}
	player = Player(0, 0, -TURN/4, aliens, image.shard)
	for i=1,2 do player:addSegment(0, 0, -TURN/4) end

	blocks = TileMap(image.blocks, 256, 32, {
		'sand', 'soil', 'grass',
		'ice', 'purple', 'zigzag'
	})

	levels = {
		require 'levels/1'
	}
	levels[1]:generate(blocks)

	enemies = {}
	local fish = Enemy(frames.fish, 100, 100, 0, 1, 1/5)
	local fly = Fly(blocks:randomFloor())
	table.insert(enemies, fish)
	table.insert(enemies, fly)
end


function love.update(dt)
	music:update()

	local turn, accel = kb.stick('right', 'left', 'up', 'down')
	local control = {
		turn = turn, accel = accel,
		fire = love.keyboard.isScancodeDown('space')
	}
	player:update(dt, control, blocks)

	local head = player:head()
	camera:follow(head.x, head.y, dt, 0.4, 0.95)

	local delete = {}
	for i,shard in ipairs(shards) do
		shard:update(dt)
		if #blocks:circleOverlaps(shard.x, shard.y, shard.r) > 0 then
			table.insert(delete, i)
		end
		for _,enemy in ipairs(enemies) do
			local dx, dy = enemy.x - shard.x, enemy.y - shard.y
			local r = enemy.r + shard.r
			if dx*dx + dy*dy <= r*r then
				enemy:hit(1)
				table.insert(delete, i)
			end
		end
	end
	for _,i in ipairs(delete) do
		table.remove(shards, i)
	end

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
	elseif k == 'tab' then
		levels[1]:generate(blocks)
	elseif k == 'f11' or (alt and k == 'return') then
		toggleFullscreen()
	end
end
