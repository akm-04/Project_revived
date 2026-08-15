local var_0_0 = class("FishGamblingScheduleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFish
local var_0_3 = xyd.tables.activityFishGamblingOddSche
local var_0_4 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.baseInfo = arg_1_2.fish_fight_info.base_info
	arg_1_0.gameInfo = arg_1_2.fish_fight_info.game_info
	arg_1_0.stageInfo = arg_1_2.fish_fight_info.stage_info
	arg_1_0.round = arg_1_0.stageInfo.round

	if arg_1_0.round == 0 then
		arg_1_0.round = 1
	end

	arg_1_0.startTime = arg_1_2.start_time
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initMatchInfo()
	arg_2_0:layout()
end

function var_0_0.initMatchInfo(arg_3_0)
	arg_3_0.macthStartTime = {}
	arg_3_0.macthEndTime = {}

	for iter_3_0 = 1, 21 do
		arg_3_0.macthStartTime[iter_3_0] = var_0_3:startTime(iter_3_0)
		arg_3_0.macthEndTime[iter_3_0] = var_0_3:endTime(iter_3_0)
	end

	arg_3_0.time = xyd.ServerTime.get():getServerTime() - arg_3_0.startTime

	arg_3_0:updateMatchInfo(arg_3_0.time)

	arg_3_0.handler = var_0_4.scheduleGlobal(function()
		arg_3_0.time = arg_3_0.time + 1

		arg_3_0:updateMatchInfo(arg_3_0.time)
	end, 1)
end

function var_0_0.updateMatchInfo(arg_5_0, arg_5_1)
	local var_5_0
	local var_5_1 = true

	for iter_5_0 = 1, 21 do
		if arg_5_1 > arg_5_0.macthStartTime[iter_5_0] and arg_5_1 < arg_5_0.macthEndTime[iter_5_0] + 600 then
			arg_5_0.nowMatchCount = iter_5_0

			if not arg_5_0.preMatchCount then
				arg_5_0.showMatchCount = arg_5_0.nowMatchCount
				arg_5_0.preMatchCount = arg_5_0.nowMatchCount

				arg_5_0:nodeByName("text_round"):setString(var_0_3:name(iter_5_0) .. "：")
			elseif arg_5_0.preMatchCount ~= arg_5_0.nowMatchCount then
				arg_5_0:nodeByName("text_round"):setString(var_0_3:name(iter_5_0) .. "：")
			end

			if arg_5_1 < arg_5_0.macthEndTime[iter_5_0] + 300 then
				local var_5_2 = arg_5_0.macthEndTime[iter_5_0] + 300 - arg_5_1

				arg_5_0:nodeByName("text_time"):setString(string.format(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_3"), string.format(xyd.secondsToString1(var_5_2))))

				var_5_1 = false

				break
			end

			local var_5_3 = iter_5_0 % 7

			if var_5_3 == 0 then
				var_5_3 = 7
			end

			arg_5_0:nodeByName("icon_battle_" .. var_5_3)
			arg_5_0:nodeByName("text_time"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_4"))

			var_5_1 = false

			break
		end
	end

	if var_5_1 then
		arg_5_0.nowMatchCount = 21
		arg_5_0.showMatchCount = arg_5_0.nowMatchCount

		arg_5_0:nodeByName("text_round"):setString(var_0_1:translation("ACTIVITY_FISH_GAMBLING_TEXT_5"))
		arg_5_0:nodeByName("text_time"):setVisible(false)
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("text_title"):setString(var_0_1:translation("FIGHT_FISH_TEXT_1"))
	arg_6_0:nodeByName("text_title_2"):setString(string.format(var_0_1:translation("NUM_LUN"), var_0_1:translation("NUM_" .. arg_6_0.round)))
	arg_6_0:nodeByName("text_title_2"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_6_0:updateShow(1)
	arg_6_0:updateShow(2)
	arg_6_0:updateShow(3)
	arg_6_0:updateShow(4)
	arg_6_0:updateShow(5)
	arg_6_0:updateShow(6)
	arg_6_0:updateShow(7)
end

function var_0_0.updateShow(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.baseInfo[arg_7_0.round][arg_7_1]
	local var_7_1 = arg_7_0.gameInfo[arg_7_0.round][arg_7_1]

	arg_7_0:nodeByName("line_" .. arg_7_1 .. "_light"):setVisible(false)

	if #var_7_0 > 0 then
		if var_7_1 == 0 then
			if var_7_0[1] then
				arg_7_0:updateIcon("node_" .. arg_7_1 .. "_1", var_7_0[1].fish_id)
			end

			if var_7_0[2] then
				arg_7_0:updateIcon("node_" .. arg_7_1 .. "_2", var_7_0[2].fish_id)
			end

			arg_7_0:nodeByName("line_" .. arg_7_1):setVisible(true)
			arg_7_0:nodeByName("line_" .. arg_7_1 .. "_light"):setVisible(false)
		else
			if arg_7_1 == 7 then
				arg_7_0:updateIcon("node_8", var_7_0[var_7_1].fish_id, true)
			end

			if var_7_0[1] then
				arg_7_0:updateIcon("node_" .. arg_7_1 .. "_1", var_7_0[1].fish_id, var_7_1 == 1)
			end

			if var_7_0[2] then
				arg_7_0:updateIcon("node_" .. arg_7_1 .. "_2", var_7_0[2].fish_id, var_7_1 == 2)
			end

			arg_7_0:nodeByName("line_" .. arg_7_1):setVisible(false)
			arg_7_0:nodeByName("line_" .. arg_7_1 .. "_light"):setVisible(true)
			arg_7_0:nodeByName("line_" .. arg_7_1 .. "_light"):flipX(var_7_1 == 1)
		end
	end
end

function var_0_0.updateIcon(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = arg_8_0:nodeByName(arg_8_1)

	var_8_0:removeAllChildren()

	local var_8_1 = display.newNode()

	var_8_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_1:setContentSize(108, 108)

	local var_8_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. arg_8_2 .. ".png")

	var_8_2:setScale(0.9)

	local var_8_3 = xyd.getItemBg(var_0_2:rarity(arg_8_2))

	xyd.displaySpriteOnContainer(var_8_3, var_8_1)
	xyd.displaySpriteOnContainer(var_8_2, var_8_1, false)

	if arg_8_3 then
		local var_8_4 = xyd.AssetLoader.get():loadSprite("windows/fish_gambling/main/word_win.png")

		var_8_4:setScale(0.5)
		var_8_4:addTo(var_8_1)
		var_8_4:setPosition(84, 26)
	elseif arg_8_3 == false then
		xyd.GrayNode(var_8_1)

		local var_8_5 = xyd.AssetLoader.get():loadSprite("windows/fish_gambling/main/word_lose.png")

		var_8_5:setScale(0.5)
		var_8_5:addTo(var_8_1)
		var_8_5:setPosition(84, 26)
	end

	var_8_1:addTo(var_8_0)
end

function var_0_0.didOpen(arg_9_0)
	var_0_0.super.didOpen(arg_9_0)
	arg_9_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.willClose(arg_10_0)
	var_0_0.super.willClose(arg_10_0)

	if arg_10_0.handler then
		var_0_4.unscheduleGlobal(arg_10_0.handler)

		arg_10_0.handler = nil
	end
end

return var_0_0
