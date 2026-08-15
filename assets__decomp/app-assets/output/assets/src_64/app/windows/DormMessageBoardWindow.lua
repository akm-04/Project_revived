local var_0_0 = class("DormMessageBoardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.houseId = arg_1_2.house_id
	arg_1_0.data = arg_1_2.data or {}
	arg_1_0.spaceCommentPage = 1
	arg_1_0.data = arg_1_0.dorm:getCommentInfos(arg_1_0.spaceCommentPage)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_last_comment"):setString(var_0_1:translation("PAGE_UP"))
	arg_3_0:nodeByName("text_next_comment"):setString(var_0_1:translation("PAGE_DOWN"))

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setBounceable(false)
	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:setTouchType(false)
	arg_3_0.scrollList:reload()
	arg_3_0:createSpace()
	arg_3_0:updatePage()
	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("btn_send"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			if not arg_4_0.sendContentText or arg_4_0.sendContentText == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NOT_SEND_NULL_MSG")
				})

				return
			end

			local var_5_0 = arg_4_0.sendContentText

			if not var_5_0 or var_5_0 == "" then
				return false
			end

			local var_5_1 = {
				content = var_5_0,
				house_id = arg_4_0.houseId
			}

			arg_4_0.dorm:commentHouse(var_5_1, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.sendContentText = ""

					arg_4_0.textSendContent:setString(var_0_1:translation("PERSON_ZONE_TIP_COMMENT"))

					arg_4_0.spaceCommentPage = 1
					arg_4_0.data = arg_4_0.dorm:getCommentInfos(arg_4_0.spaceCommentPage)

					arg_4_0.scrollList:reload()
					arg_4_0:updatePage()
				end
			end)
		end
	end)
	arg_4_0:nodeByName("last_comment"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			return true
		elseif arg_7_1 == ccui.TouchEventType.ended then
			if arg_4_0.spaceCommentPage == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PERSON_MSG_START")
				})

				return false
			end

			arg_4_0.spaceCommentPage = arg_4_0.spaceCommentPage - 1
			arg_4_0.data = arg_4_0.dorm:getCommentInfos(arg_4_0.spaceCommentPage)

			arg_4_0.scrollList:reload()
			arg_4_0:updatePage()
		end
	end)
	arg_4_0:nodeByName("next_comment"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			return true
		elseif arg_8_1 == ccui.TouchEventType.ended then
			if arg_4_0.spaceCommentPage == xyd.tables.misc.personCommentPage then
				return false
			end

			if arg_4_0.spaceCommentPage >= arg_4_0.dorm:getMaxCommentPage() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PERSON_MSG_OVER")
				})

				return
			end

			local var_8_0 = {
				pageNum = arg_4_0.spaceCommentPage + 1
			}

			arg_4_0.dorm:getDormCommentList(var_8_0, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					local var_9_0 = arg_4_0.dorm:getCommentInfos(arg_4_0.spaceCommentPage + 1)

					if #var_9_0 > 0 then
						arg_4_0.spaceCommentPage = arg_4_0.spaceCommentPage + 1
						arg_4_0.data = var_9_0

						arg_4_0.scrollList:reload()
						arg_4_0:updatePage()

						return
					end
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PERSON_MSG_OVER")
				})
			end)
		end
	end)
end

function var_0_0.updatePage(arg_10_0)
	arg_10_0:nodeByName("page_txt"):setString(tostring(arg_10_0.spaceCommentPage) .. "/" .. tostring(arg_10_0.dorm:getMaxCommentPage()))
end

