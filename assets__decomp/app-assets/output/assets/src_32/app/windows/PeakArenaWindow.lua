local var_0_0 = class("PeakArenaWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.peakArenaRank

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teams = arg_1_0.peakArena.teams
	arg_1_0.teamItems = {}
	arg_1_0.switch = false
	arg_1_0.teamNum = arg_1_0.peakArena.teamNum
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		show_rule = true
	})

	arg_2_0.redMarkReport = arg_2_0:nodeByName("red_point")

	arg_2_0:checkRedMark(arg_2_0.player.peakArenaRedMarkEnable)
	arg_2_0:layout()

	local var_2_0 = arg_2_0:nodeByName("defend_container")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.defendList = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0)

	arg_2_0:updateDefendTeam()
	arg_2_0:updateRank()
end

function var_0_0.updateRank(arg_3_0)
	if arg_3_0.rankLabel then
		arg_3_0.rankLabel:removeAllChildren()
		arg_3_0.rankLabel:removeSelf()

		arg_3_0.rankLabel = nil
	end

	local var_3_0, var_3_1 = arg_3_0:nodeByName("region_rank_pos"):getPosition()

	if arg_3_0.peakArena.level < 3 then
		arg_3_0:nodeByName("txt_region_point"):setString(var_0_3:translation("LEGEND_WINDOW_RANK_2"))

		arg_3_0.rankLabel = xyd.colorNumLabel(arg_3_0.peakArena.rank, "yellow1")
	else
		arg_3_0:nodeByName("txt_region_point"):setString(var_0_3:translation("PEAK_ARENA_MY_POINT"))

		arg_3_0.rankLabel = xyd.colorNumLabel(arg_3_0.peakArena.point, "yellow1")
	end

	arg_3_0.rankLabel:addTo(arg_3_0:nodeByName("bg_region_point"))
	arg_3_0.rankLabel:setPosition(var_3_0, var_3_1)
	arg_3_0.rankLabel:setAnchorPoint(cc.p(1, 0))
	arg_3_0:nodeByName("label_rank"):setString(arg_3_0.peakArena.myRank)

	if arg_3_0.peakArena.level < 4 then
		arg_3_0:nodeByName("bg_promo_point"):setVisible(false)
		arg_3_0:nodeByName("bg_region_point"):setPosition(151.5, 78.5)
	else
		arg_3_0:nodeByName("bg_promo_point"):setVisible(true)
		arg_3_0:nodeByName("bg_region_point"):setPosition(152, 122)
		arg_3_0:nodeByName("label_promo_point"):setString(var_0_5:score(arg_3_0.peakArena.level - 1))
	end

	arg_3_0:nodeByName("pic_rank"):loadTexture("windows/peak_arena/pic/rank" .. arg_3_0.peakArena.level .. ".png")
	arg_3_0:nodeByName("pic_word"):setTexture("windows/peak_arena/pic/word" .. arg_3_0.peakArena.level .. ".png")
end

function var_0_0.updateDefendTeam(arg_4_0)
	arg_4_0.teams = arg_4_0.peakArena.teams

	arg_4_0.defendList:removeAllItems()

	for iter_4_0 = 1, arg_4_0.teamNum do
		local var_4_0 = arg_4_0.defendList:newItem()
		local var_4_1, var_4_2 = arg_4_0:newTeamItem(iter_4_0)

		var_4_0:addContent(var_4_1)
		var_4_0:setItemSize(var_4_2.width, var_4_2.height + 13)
		arg_4_0.defendList:addItem(var_4_0)
	end

	arg_4_0.defendList:reload()
end

