local var_0_0 = class("LvbuWorldCampusWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	battle = var_0_1:translation("BATTlE_TEXT"),
	change_group = var_0_1:translation("LVBU_CHANGE_GROUP"),
	rule = var_0_1:translation("ACTIVITY_DECODE_RULE_TITLE"),
	exploits = var_0_1:translation("PERSON_HISTORY_TIPS_1"),
	rank = var_0_1:translation("RANK"),
	rule_title = var_0_1:translation("LVBU_MATCH_RULER_TITLE"),
	rule_txt = var_0_1:translation("LVBU_MATCH_RULER")
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.lvbuFestival = xyd.ModelManager.get():loadModel(xyd.ModelType.LVBU_FESTIVAL)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.LVBU_DOOR_BRANCH_FESIBLE,
		params = {
			isShow = false
		}
	})
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	var_0_0.super:willClose(arg_4_1)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.LVBU_DOOR_BRANCH_FESIBLE
	})
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setButtonClick()
	arg_5_0:updateLvbuGroup()

	local var_5_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(xyd.tables.misc.lubuMatchTicket)

	arg_5_0:nodeByName("ticket_num_txt"):enableOutline(cc.c4b(113, 83, 152, 255), 2)
	arg_5_0:nodeByName("ticket_num_txt"):setString(var_5_0)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.LVBU_GROUP_CHANGE, function(arg_6_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			arg_5_0:updateLvbuGroup()
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.LVBU_MATCH_TICKET_CHANGE, function(arg_7_0)
		if arg_5_0 and not tolua.isnull(arg_5_0) then
			local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(xyd.tables.misc.lubuMatchTicket)

			arg_5_0:nodeByName("ticket_num_txt"):setString(var_7_0)
		end
	end)
end

function var_0_0.updateLvbuGroup(arg_8_0)
	arg_8_0:nodeByName("start_pos"):removeAllChildren(true)

	for iter_8_0 = 1, #arg_8_0.lvbuFestival.teamHeros do
		local var_8_0 = arg_8_0:initHeroCell(arg_8_0.lvbuFestival.teamHeros[iter_8_0], 170)

		var_8_0:setAnchorPoint(cc.p(0, 0))
		var_8_0:addTo(arg_8_0:nodeByName("start_pos"))
		var_8_0:setPositionX((iter_8_0 - 1) * 190)
	end
end

function var_0_0.setButtonClick(arg_9_0)
	arg_9_0:nodeByName("rule_text"):setString(var_0_2.rule)
	arg_9_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.began then
			arg_9_0:nodeByName("rule_btn"):setScale(0.9)
		elseif arg_10_1 == ccui.TouchEventType.ended then
			arg_9_0:nodeByName("rule_btn"):setScale(1)

			local var_10_0 = {
				hasOtherItem = true,
				title_name = "LVBU_MATCH_RULER_TITLE",
				crystalNotShow = true,
				rule = "LVBU_MATCH_RULER",
				otherItemType = xyd.TextRuleItemType.Award,
				award = xyd.tables.ActivityLvbuAwardTable
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_10_0)
		end
	end)
	arg_9_0:nodeByName("battle_text"):setString(var_0_2.battle)
	arg_9_0:nodeByName("battle_text"):enableOutline(cc.c4b(85, 49, 27, 255), 2)
	arg_9_0:nodeByName("compete_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.began then
			arg_9_0:nodeByName("compete_btn"):setScale(0.9)
		elseif arg_11_1 == ccui.TouchEventType.ended then
			arg_9_0:nodeByName("compete_btn"):setScale(1)

			if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(xyd.tables.misc.lubuMatchTicket) <= 0 then
				local var_11_0 = var_0_1:translation("LVBU_NO_TICKET")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			xyd.WindowManager.get():openWindow("lvbu_world_campus_result")
		end
	end)
	arg_9_0:nodeByName("change_group_text"):setString(var_0_2.change_group)
	arg_9_0:nodeByName("change_group_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.began then
			arg_9_0:nodeByName("change_group_btn"):setScale(0.9)
		elseif arg_12_1 == ccui.TouchEventType.ended then
			arg_9_0:nodeByName("change_group_btn"):setScale(1)
			arg_9_0.lvbuFestival:playChangeTeam()
		end
	end)
	arg_9_0:nodeByName("battle_result_text"):setString(var_0_2.exploits)
	arg_9_0:nodeByName("exploits_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.began then
			arg_9_0:nodeByName("exploits_btn"):setScale(0.9)
		elseif arg_13_1 == ccui.TouchEventType.ended then
			arg_9_0:nodeByName("exploits_btn"):setScale(1)
			arg_9_0.lvbuFestival:getRecordList({}, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("lvbu_world_campus_record")
				end
			end)
		end
	end)
	arg_9_0:nodeByName("rank_text"):setString(var_0_2.rank)
	arg_9_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.began then
			arg_9_0:nodeByName("rank_btn"):setScale(0.9)
		elseif arg_15_1 == ccui.TouchEventType.ended then
			arg_9_0:nodeByName("rank_btn"):setScale(1)
			arg_9_0.lvbuFestival:getRankInfo({}, function(arg_16_0, arg_16_1)
				if arg_16_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("lvbu_world_campus_rank")
				end
			end)
		end
	end)
end

function var_0_0.initHeroCell(arg_17_0, arg_17_1, arg_17_2)
	if not arg_17_1 or not next(arg_17_1) then
		return
	end

	local var_17_0 = import("app.windows.HeroListCell").new({
		hero = arg_17_1,
		type = xyd.HeroListDisplayType.ONLYSHOW
	})

	var_17_0:layout()

	if arg_17_2 and arg_17_2 > 0 then
		local var_17_1 = arg_17_2 / var_17_0:getWidth()

		var_17_0:setScale(var_17_1)
	end

	return var_17_0
end

return var_0_0
