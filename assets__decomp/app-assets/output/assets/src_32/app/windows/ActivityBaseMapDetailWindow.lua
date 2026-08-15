local var_0_0 = class("ActivityBaseMapDetailWindow", import("app.common.ui.BaseWindow"))

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:baseDefine()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.baseDefine(arg_4_0)
	arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_4_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_4_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.MAP_DETAIL_UPDATE, handler(arg_4_0, arg_4_0.updateSweepItemNum))
end

function var_0_0.updateModelContainer(arg_5_0)
	arg_5_0:nodeByName(arg_5_0.MODEL_CONTAINER):removeAllChildren()

	local var_5_0 = arg_5_0:nodeByName(arg_5_0.MODEL_CONTAINER):getContentSize()
	local var_5_1 = arg_5_0.campaignTable:monsterDisplay(arg_5_0.campaignID)
	local var_5_2 = var_5_1[#var_5_1]
	local var_5_3 = arg_5_0.campaignTable:smallBg(arg_5_0.campaignID)

	if var_5_3 and var_5_3 ~= "" then
		local var_5_4 = xyd.SpriteLoader.new(var_5_3, nil, nil, xyd.DefaultImageType.SMALL_MAP_BG)

		var_5_4:addTo(arg_5_0:nodeByName(arg_5_0.MODEL_CONTAINER))
		var_5_4:setPosition(cc.p(var_5_0.width / 2, var_5_0.height / 2))
	end

	if var_5_2 and var_5_2 > 0 then
		local var_5_5 = xyd.tables.hero:modelID(var_5_2)
		local var_5_6 = xyd.HeroAnimation.new(nil, var_5_5, xyd.tables.model:uiScale(var_5_5) * 0.8, {})

		var_5_6:addTo(arg_5_0:nodeByName(arg_5_0.MODEL_CONTAINER))
		var_5_6:setPosition(cc.p(var_5_0.width / 2, 30))
		var_5_6:idle()
	end
end

function var_0_0.updateEquipPanel(arg_6_0)
	local var_6_0 = 100
	local var_6_1 = xyd.tables.translation

	arg_6_0:nodeByName(arg_6_0.PANEL_ENEMY):removeAllChildren()
	arg_6_0:nodeByName(arg_6_0.EQUIP_TXT):setString(var_6_1:translation("ACTIVITY_MAP_MAY_GET_TXT"))

	local var_6_2 = arg_6_0.campaignTable:itemDisplay(arg_6_0.campaignID)
	local var_6_3 = arg_6_0.campaignTable:firstDisplay(arg_6_0.campaignID)

	if arg_6_0.star == 0 and var_6_3 and next(var_6_3) then
		var_6_2 = var_6_3

		arg_6_0:nodeByName(arg_6_0.EQUIP_TXT):setString(var_6_1:translation("ACTIVITY_MAP_FIRST_DROP_TXT"))
	end

	arg_6_0.itemTips = {}
	arg_6_0.listview = cc.ui.UIListView.new({
		viewRect = cc.rect(50, 10, arg_6_0:nodeByName(arg_6_0.PANEL_EQUIP):getContentSize().width - 50, var_6_0),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_6_0:nodeByName(arg_6_0.PANEL_EQUIP)):onScroll(handler(arg_6_0, arg_6_0.scrollListener))

	for iter_6_0 = 1, #var_6_2 do
		local var_6_4 = cc.Node:create()
		local var_6_5 = display.newNode()
		local var_6_6 = arg_6_0.listview:newItem()

		var_6_4:setContentSize(var_6_0, var_6_0)

		if var_6_2[iter_6_0] == -1 then
			xyd.setItemBorder(var_6_4, -1, nil, nil, starGift)
			xyd.setItemStarOnTop(var_6_4, 3)
		else
			xyd.setItemBorder(var_6_4, var_6_2[iter_6_0])
		end

		local var_6_7 = {
			id = var_6_2[iter_6_0]
		}

		arg_6_0:addTips(var_6_4, var_6_7)
		var_6_5:addChild(var_6_4)
		var_6_5:setContentSize(var_6_0, var_6_0)
		var_6_6:addContent(var_6_5)
		var_6_6:setItemSize(var_6_0, var_6_0)
		arg_6_0.listview:addItem(var_6_6)
	end

	arg_6_0.listview:reload()
end

function var_0_0.scrollListener(arg_7_0, arg_7_1)
	if arg_7_1.name == "began" then
		arg_7_0.scrollViewMoved_ = false
		arg_7_0.prevX_ = arg_7_1.x
	elseif arg_7_1.name == "moved" and 20 <= math.abs(arg_7_1.x - arg_7_0.prevX_) then
		arg_7_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateEnemyPanel(arg_8_0)
	local var_8_0 = xyd.tables.translation

	arg_8_0:nodeByName(arg_8_0.PANEL_ENEMY):removeAllChildren()
	arg_8_0:nodeByName(arg_8_0.ENEMY_TXT):setString(var_8_0:translation("ACTIVITY_MAP_ENEMY_INFO_TXT"))

	local var_8_1 = arg_8_0.campaignTable:monsterDisplay(arg_8_0.campaignID)
	local var_8_2 = arg_8_0.campaignTable:monsterStar(arg_8_0.campaignID)
	local var_8_3 = arg_8_0.campaignTable:monsterQuality(arg_8_0.campaignID)
	local var_8_4 = arg_8_0.campaignTable:monsterLevel(arg_8_0.campaignID)

	for iter_8_0 = 1, #var_8_1 do
		local var_8_5 = {}
		local var_8_6 = cc.Node:create()

		if iter_8_0 ~= #var_8_1 then
			var_8_5.isBoss = false

			var_8_6:setContentSize(90, 90)
		else
			var_8_5.isBoss = true

			var_8_6:setContentSize(107, 107)
		end

		xyd.setAvatarBorder(var_8_1[iter_8_0], var_8_6, var_8_3[iter_8_0], var_8_2[iter_8_0])
		arg_8_0:nodeByName(arg_8_0.PANEL_ENEMY):addChild(var_8_6)
		var_8_6:setPosition(iter_8_0 * 100 - 50, 0)

		var_8_5.id = var_8_1[iter_8_0]
		var_8_5.lev = var_8_4[iter_8_0]
		var_8_5.quality = var_8_3[iter_8_0]
		var_8_5.name = xyd.tables.hero:name(var_8_1[iter_8_0])
		var_8_5.desc = xyd.tables.hero:getDes(var_8_1[iter_8_0])
		var_8_5.isHero = true

		local var_8_7, var_8_8 = var_8_6:getPosition()

		var_8_6:setTouchEnabled(true)
		var_8_6:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				local var_9_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_9_1 = arg_8_0:convertToWorldSpace(cc.p(0, 0))

				if not var_9_0 then
					local var_9_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_8_5)

					xyd.adaptToWorldPosition(var_8_6, var_9_2)
				end

				return true
			elseif arg_9_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_9_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end
end

function var_0_0.updateSweepPanel(arg_10_0)
	local var_10_0 = arg_10_0.campaignTable:campaignType(arg_10_0.campaignID)
	local var_10_1 = arg_10_0:nodeByName(arg_10_0.PANEL_SWEEP)

	if var_10_0 == xyd.ActivityCampaignType.STORY or arg_10_0.star < 3 then
		var_10_1:setVisible(false)

		return
	end

	local var_10_2 = arg_10_0.campaignTable:costType(arg_10_0.campaignID)
	local var_10_3 = arg_10_0.campaignTable:winCost(arg_10_0.campaignID)

	var_10_1:getChildByName("once_button"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_11_0 = arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_0.sweepItemID)
			local var_11_1 = arg_10_0.selfPlayer:getEconomicItemNumByType(var_10_2)

			if var_11_0 < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("NO_ACTIVITY_MAP_SWEEP_ITEM")
				})

				return
			end

			if var_11_1 < var_10_3 then
				if var_10_2 == xyd.EconomicType.ENERGY then
					arg_10_0:buyEnergy()
				end

				return
			end

			local var_11_2 = {}

			var_11_2.sweep_num = 1
			var_11_2.campaign_id = arg_10_0.campaignID
			var_11_2.campaign_type = xyd.CampaignType.CHOCOLATE
			var_11_2.sweep_type = xyd.SweepType.ITEM_SWEEP
			var_11_2.tipMessage = arg_10_0.params and arg_10_0.params.tipMessage

			xyd.WindowManager.get():openWindow("sweep_window", var_11_2)
		end
	end)

	local var_10_4

	if arg_10_0.mapCampaignType == xyd.CampaignType.CHOCOLATE then
		var_10_4 = 10
	end

	var_10_1:getChildByName("multi_button"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = arg_10_0.selfPlayer:getBackpack():getItemNumByID(arg_10_0.sweepItemID)
			local var_12_1 = arg_10_0.selfPlayer:getEconomicItemNumByType(var_10_2)

			if var_12_0 < var_10_4 then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("NO_ACTIVITY_MAP_SWEEP_ITEM")
				})

				return
			end

			if var_12_1 < var_10_3 * var_10_4 then
				if var_10_2 == xyd.EconomicType.ENERGY then
					arg_10_0:buyEnergy()
				end

				return
			end

			local var_12_2 = {
				sweep_num = var_10_4,
				campaign_id = arg_10_0.campaignID,
				campaign_type = arg_10_0.mapCampaignType,
				sweep_type = xyd.SweepType.ITEM_SWEEP,
				tipMessage = arg_10_0.params and arg_10_0.params.tipMessage
			}

			xyd.WindowManager.get():openWindow("sweep_window", var_12_2)
		end
	end)
	arg_10_0:updateSweepItemNum()