function var_0_0.newTeamItem(arg_5_0, arg_5_1)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/peak_arena/defend_item.csb")

	arg_5_0.teamItems[arg_5_1] = var_5_0

	local var_5_1 = var_5_0:getChildByName("container")

	var_5_1:getChildByName("pic_team_id"):loadTexture("windows/peak_arena/pic/pic_team" .. arg_5_1 .. ".png")
	arg_5_0:setItemHero(var_5_1, arg_5_0.teams[arg_5_1])

	local var_5_2 = var_5_1:getChildByName("change")

	xyd.nodeEventSample(var_5_2, nil, function(arg_6_0)
		var_5_2:setVisible(false)

		arg_5_0.count = arg_5_1

		arg_5_0:openOtherTeamsArrow(arg_5_1)
	end)

	local var_5_3 = var_5_1:getChildByName("switch")

	xyd.nodeEventSample(var_5_3, nil, function(arg_7_0)
		local var_7_0 = clone(arg_5_0.teams)
		local var_7_1 = var_7_0[arg_5_0.count]

		var_7_0[arg_5_0.count] = var_7_0[arg_5_1]
		var_7_0[arg_5_1] = var_7_1

		arg_5_0.peakArena:changeTeam(var_7_0, function()
			arg_5_0.teams = arg_5_0.peakArena.teams

			var_5_1:getChildByName("switch"):setVisible(false)
			arg_5_0:doSwitchAction(arg_5_1)
		end)
	end)

	local var_5_4 = var_5_1:getContentSize()

	var_5_0:setContentSize(var_5_4.width, var_5_4.height)

	return var_5_0, var_5_4
end

function var_0_0.doSwitchAction(arg_9_0, arg_9_1)
	local var_9_0 = {}

	for iter_9_0 = 1, arg_9_0.teamNum do
		if iter_9_0 == arg_9_1 or iter_9_0 == arg_9_0.count then
			table.insert(var_9_0, iter_9_0)
		end
	end

	for iter_9_1, iter_9_2 in ipairs(var_9_0) do
		local var_9_1 = arg_9_0.teamItems[iter_9_2]:getChildByName("container")

		for iter_9_3 = 1, 5 do
			var_9_1:getChildByName("hero_container" .. iter_9_3):getChildByName("hero" .. iter_9_3):removeAllChildren()
		end

		var_9_1:getChildByName("pet_container"):getChildByName("pet"):removeAllChildren()
	end

	for iter_9_4, iter_9_5 in ipairs(var_9_0) do
		local var_9_2 = arg_9_0.teamItems[iter_9_5]:getChildByName("container")

		arg_9_0:setItemHero(var_9_2, arg_9_0.teams[iter_9_5])
	end

	arg_9_0.switch = false

	arg_9_0:updateSwitchBtnTxt()
	arg_9_0:switchMoveBack()
end

function var_0_0.setItemHero(arg_10_0, arg_10_1, arg_10_2)
	for iter_10_0, iter_10_1 in pairs(arg_10_2.heros) do
		local var_10_0 = arg_10_1:getChildByName("hero_container" .. iter_10_0)

		xyd.setAvatarBorderNewUI(iter_10_1, var_10_0:getChildByName("hero" .. iter_10_0))
	end

	if arg_10_2.pet then
		local var_10_1 = arg_10_1:getChildByName("pet_container")

		xyd.setPetAvatarNewUI(var_10_1:getChildByName("pet"), arg_10_2.pet, nil, true)
	end
end

function var_0_0.switchMoveBack(arg_11_0)
	for iter_11_0 = 1, arg_11_0.teamNum do
		local var_11_0 = arg_11_0.teamItems[iter_11_0]:getChildByName("container")

		var_11_0:getChildByName("change"):setVisible(false)
		var_11_0:getChildByName("switch"):setVisible(false)
		var_11_0:getChildByName("pic_team_id"):setVisible(true)
	end
end

