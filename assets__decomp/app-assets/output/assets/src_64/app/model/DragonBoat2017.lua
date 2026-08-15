local var_0_0 = class("DragonBoat2017", import(".BaseModel"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.hero
local var_0_3 = 1
local var_0_4 = {
	400,
	240,
	80,
	65
}
local var_0_5 = {
	10001003,
	10001009,
	10001010,
	10001018,
	10001025,
	10001028,
	10001039,
	10001040,
	10001046,
	10001048,
	10001053,
	10001071,
	10001075,
	11001003,
	11001009,
	11001040
}

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teams_ = {}
	arg_1_0.boatID_ = nil
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.loadInfo(arg_3_0, arg_3_1)
	xyd.Backend.get():request(xyd.mid.LOAD_SINGLE_ACTIVITY, {
		activity_id = xyd.Activities.DragonBoat2017
	}, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.baseInfo = arg_4_1.details.base_info
			arg_3_0.buyLimitInfo = arg_4_1.details.buy_limit_info

			arg_3_0:initialHeros()

			if arg_3_1 then
				arg_3_1()
			end
		end
	end)
end

function var_0_0.getBuyTimes(arg_5_0)
	return arg_5_0.buyLimitInfo or {}
end

function var_0_0.initialHeros(arg_6_0)
	arg_6_0.teams_ = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.baseInfo.formation) do
		local var_6_0 = arg_6_0.selfPlayer:getHero(iter_6_1)

		if var_6_0 and not xyd.isInTable(var_0_5, var_6_0:getFirstTableID()) then
			var_6_0.dragonModel_ = var_6_0:getHeroModel()

			var_6_0.dragonModel_:retain()
			table.insert(arg_6_0.teams_, var_6_0)
		end
	end

	if #arg_6_0.teams_ < 1 then
		local var_6_1 = arg_6_0.selfPlayer:getHeroByTableID(10001001) or arg_6_0.selfPlayer:getHeroByTableID(11001001)

		var_6_1.dragonModel_ = var_6_1:getHeroModel()

		var_6_1.dragonModel_:retain()
		table.insert(arg_6_0.teams_, var_6_1)
	end
end

function var_0_0.getTeams(arg_7_0)
	return arg_7_0.teams_
end

function var_0_0.startBoating(arg_8_0, arg_8_1, arg_8_2)
	xyd.Backend.get():request(xyd.mid.START_BOAT2017_FIGHT, arg_8_1, function(arg_9_0, arg_9_1)
		if arg_9_0 == xyd.error.OK then
			arg_8_0.baseInfo = arg_9_1

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRAGON_BOAT_UPDATE
			})

			if arg_8_2 then
				arg_8_2(arg_9_0, arg_9_1)
			end
		end
	end)
end

function var_0_0.saveBoatFormation(arg_10_0, arg_10_1, arg_10_2)
	xyd.Backend.get():request(xyd.mid.SAVA_BOAT2017_FORMATION, arg_10_1, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end

		if arg_11_0 == xyd.error.OK then
			arg_10_0.baseInfo.formation = xyd.splitToNumber(arg_10_1.formation, "|")

			arg_10_0:initialHeros()
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.DRAGON_BOAT_UPDATE
			})
		end
	end)
end

function var_0_0.exchange(arg_12_0, arg_12_1, arg_12_2)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT2017_EXCHANGE, arg_12_1, function(arg_13_0, arg_13_1)
		if arg_13_0 == xyd.error.OK then
			if arg_13_1.buy_limit_info then
				arg_12_0.buyLimitInfo = arg_13_1.buy_limit_info
			end

			if arg_13_1.awards then
				arg_12_0.selfPlayer:handleRewards(arg_13_1.awards)
			end
		end

		if arg_12_2 then
			arg_12_2(arg_13_0, arg_13_1)
		end
	end)
end

function var_0_0.getRankData(arg_14_0, arg_14_1, arg_14_2)
	xyd.Backend.get():request(xyd.mid.DRAGON_BOAT2017_RANK, arg_14_1, function(arg_15_0, arg_15_1)
		if arg_14_2 then
			arg_14_2(arg_15_0, arg_15_1)
		end
	end)
