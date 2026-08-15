local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.allNightCampaign
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.tables.misc
local var_0_5 = var_0_4:getValue("activity_polar_night_pool_coin")[1]
local var_0_6 = var_0_4:getValue("activity_polar_night_gacha_coin")[1]
local var_0_7 = var_0_4:getValue("activity_polar_night_boss_ticket")
local var_0_8 = var_0_4:getValue("activity_polar_night_campaign_unlock")[1]
local var_0_9 = var_0_4:getValue("activity_polar_night_boss_unlock")[1]
local var_0_10 = {
	message = var_0_1:translation("ACTIVITY_POLAR_NIGHT_1"),
	story = var_0_1:translation("ACTIVITY_POLAR_NIGHT_2"),
	storyChapter = var_0_1:translation("ACTIVITY_POLAR_NIGHT_3"),
	explore = var_0_1:translation("ACTIVITY_POLAR_NIGHT_4"),
	exploreChapter = var_0_1:translation("ACTIVITY_POLAR_NIGHT_5"),
	boss = var_0_1:translation("ACTIVITY_POLAR_NIGHT_6"),
	boss2 = var_0_1:translation("ACTIVITY_POLAR_NIGHT_7"),
	bossChapter = var_0_1:translation("ACTIVITY_POLAR_NIGHT_8")
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.allNight = xyd.ModelManager.get():loadModel(xyd.ModelType.ALL_NIGHT)

	dump(arg_1_0.activity)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))

	arg_2_0.container = var_2_0:getChildByName("conatiner")

	cc.EventProxy.new(xyd.EventDispatcher.get(), var_2_0):addEventListener(xyd.event.ALL_NIGHT_POOL_CHANGE, handler(arg_2_0, arg_2_0.updatePoolShow))
	cc.EventProxy.new(xyd.EventDispatcher.get(), var_2_0):addEventListener(xyd.event.ALL_NIGHT_ECONOMY_UPDATE, handler(arg_2_0, arg_2_0.updateCoin))
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.container:getChildByName("btn_gacha_1"):getChildByName("txt_gacha_1"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT2"))
	arg_3_0.container:getChildByName("btn_gacha_2"):getChildByName("txt_gacha_2"):setString(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT1"))

	local var_3_0 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/coin_1.png")
	local var_3_1 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/coin_2.png")
	local var_3_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1199/coin_3.png")

	arg_3_0.container:getChildByName("bg_coin_1"):getChildByName("pos_1"):addChild(var_3_0)
	arg_3_0.container:getChildByName("bg_coin_2"):getChildByName("pos_2"):addChild(var_3_1)
	arg_3_0.container:getChildByName("bg_coin_3"):getChildByName("pos_3"):addChild(var_3_2)
	arg_3_0.container:getChildByName("bg_message"):getChildByName("txt_message"):setString(var_0_10.message)
	arg_3_0.container:getChildByName("btn_story"):getChildByName("txt_story"):setString(var_0_10.story)
	arg_3_0.container:getChildByName("btn_explore"):getChildByName("txt_explore"):setString(var_0_10.explore)
	arg_3_0.container:getChildByName("btn_explore_close"):getChildByName("txt_explore_close"):setString(var_0_10.explore)

	local var_3_3 = math.floor(var_0_8 / 1000)
	local var_3_4 = var_0_8 % 100
	local var_3_5 = string.format(var_0_10.exploreChapter, var_3_3, var_3_4)

	arg_3_0.container:getChildByName("btn_explore_close"):getChildByName("txt_chapter_close"):setString(var_3_5)
	arg_3_0.container:getChildByName("btn_boss"):getChildByName("txt_boss"):setString(var_0_10.boss)
	arg_3_0.container:getChildByName("btn_boss_close"):getChildByName("txt_boss_close"):setString(var_0_10.boss2)

	local var_3_6 = math.floor(var_0_9 / 1000)
	local var_3_7 = var_0_9 % 100
	local var_3_8 = string.format(var_0_10.bossChapter, var_3_6, var_3_7)

	arg_3_0.container:getChildByName("btn_boss_close"):getChildByName("txt_boss_enter_close"):setString(var_3_8)

	local var_3_9 = {}

	if arg_3_0.activity.campaign_info then
		var_3_9 = arg_3_0.activity.campaign_info.campaign_list
	end

	if var_3_9[tostring(var_0_8)] and var_3_9[tostring(var_0_8)].star > 0 then
		arg_3_0.container:getChildByName("btn_explore"):setVisible(true)
		arg_3_0.container:getChildByName("btn_explore_close"):setVisible(false)
	else
		arg_3_0.container:getChildByName("btn_explore"):setVisible(false)
		arg_3_0.container:getChildByName("btn_explore_close"):setVisible(true)
	end

	if var_3_9[tostring(var_0_9)] and var_3_9[tostring(var_0_9)].star > 0 then
		arg_3_0.container:getChildByName("btn_boss"):setVisible(true)
		arg_3_0.container:getChildByName("btn_boss_close"):setVisible(false)
	else
		arg_3_0.container:getChildByName("btn_boss"):setVisible(false)
		arg_3_0.container:getChildByName("btn_boss_close"):setVisible(true)
	end

	local var_3_10 = var_0_2:ids()
	local var_3_11 = var_0_2:startPoints()
	local var_3_12 = var_3_11[1]
	local var_3_13 = var_3_11[2]

	while var_0_2:nextCampaignId(var_3_12)[1] ~= 0 do
		if not var_3_9[tostring(var_3_12)] or var_3_9[tostring(var_3_12)].star == 0 then
			break
		end

		var_3_12 = var_0_2:nextCampaignId(var_3_12)[1]
	end

	arg_3_0.container:getChildByName("btn_story"):getChildByName("txt_chapter"):setString(string.format(var_0_10.storyChapter, math.ceil(var_3_12 % 1000)))

	while var_0_2:nextCampaignId(var_3_13)[1] ~= 0 do
		if not var_3_9[tostring(var_3_13)] or var_3_9[tostring(var_3_13)].star == 0 then
			break
		end

		var_3_13 = var_0_2:nextCampaignId(var_3_13)[1]
	end

	arg_3_0.container:getChildByName("btn_explore"):getChildByName("txt_explore_chapter"):setString(string.format(var_0_10.storyChapter, math.ceil(var_3_13 % 1000)))
	arg_3_0:updateCoin()
	arg_3_0:initBtn()
	arg_3_0:updatePoolShow()
end

function var_0_0.updateCoin(arg_4_0)
	local var_4_0 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(var_0_5)
	local var_4_1 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(var_0_6)
	local var_4_2 = arg_4_0.selfPlayer:getBackpack():getItemNumByID(var_0_7)

	arg_4_0.container:getChildByName("bg_coin_1"):getChildByName("txt_num_1"):setString(var_4_0)
	arg_4_0.container:getChildByName("bg_coin_2"):getChildByName("txt_num_2"):setString(var_4_1)
	arg_4_0.container:getChildByName("bg_coin_3"):getChildByName("txt_num_3"):setString(var_4_2)
end

function var_0_0.initBtn(arg_5_0)
	local var_5_0 = arg_5_0.container:getChildByName("btn_story")

	var_5_0:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_5_0:setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_5_0:setScale(1)
			arg_5_0.allNight:enterMap(nil, 1)
		end
	end)

	local var_5_1 = arg_5_0.container:getChildByName("btn_explore")

	var_5_1:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.began then
			var_5_1:setScale(0.9)
		elseif arg_7_1 == ccui.TouchEventType.ended then
			var_5_1:setScale(1)
			arg_5_0.allNight:enterMap(nil, 2)
		end
	end)

	local var_5_2 = arg_5_0.container:getChildByName("btn_boss")

	var_5_2:addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.began then
			var_5_2:setScale(0.9)
		elseif arg_8_1 == ccui.TouchEventType.ended then
			var_5_2:setScale(1)
			xyd.WindowManager.get():openWindow("all_night_boss")
		end
	end)
	arg_5_0.container:getChildByName("btn_gacha_1"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			arg_5_0.allNight:enterLightGacha()
		end
	end)
	arg_5_0.container:getChildByName("btn_gacha_2"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended then
			arg_5_0.allNight:enterDarkGacha()
		end
	end)
