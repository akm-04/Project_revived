local var_0_0 = class("GrabResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = "skeletons/ui_effect/effect_redpacket/effect_redpacket1"
local var_0_4 = "skeletons/ui_effect/effect_redpacket/effect_redpacket2"
local var_0_5 = "skeletons/ui_effect/effect_redpacket/effect_redpacket3"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.crystal = arg_1_2.crystal
	arg_1_0.awards = arg_1_2.awards
	arg_1_0.packetID = arg_1_2.packetID
	arg_1_0.container = arg_1_2.container
	arg_1_0.id = arg_1_2.id
	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.crystal then
		arg_4_0:playSuccess()
	else
		arg_4_0:playFailed()
	end
end

function var_0_0.willClose(arg_5_0, arg_5_1)
	var_0_0.super:willClose(arg_5_1)
end

function var_0_0.playSuccess(arg_6_0)
	if arg_6_0.container then
		arg_6_0.container:getChildByName("open_state"):setVisible(true)
		arg_6_0.container:getChildByName("close_state"):setVisible(false)

		local var_6_0 = arg_6_0.container:getChildByName("desc_label")

		var_6_0:setString(var_0_1:translation("CHECK_ENVELOPE"))
		var_6_0:setColor(cc.c3b(241, 235, 7))
	end

	arg_6_0:nodeByName("failed_node"):setVisible(false)

	local var_6_1 = var_0_4 .. ".json"
	local var_6_2 = var_0_4 .. ".atlas"

	arg_6_0.crystalEffect = var_0_2.new(var_6_1, var_6_2, 1)

	arg_6_0.crystalEffect:addTo(arg_6_0:nodeByName("success_node"))
	arg_6_0.crystalEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.crystalEffect:setPosition(arg_6_0:nodeByName("crystal_reward"):getPosition())
	arg_6_0.crystalEffect:setLocalZOrder(49)
	arg_6_0.crystalEffect:play(nil, true)
	arg_6_0:nodeByName("crystal_reward"):setLocalZOrder(50)

	local var_6_3 = var_0_5 .. ".json"
	local var_6_4 = var_0_5 .. ".atlas"

	arg_6_0.clickEffect = var_0_2.new(var_6_3, var_6_4, 1)

	arg_6_0.clickEffect:addTo(arg_6_0:nodeByName("success_node"))
	arg_6_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.clickEffect:setPosition(arg_6_0:nodeByName("crystal_reward"):getPosition())
	arg_6_0:nodeByName("celerbrate_txt"):setString(var_0_1:translation("HAVE_GRAB_CRYSTAL"))
	arg_6_0:nodeByName("reward_num"):setString(arg_6_0.crystal)
	arg_6_0:nodeByName("reward_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_6_0:nodeByName("click_envelope_tip"):setVisible(true)
	arg_6_0:nodeByName("click_envelope_tip"):setString(var_0_1:translation("CLICK_ENVELOPE_TIP"))
	arg_6_0:nodeByName("success_node"):setVisible(false)
	arg_6_0:nodeByName("failed_node"):setVisible(false)
	arg_6_0:nodeByName("check_btn"):setVisible(false)
	arg_6_0:nodeByName("close"):setVisible(false)

	local var_6_5 = var_0_3 .. ".json"
	local var_6_6 = var_0_3 .. ".atlas"

	arg_6_0.redEnvelopeEffect = var_0_2.new(var_6_5, var_6_6, 1)

	arg_6_0.redEnvelopeEffect:addTo(arg_6_0:nodeByName("red_large"):getParent())
	arg_6_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.redEnvelopeEffect:setPosition(arg_6_0:nodeByName("envelope_pos"):getPosition())
	arg_6_0.redEnvelopeEffect:setLocalZOrder(60)
	arg_6_0.redEnvelopeEffect:play(nil, true)
	arg_6_0:nodeByName("red_large"):setTouchEnabled(true)
	arg_6_0:nodeByName("red_large"):setLocalZOrder(70)
	arg_6_0:nodeByName("red_large"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			local var_7_0 = cc.FadeOut:create(0.1)

			arg_6_0.redEnvelopeEffect:runAction(var_7_0)

			local var_7_1 = cc.ScaleTo:create(0.3, 0)
			local var_7_2 = cc.FadeOut:create(0.3)
			local var_7_3 = cc.FadeOut:create(0.15)
			local var_7_4 = cc.CallFunc:create(function()
				arg_6_0:nodeByName("success_node"):setVisible(true)
				arg_6_0:nodeByName("success_node"):setScale(0)

				local var_8_0 = cc.ScaleTo:create(0.15, 1)
				local var_8_1 = cc.CallFunc:create(function()
					arg_6_0.clickEffect:play(nil, false)
				end)

				arg_6_0:nodeByName("success_node"):runActionOnce(cc.Sequence:create(var_8_0, var_8_1), false, function()
					arg_6_0:nodeByName("check_btn"):setVisible(true)
					arg_6_0:nodeByName("close"):setVisible(true)
					arg_6_0.selfPlayer:handleRewards(arg_6_0.awards)
				end)
			end)

			arg_6_0:nodeByName("click_envelope_tip"):runAction(var_7_3)
			arg_6_0:nodeByName("red_large"):runAction(cc.Sequence:create({
				cc.Spawn:create({
					var_7_1,
					var_7_2
				}),
				var_7_4
			}))
		end
	end)
	arg_6_0:nodeByName("check_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			local var_11_0 = {
				packet_id = arg_6_0.packetID
			}

			arg_6_0.redEnvelope:loadEnvelopRecord(var_11_0, function(arg_12_0, arg_12_1)
				local var_12_0 = arg_12_1.log_list
				local var_12_1 = {
					players = var_12_0,
					id = arg_6_0.id,
					num = arg_12_1.num
				}

				xyd.WindowManager.get():openWindow("envelope_record", var_12_1)
			end)
		end
	end)
end

function var_0_0.playFailed(arg_13_0)
	if arg_13_0.container then
		arg_13_0.container:getChildByName("open_state"):setVisible(false)
		arg_13_0.container:getChildByName("close_state"):setVisible(true)

		local var_13_0 = arg_13_0.container:getChildByName("desc_label")

		var_13_0:setString(var_0_1:translation("CHECK_ENVELOPE"))
		var_13_0:setColor(cc.c3b(241, 235, 7))
	end

	arg_13_0:nodeByName("success_node"):setVisible(false)
	arg_13_0:nodeByName("red_large"):setVisible(false)
	arg_13_0:nodeByName("click_envelope_tip"):setVisible(false)

	local var_13_1 = arg_13_0:nodeByName("black_line")

	var_13_1:setScaleY(0.5)

	local var_13_2 = cc.ScaleTo:create(1, 1, 1)

	var_13_1:runAction(var_13_2)
	arg_13_0:nodeByName("failed_txt"):setString(var_0_1:translation("GRAB_FAILED_TXT"))
	arg_13_0:nodeByName("check_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = {
				packet_id = arg_13_0.packetID
			}

			arg_13_0.redEnvelope:loadEnvelopRecord(var_14_0, function(arg_15_0, arg_15_1)
				local var_15_0 = arg_15_1.log_list
				local var_15_1 = {
					players = var_15_0,
					id = arg_13_0.id,
					num = arg_15_1.num
				}

				xyd.WindowManager.get():openWindow("envelope_record", var_15_1)
			end)
		end
	end)
end

return var_0_0
