local var_0_0 = class("NewMapDetailWindow", import("app.common.ui.BaseWindow"))

var_0_0.START_BUTTON = "start"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_DESC = "txt_desc"
var_0_0.TXT_XIAOHAO = "txt_xiaohao"
var_0_0.TXT_ENERGY = "txt_energy"
var_0_0.TXT_ENEMY = "txt_enemy"
var_0_0.TXT_EQUIP = "txt_equip"
var_0_0.TXT_FIRST = "txt_first"
var_0_0.PANEL_EQUIP = "panel_equip"
var_0_0.PANEL_ENEMY = "panel_enemy"
var_0_0.PANEL_SWEEP = "panel_sweep"
var_0_0.PANEL_LEFT = "panel_left"
var_0_0.PANEL_ENERGY = "energy_container"

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
local var_0_11 = 100
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
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.itemComposeID = arg_1_2.itemComposeID
	arg_1_0.needItemComposeNum = arg_1_2.needItemComposeNum
end

function var_0_0.willClose(arg_2_0)
	local var_2_0 = xyd.WindowManager.get():getWindow("time_travel")

	if var_2_0 then
		var_2_0:updateItems()
	end
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.campaignType == xyd.CampaignType.CHALLENGE then
		arg_3_0:nodeByName("clgStar_container"):setVisible(true)
		arg_3_0:nodeByName("star_container"):setVisible(false)

		for iter_3_0 = 1, 3 do
			if iter_3_0 > arg_3_0.clgStar then
				arg_3_0:nodeByName("clgIcon" .. iter_3_0):setVisible(false)
				arg_3_0:nodeByName("clgIcon" .. iter_3_0 .. "_gray"):setVisible(true)
				arg_3_0:nodeByName("clgIcon" .. iter_3_0 .. "_gray"):loadTexture("windows/map_window/challenge_type" .. arg_3_0.challengeType[iter_3_0] .. "_s_gray.png")
			else
				arg_3_0:nodeByName("clgIcon" .. iter_3_0):setVisible(true)
				arg_3_0:nodeByName("clgIcon" .. iter_3_0 .. "_gray"):setVisible(false)
				arg_3_0:nodeByName("clgIcon" .. iter_3_0):loadTexture("windows/map_window/challenge_type" .. arg_3_0.challengeType[iter_3_0] .. "_s.png")
			end
		end
	elseif arg_3_0.campaignType == xyd.CampaignType.SAKURA2_WAR then
		arg_3_0:nodeByName("clgStar_container"):setVisible(false)
		arg_3_0:nodeByName("star_container"):setVisible(false)
	else
		arg_3_0:nodeByName("clgStar_container"):setVisible(false)
		arg_3_0:nodeByName("star_container"):setVisible(true)

		for iter_3_1 = 1, 3 do
			if iter_3_1 > arg_3_0.star then
				arg_3_0:nodeByName("star" .. iter_3_1):setVisible(false)
			else
				arg_3_0:nodeByName("star" .. iter_3_1):setVisible(true)
			end
		end
	end

	local var_3_0 = arg_3_0.campaignID
	local var_3_1 = arg_3_0:nodeByName("title_pos")

	var_3_1:setString(xyd.tables.campaign:campaignName(var_3_0))

	local var_3_2 = xyd.tables.campaign:campaignDesc(var_3_0)

	arg_3_0:nodeByName(var_0_0.TXT_DESC):setString(var_3_2)

	local var_3_3 = xyd.tables.campaign:energyCost(var_3_0)

	arg_3_0:nodeByName(var_0_0.TXT_ENERGY):setString(var_3_3)
	arg_3_0:nodeByName(var_0_0.TXT_XIAOHAO):setString(var_0_1:translation("MAP_TILI_TXT"))
	arg_3_0:nodeByName(var_0_0.TXT_ENEMY):setString(var_0_1:translation("NEW_MAP_ENEMY_TXT"))

	if arg_3_0.star == 0 then
		arg_3_0:nodeByName(var_0_0.TXT_EQUIP):setString(var_0_1:translation("NEW_MAP_FIRST_GET_TXT"))
	else
		arg_3_0:nodeByName(var_0_0.TXT_EQUIP):setString(var_0_1:translation("NEW_MAP_GET_TXT"))
	end

	arg_3_0:nodeByName(var_0_0.PANEL_ENEMY):removeAllChildren()

	if xyd.tables.campaign:chapter(var_3_0) >= xyd.tables.misc.energyReduceChapter then
		local var_3_4 = 50

		if arg_3_0.handBuff then
			arg_3_0.handBuff:removeFromParent()

			arg_3_0.handBuff = nil
			var_3_4 = 38
		end

		local var_3_5 = xyd.AssetLoader.get():loadSprite("windows/map_window/campaign_hand.png")

		var_3_5:addTo(arg_3_0)

		arg_3_0.handBuff = var_3_5

		var_3_5:setAnchorPoint(cc.p(0, 0.5))

		local var_3_6, var_3_7 = var_3_1:getPosition()

		var_3_5:setPosition(var_3_6 + var_3_1:getContentSize().width + var_3_4, var_3_7)
		var_3_5:setTouchEnabled(true)
		var_3_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				local var_4_0 = {
					message = var_0_1:translation("CAMPAIGN_DEBUFF_TIP")
				}

				var_4_0.isAutoClose = 0
				var_4_0.txtSize = 24
				var_4_0.isOutLine = 0

				local var_4_1 = xyd.WindowManager.get():openWindow("toast", var_4_0)
				local var_4_2 = arg_3_0:convertToWorldSpace(cc.p(0, 0))
				local var_4_3, var_4_4 = var_3_5:getPosition()
				local var_4_5 = arg_3_0:convertToWorldSpace(cc.p(var_4_3 + var_3_5:getWidth() + var_4_1:getWndWidth() / 2 + 5, var_4_4))

				var_4_1:setPosition(var_4_5)

				return true
			elseif arg_4_0.name == "ended" then
				local var_4_6 = xyd.WindowManager.get():getWindow("toast")

				if var_4_6 then
					xyd.WindowManager.get():closeWindow(var_4_6.name)
				end
			end
		end)
	end

	local var_3_8 = xyd.tables.campaign:monsterDisplay(var_3_0)
	local var_3_9 = xyd.tables.campaign:monsterStar(var_3_0)
	local var_3_10 = xyd.tables.campaign:monsterQuality(var_3_0)
	local var_3_11 = xyd.tables.campaign:element(var_3_0)
	local var_3_12 = xyd.tables.campaign:monsterLevel(var_3_0)

	arg_3_0.sweepNum = 0
	arg_3_0.hasItemNum = arg_3_0.player_:getBackpack():getItemNumByID(var_0_9)
	arg_3_0.monsterTips = {}

	for iter_3_2 = 1, #var_3_8 do
		local var_3_13 = {}
		local var_3_14 = cc.Node:create()

		var_3_14:setAnchorPoint(cc.p(0.5, 0.5))

		if iter_3_2 ~= #var_3_8 then
			var_3_13.isBoss = false

			var_3_14:setContentSize(var_0_11, var_0_11)
			var_3_14:setPosition((iter_3_2 - 1) * (var_0_11 + 8) + 115, 60)
		else
			local var_3_15 = 12

			var_3_13.isBoss = true

			var_3_14:setContentSize(var_0_11 + var_3_15, var_0_11 + var_3_15)
			var_3_14:setPosition((iter_3_2 - 1) * (var_0_11 + 7) + 115 + var_3_15 / 2, 60)
		end

		if var_3_11 == {} then
			xyd.setAvatarBorderNewUI(var_3_8[iter_3_2], var_3_14, var_3_10[iter_3_2], var_3_9[iter_3_2])
		else
			xyd.setAvatarBorderNewUI(var_3_8[iter_3_2], var_3_14, var_3_10[iter_3_2], var_3_9[iter_3_2], nil, nil, nil, nil, nil, nil, var_3_11[iter_3_2])
		end

		arg_3_0:nodeByName(var_0_0.PANEL_ENEMY):addChild(var_3_14)

		var_3_13.id = var_3_8[iter_3_2]
		var_3_13.lev = var_3_12[iter_3_2]
		var_3_13.quality = var_3_10[iter_3_2]
		var_3_13.name = xyd.tables.hero:name(var_3_8[iter_3_2])
		var_3_13.desc = xyd.tables.hero:getDes(var_3_8[iter_3_2])
		var_3_13.stars = var_3_9[iter_3_2]
		var_3_13.isHero = true
		var_3_13.elements = var_3_11[iter_3_2]

		local var_3_16, var_3_17 = var_3_14:getPosition()

		var_3_14:setTouchEnabled(true)
		var_3_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				local var_5_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_5_1 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

				if not var_5_0 then
					local var_5_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_3_13)

					xyd.adaptToWorldPosition(var_3_14, var_5_2)
				end

				return true
			elseif arg_5_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
				local var_5_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
			end
		end)
	end

	arg_3_0:nodeByName("panel_equip"):removeAllChildren()

	local var_3_18 = {}

	if arg_3_0.cur_xg > arg_3_0.clgStar then
		if xyd.tables.campaign:campaignType(var_3_0) ~= xyd.CampaignType.CHALLENGE and arg_3_0.star == 0 then
			if xyd.tables.campaign:firstDisplay(var_3_0)[1] == 0 then
				var_3_18 = clone(xyd.tables.campaign:itemDisplay(var_3_0))
			else
				var_3_18 = clone(xyd.tables.campaign:firstDisplay(var_3_0))
			end
		else
			var_3_18 = clone(xyd.tables.campaign:itemDisplay(var_3_0))
		end
	end

	local var_3_19 = arg_3_0:getAwakeMissionItem()

	if var_3_19 and var_3_19 > 0 then
		table.insert(var_3_18, var_3_19)
	end

	local var_3_20 = arg_3_0:getAwakeTwiceMissionItem()

	if var_3_20 and var_3_20 > 0 then
		table.insert(var_3_18, var_3_20)
	end

	local var_3_21 = xyd.tables.campaign:starGift(var_3_0)

	if xyd.tables.functionOpen:open_control(xyd.FunctionID.ID_REWARD_CHANGE) == 1 and arg_3_0.star < 3 and var_3_21 ~= 0 then
		table.insert(var_3_18, -1)
	end

	arg_3_0.itemTips = {}

	local var_3_22 = {
		viewRect = cc.rect(65, 10, arg_3_0:nodeByName(var_0_0.PANEL_EQUIP):getContentSize().width - 70, var_0_11),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}

	arg_3_0.listview = cc.ui.UIListView.new(var_3_22):addTo(arg_3_0:nodeByName(var_0_0.PANEL_EQUIP)):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	for iter_3_3 = 1, #var_3_18 do
		local var_3_23 = cc.Node:create()
		local var_3_24 = display.newNode()
		local var_3_25 = arg_3_0.listview:newItem()

		var_3_23:setContentSize(var_0_11, var_0_11)

		if var_3_18[iter_3_3] == -1 then
			xyd.setItemBorder(var_3_23, -1, nil, nil, var_3_21)
			xyd.setItemStarOnTop(var_3_23, 3)
		else
			xyd.setItemBorder(var_3_23, var_3_18[iter_3_3])
		end

		local var_3_26 = {
			id = var_3_18[iter_3_3]
		}

		arg_3_0:addTips(var_3_23, var_3_26)
		var_3_24:addChild(var_3_23)
		var_3_24:setContentSize(var_0_11 + 7, var_0_11)
		var_3_25:addContent(var_3_24)
		var_3_25:setItemSize(var_0_11 + 7, var_0_11)
		arg_3_0.listview:addItem(var_3_25)
	end

	arg_3_0.listview:reload()
	arg_3_0:updateLayout()
