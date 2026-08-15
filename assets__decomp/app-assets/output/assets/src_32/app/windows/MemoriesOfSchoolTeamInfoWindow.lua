local var_0_0 = class("MemoriesOfSchoolTeamInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "march_team_info"
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.common.ui.SplitLine")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.mazeFloor
local var_0_6 = xyd.tables.hero
local var_0_7 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
local var_0_8 = 120
local var_0_9 = {
	CAN_ADD = 1,
	IN_BLACK = 3,
	IN_FRIEND = 2,
	FULL_FRIEND = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.team = arg_1_2.team or {
		isMonster = true
	}
	arg_1_0.enemiesinfo = arg_1_2.enemiesinfo
	arg_1_0.battleID = arg_1_2.battleID
	arg_1_0.isBoss = arg_1_2.isBoss
	arg_1_0.gridPos = arg_1_2.pos
	arg_1_0.currentRound = tonumber(arg_1_2.currentRound)
	arg_1_0.backpack = var_0_7:getBackpack()
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.memoriesOfSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)

	local var_1_0 = xyd.tables.battle:monsters(arg_1_2.battleID)

	if arg_1_0.team.isMonster then
		monsterInfo = arg_1_0.enemiesinfo
		arg_1_0.enemyHeroes = {}
		arg_1_0.herosB = {}

		for iter_1_0 = 1, #var_1_0 do
			local var_1_1 = {}

			for iter_1_1, iter_1_2 in ipairs(var_1_0[iter_1_0]) do
				local var_1_2 = var_0_2.new()

				var_1_2:populateWithTableID(iter_1_2)

				if monsterInfo[tostring(iter_1_2)] then
					local var_1_3 = {}

					var_1_3.health = 1
					var_1_3.hp = monsterInfo[tostring(iter_1_2)].hp
					var_1_3.is_reborn = monsterInfo[tostring(iter_1_2)].is_reborn
					var_1_3.mp = monsterInfo[tostring(iter_1_2)].mp
					var_1_2.healthStatus = var_1_3
				end

				table.insert(var_1_1, var_1_2)
			end

			if #var_1_1 ~= 0 then
				table.insert(arg_1_0.herosB, var_1_1)
			end
		end

		arg_1_0.enemyHeroes = arg_1_0.herosB[arg_1_0.currentRound]
	else
		arg_1_0.enemyHeroes = {}

		if arg_1_0.team.heroes and next(arg_1_0.team.heroes) then
			for iter_1_3, iter_1_4 in pairs(arg_1_0.team.heroes) do
				local var_1_4 = clone(iter_1_4)

				if arg_1_0.team.is_robot == 1 then
					var_1_4.table_id = var_1_4.partner_id
					var_1_4.partner_id = iter_1_3
				end

				var_1_4.partner_id = tonumber(var_1_4.partner_id) or iter_1_3

				if type(var_1_4.equips) == "string" then
					var_1_4.equips = xyd.splitToNumber(var_1_4.equips, "|")
				end

				if type(var_1_4.fumo_levels) == "string" then
					var_1_4.fumo_levels = xyd.splitToNumber(var_1_4.fumo_levels, "|")
				end

				if type(var_1_4.fumos) == "string" then
					var_1_4.fumos = xyd.splitToNumber(var_1_4.fumos, "|")
				end

				if type(var_1_4.skills) == "string" then
					var_1_4.skills = xyd.splitToNumber(var_1_4.skills, "|")
				end

				local var_1_5

				if arg_1_0.enemiesinfo[tostring(var_1_4.partner_id)] then
					var_1_5 = {
						health = arg_1_0.enemiesinfo[tostring(var_1_4.partner_id)].health,
						hp = arg_1_0.enemiesinfo[tostring(var_1_4.partner_id)].hp,
						mp = arg_1_0.enemiesinfo[tostring(var_1_4.partner_id)].mp,
						is_reborn = arg_1_0.enemiesinfo[tostring(var_1_4.partner_id)].is_reborn
					}
				else
					var_1_5 = {
						health = 0,
						hp = var_1_4.hp,
						mp = var_1_4.mp,
						is_reborn = var_1_4.is_reborn
					}
				end

				local var_1_6 = import("app.model.Hero").new()

				var_1_6:populate(var_1_4)

				if arg_1_0.team.conquer_lev and arg_1_0.team.conquer_lev > 0 then
					var_1_6:setConquerSchoolLev(arg_1_0.team.conquer_lev)
				end

				var_1_6.healthStatus = var_1_5

				table.insert(arg_1_0.enemyHeroes, var_1_6)
			end

			if arg_1_0.team.pet then
				local var_1_7 = import("app.model.Hero").new()

				var_1_7:populate(arg_1_0.team.pet)

				arg_1_0.enemyPet = var_1_7
			end
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_fight"):setString(var_0_4:translation("MEMORIES_OF_SCHOOL_TIPS10"))
	arg_4_0:nodeByName("txt_title"):setString(var_0_4:translation("MEMORIES_OF_SCHOOL_TIPS10"))
	arg_4_0:nodeByName("title_txt"):setString(var_0_4:translation("MEMORIES_OF_SCHOOL_TIPS5"))

	local var_4_0 = arg_4_0:container()

	arg_4_0.playerName = arg_4_0:nodeByName("text_player_name")
	arg_4_0.avatarPanel = arg_4_0:nodeByName("avatar")
	arg_4_0.textOrder = arg_4_0:nodeByName("text_order")

	local var_4_1 = arg_4_0.memoriesOfSchool.baseInfo.now_floor
	local var_4_2 = var_0_5:tiliCost(var_4_1)[2]

	arg_4_0:nodeByName("tili_num"):setString(var_4_2)

	arg_4_0.heroesContainer = arg_4_0:nodeByName("heroes_container")

	arg_4_0:updateTeamInfo()

	local var_4_3 = var_0_3.new({
		size = 696
	})

	arg_4_0:nodeByName("pos_line"):addChild(var_4_3)

	local var_4_4 = arg_4_0:nodeByName("start_btn")

	var_4_4:setVisible(true)
	var_4_4:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_5_0, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				campaignType = xyd.CampaignType.MEMORIES_OF_SCHOOL
			}

			if arg_4_0.team.isMonster then
				var_5_0.type = xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER
				var_5_0.battleID = arg_4_0.battleID
				var_5_0.campaignID = arg_4_0.battleID

				if var_0_7:getEnergy() < var_4_2 then
					arg_4_0:openTiliWindow()
				else
					arg_4_0.memoriesOfSchool:setBattleGrid(arg_4_0.gridPos)
					xyd.WindowManager.get():openWindow("battle_select_team", var_5_0)
				end
			elseif var_0_7:getEnergy() < var_4_2 then
				arg_4_0:openTiliWindow()
			else
				var_5_0.type = xyd.SelectTeamType.MEMORIES_OF_SCHOOL_PLAYER
				var_5_0.battleID = battleID
				var_5_0.campaignID = battleID

				arg_4_0.memoriesOfSchool:setBattleGrid(arg_4_0.gridPos)
				xyd.WindowManager.get():openWindow("battle_select_team", var_5_0)
			end
		end
	end)

	if not arg_4_0.team.isMonster then
		arg_4_0:nodeByName("title_txt"):setVisible(false)
	else
		arg_4_0:nodeByName("text_player_name"):setVisible(false)
	end
