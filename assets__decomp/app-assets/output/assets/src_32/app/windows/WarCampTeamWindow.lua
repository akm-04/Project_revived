local var_0_0 = class("WarCampTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = xyd.tables.translation
local var_0_5 = 10
local var_0_6 = 56
local var_0_7 = 70
local var_0_8 = 4
local var_0_9 = xyd.tables.warCamp
local var_0_10 = xyd.tables.warCampCampaign
local var_0_11 = xyd.tables.misc:getValue("camp_war_winning_streak_tip_times")
local var_0_12 = {
	NEW_TEAM = 3,
	TITLE = 1,
	TEAM = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teamWindowType_ = arg_1_2.window_type or xyd.WarCampTeamWindowType.NORMAL
	arg_1_0.cityID = arg_1_2.city_id or 0
	arg_1_0.clickCity = arg_1_2.click_city or 0
	arg_1_0.campType = arg_1_0.warCamp_:getCampType()
	arg_1_0.teams_ = {}
	arg_1_0.showItems_ = {}
	arg_1_0.maxCityNum = arg_1_0.warCamp_:getMaxCityNum()

	if arg_1_0.campType == xyd.WarCampSelectType.LEFT then
		arg_1_0.mainCityId = 1
	else
		arg_1_0.mainCityId = arg_1_0.maxCityNum
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initTeams()
	arg_2_0:getTeamsNum()
	arg_2_0:initListview()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0.list_:reload()

	if arg_3_0.scrollPosY_ then
		local var_3_0 = cc.p(arg_3_0.list_:getScrollNode():getPosition())

		arg_3_0.list_:scrollTo(var_3_0.x, var_3_0.y + arg_3_0.scrollPosY_)

		arg_3_0.scrollPosY_ = nil
	end
end

function var_0_0.willClose(arg_4_0, arg_4_1)
	if arg_4_0.teamWindowType_ == xyd.WarCampTeamWindowType.NORMAL then
		arg_4_0.warCamp_.isClick = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0.teams_ or {}) do
			if iter_4_1 and iter_4_1.is_click then
				arg_4_0.warCamp_.isClick[iter_4_0] = true
			end
		end
	end
end

function var_0_0.initListview(arg_5_0)
	local var_5_0 = arg_5_0:nodeByName("list")
	local var_5_1 = var_5_0:getContentSize().width
	local var_5_2 = var_5_0:getContentSize().height

	arg_5_0.list_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_5_1, var_5_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_5_0):onScroll(handler(arg_5_0, arg_5_0.scrollListener))
	arg_5_0.heroCells_ = {}
	arg_5_0.listWidth = var_5_1

	arg_5_0.list_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevY_ = arg_6_1.y
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.y - arg_6_0.prevY_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.recordScrollPos(arg_7_0, arg_7_1)
	local var_7_0 = cc.p(arg_7_0.list_:getScrollNode():getPosition())

	arg_7_0.scrollPos_ = cc.p(var_7_0.x, var_7_0.y + arg_7_1)
end

function var_0_0.refreshTeam(arg_8_0)
	arg_8_0:initTeams(true)
	arg_8_0:getTeamsNum()
	arg_8_0.list_:reload()

	if arg_8_0.scrollPos_ then
		arg_8_0.list_:scrollTo(arg_8_0.scrollPos_)
	end
end