end

function var_0_0.scrollListener(arg_6_0, arg_6_1)
	if arg_6_1.name == "began" then
		arg_6_0.scrollViewMoved_ = false
		arg_6_0.prevX_ = arg_6_1.x
	elseif arg_6_1.name == "moved" and 20 <= math.abs(arg_6_1.x - arg_6_0.prevX_) then
		arg_6_0.scrollViewMoved_ = true
	end
end

function var_0_0.updateLayout(arg_7_0)
	if arg_7_0.campaignType == xyd.CampaignType.SUPER or arg_7_0.campaignType == xyd.CampaignType.WEI or arg_7_0.campaignType == xyd.CampaignType.SHU or arg_7_0.campaignType == xyd.CampaignType.WU or arg_7_0.campaignType == xyd.CampaignType.WUMIAN or arg_7_0.campaignType == xyd.CampaignType.MOMIAN or arg_7_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_7_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_7_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_7_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
		arg_7_0:nodeByName(var_0_0.PANEL_LEFT):setVisible(true)
		arg_7_0:nodeByName(var_0_0.PANEL_ENERGY):setPositionY(90)

		if not tolua.isnull(arg_7_0:nodeByName("left_times")) then
			arg_7_0:nodeByName("left_times"):setString(arg_7_0.params.dailyLimit)
		end

		if not tolua.isnull(arg_7_0:nodeByName("limit_times")) then
			if arg_7_0.campaignType == xyd.CampaignType.SUPER then
				arg_7_0:nodeByName("limit_times"):setString("/" .. var_0_7)
			elseif arg_7_0.campaignType == xyd.CampaignType.WUMIAN or arg_7_0.campaignType == xyd.CampaignType.MOMIAN then
				arg_7_0:nodeByName("limit_times"):setString("/" .. var_0_8)
			elseif arg_7_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
				arg_7_0:nodeByName("limit_times"):setString("/" .. xyd.tables.misc.sakuraSecurityFightLimit)
			else
				arg_7_0:nodeByName("limit_times"):setString("/" .. var_0_6)
			end
		end

		if arg_7_0.params.dailyLimit <= 0 then
			arg_7_0:nodeByName("buy_button"):setVisible(true)
		else
			arg_7_0:nodeByName("buy_button"):setVisible(false)
		end
	else
		arg_7_0:nodeByName(var_0_0.PANEL_LEFT):setVisible(false)
		arg_7_0:nodeByName(var_0_0.PANEL_ENERGY):setPositionY(60)
	end

	if arg_7_0.campaignType == xyd.CampaignType.CHALLENGE then
		arg_7_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		arg_7_0:nodeByName("panel_challenge"):setVisible(true)

		if arg_7_0.cur_xg > 1 then
			arg_7_0:nodeByName("challenge_leftBtn"):setVisible(true)
		else
			arg_7_0:nodeByName("challenge_leftBtn"):setVisible(false)
		end

		if arg_7_0.cur_xg < arg_7_0.max_xg then
			arg_7_0:nodeByName("challenge_rightBtn"):setVisible(true)
		else
			arg_7_0:nodeByName("challenge_rightBtn"):setVisible(false)
		end

		arg_7_0:nodeByName("challenge_type_txt"):setString(arg_7_0.challengeTypeTxt[arg_7_0.challengeType[arg_7_0.cur_xg]])
		arg_7_0:nodeByName("challenge_icon"):loadTexture("windows/map_window/challenge_type" .. arg_7_0.challengeType[arg_7_0.cur_xg] .. "_s.png")
	elseif arg_7_0.star < var_0_4 then
		arg_7_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		arg_7_0:nodeByName("panel_challenge"):setVisible(false)

		arg_7_0.sweepNum = var_0_5

		if arg_7_0.campaignType ~= xyd.CampaignType.NORMAL then
			arg_7_0.sweepNum = arg_7_0.params.dailyLimit
		end
	else
		arg_7_0:nodeByName("panel_challenge"):setVisible(false)
		arg_7_0:initSweepPanel()

		if arg_7_0.campaignType == xyd.CampaignType.SUPER or arg_7_0.campaignType == xyd.CampaignType.NORMAL or arg_7_0.player_.lev >= 55 or arg_7_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
			arg_7_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(true)
		else
			arg_7_0:nodeByName(var_0_0.PANEL_SWEEP):setVisible(false)
		end

		arg_7_0.sweepNum = var_0_5

		if arg_7_0.campaignType ~= xyd.CampaignType.NORMAL then
			arg_7_0.sweepNum = arg_7_0.params.dailyLimit
		end

		if not tolua.isnull(arg_7_0:nodeByName("sweep_num_txt")) then
			if arg_7_0.sweepNum > 0 then
				arg_7_0:nodeByName("sweep_num_txt"):setString(string.format(var_0_1:translation("MAP_SWEEP_NUM"), tostring(arg_7_0.sweepNum)))
			else
				arg_7_0:nodeByName("sweep_num_txt"):setString(var_0_1:translation("MAP_NO_SWEEP"))
			end
		end

		if not tolua.isnull(arg_7_0:nodeByName("sweep_txt")) then
			arg_7_0:nodeByName("sweep_txt"):setString(var_0_1:translation("MAP_SWEEP"))
		end

		if not tolua.isnull(arg_7_0:nodeByName("sweep_item_num")) then
			arg_7_0:nodeByName("sweep_item_num"):setString(string.format(var_0_1:translation("MAP_SWEEP_ITEM"), tostring(arg_7_0.hasItemNum)))
		end
	end
