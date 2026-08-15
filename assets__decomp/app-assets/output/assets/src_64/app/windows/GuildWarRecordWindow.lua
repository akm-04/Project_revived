local var_0_0 = class("GuildWarRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.guildBattleTable
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_1_0:setList(arg_1_2)

	arg_1_0.params = arg_1_2

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.setList(arg_2_0, arg_2_1)
	arg_2_0.enemy = {}
	arg_2_0.mine = {}
	arg_2_0.enemy.heroIds = xyd.splitToNumber(arg_2_1.enemy.formation_ids, "|")
	arg_2_0.enemy.heroLevs = xyd.splitToNumber(arg_2_1.enemy.formation_levs, "|")
	arg_2_0.enemy.heroColors = xyd.splitToNumber(arg_2_1.enemy.formation_colors, "|")
	arg_2_0.enemy.heroStars = xyd.splitToNumber(arg_2_1.enemy.formation_stars, "|")
	arg_2_0.enemy.heroLev = xyd.splitToNumber(arg_2_1.enemy.formation_levs, "|")
	arg_2_0.enemy.hps = xyd.splitToNumber(arg_2_1.enemy.team_hps, ",")
	arg_2_0.enemy.skinIds = xyd.splitToNumber(arg_2_1.enemy.formation_skin_ids, "|")
	arg_2_0.enemy.awakeStages = xyd.splitToNumber(arg_2_1.enemy.formation_awake_stages, "|")

	if arg_2_1.enemy.team_total_hps then
		arg_2_0.enemy.totalHps = xyd.splitToNumber(arg_2_1.enemy.team_total_hps, ",")
	end

	arg_2_0.enemy.mps = xyd.splitToNumber(arg_2_1.enemy.team_mps, ",")
	arg_2_0.enemy.isWin = arg_2_1.enemy.is_win
	arg_2_0.enemy.avatar = arg_2_1.enemy.player_avatar
	arg_2_0.enemy.frame = arg_2_1.enemy.player_frame
	arg_2_0.enemy.lev = arg_2_1.enemy.player_lev
	arg_2_0.enemy.name = arg_2_1.enemy.player_name
	arg_2_0.enemy.reportKey = arg_2_1.enemy.report_key
	arg_2_0.enemy.pet = arg_2_1.enemy.pet_info
	arg_2_0.mine.heroIds = xyd.splitToNumber(arg_2_1.mine.formation_ids, "|")
	arg_2_0.mine.heroLevs = xyd.splitToNumber(arg_2_1.mine.formation_levs, "|")
	arg_2_0.mine.heroColors = xyd.splitToNumber(arg_2_1.mine.formation_colors, "|")
	arg_2_0.mine.heroStars = xyd.splitToNumber(arg_2_1.mine.formation_stars, "|")
	arg_2_0.mine.heroLev = xyd.splitToNumber(arg_2_1.mine.formation_levs, "|")
	arg_2_0.mine.hps = xyd.splitToNumber(arg_2_1.mine.team_hps, ",")
	arg_2_0.mine.skinIds = xyd.splitToNumber(arg_2_1.mine.formation_skin_ids, "|")
	arg_2_0.mine.awakeStages = xyd.splitToNumber(arg_2_1.mine.formation_awake_stages, "|")

	if arg_2_1.mine.team_total_hps then
		arg_2_0.mine.totalHps = xyd.splitToNumber(arg_2_1.mine.team_total_hps, ",")
	end

	arg_2_0.mine.mps = xyd.splitToNumber(arg_2_1.mine.team_mps, ",")
	arg_2_0.mine.isWin = arg_2_1.mine.is_win
	arg_2_0.mine.avatar = arg_2_1.mine.player_avatar
	arg_2_0.mine.frame = arg_2_1.mine.player_frame
	arg_2_0.mine.lev = arg_2_1.mine.player_lev
	arg_2_0.mine.name = arg_2_1.mine.player_name
	arg_2_0.mine.pet = arg_2_1.mine.pet_info
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)
end