function var_0_0.initTeams(arg_9_0, arg_9_1)
	if arg_9_0.teamWindowType_ ~= xyd.WarCampTeamWindowType.NORMAL then
		arg_9_0.teams_ = arg_9_0.warCamp_.teamInfos

		return
	end

	local var_9_0 = arg_9_0.warCamp_:getMaxCityNum()

	if arg_9_0.campType == xyd.WarCampSelectType.LEFT then
		for iter_9_0 = 1, var_9_0 - 1 do
			if arg_9_1 then
				arg_9_0.teams_[iter_9_0].sub_list = arg_9_0.warCamp_:getTeamsByMapId(iter_9_0)
			else
				local var_9_1 = {
					is_click = (arg_9_0.warCamp_.isClick or {})[iter_9_0] or false,
					sub_list = arg_9_0.warCamp_:getTeamsByMapId(iter_9_0),
					city_id = iter_9_0
				}

				if iter_9_0 == arg_9_0.clickCity then
					var_9_1.is_click = true

					if #arg_9_0.teams_ > 6 then
						arg_9_0.scrollPosY_ = (var_0_6 + var_0_5) * (#arg_9_0.teams_ - 6) + var_0_7
					end
				end

				table.insert(arg_9_0.teams_, var_9_1)
			end
		end
	else
		for iter_9_1 = var_9_0, 2, -1 do
			if arg_9_1 then
				arg_9_0.teams_[var_9_0 - iter_9_1 + 1].sub_list = arg_9_0.warCamp_:getTeamsByMapId(iter_9_1)
			else
				local var_9_2 = {
					is_click = false,
					sub_list = arg_9_0.warCamp_:getTeamsByMapId(iter_9_1),
					city_id = iter_9_1
				}

				if iter_9_1 == arg_9_0.clickCity then
					var_9_2.is_click = true

					if #arg_9_0.teams_ > 6 then
						arg_9_0.scrollPosY_ = (var_0_6 + var_0_5) * (#arg_9_0.teams_ - 6) + var_0_7
					end
				end

				table.insert(arg_9_0.teams_, var_9_2)
			end
		end
	end
end

function var_0_0.checkCanAddNewTeam(arg_10_0, arg_10_1)
	if not arg_10_0.warCamp_:isMyCampCity(arg_10_1) then
		return false
	end

	return true
end

function var_0_0.getTeamsNum(arg_11_0)
	arg_11_0.showItems_ = {}

	if arg_11_0.teamWindowType_ ~= xyd.WarCampTeamWindowType.NORMAL then
		for iter_11_0, iter_11_1 in ipairs(arg_11_0.teams_) do
			table.insert(arg_11_0.showItems_, {
				item_type = var_0_12.TEAM,
				city_id = iter_11_1.city_id,
				team_info = iter_11_1,
				sub_index = i
			})
		end

		table.insert(arg_11_0.showItems_, {
			item_type = var_0_12.NEW_TEAM,
			city_id = arg_11_0.mainCityId
		})

		return
	end

	for iter_11_2 = 1, #arg_11_0.teams_ do
		local var_11_0 = arg_11_0.teams_[iter_11_2]

		if arg_11_0:checkCanAddNewTeam(var_11_0.city_id) then
			table.insert(arg_11_0.showItems_, {
				item_type = var_0_12.TITLE,
				city_id = var_11_0.city_id,
				team_index = iter_11_2,
				sub_num = #var_11_0.sub_list
			})

			if var_11_0.is_click then
				for iter_11_3 = 1, #var_11_0.sub_list do
					table.insert(arg_11_0.showItems_, {
						item_type = var_0_12.TEAM,
						city_id = var_11_0.city_id,
						team_info = var_11_0.sub_list[iter_11_3],
						sub_index = iter_11_3
					})
				end

				if arg_11_0:checkCanAddNewTeam(var_11_0.city_id) then
					table.insert(arg_11_0.showItems_, {
						item_type = var_0_12.NEW_TEAM,
						city_id = var_11_0.city_id
					})
				end
			end
		end
	end
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.showItems_
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		local var_12_0
		local var_12_1
		local var_12_2
		local var_12_3 = arg_12_0.list_:dequeueItem()

		if not var_12_3 then
			var_12_3 = arg_12_0.list_:newItem()
		else
			var_12_3:removeAllChildren()
		end

		local var_12_4 = display.newNode()

		var_12_4:setTouchSwallowEnabled(false)

		local var_12_5 = display.newNode()

		if not arg_12_0:initCell(var_12_5, arg_12_3) then
			return nil
		end

		var_12_4:addChild(var_12_5)
		var_12_4:setContentSize(cc.size(arg_12_0.list_.viewRect_.width, var_12_5:getContentSize().height + var_0_5))
		var_12_3:setItemSize(arg_12_0.list_.viewRect_.width, var_12_5:getContentSize().height + var_0_5)
		var_12_3:addContent(var_12_4)

		return var_12_3
	end
end

function var_0_0.initCell(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_0.showItems_[arg_13_2]

	if not var_13_0 then
		return false
	end

	if var_13_0.item_type == var_0_12.TITLE then
		arg_13_0:initTitleCell(arg_13_1, var_13_0)
	elseif var_13_0.item_type == var_0_12.TEAM then
		arg_13_0:initTeamCell(arg_13_1, var_13_0)
	elseif var_13_0.item_type == var_0_12.NEW_TEAM then
		arg_13_0:initNewTeamCell(arg_13_1, var_13_0)
	end

	return true
end

function var_0_0.initTitleCell(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_team/team_title.csb")

	var_14_0:addTo(arg_14_1)

	local var_14_1 = var_14_0:getChildByName("btn_title")
	local var_14_2 = var_14_1:getContentSize()

	arg_14_1:setContentSize(arg_14_0.listWidth, var_14_2.height)

	local var_14_3 = var_0_9:name(arg_14_2.city_id) .. string.format(var_0_4:translation("WAR_CAMP_TEAMS_TIPS_3"), arg_14_2.sub_num)

	var_14_1:getChildByName("text_title"):setString(var_14_3)
	var_14_1:addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended and not arg_14_0.scrollViewMoved_ then
			arg_14_0.teams_[arg_14_2.team_index].is_click = not arg_14_0.teams_[arg_14_2.team_index].is_click

			local var_15_0 = 0

			if arg_14_0.list_:getItemPos(arg_14_1:getParent():getParent()) > var_0_8 and arg_14_0:checkCanAddNewTeam(arg_14_2.city_id) then
				var_15_0 = (arg_14_0.teams_[arg_14_2.team_index].is_click and 1 or -1) * var_0_7
			end

			local var_15_1 = cc.p(arg_14_0.list_:getScrollNode():getPosition())

			arg_14_0:getTeamsNum()
			arg_14_0.list_:reload()
			arg_14_0.list_:scrollTo(var_15_1.x, var_15_1.y + var_15_0)
		end
	end)

	if arg_14_0.teams_[arg_14_2.team_index].is_click then
		var_14_1:setBrightStyle(ccui.BrightStyle.highlight)
		var_14_1:getChildByName("arrow"):setScaleY(-1)
	end

	local var_14_4 = var_14_1:getChildByName("text_title"):getContentSize()
	local var_14_5 = var_14_1:getChildByName("text_title"):getPositionX()

	var_14_1:getChildByName("arrow"):setPositionX(var_14_5 + var_14_4.width / 2 + 34)
end

function var_0_0.initTeamCell(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_team/team_item.csb")

	var_16_0:addTo(arg_16_1)

	local var_16_1 = var_16_0:getChildByName("container")
	local var_16_2 = var_16_1:getContentSize()

	arg_16_1:setContentSize(arg_16_0.listWidth, var_16_2.height)
	arg_16_0:initHeroList(var_16_1, arg_16_2)

	local var_16_3 = var_16_1:getChildByName("layout1")
	local var_16_4 = var_16_1:getChildByName("layout2")

	if arg_16_0.teamWindowType_ == xyd.WarCampTeamWindowType.NORMAL then
		var_16_4:setVisible(false)
		var_16_3:getChildByName("btn_change_team"):addTouchEventListener(function(arg_17_0, arg_17_1)
			if arg_17_1 == ccui.TouchEventType.ended then
				arg_16_0:recordScrollPos(0)
				arg_16_0:judgechangeTeam(arg_17_0, arg_16_1, arg_16_2)
			end
		end)
		var_16_3:getChildByName("btn_del"):addTouchEventListener(function(arg_18_0, arg_18_1)
			if arg_18_1 == ccui.TouchEventType.ended then
				arg_16_0:recordScrollPos(0)
				arg_16_0:judgeDelTeam(arg_18_0, arg_16_1, arg_16_2)
			end
		end)
		var_16_3:getChildByName("btn_change_city"):addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				arg_16_0:judgechangeCity(arg_19_0, arg_16_1, arg_16_2)
			end
		end)
		var_16_3:getChildByName("btn_reborn"):addTouchEventListener(function(arg_20_0, arg_20_1)
			if arg_20_1 == ccui.TouchEventType.ended then
				arg_16_0:rebornTeam(arg_20_0, arg_16_2, var_16_1)
			end
		end)
	else
		var_16_3:setVisible(false)
		var_16_4:getChildByName("btn_fight"):addTouchEventListener(function(arg_21_0, arg_21_1)
			if arg_21_1 == ccui.TouchEventType.ended and arg_16_0:checkTeamCanFight(arg_16_2.team_info) then
				local var_21_0 = {
					map_id = arg_16_0.cityID,
					team_id = arg_16_2.team_info.team_id
				}

				if arg_16_0.warCamp_.baseInfo.challenge_times <= 0 and arg_16_0.teamWindowType_ == xyd.WarCampTeamWindowType.FIGHT_BOSS then
					local var_21_1 = var_0_4:translation("TRIAL_TIMES_ERROR")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_21_1
					})

					return
				end

				if arg_16_0.teamWindowType_ == xyd.WarCampTeamWindowType.FIGHT_BOSS then
					arg_16_0.warCamp_:fightBoss(var_21_0, function(arg_22_0, arg_22_1)
						if arg_22_0 == xyd.error.OK then
							if arg_22_1 and arg_22_1.no_enemy and arg_22_1.no_enemy == 1 then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_4:translation("CAMP_WAR_NO_ENEMY")
								})
								arg_16_0:updateFightResult(arg_16_0.cityID, true)

								return
							end

							if not arg_22_1 or not arg_22_1.battle_report then
								arg_16_0:updateFightResult(arg_16_0.cityID)
							else
								arg_16_0:playReport(arg_22_1)
							end
						else
							arg_16_0:updateMapInfo(arg_16_0.cityID)
						end
					end)
				else
					arg_16_0.warCamp_:fightEnemy(var_21_0, function(arg_23_0, arg_23_1)
						if arg_23_0 == xyd.error.OK then
							if arg_23_1 and arg_23_1.no_enemy and arg_23_1.no_enemy == 1 then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_4:translation("CAMP_WAR_NO_ENEMY")
								})
								arg_16_0:updateFightResult(arg_16_0.cityID, true)

								return
							end

							if not arg_23_1 or not arg_23_1.battle_report then
								arg_16_0:updateFightResult(arg_16_0.cityID)
							else
								arg_16_0:playReport(arg_23_1, true)
							end
						else
							arg_16_0:updateMapInfo(arg_16_0.cityID)
						end
					end)
				end
			end
		end)
		var_16_4:getChildByName("btn_reborn_2"):addTouchEventListener(function(arg_24_0, arg_24_1)
			if arg_24_1 == ccui.TouchEventType.ended then
				arg_16_0:rebornTeam(arg_24_0, arg_16_2, var_16_1)
			end
		end)
	end
