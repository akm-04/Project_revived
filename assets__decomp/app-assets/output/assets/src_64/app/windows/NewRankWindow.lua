local var_0_0 = class("RankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.EcoSidebar")
local var_0_2 = xyd.WindowName.rankWnd
local var_0_3 = 10
local var_0_4 = xyd.tables.translation
local var_0_5 = import("app.model.Hero")
local var_0_6 = import("app.model.Pet")
local var_0_7 = xyd.tables.misc.teamIcons[1]

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.rank_type = arg_1_2.rank_type
	arg_1_0.curSubType = arg_1_2.sub_type
	arg_1_0.sub_type = arg_1_2.sub_type
	arg_1_0.ranks = {}
	arg_1_0.leftSelected = -1
	arg_1_0.subTypeLists = {}
	arg_1_0.enter_rank_type = arg_1_2.rank_type
	arg_1_0.leftSelectedIndex = 0
	arg_1_0.has_click_left = false
	arg_1_0.click_same_left = false
	arg_1_0.index_ = 1
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rankList = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_1_0.rankData = arg_1_2.rankData or arg_1_0.rankList:getRankList() or {}
	arg_1_0.firstIn = true
	arg_1_0.idx = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.rank_type then
		arg_3_0.firstIn = false
	end

	arg_3_0.left_container = arg_3_0:nodeByName("left_inner")

	local var_3_0 = arg_3_0.left_container:getContentSize()

	arg_3_0.leftList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.left_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener1)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_3_0.main_container = arg_3_0:nodeByName("main_inner")

	local var_3_1 = arg_3_0.main_container:getContentSize()

	arg_3_0.mainList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_3_0.main_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_3_0.bottom_container = arg_3_0:nodeByName("bottom_inner")

	local var_3_2 = arg_3_0.bottom_container:getContentSize()

	arg_3_0.bottomList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_2.width, var_3_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.bottom_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):setBounceable(false):pos(0, 0)

	arg_3_0.bottomList_:setViewCanNotScroll(true)

	arg_3_0.return_btn = arg_3_0:nodeByName("return_button")

	arg_3_0.return_btn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("new_rank_list")
		end
	end)
	arg_3_0.bottomList_:setDelegate(handler(arg_3_0, arg_3_0.myrankDelegate))
	arg_3_0.mainList_:setDelegate(handler(arg_3_0, arg_3_0.rankDelegate))
	arg_3_0:nodeByName("refresh_bg"):setVisible(false)
	arg_3_0:updateListView()
end