function var_0_0.replayRecord(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_1 == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_5_0 = {}
	local var_5_1 = json.decode(arg_5_1)

	var_5_0.herosA = {}
	var_5_0.herosB = {}
	var_5_0.summonMonsters = {}
	var_5_0.campaignType = xyd.CampaignType.GUILD_ARENA
	var_5_0.battleID = xyd.MapBattleID.ARENA
	var_5_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_5_1

	local var_5_2 = {}
	local var_5_3 = {}

	for iter_5_0, iter_5_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_5_4 = string.sub(iter_5_0, 1, 1)
		local var_5_5 = tonumber(string.sub(iter_5_0, 3, 3))

		if var_5_4 == "A" and tonumber(iter_5_1.summon_type) == xyd.summonMonsterType.None then
			local var_5_6 = var_0_3.new()

			var_5_6:populate(iter_5_1.hero)
			var_5_6:setReportData(iter_5_1)

			if iter_5_1.health_status then
				var_5_6.healthStatus = iter_5_1.health_status
			end

			if arg_5_2 then
				var_5_6.willDie = (iter_5_1.die_count or 0) ~= -1
				var_5_6.harms = iter_5_1.harms
			end

			var_5_0.herosA[var_5_5] = var_5_6
		elseif var_5_4 == "A" and tonumber(iter_5_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_5_7 = var_0_4.new()

			var_5_7:populate(iter_5_1.hero)
			var_5_7:setReportData(iter_5_1)

			if arg_5_2 then
				var_5_7.harms = iter_5_1.harms
				var_5_7.willDie = (iter_5_1.die_count or 0) ~= -1
				var_5_0.petA = {
					var_5_7
				}
			else
				var_5_0.petsA = {
					var_5_7
				}
			end
		elseif var_5_4 == "B" and tonumber(iter_5_1.summon_type) == xyd.summonMonsterType.None then
			local var_5_8 = var_0_3.new()

			var_5_8:populate(iter_5_1.hero)
			var_5_8:setReportData(iter_5_1)

			if iter_5_1.health_status then
				var_5_8.healthStatus = iter_5_1.health_status
			end

			if arg_5_2 then
				var_5_8.willDie = (iter_5_1.die_count or 0) ~= -1
				var_5_8.harms = iter_5_1.harms
				var_5_0.herosB[var_5_5] = var_5_8
			else
				var_5_2[var_5_5] = var_5_8
			end
		elseif var_5_4 == "B" and tonumber(iter_5_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_5_9 = var_0_4.new()

			var_5_9:populate(iter_5_1.hero)
			var_5_9:setReportData(iter_5_1)

			if arg_5_2 then
				var_5_9.willDie = (iter_5_1.die_count or 0) ~= -1
				var_5_9.harms = iter_5_1.harms
				var_5_0.petB = {
					var_5_9
				}
			else
				var_5_0.petsB = {
					var_5_9
				}
			end
		elseif tonumber(iter_5_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_5_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_5_10 = var_0_3.new()

			var_5_10:populate(iter_5_1.hero)
			var_5_10:setReportData(iter_5_1)

			var_5_3[iter_5_0] = var_5_10
		end
	end

	if arg_5_2 then
		var_5_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_5_0)
	else
		var_5_0.herosB = {
			var_5_2
		}
		var_5_0.summonMonsters = var_5_3
		var_5_0.reportStar = arg_5_0.mine.isWin
		var_5_0.location = arg_5_0.guild.warSide
		var_5_0.campaignType = xyd.CampaignType.GUILD_ARENA

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = "guild_war_record",
				status = arg_5_0.params
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_5_0)
	end
end

function var_0_0.layout(arg_6_0)
	arg_6_0:addBlockLayer()

	arg_6_0.report = {}

	arg_6_0:nodeByName("record_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_7_0 = {
				report_key = arg_6_0.enemy.reportKey
			}

			arg_6_0.guild:guildWarReplay(var_7_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					if arg_8_1 == nil or arg_8_1 == {} then
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
						})
					else
						arg_6_0:replayRecord(arg_8_1.report)
					end
				end
			end)
		end
	end)
	arg_6_0:nodeByName("data_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_9_0 = {
				report_key = arg_6_0.enemy.reportKey
			}

			arg_6_0.guild:guildWarReplay(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					if arg_10_1 == nil or arg_10_1 == {} then
						if xyd.WindowManager.get():getWindow("toast") ~= nil then
							xyd.WindowManager.get():closeWindow("toast")
						end

						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("ARENA_RECORD_OUT_OF_DATE")
						})
					else
						arg_6_0:replayRecord(arg_10_1.report, true)
					end
				end
			end)
		end
	end)

	if arg_6_0.guild.warSide == 1 then
		arg_6_0.side = "blue"
		arg_6_0.enSide = "red"
	else
		arg_6_0.side = "red"
		arg_6_0.enSide = "blue"
	end

	arg_6_0:addHeroCells(arg_6_0.side, arg_6_0.mine)
	arg_6_0:addHeroCells(arg_6_0.enSide, arg_6_0.enemy)
	xyd.setAvatarClip(arg_6_0:nodeByName(arg_6_0.side .. "_avatar"), arg_6_0.mine.avatar, 1)

	local var_6_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_6_0.mine.frame and arg_6_0.mine.frame ~= 0 then
		var_6_0 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_6_0.mine.frame] .. ".png"
	end

	local var_6_1 = xyd.AssetLoader.get():loadSprite(var_6_0)

	var_6_1:setPosition(37.5, 37.5)
	arg_6_0:nodeByName(arg_6_0.side .. "_avatar_border"):addChild(var_6_1)
	arg_6_0:nodeByName(arg_6_0.side .. "_name_text"):setString(arg_6_0.mine.name)
	xyd.setAvatarClip(arg_6_0:nodeByName(arg_6_0.enSide .. "_avatar"), arg_6_0.enemy.avatar, 1)

	local var_6_2 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarFrameId] .. ".png"

	if arg_6_0.enemy.frame and arg_6_0.enemy.frame ~= 0 then
		var_6_2 = "images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_6_0.enemy.frame] .. ".png"
	end

	local var_6_3 = xyd.AssetLoader.get():loadSprite(var_6_2)

	var_6_3:setPosition(37.5, 37.5)
	arg_6_0:nodeByName(arg_6_0.enSide .. "_avatar_border"):addChild(var_6_3)
	arg_6_0:nodeByName(arg_6_0.enSide .. "_name_text"):setString(arg_6_0.enemy.name)

	if arg_6_0.mine.isWin == 1 then
		arg_6_0:nodeByName(arg_6_0.enSide .. "_win_bg"):setVisible(false)
		arg_6_0:nodeByName(arg_6_0.side .. "_fail_bg"):setVisible(false)
	else
		arg_6_0:nodeByName(arg_6_0.enSide .. "_fail_bg"):setVisible(false)
		arg_6_0:nodeByName(arg_6_0.side .. "_win_bg"):setVisible(false)
	end
