local var_0_0 = class("ChatBubbleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SplitLine")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.chatBubble

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.chatBubble = xyd.ModelManager.get():loadModel(xyd.ModelType.CHAT_BUBBLE)
	arg_1_0.oldBubble = arg_1_0.chatBubble:getBubbleID()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.bubbles = arg_2_0.chatBubble:getBubbles()
	arg_2_0.lockBubbles = arg_2_0.chatBubble:getLockBubbles()

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_3:translation("CHAT_BUBBLE_TEXT_1"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if arg_5_2 == cc.ui.UIListView.COUNT_TAG then
		return 2 + math.ceil(#arg_5_0.bubbles / 2) + math.ceil(#arg_5_0.lockBubbles / 2)
	elseif arg_5_2 == cc.ui.UIListView.CELL_TAG then
		local var_5_0 = arg_5_0.list:dequeueItem()

		if var_5_0 then
			var_5_0:removeAllChildren()
		else
			var_5_0 = arg_5_0.list:newItem()
		end

		local var_5_1 = arg_5_0:createContent(arg_5_3)
		local var_5_2 = var_5_1:getContentSize()

		var_5_0:addContent(var_5_1)
		var_5_0:setItemSize(var_5_2.width, var_5_2.height)

		return var_5_0
	end
end

function var_0_0.createContent(arg_6_0, arg_6_1)
	local var_6_0

	if arg_6_1 == 1 then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_bubble_title.csb")

		local var_6_1 = var_6_0:getChildByName("container")
		local var_6_2 = var_0_2.new({
			size = 216
		})
		local var_6_3 = var_0_2.new({
			size = 216
		})

		var_6_0:setContentSize(var_6_1:getContentSize())
		var_6_1:getChildByName("pos_line_1"):addChild(var_6_2)
		var_6_1:getChildByName("pos_line_2"):addChild(var_6_3)
		var_6_1:getChildByName("txt"):setString(var_0_3:translation("CHAT_BUBBLE_TEXT_2"))
	elseif arg_6_1 <= 1 + math.ceil(#arg_6_0.bubbles / 2) then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_bubble_item.csb")

		local var_6_4 = var_6_0:getChildByName("container")

		var_6_0:setContentSize(var_6_4:getContentSize())

		for iter_6_0 = 1, 2 do
			local var_6_5 = (arg_6_1 - 2) * 2 + iter_6_0
			local var_6_6 = var_6_4:getChildByName("bubble_" .. iter_6_0)

			if not arg_6_0.bubbles[var_6_5] then
				var_6_6:setVisible(false)

				break
			end

			local var_6_7 = var_6_6:getChildByName("bubble"):getChildByName("icon1")

			if arg_6_0.bubbles[var_6_5].id == arg_6_0.chatBubble:getBubbleID() then
				var_6_7:setLocalZOrder(1)
				var_6_7:setVisible(true)
			end

			arg_6_0:setBubble(var_6_6:getChildByName("bubble"), arg_6_0.bubbles[var_6_5].id)
			var_6_6:getChildByName("txt_name"):setString(var_0_4:name(arg_6_0.bubbles[var_6_5].id))
			var_6_6:getChildByName("lock"):setVisible(false)

			local var_6_8 = arg_6_0.bubbles[var_6_5].time

			if var_6_8 and var_6_8 >= 0 then
				var_6_6:getChildByName("txt_name"):setPositionY(19)

				local var_6_9, var_6_10 = arg_6_0:getTime(var_6_8)

				var_6_6:getChildByName("bg_time"):getChildByName("txt_time"):setString(var_0_3:translation("CHAT_BUBBLE_TEXT_5") .. var_6_9 .. var_6_10)
			else
				var_6_6:getChildByName("bg_time"):setVisible(false)
				var_6_6:getChildByName("txt_name"):setPositionY(35)
			end

			var_6_6:getChildByName("bubble"):addTouchEventListener(function(arg_7_0, arg_7_1)
				xyd.buttonScaleAnim(arg_7_0, arg_7_1)

				if arg_7_1 == ccui.TouchEventType.ended then
					if arg_6_0.scrollViewMoved_ then
						return
					end

					arg_6_0.chatBubble:setBubble(arg_6_0.bubbles[var_6_5].id, function()
						arg_6_0:refreshList()
					end)
				end
			end)
		end
	elseif arg_6_1 == 2 + math.ceil(#arg_6_0.bubbles / 2) then
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_bubble_title.csb")

		local var_6_11 = var_6_0:getChildByName("container")
		local var_6_12 = var_0_2.new({
			size = 216
		})
		local var_6_13 = var_0_2.new({
			size = 216
		})

		var_6_0:setContentSize(var_6_11:getContentSize())
		var_6_11:getChildByName("pos_line_1"):addChild(var_6_12)
		var_6_11:getChildByName("pos_line_2"):addChild(var_6_13)
		var_6_11:getChildByName("txt"):setString(var_0_3:translation("CHAT_BUBBLE_TEXT_3"))
	else
		var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_bubble_item.csb")

		local var_6_14 = var_6_0:getChildByName("container")

		var_6_0:setContentSize(var_6_14:getContentSize())

		for iter_6_1 = 1, 2 do
			local var_6_15 = (arg_6_1 - 3 - math.ceil(#arg_6_0.bubbles / 2)) * 2 + iter_6_1
			local var_6_16 = var_6_14:getChildByName("bubble_" .. iter_6_1)

			if not arg_6_0.lockBubbles[var_6_15] then
				var_6_16:setVisible(false)

				break
			end

			arg_6_0:setBubble(var_6_16:getChildByName("bubble"), arg_6_0.lockBubbles[var_6_15])
			var_6_16:getChildByName("txt_name"):setString(var_0_4:name(arg_6_0.lockBubbles[var_6_15]))
			var_6_16:getChildByName("bg_time"):setVisible(false)
			var_6_16:getChildByName("txt_name"):setPositionY(35)
			var_6_16:getChildByName("bubble"):addTouchEventListener(function(arg_9_0, arg_9_1)
				xyd.buttonScaleAnim(arg_9_0, arg_9_1)

				if arg_9_1 == ccui.TouchEventType.ended then
					if arg_6_0.scrollViewMoved_ then
						return
					end

					local var_9_0 = var_0_4:desc(arg_6_0.lockBubbles[var_6_15])

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_0
					})
				end
			end)
		end
	end

	return var_6_0
end

function var_0_0.refreshList(arg_10_0)
	arg_10_0.bubbles = arg_10_0.chatBubble:getBubbles()
	arg_10_0.lockBubbles = arg_10_0.chatBubble:getLockBubbles()

	arg_10_0.list:refreshList()
end

function var_0_0.setBubble(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1:getContentSize()
	local var_11_1 = var_0_4:capInsets(arg_11_2)
	local var_11_2 = {
		41,
		-37
	}
	local var_11_3 = {
		37,
		25,
		37,
		24
	}
	local var_11_4 = cc.size(var_11_0.width + var_11_3[1] + var_11_3[3], var_11_0.height + var_11_3[2] + var_11_3[4])
	local var_11_5 = xyd.SpriteLoader.new("images/bubble/arrow/" .. arg_11_2 .. ".png", nil, nil, xyd.DefaultImageType.BUBBLE_ARROW)
	local var_11_6 = xyd.SpriteLoader.new("images/bubble/bg/" .. arg_11_2 .. ".png", cc.rect(var_11_1[1], var_11_1[2], var_11_1[3], var_11_1[4]), {
		size = var_11_4
	}, xyd.DefaultImageType.BUBBLE_BG)

	var_11_6:setAnchorPoint(0, 0)
	var_11_6:setPosition(-var_11_3[1], -var_11_3[2])
	var_11_5:setAnchorPoint(1, 1)
	var_11_5:setPosition(var_11_2[1] - var_11_3[1], var_11_0.height + var_11_3[4] + var_11_2[2])
	arg_11_1:addChild(var_11_6)
	arg_11_1:addChild(var_11_5)

	local var_11_7 = {
		size = 22,
		color = cc.c3b(96, 99, 131),
		text = var_0_3:translation("CHAT_BUBBLE_TEXT_4"),
		x = var_11_0.width / 2,
		y = var_11_0.height / 2
	}
	local var_11_8 = xyd.AssetLoader.get():loadLabel(var_11_7)

	var_11_8:setAnchorPoint(0.5, 0.5)
	arg_11_1:addChild(var_11_8)
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	if arg_12_1.name == "began" then
		arg_12_0.scrollViewMoved_ = false
		arg_12_0.preY_ = arg_12_1.y
	elseif arg_12_1.name == "ended" and math.abs(arg_12_0.preY_ - arg_12_1.y) > 10 then
		arg_12_0.scrollViewMoved_ = true
	end
end

function var_0_0.getTime(arg_13_0, arg_13_1)
	local var_13_0 = math.ceil(arg_13_1 / 86400)

	if var_13_0 > 1 then
		return var_13_0, var_0_3:translation("CHAT_BUBBLE_TEXT_6")
	end

	return math.ceil(arg_13_1 % 86400 / 3600), var_0_3:translation("CHAT_BUBBLE_TEXT_7")
end

function var_0_0.willClose(arg_14_0)
	if arg_14_0.oldBubble == arg_14_0.chatBubble:getBubbleID() then
		return
	end

	xyd.Backend.get():enterChatRoom(arg_14_0.selfPlayer.region)
	xyd.Backend.get():enterServiceChatRoom(99999)

	if arg_14_0.selfPlayer.guildID and arg_14_0.selfPlayer.guildID ~= 0 then
		xyd.Backend.get():enterLeagueRoom(arg_14_0.selfPlayer.guildID)
	end
end

return var_0_0
