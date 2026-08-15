local var_0_0 = class("MapDetailWindow", import("app.common.ui.BaseWindow"))

var_0_0.START_BUTTON = "start"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_DESC = "txt_desc"
var_0_0.TXT_XIAOHAO = "txt_xiaohao"
var_0_0.TXT_ENERGY = "txt_energy"
var_0_0.TXT_ENEMY = "txt_enemy"
var_0_0.TXT_EQUIP = "txt_equip"
var_0_0.PANEL_EQUIP = "panel_equip"
var_0_0.PANEL_ENEMY = "panel_enemy"
var_0_0.PANEL_SWEEP = "panel_sweep"
var_0_0.PANEL_LEFT = "panel_left"

local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.battle
local var_0_3 = xyd.tables.campaign
local var_0_4 = 3
local var_0_5 = 10
local var_0_6 = 5
local var_0_7 = 3
local var_0_8 = 2
local var_0_9 = 50001013
local var_0_10 = 120
local var_0_11 = 113
local var_0_12 = import("app.model.Hero")
local var_0_13 = import("app.model.Pet")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	if xyd.WindowManager.get():getWindow("activities") then
		xyd.WindowManager.get():closeWindow("activities")
	end

	arg_1_0.params = arg_1_2
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.max_xg = arg_1_0.campaignID % 10

	if arg_1_2.maxOK then
		arg_1_0.clgStar = 3
	else
		arg_1_0.clgStar = arg_1_0.max_xg - 1
	end

	arg_1_0.cur_xg = arg_1_0.max_xg
	arg_1_0.campaignType = arg_1_2.campaignType
	arg_1_0.star = arg_1_2.star
	arg_1_0.challengeType = {}
	arg_1_0.challengeType[1] = var_0_2:modeType(var_0_3:fightID(arg_1_0.campaignID - arg_1_0.max_xg + 1))
	arg_1_0.challengeType[2] = var_0_2:modeType(var_0_3:fightID(arg_1_0.campaignID - arg_1_0.max_xg + 2))
	arg_1_0.challengeType[3] = var_0_2:modeType(var_0_3:fightID(arg_1_0.campaignID - arg_1_0.max_xg + 3))
	arg_1_0.challengeTypeTxt = xyd.split(var_0_1:translation("CHALLENGE_MODEL_NAME"), ",")

	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.addEnergyModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ADD_ENERGY)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
	arg_1_0.needItemComposeNum = arg_1_2.needItemComposeNum
end

