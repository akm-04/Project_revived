local var_0_0 = class("MakeAccelerateWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.eventCentre = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)
	arg_1_0.backPack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.buildingType = arg_1_2.building_type
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.buildingInfo = arg_1_2.building_info
	arg_1_0.itemID = xyd.tables.misc.eventCentreAccelerateItem

	local var_1_0 = arg_1_0.buildingInfo.make_need_time - (xyd.ServerTime.get():getServerTime() - arg_1_0.buildingInfo.make_start_time)
	local var_1_1 = math.ceil(var_1_0 / xyd.tables.misc.eventCentreAccelerateTime)

	arg_1_0.totalNum = math.min(arg_1_0.backPack:getItemNumByID(arg_1_0.itemID), var_1_1)
	arg_1_0.currentNum = arg_1_0.totalNum
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("total_inscrease_text"):setString(var_0_3:translation("MAKE_INSCREASE_DES"))
	var_0_2.new({
		size = 400
	}):addTo(arg_3_0:nodeByName("pos_line"))
	arg_3_0:initChatBox()
	arg_3_0:updateNum()

	arg_3_0.handler = {}

	arg_3_0:nodeByName("accelerate_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("accelerate_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			if arg_3_0.currentNum <= 0 then
				return
			end

			local var_4_0 = {
				speed_num = arg_3_0.currentNum,
				building_type = arg_3_0.buildingType
			}

			arg_3_0.eventCentre:accelerateMakeItem(var_4_0, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					local var_5_0 = {
						itemID = arg_3_0.itemID,
						itemNum = arg_3_0.currentNum
					}

					arg_3_0.backPack:removeItem(var_5_0)

					if arg_3_0.callback then
						arg_3_0.callback(arg_5_1)
					end

					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
		end
	end)
	xyd.setItemBorder(arg_3_0:nodeByName("icon_container"), arg_3_0.itemID)

	local var_3_0 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_sub.png",
		disabled = "windows/button/btn_sub.png",
		normal = "windows/button/btn_sub.png"
	})

	var_3_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_0:setScale(1, 1)
	var_3_0:addTo(arg_3_0:nodeByName("decrease_pos"))
	var_3_0:setName("jiandian")

	local var_3_1 = false

	var_3_0:onButtonPressed(function(arg_6_0)
		var_3_0:setScale(0.9)

		local var_6_0 = 0

		local function var_6_1()
			var_6_0 = var_6_0 + 0.03

			if arg_3_0.decreaseCurrentNum then
				arg_3_0:decreaseCurrentNum()
			end
		end

		local function var_6_2()
			var_6_0 = var_6_0 + 0.1

			if var_6_0 > 0.5 and var_6_0 <= 4 then
				var_3_1 = true

				if arg_3_0.decreaseCurrentNum then
					arg_3_0:decreaseCurrentNum()
				end
			elseif var_6_0 > 4 then
				arg_3_0.handler[2] = var_0_1.scheduleGlobal(var_6_1, 0.03)

				var_0_1.unscheduleGlobal(arg_3_0.handler[1])
			else
				var_3_1 = false
			end
		end

		var_3_1 = false
		arg_3_0.handler[1] = var_0_1.scheduleGlobal(var_6_2, 0.1)
	end)
	var_3_0:onButtonRelease(function(arg_9_0)
		var_3_0:setScale(1)

		if arg_3_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[1])
		end

		if arg_3_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[2])
		end

		if var_3_1 == false and arg_3_0.decreaseCurrentNum then
			arg_3_0:decreaseCurrentNum()
		end
	end)

	local var_3_2 = cc.ui.UIPushButton.new({
		pressed = "windows/button/btn_add.png",
		disabled = "windows/button/btn_add.png",
		normal = "windows/button/btn_add.png"
	})

	var_3_2:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_2:setScale(1, 1)
	var_3_2:addTo(arg_3_0:nodeByName("increase_pos"))
	var_3_2:setName("jiadian")

	local var_3_3 = false

	var_3_2:onButtonPressed(function(arg_10_0)
		var_3_2:setScale(0.9)

		local var_10_0 = 0

		local function var_10_1()
			var_10_0 = var_10_0 + 0.03

			if arg_3_0.addCurrentNum then
				arg_3_0:addCurrentNum()
			end
		end

		local function var_10_2()
			var_10_0 = var_10_0 + 0.1

			if var_10_0 > 0.5 and var_10_0 <= 4 then
				var_3_3 = true

				if arg_3_0.addCurrentNum then
					arg_3_0:addCurrentNum()
				end
			elseif var_10_0 > 4 then
				arg_3_0.handler[2] = var_0_1.scheduleGlobal(var_10_1, 0.03)

				var_0_1.unscheduleGlobal(arg_3_0.handler[1])
			else
				var_3_3 = false
			end
		end

		var_3_3 = false
		arg_3_0.handler[1] = var_0_1.scheduleGlobal(var_10_2, 0.1)
	end)
	var_3_2:onButtonRelease(function(arg_13_0)
		var_3_2:setScale(1)

		if arg_3_0.handler[1] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[1])
		end

		if arg_3_0.handler[2] ~= nil then
			var_0_1.unscheduleGlobal(arg_3_0.handler[2])
		end

		if var_3_3 == false and arg_3_0.addCurrentNum then
			arg_3_0:addCurrentNum()
		end
	end)
	xyd.nodeEventSample(arg_3_0:nodeByName("btn_max"), nil, function(arg_14_0)
		arg_3_0.currentNum = arg_3_0.totalNum

		arg_3_0:updateNum()
	end)
