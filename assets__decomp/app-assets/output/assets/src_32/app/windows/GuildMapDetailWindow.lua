local var_0_0 = class("GuildGuildMapDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

var_0_0.START_BUTTON = "start"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_DESC = "txt_desc"
var_0_0.TXT_ENEMY = "txt_enemy"
var_0_0.PANEL_ENEMY = "panel_enemy"

local var_0_2 = xyd.tables.translation
local var_0_3 = 3
local var_0_4 = 10
local var_0_5 = 3
local var_0_6 = 50001013
local var_0_7 = 120
local var_0_8 = 100
local var_0_9 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.waveIndex = arg_1_2.waveIndex
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.monsterStatus = arg_1_2.monster_status
	arg_1_0.isOpen = arg_1_2.isOpen
	arg_1_0.isWin = arg_1_2.isWin
	arg_1_0.chapter = arg_1_2.chapter
	arg_1_0.monsterShowStatus = arg_1_0.monsterStatus[arg_1_0.waveIndex]
	arg_1_0.fightPlayerID = arg_1_2.fightPlayerID
	arg_1_0.fightPlayerName = arg_1_2.fightPlayerName
	arg_1_0.fightPlayerLev = arg_1_2.fightPlayerLev
	arg_1_0.fightPlayerAvatar = arg_1_2.fightPlayerAvatar
	arg_1_0.fightStage = arg_1_2.fightStage
	arg_1_0.challengeTimes = arg_1_2.challengeTimes
	arg_1_0.conquerLev = arg_1_2.conquer_lev
	arg_1_0.conquerLoopID = arg_1_2.conquer_loop_id
	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.prepareTime = arg_1_0.guild:getPrepareTime(arg_1_0.campaignID)
end

function var_0_0.onGuildFightNotice_(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.params
	local var_2_1 = var_2_0.copy_id
	local var_2_2 = var_2_0.chapter_id

	if var_2_0.player_id == xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).playerID or var_2_1 ~= arg_2_0.campaignID then
		return
	end

	arg_2_0.guild:loadGuildMapDetail(var_2_0, function(arg_3_0, arg_3_1)
		if arg_3_0 == xyd.error.OK then
			local var_3_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
			local var_3_1 = xyd.WindowManager.get():getWindow("guild_map_detail_window")

			if var_3_1 then
				local var_3_2 = arg_3_1
				local var_3_3 = arg_3_1.fight_info

				if var_3_2.current_fight_player > 0 and var_3_2.last_fight_time > 0 then
					local var_3_4 = xyd.ServerTime.get():getServerTime()
					local var_3_5 = 0

					if var_3_2.stage == 1 then
						var_3_5 = 60 - (var_3_4 - var_3_2.last_fight_time)
					elseif var_3_2.stage == 2 then
						var_3_5 = 180 - (var_3_4 - var_3_2.start_fight_time)
					end

					var_3_0:setPrepareTime(var_3_5, var_2_1, var_3_2.stage)

					var_3_1.waveIndex = var_3_2.current_index
					var_3_1.monsterStatus = var_3_2.monster_status
					var_3_1.monsterShowStatus = var_3_1.monsterStatus[var_3_1.waveIndex]
					var_3_1.isOpen = var_3_2.is_open
					var_3_1.isWin = var_3_2.is_win
					var_3_1.fightPlayerID = var_3_2.current_fight_player
					var_3_1.fightPlayerName = var_3_3.player_name
					var_3_1.fightPlayerLev = var_3_3.lev
					var_3_1.fightPlayerAvatar = var_3_3.avatar_id
					var_3_1.prepareTime = var_3_0:getPrepareTime(var_2_1)

					var_3_1:layout()
				else
					var_3_1.waveIndex = var_3_2.current_index
					var_3_1.monsterStatus = var_3_2.monster_status
					var_3_1.monsterShowStatus = var_3_1.monsterStatus[var_3_1.waveIndex]
					var_3_1.isOpen = var_3_2.is_open
					var_3_1.isWin = var_3_2.is_win
					var_3_1.prepareTime = var_3_0:getPrepareTime(var_2_1)

					var_3_1:layout()
				end
			end
		end
	end)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:initPrepareWindow()

	local var_4_0 = tonumber(arg_4_0.params.campaignID)
	local var_4_1 = {
		size = 24,
		color = cc.c3b(255, 255, 255)
	}
	local var_4_2 = xyd.AssetLoader.get():loadLabel(var_4_1)

	var_4_2:setString(xyd.tables.teamCampaign:campaignName(var_4_0))
	var_4_2:setAnchorPoint(cc.p(0, 0))
	var_4_2:setPosition(arg_4_0:nodeByName("title_pos"):getPosition())
	var_4_2:addTo(arg_4_0)

	local var_4_3 = xyd.tables.teamCampaign:campaignDesc(var_4_0)

	arg_4_0:nodeByName(var_0_0.TXT_DESC):setString(var_4_3)

	local var_4_4 = xyd.tables.teamCampaign:energyCost(var_4_0)

	arg_4_0:nodeByName(var_0_0.TXT_ENEMY):setString(var_0_2:translation("NEW_MAP_ENEMY_TXT"))
	arg_4_0:nodeByName(var_0_0.TXT_ENEMY):enableShadow(cc.c4b(95, 105, 161, 150), cc.size(1, -1), 1)
	arg_4_0:nodeByName("enemy_desc"):setString(string.format(var_0_2:translation("GUILD_CAMPAIGN_DETAIL"), arg_4_0.waveIndex))

	if xyd.tables.campaign:chapter(var_4_0) >= xyd.tables.misc.energyReduceChapter then
		local var_4_5 = 50

		if arg_4_0.handBuff then
			arg_4_0.handBuff:removeFromParent()

			arg_4_0.handBuff = nil
			var_4_5 = 38
		end

		local var_4_6 = xyd.AssetLoader.get():loadSprite("windows/map_window/campaign_hand.png")

		var_4_6:addTo(arg_4_0)

		arg_4_0.handBuff = var_4_6

		var_4_6:setAnchorPoint(cc.p(0, 0.5))

		local var_4_7, var_4_8 = var_4_2:getPosition()

		var_4_6:setPosition(var_4_7 + var_4_2:getContentSize().width + var_4_5, var_4_8)
		var_4_6:setTouchEnabled(true)
		var_4_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				local var_5_0 = {
					message = var_0_2:translation("CAMPAIGN_DEBUFF_TIP")
				}

				var_5_0.isAutoClose = 0
				var_5_0.txtSize = 24
				var_5_0.isOutLine = 0

				local var_5_1 = xyd.WindowManager.get():openWindow("toast", var_5_0)
				local var_5_2 = arg_4_0:convertToWorldSpace(cc.p(0, 0))
				local var_5_3, var_5_4 = var_4_6:getPosition()
				local var_5_5 = arg_4_0:convertToWorldSpace(cc.p(var_5_3, var_5_4 + var_4_6:getHeight() / 2 + var_5_1:getWndHeight() / 2 + 5))

				var_5_1:setPosition(var_5_5)

				return true
			elseif arg_5_0.name == "ended" then
				local var_5_6 = xyd.WindowManager.get():getWindow("toast")

				if var_5_6 then
					xyd.WindowManager.get():closeWindow(var_5_6.name)
				end
			end
		end)
	end

	if arg_4_0.isOpen and arg_4_0.isOpen == 0 or arg_4_0.isWin and arg_4_0.isWin == 1 then
		arg_4_0:nodeByName("start"):setVisible(false)
	else
		arg_4_0:nodeByName("start"):setVisible(true)
	end

	local var_4_9
	local var_4_10
	local var_4_11
	local var_4_12

	if arg_4_0.waveIndex == 1 then
		local var_4_13 = xyd.tables.teamCampaign:monsterDisplay1(var_4_0)

		var_4_10 = xyd.tables.teamCampaign:monsterStar1(var_4_0)
		var_4_11 = xyd.tables.teamCampaign:monsterQualitys1(var_4_0)

		local var_4_14 = xyd.tables.teamCampaign:monsterLevels1(var_4_0)
	elseif arg_4_0.waveIndex == 2 then
		local var_4_15 = xyd.tables.teamCampaign:monsterDisplay2(var_4_0)

		var_4_10 = xyd.tables.teamCampaign:monsterStar2(var_4_0)
		var_4_11 = xyd.tables.teamCampaign:monsterQualitys2(var_4_0)

		local var_4_16 = xyd.tables.teamCampaign:monsterLevels2(var_4_0)
	elseif arg_4_0.waveIndex == 3 then
		local var_4_17 = xyd.tables.teamCampaign:monsterDisplay3(var_4_0)

		var_4_10 = xyd.tables.teamCampaign:monsterStar3(var_4_0)
		var_4_11 = xyd.tables.teamCampaign:monsterQualitys3(var_4_0)

		local var_4_18 = xyd.tables.teamCampaign:monsterLevels3(var_4_0)
	end

	arg_4_0:resortMonsterStatusByBoss(arg_4_0.monsterShowStatus)

	arg_4_0.monsterTips = {}

	arg_4_0:nodeByName(var_0_0.PANEL_ENEMY):removeAllChildren()

	for iter_4_0 = 1, #arg_4_0.monsterShowStatus do
		local var_4_19 = arg_4_0.monsterShowStatus[iter_4_0]
		local var_4_20 = {}
		local var_4_21 = cc.Node:create()

		var_4_21:setAnchorPoint(cc.p(0.5, 0.5))

		local var_4_22

		if iter_4_0 ~= #arg_4_0.monsterShowStatus then
			var_4_20.isBoss = false

			var_4_21:setContentSize(var_0_8, var_0_8)
			var_4_21:setPosition((iter_4_0 - 1) * (var_0_8 + 8) + 115, 60)

			var_4_22 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar4.csb")
		else
			local var_4_23 = 12

			var_4_20.isBoss = true

			var_4_21:setContentSize(var_0_8 + var_4_23, var_0_8 + var_4_23)
			var_4_21:setPosition((iter_4_0 - 1) * (var_0_8 + 7) + 115 + var_4_23 / 2, 60)

			var_4_22 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar5.csb")
		end

		local var_4_24 = var_4_22:getChildByName("background")

		var_4_22:setContentSize(var_4_24:getContentSize())
		xyd.justSetAvatar(var_4_19.table_id, var_4_22:getChildByName("avatar"))
		xyd.justSetAvatarBorderAndStar(var_4_22:getChildByName("border"), var_4_11[iter_4_0], var_4_10[iter_4_0])

		local var_4_25 = var_4_22:getChildByName("hp")
		local var_4_26 = var_4_22:getChildByName("hp_di")
		local var_4_27 = var_4_19.health
		local var_4_28 = var_4_19.hp
		local var_4_29 = xyd.tables.hero:getInitialAttr(var_4_19.table_id, xyd.AttributeType.HP)
		local var_4_30 = var_4_22:getChildByName("dead_txt")

		var_4_30:setString(var_0_2:translation("DEAD_TEXT"))

		local var_4_31 = var_4_22:getChildByName("mask")
		local var_4_32 = var_4_25:getLocalZOrder()
		local var_4_33 = var_4_22:getChildByName("percent")

		var_4_33:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

		if var_4_27 == 0 and not var_4_28 then
			var_4_25:setPercent(100)
			var_4_33:setString("100%")
			var_4_30:setVisible(false)
			var_4_31:setVisible(false)
		elseif var_4_28 and var_4_28 > 0 then
			var_4_25:setPercent(var_4_28 / var_4_29 * 100)
			var_4_33:setString(math.floor(var_4_28 / var_4_29 * 100) .. "%")
			var_4_30:setVisible(false)
			var_4_31:setVisible(false)
		else
			var_4_31:setVisible(true)
			var_4_25:setVisible(false)
			var_4_26:setVisible(false)
			var_4_33:setVisible(false)
			var_4_30:setVisible(true)
			var_4_30:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
		end

		var_4_22:addTo(var_4_21)
		var_4_22:setScale(0.9)
		arg_4_0:nodeByName(var_0_0.PANEL_ENEMY):addChild(var_4_21)

		var_4_20.id = var_4_19.table_id
		var_4_20.lev = var_4_19.lev
		var_4_20.quality = var_4_19.color
		var_4_20.name = xyd.tables.hero:name(var_4_19.table_id)
		var_4_20.desc = xyd.tables.hero:getDes(var_4_19.table_id)
		var_4_20.isHero = true

		local var_4_34, var_4_35 = var_4_21:getPosition()

		var_4_21:setTouchEnabled(true)
		var_4_21:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				local var_6_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_6_1 = arg_4_0:convertToWorldSpace(cc.p(0, 0))

				if not var_6_0 then
					local var_6_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_4_20)

					xyd.adaptToWorldPosition(var_4_21, var_6_2)
				end

				return true
			elseif arg_6_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.initPrepareWindow(arg_7_0)
	if arg_7_0.prepareTime and arg_7_0.prepareTime > 0 and arg_7_0.isWin == 0 then
		if arg_7_0.fightPlayerID and arg_7_0.fightPlayerID > 0 and arg_7_0.fightPlayerID == arg_7_0.player_.playerID and arg_7_0.fightStage == 2 then
			return
		end

		arg_7_0:nodeByName("prepare_container"):setVisible(true)

		local var_7_0 = display.newNode()

		var_7_0:setContentSize(110, 110)
		var_7_0:addTo(arg_7_0:nodeByName("prepare_container"))
		var_7_0:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_0:setPosition(arg_7_0:nodeByName("avatar_pos"):getPosition())

		local var_7_1 = var_7_0:getLocalZOrder()

		arg_7_0:nodeByName("avatar_kuang"):setLocalZOrder(var_7_1 + 1)
		arg_7_0:nodeByName("lv_bg"):setLocalZOrder(var_7_1 + 1)
		arg_7_0:nodeByName("lv_txt"):setLocalZOrder(var_7_1 + 2)

		local var_7_2 = 0
		local var_7_3 = ""

		if arg_7_0.fightPlayerID and arg_7_0.fightPlayerID > 0 and arg_7_0.fightPlayerID ~= arg_7_0.player_.playerID then
			var_7_3 = var_0_2:translation("GUILD_DETAIL_TIP2")

			arg_7_0:nodeByName("prepareing_txt"):setString(var_7_3)

			if arg_7_0.conquerLev and arg_7_0.conquerLev > 0 then
				xyd.setConquerLev(arg_7_0.conquerLev, arg_7_0:nodeByName("lv_txt"), arg_7_0:nodeByName("lv_bg"), nil, nil, nil, nil, arg_7_0.conquerLoopID)
			else
				arg_7_0:nodeByName("lv_txt"):setString(arg_7_0.fightPlayerLev)
			end

			arg_7_0:nodeByName("player_name_txt"):setString(arg_7_0.fightPlayerName)
			xyd.setAvatarClip(var_7_0, arg_7_0.fightPlayerAvatar, 1)
		else
			var_7_3 = var_0_2:translation("GUILD_DETAIL_TIP")

			arg_7_0:nodeByName("prepareing_txt"):setString(var_7_3)

			if arg_7_0.conquerLev and arg_7_0.conquerLev > 0 then
				xyd.setConquerLev(arg_7_0.conquerLev, arg_7_0:nodeByName("lv_txt"), arg_7_0:nodeByName("lv_bg"), nil, nil, nil, nil, arg_7_0.conquerLoopID)
			else
				arg_7_0:nodeByName("lv_txt"):setString(arg_7_0.player_.lev)
			end

			arg_7_0:nodeByName("player_name_txt"):setString(arg_7_0.player_.playerName)
			xyd.setAvatarClip(var_7_0, arg_7_0.player_.avatarId, 1)
		end

		if arg_7_0.handle_ then
			var_0_1.unscheduleGlobal(arg_7_0.handle_)
		end

		arg_7_0.handle_ = var_0_1.scheduleGlobal(function()
			local var_8_0 = var_7_3

			var_7_2 = var_7_2 + 1
			count = var_7_2 % 4

			for iter_8_0 = 1, count do
				var_8_0 = var_8_0 .. "."
			end

			local var_8_1 = xyd.WindowManager.get():getWindow("guild_map_detail_window")

			if not var_8_1 then
				return
			else
				var_8_1:nodeByName("prepareing_txt"):setString(var_8_0)

				var_8_1.prepareTime = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):getPrepareTime(var_8_1.campaignID)

				if not var_8_1.prepareTime or var_8_1.prepareTime <= 0 then
					var_8_1:nodeByName("prepare_container"):setVisible(false)

					if var_8_1.handle_ then
						var_0_1.unscheduleGlobal(var_8_1.handle_)
					end
				end
			end
		end, 1)
	else
		arg_7_0:nodeByName("prepare_container"):setVisible(false)
	end
