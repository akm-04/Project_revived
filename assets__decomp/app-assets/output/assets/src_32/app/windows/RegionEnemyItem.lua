local var_0_0 = class("RegionEnemyItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = xyd.tables.misc

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.player_info = arg_2_1.player_info
	arg_2_0.region_arena_info = arg_2_1.region_arena_info
	arg_2_0.defense_info = arg_2_1.defense_info
	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = {}

	arg_3_0:contentView():nodeByName("rank_label"):setString(var_0_1:translation("RANK_LABEL"))
	arg_3_0:contentView():nodeByName("force_label"):setString(var_0_1:translation("HERO_INFO_ZHANDOULI"))

	for iter_3_0, iter_3_1 in pairs(arg_3_0.defense_info.partners_info) do
		local var_3_1 = var_0_2.new()

		var_3_1:populate(iter_3_1)
		table.insert(var_3_0, var_3_1)
	end

	xyd.formatRegionArenaHeros(var_3_0)

	local var_3_2

	if arg_3_0.defense_info.pet_info then
		var_3_2 = var_0_3.new()

		var_3_2:populate(arg_3_0.defense_info.pet_info)
		xyd.formatRegionArenaPets({
			var_3_2
		})
	end

	arg_3_0:contentView():nodeByName("name"):setString(arg_3_0.player_info.player_name)
	arg_3_0:contentView():nodeByName("rank"):setString(arg_3_0.region_arena_info.rank)

	local var_3_3 = 0

	for iter_3_2 = 1, #var_3_0 do
		var_3_3 = var_3_3 + var_3_0[iter_3_2]:getZhandouli()
	end

	if var_3_2 then
		var_3_3 = var_3_3 + var_3_2:getZhandouli()
	end

	arg_3_0:contentView():nodeByName("force"):setString(var_3_3)
	arg_3_0:contentView():nodeByName("lev"):setString(arg_3_0.player_info.lev)

	local function var_3_4()
		local var_4_0 = {
			other_player_id = arg_3_0.player_info.player_id
		}

		arg_3_0.regionArena:getFormationInfo(var_4_0, function(arg_5_0, arg_5_1)
			if arg_5_0 == xyd.error.OK then
				local var_5_0 = {
					name = arg_5_1.name,
					level = arg_5_1.level,
					fans = arg_5_1.be_support_num,
					avatar_id = arg_5_1.avatar_id,
					avatar_frame_id = arg_5_1.avatar_frame_id,
					point = arg_5_1.point,
					server = "(" .. arg_5_1.region .. ")" .. arg_5_1.region_name,
					wins = arg_5_1.win_times,
					guild = arg_5_1.guild_name,
					heroes = arg_5_1.heros,
					rank = tonumber(arg_5_1.region_rank)
				}

				if arg_5_1.pet_info then
					var_5_0.pet = arg_5_1.pet_info
				end

				xyd.WindowManager.get():openWindow("region_arena_team_info", {
					team = arg_5_1
				})
			end
		end)
	end

	xyd.setPlayerAvatar(arg_3_0:contentView():nodeByName("avatar_panel"), {
		avatar_id = arg_3_0.player_info.avatar_id,
		avatar_frame_id = arg_3_0.player_info.avatar_frame_id,
		callback = var_3_4
	})

	local var_3_5 = arg_3_0:contentView():nodeByName("rank_1")
	local var_3_6 = arg_3_0:contentView():nodeByName("rank_2")
	local var_3_7 = arg_3_0:contentView():nodeByName("rank_3")

	arg_3_0:contentView():nodeByName("challenge_button"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_3_0:checkTimeCanDo() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NEW_ARENA_CANT_CHGALLENGE_TIPS")
				})

				return
			end

			xyd.playButtonSound()

			if arg_3_0.regionArena.self_arena_info.left_time and arg_3_0.regionArena.self_arena_info.left_time <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = string.format(var_0_1:translation("TRIAL_LEFT_TIMES"), 0)
				})
			elseif xyd.WindowManager.get():getWindow("region_arena") and xyd.WindowManager.get():getWindow("region_arena").countDownOn then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TIME_TOO_EARLY")
				})
			else
				local var_6_0 = {}
				local var_6_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
				local var_6_2 = {
					my_id = var_6_1.playerID,
					enemy_id = arg_3_0.player_info.player_id
				}
				local var_6_3 = {
					withRobot = false,
					showEnemy = true,
					type = xyd.SelectTeamType.REGION_ARENA,
					campaignType = xyd.CampaignType.REGION_ARENA,
					fighterInfo = var_6_2,
					enemyHeroes = var_3_0,
					hide_counts = arg_3_0:ConcealNum(),
					enemyPets = var_3_2
				}

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_3)
			end

			return false
		end

		return false
	end)
	arg_3_0:registerTouchEvent()
