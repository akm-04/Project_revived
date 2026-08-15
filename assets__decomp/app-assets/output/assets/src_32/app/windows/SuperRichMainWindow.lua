local var_0_0 = class("SuperRichMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityRichMap
local var_0_3 = xyd.tables.activityRichEvent
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("framework.scheduler")
local var_0_6 = 32
local var_0_7 = {}

for iter_0_0 = 1, 6 do
	table.insert(var_0_7, "skeletons/ui_effect/super_rich/activity_rich_dice0" .. iter_0_0)
end

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.baseInfo = arg_1_0.superRich.baseInfo
	arg_1_0.gridInfo = arg_1_0.superRich.gridInfo
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.isFirst = true
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_SUPER_RICH_INFO, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateAsset()
			arg_2_0:updateEnterShow()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.ECONOMY, handler(arg_2_0, arg_2_0.updateAsset))

	if not arg_2_0.superRich.hasShowTip then
		arg_2_0.superRich.hasShowTip = true

		xyd.WindowManager.get():openWindow("pic_tip", {
			path = "windows/zillionaire/tip.png"
		})
	end
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.isFirst then
		-- block empty
	end

	arg_4_0:setButtonClick()
	arg_4_0:initStationItem(true)
	arg_4_0:initEffect()
	arg_4_0:updateHeroModel()
	arg_4_0:updateAsset()
	arg_4_0:nodeByName("mana_txt"):enableOutline(xyd.color.GRAY, 2)
	arg_4_0:nodeByName("crystal_txt"):enableOutline(xyd.color.GRAY, 2)
	arg_4_0:nodeByName("number_txt2"):enableOutline(cc.c4b(198, 127, 30, 255), 2)
	arg_4_0:nodeByName("number_txt1"):enableOutline(cc.c4b(198, 127, 30, 255), 2)
	arg_4_0:handleEvent()
end

function var_0_0.updateAsset(arg_5_0)
	local var_5_0 = arg_5_0.backpack:getItemNumByID(xyd.tables.misc.activityRichDiceItem)

	arg_5_0:nodeByName("number_txt2"):setString(var_5_0)
	arg_5_0:nodeByName("number_txt1"):setString(arg_5_0.baseInfo.stamps)
	arg_5_0:nodeByName("mana_txt"):setString(arg_5_0.selfPlayer.mana)
	arg_5_0:nodeByName("crystal_txt"):setString(arg_5_0.selfPlayer.crystal)
end

function var_0_0.updateHeroModel(arg_6_0, arg_6_1)
	if not arg_6_0.heroModel then
		local var_6_0 = var_0_4.new()

		var_6_0:populateWithTableID(xyd.tables.misc.activityRichHero)

		arg_6_0.heroModel = var_6_0:getHeroModel()

		arg_6_0.heroModel:setScale(0.4)
		arg_6_0.heroModel:addTo(arg_6_0:nodeByName("station_pos"))
		arg_6_0.heroModel:setLocalZOrder(2000)
	end

	if not arg_6_1 then
		arg_6_0.heroModel.currentPos = arg_6_0.baseInfo.pos
	end

	arg_6_0.heroModel.pos = arg_6_0.baseInfo.pos

	arg_6_0:updateHeroPosition(arg_6_1)

	if arg_6_0.heroModel.currentPos ~= arg_6_0.heroModel.pos then
		arg_6_0:playHeroGoAction()
	else
		arg_6_0:actionEnded()
	end
end

