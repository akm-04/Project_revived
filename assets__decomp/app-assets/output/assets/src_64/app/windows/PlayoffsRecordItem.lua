local var_0_0 = class("PlayoffsRecordItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = 6

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	arg_2_0.idx = arg_2_2
	arg_2_0.isOnFocus = arg_2_1
	arg_2_0.params = arg_2_3
	arg_2_0.playoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)

	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:setContentSize(arg_2_0:contentView():nodeByName("background"):getContentSize())

	arg_2_0.playoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:contentView():nodeByName("player_1_name"):setString(arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].player_name)
	arg_3_0:contentView():nodeByName("player_2_name"):setString(arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].player_name)

	local var_3_0 = {
		conquerLev = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].conquer_lev,
		lev = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].lev,
		loopID = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].conquer_loop_id
	}
	local var_3_1 = {
		conquerLev = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].conquer_lev,
		lev = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].lev,
		loopID = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].conquer_loop_id
	}

	xyd.setLev(arg_3_0:contentView():nodeByName("dengjiquan_1"), var_3_0)
	xyd.setLev(arg_3_0:contentView():nodeByName("dengjiquan_2"), var_3_1)
	xyd.setPlayerAvatar(arg_3_0:contentView():nodeByName("player_1_icon"), {
		avatar_id = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].avatar_id,
		avatar_frame_id = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].avatar_frame_id
	})
	xyd.setPlayerAvatar(arg_3_0:contentView():nodeByName("player_2_icon"), {
		avatar_id = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].avatar_id,
		avatar_frame_id = arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].avatar_frame_id
	})

	if arg_3_0.isOnFocus then
		arg_3_0:contentView():nodeByName("winner_label"):setString(var_0_1:translation("PLAYOFFS_WINNER_LABEL"))

		local var_3_2

		if arg_3_0.idx <= 10 then
			var_3_2 = var_0_1:translation("NUM_" .. arg_3_0.idx)
		else
			var_3_2 = tostring(arg_3_0.idx)
		end

		arg_3_0:contentView():nodeByName("match_title"):setString(string.format(var_0_1:translation("PLAYOFFS_MATCH_TITLE"), var_3_2))

		if tonumber(arg_3_0.params.battle_count) < 3 then
			arg_3_0:contentView():nodeByName("button_3"):setBright(false)
			arg_3_0:contentView():nodeByName("button_3"):setTouchEnabled(false)
		end

		if tonumber(arg_3_0.params.A_win_times) > tonumber(arg_3_0.params.B_win_times) then
			arg_3_0:contentView():nodeByName("winner_text"):setString(arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.A_player_id)].player_name)
		else
			arg_3_0:contentView():nodeByName("winner_text"):setString(arg_3_0.playoffsModel.players_info[tostring(arg_3_0.params.B_player_id)].player_name)
		end
	end

	if tonumber(arg_3_0.params.A_win_times) > tonumber(arg_3_0.params.B_win_times) then
		arg_3_0:contentView():nodeByName("flag_win_1"):setVisible(true)
		arg_3_0:contentView():nodeByName("flag_win_2"):setVisible(false)
		arg_3_0:contentView():nodeByName("flag_lose_1"):setVisible(false)
		arg_3_0:contentView():nodeByName("flag_lose_2"):setVisible(true)
		arg_3_0:contentView():nodeByName("win_cup_1"):setVisible(true)
		arg_3_0:contentView():nodeByName("win_cup_2"):setVisible(false)
	else
		arg_3_0:contentView():nodeByName("flag_win_1"):setVisible(false)
		arg_3_0:contentView():nodeByName("flag_win_2"):setVisible(true)
		arg_3_0:contentView():nodeByName("flag_lose_1"):setVisible(true)
		arg_3_0:contentView():nodeByName("flag_lose_2"):setVisible(false)
		arg_3_0:contentView():nodeByName("win_cup_1"):setVisible(false)
		arg_3_0:contentView():nodeByName("win_cup_2"):setVisible(true)
	end

	arg_3_0:registerTouchEvent()
end