function var_0_0.createSpace(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("container")

	arg_11_0.textSendContent = var_11_0:getChildByName("text_send_content")

	arg_11_0.textSendContent:setString(var_0_1:translation("PERSON_ZONE_TIP_COMMENT"))

	local var_11_1 = "windows/login/transparent.png"

	if arg_11_0.dorm:isSelfDorm() then
		var_11_0:getChildByName("img_msg_bg"):setVisible(false)
		var_11_0:getChildByName("edit_bg"):setVisible(false)
		var_11_0:getChildByName("edit_box"):setVisible(false)
		var_11_0:getChildByName("text_send_content"):setVisible(false)
		var_11_0:getChildByName("btn_send"):setVisible(false)
	else
		arg_11_0.sendContentText = ""

		local var_11_2 = var_11_0:getChildByName("edit_box"):getContentSize()

		arg_11_0.sendContent = ccui.EditBox:create(var_11_2, var_11_1)

		var_11_0:getChildByName("edit_box"):addChild(arg_11_0.sendContent)
		arg_11_0.sendContent:setAnchorPoint(cc.p(0, 0))
		arg_11_0.sendContent:setPosition(0, 0)
		arg_11_0.sendContent:registerScriptEditBoxHandler(handler(arg_11_0, arg_11_0.sendContentbox))
		arg_11_0.sendContent:setInputFlag(3)
	end
end

function var_0_0.scrollListDelegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.data
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0
		local var_12_1 = arg_12_0.scrollList:dequeueItem()

		if not var_12_1 then
			var_12_1 = arg_12_0.scrollList:newItem()
		else
			var_12_1:removeAllChildren(true)
		end

		local var_12_2 = arg_12_0:createListContent(arg_12_0.data[arg_12_3])
		local var_12_3 = var_12_2:getWidth()
		local var_12_4 = var_12_2:getHeight()

		var_12_1:setItemSize(var_12_3, var_12_4)
		var_12_1:addContent(var_12_2)

		return var_12_1
	end
end

function var_0_0.createListContent(arg_13_0, arg_13_1)
	local var_13_0 = display.newNode()

	if not arg_13_1 then
		return var_13_0
	end

	local var_13_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/message_board/comment_item.csb")
	local var_13_2 = var_13_1:getChildByName("container")
	local var_13_3 = arg_13_1.from_player_info

	xyd.setPlayerInfoContainer(var_13_2, var_13_3)

	local var_13_4 = var_13_2:getChildByName("btn_del")

	if arg_13_0.dorm:isSelfDorm() then
		var_13_4:getChildByName("img_del"):setVisible(true)
		var_13_4:getChildByName("img_praise"):setVisible(false)
	else
		var_13_4:getChildByName("img_del"):setVisible(false)
		var_13_4:getChildByName("img_praise"):setVisible(true)
	end

	if arg_13_1.is_has_praise == 1 then
		var_13_4:setBrightStyle(ccui.BrightStyle.highlight)
	end

	local var_13_5 = var_13_2:getChildByName("text_content"):getContentSize()
	local var_13_6 = xyd.createLabel(20, cc.c3b(0, 0, 0))

	var_13_6:setWidth(var_13_5.width + 20)
	var_13_6:setPosition(0, var_13_5.height / 2)
	var_13_6:setString(arg_13_1.content)
	var_13_6:setLineBreakWithoutSpace(true)
	var_13_2:getChildByName("text_content"):addChild(var_13_6)

	if arg_13_1.isBest then
		var_13_2:getChildByName("best"):setVisible(true)
	else
		var_13_2:getChildByName("best"):setVisible(false)
	end

	var_13_4:addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = arg_13_1.comment_id

			if arg_13_0.dorm:isSelfDorm() then
				local var_14_1 = var_0_1:translation("PERSON_DEL_COMMENT")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
					local var_15_0 = {
						house_id = arg_13_0.houseId,
						comment_id = var_14_0,
						pageNum = arg_13_0.spaceCommentPage
					}

					arg_13_0.dorm:deleteComment(var_15_0, function(arg_16_0, arg_16_1)
						if arg_16_0 == xyd.error.OK then
							arg_13_0.data = arg_13_0.dorm:getCommentInfos(arg_13_0.spaceCommentPage)

							if arg_13_0.spaceCommentPage > 1 and #arg_13_0.data == 0 then
								arg_13_0.data = arg_13_0.dorm:getCommentInfos(arg_13_0.spaceCommentPage - 1)
								arg_13_0.spaceCommentPage = arg_13_0.spaceCommentPage - 1
							end

							arg_13_0.scrollList:refreshList()
							arg_13_0:updatePage()
						end
					end)
				end, nil, nil, arg_13_0.colorMode)
			else
				local var_14_2 = {
					house_id = arg_13_0.houseId,
					comment_id = var_14_0
				}

				arg_13_0.dorm:praiseComment(var_14_2, function(arg_17_0, arg_17_1)
					if arg_17_0 == xyd.error.OK then
						arg_13_0.data = arg_13_0.dorm:getCommentInfos(arg_13_0.spaceCommentPage)

						arg_13_0.scrollList:refreshList()
						arg_13_0:updatePage()
					end
				end)
			end
		end
	end)
	var_13_1:addTo(var_13_0)
	var_13_1:setAnchorPoint(cc.p(0, 0))
	var_13_0:setContentSize(var_13_2:getContentSize())
	var_13_1:setName("source")

	return var_13_0
end

function var_0_0.updateScrollList(arg_18_0)
	return
end

function var_0_0.sendContentbox(arg_19_0, arg_19_1)
	if arg_19_1 == "began" then
		arg_19_0.sendContent:setText(arg_19_0.sendContentText)
		arg_19_0.textSendContent:setString("")
	elseif arg_19_1 == "return" then
		local var_19_0 = arg_19_0.sendContent:getText()

		if xyd.getTextLenNewTTF(var_19_0) > 30 then
			var_19_0 = xyd.getTextstrNewTTF(var_19_0, 1, 30)
		end

		arg_19_0.sendContentText = var_19_0

		arg_19_0.textSendContent:setString(var_19_0)
		arg_19_0.sendContent:setText("")
		arg_19_0.sendContent:setVisible(true)
	end
end

function var_0_0.scrollListener(arg_20_0, arg_20_1)
	if arg_20_1.name == "began" then
		arg_20_0.scrollViewMoved_ = false
		arg_20_0.prevY_ = arg_20_1.y
	elseif arg_20_1.name == "moved" and 5 <= math.abs(arg_20_1.y - arg_20_0.prevY_) then
		arg_20_0.scrollViewMoved_ = true
	end
end

return var_0_0