function var_0_0.getItemCount(arg_5_0, arg_5_1)
	if arg_5_0.curSubType == xyd.SubRankType.PARADISE_TEAM_RANK then
		return #arg_5_1
	end

	return math.min(50, #arg_5_1)
end

function var_0_0.myrankDelegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = arg_6_0.mainRankList.myRank
	local var_6_1 = arg_6_0.mainRankList.info_text
	local var_6_2 = 1

	if cc.ui.UIListView.COUNT_TAG == arg_6_2 then
		return var_6_2
	elseif cc.ui.UIListView.CELL_TAG == arg_6_2 then
		if var_6_2 < arg_6_3 then
			return nil
		end

		if arg_6_3 == 1 and var_6_0 then
			return arg_6_0:addMyRank(var_6_0, var_6_1)
		else
			return arg_6_0:initMyRank()
		end
	end
end

function var_0_0.rankDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0.mainRankList.rankList
	local var_7_1 = arg_7_0.mainRankList.info_text
	local var_7_2 = arg_7_0.mainRankList.title
	local var_7_3 = arg_7_0:getItemCount(var_7_0)

	if var_7_3 == 0 then
		arg_7_0:nodeByName("partner"):setVisible(true)
	end

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return var_7_3
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		if arg_7_3 == 1 then
			arg_7_0:nodeByName("partner"):setVisible(false)
		end

		if var_7_3 < arg_7_3 then
			return nil
		end

		local var_7_4
		local var_7_5 = arg_7_3
		local var_7_6 = var_7_0[var_7_5]

		return arg_7_0:addRankItem(var_7_6, var_7_1, var_7_5, var_7_2)
	end
end

function var_0_0.initMyRank(arg_8_0)
	local var_8_0 = arg_8_0.bottomList_:dequeueItem()

	if not var_8_0 then
		var_8_0 = arg_8_0.bottomList_:newItem()
	else
		var_8_0:removeAllChildren(true)
	end

	local var_8_1 = display.newNode()
	local var_8_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/my_rank_item.csb")
	local var_8_3 = var_8_2:getChildByName("container")

	xyd.setPlayerTitle(var_8_3:getChildByName("title_container"), arg_8_0.selfPlayer.titleInfo)

	local var_8_4 = var_8_3:getContentSize()

	var_8_3:getChildByName("text_player_name"):setString(arg_8_0.selfPlayer.playerName)
	xyd.setPlayerAvatar(var_8_3:getChildByName("avatar"), {
		avatar_id = arg_8_0.selfPlayer:getMyCurrentAvatarID(),
		avatar_frame_id = arg_8_0.selfPlayer.avatarFrame
	})

	if arg_8_0.selfPlayer.conquerLev and arg_8_0.selfPlayer.conquerLev > 0 then
		xyd.setConquerLev(arg_8_0.selfPlayer.conquerLev, var_8_3:getChildByName("text_level"), var_8_3:getChildByName("dengjiquan"), nil, nil, 0.6)
	else
		var_8_3:getChildByName("text_level"):setString(arg_8_0.selfPlayer.lev)
	end

	var_8_3:getChildByName("text_my_rank"):setVisible(false)
	var_8_3:getChildByName("rank_num"):setVisible(false)
	var_8_3:getChildByName("text_yesterday"):setVisible(false)
	var_8_3:getChildByName("down_arrow"):setVisible(false)
	var_8_3:getChildByName("up_arrow"):setVisible(false)
	var_8_3:getChildByName("text_change"):setVisible(false)
	var_8_3:getChildByName("text_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_8_2:setPosition(cc.p(0, 0))
	var_8_2:setContentSize(var_8_4.width, var_8_4.height)
	var_8_1:addChild(var_8_2)
	var_8_1:setContentSize(cc.size(arg_8_0.bottomList_.viewRect_.width, var_8_4.height))
	var_8_0:addContent(var_8_1)
	var_8_0:setItemSize(arg_8_0.bottomList_.viewRect_.width, var_8_4.height)

	return var_8_0
end

function var_0_0.addMyRank(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_0.bottomList_:dequeueItem()

	if not var_9_0 then
		var_9_0 = arg_9_0.bottomList_:newItem()
	else
		var_9_0:removeAllChildren(true)
	end

	local var_9_1 = display.newNode()
	local var_9_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/my_rank_item.csb")
	local var_9_3 = var_9_2:getChildByName("container")

	var_9_3:getChildByName("text_yesterday"):setString(var_0_4:translation("MY_RANK_COMPARE"))

	local var_9_4 = var_9_3:getContentSize()

	if arg_9_0.curSubType ~= 11 and arg_9_0.curSubType ~= 39 and arg_9_0.curSubType ~= 26 then
		xyd.setPlayerTitle(var_9_3:getChildByName("title_container"), arg_9_0.selfPlayer.titleInfo)
	end

	if arg_9_1.rank then
		var_9_3:getChildByName("text_my_rank"):setVisible(true)
		var_9_3:getChildByName("rank_num"):setVisible(true)
		var_9_3:getChildByName("rank_num"):setString(arg_9_1.rank)
		var_9_3:getChildByName("rank_num"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	else
		var_9_3:getChildByName("text_my_rank"):setVisible(false)
		var_9_3:getChildByName("rank_num"):setVisible(false)
	end

	if arg_9_1.name then
		var_9_3:getChildByName("text_player_name"):setString(arg_9_1.name)
		var_9_3:getChildByName("avatar"):setPosition(var_9_3:getChildByName("avatar"):getX() - 15, var_9_3:getChildByName("avatar"):getY() - 2)
		arg_9_0:setGuildAvatar(var_9_3:getChildByName("avatar"), arg_9_1.icon, true)
		var_9_3:getChildByName("avatar"):setScale(0.55)
		var_9_3:getChildByName("text_level"):setString("")
	else
		var_9_3:getChildByName("text_player_name"):setString(arg_9_0.selfPlayer.playerName)
		xyd.setPlayerAvatar(var_9_3:getChildByName("avatar"), {
			avatar_id = arg_9_0.selfPlayer:getMyCurrentAvatarID(),
			avatar_frame_id = arg_9_0.selfPlayer.avatarFrame
		})

		if arg_9_0.selfPlayer.conquerLev and arg_9_0.selfPlayer.conquerLev > 0 then
			xyd.setConquerLev(arg_9_0.selfPlayer.conquerLev, var_9_3:getChildByName("text_level"), var_9_3:getChildByName("dengjiquan"), nil, nil, 0.6)
		else
			var_9_3:getChildByName("text_level"):setString(arg_9_0.selfPlayer.lev)
		end
	end

	arg_9_0:initTextMyRank(var_9_3, arg_9_2, arg_9_1)

	local var_9_5 = tonumber(arg_9_1.diff) or 0

	if var_9_5 == 0 then
		var_9_3:getChildByName("text_yesterday"):setVisible(false)
		var_9_3:getChildByName("down_arrow"):setVisible(false)
		var_9_3:getChildByName("up_arrow"):setVisible(false)
		var_9_3:getChildByName("text_change"):setVisible(false)
	elseif var_9_5 < 0 then
		var_9_3:getChildByName("text_yesterday"):setVisible(true)
		var_9_3:getChildByName("down_arrow"):setVisible(false)
		var_9_3:getChildByName("up_arrow"):setVisible(true)
		var_9_3:getChildByName("text_change"):setString(-var_9_5)
	else
		var_9_3:getChildByName("text_yesterday"):setVisible(true)
		var_9_3:getChildByName("down_arrow"):setVisible(true)
		var_9_3:getChildByName("up_arrow"):setVisible(false)
		var_9_3:getChildByName("text_change"):setString(var_9_5)
	end

	var_9_3:getChildByName("text_my_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_9_3:getChildByName("text_yesterday"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_9_3:getChildByName("text_change"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_9_3:getChildByName("text_rank"):enableOutline(cc.c4b(145, 90, 53, 255), 2)
	var_9_2:setPosition(cc.p(0, 0))
	var_9_2:setContentSize(var_9_4.width, var_9_4.height)
	var_9_1:addChild(var_9_2)
	var_9_1:setContentSize(cc.size(arg_9_0.bottomList_.viewRect_.width, var_9_4.height))
	var_9_0:addContent(var_9_1)
	var_9_0:setItemSize(arg_9_0.bottomList_.viewRect_.width, var_9_4.height)

	return var_9_0
end

function var_0_0.initTextMyRank(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	local var_10_0 = ""
	local var_10_1

	if arg_10_3.score then
		var_10_1 = arg_10_3.score
	elseif arg_10_3.point then
		var_10_1 = arg_10_3.point
	elseif arg_10_3.alive_num and arg_10_3.kill_num then
		var_10_0 = string.format(arg_10_2, arg_10_3.kill_num, arg_10_3.alive_num)
	elseif arg_10_3.damage then
		var_10_1 = arg_10_3.damage
	elseif arg_10_3.guildDamage then
		var_10_1 = arg_10_3.guildDamage
	elseif arg_10_3.comfort then
		var_10_1 = arg_10_3.comfort
	elseif arg_10_3.hero_num then
		var_10_1 = arg_10_3.hero_num
	elseif arg_10_3.win_times then
		var_10_1 = arg_10_3.win_times
	elseif arg_10_3 == {} then
		var_10_1 = 0
	end

	if var_10_1 then
		var_10_0 = string.format(arg_10_2, var_10_1)
	end

	if var_10_0 == "" and arg_10_3.rank then
		arg_10_1:getChildByName("text_rank"):setString(var_10_0)
	elseif var_10_0 == "" and not arg_10_3.rank then
		-- block empty
	else
		arg_10_1:getChildByName("text_rank"):setString(var_10_0)
	end
end

function var_0_0.showTeamInfo(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

	var_11_0:getEnemyTeam(arg_11_1.player_id, function(arg_12_0)
		xyd.WindowManager.get():openWindow("peak_team_info", {
			rank = arg_11_2,
			playerInfo = arg_11_1,
			teams = var_11_0:formatTeams(arg_12_0)
		})
	end)
end

function var_0_0.addRankItem(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4)
	local var_13_0 = arg_13_0.mainList_:dequeueItem()

	if not var_13_0 then
		var_13_0 = arg_13_0.mainList_:newItem()
	else
		var_13_0:removeAllChildren(true)
	end

	local var_13_1 = display.newNode()
	local var_13_2 = "windows/arena/rank/rank_item.csb"
	local var_13_3 = xyd.AssetLoader.get():loadNodeFromJson(var_13_2)
	local var_13_4 = var_13_3:getChildByName("container")

	var_13_4:setPositionX(var_13_4:getPositionX() + 5)
	var_13_3:setTouchEnabled(true)
	var_13_3:setTouchSwallowEnabled(false)
	var_13_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			var_13_4:setScale(0.98)

			arg_13_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_14_0.name == "moved" then
			var_13_4:setScale(1)

			return true
		elseif arg_14_0.name == "ended" then
			var_13_4:setScale(1)

			if arg_13_0.isOpenPlayerInfoWindow then
				arg_13_0.isOpenPlayerInfoWindow = false

				return
			end

			if not arg_13_0.scrollViewMoved_ then
				arg_13_0:clickCell(arg_13_1, arg_13_3)
			end
		end
	end)
	arg_13_0:addSpecialIcon(var_13_4, arg_13_1)
	arg_13_0:initCellRankNum(var_13_4, arg_13_1, arg_13_3)
	arg_13_0:initAvatarInfo(var_13_4, arg_13_1)
	arg_13_0:initInfoText(var_13_4, arg_13_1, arg_13_2)

	local var_13_5 = var_13_4:getContentSize()

	var_13_3:setPosition(cc.p(15, 0))
	var_13_3:setContentSize(var_13_5.width + 15, var_13_5.height)
	var_13_1:addChild(var_13_3)
	var_13_1:setContentSize(cc.size(arg_13_0.mainList_.viewRect_.width, var_13_3:getContentSize().height))
	var_13_0:addContent(var_13_1)
	var_13_0:setItemSize(arg_13_0.mainList_.viewRect_.width, var_13_1:getContentSize().height + 5)

	return var_13_0
end

function var_0_0.clickCell(arg_15_0, arg_15_1, arg_15_2)
	if arg_15_0.curSubType == xyd.SubRankType.ARENA_RANK or arg_15_0.curSubType == xyd.SubRankType.ARENA_MODE_RANK_INFO then
		local var_15_0 = {
			other_player_id = arg_15_1.player_id
		}
		local var_15_1 = arg_15_0.curSubType == xyd.SubRankType.ARENA_RANK and xyd.mid.query_arena_formation or xyd.mid.ARENA_MODE_QUERY_FORMATION

		xyd.Backend.get():request(var_15_1, var_15_0, function(arg_16_0, arg_16_1)
			if arg_16_0 == xyd.error.OK then
				local var_16_0 = arg_16_1.heros
				local var_16_1 = 0
				local var_16_2 = arg_16_1.book_shelf_lev
				local var_16_3 = {}

				if var_16_0 and next(var_16_0) then
					for iter_16_0, iter_16_1 in ipairs(var_16_0) do
						local var_16_4 = import("app.model.Hero").new()
						local var_16_5 = iter_16_1

						if arg_16_1.is_robot == true then
							var_16_5.table_id = iter_16_1.partner_id
							var_16_5.partner_id = iter_16_0
						end

						if type(var_15_0.equips) == "string" then
							var_16_5.equips = xyd.splitToNumber(var_15_0.equips, "|")
						end

						var_16_4:populate(var_16_5)

						if arg_16_1.conquer_lev and arg_16_1.conquer_lev > 0 then
							var_16_4:setConquerSchoolLev(arg_16_1.conquer_lev, arg_16_1.conquer_loop_id)
						end

						table.insert(var_16_3, var_16_4)

						var_16_1 = var_16_1 + var_16_4:getZhandouli()
					end
				end

				if arg_16_1.pet then
					local var_16_6 = import("app.model.Pet").new()

					var_16_6:populate(arg_16_1.pet)

					var_16_1 = var_16_1 + var_16_6:getZhandouli()
				end

				local var_16_7 = {
					name = arg_16_1.player_name,
					level = arg_16_1.lev,
					avatar_id = arg_16_1.avatar_id,
					avatar_frame_id = arg_16_1.avatar_frame_id,
					win = arg_16_1.win,
					rank = arg_16_1.rank or arg_15_2,
					force = var_16_1,
					heroes = var_16_3,
					guild = arg_16_1.guild_name,
					pet = arg_16_1.pet,
					conquer_lev = arg_16_1.conquer_lev,
					conquer_loop_id = arg_16_1.conquer_loop_id
				}

				xyd.WindowManager.get():openWindow("arena_team_info", {
					team = var_16_7
				})
			end
		end)
	elseif arg_15_0.curSubType == xyd.SubRankType.LEGEND_RANK_TOTAL_INFO or arg_15_0.curSubType == xyd.SubRankType.LEGEND_RANK_INFO then
		arg_15_0:showTeamInfo(arg_15_1, arg_15_2)
	elseif arg_15_0.curSubType == xyd.SubRankType.TOTAL_TEAM_POWER then
		local var_15_2 = {}

		for iter_15_0, iter_15_1 in ipairs(arg_15_1.partner_infos) do
			iter_15_1.player_id = arg_15_1.player_id

			local var_15_3 = var_0_5.new()

			var_15_3:populate(params1)
			table.insert(var_15_2, var_15_3)
		end

		local var_15_4

		if arg_15_1.pet_info and arg_15_1.pet_info.table_id then
			local var_15_5 = arg_15_1.pet_info

			var_15_5.player_id = arg_15_1.player_id
			var_15_4 = var_15_5
		end

		local var_15_6 = {
			name = arg_15_1.player_name,
			level = arg_15_1.lev,
			avatar_id = arg_15_1.avatar_id,
			avatar_frame_id = arg_15_1.avatar_frame_id,
			rank = arg_15_2,
			force = arg_15_1.force,
			heroes = var_15_2,
			guild = arg_15_1.guild_name,
			conquer_lev = arg_15_1.conquer_lev,
			conquer_loop_id = arg_15_1.conquer_loop_id
		}

		if var_15_4 then
			var_15_6.pet = var_15_4
		end

		xyd.WindowManager.get():openWindow("arena_team_info", {
			team = var_15_6
		})
	elseif arg_15_0.rank_type == xyd.RankType.WB or arg_15_0.curSubType == xyd.SubRankType.PARADISE_PERSON_RANK then
		local var_15_7 = {
			player_id = arg_15_1.player_id
		}

		if arg_15_0.curSubType ~= xyd.SubRankType.ARENA_RANK or not xyd.mid.query_arena_formation then
			local var_15_8 = xyd.mid.ARENA_MODE_QUERY_FORMATION
		end

		local var_15_9 = xyd.mid.ILLUSION_RANK_HEROS

		xyd.Backend.get():request(var_15_9, var_15_7, function(arg_17_0, arg_17_1)
			if arg_17_0 == xyd.error.OK then
				local var_17_0 = arg_17_1.heros
				local var_17_1 = 0
				local var_17_2 = arg_17_1.book_shelf_lev
				local var_17_3 = {}

				if var_17_0 and next(var_17_0) then
					for iter_17_0, iter_17_1 in ipairs(var_17_0) do
						local var_17_4 = import("app.model.Hero").new()
						local var_17_5 = iter_17_1

						if arg_17_1.is_robot == true then
							var_17_5.table_id = iter_17_1.partner_id
							var_17_5.partner_id = iter_17_0
						end

						if type(var_15_7.equips) == "string" then
							var_17_5.equips = xyd.splitToNumber(var_15_7.equips, "|")
						end

						var_17_4:populate(var_17_5)

						if arg_17_1.conquer_lev and arg_17_1.conquer_lev > 0 then
							var_17_4:setConquerSchoolLev(arg_17_1.conquer_lev, arg_17_1.conquer_loop_id)
						end

						table.insert(var_17_3, var_17_4)

						var_17_1 = var_17_1 + var_17_4:getZhandouli()
					end
				end

				if arg_17_1.pet then
					local var_17_6 = import("app.model.Pet").new()

					var_17_6:populate(arg_17_1.pet)

					local var_17_7 = var_17_1 + var_17_6:getZhandouli()
				end

				local var_17_8 = arg_15_1.hurt
				local var_17_9, var_17_10 = math.modf(var_17_8)

				if var_17_10 ~= 0 then
					local var_17_11 = 0.03333333333333333 / var_17_10
					local var_17_12

					if var_17_11 % 1 >= 0.5 then
						var_17_12 = math.ceil(var_17_11)
					else
						var_17_12 = math.floor(var_17_11)
					end

					arg_15_0.huang_time = var_17_12
				end

				local var_17_13 = {
					showLevel = true,
					avatar_id = arg_15_1.avatar_id,
					avatar_frame_id = arg_15_1.avatar_frame_id,
					level = arg_15_1.level,
					hurt = math.floor(arg_15_1.total_hurt or arg_15_1.hurt),
					p_name = arg_15_1.player_name,
					rank = arg_15_2,
					guild_name = arg_15_1.guild_name,
					rank_type = arg_15_0.rank_type,
					conquer_lev = arg_15_1.conquer_lev,
					conquer_loop_id = arg_15_1.conquer_loop_id,
					heroes = var_17_3,
					pet = arg_17_1.pet,
					huang_time = arg_15_0.huang_time
				}

				if arg_15_0.rank_type == xyd.RankType.WB then
					var_17_13.boss_id = arg_15_0.mainRankList.boss_id
				else
					var_17_13.rank = arg_15_1.rank or arg_15_2
				end

				xyd.WindowManager.get():openWindow("world_boss_rank_info", var_17_13)
			end
		end)
	elseif arg_15_0.rank_type == xyd.RankType.WB or arg_15_0.curSubType == xyd.SubRankType.PARADISE_TEAM_RANK then
		local var_15_10 = {
			avatar_id = arg_15_1.avatar_id,
			avatar_frame_id = arg_15_1.avatar_frame_id,
			level = arg_15_1.level,
			hurt = math.floor(arg_15_1.total_hurt or arg_15_1.hurt),
			p_name = arg_15_1.player_name,
			rank = arg_15_2,
			guild_name = arg_15_1.guild_name,
			rank_type = arg_15_0.rank_type
		}

		if arg_15_0.rank_type == xyd.RankType.WB then
			var_15_10.boss_id = arg_15_0.mainRankList.boss_id
		else
			var_15_10.rank = arg_15_1.rank or arg_15_2
		end

		xyd.WindowManager.get():openWindow("world_boss_rank_info_team", var_15_10)
	elseif arg_15_0.curSubType == xyd.SubRankType.PARADISE_GUILD_DAMAGE or arg_15_0.curSubType == xyd.SubRankType.GUILD_RANK_INFO or arg_15_0.curSubType == xyd.SubRankType.TOTAL_GUILD_RANK then
		local var_15_11 = {
			member_nums = arg_15_1.member_num,
			guild_id = arg_15_1.guild_id,
			guild_des = arg_15_1.des,
			guild_name = arg_15_1.name,
			guild_leader_name = arg_15_1.guild_leader_name,
			guild_icon = arg_15_1.icon,
			min_lev = arg_15_1.min_allow_level
		}

		xyd.WindowManager.get():openWindow("team_icon", var_15_11)
	elseif arg_15_0.curSubType == xyd.SubRankType.SELF_FIGHTING_RANK then
		local var_15_12 = {
			avatar_id = arg_15_1.avatar_id,
			avatar_frame_id = arg_15_1.avatar_frame_id,
			level = arg_15_1.level,
			alive_num = arg_15_1.alive_num,
			kill_num = arg_15_1.kill_num,
			name = arg_15_1.player_name,
			coin_num = arg_15_1.guild_war_coin,
			rank = arg_15_2
		}

		xyd.WindowManager.get():openWindow("guild_war_rank_info", var_15_12)
	elseif arg_15_0.curSubType == xyd.SubRankType.REGION_ARENA_RANK then
		local var_15_13 = {
			level = arg_15_1.level,
			totalFight = arg_15_1.total_fight,
			winTimes = arg_15_1.win_times,
			regionName = arg_15_1.region_name,
			region = arg_15_1.region,
			point = arg_15_1.point,
			guildName = arg_15_1.guild_name,
			avatarID = arg_15_1.avatar_id,
			avatarFrameID = arg_15_1.avatar_frame_id,
			playerName = arg_15_1.player_name,
			star = arg_15_1.star,
			conquer_lev = arg_15_1.conquer_lev,
			conquer_loop_id = arg_15_1.conquer_loop_id
		}

		xyd.WindowManager.get():openWindow("region_arena_rank_info", var_15_13)
	elseif arg_15_0.curSubType == xyd.SubRankType.TOTAL_FORCE_INFO or arg_15_0.curSubType == xyd.SubRankType.TEAM_FORCE_INFO or arg_15_0.curSubType == xyd.SubRankType.HERO_STAR_INFO or arg_15_0.curSubType == xyd.SubRankType.SKYCITY_SUB_RANK or arg_15_0.curSubType == xyd.SubRankType.SKYCITY_SUB_RANK_2 or arg_15_0.curSubType == xyd.SubRankType.SEND_HERO_NUM_RANK or arg_15_0.curSubType == xyd.SubRankType.PRACTICE_NUM or arg_15_0.curSubType == xyd.SubRankType.AWAKEN_NUM or arg_15_0.curSubType == xyd.SubRankType.AWAKEN_SECOND_NUM or arg_15_0.curSubType == xyd.SubRankType.PARADISE_COMMUNITY_RANK then
		local var_15_14 = {
			playerName = arg_15_1.player_name,
			level = arg_15_1.level or arg_15_1.lev,
			guildID = arg_15_1.guild_id,
			guildName = arg_15_1.guild_name,
			avatarID = arg_15_1.avatar_id,
			avatarFrameID = arg_15_1.avatar_frame_id,
			conquer_lev = arg_15_1.conquer_lev,
			conquer_loop_id = arg_15_1.conquer_loop_id
		}

		xyd.WindowManager.get():openWindow("player_guild_info", var_15_14)
	elseif arg_15_0.curSubType == xyd.SubRankType.DORM_COMFORT_RANK then
		local var_15_15 = {
			host_id = arg_15_1.player_id,
			host_info = arg_15_1
		}

		var_15_15.isrank = true

		arg_15_0.dorm:getHouseList(var_15_15, function(arg_18_0, arg_18_1)
			if arg_18_0 == xyd.error.OK then
				xyd.WindowManager.get():closeWindow(arg_15_0)
			end
		end)
	elseif arg_15_0.curSubType == xyd.SubRankType.ACHIEVEMENT_POINT then
		local var_15_16 = {
			level = arg_15_1.level,
			regionName = arg_15_1.region_name,
			region = arg_15_1.region_id,
			avatarID = arg_15_1.avatar_id,
			avatarFrameID = arg_15_1.avatar_frame_id,
			playerName = arg_15_1.player_name,
			rank = arg_15_2,
			conquer_lev = arg_15_1.conquer_lev,
			achievementLevel = xyd.tables.achievementLevel:getLevByPoint(arg_15_1.point)
		}

		xyd.WindowManager.get():openWindow("achievement_rank_info", var_15_16)
	end
end

function var_0_0.initCellRankNum(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = arg_19_1:getChildByName("rank_item_bg_1")
	local var_19_1 = arg_19_1:getChildByName("rank_item_bg_2")
	local var_19_2 = arg_19_1:getChildByName("rank_item_bg_3")
	local var_19_3 = arg_19_1:getChildByName("rank_val_1")
	local var_19_4 = arg_19_1:getChildByName("rank_val_2")
	local var_19_5 = arg_19_1:getChildByName("rank_val_3")

	if arg_19_3 == 1 or arg_19_2.rank == 1 then
		var_19_3:setVisible(true)
		var_19_4:setVisible(false)
		var_19_5:setVisible(false)
		var_19_0:setVisible(true)
		var_19_1:setVisible(false)
		var_19_2:setVisible(false)
	elseif arg_19_3 == 2 or arg_19_2.rank == 2 then
		var_19_3:setVisible(false)
		var_19_4:setVisible(true)
		var_19_5:setVisible(false)
		var_19_0:setVisible(false)
		var_19_1:setVisible(true)
		var_19_2:setVisible(false)
	elseif arg_19_3 == 3 or arg_19_2.rank == 3 then
		var_19_3:setVisible(false)
		var_19_4:setVisible(false)
		var_19_5:setVisible(true)
		var_19_0:setVisible(false)
		var_19_1:setVisible(false)
		var_19_2:setVisible(true)
	else
		var_19_3:setVisible(false)
		var_19_4:setVisible(false)
		var_19_5:setVisible(false)
		var_19_0:setVisible(false)
		var_19_1:setVisible(false)
		var_19_2:setVisible(false)

		local var_19_6 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		if arg_19_2.rank and arg_19_2.rank > 0 then
			var_19_6:setString(arg_19_2.rank)
		else
			var_19_6:setString(arg_19_3)
		end

		var_19_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_19_6:setPosition(arg_19_1:getChildByName("rank_val_1"):getPosition())
		var_19_6:addTo(arg_19_1)
	end
end

function var_0_0.initInfoText(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	local var_20_0 = ""
	local var_20_1 = false
	local var_20_2

	if arg_20_0.rank_type == xyd.RankType.Power or arg_20_0.rank_type == xyd.RankType.Awake then
		var_20_2 = arg_20_2.info_val
	elseif arg_20_0.rank_type == xyd.RankType.Guild then
		var_20_2 = arg_20_2.three_huoyue
	elseif arg_20_0.rank_type == xyd.RankType.WB or arg_20_0.rank_type == xyd.RankType.NB then
		var_20_2 = math.floor(arg_20_2.total_hurt)

		local var_20_3 = xyd.AssetLoader.get():loadLabel({
			size = 40,
			color = cc.c3b(2, 173, 94),
			text = "S" .. math.floor(arg_20_2.player_id / 100000)
		})

		var_20_3:addTo(arg_20_1)
		var_20_3:setPosition(700, 30)
	elseif arg_20_0.rank_type == xyd.RankType.PetCampaign then
		var_20_2 = arg_20_2.max_floor
	elseif arg_20_0.curSubType == xyd.SubRankType.SEND_HERO_NUM_RANK then
		var_20_2 = arg_20_2.hero_num
	elseif arg_20_0.curSubType == xyd.SubRankType.TEAM_FORCE_INFO then
		var_20_2 = arg_20_2.force
	elseif arg_20_0.curSubType == xyd.SubRankType.TOTAL_TEAM_POWER then
		var_20_2 = arg_20_2.force
	elseif arg_20_0.curSubType == xyd.SubRankType.COMPETITION_SCORE_DES then
		var_20_2 = arg_20_2.win_times
	elseif arg_20_0.curSubType == xyd.SubRankType.SELF_FIGHTING_RANK then
		var_20_1 = true
		var_20_0 = string.format(arg_20_3, arg_20_2.kill_num, arg_20_2.alive_num)
	elseif arg_20_0.curSubType == xyd.SubRankType.ACHIEVEMENT_POINT then
		var_20_2 = arg_20_2.point
	elseif arg_20_0.curSubType == xyd.SubRankType.PARADISE_PERSON_RANK or arg_20_0.curSubType == xyd.SubRankType.PARADISE_COMMUNITY_RANK or arg_20_0.curSubType == xyd.SubRankType.PARADISE_TEAM_RANK then
		var_20_2 = arg_20_2.hurt

		local var_20_4, var_20_5 = math.modf(var_20_2)

		if var_20_5 ~= 0 then
			local var_20_6 = 0.03333333333333333 / var_20_5
			local var_20_7

			if var_20_6 % 1 >= 0.5 then
				var_20_7 = math.ceil(var_20_6)
			else
				var_20_7 = math.floor(var_20_6)
			end

			local var_20_8 = string.format(var_0_4:translation("RANK_TXT_PARADISE_TIME"), var_20_7)
			local var_20_9 = {
				size = 24,
				color = cc.c3b(110, 77, 53),
				align = cc.ui.TEXT_ALIGN_LEFT
			}
			local var_20_10 = xyd.AssetLoader.get():loadLabel(var_20_9)

			var_20_10:setString(var_20_8)
			var_20_10:setAnchorPoint(cc.p(0, 0))
			var_20_10:addTo(arg_20_1)
			var_20_10:setPosition(685, 28)
		end
	elseif arg_20_0.curSubType == xyd.SubRankType.PARADISE_GUILD_DAMAGE then
		var_20_2 = arg_20_2.hurt
	elseif arg_20_0.curSubType == xyd.SubRankType.REGION_CASUAL_RANK then
		var_20_2 = arg_20_2.point
	elseif arg_20_0.rank_type == xyd.RankType.Occult then
		var_20_2 = arg_20_2.point
	elseif arg_20_0.curSubType == xyd.SubRankType.DORM_COMFORT_RANK then
		var_20_2 = arg_20_2.comfort
	elseif arg_20_0.curSubType == xyd.SubRankType.DEV_PARTNER_NUM or arg_20_0.curSubType == xyd.SubRankType.DEV_SKIN_NUM then
		var_20_2 = arg_20_2.score
	end

	if not var_20_1 and var_20_2 then
		var_20_0 = string.format(arg_20_3, var_20_2)
	end

	arg_20_1:getChildByName("text_info"):setString(var_20_0)
end

function var_0_0.initAvatarInfo(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_0.rank_type == xyd.RankType.Guild or arg_21_0.rank_type == xyd.RankType.TEAM_WIN or arg_21_0.curSubType == xyd.SubRankType.PARADISE_GUILD_DAMAGE then
		arg_21_1:getChildByName("text_level"):setVisible(false)
		arg_21_1:getChildByName("text_player_name"):setString(arg_21_2.name)
		arg_21_1:getChildByName("avatar"):setPosition(arg_21_1:getChildByName("avatar"):getX() - 15, arg_21_1:getChildByName("avatar"):getY())

		if not arg_21_2.icon then
			arg_21_2.icon = 20010001
		end

		arg_21_0:setGuildAvatar(arg_21_1:getChildByName("avatar"), arg_21_2.icon)
	else
		if arg_21_2.conquer_lev and arg_21_2.conquer_lev > 0 then
			local var_21_0 = {
				x = -2,
				y = 2
			}

			xyd.setConquerLev(arg_21_2.conquer_lev, arg_21_1:getChildByName("text_level"), arg_21_1:getChildByName("dengjiquan"), var_21_0, nil, nil, nil, arg_21_2.conquer_loop_id)
		else
			arg_21_1:getChildByName("text_level"):setString(arg_21_2.level or arg_21_2.lev)
		end

		arg_21_1:getChildByName("text_player_name"):setString(arg_21_2.player_name or arg_21_2.name)
		arg_21_1:getChildByName("avatar"):setScale(0.9333333333333333)

		local function var_21_1(arg_22_0)
			if arg_22_0.name == "began" then
				arg_21_0.isOpenPlayerInfoWindow = false

				return true
			elseif arg_22_0.name == "ended" and not arg_21_0.scrollViewMoved_ then
				arg_21_0.isOpenPlayerInfoWindow = true

				xyd.openPersonDisplayWindow(arg_21_2)
			end
		end

		xyd.setPlayerAvatar(arg_21_1:getChildByName("avatar"), {
			showLevel = false,
			avatar_id = arg_21_2.avatar_id,
			avatar_frame_id = arg_21_2.avatar_frame_id,
			callback = var_21_1
		})
		xyd.setPlayerTitle(arg_21_1:getChildByName("title_container"), arg_21_2.title_info)
	end
end

function var_0_0.addSpecialIcon(arg_23_0, arg_23_1, arg_23_2)
	if arg_23_0.curSubType == xyd.SubRankType.LEGEND_RANK_INFO and arg_23_2.rank_level then
		local var_23_0 = xyd.AssetLoader.get():loadSprite("windows/rank/legend_rank" .. arg_23_2.rank_level .. ".png")

		var_23_0:addTo(arg_23_1)
		var_23_0:setPosition(700, 40)
	elseif arg_23_2.dev_time then
		local var_23_1 = {
			size = 28,
			color = cc.c3b(0, 0, 0)
		}
		local var_23_2 = xyd.AssetLoader.get():loadLabel(var_23_1)

		var_23_2:setString(os.date("%Y/%m/%d %H:%M", arg_23_2.dev_time))
		var_23_2:addTo(arg_23_1)
		var_23_2:setPosition(700, 40)
	end
end

function var_0_0.setGuildAvatar(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	local var_24_0 = "images/icon/skill_icon/" .. arg_24_2 .. "_icon.png" or "images/icon/skill_icon/" .. var_0_7 .. "_icon.png"
	local var_24_1 = xyd.SpriteLoader.new(var_24_0, nil, extra_params, xyd.DefaultImageType.SKILL_ICON)
	local var_24_2 = arg_24_1:getContentSize()
	local var_24_3 = arg_24_1:getContentSize().width
	local var_24_4 = arg_24_1:getContentSize().height
	local var_24_5 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg.png")

	var_24_5:setScale(0.8)
	var_24_5:setAnchorPoint(cc.p(0, 0))
	var_24_5:setPosition(-17, -20)
	arg_24_1:addChild(var_24_5)

	local var_24_6 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_24_6:setPosition(var_24_3 / 2, var_24_4 / 2)
	var_24_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_24_6:setScale(var_24_4 / var_24_6:getHeight())

	local var_24_7 = cc.ClippingNode:create()

	var_24_7:setStencil(var_24_6)
	var_24_7:setInverted(true)
	var_24_7:setAlphaThreshold(0)
	var_24_7:addChild(var_24_1)
	var_24_1:align(display.CENTER, var_24_2.width / 2, var_24_2.height / 2)
	var_24_1:scale(var_24_2.width / var_24_1:getWidth())
	arg_24_1:addChild(var_24_7)

	local var_24_8 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_24_9 = clone(var_24_8:getContentSize())
	local var_24_10 = display.newNode()

	var_24_10:setName("view")
	var_24_10:setContentSize(var_24_9)
	var_24_10:setAnchorPoint(cc.p(0, 0))
	var_24_10:setPosition(cc.p(0, 0))
	var_24_10:setScale(var_24_2.width / var_24_9.width, var_24_2.height / var_24_9.height)
	arg_24_1:addChild(var_24_10)

	local var_24_11 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")

	var_24_11:setScale(0.8)
	var_24_11:setAnchorPoint(cc.p(0, 0))
	var_24_11:setPosition(-17, -20)
	arg_24_1:addChild(var_24_11)
	arg_24_1:setScale(0.8)

	if arg_24_3 then
		arg_24_1:setPositionY(arg_24_1:getPositionY() + 10)
	end

	arg_24_1:setPositionX(arg_24_1:getPositionX() + 20)
end

function var_0_0.addLeftCategory(arg_25_0, arg_25_1, arg_25_2)
	local var_25_0 = arg_25_0.leftList_:newItem()
	local var_25_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/rank_type_item.csb")
	local var_25_2 = var_25_1:getChildByName("container")

	if arg_25_0.rank_type == arg_25_1.type and arg_25_0.has_click_left == false then
		arg_25_0.skipBtn_ = loadingContainer

		var_25_2:getChildByName("left_btn"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_25_2:getChildByName("left_btn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	local var_25_3 = var_25_2:getContentSize()

	var_25_1:setPosition(cc.p(0, 0))
	var_25_1:setContentSize(var_25_3)
	var_25_1:setTouchEnabled(true)
	var_25_1:setTouchSwallowEnabled(false)
	var_25_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
		if arg_26_0.name == "began" then
			return true
		elseif arg_26_0.name == "ended" then
			arg_25_0.skipBtn_ = loadingContainer

			if not arg_25_0.scrollViewMoved_1 then
				if arg_25_0.rank_type == arg_25_1.type then
					if arg_25_0.has_click_left == false then
						arg_25_0.has_click_left = true
					else
						arg_25_0.has_click_left = false
					end

					arg_25_0.click_same_left = true
					arg_25_0.leftSelectedIndex = arg_25_2
					arg_25_0.rank_type = arg_25_1.type
					arg_25_0.item = var_25_0

					arg_25_0:updateLeftContainer()
				else
					local var_26_0 = arg_25_0:getSubIndex(false, arg_25_1.type)

					if var_26_0 == -1 then
						var_26_0 = arg_25_1.subList[1].sub_type
					end

					arg_25_0.rankList:loadRankList({
						var_26_0
					}, false, function(arg_27_0, arg_27_1)
						if arg_27_0 == xyd.error.OK then
							arg_25_0.has_click_left = false
							arg_25_0.click_same_left = false
							arg_25_0.rank_type = arg_25_1.type

							arg_25_0:updateLeftContainer()
						end
					end)
				end
			end

			return true
		end
	end)
	var_25_0:addContent(var_25_1)
	var_25_0:setItemSize(var_25_3.width, var_25_3.height + 20)
	arg_25_0.leftList_:addItem(var_25_0)

	if arg_25_0.firstIn == true then
		arg_25_0.idx = arg_25_0.idx + 1

		local var_25_4 = cc.p(var_25_2:getPosition())

		var_25_2:pos(var_25_4.x - 200, var_25_4.y)
		var_25_2:runAction(cc.Sequence:create({
			cc.DelayTime:create(0.1 * (arg_25_0.idx - 1)),
			cc.Spawn:create({
				cc.MoveBy:create(0.2, cc.p(200, 0)),
				cc.FadeIn:create(0.2)
			})
		}))
	end

	arg_25_0:initLeftTitle(var_25_2, arg_25_2)

	if arg_25_1.type == arg_25_0.rank_type then
		arg_25_0.leftSelectedIndex = arg_25_2

		if not arg_25_1.subList or #arg_25_1.subList == 0 then
			arg_25_0.mainRankList = {}
			arg_25_0.mainRankList.rankList = {}

			arg_25_0:updateMainContainer()
		end

		local var_25_5 = arg_25_1.subList

		if var_25_5 and next(var_25_5) then
			local var_25_6 = {}

			local function var_25_7(arg_28_0)
				local var_28_0 = 1

				if arg_28_0 ~= -1 then
					for iter_28_0 = 1, #var_25_5 do
						if var_25_5[iter_28_0].sub_type == arg_28_0 then
							var_28_0 = iter_28_0

							break
						end
					end
				end

				for iter_28_1, iter_28_2 in pairs(var_25_6) do
					if iter_28_1 == var_28_0 then
						iter_28_2:getChildByName("bg1"):setVisible(false)
						iter_28_2:getChildByName("bg2"):setVisible(true)
						iter_28_2:getChildByName("left_click_not"):setVisible(false)
						iter_28_2:getChildByName("left_click_on"):setVisible(true)
					else
						iter_28_2:getChildByName("bg1"):setVisible(true)
						iter_28_2:getChildByName("bg2"):setVisible(false)
						iter_28_2:getChildByName("left_click_not"):setVisible(true)
						iter_28_2:getChildByName("left_click_on"):setVisible(false)
					end
				end

				if var_25_5[var_28_0] then
					arg_25_0.curSubType = var_25_5[var_28_0].sub_type

					local var_28_1 = arg_25_0.rankList:getRankInfoByType(arg_25_0.curSubType)

					arg_25_0.mainRankList = var_28_1
					arg_25_0.mainRankTxt = var_25_5[var_28_0].title

					arg_25_0:updateMainContainer()
				end
			end

			local var_25_8 = 0

			for iter_25_0, iter_25_1 in pairs(var_25_5) do
				var_25_8 = var_25_8 + 1

				local var_25_9 = arg_25_0.leftList_:newItem()
				local var_25_10 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/rank_type_sub_item.csb")
				local var_25_11 = var_25_10:getChildByName("container")
				local var_25_12 = var_25_11:getContentSize()

				var_25_11:setPosition(cc.p(-5, 0))
				var_25_10:setContentSize(var_25_12)
				var_25_9:setLocalZOrder(-100 - var_25_8)
				var_25_11:getChildByName("text_subtype"):setString(iter_25_1.title)
				table.insert(var_25_6, var_25_11)
				var_25_10:setTouchEnabled(true)
				var_25_10:setTouchSwallowEnabled(true)
				var_25_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(iter_25_0, function(arg_29_0, arg_29_1)
					if arg_29_1.name == "began" then
						return true
					elseif arg_29_1.name == "ended" and not arg_25_0.scrollViewMoved_1 then
						arg_25_0.rankList:loadRankList({
							iter_25_1.sub_type
						}, false, function(arg_30_0, arg_30_1)
							if arg_30_0 == xyd.error.OK then
								var_25_7(iter_25_1.sub_type)

								arg_25_0.index_ = iter_25_1.sub_type
							end
						end)

						return true
					end
				end))
				var_25_9:addContent(var_25_10)
				var_25_9:setItemSize(var_25_12.width, var_25_12.height + 10)

				if arg_25_0.has_click_left == false then
					arg_25_0.leftList_:addItem(var_25_9)
				end
			end

			arg_25_0.index_ = arg_25_0:getSubIndex(arg_25_0.click_same_left, arg_25_0.rank_type)

			var_25_7(arg_25_0.index_)
		end
	end

	table.insert(arg_25_0.subTypeLists, subListCells)
end

function var_0_0.initLeftTitle(arg_31_0, arg_31_1, arg_31_2)
	arg_31_1:getChildByName("rank_txt"):setString(var_0_4:translation("RANK_LEFT_TITLE_" .. arg_31_2))
end

function var_0_0.getSubIndex(arg_32_0, arg_32_1, arg_32_2)
	local var_32_0 = arg_32_0.index_

	if arg_32_1 == false then
		if arg_32_0.enter_rank_type == xyd.RankType.PK and arg_32_0.sub_type == xyd.SubRankType.ARENA_RANK then
			if arg_32_2 == xyd.RankType.Power then
				var_32_0 = xyd.SubRankType.TEAM_FORCE_INFO
			else
				var_32_0 = -1
			end
		elseif arg_32_0.enter_rank_type == xyd.RankType.PK and arg_32_0.sub_type == xyd.SubRankType.LEGEND_RANK_INFO then
			if arg_32_2 == xyd.RankType.PK then
				var_32_0 = xyd.SubRankType.LEGEND_RANK_INFO
			else
				var_32_0 = -1
			end
		elseif arg_32_0.enter_rank_type == xyd.RankType.PK and arg_32_0.sub_type == xyd.SubRankType.PEAK_RANK_INFO then
			if arg_32_2 == xyd.RankType.PK then
				var_32_0 = xyd.SubRankType.PEAK_RANK_INFO
			else
				var_32_0 = -1
			end
		elseif arg_32_0.enter_rank_type == xyd.RankType.PK and (arg_32_0.sub_type == xyd.SubRankType.REGION_ARENA_RANK or arg_32_0.sub_type == xyd.SubRankType.REGION_CASUAL_RANK) then
			if arg_32_2 == xyd.RankType.PK then
				var_32_0 = arg_32_0.sub_type
			else
				var_32_0 = -1
			end
		else
			var_32_0 = -1
		end
	end

	return var_32_0
end

function var_0_0.updateListView(arg_33_0)
	arg_33_0:updateLeftContainer()
end

function var_0_0.updateLeftContainer(arg_34_0)
	arg_34_0.leftList_:removeAllItems()

	local var_34_0 = table.keys(arg_34_0.rankData)

	table.sort(var_34_0, function(arg_35_0, arg_35_1)
		return arg_35_0 < arg_35_1
	end)

	for iter_34_0 = 1, #var_34_0 do
		if arg_34_0.rankData[var_34_0[iter_34_0]] then
			arg_34_0:addLeftCategory(arg_34_0.rankData[var_34_0[iter_34_0]], var_34_0[iter_34_0])
		end
	end

	arg_34_0.firstIn = false

	arg_34_0.leftList_:reload()

	local var_34_1 = arg_34_0.leftList_:getScrollNode()
	local var_34_2 = xyd.WindowManager.get():getWindow("guild_war")

	if var_34_1 and arg_34_0.leftSelectedIndex > 3 and not var_34_2 then
		local var_34_3 = var_34_1:getPositionY() + (arg_34_0.leftSelectedIndex - 3) * 80

		var_34_1:setPositionY(var_34_3)
		arg_34_0.leftList_:elasticScroll()
	end
end

function var_0_0.updateMainContainer(arg_36_0)
	arg_36_0.mainList_:reload()
	arg_36_0.bottomList_:reload()

	if arg_36_0.mainRankTxt then
		arg_36_0:nodeByName("refresh_bg"):setVisible(true)
		arg_36_0:nodeByName("main_rank_txt"):setString(arg_36_0.mainRankTxt)
	end
end

function var_0_0.scrollListener(arg_37_0, arg_37_1)
	if arg_37_1.name == "began" then
		arg_37_0.scrollViewMoved_ = false
		arg_37_0.prevY_ = arg_37_1.y
	elseif arg_37_1.name == "moved" and 10 <= math.abs(arg_37_1.y - arg_37_0.prevY_) then
		arg_37_0.scrollViewMoved_ = true
	end
end

function var_0_0.scrollListener1(arg_38_0, arg_38_1)
	if arg_38_1.name == "began" then
		arg_38_0.scrollViewMoved_1 = false
		arg_38_0.prevY_ = arg_38_1.y
	elseif arg_38_1.name == "moved" then
		if 10 <= math.abs(arg_38_1.y - arg_38_0.prevY_) then
			arg_38_0.scrollViewMoved_1 = true
		end
	elseif arg_38_1.name == "ended" then
		arg_38_0.scrollViewMoved_1 = false
	end
end

function var_0_0.didClose(arg_39_0)
	arg_39_0.rankList:loadRankList({}, true)
	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {}
	})
end

return var_0_0
