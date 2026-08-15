local var_0_0 = class("HeroTipsWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.id = arg_1_2.id
	arg_1_0.tipName = arg_1_2.name
	arg_1_0.lev = arg_1_2.lev
	arg_1_0.quality = arg_1_2.quality
	arg_1_0.desc = arg_1_2.desc
	arg_1_0.isBoss = arg_1_2.isBoss
	arg_1_0.hero = arg_1_2.hero
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:setContentSize(arg_2_0:nodeByName("container"):getContentSize())
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
	local var_4_0 = arg_4_0:nodeByName("avatar")

	var_4_0:removeAllChildren()

	if arg_4_0.hero then
		xyd.setAvatarBorder(arg_4_0.hero, var_4_0)
	else
		xyd.setAvatarBorder(arg_4_0.id, var_4_0, arg_4_0.quality, 0)
	end

	arg_4_0:nodeByName("name"):setString(arg_4_0.tipName)

	if arg_4_0.lev then
		arg_4_0:nodeByName("level"):setString("LV." .. arg_4_0.lev)
	else
		arg_4_0:nodeByName("level"):setString("")
	end

	if arg_4_0.isBoss then
		arg_4_0:nodeByName("isBoss"):setVisible(true)
	else
		arg_4_0:nodeByName("isBoss"):setVisible(false)
	end

	local var_4_1 = arg_4_0:createLabel(20, cc.c3b(250, 230, 92), arg_4_0.desc, arg_4_0:nodeByName("desc_container"))

	var_4_1:y(70)
	var_4_1:setAnchorPoint(cc.p(0, 1))

	local var_4_2 = var_4_1:getContentSize().height

	arg_4_0:nodeByName("tishi_di"):height(var_4_2 + 2)

	if not var_4_1:getString() or var_4_1:getString() == "" or var_4_1:getString() == "\n" then
		arg_4_0:nodeByName("tishi_di"):setVisible(false)
	end

	arg_4_0.tipHeight = var_4_2 + 120

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
