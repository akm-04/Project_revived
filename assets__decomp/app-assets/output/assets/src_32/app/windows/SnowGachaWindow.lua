local var_0_0 = class("SnowGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.snowModel = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.machine = arg_2_0:nodeByName("machine")
	arg_2_0.ball = arg_2_0:nodeByName("ball")
	arg_2_0.gachaBtn = arg_2_0:nodeByName("gacha_btn")
	arg_2_0.bar = arg_2_0:nodeByName("process_bar")
	arg_2_0.barCount = arg_2_0:nodeByName("process_count")
	arg_2_0.coinTxt = xyd.AssetLoader.get():loadLabel(nil, "chargePrice")

	arg_2_0.coinTxt:addTo(arg_2_0:nodeByName("coin_pos"))
	arg_2_0:initBtn()
	arg_2_0:initLayer()
	arg_2_0:initGacha()
	arg_2_0:update()
end

function var_0_0.initBtn(arg_3_0)
	arg_3_0:nodeByName("collection_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("snow_gacha_collection", {})
		end
	end)
	arg_3_0:nodeByName("buy_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("snow_gacha_buy", {})
		end
	end)
end

function var_0_0.initLayer(arg_6_0)
	arg_6_0.block1 = display.newColorLayer(cc.c4b(0, 0, 0, 0))

	arg_6_0.block1:addTo(arg_6_0, 36)
	arg_6_0.block1:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_6_0.block1:setTouchEnabled(true)
	arg_6_0.block1:setTouchSwallowEnabled(true)

	arg_6_0.block = arg_6_0:nodeByName("block")

	arg_6_0:setLayer(false)
	arg_6_0.block1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			arg_6_0:endAction()
		end
	end)
end

function var_0_0.initGacha(arg_8_0)
	local var_8_0 = arg_8_0.ball
	local var_8_1 = arg_8_0.gachaBtn
	local var_8_2 = arg_8_0.machine

	var_8_0:setVisible(false)
	var_8_1:setTouchEnabled(true)
	var_8_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			var_8_1:setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			var_8_1:setScale(1)
			xyd.playButtonSound()

			if arg_8_0.snowModel.baseInfo.coin < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NUMBER_HAS_FINISH")
				})

				return
			end

			arg_8_0.snowModel:gacha({}, function(arg_10_0)
				arg_8_0.snowModel:updateBaseInfo(arg_10_0.base_info)
				arg_8_0.player:handleRewardsWithoutShow(arg_10_0.awards)

				arg_8_0.awards = arg_10_0.awards

				arg_8_0:update()
				arg_8_0:setLayer(true)
				arg_8_0:runPreAction()
			end)
		end
	end)

	local var_8_3 = arg_8_0:nodeByName("extra_click")

	var_8_3:setTouchEnabled(true)
	var_8_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			return true
		elseif arg_11_0.name == "ended" then
			if arg_8_0.snowModel.baseInfo.gacha_count < var_0_2.snowGachaExtraNum then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_1:translation("SNOW_GACHA_EXTRA_TIP"), var_0_2.snowGachaExtraNum)
				})

				return
			end

			arg_8_0:nodeByName("box_top"):setVisible(false)

			if not arg_8_0.effect0 then
				local var_11_0 = "skeletons/ui_effect/snow_gacha_recycle/gacha_box03"

				arg_8_0.effect0 = var_0_3.new(var_11_0 .. ".json", var_11_0 .. ".atlas", 1)

				arg_8_0.effect0:addTo(arg_8_0:nodeByName("deco_container"))
				arg_8_0.effect0:pos(122, 116)
			end

			arg_8_0.effect0:setVisible(true)
			arg_8_0.effect0:play(function()
				if arg_8_0 and not tolua.isnull(arg_8_0) then
					arg_8_0:openBox(effect)
				end
			end, false)
		end
	end)
end