end

function var_0_0.updateSweepItemNum(arg_13_0)
	local var_13_0 = arg_13_0.selfPlayer:getBackpack():getItemNumByID(arg_13_0.sweepItemID)
	local var_13_1 = string.format(xyd.tables.translation:translation("MAP_SWEEP_ITEM"), tostring(var_13_0))

	arg_13_0:nodeByName(arg_13_0.PANEL_SWEEP):getChildByName("sweep_item_num"):setString(var_13_1)
end

function var_0_0.updateStarContainer(arg_14_0)
	local var_14_0 = arg_14_0.campaignTable:campaignType(arg_14_0.campaignID)
	local var_14_1 = arg_14_0:nodeByName(arg_14_0.STAR_CONTAINER)

	for iter_14_0 = 1, 3 do
		var_14_1:getChildByName("star" .. iter_14_0):setVisible(iter_14_0 <= arg_14_0.star)
		var_14_1:getChildByName("star" .. iter_14_0 .. "_gray"):setVisible(true)
	end

	if var_14_0 == xyd.ActivityCampaignType.STORY then
		var_14_1:setVisible(false)
	else
		var_14_1:setVisible(true)
	end
end

function var_0_0.updateCostContainer(arg_15_0, arg_15_1)
	local var_15_0 = arg_15_0.campaignTable:campaignType(arg_15_0.campaignID)
	local var_15_1 = arg_15_0:nodeByName(arg_15_0.PANEL_COST)
	local var_15_2 = arg_15_0.campaignTable:winCost(arg_15_0.campaignID)

	if var_15_0 == xyd.ActivityCampaignType.STORY then
		var_15_1:setVisible(false)
	else
		var_15_1:setVisible(true)
	end

	var_15_1:getChildByName("txt_xiaohao"):setString(xyd.tables.translation:translation(arg_15_1 or "ACTIVITY_MAP_ENERGY_COST"))
	var_15_1:getChildByName("txt_energy"):setString(var_15_2)
