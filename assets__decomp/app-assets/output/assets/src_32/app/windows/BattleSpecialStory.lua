local var_0_0 = class("BattleSpecialStory", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.misc
local var_0_2 = xyd.tables.campaign
local var_0_3 = import("app.model.Hero")
local var_0_4 = 1
local var_0_5 = 2
local var_0_6 = {
	CHECK = 2,
	SUMMON = 3,
	ASSIST = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.data = arg_1_2
	arg_1_0.storyID_ = arg_1_2.story_id
	arg_1_0.storyState_ = arg_1_2.story_state
	arg_1_0.campaignID = arg_1_2.campaign_id
	arg_1_0.campaignType = arg_1_2.campaign_type
	arg_1_0.isReOpenWindow_ = arg_1_2.is_reopen
	arg_1_0.storyData_ = import("app.common.tables.BattleSpecialStoryTable").new(arg_1_0.storyID_)
	arg_1_0.playingIndex_ = 1

	if arg_1_2.callback then
		arg_1_0.callback = arg_1_2.callback
	end
end

function var_0_0.checkFileExist(arg_2_0)
	return true
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	if arg_3_0:checkFileExist() then
		arg_3_0:hideOtherWindows(false)
		arg_3_0:layout()
	else
		xyd.WindowManager.get():closeWindow("story")
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)

	if arg_4_0:checkFileExist() then
		arg_4_0:nextPlay()
	else
		xyd.WindowManager.get():closeWindow("story")
	end
end

function var_0_0.hideOtherWindows(arg_5_0, arg_5_1)
	local var_5_0 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleBottomWnd)
	local var_5_1 = xyd.WindowManager.get():getWindow(xyd.WindowName.battleTopWnd)

	if var_5_1 then
		var_5_1:setVisible(arg_5_1)
	end

	if var_5_0 then
		var_5_0:setVisible(arg_5_1)
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0.maskColor = cc.c4f(0.5, 0.5, 0.5, 1)

	local var_6_0 = display.newNode()

	var_6_0:setName("role")
	var_6_0:size(arg_6_0:getContentSize())
	var_6_0:setAnchorPoint(cc.p(0, 0))
	var_6_0:setPosition(cc.p(0, 0))
	var_6_0:addTo(arg_6_0, -1)

	arg_6_0.roleLayer_ = var_6_0

	arg_6_0:setTouchSwallowEnabled(false)

	arg_6_0.touchLayer_ = var_6_0:clone()

	arg_6_0.touchLayer_:addTo(arg_6_0)
	arg_6_0.touchLayer_:setTouchEnabled(true)
	arg_6_0.touchLayer_:setTouchSwallowEnabled(false)
	arg_6_0.touchLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "ended" then
			arg_6_0:nextPlay()
		end

		return true
	end)
end

function var_0_0.nextPlay(arg_8_0)
	if arg_8_0.playingIndex_ == -1 then
		arg_8_0:onEnded()

		return
	elseif arg_8_0.playingIndex_ == 0 then
		return
	end

	arg_8_0:update()

	arg_8_0.playingIndex_ = arg_8_0.storyData_:nextID(arg_8_0.playingIndex_)
end

