local var_0_0 = class("FishGamblingMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.EcoSidebar")
local var_0_3 = import("app.common.ui.SpriteNodeButton")
local var_0_4 = xyd.tables.activityFishTable
local var_0_5 = xyd.tables.activityFishGamblingSchedule
local var_0_6 = xyd.tables.activityFishGamblingOddSche
local var_0_7 = import("app.common.ui.SplitLine")
local var_0_8 = xyd.tables.misc
local var_0_9 = import("framework.scheduler")
local var_0_10 = xyd.tables.announce
local var_0_11 = var_0_8:getValue("activity_fish_gambling_silver_coin")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.player_:getBackpack()
	arg_1_0.ecoBarType = xyd.EcoSidebarType.MAIN
	arg_1_0.itemID = var_0_11
	arg_1_0.hasNum = arg_1_0.player_:getBackpack():getItemNumByID(arg_1_0.itemID)
	arg_1_0.maxNum = arg_1_0.hasNum
	arg_1_0.currentNum = 1
	arg_1_0.handler = {}
	arg_1_0.subDay = 0
	arg_1_0.nowMatchCount = 0
	arg_1_0.showMatchCount = 1
	arg_1_0.selectedFishDirection = 0
	arg_1_0.firstIn = arg_1_2.firstIn

	if arg_1_0.firstIn ~= false then
		arg_1_0.firstIn = true
	end

	arg_1_0.fightInfo = arg_1_2.fish_fight_info
	arg_1_0.baseInfo = arg_1_0.fightInfo.base_info
	arg_1_0.playerInfo = arg_1_0.fightInfo.player_info
	arg_1_0.stageInfo = arg_1_0.fightInfo.stage_info
	arg_1_0.gameInfo = arg_1_0.fightInfo.game_info
	arg_1_0.round = arg_1_0.stageInfo.round
	arg_1_0.stage = arg_1_0.stageInfo.stage
	arg_1_0.subDay = arg_1_0.stageInfo.subDay
	arg_1_0.startTime = arg_1_2.start_time
	arg_1_0.endTime = arg_1_2.end_time
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		ecoCount = 2,
		show_rule = false,
		ecoBarType = xyd.EcoSidebarType.DISPLAY,
		ecoTypes = {
			var_0_11,
			2
		},
		ecoIcons = {
			"windows/fish_gambling/fish_silver_coin.png",
			-1
		},
		ecoScale = {
			0.55,
			1
		},
		callback = handler(arg_2_0, arg_2_0.close)
	})

	arg_2_0.ecoSidebar = arg_2_0:nodeByName("eco_sidebar")

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(cc.mvc.AppBase.APP_ENTER_FOREGROUND_EVENT, handler(arg_2_0, arg_2_0.enterForeGround))
	arg_2_0:addEcoBtn()
	arg_2_0:initMatchInfo()
	arg_2_0:layout()
	arg_2_0:updateEco()
	arg_2_0:updateOddBtnState()
end

function var_0_0.enterForeGround(arg_3_0)
	if arg_3_0.handler then
		if arg_3_0.handler[1] then
			var_0_9.unscheduleGlobal(arg_3_0.handler[1])
		end

		if arg_3_0.handler[2] then
			var_0_9.unscheduleGlobal(arg_3_0.handler[2])
		end

		if arg_3_0.handler[3] then
			var_0_9.unscheduleGlobal(arg_3_0.handler[3])
		end

		arg_3_0.handler = {}
	end

	arg_3_0:initMatchInfo()
	arg_3_0:updateEco()
	arg_3_0:updateOddBtnState()
end

function var_0_0.addEcoBtn(arg_4_0)
	local var_4_0 = "windows/button/btn_add_eco.png"
	local var_4_1 = xyd.tables.systemColor:btnColors(arg_4_0.colorMode)
	local var_4_2 = {
		sprite = var_4_0,
		colorModes = var_4_1
	}
	local var_4_3 = var_0_3.new(var_4_2)

	var_4_3:setAnchorPoint(0.5, 0.5)
	var_4_3:addTo(arg_4_0.ecoSidebar:nodeByName("eco_1"))

	arg_4_0.oldCoinTxt = arg_4_0.ecoSidebar:nodeByName("eco_1"):getChildByName("txt_eco_val_1")

	var_4_3:setPositionX(arg_4_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionX() + 140)
	var_4_3:setPositionY(arg_4_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionY())
	var_4_3:setName("coin_btn")

	arg_4_0.children_.coin_btn = var_4_3

	var_4_3:addTouchEvent(function(arg_5_0)
		if arg_5_0.name == "ended" then
			xyd.playButtonSound()

			local var_5_0 = arg_4_0.itemID

			function callback()
				return
			end

			xyd.WindowManager.get():openWindow("fish_gambling_sell_detail", {
				itemID = arg_4_0.itemID
			})
		end
	end)

	local var_4_4 = var_0_3.new(var_4_2)

	var_4_4:setAnchorPoint(0.5, 0.5)
	var_4_4:addTo(arg_4_0.ecoSidebar:nodeByName("eco_2"))

	arg_4_0.crystalTxt = arg_4_0.ecoSidebar:nodeByName("eco_2"):getChildByName("txt_eco_val_2")

	var_4_4:setPositionX(arg_4_0.ecoSidebar:nodeByName("pos_icon_2"):getPositionX() + 140)
	var_4_4:setPositionY(arg_4_0.ecoSidebar:nodeByName("pos_icon_1"):getPositionY())
	var_4_4:setName("crystal_btn")

	arg_4_0.children_.crystal_btn = var_4_4

	var_4_4:addTouchEvent(function(arg_7_0)
		if arg_7_0.name == "ended" then
			xyd.playButtonSound()
			arg_4_0.player_:sendFunctionClick(xyd.FunctionClick.CHARGE)
			xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
		end
	end)
end

function var_0_0.updateEco(arg_8_0)
	local var_8_0 = arg_8_0.crystalTxt:getString()
	local var_8_1 = xyd.num2ThousandsStr(arg_8_0.player_.crystal)

	if var_8_0 ~= var_8_1 then
		arg_8_0.crystalTxt:setString(var_8_1)

		local var_8_2 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_8_3 = cc.Spawn:create(var_8_2)

		arg_8_0.crystalTxt:runAction(var_8_3)
	end

	if arg_8_0.oldCoinTxt then
		local var_8_4 = arg_8_0.oldCoinTxt:getString()
		local var_8_5 = xyd.num2ThousandsStr(arg_8_0.backpack:getItemNumByID(var_0_11))

		if var_8_4 ~= var_8_5 then
			arg_8_0.oldCoinTxt:setString(var_8_5)

			local var_8_6 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_8_7 = cc.Spawn:create(var_8_6)

			arg_8_0.oldCoinTxt:runAction(var_8_7)
		end
	end
end

