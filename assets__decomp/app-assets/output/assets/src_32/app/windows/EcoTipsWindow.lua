local var_0_0 = class("EcoTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.tipName = arg_1_2.name
	arg_1_0.desc = arg_1_2.des
	arg_1_0.hasNum = arg_1_2.num
	arg_1_0.backendName = arg_1_2.backendName
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:nodeByName("hero_can_use_txt"):setVisible(false)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.createLabel(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = {
		color = arg_3_2,
		size = arg_3_1
	}
	local var_3_1 = xyd.AssetLoader.get():loadLabel(var_3_0)

	var_3_1:setMaxLineWidth(290)

	if arg_3_3 then
		var_3_1:setString(arg_3_3)
	end

	var_3_1:addTo(arg_3_4)

	return var_3_1
end

function var_0_0.layout(arg_4_0)
	arg_4_0.lev = xyd.tables.item:level(arg_4_0.id) or 1

	local var_4_0 = arg_4_0:nodeByName("item")
	local var_4_1 = xyd.tables.ecoType:getEcoPath(arg_4_0.backendName)
	local var_4_2 = xyd.AssetLoader.get():loadSprite(var_4_1)

	var_4_0:removeAllChildren()
	xyd.displaySpriteOnContainer(var_4_2, var_4_0, false)
	arg_4_0:nodeByName("name"):setString(arg_4_0.tipName)
	arg_4_0:nodeByName("level"):setString(string.format(xyd.tables.translation:translation("NEED_LEV"), arg_4_0.lev))
	arg_4_0:nodeByName("num"):setString(string.format(xyd.tables.translation:translation("HAS_NUM"), arg_4_0.hasNum))
	arg_4_0:nodeByName("jinbi_mini"):setVisible(false)
	arg_4_0:nodeByName("price"):setVisible(false)

	local var_4_3 = arg_4_0:createLabel(20, cc.c3b(250, 230, 92), nil, arg_4_0:nodeByName("desc_container"))

	var_4_3:setAnchorPoint(cc.p(0, 1))
	var_4_3:y(70)
	var_4_3:setString(arg_4_0.desc)

	local var_4_4 = var_4_3:getContentSize().height

	arg_4_0:nodeByName("tishi_di"):height(var_4_4 + 2)

	if not var_4_3:getString() or var_4_3:getString() == "" or var_4_3:getString() == "\n" then
		arg_4_0:nodeByName("tishi_di"):setVisible(false)
	end

	arg_4_0.tipHeight = var_4_4 + 120

	arg_4_0:nodeByName("container"):height(arg_4_0.tipHeight)
end

function var_0_0.getTipHeight(arg_5_0)
	return arg_5_0.tipHeight
end

function var_0_0.getTipWidth(arg_6_0)
	return arg_6_0:nodeByName("container"):getWidth()
end

function var_0_0.getSoundEffect(arg_7_0)
	return xyd.tables.sound:getSound("ui_tips")
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)

	if not arg_8_1.noBlock then
		arg_8_0:addBlockLayerClickClose(cc.c4b(0, 0, 0, 0), nil, nil, 2)
	end
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	var_0_0.super:willClose(arg_9_1)
end

return var_0_0