end

function var_0_0.getBoatResource(arg_16_0, arg_16_1)
	local function var_16_0(arg_17_0)
		if tonumber(arg_17_0.is_skin_on) == 1 then
			return tonumber(arg_17_0.skin_id)
		else
			return var_0_2:modelID(arg_17_0.table_id)
		end
	end

	local var_16_1 = display.newNode()

	var_16_1:size(500, 200)

	local var_16_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1104/boat" .. arg_16_1.boat_id .. ".png")
	local var_16_3 = var_16_1:getWidth()
	local var_16_4 = var_16_1:getHeight()

	var_16_2:addTo(var_16_1, 1):align(display.CENTER_BOTTOM, var_16_3 / 2, 0)

	local var_16_5 = {
		y = 400,
		size = 46,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		x = var_16_1:getWidth() / 2,
		color = cc.c3b(62, 151, 253),
		text = arg_16_1.player_name
	}
	local var_16_6 = xyd.AssetLoader.get():loadLabel(var_16_5)

	var_16_6:addTo(var_16_1, 1):align(display.CENTER)
	var_16_6:enableOutline(cc.c4b(255, 255, 255, 255), 5)

	for iter_16_0, iter_16_1 in ipairs(arg_16_1.partners or {}) do
		local var_16_7 = xyd.HeroAnimation.new(iter_16_1.table_id, var_16_0(iter_16_1), 1, {})

		var_16_7:idle()
		var_16_7:addTo(var_16_1):pos(var_0_4[iter_16_0], var_0_4[4])
	end

	local var_16_8 = {
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_normal.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_move.atlas",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.json",
		"skeletons/ui_effect/activity_dragonboat/dragonboat_accelerate.atlas"
	}

	var_16_1.effect1_ = var_0_1.new(var_16_8[1], var_16_8[2], 1)

	var_16_1.effect1_:addTo(var_16_1, -1):pos(var_16_1:getWidth() / 2, 30)

	var_16_1.effect2_ = var_0_1.new(var_16_8[3], var_16_8[4], 1.3)

	var_16_1.effect2_:addTo(var_16_1, -1):pos(25, 20)

	var_16_1.effect3_ = var_0_1.new(var_16_8[5], var_16_8[6], 1)

	var_16_1.effect3_:addTo(var_16_1, 1):pos(180, 50)
	var_16_1.effect1_:hide()
	var_16_1.effect2_:hide()
	var_16_1.effect3_:hide()
	var_16_1:scale(0.5)
	var_16_1:retain()

	return var_16_1
end

function var_0_0.getTimes(arg_18_0)
	return arg_18_0.baseInfo.left_times or 0
end

function var_0_0.getBoatID(arg_19_0)
	if not arg_19_0.boatID_ or arg_19_0.boatID_ <= 0 then
		arg_19_0.boatID_ = tonumber(xyd.db.stateVariable:getState(arg_19_0.selfPlayer.playerID, xyd.state.DRAGON_BOAT2017_BOATID))
	end

	if arg_19_0.boatID_ <= 0 then
		arg_19_0.boatID_ = var_0_3
	end

	return arg_19_0.boatID_
end

function var_0_0.setBoatID(arg_20_0, arg_20_1)
	arg_20_0.boatID_ = arg_20_1

	local var_20_0 = {
		playerID = arg_20_0.selfPlayer.playerID,
		name = xyd.state.DRAGON_BOAT2017_BOATID,
		state = tostring(arg_20_1)
	}

	xyd.db.stateVariable:setState(var_20_0)
end

function var_0_0.isHeroInTeam(arg_21_0, arg_21_1)
	for iter_21_0, iter_21_1 in pairs(arg_21_0.teams_) do
		if iter_21_1:getFirstTableID() == arg_21_1:getFirstTableID() then
			return true
		end
	end

	return false
end

return var_0_0
