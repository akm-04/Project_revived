local var_0_0 = class("PersonPraiseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.personDisplay = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	arg_1_0.praiseInfos = arg_1_0.personDisplay:getPraiseInfos()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = arg_2_0:nodeByName("list"):getContentSize()

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_0.width, var_2_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0.list:reload()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	return
end

function var_0_0.layout(arg_5_0)
	if #arg_5_0.praiseInfos == 0 then
		arg_5_0:nodeByName("txt_tips"):setVisible(false)
		arg_5_0:nodeByName("bg_hero"):setVisible(true)
		arg_5_0:nodeByName("bg_message"):setVisible(true)
		arg_5_0:nodeByName("txt_message"):setVisible(true)
	else
		arg_5_0:nodeByName("txt_tips"):setString(var_0_1:translation("PERSON_PRAISE_YOU"))
		arg_5_0:nodeByName("bg_hero"):setVisible(false)
		arg_5_0:nodeByName("bg_message"):setVisible(false)
		arg_5_0:nodeByName("txt_message"):setVisible(false)
	end
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = #arg_6_0.praiseInfos

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_0
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		local var_6_1
		local var_6_2
		local var_6_3
		local var_6_4 = arg_6_0.list:dequeueItem()

		if not var_6_4 then
			var_6_4 = arg_6_0.list:newItem()
		else
			var_6_4:removeAllChildren()
		end

		local var_6_5 = display.newNode()

		var_6_5:setTouchSwallowEnabled(false)

		local var_6_6 = display.newNode()

		arg_6_0:initHideCell(var_6_6, arg_6_3)
		var_6_5:addChild(var_6_6)
		var_6_5:setContentSize(cc.size(arg_6_0.list.viewRect_.width, var_6_6:getContentSize().height))
		var_6_4:setItemSize(arg_6_0.list.viewRect_.width, var_6_6:getContentSize().height)
		var_6_4:addContent(var_6_5)

		return var_6_4
	end
end

function var_0_0.initHideCell(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_0.praiseInfos[arg_7_2]
	local var_7_1 = var_7_0.player_info
	local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/praise_item.csb")
	local var_7_3 = var_7_2:getChildByName("container")
	local var_7_4 = var_7_3:getContentSize()

	arg_7_1:setContentSize(var_7_4.width, var_7_4.height)
	var_7_2:addTo(arg_7_1)
	var_7_3:getChildByName("txt_name"):setString(var_7_1.player_name)
	var_7_3:getChildByName("txt_time"):setString(os.date("%c", tonumber(var_7_0.praise_time)))

	if var_7_1.conquer_lev and var_7_1.conquer_lev > 0 then
		xyd.setConquerLev(var_7_1.conquer_lev, var_7_3:getChildByName("txt_lev"), var_7_3:getChildByName("bg_level_circle"), nil, nil, nil, nil, var_7_1.conquer_loop_id)
	else
		var_7_3:getChildByName("txt_lev"):setString(var_7_1.lev)
	end

	var_7_3:getChildByName("txt_server"):setString("S" .. var_7_1.region)

	local var_7_5 = {
		avatar_id = tonumber(var_7_1.avatar_id),
		avatar_frame_id = var_7_1.avatar_frame_id,
		playerInfo = var_7_1
	}

	xyd.setPlayerAvatar(var_7_3:getChildByName("avatar"), var_7_5)
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.is_scroll = false
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" then
		if 10 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
			arg_8_0.scrollViewMoved_ = true
		end

		local var_8_0 = #arg_8_0.personDisplay:getPraiseInfos()

		if var_8_0 < arg_8_0.personDisplay.praiseTotalum then
			if arg_8_0.list:getScrollNode():getPositionY() > var_8_0 * 133 + 25 then
				arg_8_0.is_scroll = true
			else
				arg_8_0.is_scroll = false
			end
		end
	elseif arg_8_1.name == "scrollEnd" and arg_8_0.is_scroll == true then
		arg_8_0.personDisplay:getPraiseList(false, function()
			if arg_8_0.list and arg_8_0.list.getScrollNode and not tolua.isnull(arg_8_0.list) then
				arg_8_0.list:refreshList()

				local var_9_0 = arg_8_0.list:getScrollNode()
				local var_9_1 = var_9_0:getPositionY()

				var_9_0:setPositionY(var_9_1 + 20)
			end
		end)

		arg_8_0.is_scroll = false
	end
end

return var_0_0
