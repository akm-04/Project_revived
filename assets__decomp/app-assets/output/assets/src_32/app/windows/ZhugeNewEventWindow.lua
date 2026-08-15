local var_0_0 = class("ZhugeNewEventWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.zhugeEventDialog
local var_0_5 = xyd.tables.zhugeMazeEvent
local var_0_6 = {
	DIALOG = 2,
	SELECT = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.zhugeModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ZHUGE_FESTIVAL)
	arg_1_0.curWindowType = var_0_6.SELECT
	arg_1_0.eventID = arg_1_2.event_id
	arg_1_0.mapIndex = arg_1_2.index
	arg_1_0.curX_ = arg_1_2.x_
	arg_1_0.curY_ = arg_1_2.y_
	arg_1_0.dialogID = 0
	arg_1_0.needUpdateMap_ = false
	arg_1_0.isShowAnimation_ = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addBlockLayerWithNoTouchEvent()
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super.willClose(arg_3_0, arg_3_1)

	if arg_3_0.needUpdateMap_ then
		local var_3_0 = xyd.WindowManager.get():getWindow("zhuge_new_adventure")

		if var_3_0 and not tolua.isnull(var_3_0) then
			var_3_0:updateAll(arg_3_0.curX_, arg_3_0.curY_)
		end
	end
end

function var_0_0.initData(arg_4_0)
	local var_4_0 = arg_4_0.zhugeModel:getMapPointByIndex(arg_4_0.mapIndex)

	if var_4_0 then
		arg_4_0.dialogID = var_4_0.dialog_id
	end

	if arg_4_0.dialogID == 0 then
		arg_4_0.curWindowType = var_0_6.SELECT
	else
		arg_4_0.curWindowType = var_0_6.DIALOG
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("dialog"):setVisible(false)
	arg_5_0:nodeByName("card"):setVisible(false)
	arg_5_0:playEvent()
end

function var_0_0.playEvent(arg_6_0)
	if arg_6_0.curWindowType == var_0_6.SELECT then
		arg_6_0:playStartEvent()
	elseif arg_6_0.curWindowType == var_0_6.DIALOG then
		arg_6_0:showDialog()
	end
end

function var_0_0.playStartEvent(arg_7_0)
	local var_7_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/zhugeliang/new_adventure_event/card.csb")
	local var_7_1 = var_7_0:getChildByName("card_bg_2")
	local var_7_2 = var_7_0:getChildByName("container")
	local var_7_3 = var_7_2:getContentSize()

	var_7_0:addTo(arg_7_0:nodeByName("card"))
	var_7_0:setPosition(cc.p(var_7_3.width / 2, var_7_3.height / 2))
	var_7_2:getChildByName("text_card_word"):setString(var_0_5:name(arg_7_0.eventID))
	var_7_2:getChildByName("text_card_word"):enableOutline(cc.c4b(145, 71, 33, 255), 2)
	var_7_2:getChildByName("text_mid_word"):setString(var_0_5:desc(arg_7_0.eventID))
	var_7_2:getChildByName("text_word_1"):enableOutline(cc.c4b(125, 45, 3, 255), 2)
	var_7_2:getChildByName("text_word_2"):enableOutline(cc.c4b(125, 45, 3, 255), 2)
	var_7_2:getChildByName("text_word_1"):setString(var_0_5:choice(arg_7_0.eventID)[1])
	var_7_2:getChildByName("text_word_2"):setString(var_0_5:choice(arg_7_0.eventID)[2])

	local var_7_4 = var_0_5:icon(arg_7_0.eventID)
	local var_7_5 = xyd.AssetLoader.get():loadSprite(var_7_4)

	if var_7_5 then
		var_7_5:addTo(var_7_2:getChildByName("card_mid"))

		local var_7_6 = var_7_2:getChildByName("card_mid"):getContentSize()

		var_7_5:setPosition(cc.p(var_7_6.width / 2, var_7_6.height / 2))
		var_7_5:setAnchorPoint(cc.p(0.5, 0.5))
	end

	var_7_2:getChildByName("btn_1"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			arg_7_0:selectDialog(1)
		end
	end)
	var_7_2:getChildByName("btn_2"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_7_0:selectDialog(2)
		end
	end)
	arg_7_0:nodeByName("card"):setVisible(true)

	local function var_7_7()
		var_7_1:setVisible(false)
	end

	local var_7_8 = 0.15
	local var_7_9 = cc.OrbitCamera:create(var_7_8, 1, 0, 0, 90, 0, 0)
	local var_7_10 = cc.OrbitCamera:create(var_7_8, 1, 0, 270, 90, 0, 0)
	local var_7_11 = cc.CallFunc:create(var_7_7)
	local var_7_12 = cc.Sequence:create(var_7_9, var_7_11, var_7_10)

	var_7_0:runAction(var_7_12)
end

function var_0_0.selectDialog(arg_11_0, arg_11_1)
	local var_11_0 = var_0_5:dialog(arg_11_0.eventID)

	if not var_11_0 or #var_11_0 < 2 then
		return
	end

	local var_11_1 = {
		index = arg_11_0.mapIndex,
		event_id = arg_11_0.eventID,
		dialog_id = var_11_0[arg_11_1]
	}

	arg_11_0.zhugeModel:selectDialog(var_11_1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0:nodeByName("card"):setVisible(false)

			local var_12_0 = arg_11_0.zhugeModel:getMapPointByIndex(arg_11_0.mapIndex)

			arg_11_0.dialogID = var_12_0.dialog_id

			arg_11_0:showDialog()
		end
	end)
end

function var_0_0.getDialog(arg_13_0)
	return (var_0_4:dialog(arg_13_0.dialogID))
end

function var_0_0.showDialog(arg_14_0)
	if not arg_14_0.clickDialogNode then
		local var_14_0 = display.newNode()

		var_14_0:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
		var_14_0:addTo(arg_14_0)
		var_14_0:setPosition(cc.p(arg_14_0:convertToWorldSpace(cc.p(0, 0))))
		var_14_0:setTouchEnabled(true)
		var_14_0:setTouchSwallowEnabled(true)
		var_14_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
			if arg_15_0.name == "ended" and not arg_14_0.isOnSpeaking and not arg_14_0.isClick_ then
				arg_14_0.isClick_ = true

				arg_14_0:nextDialogEvent()
			end

			return true
		end)

		arg_14_0.clickDialogNode = var_14_0
	else
		arg_14_0.clickDialogNode:setVisible(true)
	end

	arg_14_0.blockLayer_:setVisible(false)

	arg_14_0.isClick_ = false

	arg_14_0:nodeByName("dialog"):setVisible(true)

	local var_14_1 = arg_14_0:getDialog()
	local var_14_2 = xyd.tables.misc.dialogSpeed

	arg_14_0:nodeByName("dialog_name"):setString(var_0_3:translation("ZHUGE_EVENT_DIALOG_NAME"))
	arg_14_0:nodeByName("dialog_desc"):setString("")
	arg_14_0:nodeByName("dialog_name"):setString(var_0_3:translation("ZHUGE_EVENT_DIALOG_NAME"))
	arg_14_0:speak(var_14_1, arg_14_0:nodeByName("dialog_desc"), var_14_2)
