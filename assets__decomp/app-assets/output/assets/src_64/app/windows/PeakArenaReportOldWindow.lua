local var_0_0 = class("PeakArenaReportWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("app.model.Pet")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.reports = arg_1_2.reports
	arg_1_0.herosA = {}
	arg_1_0.herosB = {}
	arg_1_0.petsA = {}
	arg_1_0.petsB = {}

	if arg_1_2.win == arg_1_2.isAttack then
		arg_1_0.isAttackWin = true
	else
		arg_1_0.isAttackWin = false
	end

	arg_1_0.isWin = arg_1_2.win
	arg_1_0.isCasual = arg_1_2.is_casual
	arg_1_0.attackerName = arg_1_2.attackerName
	arg_1_0.attackerLev = arg_1_2.attackerLev
	arg_1_0.attackerConquerLev = arg_1_2.attackerConquerLev
	arg_1_0.attackerConquerLoopID = arg_1_2.attackerConquerLoopID
	arg_1_0.defenderConquerLev = arg_1_2.defenderConquerLev
	arg_1_0.defenderConquerLoopID = arg_1_2.defenderConquerLoopID
	arg_1_0.attackerAvatar = tonumber(arg_1_2.attackerAvatar)
	arg_1_0.attackerAvatarFrame = tonumber(arg_1_2.attackerAvatarFrame)
	arg_1_0.defenderName = arg_1_2.defenderName
	arg_1_0.defenderLev = arg_1_2.defenderLev
	arg_1_0.defenderAvatar = tonumber(arg_1_2.defenderAvatar)
	arg_1_0.defenderAvatarFrame = tonumber(arg_1_2.defenderAvatarFrame)
	arg_1_0.withWin = arg_1_2.withWin
	arg_1_0.awards = arg_1_2.awards

	if not arg_1_0.attackerAvatar or arg_1_0.attackerAvatar == 0 or arg_1_0.attackAvatar == "0" or arg_1_0.attackAvatar == "0.0" then
		arg_1_0.attackerAvatar = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
	end

	if not arg_1_0.defenderAvatar or arg_1_0.defenderAvatar == 0 or arg_1_0.defenderAvatar == "0" or arg_1_0.defenderAvatar == "0.0" then
		arg_1_0.defenderAvatar = xyd.tables.avatar.icon_[xyd.tables.misc.defaultAvatarId]
	end

	arg_1_0.peakArena = xyd.ModelManager.get():loadModel(xyd.ModelType.PEAK_ARENA_OLD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	if arg_2_0.reports and next(arg_2_0.reports) ~= nil then
		arg_2_0.reportNum = #arg_2_0.reports
		arg_2_0.reportList = cc.ui.UIListView.new({
			viewRect = cc.rect(1, 1, 1135, 500),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

		arg_2_0.reportList:setAnchorPoint(cc.p(0, 0))
		arg_2_0.reportList:setPosition(0, -290)
		arg_2_0:nodeByName("bg"):height(560)
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.reports) do
		arg_2_0:initHeros(iter_2_1.content, iter_2_0)
	end

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 10 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.layout(arg_5_0)
	if not arg_5_0.reports or next(arg_5_0.reports) == nil then
		return
	end

	for iter_5_0 = 1, #arg_5_0.reports do
		if arg_5_0.reports[iter_5_0] ~= nil then
			local var_5_0 = display.newNode()
			local var_5_1 = arg_5_0.reportList:newItem()
			local var_5_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/arena_share/share_item_pet.csb")
			local var_5_3 = var_5_2:getChildByName("background")

			var_5_2:setAnchorPoint(cc.p(0, 0))
			var_5_2:setPosition(0, 0)
			var_5_2:addTo(var_5_0)
			var_5_3:getChildByName("battle_num"):setVisible(false)
			var_5_3:getChildByName("left_name_txt"):setString(arg_5_0.attackerName)
			var_5_3:getChildByName("right_name_txt"):setString(arg_5_0.defenderName)

			if arg_5_0.attackerConquerLev and arg_5_0.attackerConquerLev > 0 then
				xyd.setConquerLev(arg_5_0.attackerConquerLev, var_5_3:getChildByName("left_lev"), var_5_3:getChildByName("left_dengjiquan"), nil, nil, nil, nil, arg_5_0.attackerConquerLoopID)
			else
				var_5_3:getChildByName("left_lev"):setString(arg_5_0.attackerLev)
			end

			if arg_5_0.defenderConquerLev and arg_5_0.defenderConquerLev > 0 then
				xyd.setConquerLev(arg_5_0.defenderConquerLev, var_5_3:getChildByName("right_lev"), var_5_3:getChildByName("right_dengjiquan"), nil, nil, nil, nil, arg_5_0.defenderConquerLoopID)
			else
				var_5_3:getChildByName("right_lev"):setString(arg_5_0.defenderLev)
			end

			var_5_3:getChildByName("battle_num"):setString(string.format(xyd.tables.translation:translation("SUPER_ARENA_TITLE"), tostring(iter_5_0)))
			var_5_3:getChildByName("battle_num"):setVisible(true)

			if arg_5_0.reports[iter_5_0].win == 1 then
				var_5_3:getChildByName("piaodai_green_left"):setVisible(true)
				var_5_3:getChildByName("piaodai_red_left"):setVisible(false)
				var_5_3:getChildByName("piaodai_red_right"):setVisible(true)
				var_5_3:getChildByName("piaodai_green_right"):setVisible(false)
			else
				var_5_3:getChildByName("piaodai_green_left"):setVisible(false)
				var_5_3:getChildByName("piaodai_red_left"):setVisible(true)
				var_5_3:getChildByName("piaodai_red_right"):setVisible(false)
				var_5_3:getChildByName("piaodai_green_right"):setVisible(true)
			end

			local var_5_4 = 90
			local var_5_5 = 90

			xyd.setPlayerAvatar(var_5_3:getChildByName("left_avatar"), {
				avatar_id = arg_5_0.attackerAvatar,
				avatar_frame_id = arg_5_0.attackerAvatarFrame
			})
			xyd.setPlayerAvatar(var_5_3:getChildByName("right_avatar"), {
				avatar_id = arg_5_0.defenderAvatar,
				avatar_frame_id = arg_5_0.defenderAvatarFrame
			})

			for iter_5_1 = 1, #arg_5_0.petsA[iter_5_0] do
				local var_5_6 = var_5_3:getChildByName("pet1")
				local var_5_7 = arg_5_0.petsA[iter_5_0][1]

				xyd.setPetAvatar(var_5_6, var_5_7, nil, true)
				var_5_6:setScale(0.65, 0.65)
			end

			for iter_5_2 = 1, #arg_5_0.petsB[iter_5_0] do
				local var_5_8 = var_5_3:getChildByName("pet2")
				local var_5_9 = arg_5_0.petsB[iter_5_0][1]

				xyd.setPetAvatar(var_5_8, var_5_9, nil, true)
				var_5_8:setScale(0.65, 0.65)
			end

			local var_5_10 = 0

			for iter_5_3 = 1, #arg_5_0.herosA[iter_5_0] do
				var_5_10 = var_5_10 + 1

				local var_5_11 = var_5_3:getChildByName("icon" .. var_5_10)
				local var_5_12 = arg_5_0.herosA[iter_5_0][iter_5_3]
				local var_5_13 = var_5_12:getColor()
				local var_5_14 = var_5_12:getStar()
				local var_5_15 = var_5_12:getLevel()
				local var_5_16 = xyd.setAvatarBorderWithLevelAndHp(var_5_12, var_5_11, var_5_13, var_5_14, var_5_15)
				local var_5_17 = xyd.AssetLoader.get():loadSprite("windows/common/lv_di.png")
				local var_5_18 = var_5_4 / 90
				local var_5_19 = {
					size = 12
				}
			end

			local var_5_20 = 0

			for iter_5_4 = 1, #arg_5_0.herosB[iter_5_0] do
				var_5_20 = var_5_20 + 1

				local var_5_21 = var_5_3:getChildByName("icon" .. var_5_20 + 5)
				local var_5_22 = arg_5_0.herosB[iter_5_0][iter_5_4]
				local var_5_23 = var_5_22:getColor()
				local var_5_24 = var_5_22:getStar()
				local var_5_25 = var_5_22:getLevel()
				local var_5_26 = xyd.setAvatarBorderWithLevelAndHp(var_5_22, var_5_21, var_5_23, var_5_24, var_5_25)
				local var_5_27 = var_5_4 / 90
				local var_5_28 = {
					size = 12
				}
			end

			var_5_3:getChildByName("replay_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					arg_5_0:replayRecord(arg_5_0.reports[iter_5_0])
				end
			end)
			var_5_3:getChildByName("data_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
				if arg_7_1 == ccui.TouchEventType.ended then
					arg_5_0:replayRecord(arg_5_0.reports[iter_5_0], true)
				end
			end)
			var_5_0:setContentSize(var_5_3:getWidth(), var_5_3:getHeight())
			var_5_1:addContent(var_5_0)
			var_5_1:setItemSize(var_5_3:getWidth(), var_5_3:getHeight())
			arg_5_0.reportList:addItem(var_5_1)
		else
			return
		end
	end

	arg_5_0.reportList:reload()

	if arg_5_0.withWin then
		arg_5_0:addResultEffectLayer(arg_5_0.isWin)

		arg_5_0.withWin = false
	end

	if arg_5_0.awards and #arg_5_0.awards ~= 0 then
		arg_5_0.selfPlayer:handleRewards(arg_5_0.awards)

		arg_5_0.awards = nil
		arg_5_0.params.awards = nil
	end
end

function var_0_0.playEffect(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6)
	local var_8_0
	local var_8_1 = arg_8_5 or false
	local var_8_2 = arg_8_2 .. ".json"
	local var_8_3 = arg_8_2 .. ".atlas"
	local var_8_4 = var_0_3.new(var_8_2, var_8_3, 1)

	arg_8_1:addChild(var_8_4, arg_8_6)
	var_8_4:pos(arg_8_3.x, arg_8_3.y)

	if arg_8_4 == true then
		var_8_4:setToSetupPose()
		var_8_4:setVisible(true)

		if var_8_1 then
			var_8_4:play(function()
				return
			end, true)
		else
			var_8_4:play(function()
				var_8_4:setVisible(true)
			end)
		end
	else
		var_8_4:setVisible(false)
	end
end

function var_0_0.addResultEffectLayer(arg_11_0, arg_11_1)
	local var_11_0 = cc.c4b(0, 0, 0, 200)
	local var_11_1 = 2

	arg_11_0.effectLayer = display.newColorLayer(var_11_0)

	local var_11_2 = arg_11_0:convertToWorldSpace(cc.p(0, 0))

	arg_11_0.effectLayer:pos(-var_11_2.x, -var_11_2.y - 100):addTo(arg_11_0, var_11_1)
	arg_11_0.effectLayer:setName("effect_layer")
	arg_11_0.effectLayer:setTouchEnabled(true)
	arg_11_0.effectLayer:setTouchSwallowEnabled(true)

	local var_11_3 = {
		x = xyd.STAGE_WIDTH / 2,
		y = xyd.STAGE_HEIGHT / 2
	}

	if arg_11_1 == 1 then
		arg_11_0:playEffect(arg_11_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win_spin", var_11_3, true, true, 10)
		arg_11_0:playEffect(arg_11_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_win", var_11_3, true, false, 20)
	else
		arg_11_0:playEffect(arg_11_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat_spin", var_11_3, true, true, 10)
		arg_11_0:playEffect(arg_11_0.effectLayer, "skeletons/ui_effect/douniu_effect/douniu_effect_defeat", var_11_3, true, false, 20)
	end

	arg_11_0.effectLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			local var_12_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_0, false)
			arg_11_0:removeChildByName("effect_layer")

			return true
		elseif arg_12_0.name == "ended" then
			local var_12_1 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_12_1, false)
			arg_11_0:removeChildByName("effect_layer")
		end
	end)
end

function var_0_0.initHeros(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0 = arg_13_1

	arg_13_0.jsonData_ = json.decode(var_13_0)

	local var_13_1 = {}
	local var_13_2 = {}
	local var_13_3 = {}
	local var_13_4 = {}

	ngx.ctx.battle.reportData = arg_13_0.jsonData_

	for iter_13_0, iter_13_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_13_5 = string.sub(iter_13_0, 1, 1)
		local var_13_6 = tonumber(string.sub(iter_13_0, 3, 3))

		if var_13_5 == "A" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.None then
			local var_13_7 = var_0_1.new()

			var_13_7:populate(iter_13_1.hero)
			var_13_7:setReportData(iter_13_1)

			var_13_1[var_13_6] = var_13_7
		elseif var_13_5 == "A" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_13_8 = var_0_2.new()

			var_13_8:populate(iter_13_1.hero)
			var_13_8:setReportData(iter_13_1)

			var_13_3[1] = var_13_8
		elseif var_13_5 == "B" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.None then
			local var_13_9 = var_0_1.new()

			var_13_9:populate(iter_13_1.hero)
			var_13_9:setReportData(iter_13_1)

			var_13_2[var_13_6] = var_13_9
		elseif var_13_5 == "B" and tonumber(iter_13_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_13_10 = var_0_2.new()

			var_13_10:populate(iter_13_1.hero)
			var_13_10:setReportData(iter_13_1)

			var_13_4[1] = var_13_10
		elseif tonumber(iter_13_1.summon_type) ~= xyd.summonMonsterType.None then
			-- block empty
		end
	end

	arg_13_0.herosA[arg_13_2] = var_13_1
	arg_13_0.herosB[arg_13_2] = var_13_2
	arg_13_0.petsA[arg_13_2] = var_13_3
	arg_13_0.petsB[arg_13_2] = var_13_4
end

function var_0_0.replayRecord(arg_14_0, arg_14_1, arg_14_2)
	if arg_14_1 == nil or next(arg_14_1) == nil then
		if xyd.WindowManager.get():getWindow("toast") ~= nil then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = stringLocalizer:translation("ARENA_RECORD_OUT_OF_DATE")
		})

		return
	end

	local var_14_0 = {}
	local var_14_1 = json.decode(arg_14_1.content)

	var_14_0.herosA = {}
	var_14_0.herosB = {}
	var_14_0.summonMonsters = {}
	var_14_0.campaignType = xyd.CampaignType.ARENA

	if not arg_14_0.isCasual then
		var_14_0.battleID = xyd.MapBattleID.PEAK_ARENA
	else
		var_14_0.battleID = xyd.MapBattleID.ARENA
		var_14_0.campaignType = xyd.CampaignType.REGION_CASUAL
	end

	var_14_0.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_14_1

	local var_14_2 = {}

	for iter_14_0, iter_14_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_14_3 = string.sub(iter_14_0, 1, 1)
		local var_14_4 = tonumber(string.sub(iter_14_0, 3, 3))

		if var_14_3 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
			local var_14_5 = var_0_1.new()

			var_14_5:populate(iter_14_1.hero)
			var_14_5:setReportData(iter_14_1)

			if arg_14_2 then
				var_14_5.harms = iter_14_1.harms
				var_14_5.willDie = (iter_14_1.die_count or 0) ~= -1
			end

			var_14_0.herosA[var_14_4] = var_14_5
		elseif var_14_3 == "A" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_14_6 = var_0_2.new()

			var_14_6:populate(iter_14_1.hero)
			var_14_6:setReportData(iter_14_1)

			if arg_14_2 then
				var_14_6.harms = iter_14_1.harms
				var_14_6.willDie = (iter_14_1.die_count or 0) ~= -1
				var_14_0.petA = {
					var_14_6
				}
			else
				var_14_0.petsA = {
					var_14_6
				}
			end
		elseif var_14_3 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.None then
			local var_14_7 = var_0_1.new()

			var_14_7:populate(iter_14_1.hero)
			var_14_7:setReportData(iter_14_1)

			if arg_14_2 then
				var_14_7.harms = iter_14_1.harms
				var_14_7.willDie = (iter_14_1.die_count or 0) ~= -1
				var_14_0.herosB[var_14_4] = var_14_7
			else
				var_14_2[var_14_4] = var_14_7
			end
		elseif var_14_3 == "B" and tonumber(iter_14_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_14_8 = var_0_2.new()

			var_14_8:populate(iter_14_1.hero)
			var_14_8:setReportData(iter_14_1)

			if arg_14_2 then
				var_14_8.harms = iter_14_1.harms
				var_14_8.willDie = (iter_14_1.die_count or 0) ~= -1
				var_14_0.petB = {
					var_14_8
				}
			else
				var_14_0.petsB = {
					var_14_8
				}
			end
		elseif tonumber(iter_14_1.summon_type) ~= xyd.summonMonsterType.None then
			local var_14_9 = var_0_1.new()

			var_14_9:populate(iter_14_1.hero)
			var_14_9:setReportData(iter_14_1)

			var_14_0.summonMonsters[iter_14_0] = var_14_9
		end
	end

	if arg_14_2 then
		var_14_0.isBeforeBattle = true

		xyd.WindowManager.get():openWindow(xyd.WindowName.battleResultDataWnd, var_14_0)
	else
		var_14_0.herosB = {
			var_14_2
		}
		var_14_0.reportStar = tonumber(var_14_1.star)

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
			params = {
				window = xyd.WindowName.peakArenaReportsWnd,
				status = arg_14_0.params
			}
		})
		xyd.WindowManager.get():retainHistory()
		arg_14_0.peakArena:clearTotalResult()
		xyd.pushBattleScene(var_14_0)
	end
end

return var_0_0
