local var_0_0 = class("ZhangheDollExchangeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.activityZhangheDollShop
local var_0_5 = 50001482

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.btnState = xyd.StorageType.FURNITURE
	arg_1_0.listInfo = {}
	arg_1_0.activity = arg_1_2.details
	arg_1_0.details = arg_1_2.details.details
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	return
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.handle_ then
		var_0_3.unscheduleGlobal(arg_4_0.handle_)

		arg_4_0.handle_ = nil
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_word"):enableOutline(cc.c4b(255, 255, 255, 255), 1)
	arg_5_0:updateTimeCount()

	local var_5_0 = arg_5_0:nodeByName("item_container")
	local var_5_1 = var_5_0:getContentSize()

	arg_5_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1.width, var_5_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.list:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0:updateListInfo()
	arg_5_0.list:reload()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" then
		local var_6_0 = 3

		if var_6_0 <= math.abs(arg_6_1.y - arg_6_0.prevY_) or var_6_0 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
			arg_6_0.scrollViewMoved_ = true
		end
	end
end

function var_0_0.updateListInfo(arg_7_0)
	arg_7_0.listInfo = var_0_4:ids()
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.listInfo
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.list:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.list:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = 445
		local var_8_2 = 165

		var_8_0:setItemSize(var_8_1, var_8_2)

		local var_8_3 = display.newNode()

		var_8_3:setContentSize(var_8_1, 158)
		arg_8_0:initCell(var_8_3, arg_8_3)
		var_8_0:addContent(var_8_3)

		return var_8_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_8_2 then
		-- block empty
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2)
	if arg_9_2 > #arg_9_0.listInfo then
		return
	end

	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1135/zhanghe_doll_item.csb")

	var_9_0:setPosition(0, 0)
	arg_9_1:addChild(var_9_0)

	local var_9_1 = var_9_0:getChildByName("bg")
	local var_9_2 = var_0_4:itemID(arg_9_0.listInfo[arg_9_2])

	xyd.setItemBorder(var_9_1:getChildByName("zhanghe_item"), var_0_5)

	local var_9_3 = var_0_4:buyLimit(arg_9_0.listInfo[arg_9_2])
	local var_9_4 = var_9_3 - arg_9_0.details.is_awarded[arg_9_2]

	if var_9_3 < 0 then
		var_9_1:getChildByName("text_times"):setString(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT3"))
		var_9_1:getChildByName("btn_change"):setTouchEnabled(true)
		var_9_1:getChildByName("btn_change"):setBright(true)
		var_9_1:getChildByName("btn_change"):getChildByName("word1"):setVisible(true)
		var_9_1:getChildByName("btn_change"):getChildByName("word1_gray"):setVisible(false)
	else
		var_9_1:getChildByName("text_times"):setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT2"), var_9_4))

		if var_9_4 > 0 then
			var_9_1:getChildByName("btn_change"):setTouchEnabled(true)
			var_9_1:getChildByName("btn_change"):setBright(true)
			var_9_1:getChildByName("btn_change"):getChildByName("word1"):setVisible(true)
			var_9_1:getChildByName("btn_change"):getChildByName("word1_gray"):setVisible(false)
		else
			var_9_1:getChildByName("btn_change"):setTouchEnabled(false)
			var_9_1:getChildByName("btn_change"):setBright(false)
			var_9_1:getChildByName("btn_change"):getChildByName("word1"):setVisible(false)
			var_9_1:getChildByName("btn_change"):getChildByName("word1_gray"):setVisible(true)
		end
	end

	var_9_1:getChildByName("text_times"):enableOutline(cc.c4b(34, 112, 173, 255), 1)
	var_9_1:getChildByName("text_num"):setString(arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_0_5) .. "/" .. var_0_4:dollCost(arg_9_0.listInfo[arg_9_2]))
	xyd.setItemBorder(var_9_1:getChildByName("item_container"), var_9_2, false, false, var_0_4:itemNum(arg_9_0.listInfo[arg_9_2]))
	var_9_1:getChildByName("btn_change"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_10_0:setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.moved then
			arg_10_0:setScale(1)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_10_0:setScale(1)

			if arg_9_0.activity.is_open == 1 then
				if arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_0_5) < var_0_4:dollCost(arg_9_0.listInfo[arg_9_2]) then
					xyd.WindowManager.get():openWindow("toast", {
						message = xyd.tables.translation:translation("ACTIVITY_ZHANGHE_DOLL_TEXT4")
					})
				else
					local var_10_0 = string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT5"), var_0_4:dollCost(arg_9_0.listInfo[arg_9_2]), var_0_2:name(var_0_5), var_0_2:name(var_9_2))
					local var_10_1 = var_0_4:buyLimit(arg_9_0.listInfo[arg_9_2])
					local var_10_2

					if var_10_1 > 0 then
						var_10_2 = var_10_1 - arg_9_0.details.is_awarded[arg_9_2]
					end

					local var_10_3 = {
						idx = arg_9_2,
						item_index = arg_9_0.listInfo[arg_9_2],
						last_times = var_10_2
					}

					xyd.WindowManager.get():openWindow("zhanghe_doll_detail", var_10_3)
				end
			else
				if xyd.ServerTime.get():getServerTime() < arg_9_0.activity.start_time then
					message = var_0_1:translation("ACTIVITY_NO_OPEN")
				elseif xyd.ServerTime.get():getServerTime() >= arg_9_0.activity.end_time then
					message = var_0_1:translation("ACTIVITY_END")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = message
				})
			end
		end
	end)

	local var_9_5 = display.newNode()

	var_9_5:setContentSize(var_9_1:getChildByName("item_container"):getContentSize())
	var_9_5:addTo(var_9_1:getChildByName("item_container"))
	var_9_5:setAnchorPoint(cc.p(0, 0))

	local var_9_6 = {
		id = var_9_2,
		lev = xyd.tables.item:level(var_9_2)
	}

	if xyd.tables.item:type(var_9_2) == -1 then
		var_9_6.tipsType = 0
		var_9_6.desc1 = xyd.tables.hero:getDes(var_9_2)
	elseif specialItem then
		var_9_6.tipsType = 1
		var_9_6.id = -3
	else
		var_9_6.tipsType = 1
		var_9_6.desc1 = xyd.tables.item:desc1(var_9_2)
		var_9_6.desc2 = xyd.tables.item:desc2(var_9_2)
	end

	var_9_6.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_9_2)
	var_9_6.name = xyd.tables.item:name(var_9_2)

	arg_9_0:addTips(var_9_5, var_9_6)

	local var_9_7 = display.newNode()

	var_9_7:setContentSize(var_9_1:getChildByName("zhanghe_item"):getContentSize())
	var_9_7:addTo(var_9_1:getChildByName("zhanghe_item"))
	var_9_7:setAnchorPoint(cc.p(0, 0))

	local var_9_8 = {
		id = var_0_5,
		lev = xyd.tables.item:level(var_0_5)
	}

	if xyd.tables.item:type(var_0_5) == -1 then
		var_9_8.tipsType = 0
		var_9_8.desc1 = xyd.tables.hero:getDes(var_0_5)
	elseif specialItem then
		var_9_8.tipsType = 1
		var_9_8.id = -3
	else
		var_9_8.tipsType = 1
		var_9_8.desc1 = xyd.tables.item:desc1(var_0_5)
		var_9_8.desc2 = xyd.tables.item:desc2(var_0_5)
	end

	var_9_8.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_0_5)
	var_9_8.name = xyd.tables.item:name(var_0_5)

	arg_9_0:addTips(var_9_7, var_9_8)
