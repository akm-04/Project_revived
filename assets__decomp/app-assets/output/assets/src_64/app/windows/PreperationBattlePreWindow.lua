local var_0_0 = class("PreperationBattlePreWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = xyd.tables.attr
local var_0_4 = import("app.model.Hero")
local var_0_5 = 120
local var_0_6 = 50001013

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.star = arg_1_2.star
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.dailyLimit = arg_1_2.dailyLimit
	arg_1_0.levelNumber = arg_1_2.levelNumber
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:setReward()
	arg_2_0:setHero()
end

function var_0_0.willClose(arg_3_0)
	local var_3_0 = xyd.WindowManager.get():getWindow("time_travel")

	if var_3_0 then
		var_3_0:updateItems()
	end
end

function var_0_0.layout(arg_4_0)
	local function var_4_0()
		local var_5_0
		local var_5_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		arg_4_0.buyEnergyTimes = var_5_1.buyEnergyTimes
		arg_4_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_4_0.buyEnergyTimes + 1)
		arg_4_0.maxBuyTimes = xyd.tables.vip:numEnergy(var_5_1.vip)

		local var_5_2 = xyd.tables.misc.energyMaxLimit

		str = string.format(var_0_1:translation("ADD_ENERGY"), arg_4_0.buyEnergyCost, var_0_5, arg_4_0.buyEnergyTimes)

		if arg_4_0:isHasTiLiItem() then
			local var_5_3 = {
				text = str,
				callback = function()
					if arg_4_0.buyEnergyTimes >= arg_4_0.maxBuyTimes then
						str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_4_0.buyEnergyTimes)
						var_5_0 = xyd.AlertType.CONFIRM

						local var_6_0 = xyd.luaStringSplit(str, "\n")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
							local var_7_0 = {}

							var_7_0.windowState = false

							xyd.WindowManager.get():openWindow("vip_recharge", var_7_0)
							xyd.WindowManager.get():closeWindow("add_energy")
						end, nil, nil, arg_4_0.colorMode)
					elseif arg_4_0.player_.energy >= var_5_2 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TILI_LIMIT_INFO")
						})
						xyd.WindowManager.get():closeWindow("buy_tili")
					else
						local var_6_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_4_0.buyEnergyCost > var_6_1.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_8_0 = {}

								var_8_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_8_0)
							end, nil, nil, arg_4_0.colorMode)
						else
							arg_4_0.addEnergyModel:addEnergy(function(arg_9_0)
								if arg_9_0 == xyd.error.OK then
									return true
								end
							end)
							xyd.WindowManager.get():closeWindow("buy_tili")
						end
					end
				end
			}

			xyd.WindowManager.get():openWindow("buy_tili", var_5_3)
		else
			local var_5_4 = xyd.luaStringSplit(str, "\n")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_5_4, function()
				local var_10_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if arg_4_0.buyEnergyTimes >= arg_4_0.maxBuyTimes then
					str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_4_0.buyEnergyTimes)
					var_5_0 = xyd.AlertType.CONFIRM

					local var_10_1 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_1, function()
						local var_11_0 = {}

						var_11_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_4_0.colorMode)
				elseif arg_4_0.buyEnergyCost > var_10_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_12_0 = {}

						var_12_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
					end, nil, nil, arg_4_0.colorMode)
				else
					arg_4_0.addEnergyModel:addEnergy(function(arg_13_0)
						if arg_13_0 == xyd.error.OK then
							return true
						end
					end)
					xyd.WindowManager.get():closeWindow("alert")
				end
			end, nil, 0, arg_4_0.colorMode)
		end
	end

	local var_4_1 = xyd.tables.challenge:monster(arg_4_0.campaignType)

	arg_4_0.hero = var_0_4.new()

	local var_4_2 = xyd.tables.challenge:battleModleScale(arg_4_0.campaignType)

	arg_4_0:nodeByName("model_container"):setScale(var_4_2)
	arg_4_0.hero:populateWithTableID(var_4_1)
	arg_4_0:updateHeroModel(arg_4_0.hero)

	if xyd.tables.challenge:upPosition(arg_4_0.campaignType) == 1 then
		arg_4_0:nodeByName("model_container"):setPosition(60, 220)
	end

	if xyd.tables.challenge:upPosition(arg_4_0.campaignType) == 2 then
		arg_4_0:nodeByName("model_container"):setPosition(115, 230)
	end

	if xyd.tables.challenge:upPosition(arg_4_0.campaignType) == 3 then
		arg_4_0:nodeByName("model_container"):setPosition(85, 220)
	end

	local var_4_3 = xyd.tables.challenge:challengeName(arg_4_0.campaignType)

	arg_4_0:nodeByName("txt_title"):setString(var_4_3)
	arg_4_0:nodeByName("txt_boss_des"):setString(xyd.tables.challenge:skillType1(arg_4_0.campaignType))

	local var_4_4 = {
		size = 22,
		color = cc.c3b(64, 64, 64)
	}
	local var_4_5 = xyd.AssetLoader.get():loadLabel(var_4_4)

	var_4_5:addTo(arg_4_0:nodeByName("txt_boss_des"):getParent())
	var_4_5:setMaxLineWidth(410)
	var_4_5:setAnchorPoint(cc.p(0, 1))
	var_4_5:setPosition(arg_4_0:nodeByName("node_des_boss_pos"):getPosition())
	var_4_5:setString(xyd.tables.challenge:skillTranslation1(arg_4_0.campaignType))
	arg_4_0:nodeByName("txt_boss_skill"):setString(xyd.tables.challenge:skillType2(arg_4_0.campaignType))

	local var_4_6 = {
		size = 22,
		color = cc.c3b(64, 64, 64)
	}
	local var_4_7 = xyd.AssetLoader.get():loadLabel(var_4_6)

	var_4_7:setMaxLineWidth(410)
	var_4_7:addTo(arg_4_0:nodeByName("txt_boss_skill"):getParent())
	var_4_7:setAnchorPoint(cc.p(0, 1))
	var_4_7:setPosition(arg_4_0:nodeByName("node_des_skill_pos"):getPosition())
	var_4_7:setString(xyd.tables.challenge:skillTranslation2(arg_4_0.campaignType))

	for iter_4_0 = 1, 3 do
		if iter_4_0 <= arg_4_0.star then
			arg_4_0:nodeByName("pic_star_" .. iter_4_0):show()
			arg_4_0:nodeByName("pic_star_grey_" .. iter_4_0):hide()
		else
			arg_4_0:nodeByName("pic_star_" .. iter_4_0):hide()
			arg_4_0:nodeByName("pic_star_grey_" .. iter_4_0):show()
		end
	end

	arg_4_0:nodeByName("txt_btn_sweep"):setString(var_0_1:translation("MAP_SWEEP"))

	arg_4_0.hasItemNum = arg_4_0.player_:getBackpack():getItemNumByID(var_0_6)

	arg_4_0:nodeByName("txt_sweep_num"):setString(arg_4_0.hasItemNum)

	if arg_4_0.star == 3 and arg_4_0.player_.lev >= 70 then
		arg_4_0:nodeByName("btn_sweep"):setVisible(true)
		arg_4_0:nodeByName("txt_sweep"):setVisible(true)
		arg_4_0:nodeByName("txt_sweep_num"):setVisible(true)
	else
		arg_4_0:nodeByName("btn_sweep"):setVisible(false)
		arg_4_0:nodeByName("txt_sweep"):setVisible(false)
		arg_4_0:nodeByName("txt_sweep_num"):setVisible(false)
	end

	arg_4_0:nodeByName("btn_sweep"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_4_0.dailyLimit <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("UNLIMIT_NO_DAILY_TIMES")
				})

				return
			end

			if arg_4_0.player_.energy < xyd.tables.campaign:energyCost(arg_4_0.campaignID) then
				var_4_0()
			else
				local var_14_0 = {
					sweep_num = 1,
					campaign_id = arg_4_0.campaignID,
					campaign_type = arg_4_0.campaignType
				}

				if arg_4_0.hasItemNum < 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("SWEEP_ITEM_ABSENCE"), 1),
						var_0_1:translation("SWEEP_ITEM_CONTINUE")
					}, function()
						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).crystal < 1 then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_16_0 = {}

								var_16_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
							end, nil, nil, arg_4_0.colorMode)
						else
							var_14_0.sweep_type = xyd.SweepType.CRYSTAL_SWEEP

							xyd.WindowManager.get():openWindow("sweep_window", var_14_0)
						end
					end, nil, 0, arg_4_0.colorMode)
				else
					var_14_0.sweep_type = xyd.SweepType.ITEM_SWEEP

					xyd.WindowManager.get():openWindow("sweep_window", var_14_0)
				end
			end
		end
	end)

	local var_4_8 = var_0_1:translation("CHALLENAGE") .. var_0_1:translation("ROMAN_NUMERALS_" .. arg_4_0.levelNumber)

	arg_4_0:nodeByName("txt_difficult"):setString(var_4_8)
	arg_4_0:nodeByName("btn_fight"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			arg_4_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

			if arg_4_0.dailyLimit <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TRIAL_TIMES_ERROR")
				})
			else
				if arg_4_0.player_.energy < xyd.tables.campaign:energyCost(arg_4_0.campaignID) then
					var_4_0()

					return
				end

				local var_17_0 = {
					campaign_type = arg_4_0.campaignType
				}

				arg_4_0.guild:loadAllTeamHeros(var_17_0, function(arg_18_0)
					local var_18_0 = false
					local var_18_1 = {}
					local var_18_2 = false
					local var_18_3 = false

					if arg_18_0 == xyd.error.OK then
						var_18_0 = true

						for iter_18_0, iter_18_1 in ipairs(arg_4_0.guild:getAllTeamHeros()) do
							local var_18_4 = var_0_4.new()

							var_18_4:populate(iter_18_1)

							var_18_4.player_name = iter_18_1.player_name
							var_18_4.rent_need_mana = iter_18_1.rent_need_mana
							var_18_4.can_rent = iter_18_1.can_rent
							var_18_4.player_id = iter_18_1.player_id

							table.insert(var_18_1, var_18_4)

							if iter_18_1.color >= xyd.EquipQuality.PURPLE then
								var_18_2 = true
							end
						end
					end

					for iter_18_2, iter_18_3 in pairs(arg_4_0.player_.heros_) do
						if iter_18_3.color_ >= xyd.EquipQuality.PURPLE then
							var_18_3 = true

							break
						end
					end

					local var_18_5 = xyd.tables.challenge:hero_recommend(arg_4_0.campaignType)
					local var_18_6 = {
						isPreperation = true,
						type = xyd.SelectTeamType.CAMPAIGN,
						isMercenary = var_18_0,
						allTeamHeros = var_18_1,
						campaignID = arg_4_0.campaignID,
						campaignType = arg_4_0.campaignType,
						hasPurpleHero = var_18_3,
						hasGuildPurpleHero = var_18_2,
						recommendHeros = var_18_5
					}

					if var_18_2 == false and var_18_3 == false then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("WORLD_BOSS_HAS_NO_HERO")
						})
					else
						xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_18_6)
					end
				end)
			end
		end
	end)
