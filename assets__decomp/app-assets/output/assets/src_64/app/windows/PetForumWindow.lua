local var_0_0 = class("PetForumWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.viewListItems = arg_1_2.forum_list or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title_txt"):setString(var_0_1:translation("PET_FORUM_TITLE"))
	arg_2_0:nodeByName("txt_left"):setString(var_0_1:translation("SENOIR_FOR"))
	arg_2_0:nodeByName("txt_right"):setString(var_0_1:translation("VIEW"))

	arg_2_0.isWatingMsg = false

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:updateNoCommentsText()

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	if not arg_3_0.viewList then
		arg_3_0.viewList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height - 5),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	else
		arg_3_0.nodeX = arg_3_0.viewList.scrollNode:getPositionX()
		arg_3_0.nodeY = arg_3_0.viewList.scrollNode:getPositionY()

		arg_3_0.viewList:removeAllItems()
	end

	arg_3_0.viewList:setTouchSwallowEnabled(false)
	arg_3_0.scroll:setTouchSwallowEnabled(false)
	arg_3_0.viewList:setDelegate(handler(arg_3_0, arg_3_0.viewListDelegate))
	arg_3_0.viewList:reload()
	arg_3_0:initEditBox()
	arg_3_0:nodeByName("no_comments_text"):setString(var_0_1:translation("PET_VIEW_LIST_BLANK_ALERT"))
	arg_3_0:nodeByName("hero_name_txt"):setString(arg_3_0.hero:getName())

	local var_3_1 = arg_3_0:nodeByName("hero_name_txt"):getPositionX() + arg_3_0:nodeByName("hero_name_txt"):getContentSize().width + 12

	arg_3_0:nodeByName("txt_right"):setPositionX(var_3_1)
	arg_3_0:nodeByName("comment_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_3_0.hero:getPetID() or arg_3_0.hero:getPetID() < 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PET_NOT_COLLECTED")
				})
			else
				local var_4_0 = {
					id = arg_3_0.hero:getPetID(),
					forum_type = xyd.ForumType.Pet,
					comment = arg_3_0.message
				}

				if not arg_3_0.message or arg_3_0.message == "" then
					if xyd.WindowManager.get():isWindowOpen("toast") then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("VIEW_BLANK_ALERT")
					})

					return
				end

				arg_3_0.library:addForumComment(var_4_0, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_3_0:updateViewList()
					end
				end)
			end
		end
	end)
end

function var_0_0.updateViewList(arg_6_0)
	local var_6_0 = {}

	var_6_0.start_pos = 1
	var_6_0.end_pos = 50
	var_6_0.forum_type = xyd.ForumType.Pet
	var_6_0.table_id = arg_6_0.hero:getTableID()

	arg_6_0.library:queryForumByPage(var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0 == xyd.error.OK and arg_7_1.comments then
			arg_6_0.viewListItems = arg_7_1.comments or {}

			arg_6_0:updateNoCommentsText()
			arg_6_0.viewList:reload()
		end
	end)
end

function var_0_0.updateNoCommentsText(arg_8_0)
	if #arg_8_0.viewListItems == 0 then
		arg_8_0:nodeByName("no_comments_text"):setVisible(true)
	else
		arg_8_0:nodeByName("no_comments_text"):setVisible(false)
	end
end

function var_0_0.viewListDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.viewListItems
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0
		local var_9_1 = arg_9_0.viewList:dequeueItem()

		if not var_9_1 then
			var_9_1 = arg_9_0.viewList:newItem()
		else
			var_9_1:removeAllChildren(false)
		end

		local var_9_2 = arg_9_0:createListContent(arg_9_0.viewListItems[arg_9_3])
		local var_9_3 = var_9_2:getWidth()
		local var_9_4 = var_9_2:getHeight()

		var_9_1:setItemSize(var_9_3, var_9_4)
		var_9_1:addContent(var_9_2)

		if not tolua.isnull(var_9_2:getChildByName("source")) then
			local var_9_5 = var_9_2:getChildByName("source"):getChildByName("container"):getChildByName("best")

			if arg_9_3 == 1 or arg_9_3 == 2 then
				var_9_5:setVisible(true)
			else
				var_9_5:setVisible(false)
			end
		end

		return var_9_1
	end
