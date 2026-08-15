local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = "skeletons/ui_effect/activity_party/activity_party_choose_light"
local var_0_4 = "skeletons/ui_effect/activity_party/activity_party_chest"
local var_0_5 = import("app.model.Hero")
local var_0_6 = xyd.tables.activityCvWarmup
local var_0_7 = xyd.tables.activityPartyMission
local var_0_8 = xyd.tables.activityPartyTimeline
local var_0_9 = xyd.tables.fbShare
local var_0_10 = 1001
local var_0_11 = {
	Sub = 2,
	Main = 1
}
local var_0_12 = {
	OnTry = 2,
	NotOpen = 1,
	Show = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.showType = var_0_11.Main
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.musicSwitch = xyd.db.settings:getBackgroudMusicOn()
	arg_1_0.dialogSwitch = xyd.db.settings:getAutoDialog()
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	if var_2_0 then
		arg_2_0.container = var_2_0:getChildByName("container")
		arg_2_0.mainContainer = arg_2_0.container:getChildByName("main_container")
		arg_2_0.subContainer = arg_2_0.container:getChildByName("sub_container")

		var_2_0:addTo(arg_2_0.parent)
		var_2_0:setPosition(-9, -5)
		arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
			if arg_3_1 == ccui.TouchEventType.ended then
				local var_3_0 = {}

				var_3_0.title_name = "ACTIVITY_CV_RULE_TITLE"
				var_3_0.rule = "ACTIVITY_CV_RULE_TEXT"

				xyd.WindowManager.get():openWindow("text_rule", var_3_0)
			end
		end)
		arg_2_0.subContainer:getChildByName("return_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				arg_2_0.showType = var_0_11.Main

				arg_2_0:updateShow()
			end
		end)
		arg_2_0.subContainer:getChildByName("left_arrow"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				if arg_2_0.currentIndex >= #arg_2_0.cardItems then
					return
				end

				arg_2_0.currentIndex = arg_2_0.currentIndex + 1

				arg_2_0:playCardAnimation(true)
			end
		end)
		arg_2_0.subContainer:getChildByName("right_arrow"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				if arg_2_0.currentIndex <= 1 then
					arg_2_0.currentIndex = 1
				end

				arg_2_0.currentIndex = arg_2_0.currentIndex - 1

				arg_2_0:playCardAnimation(false)
			end
		end)
		arg_2_0.container:getChildByName("facebook_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.ended then
				if arg_2_0.details.base_info.is_awarded == 0 then
					arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, nil, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							if arg_8_1.awards then
								arg_2_0.selfPlayer:handleRewards(arg_8_1.awards)
							end

							if arg_8_1.base_info then
								arg_2_0.details.base_info = arg_8_1.base_info
							end

							arg_2_0:updateShare()
						end
					end)
				end

				local var_7_0 = var_0_9:content(var_0_10)
				local var_7_1 = ""
				local var_7_2 = xyd.split(var_7_0, "\n")

				for iter_7_0, iter_7_1 in ipairs(var_7_2) do
					var_7_1 = var_7_1 .. iter_7_1
				end

				xyd.fbShare(var_0_9:type(var_0_10), var_0_9:title(var_0_10), var_7_1, var_0_9:link(var_0_10), string.format(var_0_9:imgLink(var_0_10)))
			end
		end)

		local var_2_1 = arg_2_0.subContainer:getChildByName("bottom_container"):getChildByName("voice_bg")

		var_2_1:setTouchEnabled(true)
		var_2_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				return true
			elseif arg_9_0.name == "ended" then
				local var_9_0, var_9_1 = arg_2_0:getSoundFile()
				local var_9_2 = arg_2_0.subContainer:getChildByName("bottom_container")

				var_9_2:getChildByName("voice_num_txt"):setVisible(false)

				if arg_2_0.audioHandle then
					audio.stopSound(arg_2_0.audioHandle)

					arg_2_0.audioHandle = nil
				end

				if arg_2_0.handle then
					var_0_2.unscheduleGlobal(arg_2_0.handle)

					arg_2_0.handle = nil
				end

				arg_2_0.audioHandle = audio.playSound(var_9_0, false)

				arg_2_0:isStopBgSound(true)

				local var_9_3 = 0

				arg_2_0.handle = var_0_2.scheduleGlobal(function()
					if arg_2_0 and arg_2_0.subContainer and not tolua.isnull(arg_2_0.subContainer) then
						var_9_3 = var_9_3 + 1

						arg_2_0:updateVoiceIcon(var_9_3)

						if var_9_3 >= var_9_1 then
							if arg_2_0.handle then
								var_0_2.unscheduleGlobal(arg_2_0.handle)

								arg_2_0.handle = nil

								arg_2_0:isStopBgSound(false)
							end

							arg_2_0:updateVoiceIcon(3)
							var_9_2:getChildByName("voice_num_txt"):setVisible(true)
						end
					elseif arg_2_0.handle then
						var_0_2.unscheduleGlobal(arg_2_0.handle)

						arg_2_0.handle = nil
					end
				end, 1)
			end
		end)

		arg_2_0.currentPersonId = 1

		arg_2_0:updateMainContainer()
		arg_2_0:updateShow()

		local var_2_2 = arg_2_0.subContainer:getChildByName("bottom_container")

		var_2_2:getChildByName("person_name_txt"):enableOutline(cc.c4b(215, 120, 195, 255), 2)
		var_2_2:getChildByName("keyword_txt1"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

		for iter_2_0 = 2, 4 do
			var_2_2:getChildByName("keyword_txt" .. iter_2_0):enableOutline(cc.c4b(255, 95, 136, 255), 2)
		end

		arg_2_0:updateShare()
	end
end

function var_0_0.isStopBgSound(arg_11_0, arg_11_1)
	if arg_11_1 then
		xyd.db.settings:setBakgroundMusic(false)
		xyd.db.settings:setAutoDialog(false)
	else
		dump("111111111111111111")
		xyd.db.settings:setBakgroundMusic(arg_11_0.musicSwitch == 1)
		xyd.db.settings:setAutoDialog(arg_11_0.dialogSwitch == 1)
	end
end

function var_0_0.updateShare(arg_12_0)
	if arg_12_0.details.base_info.is_awarded == 1 then
		arg_12_0.container:getChildByName("share_text"):setVisible(false)
	else
		arg_12_0.container:getChildByName("share_text"):setVisible(true)
	end
end

function var_0_0.updateVoiceIcon(arg_13_0, arg_13_1)
	if arg_13_0 and arg_13_0.subContainer and not tolua.isnull(arg_13_0.subContainer) then
		local var_13_0 = arg_13_0.subContainer:getChildByName("bottom_container")
		local var_13_1 = (arg_13_1 - 1) % 3 + 1
		local var_13_2 = "windows/activities/1164/voice" .. var_13_1 .. ".png"
		local var_13_3 = xyd.AssetLoader.get():loadSprite(var_13_2)

		var_13_0:getChildByName("voice"):setSpriteFrame(var_13_3:getSpriteFrame())
	end
end

function var_0_0.getSoundFile(arg_14_0)
	local var_14_0 = var_0_6:girlsVoice(arg_14_0.currentPersonId)
	local var_14_1 = var_0_6:voicesTime(arg_14_0.currentPersonId)

	return var_14_0[arg_14_0.currentIndex], var_14_1[arg_14_0.currentIndex]
end

function var_0_0.canAward(arg_15_0)
	for iter_15_0 = 1, #arg_15_0.details.mission_list do
		local var_15_0 = arg_15_0.details.mission_list[iter_15_0]

		if var_15_0.is_complete == 1 and var_15_0.is_award == 0 then
			return true
		end
	end

	return false
end

function var_0_0.getMissionProgressInfo(arg_16_0, arg_16_1)
	local var_16_0 = arg_16_0.activity.start_time
	local var_16_1 = 1
	local var_16_2 = xyd.ServerTime.get():getServerTime() - var_16_0
	local var_16_3 = var_16_2 <= 0 and 1 or math.ceil(var_16_2 / 86400)
	local var_16_4 = math.ceil(var_16_3 / 7)
	local var_16_5 = (var_16_3 - 1) % 7 + 1
	local var_16_6 = {}

	if arg_16_1 < var_16_4 or arg_16_1 == var_16_4 and var_16_5 >= 6 then
		var_16_6.state = var_0_12.Show
		var_16_6.show_word_num = 7
	elseif arg_16_1 == var_16_4 then
		var_16_6.state = var_0_12.OnTry
		var_16_6.show_word_num = var_16_5
	else
		var_16_6.state = var_0_12.NotOpen
		var_16_6.show_word_num = 0
		var_16_6.wait_day = (arg_16_1 - 1) * 7 + 1 - var_16_3
	end

	return var_16_6
end

function var_0_0.updateMainContainer(arg_17_0)
	local var_17_0 = var_0_8:getPartners()

	arg_17_0.mainContainer:getChildByName("item_pos"):removeAllChildren(true)

	for iter_17_0 = 1, 3 do
		local var_17_1 = arg_17_0:getMissionProgressInfo(iter_17_0)
		local var_17_2 = var_17_1.state

		var_0_5.new():initUnCollected(var_17_0[iter_17_0])

		local var_17_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1164/item.csb")
		local var_17_4 = var_17_3:getChildByName("container")

		for iter_17_1 = 1, 3 do
			var_17_4:getChildByName("person_container" .. iter_17_1):setVisible(false)
		end

		local var_17_5 = var_17_4:getChildByName("person_container" .. var_17_2)

		var_17_5:setVisible(true)

		if var_17_2 == var_0_12.NotOpen then
			var_17_5:getChildByName("not_open_text"):setString(var_0_1:translation("CURRENT_NOT_OPEN"))
			var_17_5:getChildByName("not_open_text"):enableOutline(cc.c4b(5, 5, 94, 255), 2)
			var_17_5:getChildByName("open_time_txt"):setString(string.format(var_0_1:translation("ACTIVITY_OPEN_DAY_TIP"), var_17_1.wait_day))
		else
			var_17_5:getChildByName("try_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
				if arg_18_1 == ccui.TouchEventType.ended then
					arg_17_0.currentPersonId = iter_17_0
					arg_17_0.showType = var_0_11.Sub
					arg_17_0.currentIndex = 2

					arg_17_0:updateShow()
				end
			end)
		end

		if var_17_2 == var_0_12.Show then
			local var_17_6 = var_0_6:cvPicBig(iter_17_0)

			dump(var_17_6)

			icon = xyd.AssetLoader.get():loadSprite(var_17_6)

			local var_17_7 = xyd.AssetLoader:get():loadSprite("windows/activities/1164/avatar_bg3.png")
			local var_17_8 = var_17_5:getChildByName("avatar_container"):getContentSize()
			local var_17_9 = cc.ClippingNode:create()

			var_17_9:setStencil(var_17_7)
			var_17_9:setInverted(false)
			var_17_9:setAlphaThreshold(0)
			var_17_9:addChild(icon)
			icon:align(display.CENTER, var_17_8.width / 2, var_17_8.height / 2)
			icon:scale(var_17_8.width / icon:getWidth())
			var_17_7:addTo(var_17_5:getChildByName("avatar_container"), -1)
			var_17_7:align(display.CENTER, var_17_8.width / 2, var_17_8.height / 2)
			var_17_7:scale((var_17_8.width - 3) / var_17_7:getWidth())
			var_17_5:getChildByName("avatar_container"):addChild(var_17_9)
			var_17_5:getChildByName("name_txt"):setString(var_0_6:name(iter_17_0))
			var_17_5:getChildByName("name_txt"):enableOutline(cc.c4b(5, 5, 94, 255), 2)
		end

		var_17_3:addTo(arg_17_0.mainContainer:getChildByName("item_pos"))
		var_17_3:setPosition(cc.p((iter_17_0 - 1) * 230 - 35, -8))
	end
end

function var_0_0.updateSubContainer(arg_19_0)
	local var_19_0 = arg_19_0:getMissionProgressInfo(arg_19_0.currentPersonId)
	local var_19_1 = var_19_0.state
	local var_19_2 = arg_19_0.subContainer:getChildByName("bottom_container")

	var_19_2:getChildByName("voice_num_txt"):setVisible(true)

	if var_19_1 == var_0_12.Show then
		local var_19_3 = var_0_6:cvPicBig(arg_19_0.currentPersonId)
		local var_19_4 = xyd.AssetLoader.get():loadSprite(var_19_3)
		local var_19_5 = xyd.AssetLoader:get():loadSprite("windows/activities/1164/avatar_bg7.png")
		local var_19_6 = var_19_2:getChildByName("avatar_container"):getContentSize()
		local var_19_7 = cc.ClippingNode:create()

		var_19_7:setStencil(var_19_5)
		var_19_7:setInverted(false)
		var_19_7:setAlphaThreshold(0)
		var_19_7:addChild(var_19_4)
		var_19_4:align(display.CENTER, var_19_6.width / 2, var_19_6.height / 2)
		var_19_4:scale(var_19_6.width / var_19_4:getWidth())
		var_19_5:addTo(var_19_2:getChildByName("avatar_container"), -1)
		var_19_5:align(display.CENTER, var_19_6.width / 2, var_19_6.height / 2)
		var_19_5:scale((var_19_6.width - 3) / var_19_5:getWidth())
		var_19_2:getChildByName("avatar_container"):addChild(var_19_7)
		var_19_2:getChildByName("person_name_txt"):setString(var_0_6:name(arg_19_0.currentPersonId))
	else
		var_19_2:getChildByName("person_name_txt"):setString("")
		var_19_2:getChildByName("avatar_container"):removeAllChildren()
	end

	local var_19_8 = var_0_6:girls(arg_19_0.currentPersonId)
	local var_19_9 = false

	arg_19_0.currentIndex = math.ceil(#var_19_8 / 2)

	local var_19_10 = arg_19_0.currentIndex

	arg_19_0.subContainer:getChildByName("card_pos"):removeAllChildren(true)

	arg_19_0.cardItems = {}

	for iter_19_0 = 1, #var_19_8 do
		local var_19_11 = var_19_8[iter_19_0]
		local var_19_12 = "images/icon/cv/card/" .. var_19_11 .. "_dark.png"

		if iter_19_0 == var_19_10 then
			var_19_12 = "images/icon/cv/card/" .. var_19_11 .. "_light.png"
		end

		local var_19_13 = xyd.AssetLoader.get():loadSprite(var_19_12)

		var_19_13:setAnchorPoint(cc.p(0.5, 0))
		var_19_13:addTo(arg_19_0.subContainer:getChildByName("card_pos"))
		var_19_13:setPosition(cc.p((iter_19_0 - arg_19_0.currentIndex) * 200, 170))
		var_19_13:setScale(0.7)

		var_19_13.table_id = var_19_11

		if iter_19_0 == var_19_10 then
			var_19_13:setLocalZOrder(100)
		else
			var_19_13:setLocalZOrder(0)
		end

		table.insert(arg_19_0.cardItems, var_19_13)

		if math.abs(arg_19_0.currentIndex - iter_19_0) > 1 then
			var_19_13:setOpacity(0)
		end
	end

	arg_19_0:updateArrow()

	local var_19_14 = var_0_6:keyWords(arg_19_0.currentPersonId)

	for iter_19_1 = 1, 3 do
		var_19_2:getChildByName("keyword_txt" .. iter_19_1 + 1):setString(var_19_14[iter_19_1])

		if iter_19_1 <= var_19_0.show_word_num then
			local var_19_15 = xyd.AssetLoader.get():loadSprite("windows/activities/1164/keyword_bg2.png")

			var_19_2:getChildByName("keyword_txt" .. iter_19_1 + 1):setVisible(true)
			var_19_2:getChildByName("keyword_bg" .. iter_19_1 + 1):setSpriteFrame(var_19_15:getSpriteFrame())
		else
			local var_19_16 = xyd.AssetLoader.get():loadSprite("windows/activities/1164/keyword_bg3.png")

			var_19_2:getChildByName("keyword_txt" .. iter_19_1 + 1):setVisible(false)
			var_19_2:getChildByName("keyword_bg" .. iter_19_1 + 1):setSpriteFrame(var_19_16:getSpriteFrame())
		end
	end

	var_19_2:getChildByName("keyword_txt1"):setString(var_0_1:translation("ACTIVITY_CV_KEYWORD_TEXT"))

	local var_19_17 = string.format(var_0_1:translation("ACTIVITY_CV_TRY_TEXT"), xyd.tables.hero:name(var_19_8[arg_19_0.currentIndex]))

	var_19_2:getChildByName("hero_name_txt"):setString(var_19_17)
	var_19_2:getChildByName("hero_name_txt"):enableOutline(cc.c4b(73, 17, 177, 255), 2)

	local var_19_18, var_19_19 = arg_19_0:getSoundFile()

	var_19_2:getChildByName("voice_num_txt"):setString(var_19_19)
	var_19_2:getChildByName("voice_num_txt"):setColor(cc.c4b(241, 122, 175, 255))
end

function var_0_0.playCardAnimation(arg_20_0, arg_20_1)
	arg_20_0.subContainer:getChildByName("left_arrow"):setVisible(false)
	arg_20_0.subContainer:getChildByName("right_arrow"):setVisible(false)

	for iter_20_0 = 1, #arg_20_0.cardItems do
		local var_20_0 = arg_20_0.cardItems[iter_20_0]
		local var_20_1 = 0.5
		local var_20_2 = cc.p(var_20_0:getPosition())

		if arg_20_1 then
			var_20_2 = cc.p(var_20_2.x - 200, var_20_2.y)
		else
			var_20_2 = cc.p(var_20_2.x + 200, var_20_2.y)
		end

		local var_20_3 = cc.Spawn:create({
			cc.MoveTo:create(var_20_1, var_20_2)
		})

		if math.abs(arg_20_0.currentIndex - iter_20_0) > 1 then
			var_20_3 = cc.Spawn:create({
				cc.MoveTo:create(var_20_1, var_20_2),
				cc.FadeTo:create(var_20_1, 0)
			})
		else
			var_20_3 = cc.Spawn:create({
				cc.MoveTo:create(var_20_1, var_20_2),
				cc.FadeTo:create(var_20_1, 255)
			})
		end

		local var_20_4 = cc.Sequence:create({
			cc.CallFunc:create(function()
				if arg_20_0 and arg_20_0.subContainer and not tolua.isnull(arg_20_0.subContainer) then
					arg_20_0:updateCardStates()
				end
			end),
			var_20_3,
			cc.CallFunc:create(function()
				if arg_20_0 and arg_20_0.subContainer and not tolua.isnull(arg_20_0.subContainer) then
					arg_20_0:updateArrow()
				end
			end)
		})

		var_20_0:runActionOnce(var_20_4)
	end
end

function var_0_0.updateCardStates(arg_23_0)
	local var_23_0 = arg_23_0.subContainer:getChildByName("bottom_container")

	for iter_23_0 = 1, #arg_23_0.cardItems do
		local var_23_1 = arg_23_0.cardItems[iter_23_0].table_id
		local var_23_2 = "images/icon/cv/card/" .. var_23_1 .. "_dark.png"

		if iter_23_0 == arg_23_0.currentIndex then
			var_23_2 = "images/icon/cv/card/" .. var_23_1 .. "_light.png"

			local var_23_3 = string.format(var_0_1:translation("ACTIVITY_CV_TRY_TEXT"), xyd.tables.hero:name(var_23_1))

			var_23_0:getChildByName("hero_name_txt"):setString(var_23_3)
		end

		local var_23_4 = xyd.AssetLoader.get():loadSprite(var_23_2)

		arg_23_0.cardItems[iter_23_0]:setSpriteFrame(var_23_4:getSpriteFrame())
	end

	local var_23_5, var_23_6 = arg_23_0:getSoundFile()

	var_23_0:getChildByName("voice_num_txt"):setString(var_23_6)
end

function var_0_0.updateArrow(arg_24_0)
	arg_24_0.subContainer:getChildByName("left_arrow"):setVisible(true)
	arg_24_0.subContainer:getChildByName("right_arrow"):setVisible(true)

	if arg_24_0.currentIndex == 1 then
		arg_24_0.subContainer:getChildByName("right_arrow"):setVisible(false)
	elseif arg_24_0.currentIndex >= #arg_24_0.cardItems then
		arg_24_0.subContainer:getChildByName("left_arrow"):setVisible(false)
	end
end

function var_0_0.updateShow(arg_25_0)
	if arg_25_0.showType == var_0_11.Main then
		arg_25_0.mainContainer:setVisible(true)
		arg_25_0.subContainer:setVisible(false)
	else
		arg_25_0.mainContainer:setVisible(false)
		arg_25_0.subContainer:setVisible(true)
	end

	arg_25_0:updateSubContainer()
end

function var_0_0.update(arg_26_0)
	arg_26_0:updateCardInfo()
end

function var_0_0.scrollListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.scrollViewMoved_ = false
		arg_27_0.prevY_ = arg_27_1.y
	elseif arg_27_1.name == "moved" and 10 <= math.abs(arg_27_1.y - arg_27_0.prevY_) then
		arg_27_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_28_0)
	if arg_28_0.handle then
		var_0_2.unscheduleGlobal(arg_28_0.handle)

		arg_28_0.handle = nil
	end

	if arg_28_0.audioHandle then
		audio.stopSound(arg_28_0.audioHandle)

		arg_28_0.audioHandle = nil
	end

	arg_28_0:isStopBgSound(false)
end

return var_0_0
