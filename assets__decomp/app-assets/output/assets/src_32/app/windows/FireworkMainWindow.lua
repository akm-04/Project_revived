local var_0_0 = class("FireworkMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityFireworkFever
local var_0_4 = xyd.tables.activityFireworkType
local var_0_5 = "skeletons/ui_effect/activity_firework/yanhua0"
local var_0_6 = import("app.common.ui.SpineEffect")
local var_0_7 = 90
local var_0_8 = 20
local var_0_9 = 5
local var_0_10 = 50
local var_0_11 = 0.1
local var_0_12 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.awardTips = nil
	arg_1_0.itemTips = nil
	arg_1_0.heatLev = 1
	arg_1_0.showFireworkIndex = 0
	arg_1_0.showFireworkID = nil
	arg_1_0.showFireworkType = nil
	arg_1_0.handler = {}
	arg_1_0.handlerFire = {}
	arg_1_0.handlerFireCount = {}
	arg_1_0.fireworkPos = {}
	arg_1_0.fireworkEffect = {}
	arg_1_0.fireworkCountTime = {}
	arg_1_0.showFireworkHandle = nil
	arg_1_0.showFireworkTable = {}
	arg_1_0.totalShot = 10
	arg_1_0.fireworkModel = xyd.ModelManager.get():loadModel(xyd.ModelType.FIREWORK)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:loadActivityInfo()
	arg_2_0:layout()
	arg_2_0:initBtnClickEvent()
	arg_2_0:initLoadingBar()
	arg_2_0.player:loadBackpack(arg_2_0:initSelfFirework())
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:showFirework()
end

function var_0_0.updateWindow(arg_4_0)
	arg_4_0.startClick = false
	arg_4_0.showFireworkType = nil
	arg_4_0.showFireworkID = nil
	arg_4_0.showFireworkPlayerName = nil

	arg_4_0:nodeByName("remain_photo_time"):setString(string.format(var_0_2:translation("FIREWORK_TEXT_PHOTOGRAPHY"), arg_4_0.canshotTimes))
	arg_4_0:showFirework()
end

function var_0_0.loadActivityInfo(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.fireworkModel:loadActivityInfo(arg_5_1, arg_5_2)
end

function var_0_0.layout(arg_6_0)
	local var_6_0 = arg_6_0.fireworkModel.activity.details

	arg_6_0.canshotTimes = arg_6_0.totalShot - arg_6_0.fireworkModel.activity.details.photo_times

	arg_6_0:nodeByName("text_container"):setVisible(false)
	arg_6_0:nodeByName("bg_camera"):setVisible(false)
	arg_6_0:nodeByName("text_exchange_num"):setString(var_6_0.exchange_ticket)
	arg_6_0:nodeByName("remain_photo_time"):setString(string.format(var_0_2:translation("FIREWORK_TEXT_PHOTOGRAPHY"), arg_6_0.canshotTimes))

	local var_6_1 = cc.p(arg_6_0:nodeByName("left_container"):getPosition())
	local var_6_2 = cc.p(arg_6_0:nodeByName("firework_show"):getPosition())
	local var_6_3 = arg_6_0:nodeByName("firework_show"):getContentSize()
	local var_6_4 = display.newNode()

	var_6_4:setContentSize(var_6_3.width, var_6_3.height)
	var_6_4:setAnchorPoint(cc.p(0, 0))
	var_6_4:setName("fire_space")
	var_6_4:setPosition(cc.p(var_6_1.x + var_6_2.x, var_6_1.y + var_6_2.y))

	local var_6_5 = xyd.AssetLoader:get():loadSprite("windows/firework/firework_main/firewrok_mask.png")

	var_6_5:setPosition(cc.p(0, 0))
	var_6_5:setAnchorPoint(cc.p(0, 0))

	local var_6_6 = cc.ClippingNode:create()

	var_6_6:setStencil(var_6_5)
	var_6_6:setInverted(true)
	var_6_6:setAlphaThreshold(0)
	var_6_6:setName("fire_clip")
	arg_6_0:nodeByName("left_container"):addChild(var_6_6)
	var_6_6:setPosition(cc.p(-var_6_1.x, -var_6_1.y))
	var_6_6:addChild(var_6_4)
end

function var_0_0.checkShotIsSuccess(arg_7_0)
	local var_7_0 = {}

	for iter_7_0 = 1, var_0_9 do
		if arg_7_0.fireworkCountTime[iter_7_0] then
			table.insert(var_7_0, arg_7_0.fireworkCountTime[iter_7_0])
		end
	end

	local var_7_1 = {
		fire_id = arg_7_0.showFireworkID or 0,
		fire_times = var_7_0
	}

	arg_7_0.fireworkModel:takePhoto(var_7_1, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.fireworkModel.activity.details = arg_8_1.details

			arg_7_0:layout()
			arg_7_0:clear()

			local var_8_0 = {
				isSucc = arg_8_1.is_succ,
				fireType = arg_7_0.showFireworkType,
				sendName = arg_7_0.showFireworkPlayerName,
				callback = function()
					if arg_7_0 and not tolua.isnull(arg_7_0) then
						arg_7_0.canshotTimes = arg_7_0.totalShot - arg_8_1.details.photo_times

						arg_7_0:updateWindow()
					end
				end
			}

			xyd.WindowManager.get():openWindow("firework_result", var_8_0)
		else
			arg_7_0:layout()
			arg_7_0:clear()
			arg_7_0:updateWindow()
		end
	end)
end

function var_0_0.clear(arg_10_0)
	if arg_10_0.handlerFire then
		for iter_10_0 = 1, var_0_9 do
			if arg_10_0.handlerFire[iter_10_0] then
				var_0_1.unscheduleGlobal(arg_10_0.handlerFire[iter_10_0])

				arg_10_0.handlerFire[iter_10_0] = nil
			end
		end
	end

	if arg_10_0.handlerFireCount then
		for iter_10_1 = 1, var_0_9 do
			if arg_10_0.handlerFireCount[iter_10_1] then
				var_0_1.unscheduleGlobal(arg_10_0.handlerFireCount[iter_10_1])

				arg_10_0.handlerFireCount[iter_10_1] = nil
			end
		end
	end

	arg_10_0.fireworkCountTime = {}

	if arg_10_0.broadcastEndHandler_ then
		var_0_1.unscheduleGlobal(arg_10_0.broadcastEndHandler_)

		arg_10_0.broadcastEndHandler_ = nil
	end

	if arg_10_0.showFireworkHandle then
		var_0_1.unscheduleGlobal(arg_10_0.showFireworkHandle)

		arg_10_0.showFireworkHandle = nil
	end

	arg_10_0:nodeByName("text_container"):setVisible(false)

	if arg_10_0.showFireworkHandle then
		var_0_1.unscheduleGlobal(arg_10_0.showFireworkHandle)

		arg_10_0.showFireworkHandle = nil
	end
end

function var_0_0.initBtnClickEvent(arg_11_0)
	arg_11_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("btn_rule"):setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0:nodeByName("btn_rule"):setScale(1)
			arg_11_0:clear()

			local var_12_0 = {
				title_name = "FIREWORK_RULE_TITLE",
				rule = "FIREWORK_RULE_TEXT",
				callback = function()
					arg_11_0:updateWindow()
				end
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_12_0)
		end
	end)
	arg_11_0:nodeByName("btn_firework"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("btn_firework"):setScale(0.9)
		elseif arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0:nodeByName("btn_firework"):setScale(1)
			arg_11_0:clear()

			local var_14_0 = {
				list = arg_11_0.selfFireworkList,
				callback = function()
					arg_11_0:updateWindow()
				end
			}

			xyd.WindowManager.get():openWindow("firework", var_14_0)
		end
	end)
	arg_11_0:nodeByName("btn_exchange"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("btn_exchange"):setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0:nodeByName("btn_exchange"):setScale(1)
			arg_11_0:clear()

			local var_16_0 = {
				exchange_ticket = arg_11_0.fireworkModel.activity.details.exchange_ticket,
				exchange_times = arg_11_0.fireworkModel.activity.details.exchange_times,
				callback = function()
					arg_11_0:updateWindow()
				end
			}

			xyd.WindowManager.get():openWindow("firework_shop", var_16_0)
		end
	end)
	arg_11_0:nodeByName("btn_photo"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.began then
			arg_11_0:nodeByName("btn_photo"):setScale(0.9)
			arg_11_0:nodeByName("bg_camera"):setVisible(true)

			return true
		elseif arg_18_1 == ccui.TouchEventType.ended and not arg_11_0.startClick then
			arg_11_0.startClick = true

			xyd.playButtonSound()
			arg_11_0:nodeByName("btn_photo"):setScale(1)

			;({}).callback = function()
				arg_11_0.startClick = false

				arg_11_0:nodeByName("bg_camera"):setVisible(false)
			end

			if arg_11_0.canshotTimes <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("FIREWORK_TEXT_LIMIT")
				})
				arg_11_0:layout()
				arg_11_0:clear()
				arg_11_0:updateWindow()
			elseif not arg_11_0.showFireworkID then
				arg_11_0.startClick = false

				arg_11_0:nodeByName("bg_camera"):setVisible(false)
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("FIREWORK_TEXT_11")
				})
			else
				arg_11_0:checkShotIsSuccess()
			end
		end
	end)
