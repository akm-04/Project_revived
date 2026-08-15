local var_0_0 = class("PeakArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 3
local var_0_2 = 5
local var_0_3 = 66
local var_0_4 = -66
local var_0_5 = import("framework.scheduler")
local var_0_6 = xyd.tables.translation
local var_0_7 = import("app.common.ui.SpineEffect")
local var_0_8 = {
	IN_INVALID_TIME = 2,
	VALID_TIME = 0,
	IN_SUNDAY = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)
	arg_1_0.teams = arg_1_0.peakArena:getTeams()
	arg_1_0.pets = arg_1_0.peakArena:getPets()
	arg_1_0.teamItems = {}
	arg_1_0.switch = false
end

function var_0_0.scrollListener(arg_2_0, arg_2_1)
	if arg_2_1.name == "began" then
		arg_2_0.scrollViewMoved_ = false
		arg_2_0.prevY_ = arg_2_1.y
	elseif arg_2_1.name == "moved" and 10 <= math.abs(arg_2_1.y - arg_2_0.prevY_) then
		arg_2_0.scrollViewMoved_ = true
	end
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super.willOpen(arg_3_0, arg_3_1)

	arg_3_0.revengeList = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 275, 370),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("revenge_container")):onScroll(handler(arg_3_0, arg_3_0.scrollListener))
	arg_3_0.redMarkReport = arg_3_0:nodeByName("red_point")

	if arg_3_0.player.peakArenaRedMarkEnable then
		arg_3_0.redMarkReport:setVisible(true)
	else
		arg_3_0.redMarkReport:setVisible(false)
	end
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super.didOpen(arg_4_0, arg_4_1)
	arg_4_0:layout()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_5_0)
		if arg_5_0.params == xyd.CheckMiddleRed.PEAK then
			arg_4_0:checkRedMark(1)
		elseif arg_5_0.params == xyd.CheckMiddleRed.PEAK_CANCEL then
			arg_4_0:checkRedMark(0)
		end
	end)
end

function var_0_0.didClose(arg_6_0, arg_6_1)
	var_0_0.super.didClose(arg_6_0, arg_6_1)

	if arg_6_0.handle_ then
		var_0_5.unscheduleGlobal(arg_6_0.handle_)
	end
end

function var_0_0.checkRedMark(arg_7_0, arg_7_1)
	if arg_7_1 == 1 then
		arg_7_0.redMarkReport:setVisible(true)
	else
		arg_7_0.redMarkReport:setVisible(false)
	end
end

