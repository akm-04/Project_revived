local var_0_0 = class("ActivityWufuBlessingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.activityWufu
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.idx = arg_1_2.idx
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_title"):setString(var_0_2:name(arg_3_0.idx))
	arg_3_0:nodeByName("text_blessing"):setString(var_0_2:word(arg_3_0.idx))

	local var_3_0 = var_0_2:model(arg_3_0.idx)
	local var_3_1 = xyd.HeroAnimation.new(nil, var_3_0, xyd.tables.model:uiScale(var_3_0), {})

	if var_3_1 then
		var_3_1:idle()
	end

	var_3_1:addTo(arg_3_0:nodeByName("node_model"))

	local var_3_2 = "windows/activities/1214/bg_" .. arg_3_0.idx .. ".png"

	xyd.AssetLoader.get():loadSprite(var_3_2):addTo(arg_3_0:nodeByName("node_word"))

	local var_3_3 = "windows/activities/1214/word_" .. arg_3_0.idx .. ".png"
	local var_3_4 = xyd.AssetLoader.get():loadSprite(var_3_3)

	var_3_4:addTo(arg_3_0:nodeByName("node_word"))

	if arg_3_0.idx > 4 then
		var_3_4:setPosition(-4, 10)
	else
		var_3_4:setPosition(-8, 0)
	end

	arg_3_0:nodeByName("node_word"):setScale(0.9)
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