end

function var_0_0.judgeDelTeam(arg_25_0, arg_25_1, arg_25_2, arg_25_3)
	if arg_25_0.warCamp_.baseInfo.defense_wins[arg_25_3.city_id] >= var_0_11 then
		local var_25_0 = var_0_4:translation("WAR_CAMP_BOSS_TIME_TIPS_5")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_25_0, function()
			local var_26_0 = {
				team_id = arg_25_3.team_info.team_id
			}

			arg_25_0.warCamp_:delTeam(var_26_0, function(arg_27_0, arg_27_1)
				if arg_27_0 == xyd.error.OK then
					arg_25_0:refreshTeam()

					arg_25_0.warCamp_.baseInfo.defense_wins[arg_25_3.city_id] = 0
				end
			end)
		end, nil, nil, arg_25_0.colorMode)
	else
		local var_25_1 = var_0_4:translation("WAR_CAMP_DEL_TEAM")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_25_1, function()
			local var_28_0 = {
				team_id = arg_25_3.team_info.team_id
			}

			arg_25_0.warCamp_:delTeam(var_28_0, function(arg_29_0, arg_29_1)
				if arg_29_0 == xyd.error.OK then
					arg_25_0:refreshTeam()

					arg_25_0.warCamp_.baseInfo.defense_wins[arg_25_3.city_id] = 0
				end
			end)
		end, nil, nil, arg_25_0.colorMode)
	end
