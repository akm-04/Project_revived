local var_0_0 = class("ThirdDiglettHammerWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "skeletons/ui_effect/third_anniversary/diglett_hit"
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityDiglettType
local var_0_4 = import("framework.scheduler")
local var_0_5 = 10
local var_0_6 = {
	cc.p(290, 423),
	cc.p(495, 463),
	cc.p(716, 468),
	cc.p(966, 448),
	cc.p(340, 298),
	cc.p(567, 333),
	cc.p(821, 338),
	cc.p(1058, 334),
	cc.p(725, 228)
}
local var_0_7 = {
	Dead = 3,
	On = 2,
	Wait = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.thirdAnniversary = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.btType = arg_1_2.bt_type
	arg_1_0.waveInfos = arg_1_2.wave_infos
	arg_1_0.waveIndex = 1
	arg_1_0.star = 0
	arg_1_0.mine = 0
	arg_1_0.errorCount = 0
	arg_1_0.trueCount = 0

	arg_1_0:formatWaveInfos()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.formatWaveInfos(arg_3_0)
	arg_3_0.waveGroupInfos = {}

	for iter_3_0 = 1, #arg_3_0.waveInfos do
		arg_3_0.waveGroupInfos[iter_3_0] = arg_3_0:formatWaveInfo(arg_3_0.waveInfos[iter_3_0])
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:updateHoles()
	arg_4_0:initHammer()
	arg_4_0:updateStar()
	arg_4_0:updateTime(0)

	local function var_4_0(...)
		arg_4_0:createScheduler()
	end

	local var_4_1 = {}

	var_4_1.is_start = true
	var_4_1.callback = var_4_0

	xyd.WindowManager.get():openWindow("third_diglett_start", var_4_1)
	arg_4_0:nodeByName("close"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0.isPause = true

			arg_4_0:pauseAll(arg_4_0.isPause)
			arg_4_0:nodeByName("close"):setVisible(false)

			local var_6_0 = var_0_2:translation("ACTIVITY_DIGLETT_EXIT")

			local function var_6_1()
				arg_4_0.isPause = false

				arg_4_0:pauseAll(arg_4_0.isPause)
			end

			local var_6_2 = {
				rcallback = rightcallback,
				lcallback = var_6_1
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
				arg_4_0.forceEnd = true
			end, var_6_2, nil, xyd.ColorMode.ACTIVITY)

			return
		end
	end)
end

function var_0_0.createScheduler(arg_9_0)
	local var_9_0 = -var_0_5

	arg_9_0.interValCount = var_0_5

	local var_9_1 = arg_9_0.interValCount

	arg_9_0.handle = var_0_4.scheduleGlobal(function()
		if arg_9_0.forceEnd then
			if arg_9_0.handle then
				var_0_4.unscheduleGlobal(arg_9_0.handle)

				arg_9_0.handle = nil
			end

			arg_9_0:endGame(var_9_0)

			return
		end

		if arg_9_0.isPause then
			return
		end

		var_9_1 = var_9_1 + 1
		var_9_0 = var_9_0 + 1

		arg_9_0:updateTime(var_9_0)
		arg_9_0:updateStar()

		if var_9_1 >= arg_9_0.interValCount * xyd.tables.activityAnniversaryDiglett:moveScale(arg_9_0.waveIndex) then
			local var_10_0 = arg_9_0:getNextGroup(var_9_0)

			if var_9_0 >= 10 * arg_9_0.interValCount * 6 + arg_9_0.interValCount and arg_9_0.btType == 1 or arg_9_0.errorCount >= xyd.tables.misc.activityAnniversaryDiglettLostTimes and arg_9_0.btType == 2 then
				if arg_9_0.handle then
					var_0_4.unscheduleGlobal(arg_9_0.handle)

					arg_9_0.handle = nil
				end

				arg_9_0:endGame(var_9_0)
			elseif var_10_0 and next(var_10_0) then
				var_9_1 = -1

				arg_9_0:playGroup(var_10_0)
			end
		end
	end, 1 / var_0_5)
end

function var_0_0.endGame(arg_11_0, arg_11_1)
	(function(...)
		local var_12_0 = {}

		if arg_11_0.btType == 1 then
			var_12_0.score = arg_11_0.star
		elseif arg_11_0.btType == 2 then
			var_12_0.score = math.max(math.ceil(arg_11_1 / var_0_5), 0)
		end

		arg_11_0.thirdAnniversary:thirdAnniDiglettEnd(var_12_0, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				var_12_0.bt_type = arg_11_0.btType
				var_12_0.score = arg_13_1.score

				xyd.WindowManager.get():openWindow("third_diglett_result", var_12_0)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("NET_WORK_ERROR_TEXT")
				})
				xyd.WindowManager.get():closeWindow(arg_11_0)
			end
		end)
	end)()
