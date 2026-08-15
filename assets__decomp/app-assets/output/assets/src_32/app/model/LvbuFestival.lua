local var_0_0 = class("LvbuFestival", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.model.Hero")
local var_0_4 = 6
local var_0_5 = 5

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teamHeros = {}
	arg_1_0.lastGroupIds = {}
	arg_1_0.currentSelectedIds = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	local var_3_1 = {
		activity_id = xyd.Activities.LvbuFestival
	}

	var_3_0:loadSingleActivity(var_3_1, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.activity = arg_4_1
			arg_3_0.details = arg_3_0.activity.details
			arg_3_0.free_summon_times = arg_3_0.details.free_summon_times
			arg_3_0.luckyStar = arg_3_0.details.lucky_star
			arg_3_0.teamHeros = arg_3_0:initialTeam()

			arg_3_0:initialLastGoupInfos()

			arg_3_0.isAwards = xyd.splitToNumber(arg_3_0.details.is_awards, "|")
			arg_3_0.isDailyEnter = arg_3_0.details.daily_enter
			arg_3_0.exchangeLimit = arg_3_0.details.exchange_times

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_LVBU_ASSETS
			})

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.initialTeam(arg_5_0, arg_5_1)
	local var_5_0 = {}

	arg_5_1 = arg_5_1 or xyd.splitToNumber(arg_5_0.details.partner_ids, "|")

	for iter_5_0 = 1, #arg_5_1 do
		local var_5_1 = var_0_3.new()

		var_5_1:populateWithTableID(arg_5_1[iter_5_0])
		table.insert(var_5_0, var_5_1)
	end

	arg_5_0:formatLvbuCampusHeros(var_5_0)

	return var_5_0
end

function var_0_0.initialLastGoupInfos(arg_6_0)
	if arg_6_0.details.random_ids then
		arg_6_0.lastGroupIds = xyd.splitToNumber(arg_6_0.details.random_ids, "|") or {}
	end

	if arg_6_0.details.cur_select then
		arg_6_0.currentSelectedIds = xyd.splitToNumber(arg_6_0.details.cur_select, "|") or {}
	end
end

function var_0_0.formatLvbuCampusHeros(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		local var_7_0 = {
			100,
			100,
			80,
			60,
			0,
			0
		}
		local var_7_1 = {
			0,
			1,
			1,
			1,
			1,
			1
		}
		local var_7_2 = {
			0,
			1,
			1,
			1,
			1,
			1
		}
		local var_7_3 = 5

		arg_7_0:renewHeroInfo(iter_7_1, var_7_0, var_7_1, var_7_2, var_7_3)

		iter_7_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_7_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5)
	local var_8_0 = xyd.tables.misc.regionHeroColor

	arg_8_1.level_, arg_8_1.color_ = xyd.tables.misc.regionHeroLevel, var_8_0
	arg_8_1.skillLev_ = {}
	arg_8_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_8_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_8_1.color_ >= xyd.EquipQuality.GREEN then
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_8_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_8_1.color_ >= xyd.EquipQuality.BLUE then
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_8_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_8_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_8_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_8_1:isAwaken() then
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_8_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_8_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	if arg_8_1:isAwakeTwice() then
		arg_8_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = tonumber(arg_8_2[xyd.SKILL_INDEX.AwakeTwice]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.AwakeTwice]
	else
		arg_8_1.skillLev_[xyd.SKILL_INDEX.AwakeTwice] = false
	end

	arg_8_1.equips_ = {}

	for iter_8_0 = 1, var_0_4 do
		table.insert(arg_8_1.equips_, tonumber(arg_8_4[iter_8_0]))
	end

	arg_8_1.fumo_ = {}

	for iter_8_1 = 1, var_0_4 do
		table.insert(arg_8_1.fumo_, tonumber(arg_8_3[iter_8_1]))
	end

	arg_8_1.fumoLev_ = {}

	for iter_8_2 = 1, var_0_4 do
		local var_8_1 = arg_8_1:getEquipByIndex(iter_8_2)

		table.insert(arg_8_1.fumoLev_, tonumber(var_8_1:getMaxFumoStar()))
	end

	arg_8_1:setStar(arg_8_5)
end

function var_0_0.getRandomTeam(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_RANDOM_TEAM, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.details.free_change_times = arg_10_1.free_change_times
		end

		if arg_9_2 then
			arg_9_2(arg_10_0, arg_10_1)
		end
	end)
end