function var_0_0.didOpen(arg_12_0, arg_12_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_12_0):addEventListener(xyd.event.CHECK_MIDDLE_RED_MARK, function(arg_13_0)
		if arg_13_0.params == xyd.CheckMiddleRed.PEAK then
			arg_12_0:checkRedMark(true)
		elseif arg_13_0.params == xyd.CheckMiddleRed.PEAK_CANCEL then
			arg_12_0:checkRedMark(false)
		end
	end)

	if arg_12_0.peakArena.mode == 2 and not arg_12_0.peakArena.hasEffect then
		arg_12_0.peakArena.hasEffect = true

		xyd.WindowManager.get():openWindow("peak_arena_effect", {
			rankLev = arg_12_0.peakArena.level
		})
	end
end

function var_0_0.didClose(arg_14_0, arg_14_1)
	if arg_14_0.handle_ then
		var_0_1.unscheduleGlobal(arg_14_0.handle_)
	end

	if arg_14_0.promoHandle then
		var_0_1.unscheduleGlobal(arg_14_0.promoHandle)
	end
end

function var_0_0.checkRedMark(arg_15_0, arg_15_1)
	arg_15_0.redMarkReport:setVisible(arg_15_1)
end

function var_0_0.layout(arg_16_0)
	arg_16_0:nodeByName("left_times_today_txt"):setString(var_0_3:translation("TODAY_LEFT_TIME"))
	arg_16_0:nodeByName("defend_teams_txt"):setString(var_0_3:translation("DEFENSE_FORMATION"))
	arg_16_0:nodeByName("rechallenge_txt"):setString(var_0_3:translation("PEAK_ARENA_CAN_RECHALLENGE"))
	arg_16_0:nodeByName("txt_my_rank"):setString(var_0_3:translation("LEGEND_WINDOW_POINTS_2"))
	arg_16_0:nodeByName("txt_promo_point"):setString(var_0_3:translation("LEGEND_WINDOW_POINTS_3"))
	arg_16_0:nodeByName("label_promo_time"):setString(var_0_3:translation("LEGEND_PROMO_TIME"))
	arg_16_0:nodeByName("label_promo_win_times"):setString(var_0_3:translation("LEGEND_PROMO_WINS"))
	arg_16_0:nodeByName("cancel_change"):setString(var_0_3:translation("CANCEL"))
	arg_16_0:nodeByName("change_txt"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT1"))
	arg_16_0:nodeByName("txt_adjust"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT2"))
	arg_16_0:nodeByName("txt_my_info"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT3"))
	arg_16_0:nodeByName("buy_times"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT5"))
	arg_16_0:nodeByName("reset_txt"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT6"))
	arg_16_0:nodeByName("challenge_txt"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT7"))
	arg_16_0:nodeByName("txt_record"):setString(var_0_3:translation("FIGHT_RECORD"))
	arg_16_0:nodeByName("txt_rank"):setString(var_0_3:translation("RANKING_LIST"))
	arg_16_0:nodeByName("txt_reward"):setString(var_0_3:translation("TOP_PEAKARENAWINDOW_TEXT8"))
	arg_16_0:updateLeftTimes()
	arg_16_0:updateSwitchBtnTxt()
	arg_16_0:nodeByName("switch_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_17_0, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			arg_16_0.switch = not arg_16_0.switch

			arg_16_0:updateSwitchBtnTxt()

			if arg_16_0.switch then
				for iter_17_0 = 1, arg_16_0.teamNum do
					local var_17_0 = arg_16_0.teamItems[iter_17_0]:getChildByName("container")

					var_17_0:getChildByName("change"):setVisible(true)
					var_17_0:getChildByName("pic_team_id"):setVisible(false)
				end
			else
				arg_16_0:switchMoveBack()
			end
		end
	end)
	arg_16_0:updateChallengeBtnTxt()
	arg_16_0:nodeByName("challenge_btn"):addTouchEventListener(function(arg_18_0, arg_18_1)
		xyd.buttonScaleAnim(arg_18_0, arg_18_1)

		if arg_18_1 == ccui.TouchEventType.ended then
			arg_16_0:clickChallengeBtn()
		end
	end)
	arg_16_0:nodeByName("adjust_btn"):addTouchEventListener(function(arg_19_0, arg_19_1)
		xyd.buttonScaleAnim(arg_19_0, arg_19_1)

		if arg_19_1 == ccui.TouchEventType.ended then
			local var_19_0 = {
				type = xyd.SelectTeamType.PEAK_ARENA_DEFENSE,
				selectedTeams = clone(arg_16_0.peakArena.teams)
			}

			xyd.WindowManager.get():openWindow("select_team_peak", var_19_0)
		end
	end)
	arg_16_0:nodeByName("exchange_reward_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_20_0, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.TOP
				})
			end)
		end
	end)
	arg_16_0:nodeByName("rank_list_btn"):addTouchEventListener(function(arg_22_0, arg_22_1)
		xyd.buttonScaleAnim(arg_22_0, arg_22_1)

		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_22_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)

			var_22_0:loadRankList({
				xyd.SubRankType.LEGEND_RANK_INFO
			}, true, function(arg_23_0, arg_23_1)
				if arg_23_0 == xyd.error.OK then
					local var_23_0 = {
						rank_type = xyd.RankType.PK,
						sub_type = xyd.SubRankType.LEGEND_RANK_INFO,
						rankData = var_22_0:getRankList()
					}

					xyd.WindowManager.get():openWindow("new_rank_list", var_23_0)
				end
			end)
		end
	end)
	xyd.nodeEventSample(arg_16_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function(arg_24_0)
		xyd.playButtonSound()

		local var_24_0 = {
			rank = arg_16_0.peakArena.rank,
			myRank = arg_16_0.peakArena.myRank
		}

		xyd.WindowManager.get():openWindow("peak_arena_rule", var_24_0)
	end)
	arg_16_0:nodeByName("battle_record_btn"):addTouchEventListener(function(arg_25_0, arg_25_1)
		xyd.buttonScaleAnim(arg_25_0, arg_25_1)

		if arg_25_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_16_0.peakArena:getPeakRecordsList(function(arg_26_0)
				local var_26_0 = {
					type = xyd.CampaignType.SUPER_ARENA,
					records = arg_26_0.battle_records
				}

				xyd.WindowManager.get():openWindow("new_arena_record", var_26_0)
			end)
		end
	end)
end

function var_0_0.clickChallengeBtn(arg_27_0)
	if not arg_27_0:dealWrongTimeChallenge() then
		return
	end

	local function var_27_0()
		arg_27_0:nodeByName("challenge_btn"):setVisible(true)
		arg_27_0.peakArena:refreshEnemies(function()
			local var_29_0 = arg_27_0.peakArena:getMatches()

			if #var_29_0 == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("LEGEND_WINDOW_TIP_1")
				})
			else
				xyd.WindowManager.get():openWindow("change_enemy", {
					matches = var_29_0
				})
			end
		end)
	end

	if arg_27_0.peakArena.mode == 2 then
		if arg_27_0.peakArena.promoteCoolTime > xyd.ServerTime.get():getServerTime() then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_3:translation("LEGEND_PROMO_TIPS2")
			})
		else
			var_27_0()
		end

		return
	end

	if arg_27_0.peakArena.leftTimes <= 0 then
		if not arg_27_0:vipLevelDeal() then
			return
		end

		local var_27_1 = xyd.tables.refreshCost:peakCost(arg_27_0.peakArena:getBuyTimes() + 1)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
			string.format(var_0_3:translation("ARENA_BUY_TIMES1"), arg_27_0.peakArena.buyTimes + 1),
			string.format(var_0_3:translation("ARENA_BUY_TIMES2"), var_27_1)
		}, function()
			if not arg_27_0:crystalCostDeal(var_27_1) then
				return
			end

			arg_27_0.peakArena:buyChallengeTimes(function(arg_31_0)
				if arg_31_0 == xyd.error.OK then
					arg_27_0:updateChallengeBtnTxt()
					arg_27_0:updateLeftTimes()
				end
			end)
		end, nil, 0, arg_27_0.colorMode)
	elseif arg_27_0.peakArena.coolTime > xyd.ServerTime.get():getServerTime() then
		if not arg_27_0:vipLevelDeal() then
			return
		end

		arg_27_0:nodeByName("challenge_btn"):setVisible(true)

		local var_27_2 = tonumber(var_0_4.topRefreshCost)

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("ARENA_RESET_ALERT"), var_27_2), function()
			if not arg_27_0:crystalCostDeal(var_27_2) then
				return
			end

			arg_27_0.peakArena:resetCoolTime(function(arg_33_0)
				if arg_33_0 == xyd.error.OK then
					arg_27_0:updateChallengeBtnTxt()
				end
			end)
		end, nil, 0, arg_27_0.colorMode)
	else
		var_27_0()
	end
