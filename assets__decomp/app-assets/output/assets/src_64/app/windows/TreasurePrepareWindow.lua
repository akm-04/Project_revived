local var_0_0 = class("TreasurePrepareWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.treasureLocation
local var_0_3 = xyd.tables.treasureType
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.misc
local var_0_6 = xyd.tables.treasureSkill
local var_0_7 = cc.c4b(27, 151, 46, 255)
local var_0_8 = 105
local var_0_9 = 40
local var_0_10 = 95

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.locationId = arg_1_2.locationId
	arg_1_0.types = arg_1_2.types
	arg_1_0.titleName = arg_1_2.titleName
	arg_1_0.nowIndex = 1

	for iter_1_0, iter_1_1 in ipairs(arg_1_0.types) do
		if iter_1_1 == arg_1_2.typeName then
			arg_1_0.nowIndex = iter_1_0
		end
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_title"):setString(arg_2_0.titleName)
	arg_2_0:nodeByName("txt_address"):setString(var_0_1:translation("TREASURE_REWARD_DES_1"))
	arg_2_0:nodeByName("txt_supplies"):setString(var_0_1:translation("TREASURE_REWARD_DES_2"))
	arg_2_0:nodeByName("txt_reward"):setString(var_0_1:translation("TREASURE_REWARD_DES_3"))
	arg_2_0:nodeByName("txt_random_reward"):setString(var_0_1:translation("TREASURE_REWARD_DES_4"))
	arg_2_0:nodeByName("txt_team"):setString(var_0_1:translation("TREASURE_REWARD_DES_5"))
	arg_2_0:nodeByName("txt_send"):setString(var_0_1:translation("TREASURE_REWARD_DES_6"))
	arg_2_0:nodeByName("btn_send"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("btn_send"), arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_3_0 = {
				partners = arg_2_0.heroIds,
				treasure_type = arg_2_0.nowType,
				team_id = arg_2_0.locationId,
				sp_num = arg_2_0.spNum
			}

			if not arg_2_0.heroIds or #arg_2_0.heroIds == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TREASURE_NO_HEROS_TIP")
				})

				return true
			end

			if arg_2_0.spNum > arg_2_0.selfPlayer.treasureSP then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("TREASURE_SP_NOT_ENOUGH")
				})

				return true
			end

			arg_2_0.treasureModel:setTreasurePartner(function(arg_4_0)
				if arg_4_0 == xyd.error.OK then
					xyd.WindowManager.get():closeWindow(arg_2_0)

					return true
				end
			end, var_3_0)
		end
	end)
	arg_2_0:nodeByName("btn_add"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName("btn_add"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_2_0.guideHand then
				arg_2_0.guideHand:removeSelf()

				arg_2_0.guideHand = nil
			end

			local var_5_0 = {
				locationId = arg_2_0.locationId,
				typeId = arg_2_0.nowType
			}

			xyd.WindowManager.get():openWindow("treasure_edit", var_5_0)
		end
	end)

	arg_2_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.listView_:setBounceable(true)
	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.delegate))

	arg_2_0.addressListView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list_address"):getWidth(), arg_2_0:nodeByName("list_address"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list_address")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.addressListView_:setBounceable(true)
	arg_2_0.addressListView_:setDelegate(handler(arg_2_0, arg_2_0.addressDelegate))
	arg_2_0.addressListView_:reload()
	arg_2_0:updateHeros()
	arg_2_0:updateTypeName()
end