end

function var_0_0.openTiliWindow(arg_6_0)
	local var_6_0 = var_0_7.buyEnergyTimes
	local var_6_1 = xyd.tables.refreshCost:buyEnergyCost(var_6_0 + 1)
	local var_6_2 = xyd.tables.vip:numEnergy(var_0_7.vip)

	if var_0_7.privilegeLeftCardDay > 0 then
		var_6_2 = var_6_2 + xyd.tables.monthlyPrivilege:numEnergy(1)
	end

	local var_6_3 = xyd.tables.misc.energyMaxLimit

	if var_6_3 <= var_0_7.energy and var_6_0 < var_6_2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_4:translation("TILI_LIMIT_INFO")
		})
	else
		local function var_6_4()
			if var_6_0 >= var_6_2 then
				local var_7_0 = string.format(var_0_4:translation("CAN_NOT_ADDENERGY"), var_6_0)
				local var_7_1 = xyd.luaStringSplit(var_7_0, "\n")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_1, function()
					local var_8_0 = {}

					var_8_0.windowState = false

					xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
					xyd.WindowManager.get():closeWindow("add_energy")
				end, nil, nil, arg_6_0.colorMode)
			elseif var_0_7.energy >= var_6_3 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_4:translation("TILI_LIMIT_INFO")
				})
				xyd.WindowManager.get():closeWindow("buy_tili")
			elseif var_6_1 > var_0_7.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
					local var_9_0 = {}

					var_9_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
				end, nil, nil, arg_6_0.colorMode)
			else
				arg_6_0.addEnergyModel:addEnergy()
				xyd.WindowManager.get():closeWindow("buy_tili")
			end
		end

		local var_6_5 = string.format(var_0_4:translation("ADD_ENERGY"), var_6_1, var_0_8, var_6_0)

		if arg_6_0.backpack:isHasEnergyItem() then
			local var_6_6 = {
				text = var_6_5,
				callback = var_6_4
			}

			xyd.WindowManager.get():openWindow("buy_tili", var_6_6)
		else
			local var_6_7 = xyd.luaStringSplit(var_6_5, "\n")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_7, function()
				if var_6_0 >= var_6_2 then
					local var_10_0 = string.format(var_0_4:translation("CAN_NOT_ADDENERGY"), var_6_0)
					local var_10_1 = xyd.luaStringSplit(var_10_0, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_1, function()
						local var_11_0 = {}

						var_11_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_6_0.colorMode)
				elseif var_6_1 > var_0_7.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_4:translation("ZUANSHI_ABSENCE"), function()
						local var_12_0 = {}

						var_12_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
					end, nil, nil, arg_6_0.colorMode)
				else
					arg_6_0.addEnergyModel:addEnergy()
					xyd.WindowManager.get():closeWindow("alert")
				end
			end, nil, 0, arg_6_0.colorMode)
		end
	end