function var_0_0.formatRegionArenaHeros(arg_4_0, arg_4_1)
	for iter_4_0, iter_4_1 in pairs(arg_4_1) do
		if iter_4_1:isCanAwaken() then
			local var_4_0 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_4_1 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_4_2 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_4_0:renewHeroInfo(iter_4_1, var_4_0, var_4_1, var_4_2)
		else
			local var_4_3 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_4_4 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_4_5 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_4_0:renewHeroInfo(iter_4_1, var_4_3, var_4_4, var_4_5)
		end

		iter_4_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_4_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4)
	local var_5_0 = 14
	local var_5_1 = 90

	if not arg_5_0.isfriend and arg_5_1:isCanAwaken() and not arg_5_1:isAwaken() then
		arg_5_1:setTableID(arg_5_1:afterAwakenID())
	end

	arg_5_1.color_ = var_5_0
	arg_5_1.level_ = var_5_1
	arg_5_1.skillLev_ = {}
	arg_5_1.skillLev_[xyd.SKILL_INDEX.Energy] = tonumber(arg_5_2[xyd.SKILL_INDEX.Energy]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Energy]

	if arg_5_1.color_ >= xyd.EquipQuality.GREEN then
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Green] = tonumber(arg_5_2[xyd.SKILL_INDEX.Green]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Green]
	else
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Green] = false
	end

	if arg_5_1.color_ >= xyd.EquipQuality.BLUE then
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Blue] = tonumber(arg_5_2[xyd.SKILL_INDEX.Blue]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Blue]
	else
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Blue] = false
	end

	if arg_5_1.color_ >= xyd.EquipQuality.PURPLE then
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Purple] = tonumber(arg_5_2[xyd.SKILL_INDEX.Purple]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Purple]
	else
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Purple] = false
	end

	if arg_5_1:isAwaken() then
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Awake] = tonumber(arg_5_2[xyd.SKILL_INDEX.Awake]) + xyd.SKILL_EXTRA[xyd.SKILL_INDEX.Awake]
	else
		arg_5_1.skillLev_[xyd.SKILL_INDEX.Awake] = false
	end

	arg_5_1.equips_ = {}

	for iter_5_0 = 1, var_0_4 do
		table.insert(arg_5_1.equips_, tonumber(arg_5_4[iter_5_0]))
	end

	arg_5_1.fumo_ = {}

	for iter_5_1 = 1, var_0_4 do
		table.insert(arg_5_1.fumo_, tonumber(arg_5_3[iter_5_1]))
	end

	arg_5_1.fumoLev_ = {}

	for iter_5_2 = 1, var_0_4 do
		local var_5_2 = arg_5_1:getEquipByIndex(iter_5_2)

		table.insert(arg_5_1.fumoLev_, tonumber(var_5_2:getMaxFumoStar()))
	end
end

function var_0_0.registerTouchEvent(arg_6_0)
	local var_6_0 = arg_6_0.container

	arg_6_0:contentView():nodeByName("arrow"):setTouchEnabled(true)
	arg_6_0:contentView():nodeByName("arrow"):setTouchSwallowEnabled(false)
	arg_6_0:contentView():nodeByName("arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			arg_6_0.prevX_ = arg_7_0.x
			arg_6_0.prevY_ = arg_7_0.y
			arg_6_0.startClick_ = true
		elseif arg_7_0.name == "moved" then
			if math.abs(arg_7_0.y - arg_6_0.prevY_) > 10 or math.abs(arg_7_0.x - arg_6_0.prevX_) > 20 then
				arg_6_0.startClick_ = false
			end
		elseif arg_7_0.name == "ended" and arg_6_0.startClick_ then
			if not arg_6_0.isOnFocus then
				xyd.WindowManager:get():getWindow("playoffs_record").onFocus = arg_6_0.idx
			else
				xyd.WindowManager:get():getWindow("playoffs_record").onFocus = 0
			end

			xyd.WindowManager:get():getWindow("playoffs_record"):reloadList()
		end

		return true
	end)

	if arg_6_0.isOnFocus then
		for iter_6_0 = 1, 3 do
			local var_6_1 = var_0_1:translation("NUM_" .. iter_6_0)

			arg_6_0:contentView():nodeByName("text_round_" .. iter_6_0):setString(string.format(var_0_1:translation("PLAYOFFS_MATCH_BUTTON_LABEL"), var_6_1))

			if tonumber(arg_6_0.params.battle_count) < 3 and iter_6_0 == 3 then
				arg_6_0:contentView():nodeByName("text_round_" .. iter_6_0):setColor(cc.c3b(52, 54, 55))
			end
		end

		arg_6_0:contentView():nodeByName("button_1"):addTouchEventListener(function(arg_8_0, arg_8_1)
			xyd.buttonScaleAnim(arg_8_0, arg_8_1)

			if arg_8_1 == ccui.TouchEventType.ended then
				arg_6_0:playReport(1)
			end
		end)
		arg_6_0:contentView():nodeByName("button_2"):addTouchEventListener(function(arg_9_0, arg_9_1)
			xyd.buttonScaleAnim(arg_9_0, arg_9_1)

			if arg_9_1 == ccui.TouchEventType.ended then
				arg_6_0:playReport(2)
			end
		end)
		arg_6_0:contentView():nodeByName("button_3"):addTouchEventListener(function(arg_10_0, arg_10_1)
			xyd.buttonScaleAnim(arg_10_0, arg_10_1)

			if arg_10_1 == ccui.TouchEventType.ended then
				arg_6_0:playReport(3)
			end
		end)
	end
end

