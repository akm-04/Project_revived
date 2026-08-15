local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.show(arg_1_0, arg_1_1)
	var_0_0.super.show(arg_1_0, arg_1_1)

	if not arg_1_0.res or arg_1_0.res == 0 then
		print("No res available.")

		return
	end

	local var_1_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_1_0.res)

	var_1_0:addTo(arg_1_0.parent)
	var_1_0:setPosition(38, 22)

	arg_1_0.container = var_1_0:getChildByName("container")

	arg_1_0:layout()
end

function var_0_0.layout(arg_2_0)
	local var_2_0 = arg_2_0.container

	var_2_0:getChildByName("text_top"):setString(var_0_1:translation("SEAL_HERO_DESC"))
	var_2_0:getChildByName("text_rule"):setString(var_0_1:translation("SEAL_HERO_RULE"))
	arg_2_0:initRuleTextDesc()
end

function var_0_0.initRuleTextDesc(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("rule_container")
	local var_3_1 = xyd.split(var_0_1:translation("SEAL_HERO_RULE_DESC"), "\n")
	local var_3_2 = var_3_0:getContentSize()
	local var_3_3 = var_3_2.width
	local var_3_4 = var_3_2.height

	for iter_3_0 = 1, #var_3_1 do
		local var_3_5 = arg_3_0:createTextLabel(var_3_1[iter_3_0], var_3_3, cc.ui.TEXT_ALIGN_LEFT, 24, cc.c3b(252, 255, 4))

		var_3_5:addTo(var_3_0)
		var_3_5:setPosition(cc.p(0, var_3_4))
		var_3_5:setAnchorPoint(cc.p(0, 1))

		var_3_4 = var_3_4 - var_3_5:getContentSize().height
	end
end

function var_0_0.createTextLabel(arg_4_0, arg_4_1, arg_4_2, arg_4_3, arg_4_4, arg_4_5)
	local var_4_0 = {
		text = arg_4_1,
		align = arg_4_3,
		color = arg_4_5,
		size = arg_4_4,
		dimensions = cc.size(arg_4_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_4_0))
end

return var_0_0