end

function var_0_0.updateSwitchBtnTxt(arg_34_0)
	if arg_34_0.switch then
		arg_34_0:nodeByName("change_txt"):setVisible(false)
		arg_34_0:nodeByName("cancel_change"):setVisible(true)
	else
		arg_34_0:nodeByName("change_txt"):setVisible(true)
		arg_34_0:nodeByName("cancel_change"):setVisible(false)
	end
end

function var_0_0.updateLeftTimes(arg_35_0)
	if arg_35_0.peakArena.mode == 2 then
		arg_35_0:nodeByName("container_left_time"):setVisible(false)
		arg_35_0:nodeByName("container_promo_time"):setVisible(true)
		arg_35_0:nodeByName("promo_win_times"):setString(3 - arg_35_0.peakArena.promoteTimes .. "/" .. arg_35_0.peakArena.promoteWin)

		if arg_35_0.promoHandle then
			var_0_1.unscheduleGlobal(arg_35_0.promoHandle)
		end

		arg_35_0:updatePromoTimeTxt()

		arg_35_0.promoHandle = var_0_1.scheduleGlobal(function()
			arg_35_0:updatePromoTimeTxt()
		end, 1)

		arg_35_0:nodeByName("rechallenge_txt"):setPositionY(178.5)
		arg_35_0:nodeByName("cool_time_txt"):setPositionY(150)
	else
		arg_35_0:nodeByName("container_promo_time"):setVisible(false)
		arg_35_0:nodeByName("container_left_time"):setVisible(true)

		local var_35_0 = arg_35_0.peakArena:getLeftTimes()
		local var_35_1 = string.format(var_35_0 .. "/10")

		arg_35_0:nodeByName("left_times"):setString(var_35_1)
		arg_35_0:nodeByName("rechallenge_txt"):setPositionY(153.5)
		arg_35_0:nodeByName("cool_time_txt"):setPositionY(125)
	end
