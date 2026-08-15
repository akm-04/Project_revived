local var_0_0 = class("ChapterGachaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "skeletons/ui_effect/chapter_event/guide_large_egg"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.chapter = arg_1_2.chapter
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.machine = arg_2_0:nodeByName("machine")
	arg_2_0.ball = arg_2_0:nodeByName("gacha_ball")
	arg_2_0.gachaBtn = arg_2_0:nodeByName("gacha_btn")

	arg_2_0:initGacha()
	arg_2_0:initBtn()
	arg_2_0:update()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0:initLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("close_block"):setTouchEnabled(true)
	arg_4_0:nodeByName("close_block"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0.machine:setTouchEnabled(true)
	arg_4_0.machine:setTouchSwallowEnabled(true)
	arg_4_0:nodeByName("machine_bg"):setTouchEnabled(true)
	arg_4_0:nodeByName("machine_bg"):setTouchSwallowEnabled(true)
	arg_4_0:nodeByName("collection_btn"):setTouchEnabled(true)
	arg_4_0:nodeByName("collection_btn"):setTouchSwallowEnabled(true)

	local var_4_0 = xyd.createEffect(var_0_2)

	var_4_0:addTo(arg_4_0, 50)
	var_4_0:setPosition(cc.p(600, 65))
	arg_4_0:nodeByName("container"):setVisible(false)
	var_4_0:play(function(...)
		arg_4_0:nodeByName("container"):setVisible(true)
		var_4_0:setVisible(false)
	end, false)
end

function var_0_0.initLayer(arg_7_0)
	arg_7_0.blockLayer_:setTouchEnabled(true)
	arg_7_0.blockLayer_:setTouchSwallowEnabled(true)

	arg_7_0.block = arg_7_0:nodeByName("block")

	arg_7_0:setLayer(false)
	arg_7_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			arg_7_0:endAction()
		end
	end)
end

function var_0_0.initGacha(arg_9_0)
	local var_9_0 = arg_9_0.ball
	local var_9_1 = arg_9_0.gachaBtn
	local var_9_2 = arg_9_0.machine

	var_9_0:setVisible(false)
	var_9_1:setTouchEnabled(true)
	var_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			var_9_1:setScale(0.9)

			return true
		elseif arg_10_0.name == "ended" then
			var_9_1:setScale(1)

			if arg_9_0.selfPlayer.chapterEvents[arg_9_0.chapter].left_times <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("CHAPTER_NO_GACHA_CHANCE_TIP")
				})

				return
			end

			arg_9_0.showCharge = 1

			xyd.Backend.get():request(xyd.mid.GET_CHAPTER_GACHA_AWARD, {
				chapter_id = arg_9_0.chapter
			}, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					arg_9_0.selfPlayer:handleRewardsWithoutShow(arg_11_1.awards)

					arg_9_0.award = arg_11_1.awards[1]

					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleChapterEvent(arg_11_1)

					local var_11_0 = xyd.WindowManager.get():getWindow("map_window")

					if var_11_0 then
						var_11_0:updateChapter()
					end

					arg_9_0:update()
					arg_9_0:setLayer(true)
					arg_9_0:runPreAction()
				end
			end)
		end
	end)
end

function var_0_0.runPreAction(arg_12_0)
	local var_12_0 = cc.CallFunc:create(function()
		arg_12_0.machine:runAction(cc.Sequence:create({
			cc.ScaleTo:create(0.2, 1.1, 0.9),
			cc.ScaleTo:create(0.3, 0.95, 1.05),
			cc.ScaleTo:create(0.1, 1)
		}))
	end)

	arg_12_0.gachaBtn:runAction(cc.Sequence:create({
		cc.RotateBy:create(0.9, 180),
		var_12_0,
		cc.DelayTime:create(0.6),
		cc.RotateBy:create(0.9, 180),
		cc.Spawn:create({
			cc.Sequence:create({
				cc.DelayTime:create(0.2),
				cc.CallFunc:create(function()
					arg_12_0:runGachaAction()
				end),
				var_12_0
			})
		})
	}))
end

function var_0_0.runGachaAction(arg_15_0)
	arg_15_0.ball:setVisible(true)
	arg_15_0.ball:runAction(cc.Sequence:create({
		cc.Spawn:create({
			cc.MoveBy:create(0.66, cc.p(0, -99)),
			cc.RotateBy:create(0.66, 330)
		}),
		cc.DelayTime:create(0.6),
		cc.CallFunc:create(function()
			arg_15_0:endAction()
		end)
	}))
end

function var_0_0.endAction(arg_17_0)
	arg_17_0.gachaBtn:stopAllActions()
	arg_17_0.gachaBtn:rotation(0)
	arg_17_0.machine:stopAllActions()
	arg_17_0.machine:setScale(1)
	arg_17_0.ball:stopAllActions()
	arg_17_0.ball:setPosition(128, 131)
	arg_17_0.ball:rotation(0)
	arg_17_0.ball:setVisible(false)
	arg_17_0:setLayer(false)
	xyd.WindowManager.get():openWindow("chapter_gacha_award", arg_17_0.award)

	arg_17_0.award = nil
end

function var_0_0.initBtn(arg_18_0)
	local var_18_0 = arg_18_0:nodeByName("click_node")

	var_18_0:setTouchEnabled(true)
	var_18_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			return true
		elseif arg_19_0.name == "ended" then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("chapter_gacha_collection", {
				chapter = arg_18_0.chapter
			})
		end
	end)
end

function var_0_0.setLayer(arg_20_0, arg_20_1)
	arg_20_0.block:setVisible(arg_20_1)
	arg_20_0.blockLayer_:setTouchEnabled(arg_20_1)
	arg_20_0.blockLayer_:setTouchSwallowEnabled(arg_20_1)
end

function var_0_0.update(arg_21_0)
	local var_21_0 = arg_21_0.selfPlayer.chapterEvents[arg_21_0.chapter]

	arg_21_0:nodeByName("left_times_pos"):removeAllChildren(true)

	local var_21_1 = xyd.AssetLoader.get():loadLabel(nil, "battle_float_yellow")

	var_21_1:setString(var_21_0.left_times)
	var_21_1:setAnchorPoint(cc.p(0, 0.5))
	var_21_1:addTo(arg_21_0:nodeByName("left_times_pos"))
end

function var_0_0.willClose(arg_22_0)
	if arg_22_0.chapter and arg_22_0.chapter > 1 then
		return
	end

	if not arg_22_0.showCharge then
		return
	end

	if arg_22_0.selfPlayer.charge > 0 then
		return
	end

	local var_22_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)

	var_22_0:loadSingleActivity({
		activity_id = xyd.Activities.FirstStoreAward
	}, function(arg_23_0, arg_23_1)
		if arg_23_1.details and arg_23_1.is_open == 1 then
			var_22_0:loadSingleActivity({
				activity_id = xyd.Activities.FirstRecharge
			}, function(arg_24_0, arg_24_1)
				arg_23_1.hasUnlimitGift = arg_24_1.details.is_awarded
				arg_23_1.UnlimitTableId = arg_24_1.table_id

				if arg_23_1.details.is_awarded == 0 or arg_23_1.hasUnlimitGift == 0 then
					xyd.WindowManager.get():openWindow("firststore_new", arg_23_1)
				else
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
				end
			end)
		else
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
		end
	end)
end

return var_0_0