function var_0_0.handleEvent(arg_7_0, ...)
	if arg_7_0.baseInfo.event_type > 0 then
		arg_7_0.isPlayEvent = true

		local var_7_0 = arg_7_0.baseInfo.event_type

		function callback(arg_8_0, arg_8_1)
			if not arg_8_0 then
				arg_7_0.isPlayEvent = false

				return
			end

			if not arg_7_0 or not arg_7_0.superRich or not arg_7_0.initStationItem then
				return
			end

			if arg_7_0 and arg_7_0.initStationItem then
				arg_7_0:initStationItem()
				arg_7_0:updateHeroModel()

				if var_7_0 == 1 and arg_8_0 == 0 then
					arg_7_0:addEffect(arg_7_0.heroModel, true)
				end
			end

			arg_8_1 = arg_8_1 or arg_7_0.superRich.response or {}

			if arg_8_0 == 0 then
				local var_8_0 = var_0_3:desc(var_7_0)

				if xyd.isInTable({
					2,
					3,
					9
				}, var_7_0) then
					if arg_8_1.event_pos and arg_8_1.event_pos > 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_8_0, var_0_2:name(arg_8_1.event_pos))
						})
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:descUnhappend(var_7_0)
						})
					end
				elseif xyd.isInTable({
					1,
					4,
					8,
					11,
					12,
					13
				}, var_7_0) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_8_0
					})
				elseif xyd.isInTable({
					6,
					10
				}, var_7_0) then
					xyd.WindowManager.get():openWindow("toast", {
						message = string.format(var_8_0, var_0_3:value(var_7_0))
					})
				elseif xyd.isInTable({
					5,
					7
				}, var_7_0) then
					if arg_8_1.event_item and arg_8_1.event_item > 0 then
						xyd.WindowManager.get():openWindow("toast", {
							message = string.format(var_8_0, xyd.tables.item:name(arg_8_1.event_item))
						})
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_3:descUnhappend(var_7_0)
						})
					end
				end
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("RICH_EVENT_FINISH")
				})
			end
		end

		local var_7_1 = {
			event_type = var_7_0,
			callback = callback
		}

		xyd.WindowManager.get():openWindow("super_rich_news", var_7_1)
	end
end

function var_0_0.actionEnded(arg_9_0)
	arg_9_0:handleEvent()
	arg_9_0:updateEnterShow()

	local var_9_0 = arg_9_0.baseInfo.pos
	local var_9_1 = var_0_2:type(var_9_0)
	local var_9_2 = arg_9_0.gridInfo[var_9_0]
	local var_9_3 = var_9_2.lev or 0
	local var_9_4 = {
		pos = var_9_0,
		info = var_9_2,
		grid_type = var_9_1
	}

	if arg_9_0.baseInfo.can_operate == 1 and (var_9_1 == 5 and var_9_3 < 1 or var_9_1 == 1 and var_9_3 < 3) then
		arg_9_0:upgrade(var_9_4)
	elseif var_9_1 == 3 then
		xyd.WindowManager.get():openWindow("super_rich_shop", var_9_4)
	end

	arg_9_0.isPlayEffect = false
end

function var_0_0.updateHeroPosition(arg_10_0, arg_10_1)
	local var_10_0 = cc.p(arg_10_0:nodeByName("station" .. arg_10_0.heroModel.currentPos):getPosition())
	local var_10_1 = cc.MoveTo:create(xyd.tables.misc.dormGirlsSpeedTime, var_10_0)
	local var_10_2 = false

	if arg_10_0.heroModel.currentPos >= 1 and arg_10_0.heroModel.currentPos <= 9 or arg_10_0.heroModel.currentPos > 25 then
		var_10_2 = true
	end

	if arg_10_0.baseInfo.forward < 0 then
		var_10_2 = not var_10_2
	end

	arg_10_0.heroModel:flipX(var_10_2)

	if not arg_10_1 then
		arg_10_0.heroModel:setPosition(var_10_0)
		arg_10_0:actionEnded()

		return
	end

	if arg_10_1 and arg_10_0.heroModel.pos and arg_10_0.heroModel.pos ~= arg_10_0.heroModel.currentPos then
		arg_10_0.heroModel:runAction(var_10_1)
		arg_10_0.heroModel:walk(true)
	else
		local var_10_3 = cc.Sequence:create({
			var_10_1,
			cc.CallFunc:create(function()
				arg_10_0.heroModel:idle()
				arg_10_0:actionEnded()
			end)
		})

		arg_10_0.heroModel:runAction(var_10_3)
		arg_10_0.heroModel:walk(true)

		if arg_10_0.handle then
			var_0_5.unscheduleGlobal(arg_10_0.handle)

			arg_10_0.handle = nil
		end
	end
end