function var_0_0.layout(arg_9_0)
	local var_9_0 = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_10")

	arg_9_0:nodeByName("mortage_chips_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_10"))
	arg_9_0:nodeByName("buy_chips_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_11"))
	arg_9_0:nodeByName("txt_num"):setString(arg_9_0.currentNum .. "/" .. arg_9_0.maxNum)

	local var_9_1 = var_0_7.new({
		size = 380
	})

	arg_9_0:nodeByName("left_container"):addChild(var_9_1)
	var_9_1:setPosition(cc.p(20, 115))

	local var_9_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_9_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_2:setScale(1, 1)
	var_9_2:addTo(arg_9_0:nodeByName("decrease_button"))
	var_9_2:setName("jiandian")

	arg_9_0.children_.jiandian = var_9_2

	local var_9_3 = false

	var_9_2:onButtonPressed(function(arg_10_0)
		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_9_0.decreaseCurrentNum then
				arg_9_0:decreaseCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_9_3 = true

				if arg_9_0.decreaseCurrentNum then
					arg_9_0:decreaseCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_9_0.handler[2] = var_0_9.scheduleGlobal(var_10_1, 0.03)

				var_0_9.unscheduleGlobal(arg_9_0.handler[1])
			else
				var_9_3 = false
			end
		end

		var_9_3 = false
		arg_9_0.handler[1] = var_0_9.scheduleGlobal(var_10_2, 0.1)
	end)
	var_9_2:onButtonRelease(function(arg_13_0)
		if arg_9_0.handler[1] ~= nil then
			var_0_9.unscheduleGlobal(arg_9_0.handler[1])
		end

		if arg_9_0.handler[2] ~= nil then
			var_0_9.unscheduleGlobal(arg_9_0.handler[2])
		end

		if var_9_3 == false and arg_9_0.decreaseCurrentNum then
			arg_9_0:decreaseCurrentNum()
		end
	end)

	local var_9_4 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_9_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_9_4:setScale(1, 1)
	var_9_4:addTo(arg_9_0:nodeByName("increase_button"))
	var_9_4:setName("jiadian")

	arg_9_0.children_.jiadian = var_9_4

	local var_9_5 = false

	var_9_4:onButtonPressed(function(arg_14_0)
		local var_14_0 = 0

		local function var_14_1()
			var_14_0 = var_14_0 + 0.03

			if arg_9_0.addCurrentNum then
				arg_9_0:addCurrentNum()
			end
		end

		local function var_14_2()
			var_14_0 = var_14_0 + 0.1

			if var_14_0 > 0.5 and var_14_0 <= 4 then
				var_9_5 = true

				if arg_9_0.addCurrentNum then
					arg_9_0:addCurrentNum()
				end
			elseif var_14_0 > 4 then
				arg_9_0.handler[2] = var_0_9.scheduleGlobal(var_14_1, 0.03)

				var_0_9.unscheduleGlobal(arg_9_0.handler[1])
			else
				var_9_5 = false
			end
		end

		var_9_5 = false
		arg_9_0.handler[1] = var_0_9.scheduleGlobal(var_14_2, 0.1)
	end)
	var_9_4:onButtonRelease(function(arg_17_0)
		if arg_9_0.handler[1] ~= nil then
			var_0_9.unscheduleGlobal(arg_9_0.handler[1])
		end

		if arg_9_0.handler[2] ~= nil then
			var_0_9.unscheduleGlobal(arg_9_0.handler[2])
		end

		if var_9_5 == false and arg_9_0.addCurrentNum then
			arg_9_0:addCurrentNum()
		end
	end)
	arg_9_0:nodeByName("btn_max"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("btn_max"), arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_9_0.currentNum = arg_9_0.maxNum

			arg_9_0:updateNum()
		end
	end)
	arg_9_0:initChatBox()

	arg_9_0.cardViewFishID = 0

	arg_9_0:reloadCardFish()
	arg_9_0:nodeByName("arrow_left"):setTouchEnabled(true)
	arg_9_0:nodeByName("arrow_left"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_19_0)
		if arg_19_0.name == "began" then
			arg_9_0:nodeByName("arrow_left"):setScale(0.9)

			return true
		elseif arg_19_0.name == "moved" then
			arg_9_0:nodeByName("arrow_left"):setScale(1)
		elseif arg_19_0.name == "ended" then
			arg_9_0:nodeByName("arrow_left"):setScale(1)

			arg_9_0.showMatchCount = math.max(arg_9_0.showMatchCount - 1, 1)
			arg_9_0.showMatchCount = math.max(arg_9_0.nowMatchCount - 3, arg_9_0.showMatchCount)

			arg_9_0:updateRightContainer()

			arg_9_0.selectedFishDirection = 0

			arg_9_0:reloadCardFish()
			arg_9_0:updateMatchInfo(arg_9_0.time)
		end
	end)
	arg_9_0:nodeByName("arrow_right"):setTouchEnabled(true)
	arg_9_0:nodeByName("arrow_right"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
		if arg_20_0.name == "began" then
			arg_9_0:nodeByName("arrow_right"):setScale(0.9)

			return true
		elseif arg_20_0.name == "moved" then
			arg_9_0:nodeByName("arrow_right"):setScale(1)
		elseif arg_20_0.name == "ended" then
			arg_9_0:nodeByName("arrow_right"):setScale(1)

			arg_9_0.showMatchCount = math.min(arg_9_0.showMatchCount + 1, 21)
			arg_9_0.showMatchCount = math.min(arg_9_0.nowMatchCount + 3, arg_9_0.showMatchCount)

			arg_9_0:updateRightContainer()

			arg_9_0.selectedFishDirection = 0

			arg_9_0:reloadCardFish()
			arg_9_0:updateMatchInfo(arg_9_0.time)
		end
	end)
	arg_9_0:nodeByName("left_touch_node"):setTouchEnabled(true)
	arg_9_0:nodeByName("left_touch_node"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			return true
		elseif arg_21_0.name == "moved" then
			-- block empty
		elseif arg_21_0.name == "ended" and arg_9_0.leftFishId > 0 then
			arg_9_0.selectedFishDirection = 1

			arg_9_0:reloadCardFish()
		end
	end)
	arg_9_0:nodeByName("right_touch_node"):setTouchEnabled(true)
	arg_9_0:nodeByName("right_touch_node"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			return true
		elseif arg_22_0.name == "moved" then
			-- block empty
		elseif arg_22_0.name == "ended" and arg_9_0.rightFishId > 0 then
			arg_9_0.selectedFishDirection = 2

			arg_9_0:reloadCardFish()
		end
	end)
	arg_9_0:nodeByName("btn_mortage"):addTouchEventListener(function(arg_23_0, arg_23_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("btn_mortage"), arg_23_1)

		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("fish_gambling_pledge")
		end
	end)
	arg_9_0:nodeByName("btn_buy"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("btn_buy"), arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_24_0 = arg_9_0.itemID

			xyd.WindowManager.get():openWindow("fish_gambling_sell_detail", {
				itemID = arg_9_0.itemID
			})
		end
	end)
	arg_9_0:nodeByName("btn_bet"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("btn_bet"), arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_25_0 = string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_1"), var_0_4:name(arg_9_0.cardViewFishID), arg_9_0.currentNum)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_25_0, function()
				if arg_9_0:judgeIfCanBet() then
					local var_26_0 = {
						round = arg_9_0.showRound,
						stage = arg_9_0.showStage,
						side = arg_9_0.selectedFishDirection,
						bet = arg_9_0.currentNum
					}

					local function var_26_1()
						local var_27_0 = {
							itemID = arg_9_0.itemID,
							itemNum = arg_9_0.currentNum
						}

						arg_9_0.player_:getBackpack():removeItem(var_27_0)

						arg_9_0.playerInfo[arg_9_0.showRound][arg_9_0.showStage][arg_9_0.selectedFishDirection] = arg_9_0.playerInfo[arg_9_0.showRound][arg_9_0.showStage][arg_9_0.selectedFishDirection] + arg_9_0.currentNum
						arg_9_0.hasNum = arg_9_0.player_:getBackpack():getItemNumByID(arg_9_0.itemID)
						arg_9_0.maxNum = arg_9_0.hasNum
						arg_9_0.currentNum = 1

						arg_9_0:updateOddBtnState()
						arg_9_0:updateNum()
						arg_9_0:updateMatchInfo(arg_9_0.time)
						arg_9_0:updateRightContainer()
						arg_9_0:updateEco()
					end

					xyd.Backend.get():request(xyd.mid.FISH_FIGHT_BET, var_26_0, function(arg_28_0, arg_28_1)
						if arg_28_0 == xyd.error.OK then
							arg_9_0.baseInfo = arg_28_1
						end

						if var_26_1 then
							var_26_1(arg_28_0, arg_28_1)
						end
					end)
				else
					local var_26_2 = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_26")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_26_2
					})
				end
			end, nil, nil, xyd.ColorMode.BLUE)
		end
	end)
	arg_9_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_29_0, arg_29_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("rank_btn"), arg_29_1)

		if arg_29_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_29_0 = {}

			xyd.Backend.get():request(xyd.mid.FISH_FIGHT_RANK, var_29_0, function(arg_30_0, arg_30_1)
				if arg_30_0 == xyd.error.OK then
					local var_30_0 = arg_30_1

					xyd.WindowManager.get():openWindow("fish_gambling_rank", var_30_0)
				end

				if callback then
					callback(arg_30_0, arg_30_1)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("refresh"):addTouchEventListener(function(arg_31_0, arg_31_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("refresh"), arg_31_1)

		if arg_31_1 == ccui.TouchEventType.ended then
			local var_31_0 = {}

			xyd.Backend.get():request(xyd.mid.FISH_FIGHT_BET_INFO, var_31_0, function(arg_32_0, arg_32_1)
				if arg_32_0 == xyd.error.OK then
					arg_9_0.baseInfo = arg_32_1

					arg_9_0:updateMatchInfo(arg_9_0.time)
					arg_9_0:updateRightContainer()
				end

				if callback then
					callback(arg_32_0, arg_32_1)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("icon"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended and arg_9_0.cardViewFishID and arg_9_0.cardViewFishID > 0 then
			xyd.WindowManager.get():openWindow("activity_fishing_skill_tips", {
				id = arg_9_0.cardViewFishID
			}):setPosition(400, 200)
		end
	end)
	arg_9_0:nodeByName("watch_match"):addTouchEventListener(function(arg_34_0, arg_34_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("watch_match"), arg_34_1)

		if arg_34_1 == ccui.TouchEventType.ended then
			local var_34_0 = {
				round = arg_9_0.round,
				stage = arg_9_0.stage
			}

			xyd.Backend.get():request(xyd.mid.FISH_FIGHT_REPORT, var_34_0, function(arg_35_0, arg_35_1)
				if arg_35_0 == xyd.error.OK then
					if arg_35_1 == nil or not next(arg_35_1) then
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
						})
					else
						arg_9_0:replayRecord(arg_35_1)
					end
				end

				if callback then
					callback(arg_35_0, arg_35_1)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("rule"):addTouchEventListener(function(arg_36_0, arg_36_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("rule"), arg_36_1, 0.9, 0.75)

		if arg_36_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("fish_gambling_rule", {
				pageNum = 3
			})
		end
	end)
	arg_9_0:nodeByName("fish_tujian_btn"):addTouchEventListener(function(arg_37_0, arg_37_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("fish_tujian_btn"), arg_37_1)

		if arg_37_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("activity_fishing_book", {
				type_ = 2
			})
		end
	end)
	arg_9_0:nodeByName("arrange_btn"):addTouchEventListener(function(arg_38_0, arg_38_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("arrange_btn"), arg_38_1)

		if arg_38_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_GET_INFO, nil, function(arg_39_0, arg_39_1)
				if arg_39_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("fish_gambling_schedule", arg_39_1)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("record_btn"):addTouchEventListener(function(arg_40_0, arg_40_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("record_btn"), arg_40_1)

		if arg_40_1 == ccui.TouchEventType.ended then
			xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_GET_INFO, nil, function(arg_41_0, arg_41_1)
				if arg_41_0 == xyd.error.OK then
					xyd.Backend.get():request(xyd.mid.FISH_FIGHT_RANK, nil, function(arg_42_0, arg_42_1)
						if arg_41_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("fish_gambling_record", {
								response1 = arg_41_1,
								response2 = arg_42_1
							})
						end
					end)
				end
			end)
		end
	end)
	arg_9_0:nodeByName("shop_btn"):addTouchEventListener(function(arg_43_0, arg_43_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("shop_btn"), arg_43_1)

		if arg_43_1 == ccui.TouchEventType.ended then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("fish_gambling_shop", {
					shop_type = xyd.ShopType.FISH_GAMBLING
				})
			end)
		end
	end)
end

function var_0_0.replayRecord(arg_45_0, arg_45_1)
	local var_45_0 = json.decode(arg_45_1[1].content)
	local var_45_1 = import("app.scenes.FishBattleCreate")
	local var_45_2 = {
		reportData = var_45_0,
		battleType = xyd.BattleType.ReplayReport
	}

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "fish_gambling_main"
		}
	})
	xyd.WindowManager.get():retainHistory()
	cc.Director:getInstance():pushScene(var_45_1.new(var_45_2))