function var_0_0.layout(arg_8_0)
	arg_8_0:nodeByName("my_point_txt"):setString(var_0_6:translation("PEAK_ARENA_MY_POINT"))
	arg_8_0:nodeByName("left_times_today_txt"):setString(var_0_6:translation("TODAY_LEFT_TIME"))
	arg_8_0:nodeByName("defend_teams_txt"):setString(var_0_6:translation("DEFENSE_FORMATION"))
	arg_8_0:nodeByName("rechallenge_txt"):setString(var_0_6:translation("PEAK_ARENA_CAN_RECHALLENGE"))

	local var_8_0 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	var_8_0:setString(arg_8_0.peakArena:getPoint())
	var_8_0:addTo(arg_8_0:nodeByName("main_window"))
	var_8_0:setPosition(arg_8_0:nodeByName("point_pos"):getPosition())
	var_8_0:setAnchorPoint(cc.p(0, 0.5))
	arg_8_0:updateLeftTimes()
	arg_8_0:showDefenceTeams()
	arg_8_0:initRevengeList()
	arg_8_0:updateSwitchBtnTxt()
	arg_8_0:nodeByName("switch_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			arg_8_0.switch = not arg_8_0.switch

			arg_8_0:updateSwitchBtnTxt()

			if arg_8_0.switch then
				for iter_9_0 = 1, var_0_1 do
					local var_9_0 = arg_8_0.teamItems[iter_9_0]:getChildByName("container")

					transition.moveTo(arg_8_0.teamItems[iter_9_0], {
						time = 0.2,
						x = var_0_4,
						onComplete = function()
							var_9_0:getChildByName("team" .. iter_9_0):setVisible(false)
							var_9_0:getChildByName("change"):setVisible(true)
							var_9_0:getChildByName("change"):setTouchEnabled(true)
							var_9_0:getChildByName("change"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
								if arg_11_0.name == "began" then
									return true
								elseif arg_11_0.name == "ended" then
									var_9_0:getChildByName("change"):setVisible(false)
									var_9_0:getChildByName("change"):setTouchEnabled(false)
									arg_8_0:openOtherTeamsArrow(iter_9_0)
								end
							end)
						end
					})
				end
			else
				for iter_9_1 = 1, var_0_1 do
					local var_9_1 = arg_8_0.teamItems[iter_9_1]:getChildByName("container")

					var_9_1:getChildByName("heros_layer"):setVisible(false)
					transition.moveTo(arg_8_0.teamItems[iter_9_1], {
						x = 0,
						time = 0.2,
						onComplete = function()
							var_9_1:getChildByName("team" .. iter_9_1):setVisible(true)
							var_9_1:getChildByName("switch"):setVisible(false)
							var_9_1:getChildByName("change"):setVisible(false)
						end
					})
				end
			end
		end
	end)
	arg_8_0:updateChallengeBtnTxt()
	arg_8_0:nodeByName("challenge_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			if not arg_8_0:dealWrongTimeChallenge() then
				return
			end

			if arg_8_0.peakArena.leftTimes <= 0 then
				if arg_8_0.player.vip < 3 then
					local var_13_0 = string.format(xyd.tables.translation:translation("VIP_FUNCTION_NEED"), 3)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_13_0
					})

					return
				end

				local var_13_1 = xyd.tables.refreshCost:peakCost(arg_8_0.peakArena:getBuyTimes() + 1)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					string.format(var_0_6:translation("ARENA_BUY_TIMES1"), arg_8_0.peakArena.buyTimes + 1),
					string.format(var_0_6:translation("ARENA_BUY_TIMES2"), var_13_1)
				}, function()
					if var_13_1 > arg_8_0.player.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_6:translation("ZUANSHI_ABSENCE"), function()
							local var_15_0 = {}

							var_15_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
						end, nil, nil, arg_8_0.colorMode)
					else
						arg_8_0.peakArena:buyChallengeTimes(function(arg_16_0)
							if arg_16_0 == xyd.error.OK then
								arg_8_0:updateChallengeBtnTxt()
								arg_8_0:updateLeftTimes()
							end
						end)
					end
				end, nil, 0, arg_8_0.colorMode)
			elseif arg_8_0.peakArena.coolTime > 0 then
				if arg_8_0.player.vip < 3 then
					local var_13_2 = string.format(xyd.tables.translation:translation("VIP_FUNCTION_NEED"), 3)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_13_2
					})

					return
				end

				arg_8_0:nodeByName("challenge_btn"):setVisible(true)

				local var_13_3 = tonumber(xyd.tables.misc.topRefreshCost)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_6:translation("ARENA_RESET_ALERT"), var_13_3), function()
					if var_13_3 > arg_8_0.player.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_6:translation("ZUANSHI_ABSENCE"), function()
							local var_18_0 = {}

							var_18_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
						end, nil, nil, arg_8_0.colorMode)
					else
						arg_8_0.peakArena:resetCoolTime(function(arg_19_0)
							if arg_19_0 == xyd.error.OK then
								arg_8_0:updateChallengeBtnTxt()
							end
						end)
					end
				end, nil, 0, arg_8_0.colorMode)
			else
				arg_8_0:nodeByName("challenge_btn"):setVisible(true)

				local var_13_4 = arg_8_0.peakArena:getMatches()

				if not var_13_4 or next(var_13_4) == nil then
					arg_8_0.peakArena:refreshEnemies()
				else
					local var_13_5 = {
						matches = var_13_4
					}

					xyd.WindowManager.get():openWindow("change_enemy_old", var_13_5)
				end
			end
		end
	end)
	arg_8_0:nodeByName("adjust_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			local var_20_0 = {
				type = xyd.SelectTeamType.PEAK_ARENA_DEFENSE,
				selectedTeams = clone(arg_8_0.peakArena:getTeams()),
				prePet = clone(arg_8_0.peakArena:getPets())
			}

			xyd.WindowManager.get():openWindow("select_team_peak_old", var_20_0)
		end
	end)
	arg_8_0:nodeByName("exchange_reward_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		if arg_21_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.TOP
				})
			end)
		end
	end)
	arg_8_0:nodeByName("rank_list_btn"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_23_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

			var_23_0:loadRankList({
				xyd.SubRankType.PEAK_RANK_INFO
			}, true, function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					local var_24_0 = {
						rank_type = xyd.RankType.PK,
						sub_type = xyd.SubRankType.PEAK_RANK_INFO,
						rankData = var_23_0:getRankList()
					}

					xyd.WindowManager.get():openWindow("new_rank_list", var_24_0)
				end
			end)
		end
	end)
	arg_8_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_25_0 = {
				rank = arg_8_0.peakArena:getMyRank()
			}

			xyd.WindowManager.get():openWindow("peak_arena_rule_old", var_25_0)
		end
	end)
	arg_8_0:nodeByName("battle_record_btn"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_8_0.peakArena:getPeakRecords(function(arg_27_0)
				if arg_27_0 == xyd.error.OK then
					local var_27_0 = {
						type = xyd.CampaignType.SUPER_ARENA_OLD,
						records = arg_8_0.peakArena:getRecords()
					}

					xyd.WindowManager.get():openWindow("arena_record", var_27_0)
				end
			end)
		end
	end)