function var_0_0.updateEnterShow(arg_12_0)
	for iter_12_0 = 1, #arg_12_0.enterBgs do
		if arg_12_0.enterBgs[iter_12_0].pos ~= arg_12_0.baseInfo.pos or arg_12_0.enterBgs[iter_12_0].stationType == 6 and (arg_12_0.superRich.fightInfo.lev > 10 or arg_12_0.superRich.fightInfo.times <= 0) or arg_12_0.enterBgs[iter_12_0].stationType == 8 and arg_12_0.superRich.missionInfo.lev > 16 then
			arg_12_0.enterBgs[iter_12_0]:setVisible(false)
		else
			arg_12_0.enterBgs[iter_12_0]:setVisible(true)
		end
	end
end

function var_0_0.addEffect(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = "skeletons/ui_effect/star_treasure_effect/yun"
	local var_13_1 = xyd.createEffect(var_13_0)

	var_13_1:addTo(arg_13_1)
	var_13_1:setName("effect")

	if not arg_13_2 then
		var_13_1:setScale(1, 1)
		var_13_1:setPosition(cc.p(arg_13_1:getContentSize().width / 2, arg_13_1:getContentSize().height / 2))
		var_13_1:play(nil, false, 0.9)
	else
		var_13_1:setScale(2, 2)
		var_13_1:setPosition(cc.p(0, 200))
		var_13_1:play(nil, false, 0.8)
	end
end

function var_0_0.initStationItem(arg_14_0, arg_14_1)
	arg_14_0.enterBgs = {}

	for iter_14_0 = 1, 32 do
		arg_14_0:nodeByName("station" .. iter_14_0):setLocalZOrder(math.abs(iter_14_0 - 17))

		local var_14_0 = arg_14_0:nodeByName("station" .. iter_14_0)

		if arg_14_0:nodeByName("station" .. iter_14_0 .. "_top") then
			arg_14_0:nodeByName("station" .. iter_14_0 .. "_top"):setLocalZOrder(100)

			var_14_0 = arg_14_0:nodeByName("station" .. iter_14_0 .. "_top")
		end

		local var_14_1 = var_0_2:type(iter_14_0)

		if var_14_1 == 1 or var_14_1 == 3 then
			local var_14_2 = arg_14_0.gridInfo[iter_14_0]
			local var_14_3 = var_0_2:getIconByLev(iter_14_0, math.max(1, var_14_2.lev or 1))
			local var_14_4 = var_0_2:posType(iter_14_0)
			local var_14_5 = xyd.AssetLoader.get():loadSprite(var_14_3)

			if var_14_0:getChildByName("icon") then
				var_14_0:getChildByName("icon"):removeFromParent()
			end

			if var_14_0:getChildByName("icon") then
				var_14_0:getChildByName("icon"):setSpriteFrame(var_14_5:getSpriteFrame())
			else
				var_14_5:addTo(var_14_0)
				var_14_5:setName("icon")

				if var_14_4 == 1 and (iter_14_0 > 1 and iter_14_0 < 9 or iter_14_0 > 17 and iter_14_0 < 25) then
					var_14_5:setPosition(cc.p(87, 81))
				elseif var_14_4 == 1 then
					var_14_5:setPosition(cc.p(83, 54))
				end

				local var_14_6 = var_14_0.iconPath

				if var_14_2.lev and var_14_2.lev > 0 then
					var_14_0.iconPath = var_14_3
				else
					var_14_0.iconPath = nil
				end

				if not arg_14_1 and var_14_6 ~= var_14_0.iconPath then
					arg_14_0:addEffect(var_14_5)
				end
			end

			if var_14_1 == 1 and (not var_14_2.lev or var_14_2.lev <= 0) then
				var_14_0:getChildByName("icon"):setOpacity(0)
			else
				var_14_0:getChildByName("icon"):setOpacity(255)
			end
		end

		for iter_14_1, iter_14_2 in ipairs(var_14_0:getChildren()) do
			if iter_14_2:getName() == "icon" or iter_14_2:getName() == "enter_bg" then
				local var_14_7 = false

				if iter_14_2:getName() == "enter_bg" then
					iter_14_2.pos = iter_14_0
					iter_14_2.stationType = var_14_1

					table.insert(arg_14_0.enterBgs, iter_14_2)
					iter_14_2:setVisible(false)

					var_14_7 = true
				end

				iter_14_2:setTouchEnabled(true)
				iter_14_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
					if arg_15_0.name == "began" then
						return true
					elseif arg_15_0.name == "ended" then
						xyd.playButtonSound()

						local var_15_0 = {
							pos = iter_14_0,
							info = arg_14_0.gridInfo[iter_14_0],
							grid_type = var_14_1
						}
						local var_15_1 = 0

						if arg_14_0.gridInfo[iter_14_0] and arg_14_0.gridInfo[iter_14_0].lev then
							var_15_1 = arg_14_0.gridInfo[iter_14_0].lev
						end

						if arg_14_0.baseInfo.pos == iter_14_0 and (var_14_1 ~= 5 or not (var_15_1 > 0)) and (var_14_1 ~= 1 or not (var_15_1 >= 3)) and arg_14_0.baseInfo.can_operate == 1 then
							if var_14_1 == 1 then
								arg_14_0:upgrade(var_15_0)
							elseif var_14_1 == 3 then
								xyd.WindowManager.get():openWindow("super_rich_shop", var_15_0)
							elseif var_14_1 == 5 then
								arg_14_0:upgrade(var_15_0)
							elseif var_14_1 == 6 and var_14_7 then
								xyd.WindowManager.get():openWindow("super_rich_challenge", var_15_0)
							elseif var_14_1 == 7 and var_14_7 then
								xyd.WindowManager.get():openWindow("super_rich_pipe", var_15_0)
							elseif var_14_1 == 8 and var_14_7 then
								xyd.WindowManager.get():openWindow("super_rich_wheel", var_15_0)
							end
						elseif var_14_1 == 1 or var_14_1 == 5 then
							xyd.WindowManager.get():openWindow("super_rich_desc", var_15_0)
						elseif var_14_1 == 6 or var_14_1 == 7 or var_14_1 == 8 then
							local var_15_2 = true

							if var_14_1 == 6 and arg_14_0.superRich.fightInfo.lev > 10 or var_14_1 == 8 and arg_14_0.superRich.missionInfo.lev > 16 then
								var_15_2 = false
							end

							if var_15_2 then
								xyd.WindowManager.get():openWindow("super_rich_award_tip", var_15_0)
							end
						end
					end
				end)
			end
		end
	end

	arg_14_0:updateEnterShow()