function var_0_0.layout(arg_2_0)
	if arg_2_0.campaignType == xyd.CampaignType.CHALLENGE then
		arg_2_0:nodeByName("clgStar_container"):setVisible(true)
		arg_2_0:nodeByName("star_container"):setVisible(false)

		for iter_2_0 = 1, 3 do
			if iter_2_0 > arg_2_0.clgStar then
				arg_2_0:nodeByName("clgIcon" .. iter_2_0):setVisible(false)
				arg_2_0:nodeByName("clgIcon" .. iter_2_0 .. "_gray"):loadTexture("windows/map_window/challenge_type" .. arg_2_0.challengeType[iter_2_0] .. "_s_gray.png")
			else
				arg_2_0:nodeByName("clgIcon" .. iter_2_0):loadTexture("windows/map_window/challenge_type" .. arg_2_0.challengeType[iter_2_0] .. "_s.png")
			end
		end
	elseif arg_2_0.campaignType == xyd.CampaignType.SAKURA2_WAR then
		arg_2_0:nodeByName("clgStar_container"):setVisible(false)
		arg_2_0:nodeByName("star_container"):setVisible(false)
	else
		arg_2_0:nodeByName("clgStar_container"):setVisible(false)
		arg_2_0:nodeByName("star_container"):setVisible(true)

		for iter_2_1 = 1, 3 do
			if iter_2_1 > arg_2_0.star then
				arg_2_0:nodeByName("star" .. iter_2_1):setVisible(false)
			else
				arg_2_0:nodeByName("star" .. iter_2_1):setVisible(true)
			end
		end
	end

	local var_2_0 = arg_2_0.campaignID
	local var_2_1 = arg_2_0:nodeByName("title_pos")

	var_2_1:setString(xyd.tables.campaign:campaignName(var_2_0))

	local var_2_2 = xyd.tables.campaign:campaignDesc(var_2_0)

	arg_2_0:nodeByName(var_0_0.TXT_DESC):setString(var_2_2)

	local var_2_3 = xyd.tables.campaign:energyCost(var_2_0)

	arg_2_0:nodeByName(var_0_0.TXT_ENERGY):setString(var_2_3)
	arg_2_0:nodeByName(var_0_0.TXT_XIAOHAO):setString(var_0_1:translation("MAP_TILI_TXT"))
	arg_2_0:nodeByName(var_0_0.TXT_ENEMY):setString(var_0_1:translation("MAP_ENEMY_TXT"))
	arg_2_0:nodeByName(var_0_0.TXT_EQUIP):setString(var_0_1:translation("MAP_GET_TXT"))
	arg_2_0:nodeByName(var_0_0.PANEL_ENEMY):removeAllChildren()

	if xyd.tables.campaign:chapter(var_2_0) >= xyd.tables.misc.energyReduceChapter then
		local var_2_4 = xyd.AssetLoader.get():loadSprite("windows/map_window/campaign_hand.png")

		var_2_4:addTo(arg_2_0)
		var_2_4:setAnchorPoint(cc.p(1, 0.5))

		local var_2_5, var_2_6 = var_2_1:getPosition()

		var_2_4:setPosition(var_2_5 - var_2_1:getContentSize().width / 2 - 40, var_2_6)
		var_2_4:setTouchEnabled(true)
		var_2_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
			if arg_3_0.name == "began" then
				local var_3_0 = {
					message = var_0_1:translation("CAMPAIGN_DEBUFF_TIP")
				}

				var_3_0.isAutoClose = 0
				var_3_0.txtSize = 24
				var_3_0.isOutLine = 0

				local var_3_1 = xyd.WindowManager.get():openWindow("toast", var_3_0)
				local var_3_2 = arg_2_0:convertToWorldSpace(cc.p(0, 0))
				local var_3_3, var_3_4 = var_2_4:getPosition()
				local var_3_5 = arg_2_0:convertToWorldSpace(cc.p(var_3_3, var_3_4 + var_2_4:getHeight() / 2 + var_3_1:getWndHeight() / 2 + 5))

				var_3_1:setPosition(var_3_5)

				return true
			elseif arg_3_0.name == "ended" then
				local var_3_6 = xyd.WindowManager.get():getWindow("toast")

				if var_3_6 then
					xyd.WindowManager.get():closeWindow(var_3_6.name)
				end
			end
		end)
	end

	local var_2_7 = xyd.tables.campaign:monsterDisplay(var_2_0)
	local var_2_8 = xyd.tables.campaign:monsterStar(var_2_0)
	local var_2_9 = xyd.tables.campaign:monsterQuality(var_2_0)
	local var_2_10 = xyd.tables.campaign:monsterLevel(var_2_0)

	arg_2_0.sweepNum = 0
	arg_2_0.hasItemNum = arg_2_0.player_:getBackpack():getItemNumByID(var_0_9)
	arg_2_0.monsterTips = {}

	for iter_2_2 = 1, #var_2_7 do
		local var_2_11 = {}
		local var_2_12 = cc.Node:create()

		if iter_2_2 ~= #var_2_7 then
			var_2_11.isBoss = false

			var_2_12:setContentSize(110, 110)
		else
			var_2_11.isBoss = true

			var_2_12:setContentSize(127, 127)
		end

		xyd.setAvatarBorder(var_2_7[iter_2_2], var_2_12, var_2_9[iter_2_2], var_2_8[iter_2_2])
		arg_2_0:nodeByName(var_0_0.PANEL_ENEMY):addChild(var_2_12)
		var_2_12:setPosition(iter_2_2 * 120 - 120, 0)

		var_2_11.id = var_2_7[iter_2_2]
		var_2_11.lev = var_2_10[iter_2_2]
		var_2_11.quality = var_2_9[iter_2_2]
		var_2_11.name = xyd.tables.hero:name(var_2_7[iter_2_2])
		var_2_11.desc = xyd.tables.hero:getDes(var_2_7[iter_2_2])
		var_2_11.isHero = true

		local var_2_13, var_2_14 = var_2_12:getPosition()

		var_2_12:setTouchEnabled(true)
		var_2_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				local var_4_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_4_1 = arg_2_0:convertToWorldSpace(cc.p(0, 0))

				if not var_4_0 then
					local var_4_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_2_11)

					xyd.adaptToWorldPosition(var_2_12, var_4_2)
				end

				return true
			elseif arg_4_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_4_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	arg_2_0:nodeByName("panel_equip"):removeAllChildren()

	local var_2_15 = {}

	if arg_2_0.cur_xg > arg_2_0.clgStar then
		var_2_15 = clone(xyd.tables.campaign:itemDisplay(var_2_0))
	end

	local var_2_16 = arg_2_0:getAwakeMissionItem()

	if var_2_16 and var_2_16 > 0 then
		table.insert(var_2_15, var_2_16)
	end

	local var_2_17 = arg_2_0:getAwakeTwiceMissionItem()

	if var_2_17 and var_2_17 > 0 then
		table.insert(var_2_15, var_2_17)
	end

	arg_2_0.itemTips = {}

	local var_2_18 = {
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName(var_0_0.PANEL_EQUIP):getContentSize().width, var_0_11),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}

	arg_2_0.listview = cc.ui.UIListView.new(var_2_18):addTo(arg_2_0:nodeByName(var_0_0.PANEL_EQUIP)):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	for iter_2_3 = 1, #var_2_15 do
		local var_2_19 = cc.Node:create()
		local var_2_20 = display.newNode()
		local var_2_21 = arg_2_0.listview:newItem()

		var_2_19:setContentSize(114, 113)
		xyd.setItemBorder(var_2_19, var_2_15[iter_2_3])

		local var_2_22 = {
			id = var_2_15[iter_2_3]
		}

		arg_2_0:addTips(var_2_19, var_2_22)
		var_2_20:addChild(var_2_19)
		var_2_20:setContentSize(var_0_11, var_0_11)
		var_2_21:addContent(var_2_20)
		var_2_21:setItemSize(var_0_11, var_0_11)
		arg_2_0.listview:addItem(var_2_21)
	end

	arg_2_0.listview:reload()
	arg_2_0:updateLayout()
