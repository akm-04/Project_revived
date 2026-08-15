local var_0_0 = class("TrialDetailWindow", import("app.common.ui.BaseWindow"))

var_0_0.START_BUTTON = "start"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_DESC = "txt_desc"
var_0_0.TXT_XIAOHAO = "txt_xiaohao"
var_0_0.TXT_ENERGY = "txt_energy"
var_0_0.TXT_ENEMY = "txt_enemy"
var_0_0.TXT_EQUIP = "txt_equip"
var_0_0.PANEL_EQUIP = "panel_equip"
var_0_0.PANEL_ENEMY = "panel_enemy"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.params = arg_1_2

	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	for iter_3_0 = 1, 3 do
		if iter_3_0 <= arg_3_0.params.star then
			arg_3_0:nodeByName("light_star" .. iter_3_0):setVisible(true)
			arg_3_0:nodeByName("gray_star" .. iter_3_0):setVisible(false)
		else
			arg_3_0:nodeByName("light_star" .. iter_3_0):setVisible(false)
			arg_3_0:nodeByName("gray_star" .. iter_3_0):setVisible(true)
		end
	end

	local var_3_0 = arg_3_0.params.trialID
	local var_3_1 = xyd.tables.trial:trialName(var_3_0)

	arg_3_0:nodeByName(var_0_0.TXT_NAME):setString(var_3_1)

	local var_3_2 = xyd.tables.trial:trialDesc(var_3_0)

	arg_3_0:nodeByName(var_0_0.TXT_DESC):setString(var_3_2)

	local var_3_3 = xyd.tables.trial:energyCost(var_3_0)

	arg_3_0:nodeByName(var_0_0.TXT_ENERGY):setString(var_3_3)
	arg_3_0:nodeByName(var_0_0.TXT_XIAOHAO):setString(var_0_1:translation("MAP_TILI_TXT"))
	arg_3_0:nodeByName(var_0_0.TXT_ENEMY):setString(var_0_1:translation("MAP_ENEMY_TXT"))
	arg_3_0:nodeByName(var_0_0.TXT_EQUIP):setString(var_0_1:translation("MAP_GET_TXT"))

	local var_3_4 = xyd.tables.trial:monsterDisplay(var_3_0)
	local var_3_5 = xyd.tables.trial:monsterStar(var_3_0)
	local var_3_6 = xyd.tables.trial:monsterQuality(var_3_0)
	local var_3_7 = xyd.tables.trial:monsterLevel(var_3_0)

	for iter_3_1 = 1, #var_3_4 do
		local var_3_8 = cc.Node:create()

		if iter_3_1 ~= #var_3_4 then
			var_3_8:setContentSize(110, 110)
		else
			var_3_8:setContentSize(127, 127)
		end

		xyd.setAvatarBorder(var_3_4[iter_3_1], var_3_8, var_3_6[iter_3_1], var_3_5[iter_3_1])
		arg_3_0:nodeByName(var_0_0.PANEL_ENEMY):addChild(var_3_8)
		var_3_8:setPosition(iter_3_1 * 130 - 130, 0)
	end

	local var_3_9 = xyd.tables.trial:itemDisplay(var_3_0)

	for iter_3_2 = 1, #var_3_9 do
		local var_3_10 = cc.Node:create()

		var_3_10:setContentSize(114, 113)
		xyd.setItemBorder(var_3_10, var_3_9[iter_3_2])
		arg_3_0:nodeByName(var_0_0.PANEL_EQUIP):addChild(var_3_10)
		var_3_10:setPosition(iter_3_2 * 120 - 120, 0)
	end
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	return
end

function var_0_0.didOpen(arg_5_0)
	arg_5_0:nodeByName(var_0_0.START_BUTTON):addTouchEventListener(function(arg_6_0, arg_6_1)
		local var_6_0 = {
			trialID = arg_5_0.params.trialID,
			trialType = arg_5_0.params.trialType
		}

		xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_0)
	end)
end

function var_0_0.didClose(arg_7_0)
	return
end

return var_0_0