end

function var_0_0.willOpen(arg_8_0, arg_8_1)
	arg_8_0:nodeByName("left_label"):setString(var_0_1:translation("MAP_LEFT_TIMES"))
	arg_8_0:setTouchSwallowEnabled(true)
	arg_8_0:layout()
	arg_8_0:updateModelContainer()
end

function var_0_0.updateModelContainer(arg_9_0)
	arg_9_0:nodeByName("model_container"):removeAllChildren()

	local var_9_0 = arg_9_0:nodeByName("model_container"):getContentSize()
	local var_9_1 = xyd.tables.campaign:monsterDisplay(arg_9_0.campaignID)
	local var_9_2 = var_9_1[#var_9_1]
	local var_9_3 = xyd.tables.campaign:smallBg(arg_9_0.campaignID)

	if var_9_3 and var_9_3 ~= "" then
		local var_9_4 = xyd.SpriteLoader.new(var_9_3, nil, nil, xyd.DefaultImageType.SMALL_MAP_BG)

		var_9_4:addTo(arg_9_0:nodeByName("model_container"))
		var_9_4:setPosition(cc.p(var_9_0.width / 2, var_9_0.height / 2))
	end

	if var_9_2 and var_9_2 > 0 then
		local var_9_5 = xyd.tables.hero:modelID(var_9_2)
		local var_9_6 = xyd.HeroAnimation.new(nil, var_9_5, xyd.tables.model:uiScale(var_9_5) * 0.8, {})

		var_9_6:addTo(arg_9_0:nodeByName("model_container"))
		var_9_6:setPosition(cc.p(var_9_0.width / 2, 30))
		var_9_6:idle()
	end
end

function var_0_0.didOpen(arg_10_0)
	local function var_10_0()
		local var_11_0
		local var_11_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		arg_10_0.buyEnergyTimes = var_11_1.buyEnergyTimes
		arg_10_0.buyEnergyCost = xyd.tables.refreshCost:buyEnergyCost(arg_10_0.buyEnergyTimes + 1)
		arg_10_0.maxBuyTimes = xyd.tables.vip:numEnergy(var_11_1.vip)

		if var_11_1.privilegeLeftCardDay > 0 then
			local var_11_2 = xyd.tables.monthlyPrivilege:numEnergy(1)

			arg_10_0.maxBuyTimes = arg_10_0.maxBuyTimes + var_11_2
		end

		local var_11_3 = xyd.tables.misc.energyMaxLimit

		str = string.format(var_0_1:translation("ADD_ENERGY"), arg_10_0.buyEnergyCost, var_0_10, arg_10_0.buyEnergyTimes)

		if arg_10_0:isHasTiLiItem() then
			local var_11_4 = {
				text = str,
				callback = function()
					if arg_10_0.buyEnergyTimes >= arg_10_0.maxBuyTimes then
						str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_10_0.buyEnergyTimes)
						var_11_0 = xyd.CommonAlertType.ONE_BTN

						local var_12_0 = xyd.luaStringSplit(str, "\n")

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_12_0, function()
							local var_13_0 = {}

							var_13_0.windowState = false

							xyd.WindowManager.get():openWindow("vip_recharge", var_13_0)
							xyd.WindowManager.get():closeWindow("add_energy")
						end, nil, nil, arg_10_0.colorMode)
					elseif arg_10_0.player_.energy >= var_11_3 then
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("TILI_LIMIT_INFO")
						})
						xyd.WindowManager.get():closeWindow("buy_tili")
					else
						local var_12_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_10_0.buyEnergyCost > var_12_1.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_14_0 = {}

								var_14_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_14_0)
							end, nil, nil, arg_10_0.colorMode)
						else
							arg_10_0.addEnergyModel:addEnergy(function(arg_15_0)
								if arg_15_0 == xyd.error.OK then
									return true
								end
							end)
							xyd.WindowManager.get():closeWindow("buy_tili")
						end
					end
				end
			}

			xyd.WindowManager.get():openWindow("buy_tili", var_11_4)
		else
			local var_11_5 = xyd.luaStringSplit(str, "\n")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_5, function()
				local var_16_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

				if arg_10_0.buyEnergyTimes >= arg_10_0.maxBuyTimes then
					str = string.format(var_0_1:translation("CAN_NOT_ADDENERGY"), arg_10_0.buyEnergyTimes)
					var_11_0 = xyd.AlertType.CONFIRM

					local var_16_1 = xyd.luaStringSplit(str, "\n")

					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_16_1, function()
						local var_17_0 = {}

						var_17_0.windowState = false

						xyd.WindowManager.get():openWindow("vip_recharge", var_17_0)
						xyd.WindowManager.get():closeWindow("add_energy")
					end, nil, nil, arg_10_0.colorMode)
				elseif arg_10_0.buyEnergyCost > var_16_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_18_0 = {}

						var_18_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_18_0)
					end, nil, nil, arg_10_0.colorMode)
				else
					arg_10_0.addEnergyModel:addEnergy(function(arg_19_0)
						if arg_19_0 == xyd.error.OK then
							return true
						end
					end)
					xyd.WindowManager.get():closeWindow("alert")
				end
			end, nil, 0, arg_10_0.colorMode)
		end
	end

	arg_10_0:nodeByName(var_0_0.START_BUTTON):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_20_0, arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if (arg_10_0.campaignType == xyd.CampaignType.SUPER or arg_10_0.campaignType == xyd.CampaignType.WEI or arg_10_0.campaignType == xyd.CampaignType.SHU or arg_10_0.campaignType == xyd.CampaignType.WU or arg_10_0.campaignType == xyd.CampaignType.MOMIAN or arg_10_0.campaignType == xyd.CampaignType.WUMIAN or arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN) and arg_10_0.sweepNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_TIMES")
				})

				return
			end

			if arg_10_0.player_.energy < xyd.tables.campaign:energyCost(arg_10_0.campaignID) then
				var_10_0()
			elseif arg_10_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_10_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_10_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
				local var_20_0 = {}

				arg_10_0.guild:loadAllTeamPets(var_20_0, function(arg_21_0)
					local var_21_0 = false
					local var_21_1 = {}

					if arg_21_0 == xyd.error.OK then
						var_21_0 = true

						for iter_21_0, iter_21_1 in ipairs(arg_10_0.guild:getAllTeamPets()) do
							local var_21_2 = var_0_13.new()

							var_21_2:populate(iter_21_1)

							var_21_2.player_name = iter_21_1.player_name
							var_21_2.rent_need_mana = iter_21_1.rent_need_mana
							var_21_2.can_rent = iter_21_1.can_rent
							var_21_2.player_id = iter_21_1.player_id

							table.insert(var_21_1, var_21_2)
						end
					end

					local var_21_3
					local var_21_4 = {
						type = var_21_3,
						campaignID = arg_10_0.campaignID,
						campaignType = arg_10_0.campaignType,
						itemComposeID = arg_10_0.itemComposeID,
						isMercenary = var_21_0,
						allTeamPets = var_21_1
					}

					if arg_10_0 then
						var_21_4.star = arg_10_0.star
					end

					xyd.WindowManager.get():openWindow("select_pet_team", var_21_4)
				end)
			else
				if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
					arg_10_0.player_:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_SELECT)
				end

				local var_20_1 = {
					campaign_type = arg_10_0.campaignType
				}

				arg_10_0.guild:loadAllTeamHeros(var_20_1, function(arg_22_0)
					local var_22_0 = false
					local var_22_1 = {}

					if arg_22_0 == xyd.error.OK then
						var_22_0 = true

						local var_22_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

						for iter_22_0, iter_22_1 in ipairs(var_22_2:getAllTeamHeros()) do
							local var_22_3 = var_0_12.new()

							var_22_3:populate(iter_22_1)

							var_22_3.player_name = iter_22_1.player_name
							var_22_3.rent_need_mana = iter_22_1.rent_need_mana
							var_22_3.can_rent = iter_22_1.can_rent
							var_22_3.player_id = iter_22_1.player_id

							table.insert(var_22_1, var_22_3)
						end
					end

					if not arg_10_0 or tolua.isnull(arg_10_0) then
						return
					end

					local var_22_4

					if arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						var_22_4 = xyd.SelectTeamType.SAKURA_CAMPAIGN
					elseif arg_10_0.campaignType == xyd.CampaignType.CHALLENGE then
						var_22_4 = xyd.SelectTeamType.CHALLENGE
					elseif arg_10_0.campaignType == xyd.CampaignType.STUDENT_OVER then
						var_22_4 = xyd.SelectTeamType.STUDENT_OVER
						var_22_0 = nil
						var_22_1 = nil
					end

					local var_22_5 = {
						type = var_22_4,
						campaignID = arg_10_0.campaignID,
						campaignType = arg_10_0.campaignType,
						itemComposeID = arg_10_0.itemComposeID,
						isMercenary = var_22_0,
						allTeamHeros = var_22_1
					}

					if arg_10_0 then
						var_22_5.star = arg_10_0.star
					end

					if arg_10_0:checkShowBattleStory() then
						arg_10_0:playStory(function(arg_23_0)
							var_22_5.assistID = arg_23_0

							xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_22_5)

							if xyd.isMapWindowCampaignType(arg_10_0.campaignType) then
								xyd.WindowManager.get():closeWindow(arg_10_0)
							end
						end)
					else
						xyd.WindowManager.get():openWindow(xyd.WindowName.SelectTeamWnd, var_22_5)

						if xyd.isMapWindowCampaignType(arg_10_0.campaignType) then
							xyd.WindowManager.get():closeWindow(arg_10_0)
						end
					end
				end)
			end
		end
	end)
	arg_10_0:playGuide()
	arg_10_0:nodeByName("buy_button"):addTouchEventListener(function(arg_24_0, arg_24_1)
		xyd.buttonScaleAnim(arg_24_0, arg_24_1)

		if arg_24_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.campaignType == xyd.CampaignType.SUPER then
				local var_24_0 = xyd.tables.vip:resetFuben(arg_10_0.player_.vip)

				if arg_10_0.player_.privilegeLeftCardDay > 0 then
					var_24_0 = var_24_0 + xyd.tables.monthlyPrivilege:numElite(1)
				end

				if var_24_0 <= arg_10_0.params.resetCount then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("MAP_RESET_TIMES2"), arg_10_0.params.resetCount),
						var_0_1:translation("MAP_RESET_VIP")
					}, function()
						xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
							windowState = false
						})
					end, {
						rightName = var_0_1:translation("CHECK_PRIVILEGE")
					}, nil, arg_10_0.colorMode)

					return
				end

				local function var_24_1()
					local var_26_0 = {
						campaign_id = arg_10_0.campaignID,
						campaign_type = arg_10_0.campaignType
					}

					xyd.Backend.get():request(xyd.mid.RESET_CAMPAIGN, var_26_0, function(arg_27_0, arg_27_1, arg_27_2)
						if arg_27_0 == xyd.error.OK then
							local var_27_0 = arg_27_1.campaign_id

							arg_10_0.player_.worldMaps_[var_27_0] = {}
							arg_10_0.player_.worldMaps_[var_27_0].star = tonumber(arg_27_1.star)
							arg_10_0.player_.worldMaps_[var_27_0].dailyLimit = tonumber(arg_27_1.daily_limit)
							arg_10_0.player_.worldMaps_[var_27_0].resetCount = tonumber(arg_27_1.reset_count)
							arg_10_0.params.dailyLimit = tonumber(arg_27_1.daily_limit)
							arg_10_0.params.resetCount = tonumber(arg_27_1.reset_count)

							arg_10_0:layout()

							local var_27_1 = xyd.WindowManager.get():getWindow("map_window")

							if var_27_1 then
								var_27_1:updateChapter()
							end

							if arg_10_0.itemComposeID then
								xyd.EventDispatcher.get():dispatchEvent({
									name = xyd.event.UPDATE_STONE_EQUIP_CAMPAIGN,
									params = {
										itemComposeID = arg_10_0.itemComposeID
									}
								})
							end
						end
					end)
				end

				local var_24_2 = xyd.tables.refreshCost:refreshEliteCost(arg_10_0.params.resetCount + 1)

				if var_24_2 > arg_10_0.player_.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_28_0 = {}

						var_28_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_28_0)
					end, nil, nil, arg_10_0.colorMode)
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("MAP_RESET"), var_24_2),
						var_0_1:translation("SWEEP_ITEM_CONTINUE") .. string.format(var_0_1:translation("MAP_RESET_TIMES"), arg_10_0.params.resetCount)
					}, function()
						var_24_1()
					end, nil, nil, arg_10_0.colorMode)
				end
			else
				if arg_10_0.params.buyTimes >= arg_10_0.params.maxBuyTime then
					local var_24_3 = xyd.tables.translation:translation("DAILY_TIMES_OVER")

					xyd.WindowManager.get():openWindow("toast", {
						message = var_24_3
					})

					return
				end

				local var_24_4 = xyd.tables.translation:translation("DAILY_TRIAL_INFO")

				if arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
					var_24_4 = string.format(xyd.tables.translation:translation("BUY_SAKURA_TIMES"), xyd.tables.misc.sakuraSecurityPrice[arg_10_0.params.buyTimes + 1])
				end

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_24_4, function()
					buyExtralTime()
				end, nil, 0, arg_10_0.colorMode)

				function buyExtralTime()
					local var_31_0 = xyd.tables.trialConfig:trials(arg_10_0.campaignType)
					local var_31_1 = tonumber(string.sub(tostring(var_31_0[1]), 1, 1))
					local var_31_2 = {
						xyd.DailyConsumeType.XiaoYao,
						xyd.DailyConsumeType.YiLing,
						xyd.DailyConsumeType.ChiBi,
						xyd.DailyConsumeType.PhysicsTest,
						xyd.DailyConsumeType.MagicTest
					}
					local var_31_3

					if arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						var_31_3 = xyd.tables.misc.sakuraSecurityPrice[arg_10_0.params.buyTimes + 1]
					else
						var_31_3 = xyd.tables.dailyConsume:getCost(var_31_2[var_31_1])
					end

					local var_31_4 = 0

					if arg_10_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_10_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_10_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE then
						var_31_4 = ({
							xyd.DailyConsumeType.CLOUD_LADDER,
							xyd.DailyConsumeType.CLOUD_ROAD,
							xyd.DailyConsumeType.CLOUD_TEMPLE
						})[arg_10_0.campaignType - 39]
					else
						var_31_4 = var_31_2[var_31_1]
					end

					if var_31_3 > arg_10_0.player_.crystal then
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
							local var_32_0 = {}

							var_32_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_32_0)
						end, nil, nil, arg_10_0.colorMode)

						return
					end

					if arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN then
						xyd.Backend.get():request(xyd.mid.BUY_SAKURA_TIMES, {}, function(arg_33_0, arg_33_1)
							if arg_33_0 == xyd.error.OK then
								arg_10_0.params.dailyLimit = arg_33_1.left_times
								arg_10_0.params.buyTimes = arg_33_1.buy_times

								arg_10_0:layout()
							end
						end)
					else
						params = {
							consume_id = var_31_4
						}

						xyd.Backend.get():request(xyd.mid.DAILY_CONSUNME, params, function(arg_34_0, arg_34_1)
							if arg_34_0 == xyd.error.OK then
								arg_10_0.player_.trialInfos_[arg_10_0.campaignType].leftTimes = arg_34_1.trial_info.left_times
								arg_10_0.params.dailyLimit = arg_34_1.trial_info.left_times
								arg_10_0.params.buyTimes = arg_10_0.params.buyTimes + 1

								arg_10_0:layout()
							end
						end)
					end
				end
			end
		end
	end)
	arg_10_0:nodeByName("multi_button"):addTouchEventListener(function(arg_35_0, arg_35_1)
		xyd.buttonScaleAnim(arg_35_0, arg_35_1)

		if arg_35_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.sweepNum <= 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_DAILY_TIMES")
				})

				return
			end

			if not xyd.tables.vip:quickSweep(arg_10_0.player_.vip) and arg_10_0.selfPlayer.privilegeLeftCardDay <= 0 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("SWEEP_VIP_PRIVILEGE"), function()
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
						windowState = false
					})
				end, {
					rightName = var_0_1:translation("CHECK_PRIVILEGE")
				}, nil, arg_10_0.colorMode)

				return
			end

			if arg_10_0.player_.energy < xyd.tables.campaign:energyCost(arg_10_0.campaignID) * arg_10_0.sweepNum then
				var_10_0()
			else
				local var_35_0 = {
					campaign_id = arg_10_0.campaignID,
					campaign_type = arg_10_0.campaignType,
					sweep_num = arg_10_0.sweepNum,
					itemComposeID = arg_10_0.itemComposeID,
					needItemComposeNum = arg_10_0.needItemComposeNum
				}

				if arg_10_0.hasItemNum < arg_10_0.sweepNum then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("SWEEP_ITEM_ABSENCE"), arg_10_0.sweepNum),
						var_0_1:translation("SWEEP_ITEM_CONTINUE")
					}, function()
						local var_37_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

						if arg_10_0.sweepNum > var_37_0.crystal then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_38_0 = {}

								var_38_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_38_0)
							end, nil, nil, arg_10_0.colorMode)
						else
							var_35_0.sweep_type = xyd.SweepType.CRYSTAL_SWEEP

							xyd.WindowManager.get():openWindow("sweep_window", var_35_0)
						end
					end, nil, 0, arg_10_0.colorMode)
				else
					var_35_0.sweep_type = xyd.SweepType.ITEM_SWEEP

					xyd.WindowManager.get():openWindow("sweep_window", var_35_0)
				end
			end
		end
	end)
	arg_10_0:nodeByName("once_button"):addTouchEventListener(function(arg_39_0, arg_39_1)
		xyd.buttonScaleAnim(arg_39_0, arg_39_1)

		if arg_39_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_10_0.sweepNum <= 0 and (arg_10_0.campaignType == xyd.CampaignType.SUPER or arg_10_0.campaignType == xyd.CampaignType.WEI or arg_10_0.campaignType == xyd.CampaignType.SHU or arg_10_0.campaignType == xyd.CampaignType.WU or arg_10_0.campaignType == xyd.CampaignType.MOMIAN or arg_10_0.campaignType == xyd.CampaignType.WUMIAN or arg_10_0.campaignType == xyd.CampaignType.SAKURA_CAMPAIGN or arg_10_0.campaignType == xyd.CampaignType.CLOUD_LADDER or arg_10_0.campaignType == xyd.CampaignType.CLOUD_ROAD or arg_10_0.campaignType == xyd.CampaignType.CLOUD_TEMPLE) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("MAP_NO_DAILY_TIMES")
				})

				return
			end

			if arg_10_0.player_.energy < xyd.tables.campaign:energyCost(arg_10_0.campaignID) then
				var_10_0()
			else
				local var_39_0 = {
					sweep_num = 1,
					campaign_id = arg_10_0.campaignID,
					campaign_type = arg_10_0.campaignType,
					itemComposeID = arg_10_0.itemComposeID,
					needItemComposeNum = arg_10_0.needItemComposeNum,
					awake_mission = arg_10_0.awakeMissionID
				}

				if arg_10_0.hasItemNum < 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_1:translation("SWEEP_ITEM_ABSENCE"), 1),
						var_0_1:translation("SWEEP_ITEM_CONTINUE")
					}, function()
						if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).crystal < 1 then
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
								local var_41_0 = {}

								var_41_0.windowState = true

								xyd.WindowManager.get():openWindow("vip_recharge", var_41_0)
							end, nil, nil, arg_10_0.colorMode)
						else
							var_39_0.sweep_type = xyd.SweepType.CRYSTAL_SWEEP

							xyd.WindowManager.get():openWindow("sweep_window", var_39_0)
						end
					end, nil, 0, arg_10_0.colorMode)
				else
					var_39_0.sweep_type = xyd.SweepType.ITEM_SWEEP

					xyd.WindowManager.get():openWindow("sweep_window", var_39_0)
				end
			end
		end
	end)
	arg_10_0:nodeByName("challenge_leftBtn"):addTouchEventListener(function(arg_42_0, arg_42_1)
		if arg_42_1 == ccui.TouchEventType.ended then
			arg_10_0.campaignID = arg_10_0.campaignID - 1
			arg_10_0.cur_xg = arg_10_0.cur_xg - 1

			arg_10_0:layout()
		end
	end)
	arg_10_0:nodeByName("challenge_rightBtn"):addTouchEventListener(function(arg_43_0, arg_43_1)
		if arg_43_1 == ccui.TouchEventType.ended then
			arg_10_0.campaignID = arg_10_0.campaignID + 1
			arg_10_0.cur_xg = arg_10_0.cur_xg + 1

			arg_10_0:layout()
		end
	end)
	arg_10_0:addBlockLayer(nil, false, true)