end

function var_0_0.judgechangeCity(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
	if arg_30_0.warCamp_.baseInfo.defense_wins[arg_30_3.city_id] >= var_0_11 then
		local var_30_0 = {
			txt = var_0_4:translation("WAR_CAMP_BOSS_TIME_TIPS_5"),
			rcallback = function()
				arg_30_0:showCitys(arg_30_1, arg_30_3)
			end,
			lcallback = function()
				xyd.WindowManager.get():closeWindow(arg_30_0)
			end
		}

		xyd.WindowManager.get():openWindow("common_alert", var_30_0)
	else
		arg_30_0:showCitys(arg_30_1, arg_30_3)
	end
end

function var_0_0.judgechangeTeam(arg_33_0, arg_33_1, arg_33_2, arg_33_3)
	if arg_33_0.warCamp_.baseInfo.defense_wins[arg_33_3.city_id] >= var_0_11 then
		local var_33_0 = {
			txt = var_0_4:translation("WAR_CAMP_BOSS_TIME_TIPS_5"),
			rcallback = function()
				local var_34_0 = {
					select_type = xyd.WarCampSelectTeamType.CHANGE,
					city_id = arg_33_3.city_id,
					team_id = arg_33_3.team_info.team_id,
					pre_heros = arg_33_3.team_info.partner_ids,
					pre_pet_id = arg_33_3.team_info.pet_id
				}

				xyd.WindowManager.get():closeWindow(arg_33_0)
				xyd.WindowManager.get():openWindow("war_camp_select_team", var_34_0)
			end,
			lcallback = function()
				xyd.WindowManager.get():closeWindow(arg_33_0)
			end
		}

		xyd.WindowManager.get():openWindow("common_alert", var_33_0)
	else
		local var_33_1 = {
			select_type = xyd.WarCampSelectTeamType.CHANGE,
			city_id = arg_33_3.city_id,
			team_id = arg_33_3.team_info.team_id,
			pre_heros = arg_33_3.team_info.partner_ids,
			pre_pet_id = arg_33_3.team_info.pet_id
		}

		xyd.WindowManager.get():closeWindow(arg_33_0)
		xyd.WindowManager.get():openWindow("war_camp_select_team", var_33_1)
	end
end

function var_0_0.rebornTeam(arg_36_0, arg_36_1, arg_36_2, arg_36_3)
	local var_36_0 = {
		team_id = arg_36_2.team_info.team_id
	}
	local var_36_1 = arg_36_0:checkTeamDieHeros(arg_36_2.team_info)

	if not arg_36_0:checkTicket(var_36_1) then
		local var_36_2 = var_0_4:translation("WAR_CAMP_REBORN_TEXT3")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_36_2
		})

		return
	end

	if var_36_1 > 0 then
		local var_36_3 = string.format(var_0_4:translation("WAR_CAMP_REBORN_TEXT1"), var_36_1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_36_3, function()
			arg_36_0.warCamp_:rebornTeam(var_36_0, function(arg_38_0, arg_38_1)
				if arg_38_0 == xyd.error.OK then
					arg_36_0:refreshTeam()

					local var_38_0 = arg_36_0.selfPlayer:getBackpack()
					local var_38_1 = {
						itemID = xyd.tables.misc.campWarReviveItem,
						itemNum = arg_38_1.reborn_num or 0
					}

					var_38_0:removeItem(var_38_1)

					local var_38_2 = xyd.WindowManager.get():getWindow("war_camp_map")

					if var_38_2 then
						var_38_2:updateTop()
					end
				end
			end)
		end, nil, nil, arg_36_0.colorMode)
	else
		local var_36_4 = var_0_4:translation("WAR_CAMP_REBORN_TEXT2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_36_4
		})
	end
end

function var_0_0.checkTicket(arg_39_0, arg_39_1)
	arg_39_1 = arg_39_1 or 1

	local var_39_0 = arg_39_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.campWarReviveItem)

	if var_39_0 and arg_39_1 <= var_39_0 then
		return true
	end

	return false
