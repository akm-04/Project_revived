local var_0_0 = class("ArenaShareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.attackerName = arg_1_2.attackerName
	arg_1_0.attackerLev = arg_1_2.attackerLev
	arg_1_0.attackerAvatar = tonumber(arg_1_2.attackerAvatar)
	arg_1_0.attackerAvatarFrame = tonumber(arg_1_2.attackerAvatarFrame)
	arg_1_0.defenderName = arg_1_2.defenderName
	arg_1_0.defenderLev = arg_1_2.defenderLev
	arg_1_0.defenderAvatar = tonumber(arg_1_2.defenderAvatar)
	arg_1_0.defenderAvatarFrame = tonumber(arg_1_2.defenderAvatarFrame)
	arg_1_0.herosA = {}
	arg_1_0.herosB = {}

	if arg_1_2.win == arg_1_2.isAttack then
		arg_1_0.isAttackWin = true
	else
		arg_1_0.isAttackWin = false
	end

	arg_1_0.report = arg_1_2.report

	if not arg_1_0.attackerAvatar or arg_1_0.attackerAvatar == 0 or arg_1_0.attackAvatar == "0" or arg_1_0.attackAvatar == "0.0" then
		arg_1_0.attackerAvatar = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
	end

	if not arg_1_0.defenderAvatar or arg_1_0.defenderAvatar == 0 or arg_1_0.defenderAvatar == "0" or arg_1_0.defenderAvatar == "0.0" then
		arg_1_0.defenderAvatar = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:initHeros(arg_2_0.report[1].content)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena_share/share_item.csb")
	local var_4_1 = var_4_0:getChildByName("background")

	var_4_0:setContentSize(var_4_1:getContentSize())
	var_4_0:addTo(arg_4_0:nodeByName("list"))
	var_4_0:setAnchorPoint(cc.p(0, 0))
	var_4_0:setPosition(0, 0)
	var_4_1:getChildByName("battle_num"):setVisible(false)
	var_4_1:getChildByName("left_name_txt"):setString(arg_4_0.attackerName)
	var_4_1:getChildByName("right_name_txt"):setString(arg_4_0.defenderName)
	var_4_1:getChildByName("left_lev"):setString(arg_4_0.attackerLev)
	var_4_1:getChildByName("right_lev"):setString(arg_4_0.defenderLev)

	if arg_4_0.isAttackWin then
		var_4_1:getChildByName("piaodai_green_left"):setVisible(true)
		var_4_1:getChildByName("piaodai_red_left"):setVisible(false)
		var_4_1:getChildByName("piaodai_red_right"):setVisible(true)
		var_4_1:getChildByName("piaodai_green_right"):setVisible(false)
	else
		var_4_1:getChildByName("piaodai_green_left"):setVisible(false)
		var_4_1:getChildByName("piaodai_red_left"):setVisible(true)
		var_4_1:getChildByName("piaodai_red_right"):setVisible(false)
		var_4_1:getChildByName("piaodai_green_right"):setVisible(true)
	end

	local var_4_2 = 90
	local var_4_3 = 90

	xyd.setPlayerAvatar(var_4_1:getChildByName("left_avatar"), {
		avatar_id = arg_4_0.attackerAvatar,
		avatar_frame_id = arg_4_0.attackerAvatarFrame
	})
	xyd.setPlayerAvatar(var_4_1:getChildByName("right_avatar"), {
		avatar_id = arg_4_0.defenderAvatar,
		avatar_frame_id = arg_4_0.defenderAvatarFrame
	})

	local var_4_4 = 0

	for iter_4_0 = 1, #arg_4_0.herosA do
		var_4_4 = var_4_4 + 1

		local var_4_5 = var_4_1:getChildByName("icon" .. var_4_4)
		local var_4_6 = arg_4_0.herosA[iter_4_0]
		local var_4_7 = var_4_6:getColor()
		local var_4_8 = var_4_6:getStar()
		local var_4_9 = var_4_6:getLevel()
		local var_4_10 = xyd.setAvatarBorderWithLevelAndHp(var_4_6, var_4_5, var_4_7, var_4_8, var_4_9)
		local var_4_11 = var_4_2 / 90
		local var_4_12 = {
			size = 12
		}
	end

	local var_4_13 = 0

	for iter_4_1 = 1, #arg_4_0.herosB do
		var_4_13 = var_4_13 + 1

		local var_4_14 = var_4_1:getChildByName("icon" .. var_4_13 + 5)
		local var_4_15 = arg_4_0.herosB[iter_4_1]
		local var_4_16 = var_4_15:getColor()
		local var_4_17 = var_4_15:getStar()
		local var_4_18 = var_4_15:getLevel()
		local var_4_19 = xyd.setAvatarBorderWithLevelAndHp(var_4_15, var_4_14, var_4_16, var_4_17, var_4_18)
		local var_4_20 = var_4_2 / 90
		local var_4_21 = {
			size = 12
		}
	end

	var_4_1:getChildByName("replay_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:replayRecord(arg_4_0.report)
		end
	end)
	var_4_1:getChildByName("data_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			arg_4_0:replayRecord(arg_4_0.report, true)
		end
	end)
end

function var_0_0.initHeros(arg_7_0, arg_7_1)
	local var_7_0 = json.decode(arg_7_1)
	local var_7_1 = {}
	local var_7_2 = {}

	for iter_7_0, iter_7_1 in pairs(var_7_0.fighter) do
		local var_7_3 = string.sub(iter_7_0, 1, 1)
		local var_7_4 = tonumber(string.sub(iter_7_0, 3, 3))

		if var_7_3 == "A" and tonumber(iter_7_1.summon_type) == xyd.summonMonsterType.None then
			local var_7_5 = var_0_1.new()

			var_7_5:populate(iter_7_1.hero)
			var_7_5:setReportData(iter_7_1)
			table.insert(arg_7_0.herosA, var_7_5)
		elseif var_7_3 == "B" and tonumber(iter_7_1.summon_type) == xyd.summonMonsterType.None then
			local var_7_6 = var_0_1.new()

			var_7_6:populate(iter_7_1.hero)
			var_7_6:setReportData(iter_7_1)
			table.insert(arg_7_0.herosB, var_7_6)
		elseif tonumber(iter_7_1.summon_type) ~= xyd.summonMonsterType.None then
			-- block empty
		end
	end
end

function var_0_0.replayRecord(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_1 == nil or next(arg_8_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = stringLocalizer:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_8_0 = {}
	local var_8_1 = json.decode(arg_8_1[1].content)

	var_8_0.herosA = {}
	var_8_0.herosB = {}
	var_8_0.summonMonsters = {}
	var_8_0.campaignType = xyd.CampaignType.ARENA
	var_8_0.battleID = xyd.MapBattleID.ARENA
	var_8_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_8_1

	local var_8_2 = {}
	local var_8_3 = {}

	for iter_8_0, iter_8_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_8_4 = string.sub(iter_8_0, 1, 1)
		local var_8_5 = tonumber(string.sub(iter_8_0, 3, 3))

		if var_8_4 == "A" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.None then
			local var_8_6 = var_0_1.new()

			var_8_6:populate(iter_8_1.hero)
			var_8_6:setReportData(iter_8_1)

			if arg_8_2 then
				var_8_6.harms = iter_8_1.harms
				var_8_6.willDie = (iter_8_1.die_count or 0) ~= -1
			end

			var_8_0.herosA[var_8_5] = var_8_6
		elseif var_8_4 == "A" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_8_7 = var_0_2.new()

			var_8_7:populate(iter_8_1.hero)
			var_8_7:setReportData(iter_8_1)

			if arg_8_2 then
				var_8_7.harms = iter_8_1.harms
				var_8_7.willDie = (iter_8_1.die_count or 0) ~= -1
				var_8_0.petA = {
					var_8_7
				}
			else
				var_8_0.petsA = {
					var_8_7
				}
			end
		elseif var_8_4 == "B" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.None then
			local var_8_8 = var_0_1.new()

			var_8_8:populate(iter_8_1.hero)
			var_8_8:setReportData(iter_8_1)

			if arg_8_2 then
				var_8_8.harms = iter_8_1.harms
				var_8_8.willDie = (iter_8_1.die_count or 0) ~= -1
				var_8_0.herosB[var_8_5] = var_8_8
			else
				var_8_2[var_8_5] = var_8_8
			end
		elseif var_8_4 == "B" and tonumber(iter_8_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_8_9 = var_0_2.new()

			var_8_9:populate(iter_8_1.hero)
			var_8_9:setReportData(iter_8_1)

			if arg_8_2 then
				var_8_9.harms = iter_8_1.harms
				var_8_9.willDie = (iter_8_1.die_count or 0) ~= -1
				var_8_0.petB = {
					var_8_9
				}
			else
				var_8_0.petsB = {
					var_8_9
				}
			end
		elseif tonumber(iter_8_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_8_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_8_10 = var_0_1.new()

			var_8_10:populate(iter_8_1.hero)
			var_8_10:setReportData(iter_8_1)

			var_8_3[iter_8_0] = var_8_10
		end
	end

	if arg_8_2 then
		collectgarbage("collect")

		var_8_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_8_0)
	else
		var_8_0.herosB = {
			var_8_2
		}
		var_8_0.summonMonsters = var_8_3
		var_8_0.reportStar = tonumber(var_8_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.arenaRecordWnd
			}
		})
		xyd.WindowManager.get():retainHistory()
		xyd.pushBattleScene(var_8_0)
	end
end

return var_0_0
