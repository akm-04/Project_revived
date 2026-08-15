local var_0_0 = class("LvbuEntryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("btn_start"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("lvbu_door")
		end
	end)
	arg_2_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("lvbu_entry_rule")
		end
	end)
	arg_2_0:nodeByName("btn_story"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {}

			var_5_0.story_id = 10831002
			var_5_0.show_skip = true

			xyd.WindowManager.get():openWindow("lvbu_story_talk", var_5_0)
		end
	end)

	arg_2_0.getBtn = arg_2_0:nodeByName("btn_get")

	arg_2_0:updateGetBtn()
end

function var_0_0.updateGetBtn(arg_6_0)
	local var_6_0 = arg_6_0.selfPlayer:getHeroIgnoreAwaken(var_0_1.lvbuTableID)
	local var_6_1 = arg_6_0.backpack:getItemNumByID(var_0_1.lvbuBrokenCard)

	if var_6_0 or var_6_1 > 0 then
		arg_6_0.getBtn:setBright(false)
		arg_6_0.getBtn:setTouchEnabled(false)
	else
		arg_6_0.getBtn:setBright(true)
		arg_6_0.getBtn:setTouchEnabled(true)
		arg_6_0.getBtn:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.Backend.get():request(xyd.mid.LVBU_GET_CARD, {}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_6_0.selfPlayer:handleRewards(arg_8_1.awards)
						arg_6_0:updateGetBtn()
					end
				end)
			end
		end)
	end
end

return var_0_0