function var_0_0.playReport(arg_11_0, arg_11_1)
	arg_11_0.playoffsModel:getBattleReportFromBack(function(arg_12_0)
		local var_12_0 = arg_12_0
		local var_12_1 = var_12_0.battle_report
		local var_12_2 = {
			enemyHeros = {},
			selfHeros = {},
			battleReport = var_12_0.report[1].content,
			enemyID = var_12_0.record_info.B_player_id
		}
		local var_12_3 = var_12_2.battleReport
		local var_12_4 = json.decode(var_12_3)
		local var_12_5 = xyd.split(var_12_0.record_info["team_" .. arg_11_1], "|")

		for iter_12_0 = 1, #xyd.splitToNumber(var_12_5[1], ":") do
			local var_12_6 = xyd.splitToNumber(var_12_5[1], ":")[iter_12_0]
			local var_12_7 = var_0_2.new()
			local var_12_8 = var_12_0.A_partners_info[tostring(xyd.splitToNumber(var_12_5[1], ":")[iter_12_0])]

			var_12_7:initUnCollected(var_12_8.table_id)

			for iter_12_1, iter_12_2 in pairs(var_12_4.fighter) do
				if string.sub(iter_12_1, 1, 1) == "A" and tonumber(iter_12_2.summon_type) == xyd.summonMonsterType.None then
					local var_12_9 = iter_12_2.hero

					if var_12_9.partner_id == var_12_6 then
						var_12_7:setSkinInfo(var_12_9.current_skin_id, var_12_8.skin_ids, var_12_9.illusion_skin_id)
					end
				end
			end

			table.insert(var_12_2.selfHeros, var_12_7)
		end

		local var_12_10 = xyd.splitToNumber(var_12_0.record_info["pet_id_" .. arg_11_1], "|")

		if tonumber(var_12_10[1]) ~= 0 then
			local var_12_11 = var_0_3.new()

			var_12_11:initUnCollected(var_12_0.A_pet_info[tostring(var_12_10[1])].table_id, nil, {
				color = var_12_0.A_pet_info[tostring(var_12_10[1])].color,
				star = var_12_0.A_pet_info[tostring(var_12_10[1])].star
			})
			xyd.formatRegionArenaPetsAwake({
				var_12_11
			})

			var_12_2.selfPet = var_12_11
		end

		for iter_12_3 = 1, #xyd.splitToNumber(var_12_5[2], ":") do
			local var_12_12 = xyd.splitToNumber(var_12_5[2], ":")[iter_12_3]
			local var_12_13 = var_0_2.new()
			local var_12_14 = var_12_0.B_partners_info[tostring(xyd.splitToNumber(var_12_5[2], ":")[iter_12_3])]

			var_12_13:initUnCollected(var_12_14.table_id)

			for iter_12_4, iter_12_5 in pairs(var_12_4.fighter) do
				if string.sub(iter_12_4, 1, 1) == "B" and tonumber(iter_12_5.summon_type) == xyd.summonMonsterType.None then
					local var_12_15 = iter_12_5.hero

					if var_12_15.partner_id == var_12_12 then
						var_12_13:setSkinInfo(var_12_15.current_skin_id, var_12_14.skin_ids, var_12_15.illusion_skin_id)
					end
				end
			end

			table.insert(var_12_2.enemyHeros, var_12_13)
		end

		if tonumber(var_12_10[2]) ~= 0 then
			local var_12_16 = var_0_3.new()

			var_12_16:initUnCollected(var_12_0.B_pet_info[tostring(var_12_10[2])].table_id, nil, {
				color = var_12_0.B_pet_info[tostring(var_12_10[2])].color,
				star = var_12_0.B_pet_info[tostring(var_12_10[2])].star
			})
			xyd.formatRegionArenaPetsAwake({
				var_12_16
			})

			var_12_2.enemyPet = var_12_16
		end

		xyd.formatRegionArenaHeros(var_12_2.selfHeros)
		xyd.formatRegionArenaHeros(var_12_2.enemyHeros)

		var_12_2.enemyName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.B_player_id)].player_name
		var_12_2.enemyServerName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.B_player_id)].region_name
		var_12_2.enemyGuildName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.B_player_id)].guild_name
		var_12_2.delay = 1
		var_12_2.isBackendBattle = 1
		var_12_2.oldStar = 45
		var_12_2.is_record = true
		var_12_2.selfPlayerID = var_12_0.record_info.A_player_id
		var_12_2.selfPlayerName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.A_player_id)].player_name
		var_12_2.selfGuildName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.A_player_id)].guild_name
		var_12_2.selfRegion = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.A_player_id)].region
		var_12_2.selfRegionName = arg_11_0.playoffsModel.players_info[tostring(var_12_0.record_info.A_player_id)].region_name
		var_12_2.enemyRegion = arg_11_0.playoffsModel.players_info[tostring(var_12_2.enemyID)].region

		xyd.WindowManager.get():closeAllWindows()
		xyd.WindowManager.get():openWindow("region_arena_loading", var_12_2)
	end, arg_11_0.params.stage, arg_11_0.params.record_id, arg_11_1)
end

function var_0_0.contentView(arg_13_0)
	if arg_13_0.contentView_ == nil then
		arg_13_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		if arg_13_0.isOnFocus then
			arg_13_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/group/item_on_focus.csb"))
		else
			arg_13_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/group/item_no_focus.csb"))
		end

		arg_13_0.contentView_:addTo(arg_13_0)
		arg_13_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_13_0.contentView_
end

return var_0_0
