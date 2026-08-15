local var_0_0 = require("app.utils.creator")

require("app.utils.TableViewPro")

local var_0_1 = class("MainScene", function()
	return display.newScene("MainScene")
end)

function var_0_1.ctor(arg_2_0)
	arg_2_0:TableViewProTest()
end

function var_0_1.CreatorTest(arg_3_0)
	var_0_0.parseJson("creator/main.json"):addTo(arg_3_0)
end

function var_0_1.TableViewTest(arg_4_0)
	local var_4_0 = ccui.ListView:create()

	var_4_0:setBounceEnabled(true)
	var_4_0:setContentSize(cc.size(300, 200))
	var_4_0:center():addTo(arg_4_0)
	var_4_0:setBackGroundColorType(1)
	var_4_0:setBackGroundColor(cc.c3b(0, 100, 0))
	var_4_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_0:setItemsMargin(4)

	local var_4_1 = require("app.utils.TableView")

	local function var_4_2(arg_5_0, arg_5_1)
		return cc.size(300, 15)
	end

	local function var_4_3(arg_6_0, arg_6_1)
		return ccui.Text:create(arg_6_1, "Airal", 18)
	end

	local function var_4_4(arg_7_0, arg_7_1)
		print("do texture unload here:", arg_7_1)
	end

	var_4_1.attachTo(var_4_0, var_4_2, var_4_3, var_4_4)
	var_4_0:initDefaultItems(300)
	var_4_0:jumpTo(300)
	var_4_0:addScrollViewEventListener(function(arg_8_0, arg_8_1)
		print("event:", arg_8_1)
	end)
end

function var_0_1.TableViewProTest(arg_9_0)
	local var_9_0 = 1000
	local var_9_1 = cc.TableView.new(cc.size(100, 400))

	local function var_9_2(arg_10_0, arg_10_1)
		return 100, 100
	end

	local function var_9_3(arg_11_0)
		return var_9_0
	end

	local function var_9_4(arg_12_0, arg_12_1)
		print("loadCell:", arg_12_1)

		local var_12_0 = arg_12_0:dequeueCell()

		if not var_12_0 then
			var_12_0 = cc.TableViewCell.new()

			ccui.Text:create(arg_12_1, "", 50):addTo(var_12_0, 1, 666):align(display.LEFT_BOTTOM, 0, 0):setTextColor(cc.c3b(255, 255, math.random(1, 255)))
		end

		var_12_0:getChildByTag(666):setString(arg_12_1)

		return var_12_0
	end

	local function var_9_5(arg_13_0, arg_13_1)
		print("unloadCell:", arg_13_1)
	end

	var_9_1:setDirection(cc.TableViewDirection.vertical)
	var_9_1:setFillOrder(cc.TableViewFillOrder.topToBottom)
	var_9_1:registerFunc(cc.TableViewFuncType.cellSize, var_9_2)
	var_9_1:registerFunc(cc.TableViewFuncType.cellNum, var_9_3)
	var_9_1:registerFunc(cc.TableViewFuncType.cellLoad, var_9_4)
	var_9_1:registerFunc(cc.TableViewFuncType.cellUnload, var_9_5)
	var_9_1:addTo(arg_9_0):align(display.CENTER, display.cx, display.cy)
	var_9_1:reloadData()

	local var_9_6 = ccui.Text:create("resize tableview", "", 40):addTo(arg_9_0):pos(display.cx, display.cy + 250)

	var_9_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "ended" then
			var_9_0 = 18

			var_9_1:reloadDataInPos()
		end

		return true
	end)
	var_9_6:setTouchEnabled(true)
end

function var_0_1.onEnter(arg_15_0)
	return
end

function var_0_1.onExit(arg_16_0)
	return
end

return var_0_1