end

function var_0_0.scrollListener(arg_5_0, arg_5_1)
	if arg_5_1.name == "began" then
		arg_5_0.scrollViewMoved_ = false
		arg_5_0.prevX_ = arg_5_1.x
	elseif arg_5_1.name == "moved" and 20 <= math.abs(arg_5_1.x - arg_5_0.prevX_) then
		arg_5_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLayout(arg_6_0)
	arg_6_0:awakeMissionInit()

	if arg_6_0.campaignType == xyd.CampaignType.SUPER or arg_6_0.campaignType == xyd.CampaignType.WEI or arg_6_0.campaignType == xyd.CampaignType.SHU or arg_6_0.campaignType == xyd.CampaignType.WU or arg_6_0.campaignType == xyd.CampaignType.WUMIAN or arg_6_0.campaignType == xyd.CampaignType.MOMIAN or arg_6_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_6_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_6_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_6_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
		arg_6_0:nodeByName(var_0_0.PANEL_LEFT):setVisible(true)

		if not tolua.isnull(arg_6_0:nodeByName("left_times")) then
			arg_6_0:nodeByName("left_times"):setString(arg_6_0.params.dailyLimit)
		end

		if not tolua.isnull(arg_6_0:nodeByName("limit_times")) then
			if arg_6_0.campaignType == xyd.CampaignType.SUPER then
				arg_6_0:nodeByName("limit_times"):setString("/" .. var_0_7)
			elseif arg_6_0.campaignType == xyd.CampaignType.WUMIAN or arg_6_0.campaignType == xyd.CampaignType.MOMIAN then
				arg_6_0:nodeByName("limit_times"):setString("/" .. var_0_8)
			elseif arg_6_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
				arg_6_0:nodeByName("limit_times"):setString("/" .. xyd.tables.misc.sakuraSecurityFightLimit)
			else
				arg_6_0:nodeByName("limit_times"):setString("/" .. var_0_6)
			end
		end

		if arg_6_0.params.dailyLimit <= 0 then
			arg_6_0:nodeByName("buy_button"):setVisible(true)
			arg_6_0:nodeByName("buy_txt"):setVisible(true)
		else
			arg_6_0:nodeByName("buy_button"):setVisible(false)
			arg_6_0:nodeByName("buy_txt"):setVisible(false)
		end
	else
		arg_6_0:nodeByName(var_0_0.PANEL_LEFT):setVisible(false)
	end

	if arg_6_0.campaignType == xyd.CampaignType.CHALLENGE then
		arg_6_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		arg_6_0:nodeByName("panel_challenge"):setVisible(true)

		if arg_6_0.cur_xg > 1 then
			arg_6_0:nodeByName("challenge_leftBtn"):setVisible(true)
		else
			arg_6_0:nodeByName("challenge_leftBtn"):setVisible(false)
		end

		if arg_6_0.cur_xg < arg_6_0.max_xg then
			arg_6_0:nodeByName("challenge_rightBtn"):setVisible(true)
		else
			arg_6_0:nodeByName("challenge_rightBtn"):setVisible(false)
		end

		arg_6_0:nodeByName("challenge_type_txt"):setString(arg_6_0.challengeTypeTxt[arg_6_0.challengeType[arg_6_0.cur_xg]])
		arg_6_0:nodeByName("challenge_icon"):loadTexture("windows/map_window/challenge_type" .. arg_6_0.challengeType[arg_6_0.cur_xg] .. ".png")
	elseif arg_6_0.star < var_0_4 then
		arg_6_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		arg_6_0:nodeByName("panel_challenge"):setVisible(false)

		arg_6_0.sweepNum = var_0_5

		if arg_6_0.campaignType ~= xyd.CampaignType.NORMAL then
			arg_6_0.sweepNum = arg_6_0.params.dailyLimit
		end
	else
		arg_6_0:nodeByName("panel_challenge"):setVisible(false)
		arg_6_0:initSweepPanel()

		if arg_6_0.campaignType == xyd.CampaignType.SUPER or arg_6_0.campaignType == xyd.CampaignType.NORMAL or arg_6_0.player_.lev >= 55 or arg_6_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
			arg_6_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(true)
		else
			arg_6_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		end

		arg_6_0.sweepNum = var_0_5

		if arg_6_0.campaignType ~= xyd.CampaignType.NORMAL then
			arg_6_0.sweepNum = arg_6_0.params.dailyLimit
		end

		if not tolua.isnull(arg_6_0:nodeByName("sweep_num_txt")) then
			if arg_6_0.sweepNum > 0 then
				arg_6_0:nodeByName("sweep_num_txt"):setString(string.format(var_0_1:translation("MAP_SWEEP_NUM"), tostring(arg_6_0.sweepNum)))
			else
				arg_6_0:nodeByName("sweep_num_txt"):setString(var_0_1:translation("MAP_NO_SWEEP"))
			end
		end

		if not tolua.isnull(arg_6_0:nodeByName("sweep_txt")) then
			arg_6_0:nodeByName("sweep_txt"):setString(var_0_1:translation("MAP_SWEEP"))
		end

		if not tolua.isnull(arg_6_0:nodeByName("sweep_item_num")) then
			arg_6_0:nodeByName("sweep_item_num"):setContentSize(300, 32)
			arg_6_0:nodeByName("sweep_item_num"):setString(string.format(var_0_1:translation("MAP_SWEEP_ITEM"), tostring(arg_6_0.hasItemNum)))
		end
	end
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	arg_7_0:nodeByName("sweep_num_txt"):enableOutline(cc.c4b(149, 85, 8, 255), 2)
	arg_7_0:nodeByName("sweep_num_txt"):getVirtualRenderer():setAdditionalKerning(2)
	arg_7_0:nodeByName("sweep_txt"):enableOutline(cc.c4b(149, 85, 8, 255), 2)
	arg_7_0:nodeByName("sweep_txt"):getVirtualRenderer():setAdditionalKerning(2)
	arg_7_0:nodeByName("left_label"):setString(var_0_1:translation("MAP_LEFT_TIMES"))
	arg_7_0:nodeByName("buy_txt"):setString(var_0_1:translation("MAP_BUY"))
	arg_7_0:setTouchSwallowEnabled(true)
	arg_7_0:awakeMissionInit()
	arg_7_0:layout()