function var_0_0.sortHeroDatas(arg_6_0)
	arg_6_0.datas = {}
	arg_6_0.heroIds = {}

	if arg_6_0.treasureModel.MemeoryTeams and arg_6_0.treasureModel.MemeoryTeams[arg_6_0.locationId] then
		for iter_6_0, iter_6_1 in pairs(arg_6_0.treasureModel.MemeoryTeams[arg_6_0.locationId]) do
			local var_6_0 = arg_6_0.selfPlayer:getHeroByID(iter_6_1)

			table.insert(arg_6_0.datas, var_6_0)
			table.insert(arg_6_0.heroIds, iter_6_1)
		end
	end

	arg_6_0.totalHero = 0

	for iter_6_2, iter_6_3 in pairs(var_0_4:getTreasureHeros(arg_6_0.locationId)) do
		if arg_6_0.selfPlayer:getHeroIgnoreAwaken(iter_6_3) then
			arg_6_0.totalHero = arg_6_0.totalHero + 1
		end
	end

	if arg_6_0.totalHero == #arg_6_0.treasureModel.MemeoryTeams[arg_6_0.locationId] then
		arg_6_0:nodeByName("red_point"):setVisible(false)
	else
		arg_6_0:nodeByName("red_point"):setVisible(true)
	end
end

