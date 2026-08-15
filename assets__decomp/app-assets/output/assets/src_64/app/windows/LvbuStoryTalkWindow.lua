LvbuStoryTalkWindow = class("LvbuStoryTalkWindow", import("app.common.ui.BaseWindow"))

local var_0_0 = import("framework.scheduler")
local var_0_1 = import("app.model.Hero")
local var_0_2 = 6
local var_0_3 = 5
local var_0_4 = {
	Left = 1,
	Right = 2
}
local var_0_5 = {
	Battle = 2,
	Success = 3,
	Failed = 1,
	Normal = 0
}

function LvbuStoryTalkWindow.ctor(arg_1_0, arg_1_1, arg_1_2)
	LvbuStoryTalkWindow.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
	arg_1_0.talkId = arg_1_2.story_id
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.showSkip = arg_1_2.show_skip
end

function LvbuStoryTalkWindow.checkFileExist(arg_2_0)
	return true
end

function LvbuStoryTalkWindow.willOpen(arg_3_0, arg_3_1)
	LvbuStoryTalkWindow.super.willOpen(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("bg"):setVisible(true)

	arg_3_0.cardContainerLeft = arg_3_0:nodeByName("card_container_left")
	arg_3_0.cardContainerRight = arg_3_0:nodeByName("card_container_right")
	arg_3_0.clickToEnd = false

	if arg_3_0:checkFileExist() then
		arg_3_0.talkTable_ = import("app.common.tables.ActivityLvbuStoryTable").new(arg_3_0.talkId)
		arg_3_0.playingIndex_ = arg_3_1.playing_index or 0
	end

	if arg_3_0:checkFileExist() then
		arg_3_0:layout()
	else
		xyd.WindowManager.get():closeWindow(arg_3_0)
	end
end

function LvbuStoryTalkWindow.didOpen(arg_4_0, arg_4_1)
	LvbuStoryTalkWindow.super.didOpen(arg_4_0, arg_4_1)
end

function LvbuStoryTalkWindow.didClose(arg_5_0, arg_5_1)
	LvbuStoryTalkWindow.super.didClose(arg_5_0, arg_5_1)

	if arg_5_0.handler then
		var_0_0.unscheduleGlobal(arg_5_0.handler)

		arg_5_0.handler = nil
	end

	if arg_5_0.callback then
		arg_5_0.callback()
	end
end

function LvbuStoryTalkWindow.layout(arg_6_0)
	arg_6_0.scroll = arg_6_0:nodeByName("mid")
	arg_6_0.scrollContent = arg_6_0.scroll:getContentSize()
	arg_6_0.optionList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_6_0.scrollContent.width, arg_6_0.scrollContent.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_6_0.scroll):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	arg_6_0.optionList:setDelegate(handler(arg_6_0, arg_6_0.optionListDelegate))
	arg_6_0.optionList:setBounceable(false)
	arg_6_0:nodeByName("name_box2"):setVisible(false)
	arg_6_0:nodeByName("name_box1"):setVisible(false)
	arg_6_0:nodeByName("bottom"):setLocalZOrder(100)

	local var_6_0 = {
		size = 28,
		color = cc.c3b(255, 255, 255)
	}

	arg_6_0.message = arg_6_0:nodeByName("text")

	arg_6_0.message:setAnchorPoint(cc.p(0, 1))

	arg_6_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_6_1 = display.newNode()

	var_6_1:setName("role")
	var_6_1:size(arg_6_0:getContentSize())
	var_6_1:setAnchorPoint(cc.p(0, 0))
	var_6_1:setPosition(cc.p(0, 0))
	var_6_1:addTo(arg_6_0, -1)

	arg_6_0.roleLayer_ = var_6_1

	arg_6_0:setTouchSwallowEnabled(false)

	arg_6_0.touchLayer_ = var_6_1:clone()

	arg_6_0.touchLayer_:addTo(arg_6_0)
	arg_6_0.touchLayer_:setTouchEnabled(true)
	arg_6_0.touchLayer_:setTouchSwallowEnabled(true)
	arg_6_0.touchLayer_:setLocalZOrder(1000)
	arg_6_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "ended" then
			if arg_6_0.clickToEnd then
				local var_7_0 = arg_6_0.talkTable_:isFalse(arg_6_0.playingIndex_)
				local var_7_1 = arg_6_0.talkTable_:battleId(arg_6_0.playingIndex_)

				if var_7_0 == var_0_5.Failed then
					arg_6_0:playFailed()
				elseif var_7_0 == var_0_5.Success then
					arg_6_0:playSuccess()
				elseif var_7_0 == var_0_5.Battle then
					arg_6_0:startBattle(var_7_1)
				end

				arg_6_0.clickToEnd = false
			elseif arg_6_0.isOnSpeaking then
				arg_6_0.showInOneTime = true
			else
				arg_6_0:nextPlay()
			end
		end

		return true
	end)

	if arg_6_0.showSkip then
		arg_6_0:nodeByName("skip_btn"):setVisible(true)
		arg_6_0:nodeByName("skip_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_8_0, false)
				xyd.WindowManager.get():closeWindow(arg_6_0)
			end
		end)
	end

	arg_6_0:nextPlay()
