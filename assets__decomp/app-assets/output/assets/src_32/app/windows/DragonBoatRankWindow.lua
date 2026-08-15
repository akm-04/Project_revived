local var_0_0 = class("DragonboatRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation
local var_0_3 = {
	TOP = 0,
	SELF = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.dragonBoatModel = xyd.ModelManager.get():loadModel(xyd.ModelType.DRAGON_BOAT)
	arg_1_0.day_ = 0
	arg_1_0.rightBtns_ = {}
	arg_1_0.infoType_ = var_0_3.TOP
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.willClose(arg_4_0)
	return
end

function var_0_0.didClose(arg_5_0)
	return
end

function var_0_0.layout(arg_6_0)
	arg_6_0:setTexture()
	arg_6_0:getJumpToBtn()
	arg_6_0:getLeftList():reload()

	local var_6_0 = arg_6_0.dragonBoatModel:getRankData(arg_6_0.day_)

	if #arg_6_0.dragonBoatModel:getSelfRankInfos(arg_6_0.day_) < 1 or var_6_0.self_rank <= #var_6_0.rank_list then
		arg_6_0:getJumpToBtn():hide()
	else
		arg_6_0:getJumpToBtn():show()
	end

	if #var_6_0.rank_list < 1 then
		arg_6_0:nodeByName("text_tip"):show()
	else
		arg_6_0:nodeByName("text_tip"):hide()
	end

	arg_6_0:getRightList():reload()
end

function var_0_0.setTexture(arg_7_0)
	local var_7_0 = arg_7_0.dragonBoatModel:getSelfRank(arg_7_0.day_)

	arg_7_0:nodeByName("text_my_rank"):setString(var_7_0.rank)
	arg_7_0:nodeByName("text_my_cost_time"):setString(arg_7_0:getTimeString(var_7_0.cost_time))
	arg_7_0:nodeByName("text_my_name"):setString(var_0_2:translation("DRAGONBOAT_MY_RANK"))
	arg_7_0:nodeByName("text_cost_time_label"):setString(var_0_2:translation("DRAGONBOAT_MY_COST_TIME"))
	arg_7_0:nodeByName("text_tip"):setString(var_0_2:translation("DRAGONBOAT_RANK_LOCKED"))
end

function var_0_0.getLeftList(arg_8_0)
	if not arg_8_0.leftList_ then
		local var_8_0 = arg_8_0:nodeByName("list1"):getWidth()
		local var_8_1 = arg_8_0:nodeByName("list1"):getHeight()

		arg_8_0.leftList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_8_0, var_8_1),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_8_0:nodeByName("list1"))

		arg_8_0.leftList_:setDelegate(handler(arg_8_0, arg_8_0.delegateLeft))
	end

	return arg_8_0.leftList_
end

function var_0_0.getRightList(arg_9_0)
	if not arg_9_0.rightList_ then
		local var_9_0 = arg_9_0:nodeByName("list2"):getWidth()
		local var_9_1 = arg_9_0:nodeByName("list2"):getHeight()

		arg_9_0.rightList_ = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_9_0, var_9_1),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_9_0:nodeByName("list2"))

		arg_9_0.rightList_:setDelegate(handler(arg_9_0, arg_9_0.delegateRight))
	end

	return arg_9_0.rightList_
end

