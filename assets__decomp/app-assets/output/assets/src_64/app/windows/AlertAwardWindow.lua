local var_0_0 = class("AlertAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = 64

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.title = arg_1_2.name
	arg_1_0.awards = arg_1_2.awards or {}
	arg_1_0.spiritAwards = arg_1_2.spiritAwards or {}
	arg_1_0.type = arg_1_2.type
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.spiritAwards) do
		table.insert(arg_1_0.awards, iter_1_1)
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = xyd.tables.sound:getSound("gain_window_sound")

	audio.playSound(var_2_0, false)
	var_0_0.super.willOpen()
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0:setTouchSwallowEnabled(true)
	arg_2_0:playGuide()
end

function var_0_0.didOpen(arg_3_0)
	var_0_0.super.didOpen()

	arg_3_0.touchArena = display.newNode()

	local var_3_0 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

	arg_3_0.touchArena:pos(-var_3_0.x, -var_3_0.y):addTo(arg_3_0)
	arg_3_0.touchArena:setLocalZOrder(1000)
	arg_3_0.touchArena:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_3_0.touchArena:setTouchEnabled(true)
	arg_3_0.touchArena:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0:stopAction()
		end
	end)
end

function var_0_0.scrollToPos(arg_5_0)
	local var_5_0 = 80 * #arg_5_0.awards
	local var_5_1 = arg_5_0.list:getViewRectInWorldSpace()
	local var_5_2 = 0

	if var_5_0 > var_5_1.height then
		var_5_2 = var_5_0 - var_5_1.height
	end

	if #arg_5_0.awards == 1 then
		var_5_2 = -var_5_1.height / 2 + 60

		arg_5_0.list.touchNode_:setTouchEnabled(false)
	end

	local var_5_3 = arg_5_0.list:getScrollNode()

	var_5_3:setPositionY(var_5_3:getPositionY() + var_5_2)
end

function var_0_0.willClose(arg_6_0)
	var_0_0.super.willClose()

	if arg_6_0.type == "march" then
		arg_6_0:dispatchEvent({
			name = xyd.event.GOT_MARCH_AWARD
		})
	end

	if arg_6_0.actionHandles then
		for iter_6_0, iter_6_1 in ipairs(arg_6_0.actionHandles) do
			var_0_2.unscheduleGlobal(iter_6_1)
		end
	end
end

