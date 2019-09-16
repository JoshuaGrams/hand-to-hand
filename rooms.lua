local templates = {
	single = {
		{0, 0},
		exits = {{1,0}, {0,1}, {-1,0}, {0,-1}}
	},
	quad = {
		{0,0}, {1,0}, {0,1}, {1,1},
		exits = {{2,0}, {0,2}, {-1,0}, {0,-1}}
	},
	nine = {
		{0,0}, {1,0}, {2,0},
		{0,1}, {1,1}, {2,1},
		{0,2}, {1,2}, {2,2},
		exits = {{3,1}, {1,3}, {-1,1}, {1,-1}}
	},
	hall3 = {
		{0,0}, {1,0}, {2,0},
		exits = {{3,0}, {2,1}, {-1,0}, {2,-1}}
	},
}

return function(name, chance)
	local room = {}
	for k,v in pairs(templates[name]) do
		room[k] = v
	end
	room.chance = chance
	return room
end