function var_0_0.openBox(arg_13_0, arg_13_1)
	arg_13_0:nodeByName("box_top"):setVisible(true)
	arg_13_0.snowModel:gachaExtra({}, function(arg_14_0)
		arg_13_0.snowModel:updateBaseInfo(arg_14_0.base_info)
		arg_13_0.player:handleRewards(arg_14_0.awards)
		arg_13_0:update()
	end)
	arg_13_0.effect0:setVisible(false)
end

function var_0_0.runPreAction(arg_15_0)
	local var_15_0 = cc.CallFunc:create(function()
		arg_15_0.machine:runAction(cc.Sequence:create({
			cc.ScaleTo:create(0.2, 1.1, 0.9),
			cc.ScaleTo:create(0.3, 0.95, 1.05),
			cc.ScaleTo:create(0.1, 1)
		}))
	end)

	arg_15_0.gachaBtn:runAction(cc.Sequence:create({
		cc.RotateBy:create(0.9, 180),
		var_15_0,
		cc.DelayTime:create(0.6),
		cc.RotateBy:create(0.9, 180),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_15_0:runGachaAction()
				end),
				var_15_0
			})
		})
	}))
end

function var_0_0.runGachaAction(arg_18_0)
	arg_18_0.ball:setVisible(true)
	arg_18_0.ball:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.MoveBy:create(0.66, cc.p(0, -70)),
			cc.RotateBy:create(0.66, 350)
		}),
		cc.DelayTime:create(0.6),
		cc.CallFunc:create(function()
			arg_18_0:endAction()
		end)
	}))
end

function var_0_0.endAction(arg_20_0)
	arg_20_0.gachaBtn:stopAllActions()
	arg_20_0.gachaBtn:rotation(0)
	arg_20_0.machine:stopAllActions()
	arg_20_0.machine:setScale(1)
	arg_20_0.ball:stopAllActions()
	arg_20_0.ball:rotation(0)
	arg_20_0.ball:setPosition(105, 100)
	arg_20_0.ball:setVisible(false)
	arg_20_0:setLayer(false)
	xyd.WindowManager.get():openWindow("snow_gacha_award", {
		awards = arg_20_0.awards
	})
end

function var_0_0.setLayer(arg_21_0, arg_21_1)
	arg_21_0.block:setVisible(arg_21_1)
	arg_21_0.block1:setVisible(arg_21_1)
end

function var_0_0.update(arg_22_0)
	arg_22_0.coinTxt:setString(arg_22_0.snowModel.baseInfo.coin)

	local var_22_0 = arg_22_0.snowModel.baseInfo.gacha_count
	local var_22_1 = var_0_2.snowGachaExtraNum

	arg_22_0.bar:setPercent(var_22_0 / var_22_1 * 100)
	arg_22_0.barCount:setString(var_22_0 .. "/" .. var_22_1)

	if var_22_0 < var_22_1 then
		if arg_22_0.effect1 then
			arg_22_0.effect1:removeSelf()

			arg_22_0.effect1 = nil
		end

		if arg_22_0.effect2 then
			arg_22_0.effect2:removeSelf()

			arg_22_0.effect2 = nil
		end
	else
		if not arg_22_0.effect1 then
			local var_22_2 = "skeletons/ui_effect/snow_gacha_recycle/gacha_box"

			arg_22_0.effect1 = var_0_3.new(var_22_2 .. ".json", var_22_2 .. ".atlas", 1)

			arg_22_0.effect1:addTo(arg_22_0:nodeByName("process_bg"))
			arg_22_0.effect1:pos(2.5, 2.5)
			arg_22_0.effect1:play(nil, true)
		end

		if not arg_22_0.effect2 then
			local var_22_3 = "skeletons/ui_effect/snow_gacha_recycle/gacha_box02"

			arg_22_0.effect2 = var_0_3.new(var_22_3 .. ".json", var_22_3 .. ".atlas", 1)

			arg_22_0.effect2:addTo(arg_22_0:nodeByName("deco_container"))
			arg_22_0.effect2:play(nil, true)
		end
	end
end

function var_0_0.didOpen(arg_23_0, arg_23_1)
	arg_23_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
