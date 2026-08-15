local var_0_0 = class("GrabKiteResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = "skeletons/ui_effect/effect_redpacket/effect_redpacket1"
local var_0_4 = "skeletons/ui_effect/effect_redpacket/effect_redpacket2"
local var_0_5 = "skeletons/ui_effect/effect_redpacket/effect_redpacket3"
local var_0_6 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.crystal = arg_1_2.crystal
	arg_1_0.failed = arg_1_2.failed
	arg_1_0.kiteMsg = arg_1_2.kite
	arg_1_0.kite = xyd.ModelManager.get():loadModel(xyd.ModelType.KITE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:setAllKiteinvisible()
	arg_2_0:nodeByName("close_kite_type" .. arg_2_0.kiteMsg.id):setVisible(true)
	arg_2_0:nodeByName("go_to_send_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)

	if arg_2_0.failed then
		arg_2_0:playFailed()
	else
		arg_2_0:playSuccess()
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	arg_4_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.playSuccess(arg_5_0)
	arg_5_0:nodeByName("failed_node"):setVisible(false)

	local var_5_0 = var_0_4 .. ".json"
	local var_5_1 = var_0_4 .. ".atlas"

	arg_5_0.crystalEffect = var_0_2.new(var_5_0, var_5_1, 1)

	arg_5_0.crystalEffect:addTo(arg_5_0:nodeByName("success_node"))
	arg_5_0.crystalEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.crystalEffect:setPosition(arg_5_0:nodeByName("crystal_reward"):getPosition())
	arg_5_0.crystalEffect:setLocalZOrder(49)
	arg_5_0.crystalEffect:play(nil, true)
	arg_5_0:nodeByName("crystal_reward"):setLocalZOrder(50)

	local var_5_2 = var_0_5 .. ".json"
	local var_5_3 = var_0_5 .. ".atlas"

	arg_5_0.clickEffect = var_0_2.new(var_5_2, var_5_3, 1)

	arg_5_0.clickEffect:addTo(arg_5_0:nodeByName("success_node"))
	arg_5_0.clickEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.clickEffect:setPosition(arg_5_0:nodeByName("crystal_reward"):getPosition())
	arg_5_0:nodeByName("celerbrate_txt"):setString(var_0_1:translation("HAVE_GRAB_CRYSTAL"))
	arg_5_0:nodeByName("reward_num"):setString(arg_5_0.crystal)
	arg_5_0:nodeByName("reward_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_5_0:nodeByName("click_kite_tip"):setVisible(true)
	arg_5_0:nodeByName("click_kite_tip"):setString(var_0_1:translation("CLICK_KITE_TIP"))
	arg_5_0:nodeByName("success_node"):setVisible(false)
	arg_5_0:nodeByName("failed_node"):setVisible(false)
	arg_5_0:nodeByName("check_btn"):setVisible(false)
	arg_5_0:nodeByName("go_to_send_btn"):setVisible(false)

	local var_5_4 = var_0_3 .. ".json"
	local var_5_5 = var_0_3 .. ".atlas"

	arg_5_0.redEnvelopeEffect = var_0_2.new(var_5_4, var_5_5, 1)

	arg_5_0.redEnvelopeEffect:addTo(arg_5_0:nodeByName("close_kite_type" .. arg_5_0.kiteMsg.id):getParent())
	arg_5_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.redEnvelopeEffect:setPosition(arg_5_0:nodeByName("kite_pos"):getPosition())
	arg_5_0.redEnvelopeEffect:setLocalZOrder(60)
	arg_5_0.redEnvelopeEffect:play(nil, true)
	arg_5_0:nodeByName("close_kite_type" .. arg_5_0.kiteMsg.id):setTouchEnabled(true)
	arg_5_0:nodeByName("close_kite_type" .. arg_5_0.kiteMsg.id):setLocalZOrder(70)
	arg_5_0:nodeByName("close_kite_type" .. arg_5_0.kiteMsg.id):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "ended" then
			arg_5_0:playAward()
		end
	end)
	arg_5_0:nodeByName("check_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				packet_id = arg_5_0.kiteMsg.packet_id
			}

			arg_5_0.kite:loadGrabRecord(var_7_0, function(arg_8_0, arg_8_1)
				local var_8_0 = arg_8_1.log_list
				local var_8_1 = {
					players = var_8_0,
					id = arg_5_0.kiteMsg.id
				}

				xyd.WindowManager.get():openWindow("kite_record", var_8_1)
			end)
		end
	end)
end

function var_0_0.playFailed(arg_9_0)
	arg_9_0:nodeByName("success_node"):setVisible(false)
	arg_9_0:nodeByName("failed_node"):setVisible(true)
	arg_9_0:nodeByName("close_kite_type" .. arg_9_0.kiteMsg.id):setVisible(false)
	arg_9_0:nodeByName("click_kite_tip"):setVisible(false)

	local var_9_0 = arg_9_0:nodeByName("black_line")

	var_9_0:setScaleY(0.5)

	local var_9_1 = cc.ScaleTo:create(1, 1, 1)

	var_9_0:runAction(var_9_1)
	arg_9_0:nodeByName("failed_txt"):setString(var_0_1:translation("GRAB_KITE_FAILED_TXT"))
	arg_9_0:nodeByName("check_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = {
				packet_id = arg_9_0.kiteMsg.packet_id
			}

			arg_9_0.kite:loadGrabRecord(var_10_0, function(arg_11_0, arg_11_1)
				local var_11_0 = arg_11_1.log_list
				local var_11_1 = {
					players = var_11_0,
					id = arg_9_0.kiteMsg.id
				}

				xyd.WindowManager.get():openWindow("kite_record", var_11_1)
			end)
		end
	end)
end

function var_0_0.setAllKiteinvisible(arg_12_0)
	for iter_12_0 = 1, var_0_6 do
		arg_12_0:nodeByName("open_kite_type" .. iter_12_0):setVisible(false)
		arg_12_0:nodeByName("close_kite_type" .. iter_12_0):setVisible(false)
	end
end

function var_0_0.setCrystal(arg_13_0, arg_13_1)
	arg_13_0.crystal = arg_13_1
end

function var_0_0.playAward(arg_14_0)
	arg_14_0:nodeByName("reward_num"):setString(arg_14_0.crystal)
	arg_14_0:nodeByName("reward_num"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_14_0 = cc.FadeOut:create(0.1)

	if arg_14_0.redEnvelopeEffect and not tolua.isnull(arg_14_0.redEnvelopeEffect) then
		arg_14_0.redEnvelopeEffect:runAction(var_14_0)
	end

	local var_14_1 = cc.ScaleTo:create(0.3, 0)
	local var_14_2 = cc.FadeOut:create(0.3)
	local var_14_3 = cc.FadeOut:create(0.15)
	local var_14_4 = cc.CallFunc:create(function()
		arg_14_0:nodeByName("success_node"):setVisible(true)
		arg_14_0:nodeByName("success_node"):setScale(0)

		local var_15_0 = cc.ScaleTo:create(0.15, 1)
		local var_15_1 = cc.CallFunc:create(function()
			arg_14_0.clickEffect:play(nil, false)
		end)

		arg_14_0:nodeByName("success_node"):runActionOnce(cc.Sequence:create(var_15_0, var_15_1), false, function()
			arg_14_0:nodeByName("check_btn"):setVisible(true)
			arg_14_0:nodeByName("go_to_send_btn"):setVisible(true)
		end)
	end)

	arg_14_0:nodeByName("click_kite_tip"):runAction(var_14_3)
	arg_14_0:nodeByName("close_kite_type" .. arg_14_0.kiteMsg.id):runAction(cc.Sequence:create({
		cc.Spawn:create({
			var_14_1,
			var_14_2
		}),
		var_14_4
	}))
end

return var_0_0
