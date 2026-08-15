local var_0_0 = class("MarchTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "march_team_info"
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.team = arg_1_2.team
	arg_1_0.teamIdx = arg_1_2.teamIdx
	arg_1_0.isActive = arg_1_2.isActive
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.enemyHeroes = {}

	if arg_1_0.team.heroes and next(arg_1_0.team.heroes) then
		for iter_1_0, iter_1_1 in pairs(arg_1_0.team.heroes) do
			local var_1_0 = clone(iter_1_1)

			if arg_1_0.team.is_robot == 1 then
				var_1_0.table_id = var_1_0.partner_id
				var_1_0.partner_id = iter_1_0
			end

			var_1_0.partner_id = tonumber(var_1_0.hero_id) or iter_1_0

			if type(var_1_0.equips) == "string" then
				var_1_0.equips = xyd.splitToNumber(var_1_0.equips, "|")
			end

			if type(var_1_0.fumo_levels) == "string" then
				var_1_0.fumo_levels = xyd.splitToNumber(var_1_0.fumo_levels, "|")
			end

			if type(var_1_0.fumos) == "string" then
				var_1_0.fumos = xyd.splitToNumber(var_1_0.fumos, "|")
			end

			if type(var_1_0.skills) == "string" then
				var_1_0.skills = xyd.splitToNumber(var_1_0.skills, "|")
			end

			local var_1_1 = {
				health = var_1_0.health,
				hp = var_1_0.hp,
				mp = var_1_0.mp,
				is_reborn = var_1_0.is_reborn
			}
			local var_1_2 = import("app.model.Hero").new()

			var_1_2:populate(var_1_0)

			if arg_1_0.team.conquer_lev and arg_1_0.team.conquer_lev > 0 then
				var_1_2:setConquerSchoolLev(arg_1_0.team.conquer_lev)
			end

			var_1_2.healthStatus = var_1_1

			table.insert(arg_1_0.enemyHeroes, var_1_2)
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0), nil, true)
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:container()

	arg_4_0:nodeByName("txt_title"):setString(var_0_3:translation("NEW_MAP_ENEMY_TXT"))

	arg_4_0.playerName = arg_4_0:nodeByName("text_player_name")
	arg_4_0.avatarPanel = arg_4_0:nodeByName("avatar")
	arg_4_0.textLevel = arg_4_0:nodeByName("text_level")
	arg_4_0.textOrder = arg_4_0:nodeByName("text_order")
	arg_4_0.heroesContainer = arg_4_0:nodeByName("heroes_container")

	arg_4_0:updateTeamInfo()

	local var_4_1 = arg_4_0:nodeByName("start_btn")

	if arg_4_0.isActive then
		var_4_1:setVisible(true)
		var_4_1:addTouchEventListener(function(arg_5_0, arg_5_1)
			xyd.buttonScaleAnim(arg_5_0, arg_5_1)

			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_5_0 = {
					campaign_type = xyd.CampaignType.MARCH
				}

				arg_4_0.guild:loadAllTeamHeros(var_5_0, function(arg_6_0)
					local var_6_0 = false
					local var_6_1 = {}

					if arg_6_0 == xyd.error.OK then
						var_6_0 = true

						for iter_6_0, iter_6_1 in ipairs(arg_4_0.guild:getAllMarchTeamHeros()) do
							local var_6_2 = var_0_2.new()

							var_6_2:populate(iter_6_1)

							var_6_2.player_name = iter_6_1.player_name
							var_6_2.rent_need_mana = iter_6_1.rent_need_mana
							var_6_2.can_rent = iter_6_1.can_rent
							var_6_2.player_id = iter_6_1.player_id
							var_6_2.have_rent = iter_6_1.have_rent

							table.insert(var_6_1, var_6_2)
						end
					end

					local var_6_3 = {
						type = xyd.SelectTeamType.MARCH,
						campaignType = xyd.CampaignType.MARCH,
						enemyID = arg_4_0.team.table_id,
						enemyHeroes = arg_4_0.enemyHeroes,
						marchStage = arg_4_0.teamIdx,
						isMercenary = var_6_0,
						allTeamHeros = var_6_1
					}

					xyd.WindowManager.get():closeWindow(arg_4_0)
					xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_6_3)
				end)
			end
		end)
	else
		var_4_1:setVisible(false)
	end
end