end

function var_0_0.initItemList(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	arg_20_2:removeAllChildren()

	local var_20_0 = var_0_7 / 2

	for iter_20_0, iter_20_1 in pairs(arg_20_1) do
		local var_20_1 = display.newNode()

		var_20_1:setContentSize(var_0_7, var_0_7)
		var_20_1:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setItemBorder(var_20_1, iter_20_1.itemID, false, false, iter_20_1.itemNum, false, true)
		var_20_1:setPosition(cc.p(var_20_0, var_0_7 / 2))

		if arg_20_3 then
			if iter_20_1.itemNum > 0 then
				local var_20_2 = xyd.AssetLoader:get():loadSprite("windows/common/red_point.png")

				var_20_2:setPosition(cc.p(var_0_7, var_0_7))
				var_20_2:setAnchorPoint(cc.p(0.5, 0.5))
				var_20_1:addChild(var_20_2)
			end

			local var_20_3 = false

			var_20_1:setTouchEnabled(true)
			var_20_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "began" then
					local var_21_0 = 0

					local function var_21_1()
						var_21_0 = var_21_0 + 0.1

						if var_21_0 > 0.5 then
							var_20_3 = true

							if not arg_20_0.itemTips then
								arg_20_0:showItemTips(true, iter_20_1.itemID, iter_20_1.itemNum, var_20_1)
							end
						else
							var_20_3 = false
						end
					end

					var_20_3 = false
					arg_20_0.handler[1] = var_0_1.scheduleGlobal(var_21_1, 0.1)

					return true
				elseif arg_21_0.name == "ended" then
					if arg_20_0.handler and arg_20_0.handler[1] then
						var_0_1.unscheduleGlobal(arg_20_0.handler[1])
					end

					if var_20_3 then
						arg_20_0:showItemTips(false)
					elseif not var_20_3 and iter_20_1.itemNum == 0 then
						local var_21_2 = string.format(var_0_2:translation("FIREWORK_TEXT_9"), var_0_4:name(iter_20_0))

						xyd.WindowManager.get():openWindow("toast", {
							message = var_21_2
						})
					else
						arg_20_0:clear()

						local var_21_3 = {
							id = iter_20_0,
							itemID = iter_20_1.itemID,
							itemNum = iter_20_1.itemNum,
							okCallback = function(arg_23_0)
								arg_20_0:sendFirework(arg_23_0)
							end,
							cancelCallback = function()
								arg_20_0:updateWindow()
							end
						}

						xyd.WindowManager.get():openWindow("send_firework_num", var_21_3)
					end
				end
			end)
		end

		arg_20_2:addChild(var_20_1)

		var_20_0 = var_20_0 + var_0_7 + var_0_8
	end
