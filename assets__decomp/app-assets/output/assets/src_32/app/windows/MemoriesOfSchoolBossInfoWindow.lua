local var_0_0 = class("MemoriesOfSchoolBossInfoWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "march_team_info"
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.mazeFloor
local var_0_5 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
local var_0_6 = 120

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.enemiesinfo = arg_1_2.enemiesinfo
	arg_1_0.battleID = arg_1_2.battleID
	arg_1_0.boss_id = arg_1_2.boss_id
	arg_1_0.gridPos = arg_1_2.pos
	arg_1_0.currentRound = tonumber(arg_1_2.currentRound)
	arg_1_0.memoriesOfSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.MEMORIES_OF_SCHOOL)
	arg_1_0.backpack = var_0_5:getBackpack()
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)

	local var_1_0 = xyd.tables.battle:monsters(arg_1_2.battleID)

	monsterInfo = arg_1_0.enemiesinfo
	arg_1_0.enemyHeroes = {}

	local var_1_1 = {}

	for iter_1_0 = 1, #var_1_0 do
		local var_1_2 = {}

		for iter_1_1, iter_1_2 in ipairs(var_1_0[iter_1_0]) do
			local var_1_3 = var_0_2.new()

			var_1_3:populateWithTableID(iter_1_2)

			if monsterInfo[tostring(iter_1_2)] then
				local var_1_4 = {}

				var_1_4.health = 1
				var_1_4.hp = monsterInfo[tostring(iter_1_2)].hp
				var_1_4.is_reborn = monsterInfo[tostring(iter_1_2)].is_reborn
				var_1_4.mp = monsterInfo[tostring(iter_1_2)].mp
				var_1_3.healthStatus = var_1_4
			end

			table.insert(var_1_2, var_1_3)
		end

		if #var_1_2 ~= 0 then
			table.insert(var_1_1, var_1_2)
		end
	end

	arg_1_0.enemyHeroes = var_1_1[1]
	arg_1_0.boss = arg_1_0.enemyHeroes[1]
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.createBossModel(arg_4_0)
	local var_4_0 = arg_4_0.boss:getHeroModel()

	var_4_0:setScale(xyd.tables.model:scale(arg_4_0.boss:getModelID()) * 1.4)
	var_4_0:setContentSize(1, 1)
	var_4_0:setAnchorPoint(cc.p(0.5, 0))

	return var_4_0
end

function var_0_0.layout(arg_5_0)
	local var_5_0 = arg_5_0:container()

	arg_5_0:nodeByName("txt_title"):setString(var_0_3:translation("MEMORIES_OF_SCHOOL_TIPS2"))
	arg_5_0:nodeByName("title"):setString(var_0_3:translation("MEMORIES_OF_SCHOOL_TIPS2"))
	arg_5_0:nodeByName("txt_hp"):setString(var_0_3:translation("MEMORIES_OF_SCHOOL_TIPS3"))
	arg_5_0:nodeByName("txt_fight"):setString(var_0_3:translation("MEMORIES_OF_SCHOOL_TIPS10"))
	arg_5_0:createBossModel():addTo(arg_5_0:nodeByName("boss_model"))

	local var_5_1 = arg_5_0:nodeByName("start_btn")
	local var_5_2 = arg_5_0.memoriesOfSchool.baseInfo.now_floor
	local var_5_3 = var_0_4:tiliCost(var_5_2)[1]

	arg_5_0:nodeByName("tili_num"):setString(var_5_3)
	var_5_1:setVisible(true)
	var_5_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {
				campaignType = xyd.CampaignType.MEMORIES_OF_SCHOOL
			}

			if event == xyd.MazeType.MONSTER then
				var_6_0.battleID = arg_5_0.battleID
				var_6_0.campaignID = arg_5_0.battleID
			else
				local var_6_1 = arg_5_0.battleID

				var_6_0.battleID = var_6_1
				var_6_0.campaignID = var_6_1
			end

			var_6_0.type = xyd.SelectTeamType.MEMORIES_OF_SCHOOL_MONSTER

			if var_0_5:getEnergy() < var_5_3 then
				arg_5_0:openTiliWindow()
			else
				arg_5_0.memoriesOfSchool:setBattleGrid(arg_5_0.gridPos)
				xyd.WindowManager.get():openWindow("battle_select_team", var_6_0)
			end
		end
	end)

	if not arg_5_0.boss.healthStatus or arg_5_0.boss.healthStatus and arg_5_0.boss.healthStatus.health == 0 then
		arg_5_0:nodeByName("hp_process"):setPercent(100)
		arg_5_0:nodeByName("hp_percent"):setString("100" .. "%")
	else
		arg_5_0:nodeByName("hp_process"):setPercent(arg_5_0.boss.healthStatus.hp / arg_5_0.boss:getMaxHP() * 100)
		arg_5_0:nodeByName("hp_percent"):setString(math.floor(arg_5_0.boss.healthStatus.hp / arg_5_0.boss:getMaxHP() * 10000) / 100 .. "%")
	end

	arg_5_0:nodeByName("hp_percent"):enableOutline(cc.c4b(0, 0, 0, 255), 1)

	local var_5_4 = xyd.tables.mazeCampaign:skills(arg_5_0.boss_id)

	arg_5_0:setSkillContainer(var_5_4)