end

function var_0_0.initRevengeList(arg_28_0)
	local var_28_0 = arg_28_0.peakArena:getRevengeList()

	for iter_28_0 = 1, #var_28_0 do
		local var_28_1 = var_28_0[iter_28_0]
		local var_28_2 = display.newNode()
		local var_28_3 = arg_28_0.revengeList:newItem()
		local var_28_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/revenge_item.csb")
		local var_28_5 = var_28_4:getChildByName("container")

		var_28_5:getChildByName("point_txt"):setString(var_0_6:translation("JIFEN_TIP") .. var_0_6:translation("COLON"))

		if var_28_1.conquer_lev and var_28_1.conquer_lev > 0 then
			xyd.setConquerLev(var_28_1.conquer_lev, var_28_5:getChildByName("enemy_lev"), var_28_5:getChildByName("level_bg"), nil, false, 0.65, nil, var_28_1.conquer_Loop_id)
		else
			var_28_5:getChildByName("enemy_lev"):setString(var_28_1.level)
			var_28_5:getChildByName("enemy_lev"):setLocalZOrder(30)
		end

		var_28_5:getChildByName("enemy_name"):setString(var_28_1.player_name)
		var_28_5:getChildByName("point_num"):setString(var_28_1.score)

		local var_28_6, var_28_7 = var_28_5:getChildByName("avatar_pos"):getPosition()
		local var_28_8 = var_28_5:getChildByName("revenge_bg")
		local var_28_9 = var_28_5:getChildByName("revenge_head_frame")
		local var_28_10 = var_28_8:getLocalZOrder() + 1 + 1
		local var_28_11

		if avatar_frame_id == nil or avatar_frame_id == 0 then
			var_28_11 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"
		else
			var_28_11 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_28_0.player.avatarFrame] .. ".png"
		end

		local var_28_12 = xyd.AssetLoader.get():loadSprite(var_28_11)

		var_28_12:setPosition(var_28_9:getWidth() / 2, var_28_9:getHeight() / 2)
		var_28_9:addChild(var_28_12)
		var_28_9:setLocalZOrder(var_28_10)
		var_28_5:getChildByName("level_bg"):setLocalZOrder(var_28_10 + 1)

		local var_28_13 = display.newNode()

		var_28_13:setContentSize(60, 60)
		var_28_13:setPosition(var_28_6, var_28_7)
		var_28_13:addTo(var_28_5)
		var_28_13:setName("avatar")
		var_28_13:setAnchorPoint(cc.p(0.5, 0.5))
		xyd.setAvatarClip(var_28_13, var_28_1.avatar_id, 1)
		var_28_13:setTouchEnabled(true)
		var_28_13:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_29_0)
			if arg_29_0.name == "began" then
				return true
			elseif arg_29_0.name == "ended" then
				xyd.playerAvatarTouchEvent(var_28_1)
			end
		end)
		var_28_5:getChildByName("revenge_btn"):addTouchEventListener(function(arg_30_0, arg_30_1)
			if arg_30_1 == ccui.TouchEventType.ended then
				if arg_28_0.scrollViewMoved_ then
					return
				end

				if not arg_28_0:dealWrongTimeChallenge() then
					return
				end

				if arg_28_0.peakArena.leftTimes < 1 then
					local var_30_0 = var_0_6:translation("PEAK_CHALLENGE_TIMES")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_30_0
					})
				elseif arg_28_0.peakArena.coolTime > 0 then
					local var_30_1 = var_0_6:translation("PEAK_CHALLENGE_TIME")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_30_1
					})
				else
					local var_30_2 = {}

					table.insert(var_30_2, var_28_1.team1)
					table.insert(var_30_2, var_28_1.team2)
					table.insert(var_30_2, var_28_1.team3)

					local var_30_3 = {
						{},
						{},
						{}
					}

					table.insert(var_30_3[1], var_28_1.pet1)
					table.insert(var_30_3[2], var_28_1.pet2)
					table.insert(var_30_3[3], var_28_1.pet3)

					local var_30_4 = {
						type = xyd.SelectTeamType.PEAK_ARENA,
						campaignType = xyd.CampaignType.SUPER_ARENA,
						enemyTeams = arg_28_0.peakArena:formatTeamHeros(var_30_2, var_28_1.player_id, false, var_28_1.conquer_lev),
						enemyPets = arg_28_0.peakArena:formatTeamHeros(var_30_3, var_28_1.player_id, true),
						withRobot = var_28_1.is_robot,
						matchedEnemy = var_28_1,
						enemyID = var_28_1.player_id,
						enemyName = var_28_1.player_name,
						enemyLev = var_28_1.level,
						enemyConquerLev = var_28_1.conquer_lev,
						enemyConquerLoopID = var_28_1.conquer_Loop_id,
						enemyAvatar = var_28_1.avatar_id,
						enemyAvatarFrame = var_28_1.avatar_frame_id
					}

					xyd.WindowManager.get():openWindow("select_team_peak_old", var_30_4)
				end
			end
		end)
		var_28_4:setAnchorPoint(cc.p(0, 0))
		var_28_4:addTo(var_28_2)
		var_28_2:setContentSize(var_28_5:getWidth(), var_28_5:getHeight())
		var_28_3:addContent(var_28_2)
		var_28_3:setItemSize(var_28_5:getWidth(), var_28_5:getHeight())
		arg_28_0.revengeList:addItem(var_28_3)
	end

	arg_28_0.revengeList:reload()
