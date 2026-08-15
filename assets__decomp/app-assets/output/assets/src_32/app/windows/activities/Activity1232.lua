local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.fifthAnniModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0.fifthAnniModel:getInfo(function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			arg_2_0:layout()
		end
	end)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.container:getChildByName("btn_rule")

	var_4_0:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			var_4_0:setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			var_4_0:setScale(1)

			local var_5_0 = {
				title_name = "FIFTH_ANNI_MAIN_RULE_TITLE",
				rule = "FIFTH_ANNI_MAIN_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)

	local var_4_1 = arg_4_0.container:getChildByName("btn_party")

	var_4_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_4_1:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_4_1:setScale(1)

			if arg_4_0:checkActivityIsOpen() then
				arg_4_0.fifthAnniModel:getInfo(function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("fifth_anni_party_main")
					end
				end)
			end
		end
	end)

	local var_4_2 = arg_4_0.container:getChildByName("btn_monopoly")

	var_4_2:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_4_2:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_4_2:setScale(1)

			if arg_4_0:checkActivityIsOpen() then
				arg_4_0.fifthAnniModel:getInfo(function(arg_9_0, arg_9_1)
					if arg_9_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("fifth_anni_monopoly")
					end
				end)
			end
		end
	end)

	local var_4_3 = arg_4_0.container:getChildByName("btn_gacha")

	var_4_3:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			var_4_3:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			var_4_3:setScale(1)

			if arg_4_0:checkActivityIsOpen() then
				xyd.WindowManager.get():openWindow("fifth_anni_gacha")
			end
		end
	end)

	local var_4_4 = arg_4_0.container:getChildByName("btn_boss")

	var_4_4:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			var_4_4:setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			var_4_4:setScale(1)

			if arg_4_0:checkActivityIsOpen() then
				arg_4_0.fifthAnniModel:getBossInfo(function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("fifth_anni_boss")
					end
				end)
			end
		end
	end)
end

function var_0_0.checkActivityIsOpen(arg_13_0)
	local var_13_0 = xyd.ServerTime.get():getServerTime()

	if var_13_0 < arg_13_0.activity.start_time then
		return false
	elseif var_13_0 >= arg_13_0.activity.end_time then
		return false
	else
		return true
	end
end

return var_0_0