end

function var_0_0.upgrade(arg_16_0, arg_16_1)
	arg_16_0.isPlayUpgrade = true

	function arg_16_1.callback()
		arg_16_0:initStationItem()

		arg_16_0.isPlayUpgrade = false
	end

	xyd.WindowManager.get():openWindow("super_rich_upgrade", arg_16_1)
end

function var_0_0.initEffect(arg_18_0)
	arg_18_0.diceEffects = {}

	for iter_18_0 = 1, #var_0_7 do
		local var_18_0 = xyd.createEffect(var_0_7[iter_18_0])

		var_18_0:addTo(arg_18_0:nodeByName("dice_effect_pos"))
		var_18_0:setVisible(false)
		var_18_0:setLocalZOrder(1000)
		table.insert(arg_18_0.diceEffects, var_18_0)
	end

	arg_18_0:nodeByName("dice_effect_pos"):setPositionY(320)
end

function var_0_0.playHeroGoAction(arg_19_0)
	if arg_19_0.handle then
		var_0_5.unscheduleGlobal(arg_19_0.handle)

		arg_19_0.handle = nil
	end

	if arg_19_0.heroModel.pos and arg_19_0.heroModel.pos ~= arg_19_0.heroModel.currentPos then
		arg_19_0.heroModel.currentPos = (arg_19_0.heroModel.currentPos + arg_19_0.baseInfo.forward - 1) % var_0_6 + 1

		arg_19_0:updateHeroPosition(true)
	end

	arg_19_0.handle = var_0_5.scheduleGlobal(function()
		if arg_19_0 and not tolua.isnull(arg_19_0) then
			if arg_19_0.heroModel.pos and arg_19_0.heroModel.pos ~= arg_19_0.heroModel.currentPos then
				arg_19_0.heroModel.currentPos = (arg_19_0.heroModel.currentPos + arg_19_0.baseInfo.forward - 1) % var_0_6 + 1
			end

			arg_19_0:updateHeroPosition(true)
		elseif arg_19_0.handle then
			var_0_5.unscheduleGlobal(arg_19_0.handle)

			arg_19_0.handle = nil
		end
	end, xyd.tables.misc.dormGirlsSpeedTime)