end

function var_0_0.updateOddBtnState(arg_46_0)
	if arg_46_0.maxNum == 0 or arg_46_0.selectedFishDirection == 0 then
		arg_46_0:nodeByName("btn_max"):setBright(false)
		arg_46_0:nodeByName("btn_max"):setTouchEnabled(false)
		arg_46_0:nodeByName("btn_bet"):setBright(false)
		arg_46_0:nodeByName("btn_bet"):setTouchEnabled(false)
	end
end

function var_0_0.reloadFishSprite(arg_47_0)
	arg_47_0:nodeByName("left_word_win"):setVisible(false)
	arg_47_0:nodeByName("left_word_lose"):setVisible(false)
	arg_47_0:nodeByName("right_word_win"):setVisible(false)
	arg_47_0:nodeByName("right_word_lose"):setVisible(false)
	arg_47_0:nodeByName("left_hero_card_container"):removeAllChildren()
	arg_47_0:nodeByName("right_hero_card_container"):removeAllChildren()

	local var_47_0 = "windows/activities/1226/fish/" .. arg_47_0.leftFishId .. ".png"
	local var_47_1 = xyd.SpriteLoader.new(var_47_0, nil, nil, xyd.DefaultImageType.QUESTION_MARK)

	var_47_1:addTo(arg_47_0:nodeByName("left_hero_card_container"))
	var_47_1:setScale(0.65)
	var_47_1:pos(200, 130)

	if arg_47_0.leftFishId == 0 then
		var_47_1:setScale(1)
		var_47_1:pos(200, 160)
		arg_47_0:nodeByName("left_hero_name"):setString("???")
	else
		arg_47_0:nodeByName("left_hero_name"):setString(var_0_4:name(arg_47_0.leftFishId))
		var_47_1:flipX(true)
	end

	local var_47_2 = "windows/activities/1226/fish/" .. arg_47_0.rightFishId .. ".png"
	local var_47_3 = xyd.SpriteLoader.new(var_47_2, nil, nil, xyd.DefaultImageType.QUESTION_MARK)

	var_47_3:addTo(arg_47_0:nodeByName("right_hero_card_container"))
	var_47_3:setScale(0.65)
	var_47_3:pos(200, 130)

	if arg_47_0.rightFishId == 0 then
		var_47_3:setScale(1)
		var_47_3:pos(200, 160)
		arg_47_0:nodeByName("right_hero_name"):setString("???")
	else
		arg_47_0:nodeByName("right_hero_name"):setString(var_0_4:name(arg_47_0.rightFishId))
	end

	xyd.GrayNode(arg_47_0:nodeByName("bg_purple_on"))
	xyd.GrayNode(arg_47_0:nodeByName("bg_purple"))
	xyd.GrayNode(arg_47_0:nodeByName("name_bg_purple"))
	xyd.GrayNode(arg_47_0:nodeByName("right_hero_card_container"))
	xyd.GrayNode(arg_47_0:nodeByName("bg_blue_on"))
	xyd.GrayNode(arg_47_0:nodeByName("bg_blue"))
	xyd.GrayNode(arg_47_0:nodeByName("name_bg_blue"))
	xyd.GrayNode(arg_47_0:nodeByName("left_hero_card_container"))

	if arg_47_0.showWinSide == 1 then
		arg_47_0:nodeByName("left_word_win"):setVisible(true)
		arg_47_0:nodeByName("right_word_lose"):setVisible(true)
		xyd.unGrayNode(arg_47_0:nodeByName("bg_blue_on"))
		xyd.unGrayNode(arg_47_0:nodeByName("bg_blue"))
		xyd.unGrayNode(arg_47_0:nodeByName("name_bg_blue"))
		xyd.unGrayNode(arg_47_0:nodeByName("left_hero_card_container"))
	elseif arg_47_0.showWinSide == 2 then
		arg_47_0:nodeByName("left_word_lose"):setVisible(true)
		arg_47_0:nodeByName("right_word_win"):setVisible(true)
		xyd.unGrayNode(arg_47_0:nodeByName("bg_purple_on"))
		xyd.unGrayNode(arg_47_0:nodeByName("bg_purple"))
		xyd.unGrayNode(arg_47_0:nodeByName("name_bg_purple"))
		xyd.unGrayNode(arg_47_0:nodeByName("right_hero_card_container"))
	else
		xyd.unGrayNode(arg_47_0:nodeByName("bg_purple_on"))
		xyd.unGrayNode(arg_47_0:nodeByName("bg_purple"))
		xyd.unGrayNode(arg_47_0:nodeByName("name_bg_purple"))
		xyd.unGrayNode(arg_47_0:nodeByName("right_hero_card_container"))
		xyd.unGrayNode(arg_47_0:nodeByName("bg_blue_on"))
		xyd.unGrayNode(arg_47_0:nodeByName("bg_blue"))
		xyd.unGrayNode(arg_47_0:nodeByName("name_bg_blue"))
		xyd.unGrayNode(arg_47_0:nodeByName("left_hero_card_container"))
	end
