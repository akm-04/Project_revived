xyd = xyd or {}

local var_0_0 = xyd.tables.translation

function xyd.lastLoginTimeString(arg_1_0)
	local var_1_0 = xyd.ServerTime.get():getServerTime() - arg_1_0
	local var_1_1 = math.floor(var_1_0 / 3600)
	local var_1_2 = math.floor(var_1_1 / 24)

	if var_1_2 >= 1 then
		return string.format(var_0_0:translation("DAYS_AGO_PROMPT"), var_1_2)
	elseif var_1_1 >= 1 then
		return string.format(var_0_0:translation("HOURS_AGO_PROMPT"), var_1_1)
	else
		return var_0_0:translation("RECENT")
	end
end

function xyd.currencyName(arg_2_0)
	if arg_2_0 == xyd.Currency.MANA then
		return var_0_0:translation("MANA")
	elseif arg_2_0 == xyd.Currency.CRYSTAL then
		return var_0_0:translation("CRYSTAL")
	elseif arg_2_0 == xyd.Currency.CREDIT then
		return var_0_0:translation("CREDIT")
	else
		return ""
	end
end

function xyd.attributeName(arg_3_0)
	if arg_3_0 == xyd.HeroAttribute.HP_LIMIT then
		return var_0_0:translation("HP")
	elseif arg_3_0 == xyd.HeroAttribute.ATTACK then
		return var_0_0:translation("ATTACK")
	elseif arg_3_0 == xyd.HeroAttribute.DEFENCE then
		return var_0_0:translation("DEFENCE")
	elseif arg_3_0 == xyd.HeroAttribute.SPEED then
		return var_0_0:translation("SPEED")
	elseif arg_3_0 == xyd.HeroAttribute.CRIT_RATE then
		return var_0_0:translation("CRIT_RATE")
	elseif arg_3_0 == xyd.HeroAttribute.CRIT_DAMAGE_RATE then
		return var_0_0:translation("CRIT_DAMAGE_RATE")
	elseif arg_3_0 == xyd.HeroAttribute.RESIST then
		return var_0_0:translation("RESIST")
	elseif arg_3_0 == xyd.HeroAttribute.ACCURACY then
		return var_0_0:translation("ACCURACY")
	else
		return ""
	end
end

function xyd.heroTypeName(arg_4_0)
	if arg_4_0 == xyd.HeroType.ATTACKER then
		return var_0_0:translation("ATTACKER_TYPE")
	elseif arg_4_0 == xyd.HeroType.DEFENCER then
		return var_0_0:translation("DEFENCER_TYPE")
	elseif arg_4_0 == xyd.HeroType.PHYSICAL then
		return var_0_0:translation("PHYSICAL_TYPE")
	elseif arg_4_0 == xyd.HeroType.ASSISTANT then
		return var_0_0:translation("ASSISTANT_TYPE")
	else
		return ""
	end
end

function xyd.stageLevelName(arg_5_0)
	if arg_5_0 == xyd.StageLevel.NORMAL then
		return var_0_0:translation("NORMAL")
	elseif arg_5_0 == xyd.StageLevel.HARD then
		return var_0_0:translation("HARD")
	elseif arg_5_0 == xyd.StageLevel.HELL then
		return var_0_0:translation("HELL")
	else
		return ""
	end
end

function xyd.arenaBuffAwardName(arg_6_0)
	if arg_6_0 == xyd.ArenaBuffAwardType.HP then
		return var_0_0:translation("HP")
	elseif arg_6_0 == xyd.ArenaBuffAwardType.ATTACK then
		return var_0_0:translation("ATTACK")
	elseif arg_6_0 == xyd.ArenaBuffAwardType.GLORY then
		return var_0_0:translation("GLORY")
	else
		return ""
	end
end

function xyd.alertMessage(arg_7_0, ...)
	if arg_7_0 == xyd.AlertInfo.LACK_OF_CRYSTAL then
		return var_0_0:translation("LACK_OF_CRYSTAL")
	elseif arg_7_0 == xyd.AlertInfo.LACK_OF_SOCIAL then
		return var_0_0:translation("LACK_OF_SOCIAL")
	elseif arg_7_0 == xyd.AlertInfo.LACK_OF_SCROLL then
		return var_0_0:translation("LACK_OF_SCROLL")
	elseif arg_7_0 == xyd.AlertInfo.LACK_OF_MANA then
		return var_0_0:translation("LACK_OF_MANA")
	elseif arg_7_0 == xyd.AlertInfo.LACK_OF_ENERGY then
		return var_0_0:translation("LACK_OF_ENERGY")
	elseif arg_7_0 == xyd.AlertInfo.LACK_OF_INVITATION then
		return var_0_0:translation("LACK_OF_INVITATION")
	elseif arg_7_0 == xyd.AlertInfo.SWALLOW_REP_HERO then
		return var_0_0:translation("CANNOT_SWALLOW_REP_HERO")
	elseif arg_7_0 == xyd.AlertInfo.SWALLOW_DEFENCE_HERO then
		return var_0_0:translation("CANNOT_SWALLOW_DEFENCE_HERO")
	elseif arg_7_0 == xyd.AlertInfo.SWALLOW_LOCK_HERO then
		return var_0_0:translation("CANNOT_SWALLOW_LOCK_HERO")
	elseif arg_7_0 == xyd.AlertInfo.MAX_POWERUPED then
		return var_0_0:translation("CANNOT_POWERUP")
	elseif arg_7_0 == xyd.AlertInfo.EVOLVE_STAR then
		return string.format(var_0_0:translation("UNSATISFY_EVOLVE_STAR"), ...)
	elseif arg_7_0 == xyd.AlertInfo.EVOLVE_HERO_NUM then
		return string.format(var_0_0:translation("UNSATISFY_EVOLVE_HERO_NUM"), ...)
	elseif arg_7_0 == xyd.AlertInfo.EMPTY_SWALLOW_HERO then
		return var_0_0:translation("PLEASE_CHOOSE_SWALLOW_HEROS")
	elseif arg_7_0 == xyd.AlertInfo.DISMISS_REP_HERO then
		return var_0_0:translation("DISMISS_REP_HERO")
	elseif arg_7_0 == xyd.AlertInfo.DISMISS_LOCK_HERO then
		return var_0_0:translation("DISMISS_LOCK_HERO")
	elseif arg_7_0 == xyd.AlertInfo.DISMISS_DEFENCE_HERO then
		return var_0_0:translation("DISMISS_DEFENCE_HERO")
	end
end
