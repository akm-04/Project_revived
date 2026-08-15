local var_0_0 = class("DragonBoat", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.hero
local var_0_3 = {
	400,
	240,
	80,
	65
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.loaded_ = false
	arg_1_0.times_ = 0
	arg_1_0.buyTimes_ = 0
	arg_1_0.rankInfos_ = {}
	arg_1_0.selfRanInfos_ = {}
	arg_1_0.costTime_ = 0
	arg_1_0.lastBoatID_ = 1
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT_LOAD_INFO, {}, function(arg_4_0, arg_4_1, arg_4_2)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.times_ = tonumber(arg_4_1.times) or 0
			arg_3_0.boatTimes = tonumber(arg_4_1.boat_times) or 0
			arg_3_0.buyTimes_ = tonumber(arg_4_1.daily_buy_times) or arg_3_0.buyTimes_

			if arg_4_1.rank then
				arg_3_0.rankInfos_ = arg_4_1.rank
			end

			if arg_4_1.self_rank then
				arg_3_0.selfRanInfos_ = arg_4_1.self_rank
			end

			if arg_4_1.boat_id then
				arg_3_0.lastBoatID_ = arg_4_1.boat_id
			end

			if arg_3_1 then
				arg_3_1()
			end
		end
	end)
end

function var_0_0.getTimes(arg_5_0)
	return arg_5_0.times_
end

function var_0_0.buyTimes(arg_6_0, arg_6_1)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT_BUY_TIMES, {}, function(arg_7_0, arg_7_1, arg_7_2)
		if arg_7_0 == xyd.error.OK then
			arg_6_0.times_ = tonumber(arg_7_1.times) or arg_6_0.times_
			arg_6_0.buyTimes_ = tonumber(arg_7_1.daily_buy_times) or arg_6_0.buyTimes_

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRAGON_BOAT_UPDATE
			})

			if arg_6_1 then
				arg_6_1()
			end
		end
	end)
end

function var_0_0.startBoating(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT_START, arg_8_1, function(arg_9_0, arg_9_1, arg_9_2)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.matchPlayers = {}
			arg_8_0.lastBoatID_ = arg_8_1.boat_id

			for iter_9_0, iter_9_1 in pairs(arg_9_1.match_players or {}) do
				table.insert(arg_8_0.matchPlayers, iter_9_1)

				iter_9_1.boatSp_ = arg_8_0:getBoatResource(iter_9_1)
			end

			arg_8_0.times_ = tonumber(arg_9_1.times) or arg_8_0.times_
			arg_8_0.boatTimes = tonumber(arg_9_1.boat_times) or 0

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRAGON_BOAT_UPDATE
			})

			if arg_8_2 then
				arg_8_2()
			end
		end
	end)
end

function var_0_0.getBuyTimesCost(arg_10_0)
	return xyd.tables.misc.dragonBoatBuyTimesCost
end

function var_0_0.endBoating(arg_11_0, arg_11_1, arg_11_2)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT_END_BOAT, arg_11_1, function(arg_12_0, arg_12_1, arg_12_2)
		if arg_12_0 == xyd.error.OK then
			if arg_12_1.rank_info and arg_12_1.rank_info.rank then
				arg_11_0.rankInfos_ = arg_12_1.rank_info.rank
			end

			if arg_12_1.rank_info and arg_12_1.rank_info.self_rank then
				arg_11_0.selfRanInfos_ = arg_12_1.rank_info.self_rank
			end

			if arg_12_1.boat_id then
				arg_11_0.lastBoatID_ = arg_12_1.boat_id
			end

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRAGON_BOAT_UPDATE
			})
		end

		if arg_11_2 then
			arg_11_2(arg_12_1)
		end
	end)
end

function var_0_0.getRankData(arg_13_0, arg_13_1)
	if not arg_13_1 then
		return arg_13_0.rankInfos_
	end

	if arg_13_1 <= 0 then
		return arg_13_0.rankInfos_["-1"] or {}
	end

	return arg_13_0.rankInfos_[tostring(arg_13_1)] or {}
end

function var_0_0.getSelfRankInfos(arg_14_0, arg_14_1)
	if not arg_14_1 then
		return arg_14_0.selfRanInfos_
	end

	if arg_14_1 <= 0 then
		return arg_14_0.selfRanInfos_["-1"] or {}
	end

	return arg_14_0.selfRanInfos_[tostring(arg_14_1)] or {}
end

function var_0_0.getSelfRank(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0:getRankData(arg_15_1).self_rank

	if var_15_0 <= 0 then
		return {
			rank = 0,
			cost_time = 0
		}
	end

	local var_15_1 = arg_15_0:getSelfRankInfos(arg_15_1)

	for iter_15_0, iter_15_1 in ipairs(var_15_1) do
		if var_15_0 == iter_15_1.rank then
			return iter_15_1
		end
	end

	return {
		rank = 0,
		cost_time = 0
	}
end

function var_0_0.getMatchPlayers(arg_16_0)
	return arg_16_0.matchPlayers or {}
end

function var_0_0.getBoatResource(arg_17_0, arg_17_1)
	local function var_17_0(arg_18_0)
		if tonumber(arg_18_0.is_skin_on) == 1 then
			return tonumber(arg_18_0.skin_id)
		else
			return var_0_2:modelID(arg_18_0.table_id)
		end
	end

	local var_17_1 = display.newNode()

	var_17_1:size(500, 200)

	local var_17_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1060/boat" .. arg_17_1.boat_id .. ".png")
	local var_17_3 = var_17_1:getWidth()
	local var_17_4 = var_17_1:getHeight()

	var_17_2:addTo(var_17_1, 1):align(display.CENTER_BOTTOM, var_17_3 / 2, 0)

	local var_17_5 = {
		y = 400,
		size = 46,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = var_17_1:getWidth() / 2,
		color = cc.c3b(62, 151, 253),
		text = arg_17_1.player_name
	}
	local var_17_6 = xyd.AssetLoader.get():loadLabel(var_17_5)

	var_17_6:addTo(var_17_1, 1):align(display.CENTER)
	var_17_6:enableOutline(cc.c4b(255, 255, 255, 255), 5)

	for iter_17_0, iter_17_1 in ipairs(arg_17_1.partners or {}) do
		local var_17_7 = xyd.HeroAnimation.new(iter_17_1.table_id, var_17_0(iter_17_1), 1, {})

		var_17_7:idle()
		var_17_7:addTo(var_17_1):pos(var_0_3[iter_17_0], var_0_3[4])
	end

	local var_17_8 = {
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.atlas"
	}

	var_17_1.effect1_ = var_0_1.new(var_17_8[1], var_17_8[2], 1)

	var_17_1.effect1_:addTo(var_17_1, -1):pos(var_17_1:getWidth() / 2, 30)

	var_17_1.effect2_ = var_0_1.new(var_17_8[3], var_17_8[4], 1.3)

	var_17_1.effect2_:addTo(var_17_1, -1):pos(25, 20)

	var_17_1.effect3_ = var_0_1.new(var_17_8[5], var_17_8[6], 1)

	var_17_1.effect3_:addTo(var_17_1, 1):pos(180, 50)
	var_17_1.effect1_:hide()
	var_17_1.effect2_:hide()
	var_17_1.effect3_:hide()
	var_17_1:scale(0.5)
	var_17_1:retain()

	return var_17_1
end

function var_0_0.getCostTime(arg_19_0)
	return arg_19_0.costTime_
end

function var_0_0.getLastBoatID(arg_20_0)
	return arg_20_0.lastBoatID_
end

return var_0_0
