return function(fight, input)
	xyd.formatRegionArenaHerosAwake(fight.herosA)
	for _, wave in ipairs(fight.herosB) do
		xyd.formatRegionArenaHerosAwake(wave)
	end
	xyd.formatRegionArenaPetsAwake(fight.petsA)
	xyd.formatRegionArenaPetsAwake(fight.petsB)
end
