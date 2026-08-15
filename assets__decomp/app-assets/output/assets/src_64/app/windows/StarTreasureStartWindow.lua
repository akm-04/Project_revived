local var_0_0 = class("StarTreasureStartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.starTreasureShop
local var_0_3 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.starTreasure = xyd.ModelManager.get():loadModel(xyd.ModelType.STAR_TREASURE)
	arg_1_0.info = arg_1_0.starTreasure:getInfo()
	arg_1_0.details = arg_1_0.info.details
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("progress_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 1)
	arg_4_0:nodeByName("progress_txt"):setString(string.format(var_0_1:translation("STAR_TREASURE_TIP4"), arg_4_0.details.current_floor))

	if arg_4_0.details.current_floor == 1 and arg_4_0.details.max_floor == 1 then
		arg_4_0:nodeByName("progress_txt"):setVisible(false)
	end

	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			return true
		elseif arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				title_name = "STAR_TREASURE_RULE_TITLE",
				rule = "STAR_TREASURE_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_5_0)
		end
	end)
	arg_4_0:nodeByName("start_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			return true
		elseif arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("star_treasure")
			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)
end

function var_0_0.willClose(arg_7_0)
	return
end

return var_0_0