function var_0_0.updateHeros(arg_7_0)
	arg_7_0:sortHeroDatas()
	arg_7_0.listView_:reload()
	arg_7_0:updateRewards()
	arg_7_0:nodeByName("txt_team_num"):setString(#arg_7_0.datas .. "/" .. var_0_2:maxMember(arg_7_0.locationId))
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	var_0_0.super:didOpen(arg_8_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_8_0):addEventListener(xyd.event.TREASURE_SAVE_HEROS, function(arg_9_0)
		arg_8_0:updateHeros()
	end)
	arg_8_0:playGuide()
end

function var_0_0.updateTypeName(arg_10_0, arg_10_1)
	local var_10_0 = arg_10_1

	if not arg_10_1 then
		var_10_0 = arg_10_0.types[arg_10_0.nowIndex]
	end

	arg_10_0.nowType = var_10_0

	arg_10_0:nodeByName("address_text"):setString(var_0_3:name(var_10_0))
	arg_10_0:nodeByName("node_item_pos"):removeAllChildren()

	local var_10_1 = var_0_3:chest(var_10_0)

	for iter_10_0, iter_10_1 in pairs(var_10_1) do
		local var_10_2 = display.newNode()

		var_10_2:setContentSize(var_0_10, var_0_10)
		xyd.setItemAndAddTips(var_10_2, iter_10_1, 1)
		arg_10_0:nodeByName("node_item_pos"):addChild(var_10_2)
		var_10_2:setPositionX((iter_10_0 - 1) * (var_0_10 + 15))
	end

	local var_10_3 = 75
	local var_10_4 = 13

	if (not arg_10_0.lastChestNum or arg_10_0.lastChestNum ~= 0) and #var_10_1 == 0 then
		arg_10_0:nodeByName("txt_random_reward"):setVisible(false)
		arg_10_0:nodeByName("node_item_pos"):setVisible(false)
		arg_10_0:nodeByName("container_team"):setPositionY(arg_10_0:nodeByName("container_team"):getPositionY() + var_10_3)
		arg_10_0:nodeByName("node_team_title"):setPositionY(arg_10_0:nodeByName("node_team_title"):getPositionY() + var_10_4)
	elseif arg_10_0.lastChestNum and arg_10_0.lastChestNum == 0 and #var_10_1 ~= 0 then
		arg_10_0:nodeByName("txt_random_reward"):setVisible(true)
		arg_10_0:nodeByName("node_item_pos"):setVisible(true)
		arg_10_0:nodeByName("container_team"):setPositionY(arg_10_0:nodeByName("container_team"):getPositionY() - var_10_3)
		arg_10_0:nodeByName("node_team_title"):setPositionY(arg_10_0:nodeByName("node_team_title"):getPositionY() - var_10_4)
	end

	arg_10_0.lastChestNum = #var_10_1

	arg_10_0:updateRewards()
end

function var_0_0.updateRewards(arg_11_0)
	arg_11_0:nodeByName("node_need_pos"):removeAllChildren()

	local var_11_0 = var_0_2:baseIce(arg_11_0.locationId)
	local var_11_1 = 0
	local var_11_2 = 0
	local var_11_3 = 0

	for iter_11_0, iter_11_1 in pairs(arg_11_0.datas) do
		if var_0_4:treasureSkill(iter_11_1:getTableID()) == xyd.TreasureSkillType.ICE_CREAM then
			var_11_1 = var_11_1 + var_0_6:num(xyd.TreasureSkillType.ICE_CREAM)
		end

		var_11_2 = var_11_2 + 1
		var_11_3 = var_11_3 + var_0_5.treasureColorParam * iter_11_1:getColor()
		var_11_3 = var_11_3 + var_0_5.treasureStarParam * iter_11_1:getStar()
		var_11_3 = var_11_3 + var_0_5.treasureLevelParam * iter_11_1:getLevel()
	end

	local var_11_4 = var_11_0 - var_11_1

	arg_11_0.spNum = var_11_4

	local var_11_5 = xyd.setItemWithTextNode(-3, var_11_4, var_0_7, var_0_9)

	arg_11_0:nodeByName("node_need_pos"):addChild(var_11_5)
	arg_11_0:nodeByName("node_get_pos"):removeAllChildren()

	if arg_11_0.treasureModel.teams[arg_11_0.locationId].with_external_award == 1 then
		local var_11_6 = arg_11_0.treasureModel.teams[arg_11_0.locationId].externa_crystal_award
		local var_11_7 = xyd.setItemWithTextNode(-1, var_11_6, var_0_7, var_0_9)

		arg_11_0:nodeByName("node_get_pos"):addChild(var_11_7)
		var_11_7:setPositionX(var_0_9 * 6)
	end

	local var_11_8 = xyd.tables.vip:tresureReward(arg_11_0.selfPlayer.vip)
	local var_11_9 = math.floor(var_11_8 * (var_0_5.treasureGoldParam1 + var_0_5.treasureGoldParam2 * var_11_2 + var_11_3))
	local var_11_10 = xyd.getTreasureItem(var_0_3:productType(arg_11_0.types[arg_11_0.nowIndex]), var_11_9)

	if arg_11_0.activities:isOpenDoubleTreasureAward() then
		var_11_10.item_num = var_11_10.item_num * 2
	end

	if var_11_2 == 0 then
		var_11_10.item_num = 0
	end

	local var_11_11 = xyd.setItemWithTextNode(var_11_10.item_id, var_11_10.item_num, var_0_7, var_0_9)

	arg_11_0:nodeByName("node_get_pos"):addChild(var_11_11)
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	local var_12_0 = 100

	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return var_12_0
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		if var_12_0 < arg_12_3 then
			return nil
		end

		local var_12_1 = arg_12_0.listView_:dequeueItem()

		if not var_12_1 then
			var_12_1 = arg_12_0.listView_:newItem()
		else
			var_12_1:removeAllChildren(true)
		end

		local var_12_2 = display.newNode()

		arg_12_0:initCell(var_12_2, arg_12_3)

		local var_12_3 = display.newNode()

		var_12_3:addChild(var_12_2)
		var_12_2:setPosition(0, 0)
		var_12_3:setContentSize(var_0_8, var_0_8 + 5)
		var_12_1:setItemSize(var_0_8 + 20, var_0_8 + 5)
		var_12_1:addContent(var_12_3)

		return var_12_1
	end
end

function var_0_0.addressDelegate(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	data = arg_13_0.types

	if cc.ui.UIListView.COUNT_TAG == arg_13_2 then
		return #data
	elseif cc.ui.UIListView.CELL_TAG == arg_13_2 then
		if arg_13_3 > #data then
			return nil
		end

		local var_13_0 = arg_13_0.addressListView_:dequeueItem()

		if not var_13_0 then
			var_13_0 = arg_13_0.addressListView_:newItem()
		else
			var_13_0:removeAllChildren(true)
		end

		local var_13_1 = data[arg_13_3]
		local var_13_2 = display.newNode()

		arg_13_0:initAddressCell(var_13_2, arg_13_3)

		local var_13_3 = display.newNode()

		var_13_3:addChild(var_13_2)
		var_13_2:setPosition(0, 0)

		local var_13_4 = var_13_2:getContentSize()

		var_13_3:setContentSize(var_13_2:getContentSize())
		var_13_0:setItemSize(var_13_4.width, var_13_4.height)
		var_13_0:addContent(var_13_3)

		return var_13_0
	end
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.startClick_ = true
		arg_14_0.prevY_ = arg_14_1.y
	elseif arg_14_1.name == "moved" and 20 <= math.abs(arg_14_1.y - arg_14_0.prevY_) then
		arg_14_0.startClick_ = false
	end
end

function var_0_0.initCell(arg_15_0, arg_15_1, arg_15_2)
	local var_15_0 = display.newNode()

	var_15_0:setContentSize(var_0_8, var_0_8)
	var_15_0:setTouchEnabled(true)
	var_15_0:setTouchSwallowEnabled(false)
	var_15_0:setAnchorPoint(cc.p(0, 0))
	var_15_0:setPosition(0, 0)

	if arg_15_2 <= #arg_15_0.datas then
		local var_15_1 = arg_15_0.datas[arg_15_2]

		xyd.setAvatarBorderWithLevelAndHpNewUI(var_15_1, var_15_0)
	else
		local var_15_2 = xyd.AssetLoader.get():loadSprite("windows/treasure/prepare/nil_box.png")

		var_15_2:setAnchorPoint(cc.p(0, 0))
		var_15_2:addTo(arg_15_1)
	end

	arg_15_1:addChild(var_15_0)
end

function var_0_0.initAddressCell(arg_16_0, arg_16_1, arg_16_2)
	local var_16_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/prepare/address_item.csb")
	local var_16_1 = var_16_0:getChildByName("btn")

	if arg_16_0.nowIndex == arg_16_2 then
		arg_16_0.selectBtn = var_16_1

		arg_16_0.selectBtn:setBright(false)
		arg_16_0.selectBtn:setTouchEnabled(false)
	end

	local var_16_2 = arg_16_0.types[arg_16_2]

	var_16_1:getChildByName("txt"):setString(var_0_3:name(var_16_2))
	var_16_1:addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(var_16_1, arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended and arg_16_0.nowIndex ~= arg_16_2 then
			xyd.playButtonSound()

			if arg_16_0.selectBtn and not tolua.isnull(arg_16_0.selectBtn) then
				arg_16_0.selectBtn:setBright(true)
				arg_16_0.selectBtn:setTouchEnabled(true)
			end

			arg_16_0.selectBtn = var_16_1

			arg_16_0.selectBtn:setBright(false)
			arg_16_0.selectBtn:setTouchEnabled(false)

			arg_16_0.nowIndex = arg_16_2

			arg_16_0:updateTypeName()
		end
	end)

	local var_16_3 = var_16_1:getContentSize()

	arg_16_1:setContentSize(var_16_3.width, var_16_3.height + 10)
	arg_16_1:addChild(var_16_0)
end

function var_0_0.playGuide(arg_18_0)
	local var_18_0 = xyd.StoryData.get():getGuideID()

	if var_18_0 == xyd.GuideStoryType.GUIDE_TREASURE_ONE then
		local var_18_1 = arg_18_0:nodeByName("btn_add")

		if not var_18_1 or tolua.isnull(var_18_1) then
			return
		end

		local var_18_2 = var_18_1:getPositionX()
		local var_18_3 = var_18_1:getPositionY()
		local var_18_4 = var_18_1:getContentSize().width
		local var_18_5 = var_18_1:getContentSize().height
		local var_18_6 = display.newNode()
		local var_18_7 = cc.p(var_18_4 / 2, var_18_5 / 2)

		var_18_6:setPosition(var_18_7)
		var_18_6:addTo(var_18_1)

		local var_18_8 = import("app.windows.GuideHand").new()

		var_18_6:addChild(var_18_8)
		var_18_8:setPosition(0, 0)

		local var_18_9 = xyd.tables.guide:desc(var_18_0)

		var_18_8:setText(var_18_9, cc.p(0, 0))

		arg_18_0.guideHand = var_18_6

		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_TREASURE_END, true)
		xyd.StoryData.get():persist()
	end
end

return var_0_0
