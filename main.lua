local Camera = require 'camera'
local kb = require 'scancode'
local Level = require 'level'
local Player = require 'player'
local TileMap = require 'tilemap'

TURN = 2*math.pi

function love.load()
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
		}
	}

	local w, h = love.graphics.getDimensions()
	unit = math.min(w, h) / 3.5
	noiseUnit = 43/17

	camera = Camera.new(0, 0, 1.8*w*h)

	local aliens = {image.alien.blue, image.alien.green, image.alien.pink}
	player = Player(0, 0, -TURN/4, aliens, image.shard)
	for i=1,5 do player:addSegment(0, 0, -TURN/4) end
	-- table.insert(shards, Shard(segment, math.random() < 0.5))

	blocks = TileMap(image.blocks, 256, 32, {
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
	local turn, accel = kb.stick('right', 'left', 'up', 'down')
	player:update(dt, turn, accel, blocks)

	local head = player:head()
	camera:follow(head.x, head.y, dt, 0.4, 0.95)
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
	
	love.graphics.setColor(1, 1, 1)
	player:draw()
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
