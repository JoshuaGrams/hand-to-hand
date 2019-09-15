local Map = require 'map'
local Fly = require 'enemy-fly'

return Map(50, 0.05, {4, 1, 0.5, 0}, {
	{ {0,0}, chance = 5, exits = {{1,0}, {0,1}, {-1,0}, {0,-1}} },
	{
		{0,0}, {1, 0}, {0,1}, {1,1},
		chance = 2,
		exits = {{2,0}, {0,2}, {-1,0}, {0,-1}}
	}
}, {
	{9, Fly, 5, 'enemies'}
})
