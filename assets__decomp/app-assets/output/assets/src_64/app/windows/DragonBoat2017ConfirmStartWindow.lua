local var_0_0 = class("DragonBoat2017ConfirmStartWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.itemID = arg_1_2.item_id
	arg_1_0.hasNum = arg_1_0.selfPlayer:getBackpack():getItemNumByID(arg_1_0.itemID)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.maxNum = arg_1_0.hasNum
	arg_1_0.currentNum = 1
	arg_1_0.handler = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("img_icon"):removeAllChildren()
	xyd.setItemBorder(arg_4_0:nodeByName("img_icon"), arg_4_0.itemID)
	arg_4_0:nodeByName("name_text"):setString(xyd.tables.item:name(arg_4_0.itemID))
	arg_4_0:nodeByName("has_txt"):setString(var_0_1:translation("ITEM_OWN"))
	arg_4_0:nodeByName("jian_txt"):setString(var_0_1:translation("ITEM_OWN_SUFFIX"))
	arg_4_0:nodeByName("select_txt"):setString(var_0_1:translation("SELECT_NUM"))
	arg_4_0:nodeByName("num_txt"):setString(arg_4_0.hasNum)
	arg_4_0:nodeByName("use_num_txt"):setString(arg_4_0.currentNum .. "/" .. arg_4_0.maxNum)
	arg_4_0:nodeByName("max_txt"):setString(var_0_1:translation("MAX"))
	arg_4_0:nodeByName("use_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.callback then
				arg_4_0.callback(arg_4_0.currentNum)
			end

			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)
	arg_4_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_4_0.name)
		end
	end)

	local var_4_0
	local var_4_1 = cc.ui.UIPushButton.new({
		pressed = "windows/button/-_button2.png",
		disabled = "windows/button/-_button2.png",
		normal = "windows/button/-_button1.png"
	})

	var_4_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_1:setScale(1, 1)
	var_4_1:addTo(arg_4_0:nodeByName("decrease_button"))
	var_4_1:setName("jiandian")

	local var_4_2 = false

	var_4_1:onButtonPressed(function(arg_7_0)
		local var_7_0 = 0

		local function var_7_1()
			var_7_0 = var_7_0 + 0.03

			if arg_4_0.decreaseCurrentNum then
				arg_4_0:decreaseCurrentNum()
			end
		end

		local function var_7_2()
			var_7_0 = var_7_0 + 0.1

			if var_7_0 > 0.5 and var_7_0 <= 4 then
				var_4_2 = true

				if arg_4_0.decreaseCurrentNum then
					arg_4_0:decreaseCurrentNum()
				end
			elseif var_7_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_7_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_2 = false
			end
		end

		var_4_2 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_7_2, 0.1)
	end)
	var_4_1:onButtonRelease(function(arg_10_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_2 == false and arg_4_0.decreaseCurrentNum then
			arg_4_0:decreaseCurrentNum()
		end
	end)

	local var_4_3 = cc.ui.UIPushButton.new({
		pressed = "windows/button/add_button2.png",
		disabled = "windows/button/add_button2.png",
		normal = "windows/button/add_button1.png"
	})

	var_4_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_3:setScale(1, 1)
	var_4_3:addTo(arg_4_0:nodeByName("increase_button"))
	var_4_3:setName("jiadian")

	local var_4_4 = false

	var_4_3:onButtonPressed(function(arg_11_0)
		local var_11_0 = 0

		local function var_11_1()
			var_11_0 = var_11_0 + 0.03

			if arg_4_0.addCurrentNum then
				arg_4_0:addCurrentNum()
			end
		end

		local function var_11_2()
			var_11_0 = var_11_0 + 0.1

			if var_11_0 > 0.5 and var_11_0 <= 4 then
				var_4_4 = true

				if arg_4_0.addCurrentNum then
					arg_4_0:addCurrentNum()
				end
			elseif var_11_0 > 4 then
				arg_4_0.handler[2] = var_0_2.scheduleGlobal(var_11_1, 0.03)

				var_0_2.unscheduleGlobal(arg_4_0.handler[1])
			else
				var_4_4 = false
			end
		end

		var_4_4 = false
		arg_4_0.handler[1] = var_0_2.scheduleGlobal(var_11_2, 0.1)
	end)
	var_4_3:onButtonRelease(function(arg_14_0)
		if arg_4_0.handler[1] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[1])
		end

		if arg_4_0.handler[2] ~= nil then
			var_0_2.unscheduleGlobal(arg_4_0.handler[2])
		end

		if var_4_4 == false and arg_4_0.addCurrentNum then
			arg_4_0:addCurrentNum()
		end
	end)
	arg_4_0:nodeByName("max_button"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_4_0.currentNum = arg_4_0.maxNum

			arg_4_0:updateNum()
		end
	end)
end

function var_0_0.addCurrentNum(arg_16_0)
	if arg_16_0.currentNum + 1 >= arg_16_0.maxNum then
		arg_16_0.currentNum = arg_16_0.maxNum
	else
		arg_16_0.currentNum = arg_16_0.currentNum + 1
	end

	arg_16_0:nodeByName("use_num_txt"):setString(arg_16_0.currentNum .. "/" .. arg_16_0.maxNum)
	arg_16_0:updateNum()
end

function var_0_0.decreaseCurrentNum(arg_17_0)
	if arg_17_0.currentNum - 1 <= 0 then
		arg_17_0.currentNum = 1
	else
		arg_17_0.currentNum = arg_17_0.currentNum - 1
	end

	arg_17_0:nodeByName("use_num_txt"):setString(arg_17_0.currentNum .. "/" .. arg_17_0.maxNum)
	arg_17_0:updateNum()
end

function var_0_0.updateNum(arg_18_0)
	arg_18_0:nodeByName("use_num_txt"):setString(arg_18_0.currentNum .. "/" .. arg_18_0.maxNum)
end

function var_0_0.didClose(arg_19_0)
	if arg_19_0.handler then
		if arg_19_0.handler[1] then
			var_0_2.unscheduleGlobal(arg_19_0.handler[1])
		end

		if arg_19_0.handler[2] then
			var_0_2.unscheduleGlobal(arg_19_0.handler[2])
		end
	end
end

return var_0_0
