local var_0_0 = class("WndLeftSidebar", import("app.common.ui.BaseWidget"))
local var_0_1 = import("app.common.ui.CommonButton")
local var_0_2 = import("app.common.ui.SidebarTabButton")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.isBounceable = arg_1_2.isBounceable or false
	arg_1_0.colorMode = arg_1_2.colorMode or xyd.ColorMode.BLUE

	if arg_1_0.colorMode <= 0 then
		arg_1_0.colorMode = xyd.ColorMode.BLUE
	end

	arg_1_0.spaceX = arg_1_2.spaceX or 10
	arg_1_0.spaceY = arg_1_2.spaceY or 30
	arg_1_0.btnList = {}
	arg_1_0.tabBtns = {}

	arg_1_0:init()
end

function var_0_0.init(arg_2_0)
	return
end

function var_0_0.createSidebarList(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.list:setAnchorPoint(1, 0)
	arg_3_0.list:setBounceable(arg_3_0.isBounceable)

	local var_3_2 = xyd.tables.systemColor:btnImgs(arg_3_0.colorMode)
	local var_3_3 = {
		normal_img = var_3_2[1],
		pressed_img = var_3_2[2],
		disabled_img = var_3_2[3],
		titleSize = arg_3_2 or 24,
		titleColor = arg_3_3 or "#343637"
	}

	for iter_3_0, iter_3_1 in ipairs(arg_3_1) do
		var_3_3.title = iter_3_1
		arg_3_0.btnList[iter_3_0] = var_0_1.new(var_3_3)
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.btnList) do
		local var_3_4 = display.newNode()
		local var_3_5 = arg_3_0.list:newItem()

		iter_3_3:setAnchorPoint(0, 0)
		iter_3_3:setPosition(arg_3_0.spaceX, arg_3_0.spaceY - 5)
		iter_3_3:addTo(var_3_4)
		var_3_4:setContentSize(arg_3_0:nodeByName("list"):getWidth(), iter_3_3:getHeight() + arg_3_0.spaceY)
		var_3_5:addContent(var_3_4)

		if arg_3_4 and next(arg_3_4) and arg_3_4[iter_3_2] == false then
			var_3_5:setItemSize(arg_3_0:nodeByName("list"):getWidth(), 0.01)
			var_3_5:setVisible(false)
		else
			var_3_5:setItemSize(arg_3_0:nodeByName("list"):getWidth(), iter_3_3:getHeight() + arg_3_0.spaceY)
		end

		arg_3_0.list:addItem(var_3_5)
	end

	arg_3_0.list:reload()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.onRegister(arg_5_0)
	arg_5_0:registerButton()
end

function var_0_0.registerButton(arg_6_0, arg_6_1)
	if not arg_6_0.btnList or not next(arg_6_0.btnList) then
		return
	end

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.btnList) do
		iter_6_1:addTouchEvent(function(arg_7_0)
			if arg_7_0.name == "ended" then
				for iter_7_0, iter_7_1 in ipairs(arg_6_0.btnList) do
					if iter_7_0 == iter_6_0 then
						iter_7_1:setBrightStyle(xyd.ButtonStyle.HIGHLIGHT)
					else
						iter_7_1:setBrightStyle(xyd.ButtonStyle.NORMAL)
					end
				end
			end

			if arg_6_1 then
				arg_6_1(iter_6_0, arg_7_0)
			end
		end)
	end
end

function var_0_0.getButtonList(arg_8_0)
	return arg_8_0.btnList
end

function var_0_0.getBtnByIdx(arg_9_0, arg_9_1)
	return arg_9_0.btnList[arg_9_1]
end

function var_0_0.hideBtnByIdx(arg_10_0, arg_10_1)
	arg_10_0:setBtnVisible(arg_10_1, false)
end

function var_0_0.setBtnVisible(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_0.btnList and arg_11_0.btnList[arg_11_1] then
		arg_11_0.btnList[arg_11_1]:setVisible(arg_11_2)

		if not arg_11_2 then
			arg_11_0.btnList[arg_11_1]:setBrightStyle(xyd.ButtonStyle.DISABLE)
		else
			arg_11_0.btnList[arg_11_1]:setBrightStyle(xyd.ButtonStyle.NORMAL)
		end
	end
end

function var_0_0.addTabBtn(arg_12_0, arg_12_1)
	local var_12_0 = var_0_2.new({
		title = arg_12_1
	})

	table.insert(arg_12_0.tabBtns, var_12_0)
	var_12_0:addTo(arg_12_0:background())
	var_12_0:setPosition(0, 40 + (#arg_12_0.tabBtns - 1) * 52)
	var_12_0:switch(xyd.TabButtonType.OFF)

	return var_12_0
end

function var_0_0.getTabBtns(arg_13_0)
	return arg_13_0.tabBtns
end

return var_0_0