end

function var_0_0.openTiliWindow(arg_7_0)
	local var_7_0 = var_0_5.buyEnergyTimes
	local var_7_1 = xyd.tables.refreshCost:buyEnergyCost(var_7_0 + 1)
	local var_7_2 = xyd.tables.vip:numEnergy(var_0_5.vip)

	if var_0_5.privilegeLeftCardDay > 0 then
		var_7_2 = var_7_2 + xyd.tables.monthlyPrivilege:numEnergy(1)
	end

	local var_7_3 = xyd.tables.misc.energyMaxLimit

	if var_7_3 <= var_0_5.energy and var_7_0 < var_7_2 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_3:translation("TILI_LIMIT_INFO")
		})
	else
		local function var_7_4()
			if var_7_0 >= var_7_2 then
				local var_8_0 = string.format(var_0_3:translation("CAN_NOT_ADDENERGY"), var_7_0)
				local var_8_1 = xyd.luaStringSplit(var_8_0, "\n")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_8_1, function()
					local var_9_0 = {}

					var_9_0.windowState = false

					xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					xyd.WindowManager.get():closeWindow("add_energy")
				end, nil, nil, arg_7_0.colorMode)
			elseif var_0_5.energy >= var_7_3 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_3:translation("TILI_LIMIT_INFO")
				})
				xyd.WindowManager.get():closeWindow("buy_tili")
			elseif var_7_1 > var_0_5.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
					local var_10_0 = {}

					var_10_0.windowState = true

					xyd.WindowManager.get():openWindow("vip_recharge", var_10_0)
				end, nil, nil, arg_7_0.colorMode)
			else
				arg_7_0.addEnergyModel:addEnergy()
				xyd.WindowManager.get():closeWindow("buy_tili")
			end
		end

		local var_7_5 = string.format(var_0_3:translation("ADD_ENERGY"), var_7_1, var_0_6, var_7_0)

		if arg_7_0.backpack:isHasEnergyItem() then
			local var_7_6 = {
				text = var_7_5,
				callback = var_7_4
			}

			xyd.WindowManager.get():openWindow("buy_tili", var_7_6)
		else
			local var_7_7 = xyd.luaStringSplit(var_7_5, "\n")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_7, function()
				if var_7_0 >= var_7_2 then
					local var_11_0 = string.format(var_0_3:translation("CAN_NOT_ADDENERGY"), var_7_0)
					local var_11_1 = xyd.luaStringSplit(var_11_0, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_1, function()
						local var_12_0 = {}

						var_12_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_7_0.colorMode)
				elseif var_7_1 > var_0_5.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("ZUANSHI_ABSENCE"), function()
						local var_13_0 = {}

						var_13_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
					end, nil, nil, arg_7_0.colorMode)
				else
					arg_7_0.addEnergyModel:addEnergy()
					xyd.WindowManager.get():closeWindow("alert")
				end
			end, nil, 0, arg_7_0.colorMode)
		end
	end
