local var_0_0 = class("AdventureIllusionBattleResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.damage = math.floor(arg_1_2.damage or 0)
	arg_1_0.fighterA = arg_1_2.fighterA
	arg_1_0.fighterB = arg_1_2.fighterB
	arg_1_0.petA = arg_1_2.petA
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.init(arg_3_0)
	arg_3_0:nodeByName("continue_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)
			arg_3_0:dispatchEvent({
				name = xyd.event.BATTLE_END_BACK_TO_MAIN
			})
		end
	end)
	arg_3_0:nodeByName("damage_num"):setString(arg_3_0.damage)
	arg_3_0:nodeByName("data_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, {
				herosA = arg_3_0.fighterA,
				herosB = arg_3_0.fighterB,
				petA = arg_3_0.petA
			})
		end
	end)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