end

function var_0_0.didOpen(arg_8_0)
	local function var_8_0()
		local var_9_0
		local var_9_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		arg_8_0.buyEnergyTimes = var_9_1.buyEnergyTimes
		arg_8_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_8_0.buyEnergyTimes + 1)
		arg_8_0.maxBuyTimes = xyd.tables.vip:numEnergy(var_9_1.vip)

		local var_9_2 = xyd.tables.misc.energyMaxLimit

		str = string.format(var_0_1:translation("ADD_ENERGY"), arg_8_0.buyEnergyCost, var_0_10, arg_8_0.buyEnergyTimes)

		if arg_8_0:isHasTiLiItem() then
			local var_9_3 = {
				text = str,
				callback = function()
					if arg_8_0.buyEnergyTimes >= arg_8_0.maxBuyTimes then
						str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_8_0.buyEnergyTimes)
						var_9_0 = xyd.AlertType.CONFIRM

						local var_10_0 = xyd.luaStringSplit(str, "\n")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
							local var_11_0 = {}

							var_11_0.windowState = false

							xyd.WindowManager.get():openWindow("vip_recharge", var_11_0)
							xyd.WindowManager.get():closeWindow("add_energy")
						end, nil, nil, arg_8_0.colorMode)
					elseif arg_8_0.player_.energy >= var_9_2 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TILI_LIMIT_INFO")
						})
						xyd.WindowManager.get():closeWindow("buy_tili")
					else
						local var_10_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_8_0.buyEnergyCost > var_10_1.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_12_0 = {}

								var_12_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_12_0)
							end, nil, nil, arg_8_0.colorMode)
						else
							arg_8_0.addEnergyModel:addEnergy(function(arg_13_0)
								if arg_13_0 == xyd.error.OK then
									return true
								end
							end)
							xyd.WindowManager.get():closeWindow("buy_tili")
						end
					end
				end
			}

			xyd.WindowManager.get():openWindow("buy_tili", var_9_3)
		else
			local var_9_4 = xyd.luaStringSplit(str, "\n")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_9_4, function()
				local var_14_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if arg_8_0.buyEnergyTimes >= arg_8_0.maxBuyTimes then
					str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_8_0.buyEnergyTimes)
					var_9_0 = xyd.AlertType.CONFIRM

					local var_14_1 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
						local var_15_0 = {}

						var_15_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_15_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_8_0.colorMode)
				elseif arg_8_0.buyEnergyCost > var_14_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_16_0 = {}

						var_16_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_16_0)
					end, nil, nil, arg_8_0.colorMode)
				else
					arg_8_0.addEnergyModel:addEnergy(function(arg_17_0)
						if arg_17_0 == xyd.error.OK then
							return true
						end
					end)
					xyd.WindowManager.get():closeWindow("alert")
				end
			end, nil, 0, arg_8_0.colorMode)
		end
	end

	arg_8_0:nodeByName(var_0_0.START_BUTTON):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if (arg_8_0.campaignType == xyd.CampaignType.SUPER or arg_8_0.campaignType == xyd.CampaignType.WEI or arg_8_0.campaignType == xyd.CampaignType.SHU or arg_8_0.campaignType == xyd.CampaignType.WU or arg_8_0.campaignType == xyd.CampaignType.MOMIAN or arg_8_0.campaignType == xyd.CampaignType.WUMIAN or arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN) and arg_8_0.sweepNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_TIMES")
				})

				return
			end

			if arg_8_0.player_.energy < xyd.tables.campaign:energyCost(arg_8_0.campaignID) then
				var_8_0()
			elseif arg_8_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_8_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_8_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
				local var_18_0 = {}

				arg_8_0.guild:loadAllTeamPets(var_18_0, function(arg_19_0)
					local var_19_0 = false
					local var_19_1 = {}

					if arg_19_0 == xyd.error.OK then
						var_19_0 = true

						for iter_19_0, iter_19_1 in ipairs(arg_8_0.guild:getAllTeamPets()) do
							local var_19_2 = var_0_13.new()

							var_19_2:populate(iter_19_1)

							var_19_2.player_name = iter_19_1.player_name
							var_19_2.rent_need_mana = iter_19_1.rent_need_mana
							var_19_2.can_rent = iter_19_1.can_rent
							var_19_2.player_id = iter_19_1.player_id

							table.insert(var_19_1, var_19_2)
						end
					end

					local var_19_3
					local var_19_4 = {
						type = var_19_3,
						campaignID = arg_8_0.campaignID,
						campaignType = arg_8_0.campaignType,
						itemComposeID = arg_8_0.itemComposeID,
						isMercenary = var_19_0,
						allTeamPets = var_19_1
					}

					if arg_8_0 then
						var_19_4.star = arg_8_0.star
					end

					xyd.WindowManager.get():openWindow("select_pet_team", var_19_4)
				end)
			else
				if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
					arg_8_0.player_:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT)
				end

				local var_18_1 = {
					campaign_type = arg_8_0.campaignType
				}

				arg_8_0.guild:loadAllTeamHeros(var_18_1, function(arg_20_0)
					local var_20_0 = false
					local var_20_1 = {}

					if arg_20_0 == xyd.error.OK then
						var_20_0 = true

						local var_20_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

						for iter_20_0, iter_20_1 in ipairs(var_20_2:getAllTeamHeros()) do
							local var_20_3 = var_0_12.new()

							var_20_3:populate(iter_20_1)

							var_20_3.player_name = iter_20_1.player_name
							var_20_3.rent_need_mana = iter_20_1.rent_need_mana
							var_20_3.can_rent = iter_20_1.can_rent
							var_20_3.player_id = iter_20_1.player_id

							table.insert(var_20_1, var_20_3)
						end
					end

					local var_20_4

					if arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						var_20_4 = xyd.SelectTeamType.SAKURA_CAMPAIGN
					elseif arg_8_0.campaignType == xyd.CampaignType.CHALLENGE then
						var_20_4 = xyd.SelectTeamType.CHALLENGE
					elseif arg_8_0.campaignType == xyd.CampaignType.STUDENT_OVER then
						var_20_4 = xyd.SelectTeamType.STUDENT_OVER
						var_20_0 = nil
						var_20_1 = nil
					end

					local var_20_5 = {
						type = var_20_4,
						campaignID = arg_8_0.campaignID,
						campaignType = arg_8_0.campaignType,
						itemComposeID = arg_8_0.itemComposeID,
						isMercenary = var_20_0,
						allTeamHeros = var_20_1
					}

					if arg_8_0 then
						var_20_5.star = arg_8_0.star
					end

					if arg_8_0:checkShowBattleStory() then
						arg_8_0:playStory(function(arg_21_0)
							var_20_5.assistID = arg_21_0

							xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_20_5)
						end)
					else
						xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_20_5)
					end
				end)
			end
		end
	end)
	arg_8_0:playGuide()
	arg_8_0:nodeByName("buy_button"):addTouchEventListener(function(arg_22_0, arg_22_1)
		if arg_22_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.campaignType == xyd.CampaignType.SUPER then
				local var_22_0 = xyd.tables.vip:resetFuben(arg_8_0.player_.vip)

				if arg_8_0.player_.privilegeLeftCardDay > 0 then
					var_22_0 = var_22_0 + xyd.tables.monthlyPrivilege:numElite(1)
				end

				if var_22_0 <= arg_8_0.params.resetCount then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("MAP_RESET_TIMES2"), arg_8_0.params.resetCount),
						var_0_1:translation("MAP_RESET_VIP")
					}, function()
						xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
							windowState = false
						})
					end, {
						rightName = var_0_1:translation("CHECK_PRIVILEGE")
					}, nil, arg_8_0.colorMode)

					return
				end

				local function var_22_1()
					local var_24_0 = {
						campaign_id = arg_8_0.campaignID,
						campaign_type = arg_8_0.campaignType
					}

					xyd.Backend.get():request(xyd.mid.RESET_CAMPAIGN, var_24_0, function(arg_25_0, arg_25_1, arg_25_2)
						if arg_25_0 == xyd.error.OK then
							local var_25_0 = arg_25_1.campaign_id

							arg_8_0.player_.worldMaps_[var_25_0] = {}
							arg_8_0.player_.worldMaps_[var_25_0].star = tonumber(arg_25_1.star)
							arg_8_0.player_.worldMaps_[var_25_0].dailyLimit = tonumber(arg_25_1.daily_limit)
							arg_8_0.player_.worldMaps_[var_25_0].resetCount = tonumber(arg_25_1.reset_count)
							arg_8_0.params.dailyLimit = tonumber(arg_25_1.daily_limit)
							arg_8_0.params.resetCount = tonumber(arg_25_1.reset_count)

							arg_8_0:layout()

							local var_25_1 = xyd.WindowManager.get():getWindow("map_window")

							if var_25_1 then
								var_25_1:updateChapter()
							end

							if arg_8_0.itemComposeID then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.UPDATE_STONE_EQUIP_CAMPAIGN,
									params = {
										itemComposeID = arg_8_0.itemComposeID
									}
								})
							end
						end
					end)
				end

				local var_22_2 = xyd.tables.refreshCost:refreshEliteCost(arg_8_0.params.resetCount + 1)

				if var_22_2 > arg_8_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_26_0 = {}

						var_26_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_26_0)
					end, nil, nil, arg_8_0.colorMode)
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("MAP_RESET"), var_22_2),
						var_0_1:translation("SWEEP_ITEM_CONTINUE") .. string.format(var_0_1:translation("MAP_RESET_TIMES"), arg_8_0.params.resetCount)
					}, function()
						var_22_1()
					end, nil, nil, arg_8_0.colorMode)
				end
			else
				if arg_8_0.params.buyTimes >= arg_8_0.params.maxBuyTime then
					local var_22_3 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_22_3
					})

					return
				end

				local var_22_4 = xyd.tables.translation:translation("DAILY_TRIAL_INFO")

				if arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
					var_22_4 = string.format(xyd.tables.translation:translation("BUY_SAKURA_TIMES"), xyd.tables.misc.sakuraSecurityPrice[arg_8_0.params.buyTimes + 1])
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_22_4, function()
					buyExtralTime()
				end, nil, 0, arg_8_0.colorMode)

				function buyExtralTime()
					local var_29_0 = xyd.tables.trialConfig:trials(arg_8_0.campaignType)
					local var_29_1 = tonumber(string.sub(tostring(var_29_0[1]), 1, 1))
					local var_29_2 = {
						xyd.DailyConsumeType.XiaoYao,
						xyd.DailyConsumeType.YiLing,
						xyd.DailyConsumeType.ChiBi,
						xyd.DailyConsumeType.PhysicsTest,
						xyd.DailyConsumeType.MagicTest
					}
					local var_29_3

					if arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						var_29_3 = xyd.tables.misc.sakuraSecurityPrice[arg_8_0.params.buyTimes + 1]
					else
						var_29_3 = xyd.tables.dailyConsume:getCost(var_29_2[var_29_1])
					end

					local var_29_4 = 0

					if arg_8_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_8_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_8_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
						var_29_4 = ({
							xyd.DailyConsumeType.CLOUD_LADDER,
							xyd.DailyConsumeType.CLOUD_ROAD,
							xyd.DailyConsumeType.CLOUD_TEMPLE
						})[arg_8_0.campaignType - 39]
					else
						var_29_4 = var_29_2[var_29_1]
					end

					if var_29_3 > arg_8_0.player_.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_30_0 = {}

							var_30_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_30_0)
						end, nil, nil, arg_8_0.colorMode)

						return
					end

					if arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						xyd.Backend.get():request(xyd.mid.BUY_SAKURA_TIMES, {}, function(arg_31_0, arg_31_1)
							if arg_31_0 == xyd.error.OK then
								arg_8_0.params.dailyLimit = arg_31_1.left_times
								arg_8_0.params.buyTimes = arg_31_1.buy_times

								arg_8_0:layout()
							end
						end)
					else
						params = {
							consume_id = var_29_4
						}

						xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, params, function(arg_32_0, arg_32_1)
							if arg_32_0 == xyd.error.OK then
								arg_8_0.player_.trialInfos_[arg_8_0.campaignType].leftTimes = arg_32_1.trial_info.left_times
								arg_8_0.params.dailyLimit = arg_32_1.trial_info.left_times
								arg_8_0.params.buyTimes = arg_8_0.params.buyTimes + 1

								arg_8_0:layout()
							end
						end)
					end
				end
			end
		end
	end)
	arg_8_0:nodeByName("multi_button"):addTouchEventListener(function(arg_33_0, arg_33_1)
		if arg_33_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.sweepNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_DAILY_TIMES")
				})

				return
			end

			if not xyd.tables.vip:quickSweep(arg_8_0.player_.vip) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("SWEEP_VIP"), function()
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
						windowState = false
					})
				end, {
					rightName = var_0_1:translation("CHECK_PRIVILEGE")
				}, nil, arg_8_0.colorMode)

				return
			end

			if arg_8_0.player_.energy < xyd.tables.campaign:energyCost(arg_8_0.campaignID) * arg_8_0.sweepNum then
				var_8_0()
			else
				local var_33_0 = {
					campaign_id = arg_8_0.campaignID,
					campaign_type = arg_8_0.campaignType,
					sweep_num = arg_8_0.sweepNum,
					itemComposeID = arg_8_0.itemComposeID,
					needItemComposeNum = arg_8_0.needItemComposeNum
				}

				if arg_8_0.hasItemNum < arg_8_0.sweepNum then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("SWEEP_ITEM_ABSENCE"), arg_8_0.sweepNum),
						var_0_1:translation("SWEEP_ITEM_CONTINUE")
					}, function()
						local var_35_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_8_0.sweepNum > var_35_0.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_36_0 = {}

								var_36_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_36_0)
							end, nil, nil, arg_8_0.colorMode)
						else
							var_33_0.sweep_type = xyd.SweepType.CRYSTAL_SWEEP

							xyd.WindowManager.get():openWindow("sweep_window", var_33_0)
						end
					end, nil, 0, arg_8_0.colorMode)
				else
					var_33_0.sweep_type = xyd.SweepType.ITEM_SWEEP

					xyd.WindowManager.get():openWindow("sweep_window", var_33_0)
				end
			end
		end
	end)
	arg_8_0:nodeByName("once_button"):addTouchEventListener(function(arg_37_0, arg_37_1)
		if arg_37_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.sweepNum <= 0 and (arg_8_0.campaignType == xyd.CampaignType.SUPER or arg_8_0.campaignType == xyd.CampaignType.WEI or arg_8_0.campaignType == xyd.CampaignType.SHU or arg_8_0.campaignType == xyd.CampaignType.WU or arg_8_0.campaignType == xyd.CampaignType.MOMIAN or arg_8_0.campaignType == xyd.CampaignType.WUMIAN or arg_8_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_8_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_8_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_8_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_DAILY_TIMES")
				})

				return
			end

			if arg_8_0.player_.energy < xyd.tables.campaign:energyCost(arg_8_0.campaignID) then
				var_8_0()
			else
				local var_37_0 = {
					sweep_num = 1,
					campaign_id = arg_8_0.campaignID,
					campaign_type = arg_8_0.campaignType,
					itemComposeID = arg_8_0.itemComposeID,
					needItemComposeNum = arg_8_0.needItemComposeNum,
					awake_mission = arg_8_0.awakeMissionID
				}

				if arg_8_0.hasItemNum < 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("SWEEP_ITEM_ABSENCE"), 1),
						var_0_1:translation("SWEEP_ITEM_CONTINUE")
					}, function()
						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).crystal < 1 then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_39_0 = {}

								var_39_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_39_0)
							end, nil, nil, arg_8_0.colorMode)
						else
							var_37_0.sweep_type = xyd.SweepType.CRYSTAL_SWEEP

							xyd.WindowManager.get():openWindow("sweep_window", var_37_0)
						end
					end, nil, 0, arg_8_0.colorMode)
				else
					var_37_0.sweep_type = xyd.SweepType.ITEM_SWEEP

					xyd.WindowManager.get():openWindow("sweep_window", var_37_0)
				end
			end
		end
	end)
	arg_8_0:nodeByName("challenge_leftBtn"):addTouchEventListener(function(arg_40_0, arg_40_1)
		if arg_40_1 == ccui.TouchEventType.ended then
			arg_8_0.campaignID = arg_8_0.campaignID - 1
			arg_8_0.cur_xg = arg_8_0.cur_xg - 1

			arg_8_0:layout()
		end
	end)
	arg_8_0:nodeByName("challenge_rightBtn"):addTouchEventListener(function(arg_41_0, arg_41_1)
		if arg_41_1 == ccui.TouchEventType.ended then
			arg_8_0.campaignID = arg_8_0.campaignID + 1
			arg_8_0.cur_xg = arg_8_0.cur_xg + 1

			arg_8_0:layout()
		end
	end)