end

function var_0_0.updateTime(arg_14_0, arg_14_1)
	if arg_14_1 < 0 then
		arg_14_1 = 0
	end

	local var_14_0 = math.max(0, 60 - math.ceil(arg_14_1 / var_0_5))

	if arg_14_0.btType == 2 then
		var_14_0 = math.ceil(arg_14_1 / var_0_5)
	end

	arg_14_0:nodeByName("txt1"):setString(xyd.secondsToString(var_14_0))
end

function var_0_0.updateStar(arg_15_0, arg_15_1)
	if arg_15_1 then
		arg_15_0.star = arg_15_0.star + var_0_3:point(arg_15_1)
		arg_15_0.star = math.max(0, arg_15_0.star)

		if var_0_3:point(arg_15_1) < 0 then
			arg_15_0.mine = arg_15_0.mine + 1
			arg_15_0.errorCount = arg_15_0.errorCount + 1
		else
			arg_15_0.trueCount = arg_15_0.trueCount + 1
		end
	end

	arg_15_0:nodeByName("txt2"):setString(arg_15_0.errorCount)
	arg_15_0:nodeByName("txt3"):setString(arg_15_0.trueCount)
	arg_15_0:nodeByName("txt4"):setString(arg_15_0.mine)
end

function var_0_0.getNextGroup(arg_16_0)
	if not arg_16_0.groups or not next(arg_16_0.groups) then
		arg_16_0.groups = clone(arg_16_0.waveGroupInfos[arg_16_0.waveIndex]) or {}
		arg_16_0.waveIndex = arg_16_0.waveIndex + 1

		if arg_16_0.btType == 2 then
			arg_16_0.waveIndex = math.min(arg_16_0.waveIndex, 12)
		end
	end

	local var_16_0 = arg_16_0.groups[1]

	table.remove(arg_16_0.groups, 1)

	return var_16_0
end

function var_0_0.pauseAll(arg_17_0, arg_17_1)
	arg_17_0.isPause = arg_17_1

	for iter_17_0, iter_17_1 in pairs(arg_17_0.holeItems) do
		if arg_17_1 then
			iter_17_1.icon:pause()
		else
			iter_17_1.icon:resume()
		end
	end
end

function var_0_0.playGroup(arg_18_0, arg_18_1)
	if not arg_18_0.lastHoles then
		arg_18_0.lastHoles = {}
	end

	local var_18_0 = {}

	for iter_18_0 = 1, #var_0_6 do
		if not xyd.isInTable(arg_18_0.lastHoles, iter_18_0) then
			table.insert(var_18_0, iter_18_0)
		end
	end

	local var_18_1 = xyd.shuffle(var_18_0)

	arg_18_0.lastHoles = {}

	for iter_18_1 = 1, #arg_18_1 do
		table.insert(arg_18_0.lastHoles, var_18_1[iter_18_1])
	end

	local var_18_2 = xyd.tables.activityAnniversaryDiglett:moveScale(arg_18_0.waveIndex)

	for iter_18_2 = 1, #arg_18_1 do
		local var_18_3 = 0.2
		local var_18_4 = 166
		local var_18_5 = arg_18_1[iter_18_2]
		local var_18_6 = arg_18_0.holeItems[arg_18_0.lastHoles[iter_18_2]]

		var_18_6.icon:setOpacity(255)

		var_18_6.id = var_18_5

		arg_18_0:changeState(var_18_6, var_18_5, 2)
		var_18_6.icon:runActionOnce(cc.Sequence:create({
			cc.MoveTo:create(var_0_3:upTime(var_18_5) * var_18_2 * var_18_3, cc.p(0, var_18_4 * var_18_3)),
			cc.CallFunc:create(function()
				var_18_6.touchArena:setVisible(true)
			end),
			cc.MoveTo:create(var_0_3:upTime(var_18_5) * var_18_2 * (1 - var_18_3), cc.p(0, var_18_4)),
			cc.CallFunc:create(function()
				arg_18_0:changeState(var_18_6, var_18_5, 1)
			end),
			cc.DelayTime:create(var_0_3:stayTime(var_18_5) * var_18_2),
			cc.MoveTo:create(var_0_3:downTime(var_18_5) * var_18_2 * (1 - var_18_3), cc.p(0, var_18_4 * var_18_3)),
			cc.CallFunc:create(function()
				var_18_6.touchArena:setVisible(false)
			end),
			cc.MoveTo:create(var_0_3:downTime(var_18_5) * var_18_2 * var_18_3, cc.p(0, 0)),
			cc.FadeOut:create(0),
			cc.CallFunc:create(function()
				if var_0_3:point(var_18_5) > 0 then
					arg_18_0.errorCount = arg_18_0.errorCount + 1
				end
			end)
		}))
	end