end

function var_0_0.createListContent(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()

	if not arg_10_1 then
		var_10_0:setContentSize(0, 0)

		return var_10_0
	end

	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/senior_forum/item.csb")
	local var_10_2 = var_10_1:getChildByName("container")
	local var_10_3 = {
		avatar_id = arg_10_1.avatar_id,
		avatar_frame_id = arg_10_1.avatar_frame_id,
		playerInfo = arg_10_1
	}

	xyd.setPlayerAvatar(var_10_2:getChildByName("avtar_container"), var_10_3)
	var_10_2:getChildByName("avtar_container"):setScale(0.9)
	var_10_2:getChildByName("vote_num"):setString(arg_10_1.like)

	if arg_10_1.conquer_lev and arg_10_1.conquer_lev > 0 then
		xyd.setConquerLev(arg_10_1.conquer_lev, var_10_2:getChildByName("player_lev_txt"), var_10_2:getChildByName("dengjiquan"), nil, nil, nil, nil, arg_10_1.conquer_loop_id)
	else
		var_10_2:getChildByName("player_lev_txt"):setString(arg_10_1.player_lev)
	end

	var_10_2:getChildByName("player_name_txt"):setString(arg_10_1.player_name)
	var_10_2:getChildByName("hero_lev_txt"):setString("LV:" .. arg_10_1.pet_lev)
	var_10_2:getChildByName("hero_lev_txt"):setColor(xyd.color.HERO_QUALITY[arg_10_1.pet_color])
	var_10_2:getChildByName("hero_name_txt"):setString(arg_10_0.hero:getName() .. xyd.Color2Level[arg_10_1.pet_color])
	var_10_2:getChildByName("hero_name_txt"):setColor(xyd.color.HERO_QUALITY[arg_10_1.pet_color])
	var_10_2:getChildByName("domain_txt"):setString("S" .. arg_10_1.region)

	if arg_10_1.pet_color == 1 then
		var_10_2:getChildByName("hero_lev_txt"):setColor(cc.c3b(130, 97, 91))
		var_10_2:getChildByName("hero_name_txt"):setColor(cc.c3b(130, 97, 91))
	end

	for iter_10_0 = 1, xyd.HERO_TOTAL_STARS do
		if iter_10_0 > arg_10_1.pet_star then
			var_10_2:getChildByName("hero_star_" .. iter_10_0):setVisible(false)
		else
			var_10_2:getChildByName("hero_star_" .. iter_10_0):setVisible(true)
		end
	end

	local var_10_4 = arg_10_0:createDescLabel(arg_10_1.comment, cc.c3b(68, 68, 91))

	var_10_4:setAnchorPoint(cc.p(0, 1))
	var_10_4:addTo(var_10_2)
	var_10_4:setPosition(var_10_2:getChildByName("desc_pos"):getPosition())

	if arg_10_1.is_commented == 1 then
		var_10_2:getChildByName("click_btn1"):setOpacity(0)
		var_10_2:getChildByName("click_btn2"):setVisible(true)
	else
		var_10_2:getChildByName("click_btn1"):setOpacity(255)
		var_10_2:getChildByName("click_btn2"):setVisible(false)
	end

	var_10_2:getChildByName("click_btn1"):setTouchEnabled(true)
	var_10_2:getChildByName("click_btn1"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			var_10_2:getChildByName("click_btn1"):setScale(0.9)
			var_10_2:getChildByName("click_btn2"):setScale(0.9)

			return true
		elseif arg_11_0.name == "ended" then
			var_10_2:getChildByName("click_btn1"):setScale(1)
			var_10_2:getChildByName("click_btn2"):setScale(1)
			xyd.playButtonSound()

			if arg_10_0.isWatingMsg == true then
				return
			end

			arg_10_0.isWatingMsg = true

			local var_11_0 = {
				player_id = arg_10_1.player_id,
				table_id = arg_10_1.table_id,
				forum_type = xyd.ForumType.Pet
			}

			arg_10_0.library:addForumLike(var_11_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					local var_12_0 = var_0_1:translation("CLICK_LIKE_SUCCEED")

					if xyd.WindowManager.get():isWindowOpen("toast") then
						xyd.WindowManager.get():closeWindow("toast")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_12_0
					})

					arg_10_0.viewListItems = arg_12_1.comments or {}

					arg_10_0.viewList:reload()
				end

				arg_10_0.isWatingMsg = false
			end)
		end
	end)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function var_0_0.createDescLabel(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = {
		size = 20,
		color = arg_13_2 or cc.c3b(255, 255, 255)
	}
	local var_13_1 = xyd.AssetLoader.get():loadLabel(var_13_0)

	var_13_1:setMaxLineWidth(330)
	var_13_1:setLineBreakWithoutSpace(true)
	var_13_1:setString(arg_13_1)

	return var_13_1
end

function var_0_0.didOpen(arg_14_0, arg_14_1)
	var_0_0.super:didOpen(arg_14_1)
end

function var_0_0.initEditBox(arg_15_0)
	arg_15_0:nodeByName("edit_desc"):setString("")

	local var_15_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_15_0, cc.rect(28, 28, 1, 1))

	arg_15_0.editbox_ = ccui.EditBox:create(cc.size(830, 51), var_15_0)

	arg_15_0:nodeByName("edit_container"):addChild(arg_15_0.editbox_)
	arg_15_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_15_0.editbox_:setPosition(0, 0)
	arg_15_0.editbox_:registerScriptEditBoxHandler(handler(arg_15_0, arg_15_0.inputboxEventHandler))
	arg_15_0.editbox_:setInputFlag(3)

	if not arg_15_0.message or arg_15_0.message == "" then
		arg_15_0:nodeByName("edit_desc"):setString(var_0_1:translation("PET_VIEW_MSG"))
		arg_15_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
	else
		arg_15_0:nodeByName("edit_desc"):setString(arg_15_0.message)
		arg_15_0:nodeByName("edit_desc"):setColor(cc.c3b(144, 116, 100))
	end