end

function var_0_0.isHasTiLiItem(arg_19_0)
	local var_19_0 = arg_19_0.player_:getBackpack():getItems()

	for iter_19_0, iter_19_1 in pairs(var_19_0) do
		if xyd.tables.item:subType(iter_19_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

function var_0_0.updateHeroModel(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_1:getHeroModel()

	var_20_0:setTouchSwallowEnabled(false)

	local var_20_1 = arg_20_0:nodeByName("model_container"):getContentSize().width / 2

	var_20_0:setPosition(cc.p(var_20_1, 0))
	arg_20_0:nodeByName("model_container"):removeAllChildren()
	var_20_0:addTo(arg_20_0:nodeByName("model_container"))
end

function var_0_0.setHero(arg_21_0)
	arg_21_0:nodeByName("txt_rec_hero"):setString(var_0_1:translation("RECOMMENDED_HERO"))

	local var_21_0 = xyd.tables.challenge:hero_recommend(arg_21_0.campaignType)
	local var_21_1 = arg_21_0:nodeByName("container_hero")
	local var_21_2 = var_21_1:getContentSize()

	arg_21_0.hero_list = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, var_21_2.width, var_21_2.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_BOTTOM
	}):addTo(var_21_1):onScroll(handler(arg_21_0, arg_21_0.scrollListener)):setBounceable(false)

	arg_21_0.hero_list:setTouchSwallowEnabled(true)

	for iter_21_0 = 1, #var_21_0 do
		local var_21_3 = arg_21_0.hero_list:newItem()
		local var_21_4 = display.newNode()
		local var_21_5 = cc.Node:create()

		var_21_5:setContentSize(80, 80)
		xyd.setAvatarBorder(var_21_0[iter_21_0], var_21_5, 1, xyd.tables.hero:initialStar(var_21_0[iter_21_0]))

		local var_21_6 = {}

		arg_21_0:tipsFormat(var_21_5, var_21_0[iter_21_0], var_21_6)
		arg_21_0:addTips(var_21_5, var_21_6)
		var_21_5:addTo(var_21_4)
		var_21_5:setTouchEnabled(true)
		var_21_5:setTouchSwallowEnabled(false)
		var_21_4:setContentSize(80, 80)
		var_21_3:addContent(var_21_4)
		var_21_3:setItemSize(80, 80)
		arg_21_0.hero_list:addItem(var_21_3)
	end

	arg_21_0.hero_list:reload()
