local var_0_0 = class("OpenChestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 9
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.passedStage = arg_1_2.passedStage
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.marchModel = xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_btn"):setString(var_0_1:translation("OPEN_CHEST_TEXT_1"))

	if arg_3_0.passedStage >= var_0_2 then
		arg_3_0:nodeByName("not_get_state"):setVisible(false)
		arg_3_0:nodeByName("close_state"):setVisible(true)

		local var_3_0 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".json"
		local var_3_1 = "skeletons/ui_effect/effect_baoxiang/baoxiang01" .. ".atlas"
		local var_3_2 = var_0_3.new(var_3_0, var_3_1, 1)

		var_3_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_2:setPosition(arg_3_0:nodeByName("close_state"):getChildByName("effect_pos"):getPosition())
		var_3_2:addTo(arg_3_0:nodeByName("close_state"))
		var_3_2:play(nil, true)
		arg_3_0:nodeByName("open_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
			xyd.buttonScaleAnim(arg_4_0, arg_4_1)

			if arg_4_1 == ccui.TouchEventType.ended then
				if arg_3_0.player.crystal < 50 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_5_0 = {}

						var_5_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_5_0)
					end, nil, nil, arg_3_0.colorMode)
				else
					local var_4_0 = var_0_1:translation("EXTRA_CHEST_TIP6")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_0, function()
						xyd.Backend.get():request(xyd.mid.MARCH_OPEN_EXTRA_CHEST, {}, function(arg_7_0, arg_7_1)
							if arg_7_0 == xyd.error.OK and arg_3_0.contentView_ and not tolua.isnull(arg_3_0.contentView_) then
								if var_3_2 and not tolua.isnull(var_3_2) then
									var_3_2:removeSelf()
								end

								local var_7_0 = "skeletons/ui_effect/effect_baoxiang/baoxiang02" .. ".json"
								local var_7_1 = "skeletons/ui_effect/effect_baoxiang/baoxiang02" .. ".atlas"
								local var_7_2 = var_0_3.new(var_7_0, var_7_1, 1)

								var_7_2:setAnchorPoint(cc.p(0.5, 0.5))
								var_7_2:setPosition(arg_3_0:nodeByName("close_state"):getChildByName("effect_pos"):getPosition())
								var_7_2:addTo(arg_3_0:nodeByName("close_state"))
								var_7_2:play(nil, true)
								arg_3_0:nodeByName("txt_btn"):setString(var_0_1:translation("OPEN_CHEST_TEXT_2"))
								arg_3_0:nodeByName("open_btn"):setBright(false)
								arg_3_0:nodeByName("open_btn"):setTouchEnabled(false)

								arg_3_0.handle = var_0_4.performWithDelayGlobal(function()
									xyd.ModelManager.get():loadModel(xyd.ModelType.MARCH).isGetExtraAward = 1

									local var_8_0 = xyd.WindowManager.get():getWindow("march")

									if var_8_0 and var_8_0.initExtraAward then
										var_8_0:initExtraAward()
									end

									xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_7_1.rewards)
									xyd.WindowManager.get():closeWindow("open_chest_wnd")
								end, 0.5)
							end
						end)
					end, nil, nil, arg_3_0.colorMode)
				end
			end
		end)
	else
		arg_3_0:nodeByName("not_get_state"):setVisible(true)
		arg_3_0:nodeByName("close_state"):setVisible(false)
	end
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
	arg_9_0:addBlockLayer()
end

function var_0_0.didClose(arg_10_0, arg_10_1)
	if arg_10_0.handle then
		var_0_4.unscheduleGlobal(arg_10_0.handle)
	end
end

return var_0_0