function var_0_0.didClose(arg_7_0)
	var_0_0.super.didClose()

	if arg_7_0.callback then
		arg_7_0.callback()
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.ALERT_AWARD_CLOSE
	})

	local var_7_0 = xyd.StoryData.get():getGuideID()

	if var_7_0 == xyd.GuideStoryType.GUIDE_MISSION_THREE then
		local var_7_1 = xyd.WindowManager.get():getWindow("map_task")

		if var_7_1 then
			var_7_1:playGuide()
		end
	elseif var_7_0 == xyd.GuideStoryType.ACTIVITY_SIX then
		local var_7_2 = xyd.WindowManager.get():getWindow("activities")

		if var_7_2 then
			var_7_2:playGuide()
		end
	end
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.scrollViewMoved_ = false
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_9_0)
	arg_9_0:nodeByName("text_sure"):setString(var_0_1:translation("CONFIRM_TEXT"))
	arg_9_0:updateTitle()

	local var_9_0 = #arg_9_0.awards

	arg_9_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 460, 250),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_9_0:nodeByName("list_award")):onScroll(handler(arg_9_0, arg_9_0.scrollListener))

	arg_9_0.list:setTouchType(false)

	arg_9_0.action = {}
	arg_9_0.heights = {}
	arg_9_0.delays = {}

	local var_9_1 = 0

	for iter_9_0 = 1, var_9_0 do
		local var_9_2 = arg_9_0.awards[iter_9_0]
		local var_9_3 = cc.Node:create()

		var_9_3:setContentSize(var_0_3, var_0_3)

		if var_9_2.spirit_id and var_9_2.spirit_id > 0 then
			xyd.setHunqiAndAddTips({
				container = var_9_3,
				item = var_9_2
			})
		elseif var_9_2.table_id > 0 then
			xyd.setItemBorder(var_9_3, var_9_2.table_id)
		elseif var_9_2.skin_fragment and var_9_2.skin_fragment > 0 then
			xyd.setItemBorder(var_9_3, -101)
		elseif var_9_2.exp and var_9_2.exp > 0 then
			local var_9_4 = arg_9_0:getAssetIconPath(var_9_2)

			xyd.setSpriteBorder(var_9_3, var_9_4, 1)
		elseif var_9_2.charge and var_9_2.charge > 0 then
			xyd.setItemBorder(var_9_3, -8)
		elseif var_9_2.lucky_star and var_9_2.lucky_star > 0 then
			xyd.setItemBorder(var_9_3, -100, nil, nil, var_9_2.lucky_star)
		else
			local var_9_5 = arg_9_0:getAssetIcon(var_9_2)

			xyd.displaySpriteOnContainer(var_9_5, var_9_3, true)
		end

		local var_9_6 = display.newNode()
		local var_9_7 = arg_9_0.list:newItem()
		local var_9_8 = 80

		var_9_6:addChild(var_9_3)
		var_9_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_3:setPosition(70, 25)

		local var_9_9 = {
			size = 26,
			color = cc.c4b(255, 245, 157, 255)
		}
		local var_9_10 = xyd.AssetLoader:get():loadLabel(var_9_9)

		if var_9_2.table_id < 0 then
			var_9_10:setString("X " .. var_9_2.item_num)
		elseif var_9_2.spirit_id then
			local var_9_11 = xyd.tables.spiritEquip:from(var_9_2.table_id)

			var_9_10:setString(xyd.tables.spiritSuit:name(var_9_11))
		else
			local var_9_12 = xyd.tables.item:name(var_9_2.table_id)

			var_9_10:setString(var_9_12 .. " X " .. var_9_2.item_num)
		end

		var_9_6:addChild(var_9_10)
		var_9_10:setAnchorPoint(cc.p(0, 0.5))
		var_9_10:setPosition(125, 25)

		if xyd.tables.item:inscriptId(var_9_2.table_id) > 0 and var_9_0 == 1 then
			if var_9_2.workType == 1 then
				arg_9_0.title = var_0_1:translation("INSCRIPTION_MAKE_TITLE")
			elseif var_9_2.workType == 2 then
				arg_9_0.title = var_0_1:translation("INSCRIPTION_REDO_TITLE")
			end

			arg_9_0:updateTitle()

			local var_9_13, var_9_14, var_9_15 = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION):getInscriptionAttrLabelText(var_9_2.table_id)
			local var_9_16 = {
				size = 22,
				color = cc.c4b(255, 245, 157, 255)
			}
			local var_9_17 = xyd.AssetLoader:get():loadLabel(var_9_16)

			var_9_17:setString(var_9_13 .. " + " .. var_9_14 .. var_9_15)
			var_9_17:setAnchorPoint(cc.p(0, 0.5))
			var_9_6:addChild(var_9_17)
			var_9_17:setPositionX(141)
			var_9_17:setPositionY(10)
			var_9_10:setPositionX(141)
			var_9_10:setPositionY(40)
			var_9_3:setScale(1.5)
		elseif var_9_0 == 1 then
			var_9_3:setScale(1.5)
			var_9_10:setPositionX(141)
		end

		var_9_6:setContentSize(460, var_9_8)
		var_9_7:addContent(var_9_6)
		var_9_7:setItemSize(460, var_9_8)

		if var_9_0 == 1 then
			var_9_7:setItemSize(460, 100)
		end

		arg_9_0.list:addItem(var_9_7)

		var_9_1 = var_9_1 + xyd.tables.misc.awardShowTime
		arg_9_0.action[iter_9_0] = {}
		arg_9_0.action[iter_9_0].view = var_9_7
		arg_9_0.action[iter_9_0].delay = var_9_1
		arg_9_0.action[iter_9_0].height = var_9_7:getContentSize().height
	end

	arg_9_0:playAction(240)
	arg_9_0:nodeByName("close"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_9_0:nodeByName("close"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_10_0, false)

			if xyd.WindowManager.get():isWindowOpen("alert_award") and arg_9_0.selfPlayer.cloneNum and arg_9_0.selfPlayer.cloneNum ~= 0 then
				xyd.WindowManager.get():closeWindow("alert_award" .. arg_9_0.selfPlayer.cloneNum)

				arg_9_0.selfPlayer.cloneNum = arg_9_0.selfPlayer.cloneNum - 1

				return
			end

			xyd.WindowManager.get():closeWindow(arg_9_0)
		end
	end)