function var_0_0.updateTeamInfo(arg_7_0)
	xyd.setPlayerAvatar(arg_7_0.avatarPanel, {
		avatar = arg_7_0.team.avatar,
		avatar_frame_id = arg_7_0.team.avatar_frame
	})
	arg_7_0.playerName:setString(arg_7_0.team.name)

	if arg_7_0.team.conquer_lev and arg_7_0.team.conquer_lev > 0 then
		xyd.setConquerLev(arg_7_0.team.conquer_lev, arg_7_0.textLevel, arg_7_0:nodeByName("level_bg"), nil, nil, nil, nil, arg_7_0.team.conquer_loop_id or 1)
	else
		arg_7_0.textLevel:setString(arg_7_0.team.level)

		local var_7_0 = arg_7_0:nodeByName("level_bg")

		var_7_0:setPosition(var_7_0:getPositionX() + 2, var_7_0:getPositionY() - 2)
	end

	arg_7_0.textOrder:setString(string.format("%d/15", arg_7_0.teamIdx))
	arg_7_0:addHeroCells()
end

function var_0_0.addHeroCells(arg_8_0)
	arg_8_0.heroesContainer:removeAllChildren()

	for iter_8_0, iter_8_1 in pairs(arg_8_0.enemyHeroes) do
		local var_8_0 = display.newNode()
		local var_8_1 = 100
		local var_8_2 = cc.p(var_8_1, var_8_1)

		var_8_0:setContentSize(var_8_2)
		var_8_0:setPosition(cc.p(110 * (iter_8_0 - 1), 0))

		local var_8_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/common_new/hero_avatar_new.csb")

		xyd.setAvatarBorderNewUI(iter_8_1, var_8_3:getChildByName("avatar"))
		var_8_3:getChildByName("name_label_bg"):setVisible(false)
		var_8_3:getChildByName("name_text"):setVisible(false)
		var_8_3:getChildByName("yongbing_tubiao"):setVisible(false)

		local var_8_4 = var_8_3:getChildByName("lv_txt")

		var_8_4:setString(iter_8_1:getLevel())
		var_8_4:enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_8_5 = var_8_3:getChildByName("hp_bar")
		local var_8_6 = var_8_3:getChildByName("hp_di")
		local var_8_7 = var_8_3:getChildByName("dead_text")

		var_8_7:setString(var_0_3:translation("ALREADY_DEAD"))

		if var_8_7 then
			var_8_7:setVisible(false)
		end

		local var_8_8 = false
		local var_8_9 = false
		local var_8_10 = 0
		local var_8_11 = var_8_3:getChildByName("avatar_mask")

		var_8_11:setLocalZOrder(2)

		local var_8_12 = var_8_3:getChildByName("background"):getContentSize()

		var_8_3:setScale(var_8_1 / var_8_12.width)

		local var_8_13 = iter_8_1:getTableID()
		local var_8_14 = xyd.tables.hero:name(var_8_13)
		local var_8_15 = xyd.AssetLoader.get():loadSprite("windows/march/team/bg_name_cell.png")

		var_8_15:setAnchorPoint(cc.p(0.5, 0.5))

		local var_8_16 = xyd.createLabel(18, cc.c3b(255, 255, 255))

		var_8_16:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_16:setString(var_8_14)
		var_8_16:addTo(var_8_15)
		var_8_16:setPosition(cc.p(var_8_15:getContentSize().width / 2, var_8_15:getContentSize().height / 2))
		var_8_15:addTo(var_8_3)
		var_8_15:setScale(var_8_12.width / var_8_1)
		var_8_15:setPosition(cc.p(var_8_3:getChildByName("background"):getContentSize().width / 2, 5))
		var_8_3:setPositionY(-30)

		if arg_8_0.isActive == true then
			if arg_8_0.team.heroes and next(arg_8_0.team.heroes) then
				local var_8_17 = arg_8_0.team.heroes[iter_8_0]

				if var_8_17.health == 1 then
					var_8_9 = true
					var_8_10 = var_8_17.hp
				elseif var_8_17.health == 2 then
					var_8_8 = true
				end
			end
		else
			var_8_8 = true
		end

		if var_8_8 then
			var_8_5:setVisible(false)
			var_8_6:setVisible(false)
			var_8_7:setVisible(true)
			var_8_11:setVisible(true)
		elseif var_8_9 then
			var_8_5:setVisible(true)
			var_8_6:setVisible(true)
			var_8_7:setVisible(false)
			var_8_11:setVisible(false)

			hpPercent = var_8_10 / iter_8_1:getMaxHP() * 100

			var_8_5:setPercent(hpPercent)
		else
			var_8_5:setVisible(true)
			var_8_6:setVisible(true)
			var_8_7:setVisible(false)
			var_8_11:setVisible(false)
			var_8_5:setPercent(100)
		end

		var_8_0:addChild(var_8_3)
		arg_8_0.heroesContainer:addChild(var_8_0)
	end
end

function var_0_0.didClose(arg_9_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_10_0)
	return arg_10_0:nodeByName("container")
end

return var_0_0