end

function var_0_0.updateFightResult(arg_40_0, arg_40_1, arg_40_2)
	if xyd.WindowManager.get():getWindow("war_camp_city") then
		xyd.WindowManager.get():closeWindow("war_camp_city")
	end

	if xyd.WindowManager.get():getWindow("war_camp_map") then
		xyd.WindowManager.get():closeWindow("war_camp_map")
	end

	local var_40_0 = {
		cityID = arg_40_1
	}

	xyd.WindowManager.get():openWindow("war_camp_map", var_40_0)

	if arg_40_2 then
		xyd.WindowManager.get():closeWindow(arg_40_0)

		return
	end

	xyd.WindowManager.get():openWindow("toast", {
		message = var_0_4:translation("WAR_CAMP_MAP_TIPS_7")
	})
	xyd.WindowManager.get():closeWindow(arg_40_0)
end

function var_0_0.updateMapInfo(arg_41_0, arg_41_1)
	arg_41_0.warCamp_:getInfos(function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			if xyd.WindowManager.get():getWindow("war_camp_city") then
				xyd.WindowManager.get():closeWindow("war_camp_city")
			end

			if xyd.WindowManager.get():getWindow("war_camp_map") then
				xyd.WindowManager.get():closeWindow("war_camp_map")
			end

			local var_42_0 = {
				cityID = arg_41_1
			}

			xyd.WindowManager.get():openWindow("war_camp_map", var_42_0)
			xyd.WindowManager.get():closeWindow(arg_41_0)
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_4:translation("WAR_CAMP_MAP_TIPS_6")
			})
		end
	end)
end

function var_0_0.checkTeamCanFight(arg_43_0, arg_43_1)
	local var_43_0 = arg_43_1.partner_ids
	local var_43_1 = false

	for iter_43_0 = 1, #var_43_0 do
		local var_43_2 = arg_43_0.warCamp_:getHeroStatusByID(var_43_0[iter_43_0])

		if not var_43_2 or var_43_2.health and var_43_2.health <= 1 then
			var_43_1 = true

			break
		end
	end

	if not var_43_1 then
		local var_43_3 = var_0_4:translation("WAR_CAMP_SELECT_TIPS2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_43_3
		})
	end

	return var_43_1
end

function var_0_0.initHeroList(arg_44_0, arg_44_1, arg_44_2)
	local var_44_0 = arg_44_2.team_info.partner_ids
	local var_44_1 = arg_44_1:getChildByName("hero_list"):getContentSize()
	local var_44_2 = 0

	for iter_44_0 = 1, #var_44_0 do
		local var_44_3 = var_44_0[iter_44_0]
		local var_44_4 = arg_44_0.selfPlayer:getHeroByID(var_44_3)
		local var_44_5 = var_0_2.new()

		var_44_5:populate(var_44_4:toParams())
		arg_44_0.warCamp_:updateHeros({
			var_44_5
		})

		local var_44_6 = display.newNode()

		arg_44_0:initHeroAvatar(var_44_6, var_44_5)

		local var_44_7 = var_44_6:getContentSize()

		var_44_6:addTo(arg_44_1:getChildByName("hero_list"))
		var_44_6:setPosition(cc.p(var_44_2, 0))

		var_44_2 = var_44_2 + var_44_7.width + 5
	end

	if arg_44_2.team_info.pet_id and arg_44_2.team_info.pet_id > 0 then
		local var_44_8 = arg_44_2.team_info.pet_id
		local var_44_9 = arg_44_0.selfPlayer:getPetByID(var_44_8)
		local var_44_10 = var_0_3.new()

		var_44_10:populate(var_44_9:toParams())
		arg_44_0.warCamp_:updatePets({
			var_44_10
		})

		local var_44_11 = display.newNode()

		arg_44_0:initPetCell(var_44_11, var_44_10)

		local var_44_12 = var_44_11:getContentSize()

		var_44_11:addTo(arg_44_1:getChildByName("hero_list"))
		var_44_11:setPosition(cc.p(var_44_2, 0))

		local var_44_13 = var_44_2 + var_44_12.height + 5
	end
end