end

function var_0_0.showItemTips(arg_25_0, arg_25_1, arg_25_2, arg_25_3, arg_25_4)
	if arg_25_1 then
		local var_25_0 = {
			id = arg_25_2,
			hasNum = arg_25_3
		}
		local var_25_1 = xyd.WindowManager.get():getWindow("new_item_tips")
		local var_25_2 = arg_25_4:convertToWorldSpace(cc.p(0, 0))

		if not var_25_1 then
			local var_25_3 = xyd.WindowManager.get():openWindow("new_item_tips", var_25_0)

			xyd.adaptToWorldPosition(arg_25_4, var_25_3)
		end

		return true
	elseif xyd.WindowManager.get():getWindow("new_item_tips") then
		local var_25_4 = xyd.WindowManager.get():closeWindow("new_item_tips")
	end
end

function var_0_0.showAwardTips(arg_26_0, arg_26_1)
	if arg_26_1 then
		if not arg_26_0.awardTips then
			local var_26_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/firework/firework_shop/firework_award_tips.csb")

			var_26_0:addTo(arg_26_0:nodeByName("heat_fields"))

			local var_26_1 = cc.p(arg_26_0:nodeByName("img_gift"):getPosition())
			local var_26_2 = var_26_0:getChildByName("container")

			var_26_0:setPosition(cc.p(var_26_1.x - var_26_2:getContentSize().width, var_26_1.y - var_26_2:getContentSize().height / 2))

			arg_26_0.awardTips = var_26_0
		end

		local var_26_3 = arg_26_0.awardTips:getChildByName("container")

		var_26_3:getChildByName("text_desc"):setString(var_0_2:translation("FIREWORK_TEXT_5"))

		local var_26_4 = var_26_3:getChildByName("award_container")

		if arg_26_0.heatLev == #var_0_3:ids() then
			var_26_3:getChildByName("text_award"):setString(var_0_2:translation("FIREWORK_TEXT_6"))
			var_26_3:getChildByName("text_lev"):setString(string.format(var_0_2:translation("FIREWORK_TEXT_15"), arg_26_0.heatLev))
			var_26_3:getChildByName("text_award"):setPositionY(154)
			var_26_4:setVisible(false)
		else
			var_26_3:getChildByName("text_award"):setString(var_0_2:translation("FIREWORK_TEXT_4"))
			var_26_3:getChildByName("text_lev"):setString(string.format(var_0_2:translation("FIREWORK_TEXT_3"), arg_26_0.heatLev))

			local var_26_5 = var_0_3:gift(arg_26_0.heatLev + 1)
			local var_26_6 = xyd.tables.gift:items(var_26_5)
			local var_26_7 = xyd.tables.gift:mana(var_26_5)
			local var_26_8 = xyd.tables.gift:crystal(var_26_5)
			local var_26_9 = xyd.tables.gift:itemNum(var_26_5)
			local var_26_10 = {}

			for iter_26_0 = 1, #var_26_6 do
				table.insert(var_26_10, {
					itemID = var_26_6[iter_26_0],
					itemNum = var_26_9[iter_26_0]
				})
			end

			if var_26_8 ~= 0 then
				table.insert(var_26_10, {
					itemID = -1,
					itemNum = var_26_8
				})
			end

			if var_26_7 ~= 0 then
				table.insert(var_26_10, {
					itemID = -2,
					itemNum = var_26_7
				})
			end

			arg_26_0:initItemList(var_26_10, var_26_4, false)
		end

		arg_26_0.awardTips:setVisible(true)
	else
		arg_26_0.awardTips:setVisible(false)
	end