end

function var_0_0.setSkillContainer(arg_14_0, arg_14_1)
	arg_14_0.skillContainer = arg_14_0:nodeByName("skill_container")

	local var_14_0 = arg_14_1
	local var_14_1 = {}

	arg_14_0.skillItems = {}

	local var_14_2 = arg_14_0.skillContainer:getChildren()
	local var_14_3 = arg_14_0.skillContainer:getHeight()

	for iter_14_0, iter_14_1 in pairs(var_14_0) do
		local var_14_4 = display.newNode()

		var_14_4:setContentSize(var_14_3, var_14_3)

		local var_14_5 = xyd.tables.skill:icon(iter_14_1)

		if var_14_5 and var_14_5 ~= "" then
			local var_14_6 = xyd.SpriteLoader.new(var_14_5, nil, nil, xyd.DefaultImageType.SKILL_ICON)
			local var_14_7 = xyd.AssetLoader.get():loadSprite("windows/memories_of_school/skill_icon.png")

			var_14_7:setPosition(var_14_4:getWidth() / 2, var_14_4:getHeight() / 2)
			var_14_7:setAnchorPoint(cc.p(0.5, 0.5))
			var_14_7:scale(var_14_4:getWidth() / var_14_7:getWidth() / 20 * 19)

			stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

			stencil:setPosition(var_14_4:getWidth() / 2, var_14_4:getHeight() / 2)
			stencil:setAnchorPoint(cc.p(0.5, 0.5))
			stencil:scale(var_14_4:getWidth() / stencil:getWidth())

			local var_14_8 = cc.ClippingNode:create()

			var_14_8:setStencil(stencil)
			var_14_8:setInverted(true)
			var_14_8:setAlphaThreshold(0)
			var_14_4:addChild(var_14_8)
			var_14_8:addChild(var_14_6)
			var_14_6:align(display.LEFT_BOTTOM, 0, 0)
			var_14_6:scale((var_14_4:getWidth() - 3) / var_14_6:getWidth())
			var_14_4:addTo(arg_14_0.skillContainer)
			var_14_7:addTo(var_14_4)
			table.insert(arg_14_0.skillItems, var_14_4)
			var_14_4:x((iter_14_0 - 1) * (var_14_3 + 10))
			var_14_4:y(0)
			arg_14_0:createSkillTip(iter_14_0, iter_14_1)
		end
	end
end

function var_0_0.createSkillTip(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = {
		has_jiantou = false,
		id = arg_15_2
	}
	local var_15_1 = arg_15_0.skillItems[arg_15_1]
	local var_15_2, var_15_3 = var_15_1:getPosition()
	local var_15_4, var_15_5 = arg_15_0.skillContainer:getPosition()
	local var_15_6 = var_15_2 + var_15_4
	local var_15_7 = var_15_3 + var_15_5
	local var_15_8 = display.newNode()

	var_15_8:setPosition(0, 0)
	var_15_8:setAnchorPoint(cc.p(0, 0))
	var_15_8:setContentSize(var_15_1:getContentSize())
	var_15_8:setTouchEnabled(true)
	var_15_8:addTo(var_15_1)
	var_15_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			if not xyd.WindowManager.get():getWindow("skill_tips") then
				local var_16_0 = xyd.WindowManager.get():openWindow("skill_tips", var_15_0)

				xyd.adaptToWorldPosition(var_15_8, var_16_0)
			end

			return true
		elseif arg_16_0.name == "ended" then
			xyd.WindowManager.get():closeWindow("skill_tips")
		end
	end)
end

function var_0_0.didClose(arg_17_0)
	var_0_0.super.didClose()
end

function var_0_0.container(arg_18_0)
	return arg_18_0:nodeByName("container")
end

return var_0_0