end

function var_0_0.updateStartBtn(arg_16_0)
	local var_16_0 = import("app.model.Hero")
	local var_16_1 = import("app.model.Pet")

	arg_16_0:nodeByName(arg_16_0.START_BUTTON):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_17_0 = arg_16_0.campaignTable:costType(arg_16_0.campaignID)

			if arg_16_0.campaignTable:winCost(arg_16_0.campaignID) > arg_16_0.selfPlayer:getEconomicItemNumByType(var_17_0) then
				if var_17_0 == xyd.EconomicType.ENERGY then
					arg_16_0:buyEnergy()
				end

				return
			end

			local var_17_1 = {
				campaign_type = arg_16_0.mapCampaignType
			}

			arg_16_0.guild:loadAllTeamHeros(var_17_1, function(arg_18_0)
				local var_18_0 = false
				local var_18_1 = {}

				if arg_18_0 == xyd.error.OK then
					var_18_0 = true

					for iter_18_0, iter_18_1 in ipairs(arg_16_0.guild:getAllTeamHeros()) do
						local var_18_2 = var_16_0.new()

						var_18_2:populate(iter_18_1)

						var_18_2.player_name = iter_18_1.player_name
						var_18_2.rent_need_mana = iter_18_1.rent_need_mana
						var_18_2.can_rent = iter_18_1.can_rent
						var_18_2.player_id = iter_18_1.player_id

						table.insert(var_18_1, var_18_2)
					end
				end

				local var_18_3

				if arg_16_0.mapCampaignType == xyd.CampaignType.CHOCOLATE then
					var_18_3 = xyd.SelectTeamType.CHOCOLATE
				end

				local var_18_4 = {
					type = var_18_3,
					campaignID = arg_16_0.campaignID,
					campaignType = arg_16_0.mapCampaignType,
					isMercenary = var_18_0,
					allTeamHeros = var_18_1,
					battleID = arg_16_0.campaignTable:fightId(arg_16_0.campaignID),
					stories = {
						arg_16_0.campaignTable:preWarStory(arg_16_0.campaignID),
						nil,
						arg_16_0.campaignTable:victoryStory(arg_16_0.campaignID)
					}
				}

				if arg_16_0 then
					var_18_4.star = arg_16_0.star

					if arg_16_0.star and arg_16_0.star > 0 then
						var_18_4.stories = nil
					end
				end

				xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_18_4)
				xyd.WindowManager.get():closeWindow(arg_16_0)
			end)
		end
	end)
end