end

function var_0_0.addHeroCells(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = true

	for iter_11_0, iter_11_1 in pairs(arg_11_2.heroIds) do
		local var_11_1 = display.newNode()
		local var_11_2 = cc.p(55, 55)

		var_11_1:setContentSize(var_11_2)

		local var_11_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/avatar.csb")

		var_11_3:setScale(0.7, 0.7)

		local var_11_4 = arg_11_2.awakeStages[iter_11_0] == xyd.AwakeTwiceStage.COMPLETE

		xyd.setAvatarBorder(iter_11_1, var_11_3:getChildByName("avatar"), arg_11_2.heroColors[iter_11_0], arg_11_2.heroStars[iter_11_0], var_11_4, false, arg_11_2.skinIds[iter_11_0])
		var_11_3:getChildByName("lv_txt"):setString(arg_11_2.heroLevs[iter_11_0])

		local var_11_5 = var_11_3:getChildByName("hp_bar")
		local var_11_6 = var_11_3:getChildByName("hp_di")
		local var_11_7 = var_11_3:getChildByName("mp_bar")
		local var_11_8 = var_11_3:getChildByName("mp_di")
		local var_11_9 = var_11_3:getChildByName("dead_text")

		var_11_9:setString(var_0_1:translation("ALREADY_DEAD"))

		if var_11_9 then
			var_11_9:setVisible(false)
		end

		local var_11_10 = false
		local var_11_11 = false
		local var_11_12 = 0
		local var_11_13 = var_11_3:getChildByName("avatar_mask")

		var_11_13:setLocalZOrder(2)

		if arg_11_2.totalHps and next(arg_11_2.totalHps) and arg_11_2.hps and next(arg_11_2.hps) then
			if arg_11_2.hps[iter_11_0] == 0 then
				var_11_10 = true
			elseif arg_11_2.hps[iter_11_0] ~= -1 and arg_11_2.totalHps[iter_11_0] ~= -1 then
				var_11_11 = true
				var_11_12 = arg_11_2.hps[iter_11_0]
			end
		end

		if arg_11_2.mps and arg_11_2.mps[iter_11_0] then
			if arg_11_2.mps[iter_11_0] == -1 then
				var_11_7:setPercent(100)
			else
				mpPercent = arg_11_2.mps[iter_11_0] / xyd.ENERGY_DECIMAL_BASE * 100

				var_11_7:setPercent(mpPercent)
			end
		else
			var_11_7:setPercent(100)
		end

		if var_11_10 then
			var_11_5:setVisible(false)
			var_11_7:setVisible(false)
			var_11_6:setVisible(false)
			var_11_8:setVisible(false)
			var_11_9:setVisible(true)
			var_11_13:setVisible(true)
		elseif var_11_11 then
			var_11_5:setVisible(true)
			var_11_7:setVisible(true)
			var_11_6:setVisible(true)
			var_11_8:setVisible(true)
			var_11_9:setVisible(false)
			var_11_13:setVisible(false)

			hpPercent = var_11_12 / arg_11_2.totalHps[iter_11_0] * 100

			var_11_5:setPercent(hpPercent)

			var_11_0 = false
		else
			var_11_5:setVisible(true)
			var_11_7:setVisible(true)
			var_11_6:setVisible(true)
			var_11_8:setVisible(true)
			var_11_9:setVisible(false)
			var_11_13:setVisible(false)
			var_11_5:setPercent(100)

			var_11_0 = false
		end

		var_11_1:addChild(var_11_3)
		arg_11_0:nodeByName(arg_11_1 .. "_" .. iter_11_0):addChild(var_11_1)
	end

	if arg_11_2.pet and arg_11_2.pet.table_id then
		local var_11_14 = var_0_4.new()
		local var_11_15 = {
			table_id = arg_11_2.pet.table_id,
			star = arg_11_2.pet.star,
			lev = arg_11_2.pet.lev,
			color = arg_11_2.pet.color
		}

		var_11_14:populate(var_11_15)

		local var_11_16 = display.newNode()
		local var_11_17 = cc.p(55, 55)

		var_11_16:setContentSize(var_11_17)

		local var_11_18 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/fight_state/avatar.csb")

		var_11_18:setScale(0.7, 0.7)
		xyd.setAvatarBorder(var_11_14, var_11_18:getChildByName("avatar"), arg_11_2.pet.color, arg_11_2.pet.star)
		var_11_18:getChildByName("lv_txt"):setString(arg_11_2.pet.lev)
		var_11_18:getChildByName("hp_bar"):setVisible(false)
		var_11_18:getChildByName("hp_di"):setVisible(false)
		var_11_18:getChildByName("mp_bar"):setVisible(false)
		var_11_18:getChildByName("mp_di"):setVisible(false)

		local var_11_19 = var_11_18:getChildByName("dead_text")
		local var_11_20 = var_11_18:getChildByName("avatar_mask")

		var_11_19:setString(var_0_1:translation("ALREADY_DEAD"))

		if var_11_19 then
			if var_11_0 then
				var_11_19:setVisible(true)
				var_11_20:setVisible(true)
			else
				var_11_19:setVisible(false)
				var_11_20:setVisible(false)
			end
		end

		var_11_20:setLocalZOrder(2)
		var_11_16:addChild(var_11_18)
		arg_11_0:nodeByName(arg_11_1 .. "_pet"):addChild(var_11_16)

		local var_11_21 = #arg_11_2.heroIds + 1

		if var_11_21 <= 5 and var_11_21 >= 1 then
			arg_11_0:nodeByName(arg_11_1 .. "_pet"):setPositionX(arg_11_0:nodeByName(arg_11_1 .. "_" .. var_11_21):getPositionX())
		end
	end
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super:willClose(arg_12_1)
end

return var_0_0