end

function var_0_0.setIDBeforeGuideWnd(arg_44_0)
	local var_44_0 = xyd.StoryData.get():getGuideID()

	if var_44_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP_DETAIL)
	elseif var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_TWO)
	elseif var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_TWO)
	elseif var_44_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_ONE)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_45_0)
	local var_45_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_45_1 = xyd.StoryData.get():getGuideID()

	if var_45_1 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_SELECT_TEAM_ONE)
	elseif var_45_1 == xyd.GuideStoryType.GUIDE_MISSION_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_END)
	elseif var_45_1 == xyd.GuideStoryType.GUIDE_FIGHT_2_TWO then
		var_45_0:sendOperationLog(xyd.StatID.ID_FIGHT_2_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_THREE)
	elseif var_45_1 == xyd.GuideStoryType.GUIDE_FIGHT_3_ONE then
		var_45_0:sendOperationLog(xyd.StatID.ID_FIGHT_3_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_TWO)
	elseif var_45_1 == xyd.GuideStoryType.GUIDE_FIGHT_4_TWO then
		var_45_0:sendOperationLog(xyd.StatID.ID_FIGHT_4_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_THREE)
	elseif var_45_1 == xyd.GuideStoryType.GUIDE_FIGHT_5_TWO then
		var_45_0:sendOperationLog(xyd.StatID.ID_FIGHT_5_2)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_THREE)
	end