end

function LvbuStoryTalkWindow.optionListDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return #arg_9_0.chooseIds
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.optionList:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.optionList:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = arg_9_0:createListContent(arg_9_0.chooseIds[arg_9_3])
		local var_9_2 = var_9_1:getWidth()
		local var_9_3 = var_9_1:getHeight()

		var_9_0:setItemSize(var_9_2, var_9_3)
		var_9_0:addContent(var_9_1)

		return var_9_0
	end
end

function LvbuStoryTalkWindow.createListContent(arg_10_0, arg_10_1)
	local var_10_0 = display.newNode()
	local var_10_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/lvbu/story/option_item.csb")
	local var_10_2 = var_10_1:getChildByName("container")

	var_10_2:getChildByName("option_txt"):setString(arg_10_0.talkTable_:choose(arg_10_1))
	var_10_2:getChildByName("option_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			arg_10_0.selectOption = arg_10_1

			arg_10_0:nextPlay()
		end
	end)
	var_10_0:setAnchorPoint(cc.p(0, 0))
	var_10_0:setPosition(0, 0)
	var_10_1:addTo(var_10_0)
	var_10_1:setAnchorPoint(cc.p(0, 0))
	var_10_0:setContentSize(var_10_2:getContentSize())
	var_10_1:setName("source")

	return var_10_0
end

function LvbuStoryTalkWindow.nextPlay(arg_12_0, arg_12_1)
	if arg_12_0:getNextId() > 0 then
		arg_12_0.playingIndex_ = arg_12_0:getNextId()
		arg_12_0.selectOption = 0
	else
		return
	end

	arg_12_0.chooseIds = arg_12_0.talkTable_:chooseIds(arg_12_0.playingIndex_)

	arg_12_0.optionList:reload()
	arg_12_0:update()
end

function LvbuStoryTalkWindow.playDialog(arg_13_0)
	local var_13_0 = arg_13_0.talkTable_:isFalse(arg_13_0.playingIndex_)
	local var_13_1 = arg_13_0.talkTable_:battleId(arg_13_0.playingIndex_)

	if var_13_0 == var_0_5.Failed then
		arg_13_0:playFailed()
	end
end

function LvbuStoryTalkWindow.speakEnded(arg_14_0)
	local var_14_0 = arg_14_0.talkTable_:isFalse(arg_14_0.playingIndex_)
	local var_14_1 = arg_14_0.talkTable_:battleId(arg_14_0.playingIndex_)

	if var_14_0 == var_0_5.Failed then
		arg_14_0.clickToEnd = true
	elseif var_14_0 == var_0_5.Success then
		arg_14_0.clickToEnd = true
	elseif var_14_0 == var_0_5.Battle then
		arg_14_0.clickToEnd = true
	end
end

function LvbuStoryTalkWindow.playFailed(arg_15_0)
	local var_15_0 = {
		campaign_id = arg_15_0.lvbuFestival.details.campaign_id,
		event_id = arg_15_0.lvbuFestival.details.event_id
	}

	var_15_0.is_succ = 0

	arg_15_0.lvbuFestival:goForward(var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL).result = var_15_0

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.LVBU_TASK_RESULT
			})
		end
	end)
	xyd.WindowManager.get():closeWindow(arg_15_0)