end

function var_0_0.speak(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4)
	local var_16_0 = xyd.utf8len(arg_16_1)

	arg_16_0.isOnSpeaking = true

	local var_16_1 = 0

	if arg_16_0.speakHandler then
		var_0_1.unscheduleGlobal(arg_16_0.speakHandler)

		arg_16_0.speakHandler = nil
	end

	arg_16_0.speakHandler = var_0_1.scheduleGlobal(function()
		var_16_1 = var_16_1 + 1

		if var_16_1 > var_16_0 and arg_16_0.speakHandler or arg_16_0.showInOneTime == true then
			if not tolua.isnull(arg_16_2) then
				arg_16_2:setString(arg_16_1)
			end

			var_0_1.unscheduleGlobal(arg_16_0.speakHandler)

			arg_16_0.isOnSpeaking = false

			if arg_16_4 then
				arg_16_4()
			end

			return
		end

		local var_17_0 = xyd.getSplitUtf8Str(arg_16_1, 0, var_16_1 * 3)

		if not tolua.isnull(arg_16_2) then
			arg_16_2:setString(var_17_0)
		end
	end, arg_16_3)
end

function var_0_0.nextDialogEvent(arg_18_0)
	if not arg_18_0 or tolua.isnull(arg_18_0) then
		return
	end

	local var_18_0 = var_0_4:next(arg_18_0.dialogID)
	local var_18_1 = var_0_4:resultType(arg_18_0.dialogID)

	if var_18_0 and #var_18_0 == 1 then
		if var_18_0[1] == -1 then
			arg_18_0:showResult(var_18_1)

			return
		elseif var_18_0[1] > 0 then
			arg_18_0:endCurDialog(nil, function()
				local var_19_0 = arg_18_0.zhugeModel:getMapPointByIndex(arg_18_0.mapIndex)

				arg_18_0.dialogID = var_19_0.dialog_id

				arg_18_0:showDialog()
			end)

			return
		end
	elseif var_18_0 and #var_18_0 == 2 and var_18_1 == 0 then
		arg_18_0:nodeByName("card"):removeAllChildren()

		local var_18_2 = xyd.AssetLoader.get():loadSprite("windows/zhugeliang/new_adventure_event/coin_1.png")

		var_18_2:addTo(arg_18_0:nodeByName("card"))
		var_18_2:setAnchorPoint(cc.p(0.5, 0.5))

		local var_18_3 = arg_18_0:nodeByName("card"):getContentSize()

		var_18_2:setPosition(cc.p(var_18_3.width / 2, var_18_3.height / 2))
		var_18_2:setTouchEnabled(true)
		var_18_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_20_0)
			if arg_20_0.name == "began" and not arg_18_0.isShowAnimation_ then
				var_18_2:setScale(0.9)
			elseif arg_20_0.name == "moved" and not arg_18_0.isShowAnimation_ then
				var_18_2:setScale(1)
			elseif arg_20_0.name == "ended" and not arg_18_0.isShowAnimation_ then
				var_18_2:setScale(1)

				arg_18_0.isShowAnimation_ = true

				arg_18_0:endCurDialog(nil, function(arg_21_0, arg_21_1)
					if arg_21_0 == xyd.error.OK then
						arg_18_0:showCoinAnimation(var_18_2, var_18_0)
					else
						arg_18_0.isShowAnimation_ = false
					end
				end)
			end

			return true
		end)

		local var_18_4 = arg_18_0:createTextLabel(var_0_3:translation("ZHUGE_ADVENTURE_TIPS_33"), 500, cc.ui.TEXT_ALIGN_CENTER, 30)

		var_18_4:addTo(arg_18_0:nodeByName("card"))
		var_18_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_18_4:setPosition(cc.p(var_18_3.width / 2, 200))
		var_18_4:setName("label_tips")
		arg_18_0:nodeByName("card"):setVisible(true)
		arg_18_0:nodeByName("dialog"):setVisible(false)
		arg_18_0.blockLayer_:setVisible(true)
		arg_18_0.clickDialogNode:setVisible(false)
	end