end

function var_0_0.updateTimeCount(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("time")

	if arg_11_0.handle_ then
		var_0_3.unscheduleGlobal(arg_11_0.handle_)
	end

	local var_11_1
	local var_11_2 = not arg_11_0.activities:isActivityOpen(xyd.Activities.ZhangheDoll) and 0 or arg_11_0.activity.end_time - xyd.ServerTime.get():getServerTime()

	if var_11_2 <= 0 then
		var_11_2 = 0

		return
	end

	var_11_0:setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT1"), xyd.secondsToString(var_11_2, {
		toText = false
	})))

	arg_11_0.handle_ = var_0_3.scheduleGlobal(function()
		if var_11_0 and not tolua.isnull(var_11_0) then
			var_11_2 = var_11_2 - 1

			var_11_0:setString(string.format(var_0_1:translation("ACTIVITY_ZHANGHE_DOLL_TEXT1"), xyd.secondsToString(var_11_2, {
				toText = false
			})))

			if var_11_2 == 0 and arg_11_0.handle_ then
				var_0_3.unscheduleGlobal(arg_11_0.handle_)

				arg_11_0.handle_ = nil
			end
		elseif arg_11_0.handle_ then
			var_0_3.unscheduleGlobal(arg_11_0.handle_)

			arg_11_0.handle_ = nil
		end
	end, 1)
end

return var_0_0