function var_0_0.delegateLeft(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = arg_10_0.dragonBoatModel:getRankData(arg_10_0.day_)
	local var_10_1 = arg_10_0.dragonBoatModel:getSelfRankInfos(arg_10_0.day_)

	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return arg_10_0.infoType_ == var_0_3.TOP and #var_10_0.rank_list or #var_10_1
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_2
		local var_10_3 = arg_10_0.leftList_:dequeueItem()

		if not var_10_3 then
			var_10_3 = arg_10_0.leftList_:newItem()
		else
			var_10_3:removeAllChildren()
		end

		local var_10_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1060/rank/item_content.csb")
		local var_10_5 = arg_10_0.infoType_ == var_0_3.TOP and var_10_0.rank_list[arg_10_3] or var_10_1[arg_10_3]

		arg_10_0:initLeftCell(var_10_4, var_10_5, arg_10_3)
		var_10_3:setItemSize(var_10_4:getWidth(), var_10_4:getHeight())
		var_10_3:addContent(var_10_4)

		return var_10_3
	end
end

function var_0_0.initLeftCell(arg_11_0, arg_11_1, arg_11_2, arg_11_3)
	local var_11_0 = arg_11_2.rank

	arg_11_1:getChildByName("item_back2"):hide()

	local var_11_1 = arg_11_1:getChildByName("item_back2"):getWidth()
	local var_11_2 = arg_11_1:getChildByName("item_back2"):getHeight()

	arg_11_1:size(var_11_1, var_11_2)
	arg_11_1:getChildByName("text_name"):setString(arg_11_2.player_name)
	arg_11_1:getChildByName("text_name"):enableOutline(cc.c4b(44, 70, 64, 255), 2)
	arg_11_1:getChildByName("text_server"):setString("S" .. math.floor(arg_11_2.player_id / 100000))
	arg_11_1:getChildByName("text_time"):setString(arg_11_0:getTimeString(arg_11_2.cost_time))
	xyd.setPlayerAvatar(arg_11_1:getChildByName("avatar"), arg_11_2)

	local var_11_3

	if var_11_0 > 3 then
		var_11_3 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_11_3:setString(arg_11_2.rank)
	else
		var_11_3 = xyd.AssetLoader.get():loadSprite("windows/activities/1060/rank/rank" .. var_11_0 .. ".png")

		var_11_3:scale(0.7)
	end

	var_11_3:addTo(arg_11_1:getChildByName("rank"))

	local var_11_4 = arg_11_1:getChildByName("rank"):getWidth()

	var_11_3:align(display.CENTER, var_11_4 / 2, var_11_4 / 2)
	arg_11_1:setTouchEnabled(true)
	arg_11_1:setTouchSwallowEnabled(false)
	arg_11_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			arg_11_0.prevX_ = arg_12_0.x
			arg_11_0.prevY_ = arg_12_0.y
			arg_11_0.startClick_ = true

			arg_11_1:getChildByName("item_back2"):show()
			arg_11_1:getChildByName("item_back1"):hide()
		elseif arg_12_0.name == "moved" then
			if math.abs(arg_12_0.y - arg_11_0.prevY_) > 5 or math.abs(arg_12_0.x - arg_11_0.prevX_) > 5 then
				arg_11_0.startClick_ = false
			end
		elseif arg_12_0.name == "ended" then
			arg_11_1:getChildByName("item_back1"):show()
			arg_11_1:getChildByName("item_back2"):hide()

			if arg_11_0.startClick_ then
				-- block empty
			end
		end

		return true
	end)
end

function var_0_0.getTimeString(arg_13_0, arg_13_1)
	local var_13_0 = math.floor(arg_13_1)
	local var_13_1 = math.floor(var_13_0 / 60)
	local var_13_2 = var_13_0 % 60
	local var_13_3 = math.floor((arg_13_1 - var_13_0) * 100)

	return (string.format("%02d'%02d\"%02d", var_13_1, var_13_2, var_13_3))
end

