local Map = require 'map'
local Block = require 'enemy-block'
local Fly = require 'enemy-fly'
local Room = require 'rooms'

return Map(80, 0.02, {4, 1, 0, 0}, {
	Room('nine', 5),
	Room('quad', 2)
}, {
	{8, Block, 1, 'enemies'},
	{9, Fly, 3, 'enemies'}
})
