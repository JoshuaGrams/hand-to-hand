local Object = require 'base-class'

local Music = Object:extend()

function Music.set(self, ...)
	self.track = 0
	self.tracks = {...}
	for i,track in ipairs(self.tracks) do
		if type(track) == 'string' then
			self.tracks[i] = love.audio.newSource(track, 'stream')
		end
	end

	-- Swap a random track into the first position.
	local i = math.floor(math.random(#self.tracks))
	self.tracks[1], self.tracks[i] = self.tracks[i], self.tracks[1]

	self.volume = 0.25
	self.fadeDuration = 5

	self:nextTrack()
end

function Music.update(self)
	local source = self.tracks[self.track]
	if source:isPlaying() then
		local remaining = source:getDuration() - source:tell()
		if remaining <= self.fadeDuration then
			local fade = remaining / self.fadeDuration
			source:setVolume(self.volume * fade)
		end
	else
		self:nextTrack()
	end
end

function Music.nextTrack(self)
	self.track = self.track % #self.tracks + 1
	local source = self.tracks[self.track]
	source:setVolume(self.volume)
	source:play()
end

return Music
