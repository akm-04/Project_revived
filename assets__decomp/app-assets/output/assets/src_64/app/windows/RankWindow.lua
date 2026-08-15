local var_0_0 = class("RankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.WindowName.rankWnd
local var_0_2 = 10
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.model.Pet")
local var_0_6 = xyd.tables.misc.teamIcons[1]

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.rank_type = arg_2_1.rank_type
	arg_2_0.sub_type = arg_2_1.sub_type
	arg_2_0.ranks = {}
	arg_2_0.leftSelected = -1
	arg_2_0.subTypeLists = {}
	arg_2_0.rankData = arg_2_1.rankData
	arg_2_0.enter_rank_type = arg_2_1.rank_type
	arg_2_0.leftSelectedIndex = 0
	arg_2_0.has_click_left = false
	arg_2_0.click_same_left = false
	arg_2_0.index_ = 1
	arg_2_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
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
	}):addTo(arg_3_0.left_container):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
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
	arg_3_0.return_btn = arg_3_0:nodeByName("return_button")

	arg_3_0.return_btn:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow("rank")
		end
	end)
	arg_3_0.mainList_:setDelegate(handler(arg_3_0, arg_3_0.rankDelegate))
	arg_3_0:updateListView()
end

function var_0_0.rankDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0.mainRankList.rankList
	local var_5_1 = arg_5_0.mainRankList.myRank
	local var_5_2 = arg_5_0.mainRankList.info_text
	local var_5_3 = arg_5_0.mainRankList.title
	local var_5_4 = math.min(50, #var_5_0)

	if var_5_1 then
		var_5_4 = var_5_4 + 1
	end

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return var_5_4
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		if var_5_4 < arg_5_3 then
			return nil
		end

		if arg_5_3 == 1 and var_5_1 then
			return arg_5_0:addMyRank(var_5_1, var_5_2)
		else
			local var_5_5

			if var_5_1 then
				var_5_5 = arg_5_3 - 1
			else
				var_5_5 = arg_5_3
			end

			local var_5_6 = var_5_0[var_5_5]

			return arg_5_0:addRankItem(var_5_6, var_5_2, var_5_5, var_5_3)
		end
	end
end

function var_0_0.addMyRank(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.mainList_:dequeueItem()

	if not var_6_0 then
		var_6_0 = arg_6_0.mainList_:newItem()
	else
		var_6_0:removeAllChildren(true)
	end

	local var_6_1 = display.newNode()
	local var_6_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/my_rank_item.csb")
	local var_6_3 = var_6_2:getChildByName("container")

	var_6_3:getChildByName("text_yesterday"):setString(var_0_3:translation("MY_RANK_COMPARE"))
	xyd.setPlayerTitle(var_6_3:getChildByName("title_container"), arg_6_0.selfPlayer.titleInfo)

	local var_6_4 = var_6_3:getContentSize()

	if arg_6_2 == "BOSS_RANK_INFO" then
		var_6_2:setTouchEnabled(true)
		var_6_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				var_6_3:setScale(0.99)

				return true
			elseif arg_7_0.name == "moved" then
				var_6_3:setScale(1)

				return true
			elseif arg_7_0.name == "ended" then
				var_6_3:setScale(1)

				local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
				local var_7_1 = {
					avatar_id = arg_6_0.selfPlayer:getMyCurrentAvatarID(),
					avatar_frame_id = arg_6_0.selfPlayer.avatarFrame,
					level = arg_6_0.selfPlayer.lev,
					hurt = arg_6_1.score,
					p_name = arg_6_0.selfPlayer.playerName,
					rank = arg_6_1.rank,
					boss_id = arg_6_0.mainRankList.boss_id,
					guild_name = var_7_0.guild_name
				}

				xyd.WindowManager.get():openWindow("world_boss_rank_info", var_7_1)
			end
		end)
	end

	if arg_6_1.rank then
		var_6_3:getChildByName("rank_num"):setString(arg_6_1.rank)
		var_6_3:getChildByName("rank_num"):enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
	end

	if arg_6_1.name then
		var_6_3:getChildByName("text_player_name"):setString(arg_6_1.name)
		var_6_3:getChildByName("avatar"):setPosition(var_6_3:getChildByName("avatar"):getX() - 15, var_6_3:getChildByName("avatar"):getY() - 2)
		arg_6_0:setGuildAvatar(var_6_3:getChildByName("avatar"), arg_6_1.icon, true)
		var_6_3:getChildByName("text_level"):setString("")
	else
		var_6_3:getChildByName("text_player_name"):setString(arg_6_0.selfPlayer.playerName)
		xyd.setPlayerAvatar(var_6_3:getChildByName("avatar"), {
			avatar_id = arg_6_0.selfPlayer:getMyCurrentAvatarID(),
			avatar_frame_id = arg_6_0.selfPlayer.avatarFrame
		})

		if arg_6_0.selfPlayer.conquerLev and arg_6_0.selfPlayer.conquerLev > 0 then
			xyd.setConquerLev(arg_6_0.selfPlayer.conquerLev, var_6_3:getChildByName("text_level"), var_6_3:getChildByName("dengjiquan"))
		else
			var_6_3:getChildByName("text_level"):setString(arg_6_0.selfPlayer.lev)
		end
	end

	if arg_6_1.score then
		var_6_3:getChildByName("text_rank"):setVisible(true)
		var_6_3:getChildByName("text_rank"):setString(var_0_3:translation(arg_6_2) .. ":" .. arg_6_1.score)
	elseif arg_6_1.point then
		var_6_3:getChildByName("text_rank"):setVisible(true)
		var_6_3:getChildByName("text_rank"):setString(string.format(var_0_3:translation(arg_6_2), arg_6_1.point))
	elseif arg_6_1.alive_num and arg_6_1.kill_num then
		var_6_3:getChildByName("text_rank"):setString(string.format(var_0_3:translation(arg_6_2), arg_6_1.kill_num, arg_6_1.alive_num))
	elseif arg_6_1.damage then
		var_6_3:getChildByName("text_rank"):setString(var_0_3:translation(arg_6_2) .. arg_6_1.damage)
	elseif arg_6_1.guildDamage then
		var_6_3:getChildByName("text_rank"):setString(var_0_3:translation(arg_6_2) .. arg_6_1.guildDamage)
	elseif arg_6_1.buff_num then
		var_6_3:getChildByName("text_rank"):setString(var_0_3:translation(arg_6_2) .. arg_6_1.buff_num)
	else
		var_6_3:getChildByName("text_rank"):setVisible(false)
	end

	local var_6_5 = tonumber(arg_6_1.diff) or 0

	if var_6_5 == 0 then
		var_6_3:getChildByName("text_yesterday"):setVisible(false)
		var_6_3:getChildByName("down_arrow"):setVisible(false)
		var_6_3:getChildByName("up_arrow"):setVisible(false)
		var_6_3:getChildByName("text_change"):setVisible(false)
	elseif var_6_5 < 0 then
		var_6_3:getChildByName("text_yesterday"):setVisible(true)
		var_6_3:getChildByName("down_arrow"):setVisible(false)
		var_6_3:getChildByName("up_arrow"):setVisible(true)
		var_6_3:getChildByName("text_change"):setString(-var_6_5)
	else
		var_6_3:getChildByName("text_yesterday"):setVisible(true)
		var_6_3:getChildByName("down_arrow"):setVisible(true)
		var_6_3:getChildByName("up_arrow"):setVisible(false)
		var_6_3:getChildByName("text_change"):setString(var_6_5)
	end

	var_6_2:setPosition(cc.p(0, 0))
	var_6_2:setContentSize(var_6_4.width, var_6_4.height)
	var_6_1:addChild(var_6_2)
	var_6_1:setContentSize(cc.size(arg_6_0.mainList_.viewRect_.width, 130))
	var_6_0:addContent(var_6_1)
	var_6_0:setItemSize(arg_6_0.mainList_.viewRect_.width, var_6_1:getContentSize().height)

	return var_6_0
end

function var_0_0.showTeamInfo(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA)

	var_8_0:getEnemyTeam(arg_8_1.player_id, function(arg_9_0)
		xyd.WindowManager.get():openWindow("peak_team_info", {
			rank = arg_8_2,
			playerInfo = arg_8_1,
			teams = var_8_0:formatTeams(arg_9_0)
		})
	end)
end

function var_0_0.addRankItem(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = arg_10_0.mainList_:dequeueItem()

	if not var_10_0 then
		var_10_0 = arg_10_0.mainList_:newItem()
	else
		var_10_0:removeAllChildren(true)
	end

	local var_10_1 = display.newNode()
	local var_10_2 = "windows/arena/rank/rank_item.csb"
	local var_10_3 = xyd.AssetLoader.get():loadNodeFromJson(var_10_2)
	local var_10_4 = var_10_3:getChildByName("container")

	var_10_4:setPositionX(var_10_4:getPositionX() + 5)
	var_10_3:setTouchEnabled(true)
	var_10_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			var_10_4:getChildByName("rank_item_bg"):setVisible(false)

			arg_10_0.isOpenPlayerInfoWindow = false

			return true
		elseif arg_11_0.name == "moved" then
			return true
		elseif arg_11_0.name == "ended" then
			var_10_4:getChildByName("rank_item_bg"):setVisible(true)

			if arg_10_0.isOpenPlayerInfoWindow then
				arg_10_0.isOpenPlayerInfoWindow = false

				return
			end

			if not arg_10_0.scrollViewMoved_ then
				if arg_10_2 == "ARENA_RANK_INFO" then
					local var_11_0 = {
						other_player_id = arg_10_1.player_id
					}

					xyd.Backend.get():request(xyd.mid.query_arena_formation, var_11_0, function(arg_12_0, arg_12_1)
						if arg_12_0 == xyd.error.OK then
							local var_12_0 = arg_12_1.heros
							local var_12_1 = 0
							local var_12_2 = arg_12_1.book_shelf_lev
							local var_12_3 = {}

							if var_12_0 and next(var_12_0) then
								for iter_12_0, iter_12_1 in ipairs(var_12_0) do
									local var_12_4 = import("app.model.Hero").new()
									local var_12_5 = iter_12_1

									if arg_12_1.is_robot == true then
										var_12_5.table_id = iter_12_1.partner_id
										var_12_5.partner_id = iter_12_0
									end

									if type(var_11_0.equips) == "string" then
										var_12_5.equips = xyd.splitToNumber(var_11_0.equips, "|")
									end

									var_12_4:populate(var_12_5)

									if arg_12_1.conquer_lev and arg_12_1.conquer_lev > 0 then
										var_12_4:setConquerSchoolLev(arg_12_1.conquer_lev)
									end

									table.insert(var_12_3, var_12_4)

									var_12_1 = var_12_1 + var_12_4:getZhandouli()
								end
							end

							if arg_12_1.pet then
								local var_12_6 = import("app.model.Pet").new()

								var_12_6:populate(arg_12_1.pet)

								var_12_1 = var_12_1 + var_12_6:getZhandouli()
							end

							local var_12_7 = {
								name = arg_12_1.player_name,
								level = arg_12_1.lev,
								avatar_id = arg_12_1.avatar_id,
								avatar_frame_id = arg_12_1.avatar_frame_id,
								win = arg_12_1.win,
								rank = arg_12_1.rank,
								force = var_12_1,
								heroes = var_12_3,
								guild = arg_12_1.guild_name,
								pet = arg_12_1.pet,
								conquer_lev = arg_12_1.conquer_lev,
								conquer_loop_id = arg_12_1.conquer_loop_id
							}

							xyd.WindowManager.get():openWindow("arena_team_info", {
								team = var_12_7
							})
						end
					end)
				elseif arg_10_2 == "LEGEND_RANK_TOTAL_INFO" or arg_10_2 == "LEGEND_RANK_INFO" then
					arg_10_0:showTeamInfo(arg_10_1, arg_10_3)
				elseif arg_10_2 == "TOTAL_TEAM_POWER" then
					local var_11_1 = {}

					for iter_11_0, iter_11_1 in ipairs(arg_10_1.partner_infos) do
						local var_11_2 = iter_11_1

						var_11_2.player_id = arg_10_1.player_id

						local var_11_3 = var_0_4.new()

						var_11_3:populate(var_11_2)
						table.insert(var_11_1, var_11_3)
					end

					local var_11_4

					if arg_10_1.pet_info and arg_10_1.pet_info.table_id then
						local var_11_5 = arg_10_1.pet_info

						var_11_5.player_id = arg_10_1.player_id
						var_11_4 = var_11_5
					end

					local var_11_6 = {
						name = arg_10_1.player_name,
						level = arg_10_1.lev,
						avatar_id = arg_10_1.avatar_id,
						avatar_frame_id = arg_10_1.avatar_frame_id,
						rank = arg_10_3,
						force = arg_10_1.force,
						heroes = var_11_1,
						guild = arg_10_1.guild_name,
						conquer_lev = arg_10_1.conquer_lev,
						conquer_loop_id = arg_10_1.conquer_loop_id
					}

					if var_11_4 then
						var_11_6.pet = var_11_4
					end

					xyd.WindowManager.get():openWindow("arena_team_info", {
						team = var_11_6
					})
				elseif arg_10_2 == "BOSS_RANK_INFO" or arg_10_2 == "PARADISE_THE_MOST_ATTACK" and arg_10_4 ~= "PARADISE_PERSON_IN_COMMUNITY_RANK" then
					local var_11_7 = {
						avatar_id = arg_10_1.avatar_id,
						avatar_frame_id = arg_10_1.avatar_frame_id,
						level = arg_10_1.level,
						hurt = math.floor(arg_10_1.total_hurt or arg_10_1.hurt),
						p_name = arg_10_1.player_name,
						rank = arg_10_3,
						guild_name = arg_10_1.guild_name,
						rank_type = arg_10_0.rank_type
					}

					if arg_10_2 == "BOSS_RANK_INFO" then
						var_11_7.boss_id = arg_10_0.mainRankList.boss_id
					elseif arg_10_2 == "PARADISE_THE_MOST_ATTACK" then
						var_11_7.rank = arg_10_1.illusion_rank or arg_10_3
					end

					xyd.WindowManager.get():openWindow("world_boss_rank_info", var_11_7)
				elseif arg_10_2 == "GUILD_RANK_INFO" or arg_10_2 == "COMPETITION_SCORE_DES" then
					local var_11_8 = {
						member_nums = arg_10_1.member_num,
						guild_id = arg_10_1.guild_id,
						guild_des = arg_10_1.des,
						guild_name = arg_10_1.name,
						guild_leader_name = arg_10_1.guild_leader_name,
						guild_icon = arg_10_1.icon,
						min_lev = arg_10_1.min_allow_level
					}

					xyd.WindowManager.get():openWindow("team_icon", var_11_8)
				elseif arg_10_2 == "PARADISE_GUILD_DAMAGE" then
					local var_11_9 = {
						member_nums = arg_10_1.member_num,
						guild_id = arg_10_1.guild_id,
						guild_des = arg_10_1.des,
						guild_name = arg_10_1.name,
						guild_leader_name = arg_10_1.guild_leader_name,
						guild_icon = arg_10_1.icon,
						min_lev = arg_10_1.min_allow_level
					}

					xyd.WindowManager.get():openWindow("team_icon", var_11_9)
				elseif arg_10_2 == "SELF_FIGHTING_RANK" then
					local var_11_10 = {
						avatar_id = arg_10_1.avatar_id,
						avatar_frame_id = arg_10_1.avatar_frame_id,
						level = arg_10_1.level,
						alive_num = arg_10_1.alive_num,
						kill_num = arg_10_1.kill_num,
						name = arg_10_1.player_name,
						coin_num = arg_10_1.guild_war_coin,
						rank = arg_10_3
					}

					xyd.WindowManager.get():openWindow("guild_war_rank_info", var_11_10)
				elseif arg_10_2 == "REGION_ARENA_RANK" then
					local var_11_11 = {
						level = arg_10_1.level,
						totalFight = arg_10_1.total_fight,
						winTimes = arg_10_1.win_times,
						regionName = arg_10_1.region_name,
						region = arg_10_1.region,
						point = arg_10_1.point,
						guildName = arg_10_1.guild_name,
						avatarID = arg_10_1.avatar_id,
						avatarFrameID = arg_10_1.avatar_frame_id,
						playerName = arg_10_1.player_name,
						star = arg_10_1.star,
						conquer_lev = arg_10_1.conquer_lev
					}

					xyd.WindowManager.get():openWindow("region_arena_rank_info", var_11_11)
				elseif arg_10_2 == "TOTAL_FORCE_INFO" or arg_10_2 == "PEAK_FORCE_INFO" or arg_10_2 == "TEAM_FORCE_INFO" or arg_10_2 == "HERO_STAR_INFO" or arg_10_2 == "PET_CAMPAIGN" or arg_10_2 == "SEND_HERO_NUM_RANK" or arg_10_2 == "PRACTICE_NUM" or arg_10_2 == "AWAKEN_NUM" or arg_10_2 == "AWAKEN_SECOND_NUM" or arg_10_2 == "PARADISE_THE_MOST_ATTACK" and arg_10_4 == "PARADISE_PERSON_IN_COMMUNITY_RANK" then
					local var_11_12 = {
						playerName = arg_10_1.player_name,
						level = arg_10_1.level,
						guildID = arg_10_1.guild_id,
						guildName = arg_10_1.guild_name,
						avatarID = arg_10_1.avatar_id,
						avatarFrameID = arg_10_1.avatar_frame_id,
						conquer_lev = arg_10_1.conquer_lev
					}

					xyd.WindowManager.get():openWindow("player_guild_info", var_11_12)
				elseif arg_10_2 == "ACHIEVEMENT_POINT" then
					local var_11_13 = {
						level = arg_10_1.level,
						regionName = arg_10_1.region_name,
						region = arg_10_1.region_id,
						avatarID = arg_10_1.avatar_id,
						avatarFrameID = arg_10_1.avatar_frame_id,
						playerName = arg_10_1.player_name,
						rank = arg_10_3,
						conquer_lev = arg_10_1.conquer_lev,
						achievementLevel = xyd.tables.achievementLevel:getLevByPoint(arg_10_1.point)
					}

					xyd.WindowManager.get():openWindow("achievement_rank_info", var_11_13)
				end
			end
		end
	end)

	if arg_10_2 == "LEGEND_RANK_INFO" and arg_10_1.rank_level then
		local var_10_5 = xyd.AssetLoader.get():loadSprite("windows/rank/legend_rank" .. arg_10_1.rank_level .. ".png")

		var_10_5:addTo(var_10_4)
		var_10_5:setPosition(700, 30)
	end

	local var_10_6 = var_10_4:getChildByName("rank_val_1")
	local var_10_7 = var_10_4:getChildByName("rank_val_2")
	local var_10_8 = var_10_4:getChildByName("rank_val_3")

	if arg_10_3 == 1 or arg_10_1.illusion_rank == 1 then
		var_10_6:setVisible(true)
		var_10_7:setVisible(false)
		var_10_8:setVisible(false)
	elseif arg_10_3 == 2 or arg_10_1.illusion_rank == 2 then
		var_10_6:setVisible(false)
		var_10_7:setVisible(true)
		var_10_8:setVisible(false)
	elseif arg_10_3 == 3 or arg_10_1.illusion_rank == 3 then
		var_10_6:setVisible(false)
		var_10_7:setVisible(false)
		var_10_8:setVisible(true)
	else
		var_10_6:setVisible(false)
		var_10_7:setVisible(false)
		var_10_8:setVisible(false)

		local var_10_9 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		if arg_10_1.illusion_rank and arg_10_1.illusion_rank > 0 then
			var_10_9:setString(arg_10_1.illusion_rank)
		else
			var_10_9:setString(arg_10_3)
		end

		var_10_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_10_9:setPosition(var_10_4:getChildByName("rank_val_3"):getPosition())
		var_10_9:addTo(var_10_4)
	end

	if arg_10_0.rank_type == xyd.RankType.Guild or arg_10_0.rank_type == xyd.RankType.GUILD_WIN or arg_10_2 == "PARADISE_GUILD_DAMAGE" then
		var_10_4:getChildByName("text_level"):setVisible(false)
		var_10_4:getChildByName("text_player_name"):setString(arg_10_1.name)
		var_10_4:getChildByName("avatar"):setPosition(var_10_4:getChildByName("avatar"):getX() - 15, var_10_4:getChildByName("avatar"):getY())

		if not arg_10_1.icon then
			arg_10_1.icon = 20010001
		end

		arg_10_0:setGuildAvatar(var_10_4:getChildByName("avatar"), arg_10_1.icon)
	else
		if arg_10_1.conquer_lev and arg_10_1.conquer_lev > 0 then
			local var_10_10 = {
				x = -2,
				y = 2
			}

			xyd.setConquerLev(arg_10_1.conquer_lev, var_10_4:getChildByName("text_level"), var_10_4:getChildByName("dengjiquan"), var_10_10, nil, nil, nil, nil, arg_10_1.conquer_loop_id)
		else
			var_10_4:getChildByName("text_level"):setString(arg_10_1.level or arg_10_1.lev)
		end

		var_10_4:getChildByName("text_player_name"):setString(arg_10_1.player_name or arg_10_1.name)
		var_10_4:getChildByName("avatar"):setScale(0.9333333333333333)

		local function var_10_11(arg_13_0)
			if arg_13_0.name == "began" then
				arg_10_0.isOpenPlayerInfoWindow = false

				return true
			elseif arg_13_0.name == "ended" and not arg_10_0.scrollViewMoved_ then
				arg_10_0.isOpenPlayerInfoWindow = true

				xyd.openPersonDisplayWindow(arg_10_1)
			end
		end

		xyd.setPlayerAvatar(var_10_4:getChildByName("avatar"), {
			showLevel = false,
			avatar_id = arg_10_1.avatar_id,
			avatar_frame_id = arg_10_1.avatar_frame_id,
			callback = var_10_11
		})
		xyd.setPlayerTitle(var_10_4:getChildByName("title_container"), arg_10_1.title_info)
	end

	if arg_10_0.rank_type == xyd.RankType.Power then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.info_val)
	elseif arg_10_0.rank_type == xyd.RankType.Guild then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.three_huoyue)
	elseif arg_10_0.rank_type == xyd.RankType.WB or arg_10_0.rank_type == xyd.RankType.NB then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. math.floor(arg_10_1.total_hurt))
	elseif arg_10_0.rank_type == xyd.RankType.PetCampaign then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.max_floor)
	elseif arg_10_2 == "SEND_HERO_NUM_RANK" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.hero_num)
	elseif arg_10_2 == "TEAM_FORCE_INFO" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.force)
	elseif arg_10_2 == "TOTAL_TEAM_POWER" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. arg_10_1.force)
	elseif arg_10_2 == "COMPETITION_SCORE_DES" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. ":" .. arg_10_1.win_times)
	elseif arg_10_2 == "SELF_FIGHTING_RANK" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.kill_num, arg_10_1.alive_num))
	elseif arg_10_2 == "ACHIEVEMENT_POINT" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.point))
	elseif arg_10_2 == "AWAKEN_NUM" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.info_val))
	elseif arg_10_2 == "AWAKEN_SECOND_NUM" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.info_val))
	elseif arg_10_2 == "PRACTICE_NUM" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.info_val))
	elseif arg_10_2 == "PARADISE_THE_MOST_ATTACK" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. arg_10_1.hurt)
	elseif arg_10_2 == "PARADISE_GUILD_DAMAGE" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. arg_10_1.hurt)
	elseif arg_10_2 == "REGION_CASUAL_RANK" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. arg_10_1.point)
	elseif arg_10_2 == "OCCULT_TOTAL_DAMAGE_TEXT" then
		var_10_4:getChildByName("text_info"):setString(string.format(var_0_3:translation(arg_10_2), arg_10_1.point))
	elseif arg_10_2 == "GUILD_WAR_BUFF_RANK" then
		var_10_4:getChildByName("text_info"):setString(var_0_3:translation(arg_10_2) .. arg_10_1.buff_num)
	end

	local var_10_12 = var_10_4:getContentSize()

	var_10_3:setPosition(cc.p(15, 0))
	var_10_3:setContentSize(var_10_12.width + 15, var_10_12.height)
	var_10_3:setTouchEnabled(true)
	var_10_3:setTouchSwallowEnabled(false)
	var_10_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(region, function(arg_14_0, arg_14_1)
		if arg_14_1.name == "began" then
			return true
		elseif arg_14_1.name == "ended" then
			if not arg_10_0.scrollViewMoved_ then
				return true
			else
				return true
			end
		end
	end))
	var_10_1:addChild(var_10_3)
	var_10_1:setContentSize(cc.size(arg_10_0.mainList_.viewRect_.width, var_10_3:getContentSize().height))
	var_10_0:addContent(var_10_1)
	var_10_0:setItemSize(arg_10_0.mainList_.viewRect_.width, var_10_1:getContentSize().height + 5)

	return var_10_0