function var_0_0.setTeam(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_SET_TEAM, var_11_0, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.details.partner_ids = arg_12_1.partner_ids
			arg_11_0.details.cur_select = arg_12_1.cur_select or ""
			arg_11_0.details.random_ids = arg_12_1.random_ids or ""

			arg_11_0:initialLastGoupInfos()

			arg_11_0.teamHeros = arg_11_0:initialTeam()

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.LVBU_GROUP_CHANGE
			})
		end

		if arg_11_2 then
			arg_11_2(arg_12_0, arg_12_1)
		end
	end)
end

function var_0_0.playChangeTeam(arg_13_0)
	if #arg_13_0.lastGroupIds > 0 then
		arg_13_0:selectLastTeam()
	elseif arg_13_0.details.free_change_times <= 0 and arg_13_0.selfPlayer.crystal < xyd.tables.misc.lvbuTeamChange then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_2:translation("ZUANSHI_ABSENCE"), function()
			local var_14_0 = {}

			var_14_0.windowState = true

			xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
		end)

		return
	elseif arg_13_0.details.free_change_times <= 0 then
		local var_13_0 = string.format(var_0_2:translation("SURE_COST_CHANGE_GROUP"), xyd.tables.misc.lvbuTeamChange)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_13_0, function()
			arg_13_0:buyAndSelectTeam()
		end)
	else
		arg_13_0:buyAndSelectTeam()
	end
end

function var_0_0.selectLastTeam(arg_16_0)
	local var_16_0 = {
		ids = arg_16_0.lastGroupIds,
		cur_select = arg_16_0.currentSelectedIds
	}

	xyd.WindowManager.get():openWindow("lvbu_select_hero", var_16_0)
end

function var_0_0.buyAndSelectTeam(arg_17_0)
	arg_17_0:getRandomTeam({}, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = {
				ids = arg_18_1.partner_ids
			}

			xyd.WindowManager.get():openWindow("lvbu_select_hero", var_18_0)
		end
	end)
end

function var_0_0.goForward(arg_19_0, arg_19_1, arg_19_2)
	local var_19_0 = arg_19_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_GO_FORWARD, var_19_0, function(arg_20_0, arg_20_1)
		if arg_20_0 == xyd.error.OK then
			arg_19_0.details.campaign_id = arg_20_1.campaign_id
			arg_19_0.details.event_id = arg_20_1.event_id
			arg_19_0.details.partner_ids = arg_20_1.partner_ids
			arg_19_0.details.status = arg_20_1.status
			arg_19_0.details.walk = arg_20_1.walk

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_LVBU_ASSETS
			})
		end

		if arg_19_2 then
			arg_19_2(arg_20_0, arg_20_1)
		end
	end)
end

function var_0_0.buyWalk(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = arg_21_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_BUY_WALK, var_21_0, function(arg_22_0, arg_22_1)
		if arg_22_0 == xyd.error.OK then
			arg_21_0.details.walk = arg_22_1.walk

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.REFRESH_LVBU_ASSETS
			})
		end

		if arg_21_2 then
			arg_21_2(arg_22_0, arg_22_1)
		end
	end)
end

function var_0_0.summon(arg_23_0, arg_23_1, arg_23_2)
	local var_23_0 = arg_23_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_SUMMON, var_23_0, function(arg_24_0, arg_24_1)
		if arg_24_0 == xyd.error.OK then
			arg_23_0.details.normal = arg_24_1.normal
			arg_23_0.details.super = arg_24_1.super
			arg_23_0.details.summon_times = arg_24_1.summon_times
			arg_23_0.free_summon_times = arg_24_1.free_summon_times or 0
			arg_23_0.luckyStar = arg_24_1.lucky_star
		end

		if arg_23_2 then
			arg_23_2(arg_24_0, arg_24_1)
		end
	end)
end

function var_0_0.repair(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_REPAIR, var_25_0, function(arg_26_0, arg_26_1)
		if arg_26_0 == xyd.error.OK then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():addItemsByID(xyd.tables.misc.lvbuBrokenCard, -1)
		end

		if arg_25_2 then
			arg_25_2(arg_26_0, arg_26_1)
		end
	end)
end

function var_0_0.exchangeItems(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_EXCHANGE_ITEMS, var_27_0, function(arg_28_0, arg_28_1)
		if arg_28_0 == xyd.error.OK then
			-- block empty
		end

		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

function var_0_0.battle(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_BATTLE, var_29_0, function(arg_30_0, arg_30_1)
		if arg_30_0 == xyd.error.OK then
			local var_30_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack()
			local var_30_1 = {
				itemNum = 1,
				itemID = xyd.tables.misc.lubuMatchTicket
			}

			var_30_0:removeItem(var_30_1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.LVBU_MATCH_TICKET_CHANGE
			})
		end

		if arg_29_2 then
			arg_29_2(arg_30_0, arg_30_1)
		end
	end, nil, nil, false)