end

function var_0_0.updateSwitchBtnTxt(arg_31_0)
	if arg_31_0.switch then
		arg_31_0:nodeByName("change_txt"):setVisible(false)
		arg_31_0:nodeByName("cancel_change"):setVisible(true)
	else
		arg_31_0:nodeByName("change_txt"):setVisible(true)
		arg_31_0:nodeByName("cancel_change"):setVisible(false)
	end
end

function var_0_0.updateLeftTimes(arg_32_0)
	local var_32_0 = arg_32_0.peakArena:getLeftTimes()
	local var_32_1 = string.format(var_32_0 .. "/5")

	arg_32_0:nodeByName("left_times"):setString(var_32_1)
end

function var_0_0.updateChallengeBtnTxt(arg_33_0)
	if arg_33_0.peakArena.leftTimes <= 0 then
		arg_33_0:nodeByName("challenge_txt"):setVisible(false)
		arg_33_0:nodeByName("reset_txt"):setVisible(false)
		arg_33_0:nodeByName("buy_times"):setVisible(true)
		arg_33_0:nodeByName("charge_txt"):setVisible(true)
		arg_33_0:nodeByName("charge_txt"):setString(xyd.tables.refreshCost:peakCost(arg_33_0.peakArena:getBuyTimes() + 1))
		arg_33_0:nodeByName("crystal_bg"):setVisible(true)
		arg_33_0:nodeByName("yuanbao"):setVisible(true)
		arg_33_0:nodeByName("cool_time_txt"):setVisible(false)
		arg_33_0:nodeByName("rechallenge_txt"):setVisible(false)

		if arg_33_0.handle_ then
			var_0_5.unscheduleGlobal(arg_33_0.handle_)
		end
	elseif arg_33_0.peakArena.coolTime > 0 then
		arg_33_0:nodeByName("challenge_txt"):setVisible(false)
		arg_33_0:nodeByName("reset_txt"):setVisible(true)
		arg_33_0:nodeByName("buy_times"):setVisible(false)
		arg_33_0:nodeByName("charge_txt"):setVisible(true)
		arg_33_0:nodeByName("charge_txt"):setString(xyd.tables.misc.topRefreshCost)
		arg_33_0:nodeByName("crystal_bg"):setVisible(true)
		arg_33_0:nodeByName("yuanbao"):setVisible(true)
		arg_33_0:nodeByName("cool_time_txt"):setVisible(true)
		arg_33_0:nodeByName("rechallenge_txt"):setVisible(true)
		arg_33_0:nodeByName("cool_time_txt"):setString(arg_33_0.peakArena:getCoolTimeStr() .. "後")

		arg_33_0.handle_ = var_0_5.scheduleGlobal(function()
			arg_33_0:nodeByName("cool_time_txt"):setString(arg_33_0.peakArena:getCoolTimeStr() .. "後")
		end, 1)
	else
		arg_33_0:nodeByName("challenge_txt"):setVisible(true)
		arg_33_0:nodeByName("reset_txt"):setVisible(false)
		arg_33_0:nodeByName("buy_times"):setVisible(false)
		arg_33_0:nodeByName("charge_txt"):setVisible(false)
		arg_33_0:nodeByName("crystal_bg"):setVisible(false)
		arg_33_0:nodeByName("yuanbao"):setVisible(false)
		arg_33_0:nodeByName("cool_time_txt"):setVisible(false)
		arg_33_0:nodeByName("rechallenge_txt"):setVisible(false)

		if arg_33_0.handle_ then
			var_0_5.unscheduleGlobal(arg_33_0.handle_)
		end
	end