function var_0_0.delegateRight(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
	local var_14_0 = 8

	if cc.ui.UIListView.COUNT_TAG == arg_14_2 then
		return var_14_0
	elseif cc.ui.UIListView.CELL_TAG == arg_14_2 then
		local var_14_1
		local var_14_2 = arg_14_0.leftList_:dequeueItem()

		if not var_14_2 then
			var_14_2 = arg_14_0.leftList_:newItem()
		else
			var_14_2:removeAllChildren()
		end

		local var_14_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1060/rank/item_button.csb")

		arg_14_0:initRightCell(var_14_3, data, arg_14_3)
		var_14_2:setItemSize(var_14_3:getWidth(), var_14_3:getHeight())
		var_14_2:addContent(var_14_3)

		return var_14_2
	end
end

function var_0_0.initRightCell(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	arg_15_1:getChildByName("label"):enableOutline(cc.c4b(37, 68, 17, 255), 2)
	arg_15_1:size(arg_15_1:getChildByName("button"):getWidth(), arg_15_1:getChildByName("button"):getHeight())

	local var_15_0 = var_0_2:translation("DRAGONBOAT_TITTLE_TODAY")
	local var_15_1 = var_0_2:translation("DRAGONBOAT_TITTLE_TOTAL")
	local var_15_2 = var_0_2:translation("DRAGONBOAT_TITTLE_WEEKDAY")
	local var_15_3 = xyd.split(var_15_2, ":")

	table.insert(var_15_3, 1, var_15_1)
	arg_15_1:getChildByName("label"):setString(var_15_3[arg_15_3])

	arg_15_0.rightBtns_[arg_15_3] = arg_15_1:getChildByName("button")

	if arg_15_0.day_ == arg_15_3 - 1 then
		arg_15_1:getChildByName("button"):setBrightStyle(ccui.BrightStyle.highlight)
	end

	arg_15_1:getChildByName("button"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()

			arg_15_0.day_ = arg_15_3 - 1
			arg_15_0.infoType_ = var_0_3.TOP

			arg_15_0:getLeftList():reload()

			local var_16_0 = arg_15_0.dragonBoatModel:getRankData(arg_15_0.day_)
			local var_16_1 = arg_15_0.dragonBoatModel:getSelfRankInfos(arg_15_0.day_)
			local var_16_2 = arg_15_0.dragonBoatModel:getSelfRank(arg_15_0.day_)

			arg_15_0:nodeByName("text_my_rank"):setString(var_16_2.rank)
			arg_15_0:nodeByName("text_my_cost_time"):setString(arg_15_0:getTimeString(var_16_2.cost_time))
			arg_15_1:getChildByName("button"):setBrightStyle(ccui.BrightStyle.highlight)

			if #var_16_1 < 1 or var_16_2.rank <= #var_16_0.rank_list then
				arg_15_0:getJumpToBtn():hide()
			else
				arg_15_0:getJumpToBtn():show()
			end

			if #var_16_0.rank_list < 1 then
				arg_15_0:nodeByName("text_tip"):show()
			else
				arg_15_0:nodeByName("text_tip"):hide()
			end

			for iter_16_0, iter_16_1 in ipairs(arg_15_0.rightBtns_) do
				if iter_16_1 and not tolua.isnull(iter_16_1) and iter_16_1 ~= arg_15_1:getChildByName("button") then
					iter_16_1:setBrightStyle(ccui.BrightStyle.normal)
				end
			end
		end
	end)
end

function var_0_0.getJumpToBtn(arg_17_0)
	if not arg_17_0.jumpToBtn_ then
		arg_17_0.jumpToBtn_ = arg_17_0:nodeByName("button_goto")

		arg_17_0.jumpToBtn_:addTouchEventListener(function(arg_18_0, arg_18_1)
			arg_17_0:buttonHandler(arg_17_0.jumpToBtn_, arg_18_1)

			if arg_18_1 == ccui.TouchEventType.ended then
				arg_17_0.infoType_ = var_0_3.SELF

				arg_17_0:getLeftList():reload()
			end
		end)
	end

	return arg_17_0.jumpToBtn_
end

function var_0_0.buttonHandler(arg_19_0, arg_19_1, arg_19_2)
	if not arg_19_1 or not arg_19_1:getParent() then
		return
	end

	if arg_19_2 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_19_1)
		arg_19_1:setScale(1)
	elseif arg_19_2 == ccui.TouchEventType.began then
		local var_19_0 = cc.ScaleTo:create(0.3, 0.8)

		arg_19_1:runAction(var_19_0)

		return true
	elseif arg_19_2 == ccui.TouchEventType.cancled then
		transition.stopTarget(arg_19_1)
		arg_19_1:setScale(1)
	end
end

return var_0_0