end

function var_0_0.updateChallengeBtnTxt(arg_37_0)
	if arg_37_0.handle_ then
		var_0_1.unscheduleGlobal(arg_37_0.handle_)
	end

	if arg_37_0.peakArena.mode == 2 then
		arg_37_0:nodeByName("challenge_txt"):setVisible(true)
		arg_37_0:nodeByName("reset_txt"):setVisible(false)
		arg_37_0:nodeByName("buy_times"):setVisible(false)
		arg_37_0:nodeByName("bg_crystal"):setVisible(false)

		if arg_37_0.peakArena.promoteCoolTime > xyd.ServerTime.get():getServerTime() then
			arg_37_0:nodeByName("cool_time_txt"):setVisible(true)
			arg_37_0:nodeByName("rechallenge_txt"):setVisible(true)
			arg_37_0:updateCoolTimeTxt()

			arg_37_0.handle_ = var_0_1.scheduleGlobal(function()
				arg_37_0:updateCoolTimeTxt()
			end, 1)
		else
			arg_37_0:nodeByName("cool_time_txt"):setVisible(false)
			arg_37_0:nodeByName("rechallenge_txt"):setVisible(false)
		end
	elseif arg_37_0.peakArena.leftTimes <= 0 then
		arg_37_0:nodeByName("challenge_txt"):setVisible(false)
		arg_37_0:nodeByName("reset_txt"):setVisible(false)
		arg_37_0:nodeByName("buy_times"):setVisible(true)
		arg_37_0:nodeByName("charge_txt"):setString(xyd.tables.refreshCost:peakCost(arg_37_0.peakArena:getBuyTimes() + 1))
		arg_37_0:nodeByName("bg_crystal"):setVisible(true)
		arg_37_0:nodeByName("cool_time_txt"):setVisible(false)
		arg_37_0:nodeByName("rechallenge_txt"):setVisible(false)
	elseif arg_37_0.peakArena.coolTime > xyd.ServerTime.get():getServerTime() then
		arg_37_0:nodeByName("challenge_txt"):setVisible(false)
		arg_37_0:nodeByName("reset_txt"):setVisible(true)
		arg_37_0:nodeByName("buy_times"):setVisible(false)
		arg_37_0:nodeByName("charge_txt"):setString(var_0_4.topRefreshCost)
		arg_37_0:nodeByName("bg_crystal"):setVisible(true)
		arg_37_0:nodeByName("cool_time_txt"):setVisible(true)
		arg_37_0:nodeByName("rechallenge_txt"):setVisible(true)
		arg_37_0:updateCoolTimeTxt()

		arg_37_0.handle_ = var_0_1.scheduleGlobal(function()
			arg_37_0:updateCoolTimeTxt()
		end, 1)
	else
		arg_37_0:nodeByName("challenge_txt"):setVisible(true)
		arg_37_0:nodeByName("reset_txt"):setVisible(false)
		arg_37_0:nodeByName("buy_times"):setVisible(false)
		arg_37_0:nodeByName("bg_crystal"):setVisible(false)
		arg_37_0:nodeByName("cool_time_txt"):setVisible(false)
		arg_37_0:nodeByName("rechallenge_txt"):setVisible(false)
	end