end

function var_0_0.checkGuideIntoTeamWnd(arg_46_0)
	local var_46_0 = xyd.StoryData.get():getGuideID()

	if var_46_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END or var_46_0 == xyd.GuideStoryType.GUIDE_MISSION_FOUR or var_46_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE or var_46_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START or var_46_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE or var_46_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_TWO then
		return true
	end

	return false
end

function var_0_0.playGuide(arg_47_0)
	local var_47_0 = xyd.StoryData.get():getGuideID()

	if arg_47_0:checkGuideIntoTeamWnd() then
		arg_47_0:setIDBeforeGuideWnd()

		local var_47_1 = xyd.StoryData.get():getGuideID()
		local var_47_2 = arg_47_0:nodeByName("start")
		local var_47_3 = {
			920,
			350
		}

		xyd.showGuideWnd(var_47_2, nil, nil, 2, var_47_3, true)
		arg_47_0:setIDAfterGuideWnd()
	end
end

function var_0_0.getAwakeMissionItem(arg_48_0)
	local var_48_0 = arg_48_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_48_0 and xyd.getMissionGoIDs(var_48_0) == arg_48_0.campaignID then
		local var_48_1 = var_0_3:awakeMissionIds(arg_48_0.campaignID)
		local var_48_2 = var_0_3:awakeDropboxIds(arg_48_0.campaignID)
		local var_48_3

		for iter_48_0, iter_48_1 in ipairs(var_48_1) do
			if var_48_0 == iter_48_1 then
				local var_48_4 = xyd.tables.campaignDropbox:dropItem(var_48_2[iter_48_0])

				if var_48_4 then
					return var_48_4
				end
			end
		end
	end

	return nil