end

function var_0_0.inputboxEventHandler(arg_16_0, arg_16_1)
	if arg_16_1 == "began" then
		if not arg_16_0.message or arg_16_0.message == "" then
			arg_16_0:nodeByName("edit_desc"):setString("")
		else
			arg_16_0.editbox_:setText(arg_16_0:nodeByName("edit_desc"):getString())
			arg_16_0:nodeByName("edit_desc"):setString("")
		end
	end

	if arg_16_1 == "return" then
		local var_16_0 = arg_16_0.editbox_:getText()

		if var_16_0 == "" then
			arg_16_0.message = ""

			arg_16_0:nodeByName("edit_desc"):setString(var_0_1:translation("PET_VIEW_MSG"))
			arg_16_0:nodeByName("edit_desc"):setColor(cc.c3b(185, 185, 185))
		else
			if xyd.utf8len(var_16_0) > 32 then
				var_16_0 = xyd.getTextstr(var_16_0, 1, 32)
			end

			arg_16_0.message = var_16_0

			arg_16_0:nodeByName("edit_desc"):setString(var_16_0)
			arg_16_0:nodeByName("edit_desc"):setColor(cc.c3b(144, 116, 100))
		end

		arg_16_0.editbox_:setText("")
		arg_16_0.editbox_:setVisible(true)
	end
end

function var_0_0.scrollListener(arg_17_0, arg_17_1)
	if arg_17_1.name == "began" then
		arg_17_0.scrollViewMoved_ = false
		arg_17_0.prevX_ = arg_17_1.x
	elseif arg_17_1.name == "moved" and 20 <= math.abs(arg_17_1.x - arg_17_0.prevX_) then
		arg_17_0.scrollViewMoved_ = true
	end
end

return var_0_0