end

function var_0_0.updatePromoTimeTxt(arg_40_0)
	if not arg_40_0.peakArena.promoEndTime then
		if arg_40_0.promoHandle then
			var_0_1.unscheduleGlobal(arg_40_0.promoHandle)
		end

		return
	end

	local var_40_0 = arg_40_0.peakArena.promoEndTime - xyd.ServerTime.get():getServerTime()

	if var_40_0 <= 0 then
		xyd.WindowManager.get():closeWindow(arg_40_0)

		return
	end

	local var_40_1 = var_40_0 % 60
	local var_40_2 = math.floor(var_40_0 / 60)
	local var_40_3 = var_40_2 % 60
	local var_40_4 = math.floor(var_40_2 / 60)

	arg_40_0:nodeByName("promo_time"):setString(string.format("%d:%02d:%02d", var_40_4, var_40_3, var_40_1))
end

function var_0_0.updateCoolTimeTxt(arg_41_0)
	local var_41_0 = (arg_41_0.peakArena.mode == 2 and arg_41_0.peakArena.promoteCoolTime or arg_41_0.peakArena.coolTime) - xyd.ServerTime.get():getServerTime()

	if var_41_0 <= 0 then
		arg_41_0:updateChallengeBtnTxt()

		return
	end

	local var_41_1 = ""
	local var_41_2 = ""
	local var_41_3 = ""
	local var_41_4 = math.floor(var_41_0 / 60)
	local var_41_5 = var_41_0 % 60

	if var_41_4 >= 10 then
		var_41_2 = tostring(var_41_4)
	else
		var_41_2 = "0" .. tostring(var_41_4)
	end

	if var_41_5 >= 10 then
		var_41_3 = tostring(var_41_5)
	else
		var_41_3 = "0" .. tostring(var_41_5)
	end

	local var_41_6 = var_41_2 .. ":" .. var_41_3

	arg_41_0:nodeByName("cool_time_txt"):setString(var_41_6 .. var_0_3:translation("COUNT_DOWN_LATER"))