end

function var_0_0.setIDBeforeGuideWnd(arg_42_0)
	local var_42_0 = xyd.StoryData.get():getGuideID()

	if var_42_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_42_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_43_0)
	local var_43_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_43_1 = xyd.StoryData.get():getGuideID()

	if var_43_1 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE)
	elseif var_43_1 == xyd.GuideStoryType.GUIDE_MISSION_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_END)
	elseif var_43_1 == xyd.GuideStoryType.GUIDE_FIGHT_2_TWO then
		var_43_0:sendOperationLog(xyd.StatID.ID_FIGHT_2_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_THREE)
	elseif var_43_1 == xyd.GuideStoryType.GUIDE_FIGHT_3_ONE then
		var_43_0:sendOperationLog(xyd.StatID.ID_FIGHT_3_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_TWO)
	elseif var_43_1 == xyd.GuideStoryType.GUIDE_FIGHT_4_TWO then
		var_43_0:sendOperationLog(xyd.StatID.ID_FIGHT_4_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_THREE)
	elseif var_43_1 == xyd.GuideStoryType.GUIDE_FIGHT_5_TWO then
		var_43_0:sendOperationLog(xyd.StatID.ID_FIGHT_5_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_THREE)
	end
end

function var_0_0.checkGuideIntoTeamWnd(arg_44_0)
	local var_44_0 = xyd.StoryData.get():getGuideID()

	if var_44_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END or var_44_0 == xyd.GuideStoryType.GUIDE_MISSION_FOUR or var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE or var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START or var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE or var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_TWO then
		return true
	end

	return false