function var_0_0.update(arg_9_0)
	local var_9_0 = clone(arg_9_0.storyData_:dialog(arg_9_0.playingIndex_))
	local var_9_1 = clone(arg_9_0.storyData_:name(arg_9_0.playingIndex_))
	local var_9_2 = arg_9_0.storyData_:lImg(arg_9_0.playingIndex_)
	local var_9_3 = arg_9_0.storyData_:rImg(arg_9_0.playingIndex_)
	local var_9_4 = arg_9_0.storyData_:position(arg_9_0.playingIndex_)
	local var_9_5 = arg_9_0.storyData_:choose(arg_9_0.playingIndex_)
	local var_9_6 = arg_9_0.storyData_:chooseID(arg_9_0.playingIndex_)
	local var_9_7 = arg_9_0.storyData_:bg(arg_9_0.playingIndex_)
	local var_9_8 = arg_9_0.storyData_:nextID(arg_9_0.playingIndex_)
	local var_9_9 = arg_9_0.storyData_:result(arg_9_0.playingIndex_)
	local var_9_10 = xyd.tables.misc.storyCardDistance
	local var_9_11 = arg_9_0:getWidth() / 2

	if var_9_1:find("=playername=") then
		var_9_1 = arg_9_0:getPlayerName()
	end

	if var_9_0:find("=playername=") then
		local var_9_12 = clone(var_9_0)
		local var_9_13 = string.split(var_9_12, "=playername=")
		local var_9_14 = ""

		for iter_9_0 = 1, #var_9_13 do
			if iter_9_0 > 1 then
				var_9_14 = var_9_14 .. arg_9_0:getPlayerName() .. var_9_13[iter_9_0]
			else
				var_9_14 = var_9_14 .. var_9_13[iter_9_0]
			end
		end

		var_9_0 = var_9_14
	end

	arg_9_0:nodeByName("text"):setString(var_9_0)

	if var_9_4 == 1 and var_9_2 ~= "" then
		if arg_9_0.midIcon_ ~= var_9_2 then
			if arg_9_0.roleMid1_ then
				arg_9_0.roleMid1_:removeSelf()

				arg_9_0.roleMid1_ = nil
			end

			local var_9_15 = xyd.SpriteLoader.new(var_9_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

			var_9_15:addTo(arg_9_0.roleLayer_)
			var_9_15:setAnchorPoint(cc.p(0.5, 0))
			var_9_15:pos(var_9_11, 0)

			arg_9_0.midIcon_ = var_9_2
			arg_9_0.roleMid1_ = var_9_15
		end

		if arg_9_0.roleLeft1_ then
			arg_9_0.roleLeft1_:removeSelf()

			arg_9_0.roleLeft1_ = nil
			arg_9_0.leftIcon_ = nil
		end

		if arg_9_0.roleRight1_ then
			arg_9_0.roleRight1_:removeSelf()

			arg_9_0.roleRight1_ = nil
			arg_9_0.rightIcon_ = nil
		end

		arg_9_0:updateBottom(3, var_9_1)
	else
		local var_9_16 = 0

		if var_9_2 ~= "" then
			if arg_9_0.leftIcon_ ~= var_9_2 then
				if arg_9_0.roleLeft1_ then
					arg_9_0.roleLeft1_:removeSelf()

					arg_9_0.roleLeft1_ = nil
				end

				local var_9_17 = xyd.SpriteLoader.new(var_9_2, nil, nil, xyd.DefaultImageType.HOME_CARD)

				var_9_17:addTo(arg_9_0.roleLayer_)
				var_9_17:setAnchorPoint(cc.p(0.5, 0))
				var_9_17:pos(var_9_11 - var_9_10, 0)

				arg_9_0.leftIcon_ = var_9_2
				arg_9_0.roleLeft1_ = var_9_17
			end

			var_9_16 = var_9_16 + 1
		elseif arg_9_0.roleLeft1_ then
			arg_9_0.roleLeft1_:removeSelf()

			arg_9_0.roleLeft1_ = nil
			arg_9_0.leftIcon_ = nil
		end

		if var_9_3 ~= "" then
			if arg_9_0.rightIcon_ ~= var_9_3 then
				if arg_9_0.roleRight1_ then
					arg_9_0.roleRight1_:removeSelf()

					arg_9_0.roleRight1_ = nil
				end

				local var_9_18 = xyd.SpriteLoader.new(var_9_3, nil, nil, xyd.DefaultImageType.HOME_CARD)

				var_9_18:addTo(arg_9_0.roleLayer_)
				var_9_18:setAnchorPoint(cc.p(0.5, 0))
				var_9_18:pos(var_9_11 + var_9_10, 0)

				arg_9_0.rightIcon_ = var_9_3
				arg_9_0.roleRight1_ = var_9_18
			end

			var_9_16 = var_9_16 + 2
		elseif arg_9_0.roleRight1_ then
			arg_9_0.roleRight1_:removeSelf()

			arg_9_0.roleRight1_ = nil
			arg_9_0.rightIcon_ = nil
		end

		if arg_9_0.roleMid1_ then
			arg_9_0.roleMid1_:removeSelf()

			arg_9_0.roleMid1_ = nil
			arg_9_0.midIcon_ = nil
		end

		arg_9_0:updateBottom(var_9_16, var_9_1)
	end

	if var_9_6 and next(var_9_6) and var_9_6[1] ~= -1 then
		arg_9_0:createSelect(var_9_6)
	else
		arg_9_0:nodeByName("mid"):removeAllChildren()
	end
end

function var_0_0.updateBottom(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_1 == 1 then
		arg_10_0:nodeByName("name_box1"):setVisible(true)
		arg_10_0:nodeByName("label_name1"):setString(arg_10_2)
		arg_10_0:nodeByName("label_name1"):setVisible(true)
		arg_10_0:nodeByName("name_box2"):setVisible(false)
		arg_10_0:nodeByName("label_name2"):setVisible(false)
	elseif arg_10_1 == 2 then
		arg_10_0:nodeByName("name_box2"):setVisible(true)
		arg_10_0:nodeByName("label_name2"):setString(arg_10_2)
		arg_10_0:nodeByName("label_name2"):setVisible(true)
		arg_10_0:nodeByName("name_box1"):setVisible(false)
		arg_10_0:nodeByName("label_name1"):setVisible(false)
	elseif arg_10_1 == 3 then
		arg_10_0:nodeByName("name_box1"):setVisible(false)
		arg_10_0:nodeByName("label_name1"):setVisible(false)
		arg_10_0:nodeByName("name_box2"):setVisible(false)
		arg_10_0:nodeByName("label_name2"):setVisible(false)
	end
end

function var_0_0.createSelect(arg_11_0, arg_11_1)
	arg_11_0:nodeByName("mid"):removeAllChildren()

	local var_11_0 = 29
	local var_11_1 = arg_11_0:nodeByName("mid"):getContentSize().height

	for iter_11_0 = 1, #arg_11_1 do
		local var_11_2 = arg_11_1[iter_11_0]
		local var_11_3 = arg_11_0.storyData_:choose(var_11_2)
		local var_11_4 = arg_11_0.storyData_:result(var_11_2)
		local var_11_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/story/select_item.csb")

		var_11_5:addTo(arg_11_0:nodeByName("mid"))

		local var_11_6 = var_11_5:getChildByName("container")

		var_11_1 = var_11_1 - var_11_6:getContentSize().height - var_11_0

		var_11_5:setPositionY(var_11_1)

		local var_11_7 = var_11_6:getChildByName("btn_select")

		var_11_6:getChildByName("text"):setString(var_11_3)
		var_11_7:addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				if var_11_4 and next(var_11_4) and #var_11_4 == 2 then
					arg_11_0:btnTouchEvent(var_11_2, var_11_4)
				else
					arg_11_0.playingIndex_ = arg_11_0.storyData_:nextID(var_11_2)

					arg_11_0:nextPlay()
				end
			end
		end)
	end
end

function var_0_0.btnTouchEvent(arg_13_0, arg_13_1, arg_13_2)
	if not arg_13_2 or not next(arg_13_2) or #arg_13_2 ~= 2 then
		return
	end

	if arg_13_2[1] == var_0_6.ASSIST then
		arg_13_0.assistID = arg_13_2[2]
		arg_13_0.playingIndex_ = arg_13_0.storyData_:nextID(arg_13_1)

		arg_13_0:nextPlay()
	elseif arg_13_2[1] == var_0_6.CHECK then
		local var_13_0 = var_0_3.new()
		local var_13_1 = var_0_2:storyDropPartner(arg_13_0.campaignID)[arg_13_2[2]]

		var_13_0:initUnCollected(var_13_1)

		var_13_0.isHideBorrow = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_13_0)
	elseif arg_13_2[1] == var_0_6.SUMMON then
		local var_13_2 = var_0_2:storyDropPartner(arg_13_0.campaignID)[arg_13_2[2]]
		local var_13_3 = {
			campaign_id = arg_13_0.campaignID,
			story_drop_partner = var_13_2,
			campaign_type = arg_13_0.campaignType
		}

		xyd.Backend.get():request(xyd.mid.GET_STORY_DROP_PARTNER, var_13_3, function(arg_14_0, arg_14_1)
			if arg_14_0 == xyd.error.OK and arg_14_1 and next(arg_14_1) and arg_14_1.story_drop_awards and next(arg_14_1.story_drop_awards) then
				xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_14_1.story_drop_awards, function()
					arg_13_0.playingIndex_ = arg_13_0.storyData_:nextID(arg_13_1)

					arg_13_0:nextPlay()
				end)
			end
		end)
	end
end

function var_0_0.getPlayerName(arg_16_0)
	local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if not var_16_0.playerName or #var_16_0.playerName == 0 then
		return " "
	end

	return var_16_0.playerName
end

function var_0_0.onEnded(arg_17_0)
	xyd.WindowManager.get():closeWindow(arg_17_0)
end

function var_0_0.didClose(arg_18_0)
	if arg_18_0.isReOpenWindow_ then
		arg_18_0:hideOtherWindows(true)
	end
end

function var_0_0.willClose(arg_19_0)
	local var_19_0 = {
		assistID = arg_19_0.assistID
	}

	arg_19_0:dispatchEvent({
		name = xyd.event.STORY_COMPLETE,
		state = arg_19_0.storyState_,
		params = var_19_0
	})
end

return var_0_0