end

function var_0_0.willOpen(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("prepare_container"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.GUILD_FIGHT_NOTICE, handler(arg_9_0, arg_9_0.onGuildFightNotice_))
	arg_9_0:layout()
	arg_9_0:updateModelContainer()
end

function var_0_0.updateModelContainer(arg_10_0)
	arg_10_0:nodeByName("model_container"):removeAllChildren()

	local var_10_0 = arg_10_0:nodeByName("model_container"):getContentSize()
	local var_10_1

	if arg_10_0.waveIndex == 1 then
		var_10_1 = xyd.tables.teamCampaign:monsterDisplay1(arg_10_0.campaignID)
	elseif arg_10_0.waveIndex == 2 then
		var_10_1 = xyd.tables.teamCampaign:monsterDisplay2(arg_10_0.campaignID)
	else
		var_10_1 = xyd.tables.teamCampaign:monsterDisplay2(arg_10_0.campaignID)
	end

	local var_10_2 = var_10_1[#var_10_1]
	local var_10_3 = xyd.tables.teamCampaign:smallBg(arg_10_0.campaignID)

	if var_10_3 and var_10_3 ~= "" then
		local var_10_4 = xyd.SpriteLoader.new(var_10_3, nil, nil, xyd.DefaultImageType.SMALL_MAP_BG)

		var_10_4:addTo(arg_10_0:nodeByName("model_container"))
		var_10_4:setPosition(cc.p(var_10_0.width / 2, var_10_0.height / 2))
	end

	if var_10_2 and var_10_2 > 0 then
		local var_10_5 = xyd.tables.hero:modelID(var_10_2)
		local var_10_6 = xyd.HeroAnimation.new(nil, var_10_5, xyd.tables.model:uiScale(var_10_5) * 0.8, {})

		var_10_6:addTo(arg_10_0:nodeByName("model_container"))
		var_10_6:setPosition(cc.p(var_10_0.width / 2, 30))
		var_10_6:idle()
	end
end

function var_0_0.didOpen(arg_11_0)
	arg_11_0:nodeByName("all_servers_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		xyd.buttonScaleAnim(arg_12_0, arg_12_1)

		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = {
				copy_id = arg_11_0.campaignID
			}

			arg_11_0.guild:loadAllDamageRank(var_12_0, function(arg_13_0)
				if arg_13_0 == xyd.error.OK then
					local var_13_0 = {
						chapter_id = arg_11_0.chapter,
						campaignID = arg_11_0.params.campaignID
					}

					xyd.WindowManager.get():openWindow("all_server_rank", var_13_0)
				end
			end)
		end
	end)
	arg_11_0:nodeByName(var_0_0.START_BUTTON):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_11_0.challengeTimes >= 2 then
				local var_14_0 = var_0_2:translation("GUILD_CAMPAIGN_TRY_END")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return
			end

			if not arg_11_0:checkTimeWithNoDate() then
				local var_14_1 = var_0_2:translation("GUILD_CAMPAIGN_REST_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_1
				})

				return
			end

			local var_14_2 = arg_11_0.guild:getPrepareTime(arg_11_0.campaignID)
			local var_14_3 = {
				copy_id = arg_11_0.campaignID
			}

			arg_11_0.guild:getPrepareCount(var_14_3, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					local var_15_0 = arg_15_1.current_fight_player

					if var_15_0 and var_15_0 > 0 and var_15_0 ~= arg_11_0.player_.playerID then
						local var_15_1 = string.format(var_0_2:translation("GUILD_WAIT_FIGHT"), arg_15_1.fight_info.player_name)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_1
						})

						return
					end

					var_14_2 = arg_11_0.guild:getPrepareTime(arg_11_0.campaignID)

					local var_15_2 = {
						campaign_type = arg_11_0.params.campaignType
					}

					arg_11_0.guild:loadAllTeamHeros(var_15_2, function(arg_16_0)
						local var_16_0 = false
						local var_16_1 = {}

						if arg_16_0 == xyd.error.OK then
							var_16_0 = true

							for iter_16_0, iter_16_1 in ipairs(arg_11_0.guild:getAllTeamHeros()) do
								local var_16_2 = var_0_9.new()

								var_16_2:populate(iter_16_1)

								var_16_2.player_name = iter_16_1.player_name
								var_16_2.rent_need_mana = iter_16_1.rent_need_mana
								var_16_2.can_rent = iter_16_1.can_rent
								var_16_2.player_id = iter_16_1.player_id

								table.insert(var_16_1, var_16_2)
							end
						end

						local var_16_3 = {
							type = xyd.SelectTeamType.GUILD,
							guildChapterID = arg_11_0.chapter,
							campaignID = arg_11_0.params.campaignID,
							campaignType = arg_11_0.params.campaignType,
							itemComposeID = arg_11_0.itemComposeID,
							isMercenary = var_16_0,
							allTeamHeros = var_16_1,
							prepareTime = var_14_2,
							monsterStatus = arg_11_0.monsterStatus
						}

						xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_16_3)

						if xyd.isMapWindowCampaignType(arg_11_0.campaignType) then
							xyd.WindowManager.get():closeWindow(arg_11_0)
						end
					end)
				end
			end)
		end
	end)
	arg_11_0:addBlockLayer(nil, false, true)
end

function var_0_0.checkTimeWithNoDate(arg_17_0)
	local var_17_0 = xyd.ServerTime.get():getSecondsOfDay()

	if var_17_0 < xyd.tables.misc.guildCampaignTimeLimits[1] or var_17_0 > xyd.tables.misc.guildCampaignTimeLimits[2] then
		return true
	else
		return false
	end
end

function var_0_0.resortMonsterStatusByBoss(arg_18_0, arg_18_1)
	local var_18_0

	for iter_18_0, iter_18_1 in pairs(arg_18_1) do
		if xyd.tables.hero:boss(iter_18_1.table_id) == 1 then
			var_18_0 = clone(iter_18_1)

			table.remove(arg_18_1, iter_18_0)

			break
		end
	end

	table.insert(arg_18_1, var_18_0)
end

function var_0_0.willClose(arg_19_0)
	if arg_19_0.handle_ then
		var_0_1.unscheduleGlobal(arg_19_0.handle_)
	end
end

return var_0_0