end

function LvbuStoryTalkWindow.playSuccess(arg_17_0)
	local var_17_0 = {
		campaign_id = arg_17_0.lvbuFestival.details.campaign_id,
		event_id = arg_17_0.lvbuFestival.details.event_id
	}

	var_17_0.is_succ = 1

	arg_17_0.lvbuFestival:goForward(var_17_0, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL).result = var_17_0

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.LVBU_TASK_RESULT
			})
		end
	end)
	xyd.WindowManager.get():closeWindow(arg_17_0)
end

function LvbuStoryTalkWindow.getNextId(arg_19_0)
	local var_19_0 = 0

	if arg_19_0.selectOption and arg_19_0.selectOption > 0 then
		var_19_0 = arg_19_0.selectOption
	elseif arg_19_0.talkTable_:nextId(arg_19_0.playingIndex_) > 0 then
		var_19_0 = arg_19_0.talkTable_:nextId(arg_19_0.playingIndex_)
	elseif arg_19_0.playingIndex_ == 0 then
		var_19_0 = 1
	end

	return var_19_0
end

function LvbuStoryTalkWindow.update(arg_20_0)
	arg_20_0:nodeByName("bottom"):setVisible(false)
	arg_20_0:updateCardContainer(arg_20_0.playingIndex_)
	arg_20_0:playSpeak(arg_20_0.playingIndex_)
end

function LvbuStoryTalkWindow.playSpeak(arg_21_0, arg_21_1)
	arg_21_0:updateTalkBox(arg_21_1)

	local var_21_0 = xyd.tables.misc.dialogSpeed

	arg_21_0:speak(arg_21_0.talkTable_:dialog(arg_21_1), arg_21_0.message, var_21_0)
end

function LvbuStoryTalkWindow.updateTalkBox(arg_22_0, arg_22_1)
	arg_22_0.message:setString("")

	if arg_22_0.talkTable_:position(arg_22_1) == var_0_4.Left then
		arg_22_0:nodeByName("name_box2"):setVisible(false)
		arg_22_0:nodeByName("label_name2"):setVisible(false)
		arg_22_0:nodeByName("name_box1"):setVisible(true)
		arg_22_0:nodeByName("label_name1"):setVisible(true)

		local var_22_0 = arg_22_0.talkTable_:name(arg_22_1)
		local var_22_1 = string.gsub(var_22_0, "=playername=", arg_22_0.selfPlayer.playerName)

		arg_22_0:nodeByName("label_name1"):setString(var_22_1)
	elseif arg_22_0.talkTable_:position(arg_22_1) == var_0_4.Right then
		arg_22_0:nodeByName("name_box2"):setVisible(true)
		arg_22_0:nodeByName("label_name2"):setVisible(true)
		arg_22_0:nodeByName("name_box1"):setVisible(false)
		arg_22_0:nodeByName("label_name1"):setVisible(false)
		arg_22_0:nodeByName("label_name2"):setString(arg_22_0.talkTable_:name(arg_22_1))
	end

	arg_22_0:nodeByName("bottom"):setVisible(true)
end

function LvbuStoryTalkWindow.speak(arg_23_0, arg_23_1, arg_23_2, arg_23_3)
	arg_23_1 = string.gsub(arg_23_1, "=playername=", arg_23_0.selfPlayer.playerName)

	local var_23_0 = xyd.utf8len(arg_23_1)

	arg_23_0.showInOneTime = false
	arg_23_0.isOnSpeaking = true

	local var_23_1 = 0

	if arg_23_0.handler then
		var_0_0.unscheduleGlobal(arg_23_0.handler)

		arg_23_0.handler = nil
	end

	arg_23_0.handler = var_0_0.scheduleGlobal(function()
		var_23_1 = var_23_1 + 1

		if var_23_1 > var_23_0 and arg_23_0.handler or arg_23_0.showInOneTime == true then
			if not tolua.isnull(arg_23_2) then
				arg_23_2:setString(arg_23_1)
			end

			var_0_0.unscheduleGlobal(arg_23_0.handler)

			arg_23_0.isOnSpeaking = false

			arg_23_0:speakEnded()

			return
		end

		local var_24_0 = xyd.getSplitUtf8Str(arg_23_1, 0, var_23_1 * 3)

		if not tolua.isnull(arg_23_2) then
			arg_23_2:setString(var_24_0)
		end
	end, arg_23_3)
