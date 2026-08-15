local var_0_0 = class("NoticeMsgWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.data = arg_1_2.data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 20, var_4_0.width, var_4_0.height - 20),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setBounceable(false)
	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.listDelegate))
	arg_4_0.list:setTouchType(false)
	arg_4_0.list:reload()
end

function var_0_0.listDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_0
		local var_5_1 = arg_5_0.list:dequeueItem()

		if not var_5_1 then
			var_5_1 = arg_5_0.list:newItem()
		else
			var_5_1:removeAllChildren(false)
		end

		local var_5_2 = arg_5_0:createListContent(arg_5_0.data[arg_5_3])
		local var_5_3 = var_5_2:getWidth()
		local var_5_4 = var_5_2:getHeight()

		var_5_1:setItemSize(var_5_3, var_5_4)
		var_5_1:addContent(var_5_2)

		return var_5_1
	end
end

function var_0_0.createListContent(arg_6_0, arg_6_1)
	local var_6_0 = display.newNode()
	local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/social_system/manage_friend/notice_msg_item.csb")
	local var_6_2 = var_6_1:getChildByName("container")
	local var_6_3 = var_6_2:getChildByName("name_bg")
	local var_6_4 = {
		avatar_id = arg_6_1.avatar_id,
		avatar_frame_id = arg_6_1.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_6_2:getChildByName("avtar_container"), var_6_4)
	var_6_3:getChildByName("name_txt"):setString(arg_6_1.player_name)
	var_6_3:getChildByName("lev_txt"):setString(arg_6_1.level)
	var_6_2:getChildByName("get_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			-- block empty
		end
	end)
	var_6_1:addTo(var_6_0)
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_0:setContentSize(var_6_2:getContentSize())
	var_6_1:setName("source")

	return var_6_0
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevX_ = arg_8_1.x
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.x - arg_8_0.prevX_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

return var_0_0