end

function var_0_0.setGuildAvatar(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = "images/icon/skill_icon/" .. arg_15_2 .. "_icon.png" or "images/icon/skill_icon/" .. var_0_6 .. "_icon.png"
	local var_15_1 = xyd.AssetLoader:get():loadSprite(var_15_0)
	local var_15_2 = arg_15_1:getContentSize()
	local var_15_3 = arg_15_1:getContentSize().width
	local var_15_4 = arg_15_1:getContentSize().height
	local var_15_5 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg.png")

	var_15_5:setScale(0.8)
	var_15_5:setAnchorPoint(cc.p(0, 0))
	var_15_5:setPosition(-17, -20)
	arg_15_1:addChild(var_15_5)

	local var_15_6 = xyd.AssetLoader:get():loadSprite("images/avatars/mask1.png")

	var_15_6:setPosition(var_15_3 / 2, var_15_4 / 2)
	var_15_6:setAnchorPoint(cc.p(0.5, 0.5))
	var_15_6:setScale(var_15_4 / var_15_6:getHeight())

	local var_15_7 = cc.ClippingNode:create()

	var_15_7:setStencil(var_15_6)
	var_15_7:setInverted(true)
	var_15_7:setAlphaThreshold(0)
	var_15_7:addChild(var_15_1)
	var_15_1:align(display.CENTER, var_15_2.width / 2, var_15_2.height / 2)
	var_15_1:scale(var_15_2.width / var_15_1:getWidth())
	arg_15_1:addChild(var_15_7)

	local var_15_8 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")
	local var_15_9 = clone(var_15_8:getContentSize())
	local var_15_10 = display.newNode()

	var_15_10:setName("view")
	var_15_10:setContentSize(var_15_9)
	var_15_10:setAnchorPoint(cc.p(0, 0))
	var_15_10:setPosition(cc.p(0, 0))
	var_15_10:setScale(var_15_2.width / var_15_9.width, var_15_2.height / var_15_9.height)
	arg_15_1:addChild(var_15_10)

	local var_15_11 = xyd.AssetLoader:get():loadSprite("windows/corporation_window/team_icon_window/icon_bg2.png")

	var_15_11:setScale(0.8)
	var_15_11:setAnchorPoint(cc.p(0, 0))
	var_15_11:setPosition(-17, -20)
	arg_15_1:addChild(var_15_11)
	arg_15_1:setScale(0.8)

	if arg_15_3 then
		arg_15_1:setPositionY(arg_15_1:getPositionY() + 10)
	end

	arg_15_1:setPositionX(arg_15_1:getPositionX() + 20)
end

function var_0_0.addLeftCategory(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = arg_16_0.leftList_:newItem()
	local var_16_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/rank_type_item.csb")
	local var_16_2 = var_16_1:getChildByName("container")
	local var_16_3 = var_16_2:getContentSize()

	var_16_1:setPosition(cc.p(0, 0))
	var_16_1:setContentSize(var_16_3)
	var_16_1:setTouchEnabled(true)
	var_16_1:setTouchSwallowEnabled(false)
	var_16_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
		if arg_17_0.name == "began" then
			return true
		elseif arg_17_0.name == "ended" then
			if not arg_16_0.scrollViewMoved_ then
				if arg_16_0.rank_type == arg_16_1.type then
					if arg_16_0.has_click_left == false then
						arg_16_0.has_click_left = true
					else
						arg_16_0.has_click_left = false
					end

					arg_16_0.click_same_left = true
					arg_16_0.leftSelectedIndex = arg_16_2
				else
					arg_16_0.has_click_left = false
					arg_16_0.click_same_left = false
				end

				arg_16_0.rank_type = arg_16_1.type

				arg_16_0:updateLeftContainer()

				return true
			else
				return true
			end
		end
	end)
	var_16_0:addContent(var_16_1)
	var_16_0:setItemSize(var_16_3.width, var_16_3.height)
	arg_16_0.leftList_:addItem(var_16_0)
	arg_16_0:initLeftTitle(var_16_2, arg_16_2)

	if arg_16_1.type == arg_16_0.rank_type then
		arg_16_0.leftSelectedIndex = arg_16_2

		if not arg_16_1.subList or #arg_16_1.subList == 0 then
			arg_16_0.mainRankList = {}
			arg_16_0.mainRankList.rankList = {}

			arg_16_0:updateMainContainer()
		end

		local var_16_4 = arg_16_1.subList

		if var_16_4 and next(var_16_4) then
			local var_16_5 = {}

			local function var_16_6(arg_18_0)
				for iter_18_0, iter_18_1 in pairs(var_16_5) do
					if iter_18_0 == arg_18_0 then
						iter_18_1:getChildByName("bg1"):setVisible(false)
						iter_18_1:getChildByName("bg2"):setVisible(true)
						iter_18_1:getChildByName("text_subtype"):setColor(cc.c4b(255, 80, 80))
					else
						iter_18_1:getChildByName("bg1"):setVisible(true)
						iter_18_1:getChildByName("bg2"):setVisible(false)
						iter_18_1:getChildByName("text_subtype"):setColor(cc.c4b(255, 255, 255))
					end
				end

				if var_16_4[arg_18_0] and var_16_4[arg_18_0].rankList then
					arg_16_0.mainRankList = var_16_4[arg_18_0]

					arg_16_0:updateMainContainer()
				end
			end

			for iter_16_0, iter_16_1 in pairs(var_16_4) do
				local var_16_7 = arg_16_0.leftList_:newItem()
				local var_16_8 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena/rank/rank_type_sub_item.csb")
				local var_16_9 = var_16_8:getChildByName("container")
				local var_16_10 = var_16_9:getContentSize()

				var_16_9:setPosition(cc.p(-5, 0))
				var_16_8:setContentSize(var_16_10)

				if arg_16_2 ~= xyd.RankType.Occult then
					var_16_9:getChildByName("text_subtype"):setString(var_0_3:translation(iter_16_1.title))
				else
					var_16_9:getChildByName("text_subtype"):setString(iter_16_1.title)
				end

				table.insert(var_16_5, var_16_9)
				var_16_8:setTouchEnabled(true)
				var_16_8:setTouchSwallowEnabled(false)
				var_16_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, handler(iter_16_0, function(arg_19_0, arg_19_1)
					if arg_19_1.name == "began" then
						return true
					elseif arg_19_1.name == "ended" then
						if not arg_16_0.scrollViewMoved_ then
							var_16_6(arg_19_0)

							arg_16_0.index_ = arg_19_0

							return true
						else
							return true
						end
					end
				end))
				var_16_7:addContent(var_16_8)
				var_16_7:setItemSize(var_16_10.width, var_16_10.height + 5)

				if arg_16_0.has_click_left == false then
					arg_16_0.leftList_:addItem(var_16_7)
				end
			end

			local var_16_11 = arg_16_0.index_

			if arg_16_0.click_same_left == false then
				if arg_16_0.enter_rank_type == xyd.RankType.PK and arg_16_0.sub_type == 1 then
					if arg_16_0.rank_type == 2 then
						var_16_11 = 2
					else
						var_16_11 = 1
					end
				elseif arg_16_0.enter_rank_type == xyd.RankType.PK and arg_16_0.sub_type == 2 then
					if arg_16_0.rank_type == 1 then
						var_16_11 = 3
					else
						var_16_11 = 1
					end
				elseif arg_16_0.enter_rank_type == xyd.RankType.PK and arg_16_0.sub_type == 3 then
					if arg_16_0.rank_type == 1 then
						var_16_11 = 5
					else
						var_16_11 = 1
					end
				elseif arg_16_0.enter_rank_type == xyd.RankType.WB then
					if arg_16_0.rank_type == 4 then
						var_16_11 = arg_16_0.sub_type or 1
					else
						var_16_11 = 1
					end
				elseif arg_16_0.enter_rank_type == xyd.RankType.PetCampaign then
					var_16_11 = arg_16_0.sub_type
				else
					var_16_11 = 1
				end

				arg_16_0.index_ = var_16_11
			end

			var_16_6(var_16_11)
		end
	end

	table.insert(arg_16_0.subTypeLists, subListCells)