end

function var_0_0.ConcealNum(arg_7_0)
	local var_7_0 = 0

	for iter_7_0 = 1, #var_0_4.newArenaConcealRank do
		if arg_7_0.region_arena_info.rank < var_0_4.newArenaConcealRank[iter_7_0] then
			var_7_0 = var_0_4.newArenaConcealNum[iter_7_0]
		end
	end

	return var_7_0
end

function var_0_0.getRandomFirstSelect(arg_8_0)
	if math.random() < 0.5 then
		return 0
	else
		return 1
	end
end

function var_0_0.checkTimeCanDo(arg_9_0)
	if arg_9_0.regionArena.region_info.is_forbidden == 1 then
		return true
	end

	local var_9_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_9_0 < xyd.tables.misc.newArenaChallengeBegin or var_9_0 > xyd.tables.misc.newArenaChallengeFinish then
		return false
	else
		return true
	end
end

function var_0_0.registerTouchEvent(arg_10_0)
	local var_10_0 = arg_10_0.container

	arg_10_0:contentView():nodeByName("avatar_panel"):setTouchSwallowEnabled(false)
	arg_10_0:contentView():nodeByName("avatar_panel"):setTouchEnabled(true)
	arg_10_0:contentView():nodeByName("avatar_panel"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			arg_10_0.prevX_ = arg_11_0.x
			arg_10_0.prevY_ = arg_11_0.y
			arg_10_0.startClick_ = true
		elseif arg_11_0.name == "moved" then
			if math.abs(arg_11_0.y - arg_10_0.prevY_) > 10 or math.abs(arg_11_0.x - arg_10_0.prevX_) > 20 then
				arg_10_0.startClick_ = false
			end
		elseif arg_11_0.name == "ended" and arg_10_0.startClick_ then
			local var_11_0 = {
				other_player_id = arg_10_0.player_info.player_id
			}

			arg_10_0.regionArena:getFormationInfo(var_11_0, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					local var_12_0 = var_10_0:convertToNodeSpace(cc.p(arg_11_0.x, arg_11_0.y))
					local var_12_1 = {
						name = arg_12_1.name,
						level = arg_12_1.level,
						fans = arg_12_1.be_support_num,
						avatar_id = arg_12_1.avatar_id,
						avatar_frame_id = arg_12_1.avatar_frame_id,
						point = arg_12_1.point,
						server = "(" .. arg_12_1.region .. ")" .. arg_12_1.region_name,
						wins = arg_12_1.win_times,
						guild = arg_12_1.guild_name,
						heroes = arg_12_1.heros,
						rank = tonumber(arg_12_1.region_rank)
					}

					if arg_12_1.pet_info then
						var_12_1.pet = arg_12_1.pet_info
					end

					xyd.WindowManager.get():openWindow("region_arena_team_info", {
						team = arg_12_1
					})
				end
			end)
		end

		return true
	end)
end

function var_0_0.contentView(arg_13_0)
	if arg_13_0.contentView_ == nil then
		arg_13_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_13_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/across_arena/enemy_item.csb"))
		arg_13_0.contentView_:addTo(arg_13_0)
		arg_13_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_13_0.contentView_
end

return var_0_0