end

function var_0_0.showCoinAnimation(arg_22_0, arg_22_1, arg_22_2)
	arg_22_0:nodeByName("card"):getChildByName("label_tips"):setVisible(false)

	arg_22_0.dialogID = arg_22_0.zhugeModel:getMapPointByIndex(arg_22_0.mapIndex).dialog_id

	local var_22_0 = 1

	if arg_22_0.dialogID and arg_22_2 then
		for iter_22_0 = 1, #arg_22_2 do
			if arg_22_2[iter_22_0] == arg_22_0.dialogID then
				var_22_0 = iter_22_0

				break
			end
		end
	end

	arg_22_1:setVisible(false)

	local var_22_1 = "skeletons/ui_effect/zhugeliang/zhuge_01"
	local var_22_2 = arg_22_0:nodeByName("card"):getContentSize()
	local var_22_3 = cc.p(var_22_2.width / 2, var_22_2.height / 2)
	local var_22_4 = arg_22_0:createEffect(var_22_1, arg_22_0:nodeByName("card"), var_22_3)

	var_22_4:play(function()
		arg_22_0.isShowAnimation_ = false

		var_22_4:hide()
		arg_22_0:showDialog()
	end, false, nil, "texiao0" .. var_22_0)
end

function var_0_0.createTextLabel(arg_24_0, arg_24_1, arg_24_2, arg_24_3, arg_24_4, arg_24_5)
	local var_24_0 = {
		text = arg_24_1,
		align = arg_24_3 or cc.ui.TEXT_ALIGN_LEFT,
		color = arg_24_5 or cc.c3b(255, 255, 255),
		size = arg_24_4 or 24,
		dimensions = cc.size(arg_24_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_24_0))
end

function var_0_0.endCurDialog(arg_25_0, arg_25_1, arg_25_2)
	arg_25_0.zhugeModel:endCurDialog(arg_25_0.eventID, arg_25_0.dialogID, arg_25_0.mapIndex, arg_25_1, arg_25_2)
end

