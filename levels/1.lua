local Map = require 'map'
local Block = require 'enemy-block'
local Fish = require 'enemy-fish'
local Fly = require 'enemy-fly'
local Room = require('rooms')

return Map(50, 0.05, {4, 1, 0.5, 0}, {
	Room('single', 5),
	Room('quad', 2)
}, {
	{2, Block, 1.5, 'enemies'},
	{2, Fish, 4, 'enemies'}
})
