local var_0_0 = class("RefreshCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.maxTimes = 0
	arg_1_0.buyEnergyCost_ = {}
	arg_1_0.buyCoinCost_ = {}
	arg_1_0.shopCost_ = {}
	arg_1_0.arenaShopCost_ = {}
	arg_1_0.crusadeShopCost_ = {}
	arg_1_0.goblinShopCost_ = {}
	arg_1_0.topShopCost_ = {}
	arg_1_0.blackMarketCost_ = {}
	arg_1_0.regionShopCost_ = {}
	arg_1_0.buyManaRatio_ = {}
	arg_1_0.refreshEliteCost_ = {}
	arg_1_0.buySkillCost_ = {}
	arg_1_0.buyArenaCost_ = {}
	arg_1_0.treasureBuySP_ = {}
	arg_1_0.treasureMatchMana_ = {}
	arg_1_0.peakCrystalCost_ = {}
	arg_1_0.guildShopCost_ = {}
	arg_1_0.spaceShopCost_ = {}
	arg_1_0.buyBossCost_ = {}
	arg_1_0.skinShopCost_ = {}
	arg_1_0.incubusBuyCost_ = {}
	arg_1_0.honorShopCost_ = {}
	arg_1_0.illusionBuyCost_ = {}
	arg_1_0.illusionShopCost_ = {}
	arg_1_0.academyShopCost_ = {}
	arg_1_0.skycityHardCost_ = {}
	arg_1_0.magicShopCost_ = {}
	arg_1_0.teaTalkShopCost_ = {}
	arg_1_0.teamShopCost_ = {}
	arg_1_0.mazeRebornCost_ = {}
	arg_1_0.summonShopCost_ = {}
	arg_1_0.buyGlueCost_ = {}
	arg_1_0.spShopCost_ = {}
	arg_1_0.buyConquerCost_ = {}
	arg_1_0.ufocatcherCost_ = {}

	import("app.common.tables.TableParser").parse("refresh_cost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		if var_2_0 > arg_1_0.maxTimes then
			arg_1_0.maxTimes = var_2_0
		end

		arg_1_0.buyEnergyCost_[var_2_0] = tonumber(arg_2_0.buy_energy_cost)
		arg_1_0.buyCoinCost_[var_2_0] = tonumber(arg_2_0.buy_mana_cost)
		arg_1_0.shopCost_[var_2_0] = tonumber(arg_2_0.shop_cost)
		arg_1_0.arenaShopCost_[var_2_0] = tonumber(arg_2_0.arena_shop_cost)
		arg_1_0.crusadeShopCost_[var_2_0] = tonumber(arg_2_0.crusade_shop_cost)
		arg_1_0.goblinShopCost_[var_2_0] = tonumber(arg_2_0.goblin_shop_cost)
		arg_1_0.topShopCost_[var_2_0] = tonumber(arg_2_0.top_shop_cost)
		arg_1_0.regionShopCost_[var_2_0] = tonumber(arg_2_0.region_shop_cost)
		arg_1_0.blackMarketCost_[var_2_0] = tonumber(arg_2_0.black_market_cost)
		arg_1_0.buyManaRatio_[var_2_0] = tonumber(arg_2_0.buy_mana_ratio)
		arg_1_0.refreshEliteCost_[var_2_0] = tonumber(arg_2_0.refresh_elite_cost)
		arg_1_0.buySkillCost_[var_2_0] = tonumber(arg_2_0.buy_skill_cost)
		arg_1_0.buyArenaCost_[var_2_0] = tonumber(arg_2_0.buy_arena_cost)
		arg_1_0.treasureBuySP_[var_2_0] = tonumber(arg_2_0.treasure_buy_sp)
		arg_1_0.treasureMatchMana_[var_2_0] = tonumber(arg_2_0.treasure_match_mana)
		arg_1_0.peakCrystalCost_[var_2_0] = tonumber(arg_2_0.buy_top_cost)
		arg_1_0.guildShopCost_[var_2_0] = tonumber(arg_2_0.guild_shop_cost)
		arg_1_0.spaceShopCost_[var_2_0] = tonumber(arg_2_0.space_trip_shop_cost)
		arg_1_0.buyBossCost_[var_2_0] = tonumber(arg_2_0.buy_boss_cost)
		arg_1_0.skinShopCost_[var_2_0] = tonumber(arg_2_0.skin_shop_cost)
		arg_1_0.incubusBuyCost_[var_2_0] = tonumber(arg_2_0.incubus_buy_cost)
		arg_1_0.honorShopCost_[var_2_0] = tonumber(arg_2_0.guild_battle_shop_cost)
		arg_1_0.illusionBuyCost_[var_2_0] = tonumber(arg_2_0.buy_paradise_cost)
		arg_1_0.illusionShopCost_[var_2_0] = tonumber(arg_2_0.paradise_shop_cost)
		arg_1_0.academyShopCost_[var_2_0] = tonumber(arg_2_0.supremacy_shop_cost)
		arg_1_0.skycityHardCost_[var_2_0] = tonumber(arg_2_0.skycity_hard_cost)
		arg_1_0.magicShopCost_[var_2_0] = tonumber(arg_2_0.library_shop_cost)
		arg_1_0.teaTalkShopCost_[var_2_0] = tonumber(arg_2_0.guild_friend_shop_cost)
		arg_1_0.teamShopCost_[var_2_0] = tonumber(arg_2_0.team_shop_cost)
		arg_1_0.summonShopCost_[var_2_0] = tonumber(arg_2_0.vending_shop_cost)
		arg_1_0.mazeRebornCost_[var_2_0] = tonumber(arg_2_0.buy_maze_reborn_cost)
		arg_1_0.buyGlueCost_[var_2_0] = tonumber(arg_2_0.buy_glue_cost)
		arg_1_0.spShopCost_[var_2_0] = tonumber(arg_2_0.sp_shop_cost)
		arg_1_0.buyConquerCost_[var_2_0] = tonumber(arg_2_0.buy_conquer_cost)
		arg_1_0.ufocatcherCost_[var_2_0] = tonumber(arg_2_0.ufocatcher_cost)
	end)
end

function var_0_0.buyEnergyCost(arg_3_0, arg_3_1)
	return arg_3_0.buyEnergyCost_[arg_3_1] or 0
end

function var_0_0.buyCoinCost(arg_4_0, arg_4_1)
	return arg_4_0.buyCoinCost_[arg_4_1] or 0
end

function var_0_0.shopRefreshCost(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_2 == xyd.ShopType.NORMAL then
		return arg_5_0:shopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.ARENA then
		return arg_5_0:arenaShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.MARCH then
		return arg_5_0:crusadeShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.GNOME then
		return arg_5_0:goblinShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.BLACK then
		return arg_5_0:blackMarketCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.TOP then
		return arg_5_0:topShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.GUILD then
		return arg_5_0:guildShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.SPACE then
		return arg_5_0:spaceShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.REGION then
		return arg_5_0:regionShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.SKIN then
		return arg_5_0:skinShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.HONOR then
		return arg_5_0:honorShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.ILLUSION then
		return arg_5_0:illusionShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.ACADEMY_ARENA then
		return arg_5_0:academyShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.MAGIC then
		return arg_5_0:magicShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.TEATALK then
		return arg_5_0:teaTalkShopCost(arg_5_1)
	elseif arg_5_2 == xyd.ShopType.SUMMON then
		return arg_5_0:summonShopCost(arg_5_1)
	elseif xyd.tables.shop:isTeamShop(arg_5_2) == 1 then
		return arg_5_0:teamShopCost(arg_5_1)
	end
end

function var_0_0.shopCost(arg_6_0, arg_6_1)
	return arg_6_0.shopCost_[arg_6_1] or 0
end

function var_0_0.buyGlueCost(arg_7_0, arg_7_1)
	return arg_7_0.buyGlueCost_[arg_7_1] or 0
end

function var_0_0.honorShopCost(arg_8_0, arg_8_1)
	return arg_8_0.honorShopCost_[arg_8_1] or 0
end

function var_0_0.skinShopCost(arg_9_0, arg_9_1)
	return arg_9_0.skinShopCost_[arg_9_1] or 0
end

function var_0_0.arenaShopCost(arg_10_0, arg_10_1)
	return arg_10_0.arenaShopCost_[arg_10_1] or 0
end

function var_0_0.crusadeShopCost(arg_11_0, arg_11_1)
	return arg_11_0.crusadeShopCost_[arg_11_1] or 0
end

function var_0_0.goblinShopCost(arg_12_0, arg_12_1)
	return arg_12_0.goblinShopCost_[arg_12_1] or 0
end

function var_0_0.blackMarketCost(arg_13_0, arg_13_1)
	return arg_13_0.blackMarketCost_[arg_13_1] or 0
end

function var_0_0.topShopCost(arg_14_0, arg_14_1)
	return arg_14_0.topShopCost_[arg_14_1] or 0
end

function var_0_0.guildShopCost(arg_15_0, arg_15_1)
	return arg_15_0.guildShopCost_[arg_15_1] or 0
end

function var_0_0.spaceShopCost(arg_16_0, arg_16_1)
	return arg_16_0.spaceShopCost_[arg_16_1] or 0
end

function var_0_0.regionShopCost(arg_17_0, arg_17_1)
	return arg_17_0.regionShopCost_[arg_17_1] or 0
end

function var_0_0.buyManaRatio(arg_18_0, arg_18_1)
	return arg_18_0.buyManaRatio_[arg_18_1] or 0
end

function var_0_0.refreshEliteCost(arg_19_0, arg_19_1)
	return arg_19_0.refreshEliteCost_[arg_19_1] or 0
end

function var_0_0.buySkillCost(arg_20_0, arg_20_1)
	return arg_20_0.buySkillCost_[arg_20_1] or arg_20_0.buySkillCost_[arg_20_0.maxTimes] or 0
end

function var_0_0.buyArenaCost(arg_21_0, arg_21_1)
	return arg_21_0.buyArenaCost_[arg_21_1] or 0
end

function var_0_0.treasureBuySP(arg_22_0, arg_22_1)
	return arg_22_0.treasureBuySP_[arg_22_1] or 0
end

function var_0_0.peakCost(arg_23_0, arg_23_1)
	return arg_23_0.peakCrystalCost_[arg_23_1] or 0
end

function var_0_0.treasureMatchMana(arg_24_0, arg_24_1)
	return arg_24_0.treasureMatchMana_[arg_24_1] or arg_24_0.treasureMatchMana_[arg_24_0.maxTimes] or 2000
end

function var_0_0.buyBossCost(arg_25_0, arg_25_1)
	return arg_25_0.buyBossCost_[arg_25_1] or 0
end

function var_0_0.incubusBuyCost(arg_26_0, arg_26_1)
	return arg_26_0.incubusBuyCost_[arg_26_1] or 0
end

function var_0_0.illusionBuyCost(arg_27_0, arg_27_1)
	return arg_27_0.illusionBuyCost_[arg_27_1] or 0
end

function var_0_0.illusionShopCost(arg_28_0, arg_28_1)
	return arg_28_0.illusionShopCost_[arg_28_1] or 0
end

function var_0_0.academyShopCost(arg_29_0, arg_29_1)
	return arg_29_0.academyShopCost_[arg_29_1] or 0
end

function var_0_0.skycityHardCost(arg_30_0, arg_30_1)
	return arg_30_0.skycityHardCost_[arg_30_1] or 0
end

function var_0_0.magicShopCost(arg_31_0, arg_31_1)
	return arg_31_0.magicShopCost_[arg_31_1] or 0
end

function var_0_0.teaTalkShopCost(arg_32_0, arg_32_1)
	return arg_32_0.teaTalkShopCost_[arg_32_1] or 0
end

function var_0_0.summonShopCost(arg_33_0, arg_33_1)
	return arg_33_0.summonShopCost_[arg_33_1] or 0
end

function var_0_0.teamShopCost(arg_34_0, arg_34_1)
	return arg_34_0.teamShopCost_[arg_34_1] or 0
end

function var_0_0.mazeRebornCost(arg_35_0, arg_35_1)
	return arg_35_0.mazeRebornCost_[arg_35_1] or 0
end

function var_0_0.spShopCost(arg_36_0, arg_36_1)
	return arg_36_0.spShopCost_[arg_36_1] or 0
end

function var_0_0.buyConquerCost(arg_37_0, arg_37_1)
	return arg_37_0.buyConquerCost_[arg_37_1] or 0
end

function var_0_0.ufocatcherCost(arg_38_0, arg_38_1)
	return arg_38_0.ufocatcherCost_[arg_38_1] or 0
end

return var_0_0