function var_0_0.initHeroAvatar(arg_45_0, arg_45_1, arg_45_2)
	local var_45_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar.csb")

	var_45_0:setScale(0.75)
	var_45_0:getChildByName("yongbing_tubiao"):setVisible(false)

	local var_45_1 = var_45_0:getChildByName("background"):getContentSize()

	arg_45_1:setContentSize(var_45_1.width * 0.75, var_45_1.width * 0.75)
	var_45_0:setContentSize(var_45_1)
	xyd.setAvatarBorder(arg_45_2, var_45_0:getChildByName("avatar"))

	local var_45_2 = var_45_0:getChildByName("chosen")

	var_45_2:setLocalZOrder(100)
	var_45_2:setVisible(false)

	local var_45_3 = var_45_0:getChildByName("avatar_mask")

	var_45_3:setLocalZOrder(2)
	var_45_3:setVisible(false)
	var_45_0:getChildByName("is_can_rent"):setVisible(false)

	if arg_45_2.partner_type == 1 or arg_45_2.partner_type == 5 then
		var_45_0:getChildByName("yongbing_tubiao"):setVisible(true)
	else
		var_45_0:getChildByName("yongbing_tubiao"):setVisible(false)
	end

	for iter_45_0 = 1, 3 do
		var_45_0:getChildByName("team" .. iter_45_0):setVisible(false)
	end

	var_45_0:getChildByName("lv_txt"):setString(arg_45_2:getLevel())
	var_45_0:getChildByName("name_text"):setVisible(false)
	var_45_0:getChildByName("name_label_bg"):setVisible(false)

	local var_45_4 = var_45_0:getChildByName("hp_bar")
	local var_45_5 = var_45_0:getChildByName("mp_bar")
	local var_45_6 = var_45_0:getChildByName("dead_text")

	var_45_6:setString(var_0_4:translation("ALREADY_DEAD"))

	if var_45_6 then
		var_45_6:setVisible(false)
	end

	local var_45_7 = arg_45_0.warCamp_:getHeroStatusByID(arg_45_2:getHeroID())

	if var_45_7 and next(var_45_7) then
		arg_45_0:updateHeroAvatar(var_45_0, arg_45_1, arg_45_2, var_45_7)
	else
		arg_45_2.healthStatus = {}
		arg_45_2.healthStatus.health = 0
		arg_45_2.healthStatus.hp = 0
		arg_45_2.healthStatus.mp = 0

		local var_45_8 = 100
		local var_45_9 = 0

		var_45_4:setPercent(var_45_8)
		var_45_4:setVisible(true)
		var_45_5:setPercent(var_45_9)
		var_45_5:setVisible(true)

		arg_45_2.isDead = false
	end

	var_45_0:setName("layout")
	var_45_0:setPosition(cc.p(0, -18.75))
	arg_45_1:addChild(var_45_0)
end

function var_0_0.checkTeamDieHeros(arg_46_0, arg_46_1)
	local var_46_0 = 0

	for iter_46_0 = 1, #arg_46_1.partner_ids do
		local var_46_1 = arg_46_0.warCamp_:getHeroStatusByID(arg_46_1.partner_ids[iter_46_0])

		if var_46_1 and var_46_1.health and var_46_1.health ~= 0 and var_46_1.hp < 1 then
			var_46_0 = var_46_0 + 1
		end
	end

	return var_46_0
end

function var_0_0.updateHeroAvatar(arg_47_0, arg_47_1, arg_47_2, arg_47_3, arg_47_4)
	if not arg_47_4 then
		return
	end

	local var_47_0 = arg_47_1:getChildByName("hp_bar")
	local var_47_1 = arg_47_1:getChildByName("mp_bar")
	local var_47_2 = arg_47_1:getChildByName("dead_text")

	var_47_2:setVisible(false)

	local var_47_3 = arg_47_1:getChildByName("avatar_mask")

	var_47_3:setVisible(false)

	local var_47_4 = false

	arg_47_3.healthStatus = arg_47_4

	if arg_47_4 and arg_47_4.health then
		local var_47_5 = 0
		local var_47_6 = 0

		if arg_47_4.health == 0 then
			var_47_5 = 100
			var_47_6 = arg_47_4.mp / 10
		elseif arg_47_4.health == 1 and arg_47_4.hp >= 1 then
			var_47_5 = arg_47_4.hp / arg_47_4.max_hp * 100
			var_47_6 = arg_47_4.mp / 10
		else
			var_47_5 = 0
			var_47_6 = 0

			var_47_3:setVisible(true)
			var_47_2:setLocalZOrder(3)
			var_47_2:setVisible(true)
			var_47_2:enableOutline(cc.c4b(0, 0, 0), 2)
			var_47_2:getVirtualRenderer():setAdditionalKerning(2)

			var_47_4 = true
		end

		var_47_0:setPercent(var_47_5)
		var_47_0:setVisible(true)
		var_47_1:setPercent(var_47_6)
		var_47_1:setVisible(true)
	end

	arg_47_3.isDead = var_47_4
end

function var_0_0.initPetCell(arg_48_0, arg_48_1, arg_48_2)
	if not arg_48_2 or not next(arg_48_2) then
		return
	end

	arg_48_1:removeAllChildren()

	local var_48_0 = display.newNode()

	var_48_0:size(90, 90)
	var_48_0:align(display.CENTER)

	var_48_0.data = arg_48_2

	xyd.setPetAvatar(var_48_0, arg_48_2, 100, true, false, true)
	arg_48_1:addChild(var_48_0)
	arg_48_1:setContentSize(var_48_0:getContentSize())

	local var_48_1 = arg_48_1:getContentSize()

	var_48_0:pos(var_48_1.width / 2, var_48_1.height / 2)
end

