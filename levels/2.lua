local Map = require 'map'
local Fly = require 'enemy-fly'
local Fish = require 'enemy-fish'
local Room = require 'rooms'

return Map(70, 0.05, {4, 1, 0.5, 0}, {
	Room('single', 1),
	Room('nine', 3),
	Room('hall3', 5)
}, {
	{5, Fly, 3, 'enemies'},
	{3, Fish, 2, 'enemies'}
})