end

function var_0_0.getAwakeTwiceMissionItem(arg_49_0)
	local var_49_0 = arg_49_0.task:isHasAwakeOpen(xyd.AwakeType.HERO_TWICE)

	if var_49_0 then
		local var_49_1 = var_0_3:awakeTwiceMissionIds(arg_49_0.campaignID)
		local var_49_2 = var_0_3:awakeTwiceDropboxIds(arg_49_0.campaignID)

		for iter_49_0, iter_49_1 in ipairs(var_49_1) do
			if var_49_0 == iter_49_1 then
				return xyd.tables.campaignDropbox:dropItem(var_49_2[iter_49_0])
			end
		end
	end
end

function var_0_0.initSweepPanel(arg_50_0)
	local var_50_0 = arg_50_0:nodeByName(var_0_0.PANEL_SWEEP)
	local var_50_1 = var_50_0:getChildByName("multi_button")
	local var_50_2 = arg_50_0:nodeByName("sweep_num_txt")
	local var_50_3 = var_50_0:getChildByName("sweep_item_num")
	local var_50_4 = var_50_0:getChildByName("awake_hero_avatar")
	local var_50_5 = var_50_0:getChildByName("awake_process")

	if arg_50_0.isAwakeCampaign and arg_50_0.awakeMission.count > 0 and arg_50_0.awakeMission.count < xyd.tables.mission:awakeTaskNum(arg_50_0.awakeMissionID)[1] then
		var_50_1:setVisible(false)
		var_50_2:setVisible(false)
		var_50_3:setVisible(false)
		var_50_4:setVisible(true)
		var_50_5:setVisible(true)
		xyd.setAvatarBorderNewUI(arg_50_0.awakeHero, var_50_4)
		arg_50_0:nodeByName("awake_process"):setString(arg_50_0.awakeMission.count .. "/" .. xyd.tables.mission:awakeTaskNum(arg_50_0.awakeMissionID)[1])
	else
		var_50_1:setVisible(true)
		var_50_2:setVisible(true)
		var_50_3:setVisible(true)
		var_50_4:setVisible(false)
		var_50_5:setVisible(false)
	end
