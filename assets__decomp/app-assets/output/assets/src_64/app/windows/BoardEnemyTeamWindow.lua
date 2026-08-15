local var_0_0 = class("BoardEnemyTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.mission = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("enemy_title"):setString(xyd.tables.translation:translation("EVENT_CENTRE_BOARD_ENEMY_TITLE"))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:addBlockLayer()

	local var_4_0 = xyd.tables.eventCentreMissionTable:enemy(arg_4_0.mission.mission_id)
	local var_4_1 = xyd.tables.eventCentreMissionTable:monsterQuality(arg_4_0.mission.mission_id)
	local var_4_2 = xyd.tables.eventCentreMissionTable:monsterStar(arg_4_0.mission.mission_id)
	local var_4_3 = xyd.tables.eventCentreMissionTable:monsterLevel(arg_4_0.mission.mission_id)

	for iter_4_0 = 1, #var_4_0 do
		local var_4_4 = {}
		local var_4_5 = cc.Node:create()

		var_4_5:setContentSize(95, 95)
		xyd.setAvatarBorderWithLevelAndHp(var_4_0[iter_4_0], var_4_5, var_4_1[iter_4_0], var_4_2[iter_4_0], var_4_3[iter_4_0])
		arg_4_0:nodeByName("enemy" .. iter_4_0 .. "_icon"):addChild(var_4_5)
		var_4_5:setPosition(0, 0)

		var_4_4.id = var_4_0[iter_4_0]
		var_4_4.lev = var_4_3[iter_4_0]
		var_4_4.quality = var_4_1[iter_4_0]
		var_4_4.name = xyd.tables.hero:name(var_4_0[iter_4_0])
		var_4_4.isHero = true

		arg_4_0:nodeByName("enemy" .. iter_4_0 .. "_name"):setString(var_4_4.name)

		var_4_4.desc = xyd.tables.hero:getDes(var_4_0[iter_4_0])

		local var_4_6, var_4_7 = var_4_5:getPosition()

		var_4_5:setTouchEnabled(true)
		var_4_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				local var_5_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_5_1 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

				if not var_5_0 then
					local var_5_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_4_4)

					xyd.adaptToWorldPosition(var_4_5, var_5_2)
				end

				return true
			elseif arg_5_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

return var_0_0
