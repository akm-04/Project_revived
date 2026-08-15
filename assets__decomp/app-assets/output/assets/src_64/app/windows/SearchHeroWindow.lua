local var_0_0 = class("CommonAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = import("app.common.ui.CommonInputBox")
local var_0_3 = xyd.tables.translation

function var_0_0.didOpen(arg_1_0)
	arg_1_0:addBlockLayerWithNoTouchEvent()

	arg_1_0.inputBox = var_0_2.new({
		height = 54,
		bg = "windows/common/background/bg_common_input.png",
		width = 377,
		defaultTxt = var_0_3:translation("HERO_SEARCH_TIPS")
	})

	arg_1_0.inputBox:addTo(arg_1_0:background())
	arg_1_0.inputBox:setAnchorPoint(0.5, 0.5)
	arg_1_0.inputBox:setPosition(arg_1_0:nodeByName("pos_inputbox"):getPosition())

	arg_1_0.confirmBtn = var_0_1.new({
		titleSize = 24,
		sprite = "windows/button/btn195_2.png",
		title = var_0_3:translation("HERO_LIST_BTN_SEARCH"),
		clickMode = xyd.ButtonClickMode.SCALE
	})

	arg_1_0.confirmBtn:addTo(arg_1_0:background())
	arg_1_0.confirmBtn:setAnchorPoint(0.5, 0.5)
	arg_1_0.confirmBtn:setPosition(arg_1_0:nodeByName("pos_btn"):getPosition())
	arg_1_0.confirmBtn:addTouchEvent(function(arg_2_0)
		if arg_2_0.name == "began" then
			return true
		elseif arg_2_0.name == "ended" then
			local var_2_0 = arg_1_0.inputBox:getText()

			if var_2_0 and var_2_0 ~= "" then
				xyd.EventDispatcher.get():dispatchEvent({
					name = xyd.event.HERO_SEARCH,
					heroName = var_2_0
				})
			end

			arg_1_0:close()
		end
	end)
end

return var_0_0