end

function LvbuStoryTalkWindow.updateCardContainer(arg_25_0, arg_25_1)
	arg_25_0.cardContainerLeft:removeAllChildren()
	arg_25_0.cardContainerRight:removeAllChildren()

	local var_25_0 = arg_25_0.talkTable_:img(arg_25_1)
	local var_25_1 = xyd.AssetLoader.get():loadSprite(var_25_0)

	if not var_25_1 then
		return
	end

	local var_25_2

	if arg_25_0.talkTable_:position(arg_25_1) == var_0_4.Left then
		var_25_2 = arg_25_0.cardContainerLeft
	else
		var_25_2 = arg_25_0.cardContainerRight
	end

	var_25_2:addChild(var_25_1)
	var_25_1:setAnchorPoint(cc.p(0.5, 0))
	var_25_1:setPosition(cc.p(var_25_2:getContentSize().width / 2, 0))
	var_25_1:setTouchEnabled(false)
end

function LvbuStoryTalkWindow.scrollListener(arg_26_0, arg_26_1)
	if arg_26_1.name == "began" then
		arg_26_0.startClick_ = true
		arg_26_0.prevY_ = arg_26_1.y
	elseif arg_26_1.name == "moved" and 20 <= math.abs(arg_26_1.y - arg_26_0.prevY_) then
		arg_26_0.startClick_ = false
	end
end

function LvbuStoryTalkWindow.startBattle(arg_27_0, arg_27_1)
	arg_27_0.lvbuFestival.story_id = arg_27_0.talkId
	arg_27_0.lvbuFestival.playingIndex = arg_27_0.playingIndex_

	local var_27_0 = {}

	arg_27_0:initialTeam()

	var_27_0.herosA = arg_27_0.herosA_
	var_27_0.campaignType = xyd.CampaignType.LVBU_FESTIVAL
	var_27_0.campaignID = 0

	local var_27_1 = xyd.tables.battle:monsters(arg_27_1)

	var_27_0.herosB = {}

	for iter_27_0 = 1, #var_27_1 do
		local var_27_2 = {}

		for iter_27_1, iter_27_2 in ipairs(var_27_1[iter_27_0]) do
			local var_27_3 = var_0_1.new()

			var_27_3:populateWithTableID(iter_27_2)
			table.insert(var_27_2, var_27_3)
		end

		arg_27_0.lvbuFestival:formatLvbuCampusHeros(var_27_2)

		if #var_27_2 > 0 then
			table.insert(var_27_0.herosB, var_27_2)
		end
	end

	var_27_0.battleID = xyd.MapBattleID.ARENA
	var_27_0.formation = arg_27_0:getFormationStr(var_27_0.herosA)
	var_27_0.battleType = xyd.BattleType.CreateReport
	var_27_0.fighterInfo = {}

	xyd.WindowManager.get():hideAllWindows()
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "lvbu_main"
		}
	})
	xyd.LoadingProxy.get():openBattleLoading(var_27_0)
end

function LvbuStoryTalkWindow.getFormationStr(arg_28_0, arg_28_1)
	local var_28_0 = ""

	for iter_28_0, iter_28_1 in ipairs(arg_28_1) do
		var_28_0 = var_28_0 .. string.format("%d", iter_28_1:getTableID())

		if iter_28_0 < #arg_28_1 then
			var_28_0 = var_28_0 .. "|"
		end
	end

	return var_28_0
end

function LvbuStoryTalkWindow.initialTeam(arg_29_0)
	arg_29_0.herosA_ = {}

	for iter_29_0 = 1, #arg_29_0.lvbuFestival.teamHeros do
		local var_29_0 = var_0_1.new()

		var_29_0:populateWithTableID(arg_29_0.lvbuFestival.teamHeros[iter_29_0]:getTableID())
		table.insert(arg_29_0.herosA_, var_29_0)
	end

	arg_29_0.lvbuFestival:formatLvbuCampusHeros(arg_29_0.herosA_)
end

return LvbuStoryTalkWindow