end

function var_0_0.initLoadingBar(arg_27_0)
	local var_27_0 = arg_27_0.fireworkModel.activity.details

	arg_27_0.heatLev = var_27_0.lev

	local var_27_1 = var_27_0.fever
	local var_27_2 = var_0_3:totalReq(arg_27_0.heatLev)
	local var_27_3 = var_0_3:feverReq(arg_27_0.heatLev + 1)
	local var_27_4 = var_27_1 - var_27_2

	if arg_27_0.heatLev == #var_0_3:ids() then
		arg_27_0:nodeByName("text_lev"):setString(var_0_2:translation("FIREWORK_LEVEL_MAX"))

		local var_27_5 = var_0_3:feverReq(arg_27_0.heatLev)

		arg_27_0:nodeByName("text_heat_num"):setString(var_27_5 .. "/" .. var_27_5)
		arg_27_0:nodeByName("loading_bar"):setPercent(100)
	else
		arg_27_0:nodeByName("text_lev"):setString(string.format(var_0_2:translation("FIREWORK_LEVEL"), arg_27_0.heatLev))
		arg_27_0:nodeByName("text_heat_num"):setString(var_27_4 .. "/" .. var_27_3)
		arg_27_0:nodeByName("loading_bar"):setPercent(var_27_4 / var_27_3 * 100)
	end

	arg_27_0:nodeByName("img_gift"):setTouchEnabled(true)
	arg_27_0:nodeByName("img_gift"):setTouchSwallowEnabled(false)
	arg_27_0:nodeByName("img_gift"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.began then
			arg_27_0:showAwardTips(true)

			return true
		elseif arg_28_1 == ccui.TouchEventType.ended or arg_28_1 == ccui.TouchEventType.canceled then
			arg_27_0:showAwardTips(false)
		end
	end)