end

function var_0_0.initLeftTitle(arg_20_0, arg_20_1, arg_20_2)
	local var_20_0 = xyd.AssetLoader.get():loadSprite("windows/arena/rank/title_bg" .. arg_20_2 .. ".png")

	if var_20_0 then
		var_20_0:addTo(arg_20_1)
		var_20_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_20_0:setPosition(cc.p(126, 45))
	end
end

function var_0_0.updateListView(arg_21_0)
	arg_21_0:updateLeftContainer()
end

function var_0_0.updateLeftContainer(arg_22_0)
	arg_22_0.leftList_:removeAllItems()

	local var_22_0 = table.keys(arg_22_0.rankData)

	table.sort(var_22_0, function(arg_23_0, arg_23_1)
		return arg_23_0 < arg_23_1
	end)

	for iter_22_0 = 1, #var_22_0 do
		arg_22_0:addLeftCategory(arg_22_0.rankData[var_22_0[iter_22_0]], var_22_0[iter_22_0])
	end

	arg_22_0.leftList_:reload()

	local var_22_1 = arg_22_0.leftList_:getScrollNode()
	local var_22_2 = xyd.WindowManager.get():getWindow("guild_war")

	if var_22_1 and arg_22_0.leftSelectedIndex > 3 and not var_22_2 then
		local var_22_3 = var_22_1:getPositionY() + (arg_22_0.leftSelectedIndex - 3) * 80

		var_22_1:setPositionY(var_22_3)
		arg_22_0.leftList_:elasticScroll()
	end
end

function var_0_0.updateMainContainer(arg_24_0)
	arg_24_0.mainList_:reload()
end

function var_0_0.scrollListener(arg_25_0, arg_25_1)
	if arg_25_1.name == "began" then
		arg_25_0.scrollViewMoved_ = false
		arg_25_0.prevY_ = arg_25_1.y
	elseif arg_25_1.name == "moved" and 10 <= math.abs(arg_25_1.y - arg_25_0.prevY_) then
		arg_25_0.scrollViewMoved_ = true
	end
end

return var_0_0