function var_0_0.initNewTeamCell(arg_49_0, arg_49_1, arg_49_2)
	local var_49_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_team/team_add.csb")

	var_49_0:addTo(arg_49_1)

	local var_49_1 = var_49_0:getChildByName("img_new_team")
	local var_49_2 = var_49_1:getContentSize()

	var_49_0:setPosition(arg_49_0.listWidth / 2 - 111, 0)
	arg_49_1:setContentSize(arg_49_0.listWidth, var_0_7)
	var_49_1:setTouchEnabled(true)
	var_49_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_50_0)
		if arg_50_0.name == "began" then
			var_49_1:setScale(0.9)

			return true
		elseif arg_50_0.name == "ended" then
			var_49_1:setScale(1)
			arg_49_0:judgeNewTeam(arg_49_1, arg_49_2)
		end
	end)
end

function var_0_0.judgeNewTeam(arg_51_0, arg_51_1, arg_51_2)
	if arg_51_0.warCamp_.baseInfo.defense_wins[arg_51_2.city_id] >= var_0_11 then
		local var_51_0 = var_0_4:translation("WAR_CAMP_BOSS_TIME_TIPS_5")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_51_0, function()
			arg_51_0:recordScrollPos(var_0_7)

			local var_52_0 = {
				select_type = xyd.WarCampSelectTeamType.NEW_TEAM,
				city_id = arg_51_2.city_id
			}

			xyd.WindowManager.get():openWindow("war_camp_select_team", var_52_0)
		end, nil, nil, arg_51_0.colorMode)
	else
		arg_51_0:recordScrollPos(var_0_7)

		local var_51_1 = {
			select_type = xyd.WarCampSelectTeamType.NEW_TEAM,
			city_id = arg_51_2.city_id
		}

		xyd.WindowManager.get():openWindow("war_camp_select_team", var_51_1)
	end
end