end

function var_0_0.openOtherTeamsArrow(arg_42_0, arg_42_1)
	for iter_42_0 = 1, arg_42_0.teamNum do
		if iter_42_0 ~= arg_42_1 then
			local var_42_0 = arg_42_0.teamItems[iter_42_0]:getChildByName("container")

			var_42_0:getChildByName("change"):setVisible(false)
			var_42_0:getChildByName("switch"):setVisible(true)
		end
	end
end

function var_0_0.addResultEffectLayer(arg_43_0)
	if arg_43_0.peakArena:getTotalResult() == nil then
		return
	end

	local var_43_0 = cc.c4b(0, 0, 0, 200)
	local var_43_1 = 2

	arg_43_0.effectLayer = display.newColorLayer(var_43_0)

	local var_43_2 = arg_43_0:convertToWorldSpace(cc.p(0, 0))

	arg_43_0.effectLayer:pos(-var_43_2.x, -var_43_2.y):addTo(arg_43_0, var_43_1)
	arg_43_0.effectLayer:setName("effect_layer")
	arg_43_0.effectLayer:setTouchEnabled(true)

	local var_43_3 = {
		x = xyd.STAGE_WIDTH / 2,
		y = xyd.STAGE_HEIGHT / 2
	}

	if arg_43_0.peakArena:getTotalResult() then
		arg_43_0:playEffect(arg_43_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win_spin", var_43_3, true, true, 10)
		arg_43_0:playEffect(arg_43_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win", var_43_3, true, false, 20)
	else
		arg_43_0:playEffect(arg_43_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat_spin", var_43_3, true, true, 10)
		arg_43_0:playEffect(arg_43_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat", var_43_3, true, false, 20)
	end

	arg_43_0.effectLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
		if arg_44_0.name == "began" then
			if not noClose then
				local var_44_0 = xyd.tables.sound:getSound("ui_close_window")

				audio.playSound(var_44_0, false)
				arg_43_0:removeChildByName("effect_layer")
			end

			return true
		elseif arg_44_0.name == "ended" and not noClose then
			local var_44_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_44_1, false)
			arg_43_0:removeChildByName("effect_layer")
		end
	end)
end

function var_0_0.playEffect(arg_45_0, arg_45_1, arg_45_2, arg_45_3, arg_45_4, arg_45_5, arg_45_6)
	local var_45_0
	local var_45_1 = arg_45_5 or false
	local var_45_2 = arg_45_2 .. ".json"
	local var_45_3 = arg_45_2 .. ".atlas"
	local var_45_4 = var_0_2.new(var_45_2, var_45_3, 1)

	arg_45_1:addChild(var_45_4, arg_45_6)
	var_45_4:pos(arg_45_3.x, arg_45_3.y)

	if arg_45_4 == true then
		var_45_4:setToSetupPose()
		var_45_4:setVisible(true)

		if var_45_1 then
			var_45_4:play(nil, true)
		else
			var_45_4:play(function()
				var_45_4:setVisible(true)
			end)
		end
	else
		var_45_4:setVisible(false)
	end
end

function var_0_0.dealWrongTimeChallenge(arg_47_0)
	return true
end

function var_0_0.vipLevelDeal(arg_48_0)
	if arg_48_0.player.vip < 3 and arg_48_0.player.privilegeLeftCardDay <= 0 then
		local var_48_0 = string.format(xyd.tables.translation:translation("VIP_FUNCTION_NEED"), 3)

		xyd.WindowManager.get():openWindow("toast", {
			message = var_48_0
		})

		return false
	end

	return true
end

function var_0_0.crystalCostDeal(arg_49_0, arg_49_1)
	if arg_49_1 > arg_49_0.player.crystal then
		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
			xyd.WindowManager.get():openWindow("vip_recharge", {
				windowState = true
			})
		end, nil, nil, arg_49_0.colorMode)

		return false
	end

	return true
end

return var_0_0