end

function var_0_0.awakeMissionInit(arg_51_0)
	local var_51_0 = arg_51_0.task:isHasAwakeOpen(xyd.AwakeType.HERO)

	if var_51_0 and xyd.getMissionGoIDs(var_51_0) == arg_51_0.campaignID then
		arg_51_0.isAwakeCampaign = true
		arg_51_0.awakeMissionID = var_51_0
		arg_51_0.awakeMission = arg_51_0.task:getTaskByID(var_51_0, xyd.TaskType.AWAKE)
		arg_51_0.awakeHero = arg_51_0.player_:getHeroByTableID(xyd.tables.mission:beforeAwakenID(var_51_0))
	end
end

function var_0_0.checkShowBattleStory(arg_52_0)
	if arg_52_0.campaignType ~= xyd.CampaignType.NORMAL then
		return false
	end

	local var_52_0, var_52_1 = arg_52_0:getBattleID()

	if var_52_1 then
		return true
	end

	return false
end

function var_0_0.getBattleID(arg_53_0)
	local var_53_0 = 0
	local var_53_1
	local var_53_2
	local var_53_3 = false
	local var_53_4 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_53_0.campaignType == xyd.CampaignType.NORMAL and arg_53_0.campaignID ~= 0 then
		local var_53_5 = xyd.tables.campaign:firstFightID(arg_53_0.campaignID)
		local var_53_6 = var_53_4.worldMaps_[arg_53_0.campaignID].star or 0

		if var_53_5 ~= 0 and var_53_6 <= 0 then
			var_53_0 = var_53_5
			var_53_3 = true
		end
	end

	return var_53_0, var_53_3