end

function var_0_0.updateMapEnter(arg_11_0, arg_11_1)
	local var_11_0 = arg_11_1.campaign_id

	if var_11_0 == var_0_8 then
		arg_11_0.container:getChildByName("btn_explore"):setVisible(true)
		arg_11_0.container:getChildByName("btn_explore_close"):setVisible(false)
	else
		arg_11_0.container:getChildByName("btn_explore"):setVisible(false)
		arg_11_0.container:getChildByName("btn_explore_close"):setVisible(true)
	end

	if var_11_0 == var_0_9 then
		arg_11_0.container:getChildByName("btn_boss"):setVisible(true)
		arg_11_0.container:getChildByName("btn_boss_close"):setVisible(false)
	else
		arg_11_0.container:getChildByName("btn_boss"):setVisible(false)
		arg_11_0.container:getChildByName("btn_boss_close"):setVisible(true)
	end
end

function var_0_0.updatePoolShow(arg_12_0)
	local var_12_0 = arg_12_0.allNight.pool

	if var_12_0 then
		local var_12_1

		if var_12_0 <= 10 then
			var_12_1 = var_12_0
		else
			var_12_1 = "10+"
		end

		local var_12_2 = string.format(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT17"), var_12_1)

		arg_12_0.container:getChildByName("btn_gacha_1"):getChildByName("txt_process"):setString(var_12_2)

		return
	else
		arg_12_0.allNight:AllNightInfo(nil, function(arg_13_0, arg_13_1)
			if arg_13_0 == xyd.error.OK then
				var_12_0 = arg_13_1.pool_info.base_info.pool_id

				local var_13_0

				if var_12_0 <= 10 then
					var_13_0 = var_12_0
				else
					var_13_0 = "10+"
				end

				local var_13_1 = string.format(var_0_1:translation("ACTIVITY_POLAR_NIGHT_GACHA_TEXT17"), var_13_0)

				arg_12_0.container:getChildByName("btn_gacha_1"):getChildByName("txt_process"):setString(var_13_1)
			end
		end)
	end
end

return var_0_0
