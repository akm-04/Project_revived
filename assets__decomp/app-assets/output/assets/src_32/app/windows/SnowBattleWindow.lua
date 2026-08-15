local var_0_0 = class("SnowBattleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = import("app.model.Hero")
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.mainRole_ = arg_1_0.snowActivity:getHero()
	arg_1_0.preHeros_ = {}
	arg_1_0.preSelect_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.arenaInfo = arg_2_0.snowActivity:getArenaInfo()

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	var_0_1.performWithDelayGlobal(function()
		arg_3_0:inHeroList()
	end, 0.034)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setupButton()
	arg_5_0:updateIceCore()
	arg_5_0:nodeByName("ice_coin_num"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_5_0:nodeByName("text_score"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_5_0:nodeByName("text_item_num"):enableOutline(cc.c4b(54, 161, 211, 255), 2)
	arg_5_0:nodeByName("text_score"):setString(var_0_2:translation("SNOW_ACTIVITY_BATTLE_SCORE"))

	local var_5_0 = xyd.AssetLoader.get():loadLabel(nil, "inscription_lev")

	var_5_0:setString(math.floor(arg_5_0.arenaInfo.point or 0))
	var_5_0:setScale(1.5)
	var_5_0:addTo(arg_5_0:nodeByName("container"))

	local var_5_1 = cc.p(arg_5_0:nodeByName("text_score"):getPosition())
	local var_5_2 = arg_5_0:nodeByName("text_score"):getContentSize()

	var_5_0:setAnchorPoint(cc.p(0, 0.5))
	var_5_0:setPosition(cc.p(var_5_1.x + var_5_2.width / 2, var_5_1.y))

	local var_5_3 = arg_5_0.backpack:getItemNumByID(var_0_4.snowmanChallengeItem)

	arg_5_0:nodeByName("text_item_num"):setString(var_5_3)
end

function var_0_0.inHeroList(arg_6_0)
	local var_6_0 = arg_6_0.arenaInfo.defense

	if not var_6_0 or not next(var_6_0) then
		return
	end

	local var_6_1 = arg_6_0:nodeByName("list")

	arg_6_0.preSelect_ = {}
	arg_6_0.preHeros_ = {}

	var_6_1:removeAllChildren()

	local var_6_2 = var_6_1:getContentSize()
	local var_6_3 = display.newNode()
	local var_6_4 = 0

	for iter_6_0 = #var_6_0, 1, -1 do
		local var_6_5 = arg_6_0.selfPlayer:getHero(var_6_0[iter_6_0])
		local var_6_6 = var_0_3.new()

		var_6_6:populate(var_6_5:toParams())
		table.insert(arg_6_0.preHeros_, 1, var_6_6)
		table.insert(arg_6_0.preSelect_, 1, var_6_6:getHeroID())

		if var_6_6 then
			local var_6_7 = var_6_6:getHeroModel()

			var_6_7:addTo(var_6_3)
			var_6_7:setScale(0.65)
			var_6_7:setPosition(cc.p(var_6_4, 0))

			var_6_4 = var_6_4 + 120
		end
	end

	arg_6_0.snowActivity:formatNewHeros(arg_6_0.preHeros_, arg_6_0.mainRole_:getLevel(), arg_6_0.mainRole_:getColor())

	local var_6_8 = var_6_4 + 20
	local var_6_9 = arg_6_0.snowActivity:getHero():getHeroModel()

	var_6_9:addTo(var_6_3)
	var_6_9:setPosition(cc.p(var_6_8, 0))
	var_6_9:setScale(0.75)

	local var_6_10 = arg_6_0.snowActivity:getBaseInfo().effect_id
	local var_6_11 = arg_6_0.snowActivity:updateHeroEffect(var_6_10, var_6_9)

	if var_6_11 then
		var_6_11:setPosition(cc.p(0, var_6_9:getContentSize().height / 2))
	end

	var_6_3:setAnchorPoint(cc.p(0.5, 0))
	var_6_3:setContentSize(var_6_8, 0)
	var_6_3:addTo(var_6_1)
	var_6_3:setPosition(cc.p(var_6_2.width / 2, 0))
end

function var_0_0.setupButton(arg_7_0)
	arg_7_0:nodeByName("btn_change"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {
				teamType = xyd.SnowSelectTeamType.CHANGE_DEFENSE,
				preHeros = arg_7_0.preHeros_,
				selected = arg_7_0.preSelect_,
				defense = arg_7_0.arenaInfo.defense
			}

			xyd.WindowManager.get():openWindow("snow_select_team", var_8_0)
		end
	end)
	arg_7_0:nodeByName("btn_record"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0.snowActivity:battleRecords({}, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("snow_records", arg_10_1)
				end
			end)
		end
	end)
	arg_7_0:nodeByName("btn_fight"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			if arg_7_0.backpack:getItemNumByID(var_0_4.snowmanChallengeItem) <= 0 then
				local var_11_0 = var_0_2:translation("SNOW_ACTIVITY_ITEM_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			arg_7_0.snowActivity:matchEnemy(function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					local var_12_0 = {
						preHeros = arg_7_0.preHeros_,
						selected = arg_7_0.preSelect_,
						match_infos = arg_12_1.match_infos
					}

					xyd.WindowManager.get():openWindow("snow_select_enemy", var_12_0)
				end
			end)
		end
	end)
	arg_7_0:nodeByName("btn_shop"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("snow_shop")
		end
	end)
	xyd.imgEvent(arg_7_0:nodeByName("btn_close"), function()
		xyd.WindowManager.get():closeWindow(arg_7_0)
	end)
end

function var_0_0.updateDefense(arg_15_0)
	arg_15_0.arenaInfo = arg_15_0.snowActivity:getArenaInfo()

	arg_15_0:inHeroList()
end

function var_0_0.updateIceCore(arg_16_0)
	arg_16_0:nodeByName("ice_coin_num"):setString(arg_16_0.selfPlayer.iceCore)
end

return var_0_0