end

function var_0_0.getRecordList(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1 or {}

	xyd.Backend.get():request(xyd.mid.LV_GET_RECORD_LIST, var_31_0, function(arg_32_0, arg_32_1)
		if arg_32_0 == xyd.error.OK then
			arg_31_0.records = arg_32_1
		end

		if arg_31_2 then
			arg_31_2(arg_32_0, arg_32_1)
		end
	end, nil, nil, false)
end

function var_0_0.getRankInfo(arg_33_0, arg_33_1, arg_33_2)
	local var_33_0 = arg_33_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_GET_RANK_INFO, var_33_0, function(arg_34_0, arg_34_1)
		if arg_34_0 == xyd.error.OK then
			arg_33_0.campusRankInfo = arg_34_1
		end

		if arg_33_2 then
			arg_33_2(arg_34_0, arg_34_1)
		end
	end)
end

function var_0_0.getBattleReport(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0 = arg_35_1 or {}

	xyd.Backend.get():request(xyd.mid.LV_GET_BATTLE_REPORT, var_35_0, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			-- block empty
		end

		if arg_35_2 then
			arg_35_2(arg_36_0, arg_36_1)
		end
	end, nil, nil, false)
end

function var_0_0.setCurrentHero(arg_37_0, arg_37_1, arg_37_2)
	local var_37_0 = arg_37_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_SET_CURRENT_HERO, var_37_0, function(arg_38_0, arg_38_1)
		if arg_38_0 == xyd.error.OK then
			-- block empty
		end

		if arg_37_2 then
			arg_37_2(arg_38_0, arg_38_1)
		end
	end, nil, nil, false)
end

function var_0_0.giveUp(arg_39_0, arg_39_1, arg_39_2)
	local var_39_0 = arg_39_1 or {}

	xyd.Backend.get():request(xyd.mid.LVBU_GIVE_UP_TEAM, var_39_0, function(arg_40_0, arg_40_1)
		if arg_40_0 == xyd.error.OK then
			arg_39_0.details.cur_select = arg_40_1.cur_select or ""
			arg_39_0.details.random_ids = arg_40_1.random_ids or ""

			arg_39_0:initialLastGoupInfos()
		end

		if arg_39_2 then
			arg_39_2(arg_40_0, arg_40_1)
		end
	end, nil, nil, false)
end

function var_0_0.isHaveLvbu(arg_41_0)
	for iter_41_0, iter_41_1 in pairs(arg_41_0.selfPlayer.heros_) do
		local var_41_0 = iter_41_1:getTableID()

		if iter_41_1:isAwaken() then
			var_41_0 = xyd.tables.hero:beforeAwaken(var_41_0)
		end

		if var_41_0 == xyd.tables.misc.lvbuTableID then
			return true
		end
	end

	return false
end

function var_0_0.isInSecondStage(arg_42_0)
	if arg_42_0.details.campaign_id == -1 then
		return true
	end

	return false
end

function var_0_0.getExchangeLimit(arg_43_0)
	return arg_43_0.exchangeLimit or {}
end

function var_0_0.shopExchange(arg_44_0, arg_44_1, arg_44_2)
	xyd.Backend.get():request(xyd.mid.LVBU_SHOP_EXCHANGE, arg_44_1, function(arg_45_0, arg_45_1)
		if arg_45_0 == xyd.error.OK then
			arg_44_0.luckyStar = arg_45_1.lucky_star

			if arg_44_2 then
				arg_44_2(arg_45_0, arg_45_1)
			end
		end
	end)
end

function var_0_0.lvbuGetCard(arg_46_0, arg_46_1, arg_46_2)
	xyd.Backend.get():request(xyd.mid.LVBU_GET_CARD, arg_46_1, function(arg_47_0, arg_47_1)
		if arg_47_0 == xyd.error.OK then
			if arg_47_1.fengxian_times then
				arg_46_0.details.fengxian_times = arg_47_1.fengxian_times
			end

			if arg_46_2 then
				arg_46_2(arg_47_0, arg_47_1)
			end
		end
	end)
end

function var_0_0.exchangeLvbusp(arg_48_0, arg_48_1, arg_48_2)
	xyd.Backend.get():request(xyd.mid.EXCHANGE_LVBUSP, arg_48_1, function(arg_49_0, arg_49_1)
		if arg_49_0 == xyd.error.OK then
			if arg_49_1.lvbusp_times then
				arg_48_0.details.lvbusp_times = arg_49_1.lvbusp_times
			end

			if arg_48_2 then
				arg_48_2(arg_49_0, arg_49_1)
			end
		end
	end)
end

return var_0_0
