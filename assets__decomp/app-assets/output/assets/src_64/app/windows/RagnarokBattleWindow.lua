local var_0_0 = class("RagnarokBattleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc
local var_0_3 = xyd.tables.ragnarokBoss
local var_0_4 = xyd.tables.hero
local var_0_5 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.ragnarok = xyd.ModelManager.get():loadModel(xyd.ModelType.RAGNAROK)
	arg_1_0.model = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar({
		isEcoBar = 0,
		show_rule = true,
		callback = handler(arg_2_0, arg_2_0.close)
	})
	arg_2_0:layout()
	arg_2_0.ragnarok:getHeros()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_boss"):setString(var_0_1:translation("RAGNAROK_BOSS_1"))
	arg_3_0:nodeByName("txt_name_2"):setString(var_0_1:translation("RAGNAROK_BOSS_2"))
	arg_3_0:nodeByName("txt_name_3"):setString(var_0_1:translation("RAGNAROK_BOSS_2"))
	arg_3_0:nodeByName("txt_time"):setString(var_0_1:translation("RAGNAROK_BOSS_13"))
	arg_3_0:nodeByName("txt_boss"):enableOutline(cc.c4b(86, 33, 109, 255), 2)
	arg_3_0:nodeByName("txt_name_2"):enableOutline(cc.c4b(86, 33, 109, 255), 2)
	arg_3_0:nodeByName("txt_name_3"):enableOutline(cc.c4b(86, 33, 109, 255), 2)

	for iter_3_0 = 1, var_0_5 do
		arg_3_0:nodeByName("txt_team_" .. iter_3_0):enableOutline(cc.c4b(65, 74, 84, 255), 2)
	end

	if arg_3_0.ragnarok:getType() == xyd.RagnarokType.SINGLE then
		arg_3_0.data = {}
		arg_3_0.data[1] = {
			player_id = arg_3_0.selfPlayer.playerID,
			player_name = arg_3_0.selfPlayer.playerName,
			lev = arg_3_0.selfPlayer.lev,
			avatar_id = arg_3_0.selfPlayer:getMyCurrentAvatarID(),
			avatar_frame_id = arg_3_0.selfPlayer.avatarFrame,
			conquer_lev = arg_3_0.selfPlayer.conquerLev,
			conquer_loop_id = arg_3_0.selfPlayer.conquerLoopID
		}

		for iter_3_1 = 1, var_0_5 do
			arg_3_0:nodeByName("txt_team_" .. iter_3_1):setString(var_0_1:translation("RAGNAROK_BOSS_" .. iter_3_1 + 9))
			arg_3_0:nodeByName("txt_no_" .. iter_3_1):setString(var_0_1:translation("RAGNAROK_BOSS_" .. iter_3_1 + 9))
			arg_3_0:nodeByName("icon_battle" .. iter_3_1):setVisible(false)
			arg_3_0:initPlayerInfo(iter_3_1, arg_3_0.data[iter_3_1])
			arg_3_0:setEnemyClick(iter_3_1)
		end

		arg_3_0:nodeByName("btn_chat"):setVisible(false)
	elseif arg_3_0.ragnarok:getType() == xyd.RagnarokType.TEAM then
		for iter_3_2 = 1, var_0_5 do
			arg_3_0:nodeByName("txt_team_" .. iter_3_2):setString(var_0_1:translation("RAGNAROK_BOSS_" .. iter_3_2 + 6))
			arg_3_0:nodeByName("txt_no_" .. iter_3_2):setString(var_0_1:translation("RAGNAROK_BOSS_" .. iter_3_2 + 6))
			arg_3_0:nodeByName("icon_battle" .. iter_3_2):setVisible(false)
			arg_3_0:initPlayerInfo(iter_3_2, arg_3_0.ragnarok:getPlayerInfoByPos(iter_3_2))
		end

		arg_3_0:setEnemyClick(arg_3_0.ragnarok:getPos())
		arg_3_0:updateFightStatus()
	end

	for iter_3_3 = 1, var_0_5 do
		local var_3_0 = var_0_3:monsterId(arg_3_0.ragnarok:getType(), iter_3_3)
		local var_3_1 = var_0_4:modelID(var_3_0)
		local var_3_2 = xyd.HeroAnimation.new(nil, var_3_1, 0.6, {})

		var_3_2:addTo(arg_3_0:nodeByName("pos_enemy" .. iter_3_3))
		var_3_2:idle(true)

		if iter_3_3 > 1 then
			var_3_2:setPosition(-50, 0)
		end

		arg_3_0.model[iter_3_3] = var_3_2
	end

	arg_3_0:showChatWin()
	arg_3_0:initButton()
	arg_3_0:updateMonsterStatus()
	arg_3_0:updatePlayerBattleStatus()
	arg_3_0:updatePlayerInfo()
end

function var_0_0.initButton(arg_4_0)
	arg_4_0:nodeByName("btn_chat"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0:showChatWin()
			arg_4_0.ragnarok:setChatRedPoint(false)
			arg_4_0:updateRedMark(arg_4_0.ragnarok:getChatRedPoint())
		end
	end)

	local var_4_0 = arg_4_0:nodeByName("top_sidebar"):nodeByName("rule")

	xyd.nodeEventSample(var_4_0, nil, function()
		local var_6_0 = {}

		var_6_0.title_name = "RAGNAROK_BOSS_RULE_TITLE_2"
		var_6_0.rule = "RAGNAROK_BOSS_RULE_TEXT_2"
		var_6_0.style = xyd.RuleStyle.PURPLE

		xyd.WindowManager.get():openWindow("new_text_rule", var_6_0)
	end)
	arg_4_0:nodeByName("buff1"):setTouchEnabled(true)
	arg_4_0:nodeByName("buff1"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
		if arg_7_0.name == "began" then
			return true
		elseif arg_7_0.name == "ended" then
			local var_7_0 = var_0_1:translation("RAGNAROK_BOSS_31")
			local var_7_1 = arg_4_0:nodeByName("buff1"):getPositionY()

			xyd.WindowManager.get():openWindow("toast", {
				message = var_7_0
			}):setPositionY(var_7_1 + 80)
		end
	end)
	arg_4_0:nodeByName("buff2"):setTouchEnabled(true)
	arg_4_0:nodeByName("buff2"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			return true
		elseif arg_8_0.name == "ended" then
			local var_8_0 = var_0_1:translation("RAGNAROK_BOSS_32")
			local var_8_1 = arg_4_0:nodeByName("buff2"):getPositionY()

			xyd.WindowManager.get():openWindow("toast", {
				message = var_8_0
			}):setPositionY(var_8_1 - 80)
		end
	end)
end

function var_0_0.setEnemyClick(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("touch_enemy" .. arg_9_1):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			arg_9_0.ragnarok:setPos(arg_9_1)

			if arg_9_0.ragnarok:getType() == xyd.RagnarokType.SINGLE then
				arg_9_0:updatePlayerBattleStatus()
			end

			xyd.WindowManager.get():openWindow("ragnarok_battle_detail", {
				pos = arg_9_1
			})
		end
	end)
end

function var_0_0.initPlayerInfo(arg_11_0, arg_11_1, arg_11_2)
	if arg_11_2 and next(arg_11_2) then
		arg_11_0:nodeByName("bg_lock" .. arg_11_1):setVisible(false)
	else
		arg_11_0:nodeByName("bg_team" .. arg_11_1):setVisible(false)

		return
	end

	local var_11_0 = arg_11_0:nodeByName("bg_team" .. arg_11_1)
	local var_11_1 = {
		is_new = true,
		showLevel = false,
		avatar_id = arg_11_2.avatar_id,
		avatar_frame_id = arg_11_2.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_11_0:getChildByName("avatar"), var_11_1)
	var_11_0:getChildByName("txt_name"):setString(arg_11_2.player_name)
	var_11_0:getChildByName("txt_region"):setString("S" .. xyd.getPlayerRegion(arg_11_2.player_id))
	var_11_0:getChildByName("txt_lv"):setString(arg_11_2.lev)

	if arg_11_2.conquer_lev and arg_11_2.conquer_lev > 0 and arg_11_2.conquer_loop_id then
		local var_11_2 = xyd.getLoopBy(arg_11_2.conquer_lev, arg_11_2.conquer_loop_id)
		local var_11_3 = var_11_0:getChildByName("level_bg")

		if var_11_2 <= 1 then
			conquerLevBg = var_11_3:setTexture("images/conquer_lev.png")
		else
			conquerLevBg = var_11_3:setTexture("images/conquer_lev" .. var_11_2 .. ".png")
		end

		var_11_0:getChildByName("txt_lv"):setString(arg_11_2.conquer_lev)
	end
end

function var_0_0.updatePlayerInfo(arg_12_0)
	if arg_12_0.ragnarok:getType() == xyd.RagnarokType.SINGLE then
		local var_12_0 = arg_12_0:nodeByName("bg_team1")
		local var_12_1 = arg_12_0.ragnarok:getHeroDeadNum()
		local var_12_2 = arg_12_0.ragnarok:getMonsterStatus()
		local var_12_3 = 0

		for iter_12_0, iter_12_1 in ipairs(var_12_2) do
			var_12_3 = var_12_3 + iter_12_1.damage
		end

		var_12_0:getChildByName("txt_dead_num"):setString(var_12_1)
		var_12_0:getChildByName("txt_damage"):setString(var_12_3)
	elseif arg_12_0.ragnarok:getType() == xyd.RagnarokType.TEAM then
		for iter_12_2 = 1, var_0_5 do
			local var_12_4 = arg_12_0.ragnarok:getPlayerInfoByPos(iter_12_2)

			if not var_12_4 or not next(var_12_4) then
				arg_12_0:nodeByName("bg_team" .. iter_12_2):setVisible(false)
				arg_12_0:nodeByName("bg_lock" .. iter_12_2):setVisible(true)

				return
			end

			local var_12_5 = arg_12_0:nodeByName("bg_team" .. iter_12_2)
			local var_12_6 = arg_12_0.ragnarok:getHeroDeadNum(iter_12_2)
			local var_12_7 = arg_12_0.ragnarok:getMonsterStatus()[iter_12_2].damage

			var_12_5:getChildByName("txt_dead_num"):setString(var_12_6)
			var_12_5:getChildByName("txt_damage"):setString(var_12_7)
		end
	end
end

function var_0_0.updateMonsterStatus(arg_13_0)
	local var_13_0 = arg_13_0.ragnarok:getMonsterStatus()

	for iter_13_0 = 1, var_0_5 do
		if var_13_0[iter_13_0].is_dead == 1 then
			arg_13_0:runDeadAction(iter_13_0)
			arg_13_0:nodeByName("touch_enemy" .. iter_13_0):setTouchEnabled(false)

			if iter_13_0 > 1 then
				arg_13_0:nodeByName("buff" .. iter_13_0 - 1):setVisible(true)
			end
		else
			local var_13_1 = arg_13_0.ragnarok.monster_total_hp[iter_13_0]
			local var_13_2 = var_13_0[iter_13_0].damage

			arg_13_0:nodeByName("bar_hp_" .. iter_13_0):setPercent(100 * ((var_13_1 - var_13_2) / var_13_1))
		end
	end
end

function var_0_0.updatePlayerBattleStatus(arg_14_0)
	if not arg_14_0.ragnarok:getType() then
		return
	end

	if arg_14_0.ragnarok:getType() == xyd.RagnarokType.SINGLE then
		for iter_14_0 = 1, var_0_5 do
			arg_14_0:nodeByName("avatar" .. iter_14_0):removeAllChildren()

			if iter_14_0 == arg_14_0.ragnarok:getPos() then
				local var_14_0 = {
					avatar_id = arg_14_0.data[1].avatar_id,
					avatar_frame_id = arg_14_0.data[1].avatar_frame_id
				}

				var_14_0.showLevel = false
				var_14_0.is_new = true

				xyd.setPlayerAvatar(arg_14_0:nodeByName("avatar" .. iter_14_0), var_14_0)
			end
		end
	elseif arg_14_0.ragnarok:getType() == xyd.RagnarokType.TEAM then
		for iter_14_1 = 1, var_0_5 do
			local var_14_1 = arg_14_0.ragnarok:getPlayerInfoByPos(iter_14_1)

			arg_14_0:nodeByName("avatar" .. iter_14_1):removeAllChildren()

			if var_14_1 and next(var_14_1) then
				xyd.setPlayerAvatar(arg_14_0:nodeByName("avatar" .. iter_14_1), var_14_1)
			end
		end
	end
end

function var_0_0.updateFightStatus(arg_15_0)
	for iter_15_0 = 1, var_0_5 do
		local var_15_0 = arg_15_0.ragnarok:getPlayerInfoByPos(iter_15_0)

		if not var_15_0 or not next(var_15_0) then
			arg_15_0:nodeByName("icon_battle" .. iter_15_0):setVisible(false)
		elseif arg_15_0.ragnarok.is_fighting[iter_15_0] == 0 then
			arg_15_0:nodeByName("icon_battle" .. iter_15_0):setVisible(false)
		else
			arg_15_0:nodeByName("icon_battle" .. iter_15_0):setVisible(true)
		end
	end
end

function var_0_0.showChatWin(arg_16_0)
	if arg_16_0.chatWinIsShow then
		arg_16_0.chatWinIsShow = false

		arg_16_0:playChatWinMove(arg_16_0.chatWinIsShow)

		return
	elseif arg_16_0.chatIsInit then
		arg_16_0.chatWinIsShow = true

		arg_16_0:playChatWinMove(arg_16_0.chatWinIsShow)

		return
	end

	local var_16_0 = arg_16_0:nodeByName("chat_container")

	var_16_0:setTouchSwallowEnabled(true)
	var_16_0:removeAllChildren()

	local var_16_1 = import("app.windows.RagnarokChatWnd").new()
	local var_16_2 = {}

	var_16_1:setParams(var_16_2)
	var_16_1:addTo(var_16_0)
	var_16_1:setPosition(cc.p(0, 0))
	var_16_1:setName("chat_wnd")
	var_16_0:setVisible(false)

	arg_16_0.chatIsInit = true
	arg_16_0.chatWinIsShow = false

	var_16_1:updateList()
	arg_16_0:updateRedMark(arg_16_0.ragnarok:getChatRedPoint())
end

function var_0_0.updateRedMark(arg_17_0, arg_17_1)
	if arg_17_0.chatWinIsShow then
		arg_17_0.ragnarok:setChatRedPoint(false)
		arg_17_0:nodeByName("red_point"):setVisible(false)
	else
		arg_17_0:nodeByName("red_point"):setVisible(arg_17_1)
	end
end

function var_0_0.playChatWinMove(arg_18_0, arg_18_1)
	local var_18_0 = arg_18_0:nodeByName("chat_container")
	local var_18_1 = var_18_0:getContentSize()
	local var_18_2 = cc.p(arg_18_0:nodeByName("btn_chat"):getPosition())

	if arg_18_1 then
		var_18_0:setPosition(cc.p(-var_18_1.width, 0))
		var_18_0:setVisible(true)
		transition.moveTo(var_18_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
		transition.moveTo(arg_18_0:nodeByName("btn_chat"), {
			time = 0.3,
			x = var_18_2.x + var_18_1.width,
			y = var_18_2.y
		})
	else
		transition.moveTo(var_18_0, {
			time = 0.3,
			y = 0,
			x = -var_18_1.width
		})
		transition.moveTo(arg_18_0:nodeByName("btn_chat"), {
			time = 0.3,
			x = var_18_2.x - var_18_1.width,
			y = var_18_2.y
		})
	end
end

function var_0_0.runDeadAction(arg_19_0, arg_19_1)
	if arg_19_0.ragnarok.deadActionIsRun[arg_19_1] then
		arg_19_0.model[arg_19_1]:setVisible(false)
		arg_19_0:nodeByName("bg_hp_" .. arg_19_1):setVisible(false)

		return
	end

	if not arg_19_0.model[arg_19_1] then
		return
	end

	arg_19_0.ragnarok.deadActionIsRun[arg_19_1] = true

	xyd.setCascadeOpacityEnabled(arg_19_0.model[arg_19_1], true)
	arg_19_0.model[arg_19_1]:die(function()
		arg_19_0.model[arg_19_1]:runAction(cc.FadeOut:create(1))
		arg_19_0:nodeByName("bg_hp_" .. arg_19_1):runAction(cc.FadeOut:create(1))
	end)
end

function var_0_0.updateTimer(arg_21_0, arg_21_1)
	arg_21_0:nodeByName("txt_left_time"):setString(arg_21_1)
end

function var_0_0.release(arg_22_0)
	if arg_22_0.handler then
		scheduler.unscheduleGlobal(arg_22_0.handler)

		arg_22_0.handler = nil
	end
end

function var_0_0.close(arg_23_0)
	local var_23_0 = var_0_1:translation("RAGNAROK_BOSS_14")

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_23_0, function()
		if arg_23_0.ragnarok:getType() == xyd.RagnarokType.SINGLE then
			arg_23_0.ragnarok:singleEnd()
		elseif arg_23_0.ragnarok:getType() == xyd.RagnarokType.TEAM then
			arg_23_0.ragnarok:exitRoom(function()
				xyd.WindowManager.get():closeWindow(arg_23_0)
			end)
		end
	end, nil, 0, arg_23_0.colorMode)
end

return var_0_0