end

function var_0_0.openOtherTeamsArrow(arg_35_0, arg_35_1)
	for iter_35_0 = 1, var_0_1 do
		if iter_35_0 ~= arg_35_1 then
			local var_35_0 = arg_35_0.teamItems[iter_35_0]:getChildByName("container")

			var_35_0:getChildByName("change"):setVisible(false)
			var_35_0:getChildByName("change"):setTouchEnabled(false)
			var_35_0:getChildByName("switch"):setVisible(true)
			var_35_0:getChildByName("switch"):setTouchEnabled(true)
			var_35_0:getChildByName("heros_layer"):setVisible(true)
		end
	end
end

function var_0_0.showDefenceTeams(arg_36_0)
	arg_36_0.teams = arg_36_0.peakArena:getTeams()
	arg_36_0.pets = arg_36_0.peakArena:getPets()

	for iter_36_0 = 1, var_0_1 do
		arg_36_0:nodeByName("team_container_" .. iter_36_0):removeAllChildren()

		local var_36_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena_old/defend_item.csb")
		local var_36_1 = var_36_0:getChildByName("container")

		for iter_36_1 = 1, var_0_1 do
			if iter_36_1 == iter_36_0 then
				var_36_1:getChildByName("team" .. iter_36_1):setVisible(true)
			else
				var_36_1:getChildByName("team" .. iter_36_1):setVisible(false)
			end
		end

		for iter_36_2, iter_36_3 in pairs(arg_36_0.teams[iter_36_0]) do
			local var_36_2 = var_36_1:getChildByName("hero" .. iter_36_2)

			xyd.setAvatarBorder(iter_36_3, var_36_2)
		end

		for iter_36_4, iter_36_5 in pairs(arg_36_0.pets[iter_36_0]) do
			local var_36_3 = var_36_1:getChildByName("pet")

			xyd.setPetAvatar(var_36_3, iter_36_5, nil, true)
		end

		var_36_0:addTo(arg_36_0:nodeByName("team_container_" .. iter_36_0))
		var_36_0:setName("teamItem")
		var_36_0:setAnchorPoint(cc.p(0, 0))
		var_36_0:setPosition(0, 0)

		arg_36_0.teamItems[iter_36_0] = var_36_0

		var_36_1:getChildByName("switch"):setVisible(false)
		var_36_1:getChildByName("change"):setVisible(false)
		var_36_1:getChildByName("heros_layer"):setVisible(false)
		var_36_1:getChildByName("change"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
			if arg_37_0.name == "began" then
				return true
			elseif arg_37_0.name == "ended" then
				var_36_1:getChildByName("change"):setVisible(false)
				var_36_1:getChildByName("change"):setTouchEnabled(false)

				arg_36_0.count = iter_36_0

				arg_36_0:openOtherTeamsArrow(iter_36_0)
			end
		end)
		var_36_1:getChildByName("switch"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
			if arg_38_0.name == "began" then
				return true
			elseif arg_38_0.name == "ended" then
				local var_38_0 = clone(arg_36_0.teams)
				local var_38_1 = var_38_0[arg_36_0.count]

				var_38_0[arg_36_0.count] = var_38_0[iter_36_0]
				var_38_0[iter_36_0] = var_38_1

				local var_38_2 = arg_36_0.peakArena:generatePartnerIds(var_38_0)
				local var_38_3 = clone(arg_36_0.pets)
				local var_38_4 = var_38_3[arg_36_0.count]

				var_38_3[arg_36_0.count] = var_38_3[iter_36_0]
				var_38_3[iter_36_0] = var_38_4

				local var_38_5 = arg_36_0.peakArena:generatePartnerIds(var_38_3, true)

				arg_36_0.teamItems[arg_36_0.count]:getChildByName("container"):getChildByName("heros_layer"):setVisible(true)
				var_36_1:getChildByName("heros_layer"):setVisible(true)

				for iter_38_0 = 1, var_0_1 do
					local var_38_6 = arg_36_0.teamItems[iter_38_0]:getChildByName("container")

					if iter_38_0 == iter_36_0 or iter_38_0 == arg_36_0.count then
						var_38_6:getChildByName("heros_layer"):setVisible(true)
					else
						var_38_6:getChildByName("heros_layer"):setVisible(false)
					end
				end

				arg_36_0.peakArena:changeTeam({
					team1 = var_38_2[1],
					team2 = var_38_2[2],
					team3 = var_38_2[3],
					pet1 = var_38_5[1],
					pet2 = var_38_5[2],
					pet3 = var_38_5[3]
				}, function(arg_39_0)
					if arg_39_0 == xyd.error.OK then
						arg_36_0.teams = var_38_0

						arg_36_0.peakArena:setTeams(var_38_0)

						arg_36_0.pets = var_38_3

						arg_36_0.peakArena:setPets(var_38_3)
						var_36_1:getChildByName("switch"):setVisible(false)
						var_36_1:getChildByName("switch"):setTouchEnabled(false)
						var_0_5.performWithDelayGlobal(function()
							for iter_40_0 = 1, var_0_1 do
								if iter_40_0 == iter_36_0 or iter_40_0 == arg_36_0.count then
									local var_40_0 = arg_36_0.teamItems[iter_40_0]:getChildByName("container")

									for iter_40_1 = 1, var_0_2 do
										var_40_0:getChildByName("hero" .. iter_40_1):removeAllChildren()
									end

									var_40_0:getChildByName("pet"):removeAllChildren()
								end
							end

							var_0_5.performWithDelayGlobal(function()
								for iter_41_0 = 1, var_0_1 do
									if iter_41_0 == iter_36_0 or iter_41_0 == arg_36_0.count then
										for iter_41_1, iter_41_2 in pairs(arg_36_0.teams[iter_41_0]) do
											local var_41_0 = arg_36_0.teamItems[iter_41_0]:getChildByName("container")
											local var_41_1 = var_41_0:getChildByName("hero" .. iter_41_1)

											var_41_1:removeAllChildren()
											xyd.setAvatarBorder(iter_41_2, var_41_1)
											var_41_0:getChildByName("heros_layer"):setVisible(false)
										end

										for iter_41_3, iter_41_4 in pairs(arg_36_0.pets[iter_41_0]) do
											local var_41_2 = arg_36_0.teamItems[iter_41_0]:getChildByName("container"):getChildByName("pet")

											var_41_2:removeAllChildren()
											xyd.setPetAvatar(var_41_2, iter_41_4, nil, true)
										end
									end
								end

								var_0_5.performWithDelayGlobal(function()
									for iter_42_0 = 1, var_0_1 do
										local var_42_0 = arg_36_0.teamItems[iter_42_0]:getChildByName("container")

										transition.moveTo(arg_36_0.teamItems[iter_42_0], {
											x = 0,
											time = 0.2,
											onComplete = function()
												var_42_0:getChildByName("team" .. iter_42_0):setVisible(true)
												var_42_0:getChildByName("switch"):setVisible(false)
												var_42_0:getChildByName("change"):setVisible(false)

												arg_36_0.switch = false

												arg_36_0:updateSwitchBtnTxt()
											end
										})
									end
								end, 0.3)
							end, 0.2)
						end, 0.2)
					end
				end)
			end
		end)
	end
