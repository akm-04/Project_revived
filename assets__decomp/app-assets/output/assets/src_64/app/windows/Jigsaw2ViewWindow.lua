local var_0_0 = class("Jigsaw2ViewWindow", import("app.common.ui.BaseWindow"))
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

function var_0_0.updateToNextPiece(arg_5_0)
	arg_5_0.index = arg_5_0.index + 1

	if arg_5_0.index > #arg_5_0.ids then
		if arg_5_0.selfPlayer.newJig2Ids and next(arg_5_0.selfPlayer.newJig2Ids) then
			arg_5_0.ids = clone(arg_5_0.selfPlayer.newJig2Ids)
			arg_5_0.selfPlayer.newJig2Ids = {}
			arg_5_0.index = 1
		else
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0)

			return
		end
	end

	arg_5_0:nodeByName("graph_pos"):removeAllChildren()

	local var_5_1 = "windows/jigsaw2/" .. "big_" .. arg_5_0.ids[arg_5_0.index] .. ".png"

	sprite = xyd.AssetLoader.get():loadSprite(var_5_1)

	sprite:addTo(arg_5_0:nodeByName("graph_pos"))
	sprite:setScale(0.5)
	sprite:runAction(cc.ScaleTo:create(0.5, 1))

	local var_5_2 = xyd.WindowManager.get():getWindow("jigsaw2")

	if var_5_2 then
		var_5_2:createMovePieceByID(arg_5_0.ids[arg_5_0.index])
		var_5_2:updateStableJigsaw()
	end

	arg_5_0:nodeByName("effect_pos"):removeAllChildren()

	local var_5_3 = var_0_3 .. ".json"
	local var_5_4 = var_0_3 .. ".atlas"

	arg_5_0.redEnvelopeEffect = var_0_1.new(var_5_3, var_5_4, 1)

	arg_5_0.redEnvelopeEffect:addTo(arg_5_0:nodeByName("effect_pos"))
	arg_5_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.redEnvelopeEffect:play(nil, true)
	arg_5_0.redEnvelopeEffect:setTouchSwallowEnabled(false)

	local var_5_5 = var_0_4 .. ".json"
	local var_5_6 = var_0_4 .. ".atlas"

	arg_5_0.clickEffect = var_0_1.new(var_5_5, var_5_6, 1)

	arg_5_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.clickEffect:addTo(arg_5_0:nodeByName("effect_pos"))
	arg_5_0.clickEffect:play(nil, false)
	arg_5_0.clickEffect:runAction(cc.ScaleTo:create(0.5, 2))
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