end

function var_0_0.playGuide(arg_45_0)
	local var_45_0 = xyd.StoryData.get():getGuideID()

	if arg_45_0:checkGuideIntoTeamWnd() then
		arg_45_0:setIDBeforeGuideWnd()

		local var_45_1 = xyd.StoryData.get():getGuideID()
		local var_45_2 = arg_45_0:nodeByName("start")
		local var_45_3 = {
			920,
			350
		}

		xyd.showGuideWnd(var_45_2, nil, nil, 2, var_45_3, true)
		arg_45_0:setIDAfterGuideWnd()
	end
end

function var_0_0.getAwakeMissionItem(arg_46_0)
	local var_46_0 = arg_46_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)
	local var_46_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if var_46_0 and xyd.getMissionGoIDs(var_46_0) == arg_46_0.campaignID then
		local var_46_2 = var_0_3:awakeMissionIds(arg_46_0.campaignID)
		local var_46_3 = var_0_3:awakeDropboxIds(arg_46_0.campaignID)
		local var_46_4

		for iter_46_0, iter_46_1 in ipairs(var_46_2) do
			if var_46_0 == iter_46_1 then
				var_46_4 = xyd.tables.campaignDropbox:dropItem(var_46_3[iter_46_0])
			end
		end

		if var_46_4 then
			return var_46_4
		end
	end

	return nil