end

function var_0_0.setButtonClick(arg_21_0)
	arg_21_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_22_0 = {}

			arg_21_0.superRich:monopolyRankList(var_22_0, function(arg_23_0, arg_23_1)
				if arg_23_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("super_rich_rank", arg_23_1)
				end
			end)
		end
	end)

	local var_21_0 = 0

	local function var_21_1(arg_24_0)
		if not arg_24_0 and arg_21_0.backpack:getItemNumByID(xyd.tables.misc.activityRichDiceItem) <= 0 then
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("SUPER_RICH_DICE_NOT_ENOUGH")
			})

			return
		end

		local var_24_0 = {
			cheat_num = arg_24_0
		}

		arg_21_0.superRich:monoplyDicing(var_24_0, function(arg_25_0, arg_25_1)
			if arg_25_0 == xyd.error.OK then
				arg_21_0.isPlayEffect = true

				arg_21_0:playDiceEffect(arg_25_1)
			else
				arg_21_0.isPlayEffect = false
			end
		end)
	end

	local function var_21_2(arg_26_0)
		local var_26_0 = arg_21_0.baseInfo.pos
		local var_26_1 = var_0_2:type(var_26_0)

		if var_26_1 == 6 and arg_21_0.superRich.fightInfo.times > 0 then
			local var_26_2 = var_0_1:translation("SUPER_RICH_CHALLENGE_GIVE_UP_TIP")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_2, function()
				var_21_1(arg_26_0)
			end, nil, nil, arg_21_0.colorMode)
		elseif var_26_1 == 8 and arg_21_0.superRich:canGetMisstionAward() then
			local var_26_3 = var_0_1:translation("RICH_IS_GO")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_3, function()
				var_21_1(arg_26_0)
			end, nil, nil, arg_21_0.colorMode)
		elseif var_26_1 == 8 and arg_21_0.superRich:notFinishMisstion() then
			local var_26_4 = var_0_1:translation("RICH_IS_GO_MISSION")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_26_4, function()
				var_21_1(arg_26_0)
			end, nil, nil, arg_21_0.colorMode)
		else
			var_21_1(arg_26_0)
		end
	end

	arg_21_0:nodeByName("dice_btn"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended and not arg_21_0.isPlayEffect and not arg_21_0.isPlayEvent and not arg_21_0.isPlayUpgrade then
			xyd.playButtonSound()
			var_21_2()
		end
	end)
	arg_21_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_31_0, arg_31_1)
		if arg_31_1 == ccui.TouchEventType.ended and not arg_21_0.isPlayEffect then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("super_rich_main_rule")
		end
	end)
	arg_21_0:nodeByName("backpack_btn"):addTouchEventListener(function(arg_32_0, arg_32_1)
		if arg_32_1 == ccui.TouchEventType.ended and not arg_21_0.isPlayEffect then
			xyd.playButtonSound()

			local function var_32_0()
				local var_33_0 = {
					callback = var_21_2
				}

				xyd.WindowManager.get():openWindow("super_rich_select_point", var_33_0)
			end

			local var_32_1 = {
				callback = var_32_0,
				use_type = {
					1,
					0,
					0
				}
			}
			local var_32_2 = xyd.WindowManager.get():openWindow("super_rich_backpack", var_32_1)

			var_32_2:setPosition(cc.p(79, 130))
			var_32_2:addBlockLayer(cc.c4b(0, 0, 0, 0))
		end
	end)
	arg_21_0:nodeByName("dice_shop_btn"):addTouchEventListener(function(arg_34_0, arg_34_1)
		if arg_34_1 == ccui.TouchEventType.ended and not arg_21_0.isPlayEffect then
			xyd.playButtonSound()

			local var_34_0 = arg_21_0.baseInfo.pos
			local var_34_1 = var_0_2:type(var_34_0)
			local var_34_2 = arg_21_0.gridInfo[var_34_0]

			if not var_34_2.lev then
				local var_34_3 = 0
			end

			local var_34_4 = {
				pos = var_34_0,
				info = var_34_2,
				grid_type = var_34_1
			}

			xyd.WindowManager.get():openWindow("super_rich_shop", var_34_4)
		end
	end)
	arg_21_0:nodeByName("graphic_btn"):addTouchEventListener(function(arg_35_0, arg_35_1)
		if arg_35_1 == ccui.TouchEventType.ended and not arg_21_0.isPlayEffect then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("super_rich_graphic_tip")
		end
	end)

	arg_21_0.touchLayer = display.newNode()

	arg_21_0.touchLayer:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_21_0.touchLayer:addTo(arg_21_0)
	arg_21_0.touchLayer:setTouchEnabled(true)
	arg_21_0.touchLayer:setTouchSwallowEnabled(false)
	arg_21_0.touchLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
		if arg_36_0.name == "began" and arg_21_0.heroModel.pos ~= arg_21_0.heroModel.currentPos then
			arg_21_0.heroModel:stopAllActions()
			arg_21_0.heroModel:idle()

			if arg_21_0.handle then
				var_0_5.unscheduleGlobal(arg_21_0.handle)

				arg_21_0.handle = nil
			end

			arg_21_0:updateHeroModel()
		end

		return true
	end)