end

function var_0_0.scrollListener(arg_22_0, arg_22_1)
	if arg_22_1.name == "began" then
		arg_22_0.startClick_ = true
		arg_22_0.prevX_ = arg_22_1.x
	elseif arg_22_1.name == "moved" and 20 <= math.abs(arg_22_1.x - arg_22_0.prevX_) then
		arg_22_0.startClick_ = false
	end
end

function var_0_0.setReward(arg_23_0)
	local var_23_0
	local var_23_1

	;({
		color = cc.c3b(255, 255, 255)
	}).size = 24

	if arg_23_0.star == 0 then
		var_23_0 = xyd.tables.campaign:firstDisplay(arg_23_0.campaignID)
		var_23_1 = xyd.tables.campaign:firstNumber(arg_23_0.campaignID)

		local var_23_2 = arg_23_0:nodeByName("txt_first_des")

		var_23_2:setString(var_0_1:translation("FIRST_CHALLENAGE_DES"))
		var_23_2:enableShadow(cc.c4b(11, 11, 11, 0), cc.size(1, -1), 1)
	else
		var_23_0 = xyd.tables.campaign:itemDisplay(arg_23_0.campaignID)

		local var_23_3 = arg_23_0:nodeByName("txt_first_des")

		var_23_3:setString(var_0_1:translation("CAN_GET_REWARD"))
		var_23_3:enableShadow(cc.c4b(11, 11, 11, 0), cc.size(1, -1), 1)
	end

	arg_23_0.itemTips = {}

	local var_23_4 = arg_23_0:nodeByName("container_reward")
	local var_23_5 = var_23_4:getContentSize()

	arg_23_0.award_list = cc.ui.UIListView.new({
		touchOnContent = true,
		viewRect = cc.rect(0, 0, var_23_5.width, var_23_5.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_BOTTOM
	}):addTo(var_23_4):onScroll(handler(arg_23_0, arg_23_0.scrollListener)):setBounceable(false)

	arg_23_0.award_list:setTouchSwallowEnabled(true)

	for iter_23_0 = 1, #var_23_0 do
		local var_23_6 = arg_23_0.award_list:newItem()
		local var_23_7 = display.newNode()
		local var_23_8 = cc.Node:create()

		var_23_8:setContentSize(80, 80)

		if arg_23_0.star == 0 then
			xyd.setItemBorder(var_23_8, var_23_0[iter_23_0], false, false, var_23_1[iter_23_0])
		else
			xyd.setItemBorder(var_23_8, var_23_0[iter_23_0])
		end

		local var_23_9 = {}

		arg_23_0:tipsFormat(var_23_8, var_23_0[iter_23_0], var_23_9)
		arg_23_0:addTips(var_23_8, var_23_9)
		var_23_8:addTo(var_23_7)
		var_23_8:setTouchEnabled(true)
		var_23_8:setTouchSwallowEnabled(false)
		var_23_7:setContentSize(80, 80)
		var_23_6:addContent(var_23_7)
		var_23_6:setItemSize(80, 80)
		arg_23_0.award_list:addItem(var_23_6)
	end

	arg_23_0.award_list:reload()
end

function var_0_0.tipsFormat(arg_24_0, arg_24_1, arg_24_2, arg_24_3)
	arg_24_3.id = arg_24_2
	arg_24_3.lev = xyd.tables.item:level(arg_24_2)

	if xyd.tables.item:type(arg_24_2) == -1 then
		arg_24_3.tipsType = 0
		arg_24_3.desc1 = xyd.tables.hero:getDes(arg_24_2)
	elseif specialItem then
		arg_24_3.tipsType = 1
		arg_24_3.id = -3
	else
		arg_24_3.tipsType = 1
		arg_24_3.desc1 = xyd.tables.item:desc1(arg_24_2)
		arg_24_3.desc2 = xyd.tables.item:desc2(arg_24_2)
	end

	arg_24_3.hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(arg_24_2)
	arg_24_3.name = xyd.tables.item:name(arg_24_2)
end

function var_0_0.didOpen(arg_25_0, arg_25_1)
	arg_25_0:addBlockLayer()
end

function var_0_0.didClose(arg_26_0)
	return
end

function var_0_0.loadChallenge(arg_27_0, arg_27_1, arg_27_2)
	xyd.Backend.get():request(arg_27_1, {}, function(arg_28_0, arg_28_1)
		if arg_27_2 then
			arg_27_2(arg_28_0, arg_28_1)
		end
	end)
end

return var_0_0