end

function var_0_0.checkEnd(arg_23_0)
	if arg_23_0.errorCount >= 5 then
		arg_23_0:endGame()
	end
end

function var_0_0.formatWaveInfo(arg_24_0, arg_24_1)
	if not arg_24_1 then
		return {}
	end

	local var_24_0 = {}

	for iter_24_0 = 1, 3 do
		local var_24_1 = arg_24_1.dgt_nums[iter_24_0]

		for iter_24_1 = 1, var_24_1 do
			table.insert(var_24_0, iter_24_0)
		end
	end

	local var_24_2 = xyd.shuffle(var_24_0)
	local var_24_3 = {}

	for iter_24_2 = 1, arg_24_1.single_time do
		local var_24_4 = {}

		table.insert(var_24_4, var_24_2[1])
		table.remove(var_24_2, 1)
		table.insert(var_24_3, var_24_4)
	end

	for iter_24_3 = 1, arg_24_1.double_time do
		local var_24_5 = {}

		for iter_24_4 = 1, 2 do
			table.insert(var_24_5, var_24_2[1])
			table.remove(var_24_2, 1)
		end

		table.insert(var_24_3, var_24_5)
	end

	for iter_24_5 = 1, arg_24_1.triple_time do
		local var_24_6 = {}

		for iter_24_6 = 1, 3 do
			table.insert(var_24_6, var_24_2[1])
			table.remove(var_24_2, 1)
		end

		table.insert(var_24_3, var_24_6)
	end

	return (xyd.shuffle(var_24_3))
end

function var_0_0.updateHoles(arg_25_0)
	arg_25_0.holeItems = {}

	arg_25_0:nodeByName("hole_pos"):removeAllChildren(true)

	for iter_25_0, iter_25_1 in pairs(var_0_6) do
		local var_25_0 = arg_25_0:getHole(iter_25_0)

		var_25_0:addTo(arg_25_0:nodeByName("hole_pos"))
		var_25_0:setPosition(xyd.addPosition(iter_25_1, cc.p(-120, -50)))
		arg_25_0:changeState(var_25_0, 1, 2)
		table.insert(arg_25_0.holeItems, var_25_0)
	end
end