end

function var_0_0.reloadCardFish(arg_48_0)
	arg_48_0.currentNum = 1

	arg_48_0:updateNum()

	if arg_48_0.selectedFishDirection == 0 then
		arg_48_0.cardViewFishID = 0
	elseif arg_48_0.selectedFishDirection == 1 then
		arg_48_0.cardViewFishID = arg_48_0.leftFishId
	elseif arg_48_0.selectedFishDirection == 2 then
		arg_48_0.cardViewFishID = arg_48_0.rightFishId
	end

	arg_48_0:nodeByName("bg_blue_on"):setVisible(false)
	arg_48_0:nodeByName("bg_blue"):setVisible(false)
	arg_48_0:nodeByName("bg_purple_on"):setVisible(false)
	arg_48_0:nodeByName("bg_purple"):setVisible(false)

	if arg_48_0.selectedFishDirection == 1 then
		arg_48_0:nodeByName("bg_blue_on"):setVisible(true)
		arg_48_0:nodeByName("bg_purple"):setVisible(true)
	elseif arg_48_0.selectedFishDirection == 2 then
		arg_48_0:nodeByName("bg_purple_on"):setVisible(true)
		arg_48_0:nodeByName("bg_blue"):setVisible(true)
	else
		arg_48_0:nodeByName("bg_blue"):setVisible(true)
		arg_48_0:nodeByName("bg_purple"):setVisible(true)
	end

	if arg_48_0.cardViewFishID == 0 then
		arg_48_0:nodeByName("blood"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_30"), "???"))
		arg_48_0:nodeByName("attack"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_31"), "???"))
		arg_48_0:nodeByName("defence"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_32"), "???"))
		arg_48_0:nodeByName("speed"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_33"), "???"))
		arg_48_0:nodeByName("dodge"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_34"), "???"))
		arg_48_0:nodeByName("crit"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_35"), "???"))
		arg_48_0:nodeByName("name_txt"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_36"), "???"))
	else
		arg_48_0:nodeByName("blood"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_30"), var_0_4:hp(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("attack"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_31"), var_0_4:atk(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("defence"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_32"), var_0_4:def(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("speed"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_33"), var_0_4:spd(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("dodge"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_34"), var_0_4:evd(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("crit"):setString(string.format(var_0_1:translation("ACTIVITY_FISHING_TEXT_35"), var_0_4:crt(arg_48_0.cardViewFishID)))
		arg_48_0:nodeByName("name_txt"):setString(var_0_4:name(arg_48_0.cardViewFishID))
	end

	arg_48_0:nodeByName("bet_info_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_27"))
	arg_48_0:nodeByName("card_view"):removeAllChildren()

	local var_48_0 = "windows/activities/1226/fish/" .. arg_48_0.cardViewFishID .. ".png"
	local var_48_1 = xyd.SpriteLoader.new(var_48_0, nil, nil, xyd.DefaultImageType.QUESTION_MARK)

	var_48_1:addTo(arg_48_0:nodeByName("card_view"))
	var_48_1:setScale(0.65)
	var_48_1:pos(125, 130)

	if arg_48_0.cardViewFishID == 0 then
		var_48_1:setScale(1)
		var_48_1:pos(125, 160)
	end

	arg_48_0:nodeByName("icon"):removeAllChildren()

	if arg_48_0.cardViewFishID ~= 0 then
		local var_48_2 = "windows/activities/1226/skill_icon/" .. arg_48_0.cardViewFishID .. ".png"
		local var_48_3 = xyd.SpriteLoader.new(var_48_2, nil, nil, xyd.DefaultImageType.QUESTION_MARK)

		var_48_3:addTo(arg_48_0:nodeByName("icon"))
		var_48_3:setScale(0.65)
		var_48_3:pos(35, 35)

		local var_48_4 = "windows/activities/1226/skill_icon/border.png"
		local var_48_5 = xyd.SpriteLoader.new(var_48_4, nil, nil, xyd.DefaultImageType.QUESTION_MARK)

		var_48_5:addTo(arg_48_0:nodeByName("icon"))
		var_48_5:setScale(0.65)
		var_48_5:pos(35, 35)
	end

	arg_48_0:updateBetBtn()
	arg_48_0:nodeByName("bet_num_txt"):setVisible(false)
	arg_48_0:nodeByName("bg_has_bet"):setVisible(false)
	arg_48_0:nodeByName("bg_history_bet"):setVisible(false)
	arg_48_0:nodeByName("silver_coin_sprite"):setVisible(false)
	arg_48_0:nodeByName("bet_info_txt"):setVisible(false)
	arg_48_0:nodeByName("btn_bet"):setVisible(false)

	if arg_48_0.selectedFishDirection == 0 then
		arg_48_0:nodeByName("bet_info_txt"):setVisible(true)
	else
		if arg_48_0.time > arg_48_0.macthStartTime[arg_48_0.showMatchCount] and arg_48_0.time < arg_48_0.macthEndTime[arg_48_0.showMatchCount] then
			if arg_48_0.selectedFishDirection == 0 then
				arg_48_0:nodeByName("bet_info_txt"):setVisible(true)
			else
				arg_48_0:nodeByName("btn_bet"):setVisible(true)
			end
		elseif arg_48_0.time > arg_48_0.macthEndTime[arg_48_0.showMatchCount] and arg_48_0.time <= arg_48_0.macthEndTime[arg_48_0.showMatchCount] + 600 and arg_48_0.selectedFishDirection ~= 0 then
			arg_48_0:nodeByName("bg_has_bet"):setVisible(true)
		elseif arg_48_0.time > arg_48_0.macthEndTime[arg_48_0.showMatchCount] + 600 and arg_48_0.selectedFishDirection ~= 0 then
			arg_48_0:nodeByName("bg_history_bet"):setVisible(true)
		end

		local var_48_6 = arg_48_0.playerInfo[arg_48_0.showRound][arg_48_0.showStage][arg_48_0.selectedFishDirection]

		arg_48_0:nodeByName("bet_num_txt"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_2"), var_48_6))

		local var_48_7 = arg_48_0:nodeByName("bet_num_txt"):getWidth() / 2

		arg_48_0:nodeByName("silver_coin_sprite"):setPositionX(195 - var_48_7 - 20)
		arg_48_0:nodeByName("bet_num_txt"):setVisible(true)
		arg_48_0:nodeByName("silver_coin_sprite"):setVisible(true)
	end

	arg_48_0:refreshSelectedTexiao()
end

function var_0_0.updateBetBtn(arg_49_0)
	if arg_49_0:judgeIfCanBet() then
		arg_49_0:nodeByName("btn_max"):setBright(true)
		arg_49_0:nodeByName("btn_max"):setTouchEnabled(true)
		arg_49_0:nodeByName("btn_bet"):setBright(true)
		arg_49_0:nodeByName("btn_bet"):setTouchEnabled(true)
	else
		arg_49_0:nodeByName("btn_max"):setBright(false)
		arg_49_0:nodeByName("btn_max"):setTouchEnabled(false)
		arg_49_0:nodeByName("btn_bet"):setBright(false)
		arg_49_0:nodeByName("btn_bet"):setTouchEnabled(false)
	end
end

function var_0_0.refreshSelectedTexiao(arg_50_0)
	if not arg_50_0.leftSelectedEffect then
		local var_50_0 = "skeletons/ui_effect/activity_fish_fight/kapianxuanzhong"

		arg_50_0.leftSelectedEffect = xyd.createEffect(var_50_0)

		arg_50_0.leftSelectedEffect:addTo(arg_50_0:nodeByName("left_hero_container"))

		local var_50_1 = arg_50_0:nodeByName("left_hero_container"):getContentSize()

		arg_50_0.leftSelectedEffect:setAnchorPoint(0.5, 0.5)
		arg_50_0.leftSelectedEffect:setPosition(cc.p(var_50_1.width / 2, var_50_1.height / 2))
		arg_50_0.leftSelectedEffect:play(nil, true, nil, "texiao02")
		arg_50_0.leftSelectedEffect:setScale(2)
	end

	if not arg_50_0.rightSelectedEffect then
		local var_50_2 = "skeletons/ui_effect/activity_fish_fight/kapianxuanzhong"

		arg_50_0.rightSelectedEffect = xyd.createEffect(var_50_2)

		arg_50_0.rightSelectedEffect:addTo(arg_50_0:nodeByName("right_hero_container"))

		local var_50_3 = arg_50_0:nodeByName("right_hero_container"):getContentSize()

		arg_50_0.rightSelectedEffect:setAnchorPoint(0.5, 0.5)
		arg_50_0.rightSelectedEffect:setPosition(cc.p(var_50_3.width / 2 + 5, var_50_3.height / 2))
		arg_50_0.rightSelectedEffect:play(nil, true, nil, "texiao01")
		arg_50_0.rightSelectedEffect:setScale(2)
	end

	if arg_50_0.selectedFishDirection == 0 or not (arg_50_0.time > arg_50_0.macthStartTime[arg_50_0.showMatchCount]) or not (arg_50_0.time < arg_50_0.macthEndTime[arg_50_0.showMatchCount]) then
		arg_50_0.leftSelectedEffect:stop()
		arg_50_0.rightSelectedEffect:stop()
		arg_50_0.leftSelectedEffect:hide()
		arg_50_0.rightSelectedEffect:hide()
	elseif arg_50_0.selectedFishDirection == 1 then
		arg_50_0.leftSelectedEffect:play(nil, true, nil, "texiao02")
		arg_50_0.leftSelectedEffect:show()
		arg_50_0.rightSelectedEffect:stop()
		arg_50_0.rightSelectedEffect:hide()
	elseif arg_50_0.selectedFishDirection == 2 then
		arg_50_0.leftSelectedEffect:stop()
		arg_50_0.leftSelectedEffect:hide()
		arg_50_0.rightSelectedEffect:play(nil, true, nil, "texiao01")
		arg_50_0.rightSelectedEffect:show()
	end
end

function var_0_0.judgeIfCanBet(arg_51_0)
	if arg_51_0.leftFishId ~= 0 and arg_51_0.rightFishId ~= 0 and arg_51_0.time > arg_51_0.macthStartTime[arg_51_0.showMatchCount] and arg_51_0.time < arg_51_0.macthEndTime[arg_51_0.showMatchCount] and arg_51_0.selectedFishDirection ~= 0 and arg_51_0.showWinSide == 0 and arg_51_0.maxNum > 0 then
		return true
	end

	return false
end

function var_0_0.initChatBox(arg_52_0)
	local var_52_0 = xyd.AssetLoader.get()
	local var_52_1 = 18
	local var_52_2 = arg_52_0:nodeByName("num_panel")
	local var_52_3 = "windows/login/transparent.png"
	local var_52_4 = var_52_0:loadSprite(var_52_3)

	arg_52_0.chatBox_ = ccui.EditBox:create(var_52_2:getContentSize(), var_52_3)

	arg_52_0.chatBox_:setAnchorPoint(0, 0)
	arg_52_0.chatBox_:pos(0, 0):addTo(var_52_2)
	arg_52_0.chatBox_:setFont(var_52_0.FONT_NAME, var_52_1)
	arg_52_0.chatBox_:setPlaceholderFont(var_52_0.FONT_NAME, var_52_1)
	arg_52_0.chatBox_:setPlaceHolder(var_0_1:translation("CHAT_INPUT_MESSAGE"))
	arg_52_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_52_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_52_0.chatBox_:registerScriptEditBoxHandler(handler(arg_52_0, arg_52_0.inputboxEventHandler))
	arg_52_0.chatBox_:setInputFlag(3)
end

function var_0_0.addCurrentNum(arg_53_0)
	if arg_53_0:judgeIfCanBet() then
		if arg_53_0.currentNum + 1 >= arg_53_0.maxNum then
			arg_53_0.currentNum = arg_53_0.maxNum
		else
			arg_53_0.currentNum = arg_53_0.currentNum + 1
		end

		arg_53_0:nodeByName("txt_num"):setString(arg_53_0.currentNum .. "/" .. arg_53_0.maxNum)
		arg_53_0:updateNum()
	end
end

function var_0_0.decreaseCurrentNum(arg_54_0)
	if arg_54_0:judgeIfCanBet() then
		if arg_54_0.currentNum - 1 <= 0 then
			arg_54_0.currentNum = 1
		else
			arg_54_0.currentNum = arg_54_0.currentNum - 1
		end

		arg_54_0:nodeByName("txt_num"):setString(arg_54_0.currentNum .. "/" .. arg_54_0.maxNum)
		arg_54_0:updateNum()
	end
end

function var_0_0.updateNum(arg_55_0)
	arg_55_0:nodeByName("txt_num"):setString(arg_55_0.currentNum .. "/" .. arg_55_0.maxNum)
end

function var_0_0.inputboxEventHandler(arg_56_0, arg_56_1)
	if arg_56_1 == "return" then
		local var_56_0 = arg_56_0.chatBox_:getText()

		arg_56_0.chatBox_:setText("")

		local var_56_1 = xyd.getTextLen(var_56_0)
		local var_56_2 = math.floor(tonumber(var_56_0) or 0)

		arg_56_0:nodeByName("txt_num"):setVisible(true)

		if var_56_0 ~= "" then
			if var_56_2 then
				if var_56_2 <= arg_56_0.maxNum and var_56_2 > 0 then
					arg_56_0.currentNum = var_56_2

					arg_56_0:updateNum()
				else
					local var_56_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_56_3
					})

					return
				end

				return
			else
				local var_56_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_56_4
				})

				return
			end
		else
			return
		end
	elseif arg_56_1 == "began" then
		arg_56_0.chatBox_:setText("")
		arg_56_0:nodeByName("txt_num"):setVisible(false)
	end
end

function var_0_0.didClose(arg_57_0)
	if arg_57_0.handler then
		if arg_57_0.handler[1] then
			var_0_9.unscheduleGlobal(arg_57_0.handler[1])
		end

		if arg_57_0.handler[2] then
			var_0_9.unscheduleGlobal(arg_57_0.handler[2])
		end

		if arg_57_0.handler[3] then
			var_0_9.unscheduleGlobal(arg_57_0.handler[3])
		end
	end

	arg_57_0.handler = {}
end

function var_0_0.initMatchInfo(arg_58_0)
	arg_58_0.macthStartTime = {}
	arg_58_0.macthEndTime = {}

	for iter_58_0 = 1, 21 do
		arg_58_0.macthStartTime[iter_58_0] = var_0_6:startTime(iter_58_0)
		arg_58_0.macthEndTime[iter_58_0] = var_0_6:endTime(iter_58_0)
	end

	arg_58_0.time = xyd.ServerTime.get():getServerTime() - arg_58_0.startTime

	arg_58_0:updateMatchInfo(arg_58_0.time)

	arg_58_0.handler[3] = var_0_9.scheduleGlobal(function()
		arg_58_0.time = arg_58_0.time + 1

		arg_58_0:updateMatchInfo(arg_58_0.time)
	end, 1)
end

function var_0_0.updateMatchInfo(arg_60_0, arg_60_1)
	if arg_60_0.reloadMatchStateTime then
		arg_60_0.reloadMatchStateTime = arg_60_0.reloadMatchStateTime + 1

		if arg_60_0.reloadMatchStateTime >= 2 then
			arg_60_0:reloadMatchState()

			arg_60_0.reloadMatchStateTime = nil
		end
	end

	local var_60_0 = 0
	local var_60_1 = true

	arg_60_0:nodeByName("bet_stop_count_down"):setVisible(false)
	arg_60_0:nodeByName("last_match_bet_txt"):setVisible(false)
	arg_60_0:nodeByName("next_match_bet_txt"):setVisible(false)
	arg_60_0:nodeByName("bet_count_down"):setVisible(false)
	arg_60_0:nodeByName("refresh"):setVisible(false)
	arg_60_0:nodeByName("left_odd_container"):setVisible(false)
	arg_60_0:nodeByName("right_odd_container"):setVisible(false)

	if not arg_60_0.vsEffect then
		local var_60_2 = "skeletons/ui_effect/activity_fish_fight/duizhantubiao"

		arg_60_0.vsEffect = xyd.createEffect(var_60_2)

		arg_60_0.vsEffect:addTo(arg_60_0:nodeByName("fish_battle_container"))

		local var_60_3 = arg_60_0:nodeByName("fish_battle_container"):getContentSize()

		arg_60_0.vsEffect:setAnchorPoint(0.5, 0.5)
		arg_60_0.vsEffect:setPosition(cc.p(var_60_3.width / 2, var_60_3.height / 2))
		arg_60_0.vsEffect:play(nil, true, nil, "texiao02")
	end

	local var_60_4 = false

	for iter_60_0 = 1, 21 do
		if arg_60_1 > arg_60_0.macthStartTime[iter_60_0] and arg_60_1 < arg_60_0.macthEndTime[iter_60_0] + 600 then
			arg_60_0.nowMatchCount = iter_60_0

			if not arg_60_0.preMatchCount then
				arg_60_0.showMatchCount = arg_60_0.nowMatchCount
				arg_60_0.preMatchCount = arg_60_0.nowMatchCount

				arg_60_0:nodeByName("match_txt"):setString(var_0_6:name(iter_60_0) .. "：")
				arg_60_0:updateRightContainer()
			elseif arg_60_0.preMatchCount ~= arg_60_0.nowMatchCount then
				arg_60_0:nodeByName("match_txt"):setString(var_0_6:name(iter_60_0) .. "：")
			end

			if arg_60_1 < arg_60_0.macthEndTime[iter_60_0] + 300 then
				local var_60_5 = arg_60_0.macthEndTime[iter_60_0] + 300 - arg_60_1

				arg_60_0:nodeByName("match_time_txt"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_3"), string.format(xyd.secondsToString1(var_60_5))))

				var_60_1 = false
			else
				arg_60_0:nodeByName("match_time_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_4"))

				var_60_1 = false
			end

			var_60_4 = true

			break
		end
	end

	if not var_60_4 then
		for iter_60_1 = 1, 20 do
			if arg_60_1 > arg_60_0.macthStartTime[iter_60_1] and arg_60_1 <= arg_60_0.macthEndTime[iter_60_1] + 2110 then
				arg_60_0.nowMatchCount = iter_60_1 + 1

				if not arg_60_0.preMatchCount then
					arg_60_0.showMatchCount = arg_60_0.nowMatchCount
					arg_60_0.preMatchCount = arg_60_0.nowMatchCount

					arg_60_0:nodeByName("match_txt"):setString(var_0_6:name(arg_60_0.nowMatchCount) .. "：")
					arg_60_0:updateRightContainer()
				elseif arg_60_0.preMatchCount ~= arg_60_0.nowMatchCount then
					arg_60_0:nodeByName("match_txt"):setString(var_0_6:name(arg_60_0.nowMatchCount) .. "：")
				end

				if arg_60_1 < arg_60_0.macthEndTime[arg_60_0.nowMatchCount] + 300 then
					local var_60_6 = arg_60_0.macthEndTime[arg_60_0.nowMatchCount] + 300 - arg_60_1

					arg_60_0:nodeByName("match_time_txt"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_3"), string.format(xyd.secondsToString1(var_60_6))))

					var_60_1 = false

					break
				end

				arg_60_0:nodeByName("match_time_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_4"))

				var_60_1 = false

				break
			end
		end
	end

	arg_60_0.round = math.ceil(arg_60_0.nowMatchCount / 7)
	arg_60_0.stage = arg_60_0.nowMatchCount - (arg_60_0.round - 1) * 7

	if var_60_1 and not arg_60_0.preMatchCount then
		arg_60_0.nowMatchCount = 21
		arg_60_0.showMatchCount = arg_60_0.nowMatchCount
		arg_60_0.preMatchCount = arg_60_0.nowMatchCount

		arg_60_0:nodeByName("match_txt"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_5"))
		arg_60_0:nodeByName("match_time_txt"):setVisible(false)
		arg_60_0:updateRightContainer()
	end

	if arg_60_1 > arg_60_0.macthStartTime[arg_60_0.showMatchCount] and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.showMatchCount] then
		local var_60_7 = arg_60_0.macthEndTime[arg_60_0.showMatchCount] - arg_60_1

		arg_60_0:nodeByName("bet_stop_count_down"):setVisible(true)
		arg_60_0:nodeByName("bet_stop_count_down"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_6"), string.format(xyd.secondsToString1(var_60_7))))
	elseif arg_60_1 >= arg_60_0.macthEndTime[arg_60_0.showMatchCount] and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.showMatchCount] + 300 then
		local var_60_8 = arg_60_0.macthEndTime[arg_60_0.showMatchCount] - arg_60_1

		arg_60_0:nodeByName("bet_stop_count_down"):setVisible(true)
		arg_60_0:nodeByName("bet_stop_count_down"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_26"))
	end

	if arg_60_1 > arg_60_0.macthStartTime[arg_60_0.showMatchCount] then
		local var_60_9 = arg_60_0.macthEndTime[arg_60_0.showMatchCount] - arg_60_1

		arg_60_0:nodeByName("refresh"):setVisible(true)
		arg_60_0:nodeByName("left_odd_container"):setVisible(true)
		arg_60_0:nodeByName("right_odd_container"):setVisible(true)
	end

	if arg_60_1 < arg_60_0.macthStartTime[arg_60_0.showMatchCount] then
		local var_60_10 = arg_60_0.macthStartTime[arg_60_0.showMatchCount] - arg_60_1

		arg_60_0:nodeByName("bet_count_down"):setVisible(true)
		arg_60_0:nodeByName("bet_count_down"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_7"), string.format(xyd.secondsToString1(var_60_10))))
	end

	if arg_60_0.showMatchCount > 1 and arg_60_1 > arg_60_0.macthStartTime[arg_60_0.showMatchCount - 1] and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.showMatchCount - 1] then
		arg_60_0:nodeByName("last_match_bet_txt"):setVisible(true)
	else
		arg_60_0:nodeByName("last_match_bet_txt"):setVisible(false)
	end

	if arg_60_0.showMatchCount < 21 and arg_60_1 > arg_60_0.macthStartTime[arg_60_0.showMatchCount + 1] and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.showMatchCount + 1] then
		arg_60_0:nodeByName("next_match_bet_txt"):setVisible(true)
	else
		arg_60_0:nodeByName("next_match_bet_txt"):setVisible(false)
	end

	if arg_60_1 > arg_60_0.macthEndTime[arg_60_0.showMatchCount] + 310 and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.showMatchCount] + 600 then
		arg_60_0:nodeByName("bg_vs"):setVisible(false)
		arg_60_0:nodeByName("watch_match"):setVisible(true)
		arg_60_0:nodeByName("watch_match_txt"):setVisible(true)
		arg_60_0.vsEffect:play(nil, true, nil, "texiao02")
		arg_60_0.vsEffect:show()
	else
		arg_60_0:nodeByName("bg_vs"):setVisible(true)
		arg_60_0:nodeByName("watch_match"):setVisible(false)
		arg_60_0:nodeByName("watch_match_txt"):setVisible(false)
		arg_60_0.vsEffect:stop()
		arg_60_0.vsEffect:hide()
	end

	if arg_60_1 > arg_60_0.macthEndTime[arg_60_0.nowMatchCount] + 300 and arg_60_1 < arg_60_0.macthEndTime[arg_60_0.nowMatchCount] + 600 then
		-- block empty
	elseif not arg_60_0.firstIn then
		arg_60_0.firstIn = true
	end

	arg_60_0:updateBetBtn()
end

function var_0_0.activityBroadcast_(arg_61_0, arg_61_1)
	local var_61_0 = {
		time = 7
	}
	local var_61_1 = arg_61_1.params.msg
	local var_61_2 = var_0_10:getIDByActivityID(var_61_1.activity_id)
	local var_61_3

	if not var_61_1.activity_id then
		local var_61_4 = 1
	elseif type(var_61_2) ~= "table" then
		local var_61_5 = var_0_10:haveCD(var_61_2)
	else
		local var_61_6 = var_0_10:haveCD(var_61_2[1])
	end

	if var_61_1.activity_id == xyd.Activities.FISH then
		if arg_61_0.firstIn then
			local var_61_7 = var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_8")
			local var_61_8 = {
				lcallback = function()
					arg_61_0.reloadMatchStateTime = 0
				end
			}

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_61_7, function()
				local var_63_0 = {
					round = arg_61_0.round,
					stage = arg_61_0.stage
				}

				xyd.Backend.get():request(xyd.mid.FISH_FIGHT_REPORT, var_63_0, function(arg_64_0, arg_64_1)
					if arg_64_0 == xyd.error.OK then
						if arg_64_1 == nil or not next(arg_64_1) then
							if xyd.WindowManager.get():getWindow("toast") ~= nil then
								xyd.WindowManager.get():closeWindow("toast")
							end

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
							})
						else
							arg_61_0:replayRecord(arg_64_1)
						end
					end

					if callback then
						callback(arg_64_0, arg_64_1)
					end
				end)
			end, var_61_8, nil, xyd.ColorMode.BLUE)
		end

		arg_61_0.firstIn = false
	end
end

function var_0_0.reloadMatchState(arg_65_0)
	xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_GET_INFO, params, function(arg_66_0, arg_66_1)
		if arg_66_0 == xyd.error.OK then
			arg_65_0.fightInfo = arg_66_1.fish_fight_info
			arg_65_0.baseInfo = arg_65_0.fightInfo.base_info
			arg_65_0.playerInfo = arg_65_0.fightInfo.player_info
			arg_65_0.stageInfo = arg_65_0.fightInfo.stage_info
			arg_65_0.gameInfo = arg_65_0.fightInfo.game_info

			arg_65_0:updateRightContainer()
		end

		if callback then
			callback(arg_66_0, arg_66_1)
		end
	end)
end

function var_0_0.updateRightContainer(arg_67_0)
	arg_67_0:nodeByName("last_match_txt"):setVisible(true)
	arg_67_0:nodeByName("next_match_txt"):setVisible(true)
	arg_67_0:nodeByName("arrow_left"):setVisible(true)
	arg_67_0:nodeByName("arrow_right"):setVisible(true)
	arg_67_0:nodeByName("now_match_txt"):setString(var_0_6:name(arg_67_0.showMatchCount))

	if arg_67_0.showMatchCount > 1 and arg_67_0.showMatchCount < 21 then
		arg_67_0:nodeByName("last_match_txt"):setString(var_0_6:name(arg_67_0.showMatchCount - 1))
		arg_67_0:nodeByName("next_match_txt"):setString(var_0_6:name(arg_67_0.showMatchCount + 1))
	elseif arg_67_0.showMatchCount == 1 then
		arg_67_0:nodeByName("next_match_txt"):setString(var_0_6:name(arg_67_0.showMatchCount + 1))
		arg_67_0:nodeByName("last_match_txt"):setVisible(false)
		arg_67_0:nodeByName("arrow_left"):setVisible(false)
	elseif arg_67_0.showMatchCount == 21 then
		arg_67_0:nodeByName("last_match_txt"):setString(var_0_6:name(arg_67_0.showMatchCount - 1))
		arg_67_0:nodeByName("next_match_txt"):setVisible(false)
		arg_67_0:nodeByName("arrow_right"):setVisible(false)
	end

	arg_67_0.showRound = math.ceil(arg_67_0.showMatchCount / 7)
	arg_67_0.showStage = arg_67_0.showMatchCount - (arg_67_0.showRound - 1) * 7
	arg_67_0.showWinSide = 0

	local var_67_0 = var_0_8:getValue("activity_fish_gambling_initial_gold")
	local var_67_1 = var_0_8:getValue("activity_fish_gambling_commision")

	if arg_67_0.baseInfo[arg_67_0.showRound] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][1] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][1].fish_id then
		arg_67_0.leftFishId = arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][1].fish_id
		arg_67_0.leftFishBet = arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][1].bet
	else
		arg_67_0.leftFishId = 0
		arg_67_0.leftFishBet = var_67_0
	end

	if arg_67_0.baseInfo[arg_67_0.showRound] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][2] and arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][2].fish_id then
		arg_67_0.rightFishId = arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][2].fish_id
		arg_67_0.rightFishBet = arg_67_0.baseInfo[arg_67_0.showRound][arg_67_0.showStage][2].bet
	else
		arg_67_0.rightFishId = 0
		arg_67_0.rightFishBet = var_67_0
	end

	if arg_67_0.gameInfo[arg_67_0.showRound] and arg_67_0.gameInfo[arg_67_0.showRound][arg_67_0.showStage] then
		arg_67_0.showWinSide = arg_67_0.gameInfo[arg_67_0.showRound][arg_67_0.showStage]
	end

	local var_67_2 = 0
	local var_67_3 = 0

	if arg_67_0.leftFishId ~= 0 and arg_67_0.rightFishId ~= 0 then
		local var_67_4 = var_0_4:score(arg_67_0.leftFishId)
		local var_67_5 = var_0_4:score(arg_67_0.rightFishId)
		local var_67_6 = var_67_4 / var_67_5
		local var_67_7 = var_67_5 / var_67_4

		if arg_67_0.leftFishBet == var_67_0 and arg_67_0.rightFishBet == var_67_0 then
			var_67_2 = 1 + 1 / (var_67_6 * var_67_6 * var_67_6 * var_67_6 * var_67_6 * var_67_6)
			var_67_3 = 1 + 1 / (var_67_7 * var_67_7 * var_67_7 * var_67_7 * var_67_7 * var_67_7)
		else
			var_67_2 = 1 + arg_67_0.rightFishBet * (1 - var_67_1) / arg_67_0.leftFishBet
			var_67_3 = 1 + arg_67_0.leftFishBet * (1 - var_67_1) / arg_67_0.rightFishBet
		end
	end

	arg_67_0:nodeByName("left_peilv_name"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_9"), string.format("%.2f", var_67_2)))
	arg_67_0:nodeByName("right_peilv_name"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_9"), string.format("%.2f", var_67_3)))
	arg_67_0:nodeByName("left_silver_num"):setString(arg_67_0.playerInfo[arg_67_0.showRound][arg_67_0.showStage][1])
	arg_67_0:nodeByName("right_silver_num"):setString(arg_67_0.playerInfo[arg_67_0.showRound][arg_67_0.showStage][2])
	arg_67_0:reloadFishSprite()
end

return var_0_0