function var_0_0.updateTitleAndDesc(arg_19_0)
	local var_19_0 = arg_19_0.campaignTable:campaignName(arg_19_0.campaignID)
	local var_19_1 = arg_19_0.campaignTable:campaignDes(arg_19_0.campaignID)
	local var_19_2 = arg_19_0.campaignTable:campaignTips(arg_19_0.campaignID)

	arg_19_0:nodeByName(arg_19_0.TITLE):setString(var_19_0)
	arg_19_0:nodeByName(arg_19_0.TITLE):enableOutline(cc.c4b(61, 72, 131, 255), 2)
	arg_19_0:nodeByName(arg_19_0.DESC):setString(var_19_1)
	arg_19_0:nodeByName(arg_19_0.TIPS):setString(var_19_2)
end

function var_0_0.buyEnergy(arg_20_0)
	local var_20_0
	local var_20_1 = xyd.tables.translation
	local var_20_2 = 120

	arg_20_0.buyEnergyTimes = arg_20_0.selfPlayer.buyEnergyTimes
	arg_20_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_20_0.buyEnergyTimes + 1)
	arg_20_0.maxBuyTimes = xyd.tables.vip:numEnergy(arg_20_0.selfPlayer.vip)

	if arg_20_0.selfPlayer.privilegeLeftCardDay > 0 then
		local var_20_3 = xyd.tables.monthlyPrivilege:numEnergy(1)

		arg_20_0.maxBuyTimes = arg_20_0.maxBuyTimes + var_20_3
	end

	local var_20_4 = xyd.tables.misc.energyMaxLimit

	str = string.format(var_20_1:translation("ADD_ENERGY"), arg_20_0.buyEnergyCost, var_20_2, arg_20_0.buyEnergyTimes)

	if arg_20_0:isHasTiLiItem() then
		local var_20_5 = {
			text = str,
			callback = function()
				if arg_20_0.buyEnergyTimes >= arg_20_0.maxBuyTimes then
					str = string.format(var_20_1:translation("CAN_NOT_ADDENERGY"), arg_20_0.buyEnergyTimes)
					var_20_0 = xyd.AlertType.CONFIRM

					local var_21_0 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_21_0, function()
						local var_22_0 = {}

						var_22_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_22_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_20_0.colorMode)

					return
				end

				if arg_20_0.selfPlayer.energy >= var_20_4 then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_20_1:translation("TILI_LIMIT_INFO")
					})
					xyd.WindowManager.get():closeWindow("buy_tili")

					return
				end

				if arg_20_0.buyEnergyCost > arg_20_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_1:translation("ZUANSHI_ABSENCE"), function()
						xyd.WindowManager.get():openWindow("vip_recharge", {
							windowState = true
						})
					end, nil, nil, arg_20_0.colorMode)

					return
				end

				arg_20_0.addEnergyModel:addEnergy(function(arg_24_0)
					if arg_24_0 == xyd.error.OK then
						return true
					end
				end)
				xyd.WindowManager.get():closeWindow("buy_tili")
			end
		}

		xyd.WindowManager.get():openWindow("buy_tili", var_20_5)
	else
		local var_20_6 = xyd.luaStringSplit(str, "\n")

		xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_6, function()
			if arg_20_0.buyEnergyTimes >= arg_20_0.maxBuyTimes then
				str = string.format(var_20_1:translation("CAN_NOT_ADDENERGY"), arg_20_0.buyEnergyTimes)
				var_20_0 = xyd.AlertType.CONFIRM

				local var_25_0 = xyd.luaStringSplit(str, "\n")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_25_0, function()
					local var_26_0 = {}

					var_26_0.windowState = false

					xyd.WindowManager.get():openWindow("vip_recharge", var_26_0)
					xyd.WindowManager.get():closeWindow("add_energy")
				end, nil, nil, arg_20_0.colorMode)

				return
			end

			if arg_20_0.buyEnergyCost > arg_20_0.selfPlayer.crystal then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_20_1:translation("ZUANSHI_ABSENCE"), function()
					xyd.WindowManager.get():openWindow("vip_recharge", {
						windowState = true
					})
				end, nil, nil, arg_20_0.colorMode)

				return
			end

			arg_20_0.addEnergyModel:addEnergy(function(arg_28_0)
				if arg_28_0 == xyd.error.OK then
					return true
				end
			end)
			xyd.WindowManager.get():closeWindow("alert")
		end, nil, 0, arg_20_0.colorMode)
	end
end

function var_0_0.isHasTiLiItem(arg_29_0)
	local var_29_0 = arg_29_0.selfPlayer:getBackpack():getItems()

	for iter_29_0, iter_29_1 in pairs(var_29_0) do
		if xyd.tables.item:subType(iter_29_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

return var_0_0