function var_0_0.changeState(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0

	if arg_26_3 == 1 then
		var_26_0 = var_0_3:icon1(arg_26_2)
	elseif arg_26_3 == 2 then
		var_26_0 = var_0_3:icon2(arg_26_2)
	elseif arg_26_3 == 3 then
		var_26_0 = var_0_3:icon3(arg_26_2)
	end

	local var_26_1 = xyd.AssetLoader:get():loadSprite(var_26_0)

	arg_26_1.icon:setSpriteFrame(var_26_1:getSpriteFrame())
end

function var_0_0.initHammer(arg_27_0)
	arg_27_0.hammers = {}

	for iter_27_0 = 1, #var_0_6 do
		local var_27_0 = xyd.AssetLoader:get():loadSprite("windows/anniversary3rd_diglett/hammer/hammer.png")

		var_27_0:addTo(arg_27_0:nodeByName("container"))
		var_27_0:setLocalZOrder(1000)
		var_27_0:setOpacity(0)
		table.insert(arg_27_0.hammers, var_27_0)
	end
end

function var_0_0.getHole(arg_28_0, arg_28_1)
	local var_28_0 = 1
	local var_28_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd_diglett/hammer/item.csb")
	local var_28_2 = var_28_1:getChildByName("container")
	local var_28_3 = xyd.AssetLoader:get():loadSprite("windows/anniversary3rd_diglett/hammer/cover.png")
	local var_28_4 = xyd.AssetLoader:get():loadSprite("windows/anniversary3rd_diglett/hammer/five_1.png")
	local var_28_5 = cc.ClippingNode:create()

	var_28_5:setStencil(var_28_3)
	var_28_5:setInverted(true)
	var_28_5:setAlphaThreshold(0)
	var_28_5:addChild(var_28_4)
	var_28_5:addTo(var_28_2)
	var_28_5:setPosition(cc.p(86.5, -68.5))
	var_28_4:setPositionY(0)

	local var_28_6 = var_28_2:getChildByName("touch_btn")

	var_28_6:retain()
	var_28_6:removeFromParent()
	var_28_6:setAnchorPoint(cc.p(0.5, 0))
	var_28_6:addTo(var_28_4)
	var_28_6:setPosition(cc.p(94.5, 30))
	var_28_6:addTouchEventListener(function(arg_29_0, arg_29_1)
		if arg_29_1 == ccui.TouchEventType.began and not arg_28_0.isPause and var_28_6:isVisible() then
			var_28_6:setVisible(false)

			local var_29_0 = xyd.tables.activityAnniversaryDiglett:moveScale(arg_28_0.waveIndex)

			transition.stopTarget(var_28_4)
			arg_28_0.hammers[arg_28_1]:setRotation(0)
			arg_28_0.hammers[arg_28_1]:setAnchorPoint(cc.p(0.5, 0))
			arg_28_0.hammers[arg_28_1]:setPosition(xyd.addPosition(cc.p(var_28_1:getPosition()), cc.p(200, 150)))
			arg_28_0.hammers[arg_28_1]:setOpacity(255)
			arg_28_0.hammers[arg_28_1]:runAction(cc.Sequence:create({
				cc.Spawn:create({
					cc.RotateBy:create(0.2 * var_29_0, -90)
				}),
				cc.CallFunc:create(function()
					arg_28_0:changeState(var_28_1, var_28_1.id, 3)
					var_28_4:runAction(cc.Sequence:create({
						cc.MoveTo:create(var_0_3:downTime(var_28_0) * var_29_0, cc.p(0, 0)),
						cc.FadeOut:create(0)
					}))

					if arg_28_0.isPause then
						var_28_4:pause()
					end
				end),
				cc.FadeOut:create(0)
			}))

			local var_29_1 = xyd.tables.sound:getSound("diglett_attack")

			audio.playSound(var_29_1, false)
			arg_28_0:updateStar(var_28_1.id)
			var_28_1.effect:play(nil, false)

			local var_29_2 = var_0_3:point(var_28_1.id)
			local var_29_3 = xyd.createLabel(36, cc.c3b(253, 255, 0))

			var_29_3:setAnchorPoint(cc.p(0.5, 0.5))

			if var_29_2 > 0 then
				var_29_3:setString("+" .. var_29_2)
			else
				var_29_3:setString(var_29_2)
				var_29_3:setColor(xyd.color.RED)
			end

			var_29_3:addTo(var_28_2)

			local var_29_4 = var_28_2:getContentSize()

			var_29_3:setPosition(cc.p(var_29_4.width / 2, var_29_4.height - 50))
			var_29_3:enableShadow()

			local var_29_5 = 2
			local var_29_6 = 0.5
			local var_29_7 = cc.Spawn:create({
				cc.MoveBy:create(var_29_5, cc.p(0, 200)),
				cc.Sequence:create({
					cc.DelayTime:create(var_29_6),
					cc.FadeOut:create(var_29_5 - var_29_6)
				})
			})

			var_29_3:runActionOnce(var_29_7, true, nil)
		end
	end)

	var_28_1.touchArena = var_28_6
	var_28_1.id = var_28_0
	var_28_1.icon = var_28_4

	local var_28_7 = xyd.createEffect(var_0_1)

	var_28_7:addTo(var_28_4)

	local var_28_8 = var_28_4:getContentSize()

	var_28_7:setPosition(var_28_8.width / 2, var_28_8.height - 10)

	var_28_1.effect = var_28_7
	var_28_1.view = view

	return var_28_1
end

function var_0_0.willClose(arg_31_0, arg_31_1)
	var_0_0.super:willClose(arg_31_1)

	if arg_31_0.handle then
		var_0_4.unscheduleGlobal(arg_31_0.handle)

		arg_31_0.handle = nil
	end
end

return var_0_0
