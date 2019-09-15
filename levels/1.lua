local Map = require 'map'
local Fly = require 'enemy-fly'
local Fish = require 'enemy-fish'

return Map(50, 0.05, {4, 1, 0.5, 0}, {
	{ {0,0}, chance = 5, exits = {{1,0}, {0,1}, {-1,0}, {0,-1}} },
	{
		{0,0}, {1, 0}, {0,1}, {1,1},
		chance = 2,
		exits = {{2,0}, {0,2}, {-1,0}, {0,-1}}
	}
}, {
	{3, Fly, 4, 'enemies'},
	{3, Fish, 4, 'enemies'}
})
