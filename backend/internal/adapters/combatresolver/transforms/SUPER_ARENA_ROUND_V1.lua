-- C5C: BattleCreateReport takes SUPER_ARENA team groups and reads only the
-- current round from the PEAK_ARENA model; each round is its own attempt.
return function(fight)
	fight.herosA, fight.herosB = { team1 = fight.herosA }, { team1 = fight.herosB[1] }
	combat_mode_models[xyd.ModelType.PEAK_ARENA] = {
		clear = function() end,
		setCurrentBattleRound = function() end,
		getCurrentBattleRound = function() return 1 end,
	}
end