function var_0_0.showResult(arg_26_0, arg_26_1)
	if arg_26_1 == xyd.ZhugeNewEventType.AWARD then
		arg_26_0:endCurDialog(nil, function(arg_27_0, arg_27_1)
			if arg_27_0 == xyd.error.OK then
				local var_27_0 = arg_27_1.awards

				if var_27_0 and next(var_27_0) then
					xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(var_27_0)
				end

				arg_26_0.needUpdateMap_ = true

				xyd.WindowManager.get():closeWindow(arg_26_0)
			else
				arg_26_0.isClick_ = false
			end
		end)
	elseif arg_26_1 == xyd.ZhugeNewEventType.BATTLE then
		if not arg_26_0.zhugeModel:checkTeamHasAlive() then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_3:translation("ZHUGE_ADVENTURE_TIPS_36")
			})
			xyd.WindowManager.get():closeWindow(arg_26_0)

			return
		end

		local var_26_0, var_26_1 = arg_26_0.zhugeModel:initEnemyInfo(var_0_4:resultNum(arg_26_0.dialogID))
		local var_26_2 = {
			showEnemy = true,
			teamType = xyd.ZhugeSelectTeamType.SELECT_ADVENTURE_TEAM,
			enemyHeroes = var_26_0,
			enemyPets = var_26_1,
			specialParams = {
				eventID = arg_26_0.eventID,
				dialogID = arg_26_0.dialogID,
				mapIndex = arg_26_0.mapIndex,
				x_ = arg_26_0.curX_,
				y_ = arg_26_0.curY_
			}
		}

		xyd.WindowManager.get():openWindow("zhuge_new_select_team", var_26_2)
		xyd.WindowManager.get():closeWindow(arg_26_0)
	elseif arg_26_1 == xyd.ZhugeNewEventType.REBORN or arg_26_1 == xyd.ZhugeNewEventType.KILL_ONE or arg_26_1 == xyd.ZhugeNewEventType.ADD_BUFF then
		local var_26_3 = {
			eventID = arg_26_0.eventID,
			dialogID = arg_26_0.dialogID,
			mapIndex = arg_26_0.mapIndex,
			x_ = arg_26_0.curX_,
			y_ = arg_26_0.curY_
		}

		if arg_26_1 == xyd.ZhugeNewEventType.REBORN then
			var_26_3.selectType = xyd.ZhugeTeamWndType.REBORN
		elseif arg_26_1 == xyd.ZhugeNewEventType.KILL_ONE then
			var_26_3.selectType = xyd.ZhugeTeamWndType.KILL_ONE
		elseif arg_26_1 == xyd.ZhugeNewEventType.ADD_BUFF then
			var_26_3.selectType = xyd.ZhugeTeamWndType.ADD_BUFF
		end

		xyd.WindowManager.get():openWindow("zhuge_team_info", var_26_3)
		xyd.WindowManager.get():closeWindow(arg_26_0)
	elseif arg_26_1 == xyd.ZhugeNewEventType.ADD_ENERGY then
		arg_26_0:endCurDialog(nil, function(arg_28_0, arg_28_1)
			if arg_28_0 == xyd.error.OK then
				arg_26_0.needUpdateMap_ = true

				xyd.WindowManager.get():closeWindow(arg_26_0)
			else
				arg_26_0.isClick_ = false
			end
		end)
	elseif arg_26_1 == xyd.ZhugeNewEventType.OPEN_GEZI then
		if arg_26_0:checkCanOpenGezi() then
			local var_26_4 = xyd.WindowManager.get():getWindow("zhuge_new_adventure")

			if var_26_4 and not tolua.isnull(var_26_4) then
				local var_26_5 = {
					eventID = arg_26_0.eventID,
					dialogID = arg_26_0.dialogID,
					mapIndex = arg_26_0.mapIndex,
					x_ = arg_26_0.curX_,
					y_ = arg_26_0.curY_
				}

				var_26_4:specialOpenGezi(var_26_5)
			end

			xyd.WindowManager.get():closeWindow(arg_26_0)
		else
			arg_26_0:endCurDialog(nil, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					arg_26_0.needUpdateMap_ = true

					xyd.WindowManager.get():closeWindow(arg_26_0)
				else
					arg_26_0.isClick_ = false
				end
			end)
		end
	else
		arg_26_0:endCurDialog(nil, function(arg_30_0, arg_30_1)
			if arg_30_0 == xyd.error.OK then
				arg_26_0.needUpdateMap_ = true

				xyd.WindowManager.get():closeWindow(arg_26_0)
			else
				arg_26_0.isClick_ = false
			end
		end)
	end
end

function var_0_0.checkCanOpenGezi(arg_31_0)
	local var_31_0 = arg_31_0.zhugeModel:getMapInfo()
	local var_31_1 = var_31_0.map or {}
	local var_31_2 = var_31_0.points or {}
	local var_31_3 = 0

	for iter_31_0 = 1, #var_31_1 do
		if var_31_1[iter_31_0] and next(var_31_1[iter_31_0]) then
			for iter_31_1 = 1, #var_31_1[iter_31_0] do
				local var_31_4 = var_31_1[iter_31_0][iter_31_1]

				if var_31_4 > 0 and var_31_2[var_31_4] and next(var_31_2[var_31_4]) and var_31_2[var_31_4].point > 0 and var_31_2[var_31_4].is_passed == 0 then
					var_31_3 = var_31_3 + 1

					break
				end
			end
		end
	end

	if var_31_3 > 0 then
		return true
	end

	return false
end

function var_0_0.createEffect(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4)
	local var_32_0 = arg_32_4 or 1
	local var_32_1 = var_0_2.new(arg_32_1 .. ".json", arg_32_1 .. ".atlas", var_32_0)

	var_32_1:addTo(arg_32_2)
	var_32_1:setPosition(arg_32_3)

	return var_32_1
end

return var_0_0