end

function var_0_0.initSelfFirework(arg_29_0)
	local var_29_0 = arg_29_0.player:getBackpack()

	arg_29_0.selfFireworkList = {}

	local var_29_1 = var_0_4:ids()

	for iter_29_0 = 1, #var_29_1 do
		local var_29_2 = var_0_4:itemID(var_29_1[iter_29_0])
		local var_29_3 = var_29_0:getItemNumByID(var_29_2)

		table.insert(arg_29_0.selfFireworkList, {
			itemID = var_29_2,
			itemNum = var_29_3
		})
	end

	local var_29_4 = arg_29_0:nodeByName("self_firework")

	arg_29_0:initItemList(arg_29_0.selfFireworkList, var_29_4, true)
end

function var_0_0.willClose(arg_30_0)
	if arg_30_0.handler and arg_30_0.handler[1] then
		var_0_1.unscheduleGlobal(arg_30_0.handler[1])

		arg_30_0.handler[1] = nil
	end

	if arg_30_0.handlerFire then
		for iter_30_0 = 1, var_0_9 do
			if arg_30_0.handlerFire[iter_30_0] then
				var_0_1.unscheduleGlobal(arg_30_0.handlerFire[iter_30_0])

				arg_30_0.handlerFire[iter_30_0] = nil
			end
		end
	end

	if arg_30_0.broadcastEndHandler_ then
		var_0_1.unscheduleGlobal(arg_30_0.broadcastEndHandler_)

		arg_30_0.broadcastEndHandler_ = nil
	end

	if arg_30_0.showFireworkHandle then
		var_0_1.unscheduleGlobal(arg_30_0.showFireworkHandle)

		arg_30_0.showFireworkHandle = nil
	end
end

function var_0_0.showBroadcast(arg_31_0, arg_31_1)
	local var_31_0 = arg_31_1
	local var_31_1 = arg_31_0:nodeByName("text_container")

	var_31_1:removeAllChildren()

	local var_31_2 = var_31_1:getPositionX()
	local var_31_3 = var_31_1:getPositionY()

	arg_31_0:nodeByName("text_container"):setVisible(true)
	xyd.addRollingWorld(var_31_1, var_31_0.msg, var_31_0.time, "fonts/main_font.ttf", 30, 1.8)

	arg_31_0.broadcastEndHandler_ = var_0_1.scheduleGlobal(function()
		if not arg_31_0 or tolua.isnull(arg_31_0) then
			if arg_31_0.broadcastEndHandler_ then
				var_0_1.unscheduleGlobal(arg_31_0.broadcastEndHandler_)

				arg_31_0.broadcastEndHandler_ = nil
			end

			return
		end

		if arg_31_0.broadcastEndHandler_ then
			var_0_1.unscheduleGlobal(arg_31_0.broadcastEndHandler_)

			arg_31_0.broadcastEndHandler_ = nil

			var_31_1:setVisible(false)
		end
	end, var_31_0.time)