end

function var_0_0.updateTitle(arg_11_0)
	arg_11_0:nodeByName("title_get_award"):setVisible(false)
	arg_11_0:nodeByName("title_get_item"):setVisible(false)
	arg_11_0:nodeByName("title_make"):setVisible(false)
	arg_11_0:nodeByName("title_redo"):setVisible(false)

	if arg_11_0.title == var_0_1:translation("INSCRIPTION_MAKE_TITLE") then
		arg_11_0:nodeByName("title_make"):setVisible(true)
	elseif arg_11_0.title == var_0_1:translation("INSCRIPTION_REDO_TITLE") then
		arg_11_0:nodeByName("title_redo"):setVisible(true)
	elseif arg_11_0.title and arg_11_0.title ~= "" and arg_11_0.title ~= var_0_1:translation("ALERT_AWARD_NAME") then
		arg_11_0:nodeByName("title_get_item"):setVisible(true)
	else
		arg_11_0:nodeByName("title_get_award"):setVisible(true)
	end
end

function var_0_0.playAction(arg_12_0, arg_12_1)
	arg_12_0.list:reload()

	arg_12_0.isend = true
	arg_12_0.actionHandles = {}

	local var_12_0 = -arg_12_1

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.action) do
		var_12_0 = var_12_0 + iter_12_1.height

		if var_12_0 > 0 then
			local var_12_1 = var_12_0

			table.insert(arg_12_0.actionHandles, var_0_2.performWithDelayGlobal(handler(arg_12_0, function()
				transition.moveBy(arg_12_0.list.container, {
					time = 0.2,
					x = 0,
					y = var_12_1
				})
			end), iter_12_1.delay))

			var_12_0 = 0
		end

		iter_12_1.view:setVisible(false)
		table.insert(arg_12_0.actionHandles, var_0_2.performWithDelayGlobal(handler(arg_12_0, function()
			iter_12_1.view:setVisible(true)
			iter_12_1.view:setScale(0)

			local var_14_0 = transition.sequence({
				cc.ScaleTo:create(0.1, 1.1),
				cc.ScaleTo:create(0.1, 1)
			})

			iter_12_1.view:runAction(var_14_0)
		end), iter_12_1.delay))
	end

	local var_12_2 = #arg_12_0.action

	table.insert(arg_12_0.actionHandles, var_0_2.performWithDelayGlobal(handler(arg_12_0, function()
		return
	end), arg_12_0.action[var_12_2].delay))

	if #arg_12_0.awards == 1 then
		arg_12_0:scrollToPos()
	end
end

function var_0_0.stopAction(arg_16_0)
	if arg_16_0.actionHandles then
		for iter_16_0, iter_16_1 in ipairs(arg_16_0.actionHandles) do
			var_0_2.unscheduleGlobal(iter_16_1)
		end
	end

	for iter_16_2, iter_16_3 in ipairs(arg_16_0.action) do
		iter_16_3.view:setVisible(true)
	end

	arg_16_0.touchArena:removeSelf()
	arg_16_0.list:reload()
	arg_16_0:scrollToPos()
end

