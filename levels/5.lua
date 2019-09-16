local Map = require 'map'
local Block = require 'enemy-block'
local Fly = require 'enemy-fly'
local Fish = require 'enemy-fish'
local Room = require 'rooms'

return Map(100, 0.05, {4, 0.5, 0, 0.5}, {
	Room('single', 5),
	Room('hall3', 5),
	Room('nine', 1)
}, {
	{6, Block, 1.5, 'enemies'},
	{11, Fly, 1.5, 'enemies'},
	{10, Fish, 1.5, 'enemies'}
})