end

function var_0_0.getRandomPos(arg_33_0, arg_33_1)
	local var_33_0 = false
	local var_33_1
	local var_33_2

	while var_33_0 == false do
		var_33_1, var_33_2 = math.random(arg_33_1.width), math.random(arg_33_1.height)

		if not arg_33_0.fireworkPos[var_33_1] then
			arg_33_0.fireworkPos[var_33_1] = var_33_2
			var_33_0 = true
		end
	end

	return var_33_1, var_33_2
end

function var_0_0.updateInfo(arg_34_0, arg_34_1)
	arg_34_0.fireworkModel.activity.details = arg_34_1.details
	arg_34_0.canshotTimes = arg_34_0.totalShot - arg_34_1.details.photo_times

	arg_34_0:nodeByName("text_exchange_num"):setString(arg_34_1.details.exchange_ticket)
	arg_34_0:initLoadingBar()
	arg_34_0:initSelfFirework()
	arg_34_0:updateWindow()
end

function var_0_0.sendFirework(arg_35_0, arg_35_1)
	local var_35_0 = {
		fire_type = arg_35_1.id,
		fire_num = arg_35_1.sendNum
	}

	arg_35_0.fireworkModel:sendFirework(var_35_0, function(arg_36_0, arg_36_1)
		if arg_36_0 == xyd.error.OK then
			arg_35_0.player:getBackpack():setItemNumByID(arg_35_1.itemID, arg_35_1.itemNum - arg_35_1.sendNum)
			arg_35_0:updateInfo(arg_36_1)

			if not arg_35_0.showFireworkHandle then
				arg_35_0:showFirework()
			end
		end
	end)
end

function var_0_0.showFirework(arg_37_0)
	if arg_37_0.showFireworkHandle then
		var_0_1.unscheduleGlobal(arg_37_0.showFireworkHandle)

		arg_37_0.showFireworkHandle = nil
	end

	local var_37_0 = var_0_12

	arg_37_0.showFireworkHandle = var_0_1.scheduleGlobal(function()
		if (not arg_37_0 or tolua.isnull(arg_37_0)) and arg_37_0.showFireworkHandle then
			var_0_1.unscheduleGlobal(arg_37_0.showFireworkHandle)

			arg_37_0.showFireworkHandle = nil
		end

		var_37_0 = var_37_0 - 1

		if var_37_0 <= 0 then
			arg_37_0:clear()
			arg_37_0:showFirework()

			var_37_0 = 10
		end
	end, 1)

	arg_37_0:showFireworkItem()
end