end

function var_0_0.addResultEffectLayer(arg_44_0)
	if arg_44_0.peakArena:getTotalResult() == nil then
		return
	end

	local var_44_0 = cc.c4b(0, 0, 0, 200)
	local var_44_1 = 2

	arg_44_0.effectLayer = display.newColorLayer(var_44_0)

	local var_44_2 = arg_44_0:convertToWorldSpace(cc.p(0, 0))

	arg_44_0.effectLayer:pos(-var_44_2.x, -var_44_2.y):addTo(arg_44_0, var_44_1)
	arg_44_0.effectLayer:setName("effect_layer")
	arg_44_0.effectLayer:setTouchEnabled(true)

	local var_44_3 = {
		x = xyd.STAGE_WIDTH / 2,
		y = xyd.STAGE_HEIGHT / 2
	}

	if arg_44_0.peakArena:getTotalResult() then
		arg_44_0:playEffect(arg_44_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win_spin", var_44_3, true, true, 10)
		arg_44_0:playEffect(arg_44_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win", var_44_3, true, false, 20)
	else
		arg_44_0:playEffect(arg_44_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat_spin", var_44_3, true, true, 10)
		arg_44_0:playEffect(arg_44_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat", var_44_3, true, false, 20)
	end

	arg_44_0.effectLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_45_0)
		if arg_45_0.name == "began" then
			if not noClose then
				local var_45_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_45_0, false)
				arg_44_0:removeChildByName("effect_layer")
			end

			return true
		elseif arg_45_0.name == "ended" and not noClose then
			local var_45_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_45_1, false)
			arg_44_0:removeChildByName("effect_layer")
		end
	end)
