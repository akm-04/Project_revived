local var_0_0 = class("JigsawViewWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = "skeletons/ui_effect/effect_redpacket/effect_redpacket1"
local var_0_4 = "skeletons/ui_effect/effect_redpacket/effect_redpacket3"
local var_0_5 = "main_scene_bottom"
local var_0_6 = "main_scene_left"
local var_0_7 = "main_scene_middle"
local var_0_8 = "main_scene_top"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ids = {}

	if arg_1_2 then
		arg_1_0.ids = arg_1_2.ids or {}
	end

	arg_1_0.index = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("desc_txt"):setString(var_0_2:translation("GET_NEW_GRAPH"))

	local var_3_0 = arg_3_0:nodeByName("next_btn")

	var_3_0:getChildByName("txt"):setString(var_0_2:translation("OK"))
	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:updateToNextPiece()
		end
	end)
	arg_3_0:updateToNextPiece()
end

function var_0_0.closeAllWithoutFourMainWindow(arg_5_0)
	local var_5_0 = {}
	local var_5_1 = xyd.WindowManager.get():getWindowHistory()

	for iter_5_0 = 1, #var_5_1 do
		local var_5_2 = var_5_1[iter_5_0]

		if var_5_2.name ~= var_0_5 and var_5_2.name ~= var_0_6 and var_5_2.name ~= var_0_7 and var_5_2.name ~= var_0_8 then
			table.insert(var_5_0, var_5_2.name)
		end
	end

	for iter_5_1 = 1, #var_5_0 do
		xyd.WindowManager.get():closeWindow(var_5_0[iter_5_1])
	end
end

function var_0_0.updateToNextPiece(arg_6_0)
	arg_6_0.index = arg_6_0.index + 1

	if arg_6_0.index > #arg_6_0.ids then
		if arg_6_0.selfPlayer.newJigIds and next(arg_6_0.selfPlayer.newJigIds) then
			arg_6_0.ids = clone(arg_6_0.selfPlayer.newJigIds)
			arg_6_0.selfPlayer.newJigIds = {}
			arg_6_0.index = 1
		else
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			xyd.WindowManager.get():closeWindow(arg_6_0)

			return
		end
	end

	arg_6_0:nodeByName("graph_pos"):removeAllChildren()

	local var_6_1 = "windows/jigsaw/" .. "big_" .. arg_6_0.ids[arg_6_0.index] .. ".png"
	local var_6_2 = xyd.AssetLoader.get():loadSprite(var_6_1)

	var_6_2:addTo(arg_6_0:nodeByName("graph_pos"))
	var_6_2:setScale(0.5)
	var_6_2:runAction(cc.ScaleTo:create(0.5, 1))

	local var_6_3 = xyd.WindowManager.get():getWindow("jigsaw")

	if var_6_3 then
		var_6_3:createMovePieceByID(arg_6_0.ids[arg_6_0.index])
		var_6_3:updateStableJigsaw()
	end

	arg_6_0:nodeByName("effect_pos"):removeAllChildren()

	local var_6_4 = var_0_3 .. ".json"
	local var_6_5 = var_0_3 .. ".atlas"

	arg_6_0.redEnvelopeEffect = var_0_1.new(var_6_4, var_6_5, 1)

	arg_6_0.redEnvelopeEffect:addTo(arg_6_0:nodeByName("effect_pos"))
	arg_6_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.redEnvelopeEffect:play(nil, true)
	arg_6_0.redEnvelopeEffect:setTouchSwallowEnabled(false)

	local var_6_6 = var_0_4 .. ".json"
	local var_6_7 = var_0_4 .. ".atlas"

	arg_6_0.clickEffect = var_0_1.new(var_6_6, var_6_7, 1)

	arg_6_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.clickEffect:addTo(arg_6_0:nodeByName("effect_pos"))
	arg_6_0.clickEffect:play(nil, false)
	arg_6_0.clickEffect:runAction(cc.ScaleTo:create(0.5, 2))
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayer()
end

return var_0_0