function var_0_0.showFireworkItem(arg_39_0)
	local var_39_0 = arg_39_0.fireworkModel.activity.details.fires
	local var_39_1 = 0

	if var_39_0 and var_39_0[1] then
		arg_39_0.showFireworkID = var_39_0[1].fire_id
		arg_39_0.showFireworkType = var_39_0[1].fire_type
		arg_39_0.showFireworkPlayerName = var_39_0[1].player_name

		for iter_39_0 = 1, var_0_9 do
			local var_39_2 = var_0_5 .. arg_39_0.showFireworkType
			local var_39_3 = var_39_2 .. ".json"
			local var_39_4 = var_39_2 .. ".atlas"

			arg_39_0.fireworkEffect[iter_39_0] = var_0_6.new(var_39_3, var_39_4, 1)

			arg_39_0.fireworkEffect[iter_39_0]:setAnchorPoint(cc.p(0.5, 0.5))

			local var_39_5 = arg_39_0:nodeByName("firework_show"):getContentSize()
			local var_39_6, var_39_7 = arg_39_0:getRandomPos(var_39_5)

			arg_39_0.fireworkEffect[iter_39_0]:setPosition(var_39_6, var_39_7)
			arg_39_0.fireworkEffect[iter_39_0]:addTo(arg_39_0:nodeByName("left_container"):getChildByName("fire_clip"):getChildByName("fire_space"))
			arg_39_0.fireworkEffect[iter_39_0]:setGlobalZOrder(0)

			local var_39_8 = math.random(var_0_10) / 10

			if var_39_1 < var_39_8 then
				var_39_1 = var_39_8
			end

			arg_39_0.handlerFire[iter_39_0] = var_0_1.scheduleGlobal(function()
				if not arg_39_0 or tolua.isnull(arg_39_0) then
					if arg_39_0.handlerFire and arg_39_0.handlerFire[iter_39_0] then
						var_0_1.unscheduleGlobal(arg_39_0.handlerFire[iter_39_0])

						arg_39_0.handlerFire[iter_39_0] = nil
					end

					return
				end

				var_39_8 = var_39_8 - 0.1

				if var_39_8 <= 0 then
					if arg_39_0.handlerFire[iter_39_0] then
						var_0_1.unscheduleGlobal(arg_39_0.handlerFire[iter_39_0])

						arg_39_0.handlerFire[iter_39_0] = nil
					end

					if arg_39_0.fireworkEffect[iter_39_0] then
						arg_39_0:countFireworkTime(iter_39_0, 5)
						arg_39_0.fireworkEffect[iter_39_0]:play(nil, false)
					end
				end
			end, 0.1)
		end

		local var_39_9 = {
			msg = string.format(var_0_2:translation("ACTIVITY_FIREWORK_ANNOUNCE"), arg_39_0.showFireworkPlayerName, var_0_4:name(arg_39_0.showFireworkType)),
			time = var_39_1 + var_0_4:endStage(arg_39_0.showFireworkType)
		}

		arg_39_0:showBroadcast(var_39_9)
		table.remove(arg_39_0.fireworkModel.activity.details.fires, 1)
	elseif arg_39_0.showFireworkHandle then
		var_0_1.unscheduleGlobal(arg_39_0.showFireworkHandle)

		arg_39_0.showFireworkHandle = nil
	end
end

function var_0_0.countFireworkTime(arg_41_0, arg_41_1, arg_41_2)
	if not arg_41_2 or arg_41_2 <= 0 then
		return
	end

	arg_41_0.handlerFireCount[arg_41_1] = var_0_1.scheduleGlobal(function()
		if not arg_41_0 or tolua.isnull(arg_41_0) then
			if arg_41_0.handlerFireCount and arg_41_0.handlerFireCount[arg_41_1] then
				var_0_1.unscheduleGlobal(arg_41_0.handlerFireCount[arg_41_1])

				arg_41_0.handlerFireCount[arg_41_1] = nil
			end

			return
		end

		if arg_41_0.fireworkCountTime and arg_41_0.fireworkCountTime[arg_41_1] then
			arg_41_0.fireworkCountTime[arg_41_1] = arg_41_0.fireworkCountTime[arg_41_1] + var_0_11
		elseif arg_41_0.fireworkCountTime and not arg_41_0.fireworkCountTime[arg_41_1] then
			arg_41_0.fireworkCountTime[arg_41_1] = var_0_11
		end

		arg_41_2 = arg_41_2 - var_0_11

		if arg_41_2 <= 0 and arg_41_0.handlerFireCount and arg_41_0.handlerFireCount[arg_41_1] then
			var_0_1.unscheduleGlobal(arg_41_0.handlerFireCount[arg_41_1])

			arg_41_0.handlerFireCount[arg_41_1] = nil
		end
	end, var_0_11)
end

return var_0_0