function var_0_0.initChangeCity(arg_53_0)
	local var_53_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_team/change_city.csb")

	var_53_0:addTo(arg_53_0, 11)
	var_53_0:setName("change_city")

	arg_53_0.changeCity = var_53_0

	local var_53_1 = var_53_0:getChildByName("container"):getChildByName("list")
	local var_53_2 = var_53_1:getContentSize()

	arg_53_0.changeCityList_ = cc.ui.UIListView.new({
		async = false,
		viewRect = cc.rect(0, 0, var_53_2.width, var_53_2.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_53_1):onScroll(handler(arg_53_0, arg_53_0.scrollListener))
	clickNode = display.newNode()

	clickNode:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	clickNode:setAnchorPoint(cc.p(0, 0))

	local var_53_3 = arg_53_0:convertToWorldSpace(cc.p(0, 0))

	clickNode:setTouchSwallowEnabled(true)
	clickNode:pos(-var_53_3.x, -var_53_3.y):addTo(arg_53_0, 10)
	clickNode:setTouchEnabled(true)
	clickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
		if arg_54_0.name == "began" then
			-- block empty
		elseif arg_54_0.name == "ended" then
			arg_53_0.changeCity:hide()
			clickNode:setVisible(false)
		end

		return true
	end)

	arg_53_0.changeCityClickNode = clickNode
end

function var_0_0.showCitys(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = arg_55_0.warCamp_:getSelfCitys()

	if not arg_55_0.changeCity or tolua.isnull(arg_55_0.changeCity) then
		arg_55_0:initChangeCity()
	end

	arg_55_0.changeCityList_:removeAllItems()

	local var_55_1 = var_0_7

	for iter_55_0 = #var_55_0, 1, -1 do
		local var_55_2 = var_55_0[iter_55_0]

		if var_55_2.map_id ~= arg_55_2.city_id then
			local var_55_3 = arg_55_0.changeCityList_:newItem()
			local var_55_4 = display.newNode()
			local var_55_5 = var_0_9:name(var_55_2.map_id)
			local var_55_6 = xyd.AssetLoader.get():loadNodeFromJson("windows/war_camp/war_team/city_btn.csb")

			var_55_6:addTo(var_55_4)

			local var_55_7 = var_55_6:getChildByName("btn_city")
			local var_55_8 = var_55_7:getContentSize()

			var_55_7:getChildByName("text_name"):setString(var_55_5)
			var_55_7:addTouchEventListener(function(arg_56_0, arg_56_1)
				if arg_56_1 == ccui.TouchEventType.ended and not arg_55_0.scrollViewMoved_ then
					local var_56_0 = {
						map_id = var_55_2.map_id,
						team_id = arg_55_2.team_info.team_id
					}

					arg_55_0.warCamp_:moveTeam(var_56_0, function(arg_57_0, arg_57_1)
						if arg_57_0 == xyd.error.OK then
							arg_55_0.changeCity:hide()
							arg_55_0.changeCityClickNode:setVisible(false)
							arg_55_0:refreshTeam()

							arg_55_0.warCamp_.baseInfo.defense_wins[arg_55_2.city_id] = 0
							arg_55_0.warCamp_.baseInfo.defense_wins[var_55_2.map_id] = 0
						end
					end)
				end
			end)
			var_55_4:setContentSize(arg_55_0.changeCityList_.viewRect_.width, var_55_8.height + 5)
			var_55_3:setItemSize(arg_55_0.changeCityList_.viewRect_.width, var_55_8.height + 5)
			var_55_3:addContent(var_55_4)
			arg_55_0.changeCityList_:addItem(var_55_3)
		end
	end

	local var_55_9 = arg_55_0.changeCity:getChildByName("container"):getChildByName("text_tips")

	if #var_55_0 == 1 then
		var_55_9:setString(var_0_4:translation("WAR_CAMP_CHANGE_CITY"))
		var_55_9:setVisible(true)
	else
		var_55_9:setVisible(false)
	end

	arg_55_0.changeCityList_:reload()

	local var_55_10 = arg_55_0:convertToNodeSpace(arg_55_1:getParent():convertToWorldSpace(cc.p(arg_55_1:getPosition())))
	local var_55_11 = arg_55_0.changeCity:getChildByName("container"):getContentSize()

	if var_55_10.y > xyd.STAGE_HEIGHT / 2 then
		arg_55_0.changeCity:setPosition(var_55_10.x + 110, var_55_10.y - var_55_11.height)
	else
		arg_55_0.changeCity:setPosition(var_55_10.x + 110, var_55_10.y)
	end

	arg_55_0.changeCity:show()
	arg_55_0.changeCityClickNode:setVisible(true)
end

function var_0_0.playReport(arg_58_0, arg_58_1, arg_58_2)
	if arg_58_1 == nil or arg_58_1.battle_report == nil then
		return
	end

	if not arg_58_0 or tolua.isnull(arg_58_0) then
		return
	end

	local var_58_0 = {}
	local var_58_1 = json.decode(arg_58_1.battle_report)

	var_58_0.herosA = {}
	var_58_0.herosB = {}
	var_58_0.summonMonsters = {}

	local var_58_2 = var_0_9:bossId(arg_58_0.cityID)

	var_58_0.battleID = var_0_10:fightId(var_58_2) or xyd.MapBattleID.ARENA

	if arg_58_2 then
		var_58_0.campaignType = xyd.CampaignType.WAR_CAMP_ENEMY
	else
		var_58_0.campaignType = xyd.CampaignType.WAR_CAMP
	end

	var_58_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_58_1

	local var_58_3 = {}
	local var_58_4 = {}

	for iter_58_0, iter_58_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_58_5 = string.sub(iter_58_0, 1, 1)
		local var_58_6 = tonumber(string.sub(iter_58_0, 3, 3))

		if var_58_5 == "A" and tonumber(iter_58_1.summon_type) == xyd.summonMonsterType.None then
			local var_58_7 = var_0_2.new()

			var_58_7:populate(iter_58_1.hero)
			var_58_7:setReportData(iter_58_1)

			var_58_7.healthStatus = arg_58_0.warCamp_:getOldHeroStatus(var_58_7:getHeroID())

			if isOnlyData then
				var_58_7.harms = iter_58_1.harms
				var_58_7.willDie = (iter_58_1.die_count or 0) ~= -1
			end

			var_58_0.herosA[var_58_6] = var_58_7
		elseif var_58_5 == "A" and tonumber(iter_58_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_58_8 = var_0_3.new()

			var_58_8:populate(iter_58_1.hero)
			var_58_8:setReportData(iter_58_1)

			if isOnlyData then
				var_58_8.harms = iter_58_1.harms
				var_58_8.willDie = (iter_58_1.die_count or 0) ~= -1
				var_58_0.petA = {
					var_58_8
				}
			else
				var_58_0.petsA = {
					var_58_8
				}
			end
		elseif var_58_5 == "B" and tonumber(iter_58_1.summon_type) == xyd.summonMonsterType.None then
			local var_58_9 = var_0_2.new()

			var_58_9:populate(iter_58_1.hero)
			var_58_9:setReportData(iter_58_1)

			if isOnlyData then
				var_58_9.harms = iter_58_1.harms
				var_58_9.willDie = (iter_58_1.die_count or 0) ~= -1
				var_58_0.herosB[var_58_6] = var_58_9
			else
				var_58_3[var_58_6] = var_58_9
			end
		elseif var_58_5 == "B" and tonumber(iter_58_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_58_10 = var_0_3.new()

			var_58_10:populate(iter_58_1.hero)
			var_58_10:setReportData(iter_58_1)

			if isOnlyData then
				var_58_10.harms = iter_58_1.harms
				var_58_10.willDie = (iter_58_1.die_count or 0) ~= -1
				var_58_0.petB = {
					var_58_10
				}
			else
				var_58_0.petsB = {
					var_58_10
				}
			end
		elseif var_58_5 == "C" then
			local var_58_11 = var_0_2.new()

			var_58_11:populate(iter_58_1.hero)
			var_58_11:setReportData(iter_58_1)

			if not isOnlyData then
				sceneFighter = var_58_11
			end
		elseif tonumber(iter_58_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_58_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_58_12 = var_0_2.new()

			var_58_12:populate(iter_58_1.hero)
			var_58_12:setReportData(iter_58_1)

			var_58_4[iter_58_0] = var_58_12
		end
	end

	var_58_0.herosB = {
		var_58_3
	}
	var_58_0.sceneFighter = sceneFighter
	var_58_0.summonMonsters = var_58_4
	var_58_0.reportStar = tonumber(var_58_1.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "war_camp_map",
			status = {
				cityID = arg_58_0.cityID
			}
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_58_0)
end

return var_0_0
