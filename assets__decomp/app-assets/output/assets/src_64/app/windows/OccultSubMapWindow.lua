local var_0_0 = class("OccultSubMapWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.creatsCampaign
local var_0_4 = xyd.tables.creatsChapterSelect
local var_0_5 = "skeletons/ui_effect/occult/battle"
local var_0_6 = "skeletons/ui_effect/occult/cloud"
local var_0_7 = "skeletons/simashi/simashishouji03"
local var_0_8 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.chatWinIsShow = false
	arg_1_0.chapterId = arg_1_0.occult.baseInfo.chapter_id
	arg_1_0.campaignItems = {}
	arg_1_0.companionItems = {}
	arg_1_0.occultCampaignType = arg_1_0.occult:getRoomCampaignType()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0.occult:playStorys()
	arg_3_0.occult:handleInvite()
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super.didClose(arg_4_0, arg_4_1)

	if arg_4_0.handle then
		var_0_2.unscheduleGlobal(arg_4_0.handle)

		arg_4_0.handle = nil
	end
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = {
		isEcoBar = 0,
		show_rule = true
	}

	arg_5_0:addTopSidebar(var_5_0)
	arg_5_0:nodeByName("progress_txt"):setString(var_0_1:translation(""))
	arg_5_0:nodeByName("down_time_txt"):setString(var_0_1:translation(""))
	arg_5_0:nodeByName("progress_text"):setString(var_0_1:translation("RATE_OF_ADVANCE"))
	arg_5_0:nodeByName("text_log"):setString(var_0_1:translation("OCCULT_DIALOG_TEXT"))
	arg_5_0:setButtonClick()
	arg_5_0:createScheduler()
	arg_5_0:updateMapShow()
	arg_5_0:updateCompanionsInfo()
	arg_5_0:updateCompanionPosition()
	arg_5_0:updateRedMark(false)

	if arg_5_0.occultCampaignType == xyd.OccultRoomType.MULTI_PLAYER then
		arg_5_0:showChatWin()
	else
		arg_5_0:nodeByName("chat_container"):setVisible(false)
		arg_5_0:nodeByName("btn_chat"):setVisible(false)
	end
end

function var_0_0.updateCompanionPosition(arg_6_0)
	local var_6_0 = 0

	for iter_6_0, iter_6_1 in pairs(arg_6_0.occult.heroStat) do
		var_6_0 = var_6_0 + 1

		local var_6_1 = arg_6_0:getStayPos(iter_6_0)
		local var_6_2 = iter_6_1.player_info

		if not arg_6_0.companionItems[tostring(var_6_2.player_id)] then
			local var_6_3 = display.newNode()

			var_6_3:setContentSize(40, 40)
			xyd.setPlayerAvatar(var_6_3, var_6_2)

			local var_6_4 = "windows/occult/sub_map/avtar_arrow" .. tostring(var_6_0) .. ".png"
			local var_6_5 = xyd.AssetLoader.get():loadSprite(var_6_4)

			var_6_5:addTo(var_6_3)
			var_6_5:setAnchorPoint(cc.p(0.5, 1))
			var_6_5:setPosition(cc.p(var_6_3:getContentSize().width / 2, 0))
			var_6_3:setAnchorPoint(cc.p(0.5, 0))
			var_6_3:addTo(arg_6_0:nodeByName("avatar_pos"))

			arg_6_0.companionItems[tostring(var_6_2.player_id)] = var_6_3
		end

		local var_6_6 = arg_6_0:getStayPosIndex(iter_6_0, var_6_1)
		local var_6_7 = arg_6_0:getStayPosNum(var_6_1)
		local var_6_8 = 0

		if var_6_6 == 1 and var_6_7 >= 2 then
			var_6_8 = -30
		elseif var_6_6 == 3 and var_6_7 == 3 then
			var_6_8 = 30
		end

		local var_6_9 = arg_6_0.companionItems[tostring(var_6_2.player_id)]
		local var_6_10 = arg_6_0.campaignItems[tostring(var_6_1)]
		local var_6_11 = cc.p(var_6_10:getPosition())

		var_6_9:setPosition(cc.p(var_6_11.x + var_6_8, var_6_11.y + 50))
	end
end

function var_0_0.getStayPos(arg_7_0, arg_7_1)
	local var_7_0 = arg_7_0.occult.heroStat[tostring(arg_7_1)]

	for iter_7_0, iter_7_1 in pairs(arg_7_0.occult.openCampaigns) do
		local var_7_1 = iter_7_1.in_battle

		if xyd.isInTable(var_7_1, tonumber(arg_7_1)) then
			return iter_7_0
		end
	end

	return var_7_0.hero_stat.stay_pos
end

function var_0_0.updateBattleEffect(arg_8_0)
	arg_8_0:nodeByName("effect_pos"):removeAllChildren()

	for iter_8_0, iter_8_1 in pairs(arg_8_0.occult.openCampaigns) do
		local var_8_0 = iter_8_1.in_battle

		if arg_8_0:isInBattleing(var_8_0) then
			local var_8_1 = arg_8_0:createEffect(var_0_5)

			var_8_1:addTo(arg_8_0:nodeByName("effect_pos"))
			var_8_1:play(nil, true)
			var_8_1:setScale(0.7)

			local var_8_2 = arg_8_0:createEffect(var_0_6)

			var_8_2:addTo(arg_8_0:nodeByName("effect_pos"))
			var_8_2:play(nil, true)

			local var_8_3 = arg_8_0.campaignItems[tostring(iter_8_0)]
			local var_8_4 = cc.p(var_8_3:getPosition())

			var_8_1:setPosition(cc.p(var_8_4.x, var_8_4.y))
			var_8_2:setPosition(cc.p(var_8_4.x, var_8_4.y))
		end
	end
end

function var_0_0.createEffect(arg_9_0, arg_9_1)
	local var_9_0 = arg_9_1 .. ".json"
	local var_9_1 = arg_9_1 .. ".atlas"
	local var_9_2 = var_0_8.new(var_9_0, var_9_1, 1)

	var_9_2:setAnchorPoint(cc.p(0.5, 0.5))

	return var_9_2
end

function var_0_0.isInBattleing(arg_10_0, arg_10_1)
	for iter_10_0 = 1, #arg_10_1 do
		if arg_10_1[iter_10_0] > 0 then
			return true
		end
	end

	return false
end

function var_0_0.getStayPosIndex(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = 1

	for iter_11_0, iter_11_1 in pairs(arg_11_0.occult.heroStat) do
		if tonumber(arg_11_1) ~= tonumber(iter_11_0) and arg_11_0:getStayPos(iter_11_0) == arg_11_2 then
			var_11_0 = var_11_0 + 1
		elseif tonumber(arg_11_1) == tonumber(iter_11_0) then
			return var_11_0
		end
	end

	return var_11_0
end

function var_0_0.getStayPosNum(arg_12_0, arg_12_1)
	local var_12_0 = 0

	for iter_12_0, iter_12_1 in pairs(arg_12_0.occult.heroStat) do
		if arg_12_0:getStayPos(iter_12_0) == arg_12_1 then
			var_12_0 = var_12_0 + 1
		end
	end

	return var_12_0
end

function var_0_0.updateMapShow(arg_13_0)
	arg_13_0.buildings = {}

	local var_13_0 = arg_13_0:nodeByName("map_container")

	var_13_0:removeAllChildren(true)

	local var_13_1 = var_0_4:chapterMap(arg_13_0.chapterId)
	local var_13_2 = xyd.SpriteLoader.new(var_13_1, nil, nil, xyd.DefaultImageType.MAP)

	var_13_2:addTo(var_13_0)

	local var_13_3 = var_13_0:getContentSize()

	var_13_2:setPosition(cc.p(var_13_3.width / 2, var_13_3.height / 2))

	local var_13_4 = var_0_4:chapterLine(arg_13_0.chapterId)
	local var_13_5 = xyd.AssetLoader.get():loadSprite(var_13_4)

	var_13_5:addTo(var_13_0)

	local var_13_6 = var_13_0:getContentSize()

	var_13_5:setPosition(cc.p(var_13_6.width / 2, var_13_6.height / 2))

	local var_13_7 = var_0_3:getCampaignIds(arg_13_0.chapterId, arg_13_0.occultCampaignType)
	local var_13_8 = {}

	for iter_13_0 = 1, #var_13_7 do
		local var_13_9 = var_13_7[iter_13_0]
		local var_13_10 = var_0_3:model(var_13_9)

		if var_13_10 > 0 then
			table.insert(var_13_8, var_13_10)
		end
	end

	for iter_13_1 = 1, #var_13_7 do
		local var_13_11 = var_13_7[iter_13_1]
		local var_13_12 = var_0_3:x(var_13_11)
		local var_13_13 = var_0_3:y(var_13_11)
		local var_13_14 = var_0_3:icon(var_13_11)
		local var_13_15 = var_0_3:icon1(var_13_11)
		local var_13_16 = var_0_3:model(var_13_11)

		if var_13_16 > 0 then
			local var_13_17 = xyd.HeroAnimation.new(nil, var_13_16, xyd.tables.model:uiScale(var_13_16), {})

			var_13_17:addTo(var_13_0)
			var_13_17:setPosition(cc.p(var_13_12, var_13_13))
			var_13_17:idle()
			var_13_17:setFlipX(true)
			var_13_17:setLocalZOrder(#var_13_7 - iter_13_1)

			local var_13_18 = display.newNode()

			var_13_18:setContentSize(var_13_17:getContentSize())
			var_13_18:setAnchorPoint(cc.p(0.5, 0))
			var_13_18:setTouchEnabled(true)
			var_13_18:addTo(var_13_17)
			var_13_18:setPosition(0, 0)
			var_13_18:setTouchSwallowEnabled(true)
			var_13_18:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
				if arg_14_0.name == "began" then
					return true
				elseif arg_14_0.name == "ended" then
					arg_13_0:handleTouchBuilding(var_13_11)
				end
			end)

			arg_13_0.campaignItems[tostring(var_13_11)] = var_13_17
		else
			local var_13_19 = xyd.AssetLoader.get():loadSprite(var_13_14)

			if not xyd.isInTable(table.keys(arg_13_0.occult.openCampaigns), tostring(var_13_11)) and var_0_3:isStartPoint(var_13_11) == 0 then
				var_13_19 = display.newFilteredSprite(var_13_14, "GRAY", {
					0.2,
					0.3,
					0.5,
					0.1
				})
			elseif not arg_13_0.occult:isCampaignPass(var_13_11) then
				var_13_19 = xyd.AssetLoader.get():loadSprite(var_13_15)

				if var_0_3:isStartPoint(var_13_11) == 0 then
					local var_13_20 = arg_13_0:createEffect(var_0_7)

					var_13_20:addTo(var_13_19)
					var_13_20:setPosition(cc.p(var_13_19:getContentSize().width / 2, var_13_19:getContentSize().height / 2))
					var_13_20:setScale(0.5)
					var_13_20:play(nil, true)
				end
			end

			var_13_19:addTo(var_13_0)
			var_13_19:setPosition(cc.p(var_13_12, var_13_13))

			arg_13_0.buildings[var_13_11] = var_13_19

			var_13_19:setTouchEnabled(true)
			var_13_19:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_15_0)
				if arg_15_0.name == "began" then
					return true
				elseif arg_15_0.name == "ended" then
					xyd.playButtonSound()
					arg_13_0:handleTouchBuilding(var_13_11)
				end
			end)
			var_13_19:setLocalZOrder(#var_13_7 - iter_13_1)

			arg_13_0.campaignItems[tostring(var_13_11)] = var_13_19
		end
	end

	arg_13_0:updateBattleEffect()
	arg_13_0:updateCompanionPosition()
	arg_13_0:nodeByName("progress_txt"):setString(tostring(math.floor(arg_13_0.occult.progress * 100)) .. "%")
	arg_13_0:nodeByName("progress_bar"):setPercent(math.floor(arg_13_0.occult.progress * 100))
end

function var_0_0.handleTouchBuilding(arg_16_0, arg_16_1)
	if var_0_3:isStartPoint(arg_16_1) == 1 then
		if arg_16_0.occult.heroStat[tostring(arg_16_0.selfPlayer.playerID)].hero_stat.stay_pos == arg_16_1 then
			return
		end

		local var_16_0 = {
			stay_pos = arg_16_1
		}

		arg_16_0.occult:changePos(var_16_0, function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK then
				-- block empty
			end
		end)

		return
	end

	if not xyd.isInTable(table.keys(arg_16_0.occult.openCampaigns), tostring(arg_16_1)) then
		local var_16_1 = {
			campaign_id = arg_16_1
		}

		xyd.WindowManager.get():openWindow("occult_campaign_only_detail", var_16_1)

		return
	end

	local var_16_2 = {
		campaign_id = arg_16_1,
		stay_pos = var_0_3:getParentCampaignId(arg_16_1)
	}

	arg_16_0.occult:getCampaignInfo(var_16_2, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			local var_18_0 = var_0_3:getParentCampaignId(arg_16_1)

			arg_16_0.occult.heroStat[tostring(arg_16_0.selfPlayer.playerID)].hero_stat.stay_pos = var_18_0

			arg_16_0:updateCompanionPosition()

			local var_18_1 = {
				monster_infos = arg_18_1.monster_infos,
				campaign_id = arg_16_1
			}

			xyd.WindowManager.get():openWindow("occult_campaign_detail", var_18_1)
		end
	end)
end

function var_0_0.updateCompanionsInfo(arg_19_0)
	local var_19_0 = 1
	local var_19_1 = 0

	for iter_19_0, iter_19_1 in pairs(arg_19_0.occult.heroStat) do
		var_19_1 = var_19_1 + 1

		if iter_19_0 == tostring(arg_19_0.selfPlayer.playerID) and arg_19_0.occultCampaignType == xyd.OccultRoomType.SINGLE_PLAYER or iter_19_0 ~= tostring(arg_19_0.selfPlayer.playerID) and arg_19_0.occultCampaignType == xyd.OccultRoomType.MULTI_PLAYER then
			arg_19_0:updateCompanionContainer(arg_19_0:nodeByName("companion" .. tostring(var_19_0)), iter_19_1, var_19_1)

			var_19_0 = var_19_0 + 1
		end
	end

	if arg_19_0.occultCampaignType == xyd.OccultRoomType.SINGLE_PLAYER then
		arg_19_0:nodeByName("companion2"):setVisible(false)
	end
end

function var_0_0.updateCompanionContainer(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = arg_20_2.player_info
	local var_20_1 = arg_20_2.hero_stat

	xyd.setPlayerInfoContainer(arg_20_1, var_20_0)
	arg_20_1:getChildByName("live_num_txt"):setString(var_20_1.dispatch)
	arg_20_1:getChildByName("dead_num_txt"):setString(var_20_1.dead)
	arg_20_1:getChildByName("partner_info_bg1"):setVisible(false)
	arg_20_1:getChildByName("partner_info_bg2"):setVisible(false)
	arg_20_1:getChildByName("partner_info_bg3"):setVisible(false)
	arg_20_1:getChildByName("partner_info_bg" .. tostring(arg_20_3)):setVisible(true)

	if var_20_0.is_online == 0 then
		arg_20_1:getChildByName("online_text"):setVisible(false)
		arg_20_1:getChildByName("off_text"):setVisible(true)
	else
		arg_20_1:getChildByName("online_text"):setVisible(true)
		arg_20_1:getChildByName("off_text"):setVisible(false)
	end

	arg_20_1:getChildByName("partner_info_bg" .. tostring(arg_20_3)):setTouchEnabled(true)
	arg_20_1:getChildByName("partner_info_bg" .. tostring(arg_20_3)):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
		if arg_21_0.name == "began" then
			arg_20_1:setScale(0.9)

			return true
		elseif arg_21_0.name == "ended" then
			xyd.playButtonSound()
			arg_20_1:setScale(1)

			local var_21_0 = {
				player_id = var_20_0.player_id
			}

			arg_20_0.occult:getMemberStatInfo(var_21_0, function(arg_22_0, arg_22_1)
				if arg_22_1 and arg_22_0 == xyd.error.OK then
					arg_22_1.player_id = var_21_0.player_id

					xyd.WindowManager.get():openWindow("occult_companion_info", arg_22_1)
				end
			end)
		end
	end)
end

function var_0_0.createScheduler(arg_23_0)
	if arg_23_0.handle then
		var_0_2.unscheduleGlobal(arg_23_0.handle)

		arg_23_0.handle = nil
	end

	arg_23_0.downTime = arg_23_0.occult.roomInfo.start_time + xyd.tables.misc.creatsCampaignDuration - xyd.ServerTime.get():getServerTime()

	arg_23_0:updateTimeShow()

	arg_23_0.handle = var_0_2.scheduleGlobal(function()
		arg_23_0.downTime = arg_23_0.downTime - 1

		arg_23_0:updateTimeShow()

		if arg_23_0.downTime <= 0 then
			var_0_2.unscheduleGlobal(arg_23_0.handle)

			arg_23_0.handle = nil

			arg_23_0.occult:subMapEnded(true)
			xyd.WindowManager.get():closeWindow(arg_23_0)
		end
	end, 1)
end

function var_0_0.updateTimeShow(arg_25_0)
	local var_25_0 = arg_25_0.downTime

	if var_25_0 < 0 then
		var_25_0 = 0
	end

	arg_25_0:nodeByName("down_time_txt"):setString(xyd.secondsToString(var_25_0))
end

function var_0_0.setButtonClick(arg_26_0)
	arg_26_0:nodeByName("top_sidebar")
	arg_26_0:nodeByName("top_sidebar"):nodeByName("rule")
	xyd.nodeEventSample(arg_26_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_27_0)
		local var_27_0 = {}

		var_27_0.title_name = "OCCLUT_RULE_TITLE"
		var_27_0.rule = "OCCLUT_RULE_TEXT"
		var_27_0.style = xyd.RuleStyle.BLUE

		xyd.WindowManager.get():openWindow("new_text_rule", var_27_0)
	end)
	arg_26_0:nodeByName("log_btn"):addTouchEventListener(function(arg_28_0, arg_28_1)
		xyd.buttonScaleAnim(arg_28_0, arg_28_1)

		if arg_28_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_28_0 = {}

			arg_26_0.occult:getCampaignLogList(var_28_0, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					local var_29_0 = {
						log_list = arg_29_1.log_list
					}

					xyd.WindowManager.get():openWindow("occult_campaign_log", var_29_0)
				end
			end)
		end
	end)
	arg_26_0:nodeByName("btn_chat"):setTouchEnabled(true)

	local var_26_0 = display.newNode()

	var_26_0:setTouchEnabled(true)
	var_26_0:setTouchSwallowEnabled(true)
	var_26_0:setContentSize(arg_26_0:nodeByName("btn_chat"):getContentSize())
	var_26_0:addTo(arg_26_0:nodeByName("btn_chat"))
	arg_26_0:nodeByName("btn_chat"):addTouchEventListener(function(arg_30_0, arg_30_1)
		if arg_30_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_26_0:nodeByName("btn_chat"):setScale(1)
			arg_26_0:showChatWin()
			arg_26_0:updateRedMark(false)
		end
	end)
