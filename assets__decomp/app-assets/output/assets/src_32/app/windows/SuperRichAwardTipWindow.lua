local var_0_0 = class("SuperRichAwardTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "windows/zillionaire/main/"
local var_0_3 = class("Activity", import("app.windows.activities.BaseActivity"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.gridInfo = arg_1_2.info
	arg_1_0.stationType = arg_1_2.grid_type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 155))
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("sub_title_txt"):setString("")
	arg_4_0:nodeByName("text1"):setString("")
	arg_4_0:nodeByName("text2"):setString("")
	arg_4_0:nodeByName("sub_title_txt"):enableOutline(cc.c4b(128, 71, 21, 255), 2)

	local var_4_0 = false

	if arg_4_0.stationType == 6 then
		local var_4_1 = arg_4_0.superRich.fightInfo

		if var_4_1.lev >= 10 then
			var_4_0 = true
		end

		local var_4_2 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "challenge_text.png")

		arg_4_0:nodeByName("title"):setSpriteFrame(var_4_2:getSpriteFrame())
		arg_4_0:nodeByName("sub_title_txt"):setString(string.format(var_0_1:translation("SUPER_RICH_AWARD_TEXT6"), var_4_1.lev))
		arg_4_0:nodeByName("text1"):setString(var_0_1:translation("SUPER_RICH_AWARD_TEXT1"))
		arg_4_0:nodeByName("text2"):setString(var_0_1:translation("SUPER_RICH_AWARD_TEXT2"))

		local var_4_3 = xyd.tables.misc.activityRichBattleRewardTime

		var_0_3:rewardFormat(arg_4_0:nodeByName("reward_container1"), var_4_3)

		local var_4_4 = xyd.tables.misc.activityRichBattleReward

		var_0_3:rewardFormat(arg_4_0:nodeByName("reward_container2"), var_4_4)
	elseif arg_4_0.stationType == 7 then
		local var_4_5 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "pipe_text.png")

		arg_4_0:nodeByName("title"):setSpriteFrame(var_4_5:getSpriteFrame())
		arg_4_0:nodeByName("text1"):setString(var_0_1:translation("SUPER_RICH_AWARD_TEXT5"))

		local var_4_6 = xyd.tables.misc.activityRichWaterPipeReward

		var_0_3:rewardFormat(arg_4_0:nodeByName("reward_container1"), var_4_6)
		arg_4_0:nodeByName("text1"):setPositionY(208)
		arg_4_0:nodeByName("reward_container1"):setPositionY(208)
	elseif arg_4_0.stationType == 8 then
		if arg_4_0.superRich.missionInfo.lev >= 16 then
			var_4_0 = true
		end

		local var_4_7 = xyd.AssetLoader.get():loadSprite(var_0_2 .. "wheel_text.png")

		arg_4_0:nodeByName("title"):setSpriteFrame(var_4_7:getSpriteFrame())
		arg_4_0:nodeByName("sub_title_txt"):setString(string.format(var_0_1:translation("SUPER_RICH_AWARD_TEXT7"), arg_4_0.superRich.missionInfo.lev))
		arg_4_0:nodeByName("text1"):setString(var_0_1:translation("SUPER_RICH_AWARD_TEXT3"))
		arg_4_0:nodeByName("text2"):setString(var_0_1:translation("SUPER_RICH_AWARD_TEXT4"))

		local var_4_8 = xyd.tables.misc.activityRichWheeelRewardTime

		var_0_3:rewardFormat(arg_4_0:nodeByName("reward_container1"), var_4_8)

		local var_4_9 = xyd.tables.misc.activityRichWheelReward

		var_0_3:rewardFormat(arg_4_0:nodeByName("reward_container2"), var_4_9)
	end

	if var_4_0 then
		arg_4_0:nodeByName("text1"):setVisible(false)
		arg_4_0:nodeByName("reward_container1"):setVisible(false)
		arg_4_0:nodeByName("text2"):setPositionY(208)
		arg_4_0:nodeByName("reward_container2"):setPositionY(208)
	end
end

return var_0_0
