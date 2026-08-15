local var_0_0 = class("DreamWorldEnemyDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.dreamWorldMapEventTable
local var_0_4 = 78

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.eventID = arg_1_2.eventID
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dreamWorld = xyd.ModelManager.get():loadModel(xyd.ModelType.DREAM_WORLD)
	arg_1_0.battleID = var_0_3:battleID(arg_1_0.eventID)[arg_1_0.dreamWorld.mapType]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("text_title"):setString(var_0_1:translation("DREAM_WORLD_TEXT_6"))
	arg_3_0:nodeByName("text_enemy"):setString(var_0_1:translation("NEW_MAP_ENEMY_TXT"))

	local var_3_0 = xyd.tables.battle:fight1(arg_3_0.battleID)

	for iter_3_0 = 1, #var_3_0 do
		local var_3_1 = var_3_0[iter_3_0]
		local var_3_2 = var_0_2:color(var_3_1)
		local var_3_3 = var_0_2:star(var_3_1)
		local var_3_4 = var_0_2:level(var_3_1)
		local var_3_5 = {}
		local var_3_6 = cc.Node:create()

		var_3_6:setAnchorPoint(cc.p(0.5, 0.5))

		var_3_5.isBoss = false

		var_3_6:setContentSize(var_0_4, var_0_4)
		var_3_6:setPosition((iter_3_0 - 1) * (var_0_4 + 8) + 40, 40)
		xyd.setAvatarBorderNewUI(var_3_1, var_3_6, var_3_2, var_3_3)
		arg_3_0:nodeByName("panel_enemy"):addChild(var_3_6)

		var_3_5.id = var_3_1
		var_3_5.lev = var_3_4
		var_3_5.quality = var_3_2
		var_3_5.name = xyd.tables.hero:name(var_3_1)
		var_3_5.desc = xyd.tables.hero:getDes(var_3_1)
		var_3_5.isHero = true

		local var_3_7, var_3_8 = var_3_6:getPosition()

		var_3_6:setTouchEnabled(true)
		var_3_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				local var_4_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_4_1 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

				if not var_4_0 then
					local var_4_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_3_5)

					xyd.adaptToWorldPosition(var_3_6, var_4_2)
				end

				return true
			elseif arg_4_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_4_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	local var_3_9 = var_3_0[1]

	if var_3_9 and var_3_9 > 0 then
		local var_3_10 = xyd.tables.hero:modelID(var_3_9)
		local var_3_11 = xyd.HeroAnimation.new(nil, var_3_10, xyd.tables.model:uiScale(var_3_10) * 0.8, {})

		var_3_11:addTo(arg_3_0:nodeByName("boss_node"))
		var_3_11:idle()
	end

	arg_3_0:nodeByName("btn_battle"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = xyd.SelectTeamType.DREAM_WORLD
			local var_5_1 = {
				type = var_5_0,
				battleID = arg_3_0.battleID,
				campaignType = xyd.CampaignType.DREAM_WORLD
			}

			xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_5_1)
		end
	end)
end

function var_0_0.didOpen(arg_6_0)
	arg_6_0:addBlockLayer()
end

return var_0_0