end

function var_0_0.updateNum(arg_15_0)
	arg_15_0:nodeByName("num_txt"):setString(arg_15_0.currentNum .. "/" .. arg_15_0.totalNum)
	arg_15_0:nodeByName("total_inscrease_txt"):setString(xyd.secondsToString1(arg_15_0.currentNum * xyd.tables.misc.eventCentreAccelerateTime, 3))
end

function var_0_0.addCurrentNum(arg_16_0)
	if arg_16_0.currentNum + 1 >= arg_16_0.totalNum then
		arg_16_0.currentNum = arg_16_0.totalNum
	else
		arg_16_0.currentNum = arg_16_0.currentNum + 1
	end

	arg_16_0:nodeByName("num_txt"):setString(arg_16_0.currentNum .. "/" .. arg_16_0.totalNum)
	arg_16_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_17_0)
	if arg_17_0.currentNum - 1 <= 0 then
		arg_17_0.currentNum = 1

		if arg_17_0.totalNum < 1 then
			arg_17_0.currentNum = 0
		end
	else
		arg_17_0.currentNum = arg_17_0.currentNum - 1
	end

	arg_17_0:updateNum()
end

function var_0_0.initChatBox(arg_18_0)
	local var_18_0 = xyd.AssetLoader.get()
	local var_18_1 = 24
	local var_18_2 = arg_18_0:nodeByName("num_panel")
	local var_18_3 = "windows/login/transparent.png"
	local var_18_4 = var_18_0:loadSprite(var_18_3)

	arg_18_0.chatBox_ = ccui.EditBox:create(var_18_2:getContentSize(), var_18_3)

	arg_18_0.chatBox_:setAnchorPoint(0, 0)
	arg_18_0.chatBox_:pos(0, 0):addTo(var_18_2)
	arg_18_0.chatBox_:setFont(var_18_0.FONT_NAME, var_18_1)
	arg_18_0.chatBox_:setPlaceholderFont(var_18_0.FONT_NAME, var_18_1)
	arg_18_0.chatBox_:setPlaceHolder(var_0_3:translation("CHAT_INPUT_MESSAGE"))
	arg_18_0.chatBox_:setPlaceholderFontColor(xyd.color.FONT_K)
	arg_18_0.chatBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_18_0.chatBox_:registerScriptEditBoxHandler(handler(arg_18_0, arg_18_0.inputboxEventHandler))
	arg_18_0.chatBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_19_0, arg_19_1)
	if arg_19_1 == "return" then
		local var_19_0 = arg_19_0.chatBox_:getText()

		arg_19_0.chatBox_:setText("")

		local var_19_1 = xyd.getTextLen(var_19_0)
		local var_19_2 = math.floor(tonumber(var_19_0) or 0)

		arg_19_0:nodeByName("num_txt"):setVisible(true)

		if var_19_0 ~= "" then
			if var_19_2 then
				if var_19_2 <= arg_19_0.totalNum and var_19_2 > 0 then
					arg_19_0.currentNum = var_19_2

					arg_19_0:updateNum()
				else
					local var_19_3 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_19_3
					})

					return
				end

				return
			else
				local var_19_4 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_19_4
				})

				return
			end
		else
			return
		end
	elseif arg_19_1 == "began" then
		arg_19_0:nodeByName("num_txt"):setVisible(false)
		arg_19_0.chatBox_:setText("")
	end
end

function var_0_0.didOpen(arg_20_0, arg_20_1)
	var_0_0.super:didOpen(arg_20_1)
	arg_20_0:addBlockLayer()
end

function var_0_0.didClose(arg_21_0)
	if arg_21_0.handler then
		if arg_21_0.handler[1] then
			var_0_1.unscheduleGlobal(arg_21_0.handler[1])
		end

		if arg_21_0.handler[2] then
			var_0_1.unscheduleGlobal(arg_21_0.handler[2])
		end
	end
end

return var_0_0