function var_0_0.getAssetIcon(arg_17_0, arg_17_1)
	if arg_17_1.table_id ~= -1 then
		return
	end

	local var_17_0 = arg_17_0:getAssetIconPath(arg_17_1)

	return xyd.AssetLoader.get():loadSprite(var_17_0)
end

function var_0_0.getAssetIconPath(arg_18_0, arg_18_1)
	local var_18_0

	if arg_18_1.type then
		var_18_0 = xyd.tables.ecoType:getEcoPath(arg_18_1.type)
	else
		for iter_18_0, iter_18_1 in pairs(arg_18_1) do
			if iter_18_0 ~= "table_id" and iter_18_0 ~= "item_num" then
				var_18_0 = xyd.tables.ecoType:getEcoPath(iter_18_0)

				if var_18_0 and var_18_0 ~= "" then
					break
				end
			end
		end
	end

	return var_18_0
end

function var_0_0.playGuide(arg_19_0)
	local var_19_0 = xyd.StoryData.get():getGuideID()

	if var_19_0 == xyd.GuideStoryType.GUIDE_MISSION_TWO or var_19_0 == xyd.GuideStoryType.ACTIVITY_SIX then
		arg_19_0.blockLayer_:setTouchEnabled(false)

		local var_19_1 = arg_19_0:nodeByName("close")
		local var_19_2 = {
			920,
			360
		}
		local var_19_3 = true

		xyd.showGuideWnd(var_19_1, {
			x = 640,
			y = 140
		}, nil, 2, var_19_2, var_19_3)

		if var_19_0 == xyd.GuideStoryType.GUIDE_MISSION_TWO then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_THREE)
			xyd.StoryData.get():persist()
		end
	end
end

function var_0_0.addBlockLayer(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4)
	if arg_20_1 == nil then
		arg_20_1 = cc.c4b(0, 0, 0, 150)
	end

	arg_20_0.blockLayer_ = display.newColorLayer(arg_20_1)

	local var_20_0 = arg_20_0:convertToWorldSpace(cc.p(0, 0))

	arg_20_0.blockLayer_:pos(-var_20_0.x, -var_20_0.y):addTo(arg_20_0, -1)

	local function var_20_1(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended and not arg_20_3 then
			local var_21_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_21_0, false)

			if xyd.WindowManager.get():isWindowOpen("alert_award") then
				dump(arg_20_0.selfPlayer.cloneNum)

				if arg_20_0.selfPlayer.cloneNum and arg_20_0.selfPlayer.cloneNum ~= 0 then
					xyd.WindowManager.get():closeWindow("alert_award" .. arg_20_0.selfPlayer.cloneNum)

					arg_20_0.selfPlayer.cloneNum = arg_20_0.selfPlayer.cloneNum - 1

					return
				end
			end

			xyd.WindowManager.get():closeWindow(arg_20_0.name)
		end

		return true
	end

	local function var_20_2(arg_22_0, arg_22_1)
		if arg_20_4 then
			arg_20_4()
		end

		if not arg_20_3 then
			local var_22_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_22_0, false)

			if xyd.WindowManager.get():isWindowOpen("alert_award") then
				dump(arg_20_0.selfPlayer.cloneNum)

				if arg_20_0.selfPlayer.cloneNum and arg_20_0.selfPlayer.cloneNum ~= 0 then
					xyd.WindowManager.get():closeWindow("alert_award" .. arg_20_0.selfPlayer.cloneNum)

					arg_20_0.selfPlayer.cloneNum = arg_20_0.selfPlayer.cloneNum - 1

					return
				end
			end

			xyd.WindowManager.get():closeWindow(arg_20_0.name)
		end
	end

	if not arg_20_2 then
		arg_20_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_20_0.layerListener:setSwallowTouches(true)
		arg_20_0.layerListener:registerScriptHandler(var_20_1, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_20_0.layerListener:registerScriptHandler(var_20_2, cc.Handler.EVENT_TOUCH_ENDED)
		arg_20_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_20_0.layerListener, arg_20_0.contentView_)
	end
end

return var_0_0
