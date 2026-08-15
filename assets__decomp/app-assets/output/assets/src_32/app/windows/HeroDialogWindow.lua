local var_0_0 = class("HeroDialogWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 1000

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.partnerInfo = arg_1_0.library.libraryInfos[arg_1_0.hero:getHeroID()]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")
	arg_2_0.dialogListItems = arg_2_0.partnerInfo.partner_dialogs

	local var_2_0 = arg_2_0.hero:getTableID()

	if arg_2_0.hero:isAwaken() then
		var_2_0 = xyd.tables.hero:beforeAwaken(var_2_0)
	end

	arg_2_0.dialogTable = import("app.common.tables.DialogueTable").new(var_2_0)
	arg_2_0.bg = arg_2_0:nodeByName("bg")

	arg_2_0:setBG()
	arg_2_0:layout()

	local var_2_1 = {
		hero = arg_2_0.hero
	}

	xyd.WindowManager.get():openWindow("library_hero_favor", var_2_1)
end

function var_0_0.setBG(arg_3_0)
	if arg_3_0.bg then
		arg_3_0.bg:removeSelf()
	end

	arg_3_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_3_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_3_0.bg:setAnchorPoint(0, 0)
	arg_3_0.bg:addTo(arg_3_0:nodeByName("container"), -1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.dialogListItems = arg_4_0.partnerInfo.partner_dialogs

	arg_4_0:updateCardContainer()

	arg_4_0.scroll = arg_4_0:nodeByName("scroll")
	arg_4_0.scrollContent = arg_4_0.scroll:getContentSize()

	if not arg_4_0.dialogList then
		arg_4_0.dialogList = cc.ui.UIListView.new({
			async = false,
			viewRect = cc.rect(0, 0, arg_4_0.scrollContent.width, arg_4_0.scrollContent.height),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_4_0.scroll):onScroll(handler(arg_4_0, arg_4_0.scrollListener))
	else
		arg_4_0.nodeX = arg_4_0.dialogList.scrollNode:getPositionX()
		arg_4_0.nodeY = arg_4_0.dialogList.scrollNode:getPositionY()

		arg_4_0.dialogList:removeAllItems()
	end

	arg_4_0.dialogList:setBounceable(false)
	arg_4_0:dialogListLayout()
	arg_4_0:nodeByName("label_name"):setString(arg_4_0.hero:getName())
	arg_4_0:playTalk()
end

function var_0_0.playTalk(arg_5_0)
	arg_5_0:nodeByName("text"):setString("")
	arg_5_0:speak(arg_5_0.dialogTable:getDialog(0), arg_5_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
end

function var_0_0.speak(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = xyd.utf8len(arg_6_1)

	arg_6_0.showInOneTime = false
	arg_6_0.isOnSpeaking = true

	local var_6_1 = 0

	if arg_6_0.handler then
		var_0_1.unscheduleGlobal(arg_6_0.handler)

		arg_6_0.handler = nil
	end

	arg_6_0.handler = var_0_1.scheduleGlobal(function()
		var_6_1 = var_6_1 + 1

		if var_6_1 > var_6_0 and arg_6_0.handler or arg_6_0.showInOneTime == true then
			if not tolua.isnull(arg_6_2) then
				arg_6_2:setString(arg_6_1)
			end

			var_0_1.unscheduleGlobal(arg_6_0.handler)

			arg_6_0.isOnSpeaking = false

			return
		end

		local var_7_0 = xyd.getSplitUtf8Str(arg_6_1, 0, var_6_1 * 3)

		if not tolua.isnull(arg_6_2) then
			arg_6_2:setString(var_7_0)
		end
	end, arg_6_3)
end

function var_0_0.dialogListLayout(arg_8_0)
	for iter_8_0 = 1, #arg_8_0.dialogListItems do
		local var_8_0
		local var_8_1 = arg_8_0.dialogList:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_0.dialogList:newItem()
		else
			var_8_1:removeAllChildren(true)
		end

		local var_8_2 = arg_8_0:createListContent(arg_8_0.dialogListItems[iter_8_0], iter_8_0, var_8_1)
		local var_8_3 = var_8_2:getWidth()
		local var_8_4 = var_8_2:getHeight()

		var_8_1:setItemSize(var_8_3, var_8_4)
		var_8_1:addContent(var_8_2)
		arg_8_0.dialogList:addItem(var_8_1)
		arg_8_0.dialogList:reload()
	end
end

function var_0_0.createListContent(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	local var_9_0 = display.newNode()
	local var_9_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/library/dialog/dialog_item.csb")
	local var_9_2 = var_9_1:getChildByName("container")

	var_9_0:setAnchorPoint(cc.p(0, 0))
	var_9_0:setPosition(0, 0)

	if arg_9_1.is_read == 0 then
		var_9_2:getChildByName("new_txt"):setVisible(true)
	else
		var_9_2:getChildByName("new_txt"):setVisible(false)
	end

	local var_9_3 = arg_9_0.dialogTable:getTitleByIdType(arg_9_1.dialog_id)

	var_9_2:getChildByName("dialog_title_txt"):setString(var_9_3)
	var_9_2:getChildByName("dialog_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended and arg_9_0.scrollViewMoved_ ~= true then
			if arg_9_1.is_read == 0 then
				local var_10_0 = {
					partner_id = arg_9_0.hero:getHeroID(),
					dialog_id = arg_9_1.dialog_id
				}

				arg_9_0.library:readDialog(var_10_0, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						if arg_11_1.dialog then
							arg_9_0.partnerInfo.partner_dialog = arg_11_1.dialog

							if arg_9_1.is_read == 0 then
								arg_9_1.is_read = 1

								var_9_2:getChildByName("new_txt"):setVisible(false)
							end
						end

						arg_9_0.library:playDialog(arg_9_0.hero, arg_9_1)
					else
						arg_9_0.library:playDialog(arg_9_0.hero, arg_9_1)
					end
				end)
			else
				arg_9_0.library:playDialog(arg_9_0.hero, arg_9_1)
			end
		end
	end)
	var_9_1:addTo(var_9_0)
	var_9_1:setAnchorPoint(cc.p(0, 0))
	var_9_0:setContentSize(var_9_2:getContentSize())
	var_9_1:setName("source")

	return var_9_0
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	var_0_0.super:didOpen(arg_12_1)
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.prevY_ = arg_13_1.y
	elseif arg_13_1.name == "moved" and 5 <= math.abs(arg_13_1.y - arg_13_0.prevY_) then
		arg_13_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateCardContainer(arg_14_0)
	arg_14_0.library:updateCardContainer(arg_14_0.hero, arg_14_0.cardContainer, arg_14_0.library.cardState)
end

function var_0_0.didClose(arg_15_0, arg_15_1)
	var_0_0.super.didClose(arg_15_0, arg_15_1)

	if arg_15_0.handler then
		var_0_1.unscheduleGlobal(arg_15_0.handler)

		arg_15_0.handler = nil
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.REFRESH_HERO_VISIT_REDPOINT
	})
	xyd.WindowManager.get():closeWindow("library_hero_favor")
end

return var_0_0
