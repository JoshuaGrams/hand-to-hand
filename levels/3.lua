local Map = require 'map'
local Block = require 'enemy-block'
local Fly = require 'enemy-fly'
local Fish = require 'enemy-fish'
local Room = require 'rooms'

return Map(80, 0.02, {4, 1, 0.5, 0}, {
	Room('nine', 2),
	Room('quad', 2),
	Room('hall3', 5)
}, {
	{4, Block, 1.5, 'enemies'},
	{7, Fly, 2, 'enemies'},
	{2, Fish, 2, 'enemies'}
})