end

function var_0_0.getAwakeTwiceMissionItem(arg_47_0)
	local var_47_0 = arg_47_0.task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE)

	if var_47_0 then
		local var_47_1 = var_0_3:awakeTwiceMissionIds(arg_47_0.campaignID)
		local var_47_2 = var_0_3:awakeTwiceDropboxIds(arg_47_0.campaignID)

		for iter_47_0, iter_47_1 in ipairs(var_47_1) do
			if var_47_0 == iter_47_1 then
				return xyd.tables.campaignDropbox:dropItem(var_47_2[iter_47_0])
			end
		end
	end
end

function var_0_0.initSweepPanel(arg_48_0)
	local var_48_0 = arg_48_0:nodeByName(var_0_0.PANEL_SWEEP)
	local var_48_1 = var_48_0:getChildByName("multi_button")
	local var_48_2 = var_48_0:getChildByName("sweep_num_txt")
	local var_48_3 = var_48_0:getChildByName("sweep_item_num")
	local var_48_4 = var_48_0:getChildByName("awake_hero_avatar")
	local var_48_5 = var_48_0:getChildByName("awake_process")

	if arg_48_0.isAwakeCampaign and arg_48_0.awakeMission.count > 0 and arg_48_0.awakeMission.count < xyd.tables.mission:awakeTaskNum(arg_48_0.awakeMissionID)[1] then
		var_48_1:setVisible(false)
		var_48_2:setVisible(false)
		var_48_3:setVisible(false)
		var_48_4:setVisible(true)
		var_48_5:setVisible(true)
		xyd.setAvatarBorder(arg_48_0.awakeHero, var_48_4)
		arg_48_0:nodeByName("awake_process"):setString(arg_48_0.awakeMission.count .. "/" .. xyd.tables.mission:awakeTaskNum(arg_48_0.awakeMissionID)[1])
	else
		var_48_1:setVisible(true)
		var_48_2:setVisible(true)
		var_48_3:setVisible(true)
		var_48_4:setVisible(false)
		var_48_5:setVisible(false)
	end