end

function var_0_0.playStory(arg_54_0, arg_54_1)
	if arg_54_0.campaignType ~= xyd.CampaignType.NORMAL then
		return
	end

	local var_54_0, var_54_1 = arg_54_0:getBattleID()

	if not var_54_1 or var_54_0 == 0 then
		if arg_54_1 then
			arg_54_1()
		end

		return
	end

	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	local var_54_2 = var_0_2:assistStory(var_54_0)

	if var_54_1 and var_54_2 > 0 then
		arg_54_0:hide()

		local var_54_3 = xyd.WindowManager.get():openWindow("battle_special_story", {
			story_state = 1,
			story_id = var_54_2
		})

		cc.EventProxy.new(var_54_3, var_54_3):addEventListener(xyd.event.STORY_COMPLETE, function(arg_55_0)
			if arg_55_0.state == 1 then
				arg_54_0:show()

				local var_55_0

				if arg_55_0.params and next(arg_55_0.params) then
					var_55_0 = arg_55_0.params.assistID
				end

				if arg_54_1 then
					arg_54_1(var_55_0)
				end
			end
		end)
	else
		if arg_54_1 then
			arg_54_1()
		end

		return
	end
end

function var_0_0.isHasTiLiItem(arg_56_0)
	local var_56_0 = arg_56_0.player_:getBackpack():getItems()

	for iter_56_0, iter_56_1 in pairs(var_56_0) do
		if xyd.tables.item:subType(iter_56_1.itemID) == xyd.ConsumeItemType.ENERGY_ITEM then
			return true
		end
	end

	return false
end

return var_0_0
