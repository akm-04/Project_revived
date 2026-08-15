local var_0_0 = class("GardenFriendListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	guild = 2,
	friend = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.garden = xyd.ModelManager.get():loadModel(xyd.ModelType.GARDEN)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.visitWay = arg_1_2.visit_type
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
	arg_4_0:updateListInfo()

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")

	local var_4_0 = arg_4_0.scroll:getContentSize()

	arg_4_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.scrollList:setDelegate(handler(arg_4_0, arg_4_0.scrollListDelegate))
	arg_4_0.scrollList:reload()

	if arg_4_0.visitWay == var_0_2.guild then
		arg_4_0:nodeByName("friend"):setVisible(false)
		arg_4_0:nodeByName("guild"):setVisible(true)
	else
		arg_4_0:nodeByName("guild"):setVisible(false)
		arg_4_0:nodeByName("friend"):setVisible(true)
	end
end

function var_0_0.updateListInfo(arg_5_0)
	local var_5_0 = {}

	arg_5_0.data = {}

	if arg_5_0.visitWay == var_0_2.guild then
		var_5_0 = arg_5_0.guild.members
	else
		var_5_0 = arg_5_0.socialSystem.friendlist
	end

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if iter_5_1.player_id ~= arg_5_0.selfPlayer.playerID then
			table.insert(arg_5_0.data, iter_5_1)
		end
	end

	table.sort(arg_5_0.data, function(arg_6_0, arg_6_1)
		if arg_6_0.is_online ~= arg_6_1.is_online then
			return arg_6_0.is_online > arg_6_1.is_online
		else
			return arg_6_0.last_time > arg_6_1.last_time
		end
	end)
end

function var_0_0.scrollListDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_0
		local var_7_1 = arg_7_0.scrollList:dequeueItem()

		if not var_7_1 then
			var_7_1 = arg_7_0.scrollList:newItem()
		else
			var_7_1:removeAllChildren(true)
		end

		local var_7_2 = arg_7_0:createListContent(arg_7_0.data[arg_7_3])
		local var_7_3 = var_7_2:getWidth()
		local var_7_4 = var_7_2:getHeight()

		var_7_1:setItemSize(var_7_3, var_7_4 + 10)
		var_7_1:addContent(var_7_2)

		return var_7_1
	end
end

function var_0_0.createListContent(arg_8_0, arg_8_1)
	local var_8_0 = display.newNode()
	local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/visit/visit_item.csb")
	local var_8_2 = var_8_1:getChildByName("container")

	arg_8_1.playerInfo = arg_8_1

	xyd.setPlayerAvatar(var_8_2:getChildByName("avtar_container"), arg_8_1)

	if arg_8_1.conquer_lev > 0 then
		var_8_2:getChildByName("conquer_lev"):setVisible(true)
		var_8_2:getChildByName("level_bg"):setVisible(false)
		var_8_2:getChildByName("lev_txt"):setString(arg_8_1.conquer_lev)

		local var_8_3 = xyd.getLoopBy(arg_8_1.conquer_lev, arg_8_1.conquer_loop_id)

		if var_8_3 < 2 then
			var_8_3 = ""
		end

		var_8_2:getChildByName("conquer_lev"):setTexture("images/conquer_lev" .. var_8_3 .. ".png")
	else
		var_8_2:getChildByName("conquer_lev"):setVisible(false)
		var_8_2:getChildByName("level_bg"):setVisible(true)
		var_8_2:getChildByName("lev_txt"):setString(arg_8_1.lev)
	end

	if arg_8_0.visitWay == var_0_2.guild then
		var_8_2:getChildByName("name_txt"):setString(arg_8_1.name)
	else
		var_8_2:getChildByName("name_txt"):setString(arg_8_1.player_name)
	end

	var_8_2:getChildByName("visit_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = {
				player_id = arg_8_1.player_id
			}

			arg_8_0.garden:getGardenInfo(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_8_0)
				end
			end)
		end
	end)
	var_8_1:addTo(var_8_0)
	var_8_1:setAnchorPoint(cc.p(0, 0))
	var_8_0:setContentSize(var_8_2:getContentSize())
	var_8_1:setName("source")

	return var_8_0
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 5 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

return var_0_0