end

function var_0_0.playEffect(arg_46_0, arg_46_1, arg_46_2, arg_46_3, arg_46_4, arg_46_5, arg_46_6)
	local var_46_0
	local var_46_1 = arg_46_5 or false
	local var_46_2 = arg_46_2 .. ".json"
	local var_46_3 = arg_46_2 .. ".atlas"
	local var_46_4 = var_0_7.new(var_46_2, var_46_3, 1)

	arg_46_1:addChild(var_46_4, arg_46_6)
	var_46_4:pos(arg_46_3.x, arg_46_3.y)

	if arg_46_4 == true then
		var_46_4:setToSetupPose()
		var_46_4:setVisible(true)

		if var_46_1 then
			var_46_4:play(function()
				return
			end, true)
		else
			var_46_4:play(function()
				var_46_4:setVisible(true)
			end)
		end
	else
		var_46_4:setVisible(false)
	end
end

function var_0_0.dealWrongTimeChallenge(arg_49_0)
	if arg_49_0:checkTimeWithNoDate() == var_0_8.IN_INVALID_TIME then
		local var_49_0 = var_0_6:translation("PEAK_OPEN_TIP")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_49_0
		})

		return false
	end

	return true
end

function var_0_0.checkTimeWithNoDate(arg_50_0)
	local var_50_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_50_0 < xyd.tables.misc.topStartTime or var_50_0 > xyd.tables.misc.topStopTime then
		return var_0_8.IN_INVALID_TIME
	else
		return var_0_8.VALID_TIME
	end
end

return var_0_0