end

function var_0_0.checkCanAddFriend(arg_13_0, arg_13_1)
	local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)

	if var_13_0:isInFriendList(arg_13_1) then
		return var_0_9.IN_FRIEND
	elseif var_13_0:isInBlackList(arg_13_1) then
		return var_0_9.IN_BLACK
	elseif #var_13_0.friendlist >= xyd.tables.misc.maxFriendNum then
		return var_0_9.FULL_FRIEND
	else
		return var_0_9.CAN_ADD
	end
end

function var_0_0.updateTeamInfo(arg_14_0)
	if not arg_14_0.team.isMonster then
		xyd.setPlayerAvatar(arg_14_0.avatarPanel, {
			avatar = arg_14_0.team.avatar,
			avatar_frame_id = arg_14_0.team.avatar_frame
		})
		arg_14_0.playerName:setString(arg_14_0.team.player_name)
	end

	if not arg_14_0.team.isMonster then
		local var_14_0 = {
			lev = arg_14_0.team.level,
			conquerLev = arg_14_0.team.conquer_lev,
			loopID = arg_14_0.team.conquer_loop_id,
			fontColor = cc.c3b(152, 83, 53)
		}

		xyd.setLev(arg_14_0:nodeByName("lv_container"), var_14_0)
	else
		arg_14_0:nodeByName("lv_container"):setVisible(false)
		arg_14_0:nodeByName("name_bottom"):setVisible(false)
		arg_14_0:nodeByName("title_bg"):setVisible(true)
		arg_14_0:nodeByName("text_order"):setString(arg_14_0.currentRound .. "/" .. #arg_14_0.herosB)
		arg_14_0:nodeByName("heroes_container"):setPositionY(160)
	end

	arg_14_0:addHeroCells()
end

function var_0_0.addHeroCells(arg_15_0)
	arg_15_0.heroesContainer:removeAllChildren()

	for iter_15_0, iter_15_1 in pairs(arg_15_0.enemyHeroes) do
		local var_15_0 = display.newNode()
		local var_15_1 = cc.p(100, 100)

		var_15_0:setContentSize(var_15_1)
		var_15_0:setPosition(cc.p(110 * (iter_15_0 - 1), 0))

		local var_15_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/memories_of_school/hero_avatar.csb")

		if var_0_6:summonType(iter_15_1.tableID_) ~= 4 then
			xyd.setAvatarBorderNewUI(iter_15_1, var_15_2:getChildByName("avatar"))
		end

		dump(var_0_6:summonType(iter_15_1.tableID_))

		if var_0_6:summonType(iter_15_1.tableID_) == 4 then
			xyd.setPetAvatarNewUI(var_15_2:getChildByName("avatar"), iter_15_1)
		end

		var_15_2:getChildByName("lv_txt"):setString(iter_15_1:getLevel())

		local var_15_3 = var_15_2:getChildByName("hp_bar")
		local var_15_4 = var_15_2:getChildByName("hp_di")
		local var_15_5 = var_15_2:getChildByName("dead_text")

		var_15_5:setString(var_0_4:translation("ALREADY_DEAD"))

		if var_15_5 then
			var_15_5:setVisible(false)
		end

		local var_15_6 = false
		local var_15_7 = false
		local var_15_8 = 0
		local var_15_9 = var_15_2:getChildByName("avatar_mask")

		var_15_9:setLocalZOrder(2)

		if not arg_15_0.team.isMonster then
			if arg_15_0.enemyHeroes and next(arg_15_0.enemyHeroes) then
				local var_15_10 = arg_15_0.enemyHeroes[iter_15_0]

				if var_15_10.healthStatus and var_15_10.healthStatus.health == 1 and var_15_10.healthStatus.hp ~= 0 then
					var_15_7 = true
					var_15_8 = var_15_10.healthStatus.hp
				elseif var_15_10.healthStatus and var_15_10.healthStatus.health == 1 and var_15_10.healthStatus.hp == 0 then
					var_15_8 = 0
					var_15_6 = true
				end
			end
		elseif arg_15_0.enemyHeroes and next(arg_15_0.enemyHeroes) then
			local var_15_11 = arg_15_0.enemyHeroes[iter_15_0]

			if var_15_11.healthStatus and var_15_11.healthStatus.hp == 0 then
				var_15_8 = 0
				var_15_6 = true
			elseif var_15_11.healthStatus and var_15_11.healthStatus.health == 1 then
				var_15_7 = true
				var_15_8 = var_15_11.healthStatus.hp
			end
		end

		if var_15_6 then
			var_15_3:setVisible(false)
			var_15_4:setVisible(false)
			var_15_5:setVisible(true)
			var_15_9:setVisible(true)
		elseif var_15_7 then
			var_15_3:setVisible(true)
			var_15_4:setVisible(true)
			var_15_5:setVisible(false)
			var_15_9:setVisible(false)

			hpPercent = var_15_8 / iter_15_1:getMaxHP() * 100

			var_15_3:setPercent(hpPercent)
		else
			var_15_3:setVisible(true)
			var_15_4:setVisible(true)
			var_15_5:setVisible(false)
			var_15_9:setVisible(false)
			var_15_3:setPercent(100)
		end

		var_15_0:addChild(var_15_2)
		arg_15_0.heroesContainer:addChild(var_15_0)
	end

	if arg_15_0.enemyPet then
		local var_15_12 = display.newNode()

		var_15_12:setContentSize(100, 100)
		var_15_12:setPosition(cc.p(110 * #arg_15_0.enemyHeroes, 0))
		xyd.setPetAvatar(var_15_12, arg_15_0.enemyPet, nil, true, nil, true)
		arg_15_0.heroesContainer:addChild(var_15_12)
	end
end

function var_0_0.didClose(arg_16_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_17_0)
	return arg_17_0:nodeByName("container")
end

return var_0_0
