-- C5D: applies the frozen season awards after populate, then the client's own
-- balancing (SelectTeamRearenaWindow initOtherHero/willOpen).
local function balance(actors, heroes)
	for i, actor in ipairs(actors) do
		local hero, addStar = heroes[i], actor.transform.arena_add_star or 0
		if addStar > 0 then
			local cap = xyd.isSuperHero(hero) and xyd.SUPER_HERO_TOTAL_STARS or xyd.MAX_STAR_LEVEL
			hero:setStar(math.min(hero:getStar() + addStar, cap))
		end
		if actor.transform.arena_awake == 1 and not hero:isAwaken() then
			hero:setTableID(xyd.tables.hero:afterAwaken(hero:getTableID()))
		end
	end
	xyd.formatRegionArenaHeros(heroes)
end

return function(fight, input)
	balance(input.team_a, fight.herosA)
	for i, wave in ipairs(input.waves_b) do
		balance(wave, fight.herosB[i])
	end
	xyd.formatRegionArenaPets(fight.petsA)
	xyd.formatRegionArenaPets(fight.petsB)
end