end

function var_0_0.awakeMissionInit(arg_49_0)
	local var_49_0 = arg_49_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_49_0 and xyd.tables.mission:stage(var_49_0) == 2 then
		local var_49_1 = xyd.tables.mission:trialChallenges(var_49_0)

		for iter_49_0, iter_49_1 in pairs(var_49_1) do
			if iter_49_1 == arg_49_0.campaignID then
				arg_49_0.isAwakeCampaign = true
				arg_49_0.awakeMissionID = var_49_0
				arg_49_0.awakeMission = arg_49_0.task:getTaskByID(var_49_0, xyd.TaskType.AWAKE)
				arg_49_0.awakeHero = arg_49_0.player_:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_49_0))
			end
		end
	end
end

function var_0_0.checkShowBattleStory(arg_50_0)
	if arg_50_0.campaignType ~= xyd.CampaignType.NORMAL then
		return false
	end

	local var_50_0, var_50_1 = arg_50_0:getBattleID()

	if var_50_1 then
		return true
	end

	return false
end

function var_0_0.getBattleID(arg_51_0)
	local var_51_0 = 0
	local var_51_1
	local var_51_2
	local var_51_3 = false
	local var_51_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_51_0.campaignType == xyd.CampaignType.NORMAL and arg_51_0.campaignID ~= 0 then
		local var_51_5 = xyd.tables.campaign:firstFightID(arg_51_0.campaignID)
		local var_51_6 = var_51_4.worldMaps_[arg_51_0.campaignID].star or 0

		if var_51_5 ~= 0 and var_51_6 <= 0 then
			var_51_0 = var_51_5
			var_51_3 = true
		end
	end

	return var_51_0, var_51_3
end

function var_0_0.playStory(arg_52_0, arg_52_1)
	if arg_52_0.campaignType ~= xyd.CampaignType.NORMAL then
		return
	end

	local var_52_0, var_52_1 = arg_52_0:getBattleID()

	if not var_52_1 or var_52_0 == 0 then
		if arg_52_1 then
			arg_52_1()
		end

		return
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_52_2 = var_0_2:assistStory(var_52_0)

	if var_52_1 and var_52_2 > 0 then
		arg_52_0:hide()

		local var_52_3 = xyd.WindowManager.get():openWindow("battle_special_story", {
			story_state = 1,
			story_id = var_52_2
		})

		cc.EventProxy.new(var_52_3, var_52_3):addEventListener(xyd.event.STORY_COMPLETE, function(arg_53_0)
			if arg_53_0.state == 1 then
				arg_52_0:show()

				local var_53_0

				if arg_53_0.params and next(arg_53_0.params) then
					var_53_0 = arg_53_0.params.assistID
				end

				if arg_52_1 then
					arg_52_1(var_53_0)
				end
			end
		end)
	else
		if arg_52_1 then
			arg_52_1()
		end

		return
	end
end

function var_0_0.isHasTiLiItem(arg_54_0)
	local var_54_0 = arg_54_0.player_:getBackpack():getItems()

	for iter_54_0, iter_54_1 in pairs(var_54_0) do
		if xyd.tables.item:subType(iter_54_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

return var_0_0