end

function var_0_0.playDiceEffect(arg_37_0, arg_37_1)
	arg_37_0:playAddScore(-1, 2)

	arg_37_0.response = arg_37_1

	arg_37_0:nodeByName("dice_big"):setVisible(false)

	local var_37_0 = arg_37_1.last_dice

	for iter_37_0 = 1, 6 do
		arg_37_0.diceEffects[iter_37_0]:setVisible(false)
	end

	arg_37_0.diceEffects[var_37_0]:setVisible(true)
	arg_37_0.diceEffects[var_37_0]:play(function()
		arg_37_0:updateHeroModel(true)

		if arg_37_0.baseInfo.deltaStamps and arg_37_0.baseInfo.deltaStamps > 0 then
			arg_37_0:playAddScore(arg_37_0.baseInfo.deltaStamps, 1)
		end
	end, false)
end

function var_0_0.openGuideWindow(arg_39_0)
	local var_39_0 = {
		callback = {}
	}
	local var_39_1 = xyd.WindowManager.get():openWindow("super_rich_guide", var_39_0)

	var_39_1:setPosition(cc.p(344, 136))
	var_39_1:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.openBackWindow(arg_40_0)
	local function var_40_0()
		local var_41_0 = {
			callback = handlePlayDice
		}

		xyd.WindowManager.get():openWindow("super_rich_select_point", var_41_0)
	end

	local var_40_1 = {
		callback = var_40_0,
		use_type = {
			1,
			0,
			0
		}
	}
	local var_40_2 = xyd.WindowManager.get():openWindow("super_rich_backpack", var_40_1)

	var_40_2:setPosition(cc.p(79, 130))
	var_40_2:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.playAddScore(arg_42_0, arg_42_1, arg_42_2)
	local var_42_0 = xyd.createLabel(24, cc.c3b(255, 255, 255))

	if arg_42_1 < 0 then
		var_42_0:setString(arg_42_1)
	else
		var_42_0:setString("+" .. arg_42_1)
	end

	var_42_0:addTo(arg_42_0:nodeByName("number_bg" .. arg_42_2))
	var_42_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_42_0:setPosition(cc.p(120, 15))
	var_42_0:enableOutline(cc.c4b(86, 104, 33, 255), 2)

	local var_42_1 = 1
	local var_42_2 = xyd.tables.battleConfig.floatAnimationDuration * 5
	local var_42_3 = xyd.tables.battleConfig.floatFadeOutDelay * 5
	local var_42_4 = cc.Spawn:create({
		cc.MoveBy:create(var_42_2, cc.p(0, 400)),
		cc.Sequence:create({
			cc.DelayTime:create(var_42_3),
			cc.FadeOut:create(var_42_2 - var_42_3)
		})
	})

	var_42_0:runActionOnce(var_42_4, true, nil, var_42_1)
end

return var_0_0