end

function var_0_0.showChatWin(arg_31_0)
	if arg_31_0.chatWinIsShow then
		arg_31_0.chatWinIsShow = false

		arg_31_0:playChatWinMove(arg_31_0.chatWinIsShow)

		return
	elseif arg_31_0.chatIsInit then
		arg_31_0.chatWinIsShow = true

		arg_31_0:playChatWinMove(arg_31_0.chatWinIsShow)

		return
	end

	local var_31_0 = arg_31_0:nodeByName("chat_container")

	var_31_0:setTouchSwallowEnabled(true)
	var_31_0:removeAllChildren()

	local var_31_1 = arg_31_0.occult:getChatWindow("occult_sub_map")

	var_31_1:addTo(var_31_0)
	var_31_1:setPosition(cc.p(0, 0))
	var_31_1:setName("chat_wnd")
	var_31_0:setVisible(false)

	arg_31_0.chatIsInit = true
	arg_31_0.chatWinIsShow = false

	var_31_1:updateList()
end

function var_0_0.updateRedMark(arg_32_0, arg_32_1)
	if arg_32_0.chatWinIsShow then
		arg_32_0:nodeByName("icon_8"):setVisible(false)
	else
		arg_32_0:nodeByName("icon_8"):setVisible(arg_32_1)
	end
end

function var_0_0.playChatWinMove(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0:nodeByName("chat_container")
	local var_33_1 = var_33_0:getContentSize()
	local var_33_2 = cc.p(arg_33_0:nodeByName("btn_chat"):getPosition())

	if arg_33_1 then
		var_33_0:setPosition(cc.p(-var_33_1.width, 0))
		var_33_0:setVisible(true)
		transition.moveTo(var_33_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
		transition.moveTo(arg_33_0:nodeByName("btn_chat"), {
			time = 0.3,
			x = var_33_2.x + var_33_1.width,
			y = var_33_2.y
		})
	else
		transition.moveTo(var_33_0, {
			time = 0.3,
			y = 0,
			x = -var_33_1.width
		})
		transition.moveTo(arg_33_0:nodeByName("btn_chat"), {
			time = 0.3,
			x = var_33_2.x - var_33_1.width,
			y = var_33_2.y
		})
	end
end

return var_0_0
