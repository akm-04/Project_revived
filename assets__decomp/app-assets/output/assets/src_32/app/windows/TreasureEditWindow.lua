local var_0_0 = class("TreasureEditWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.treasureLocation
local var_0_3 = xyd.tables.treasureType
local var_0_4 = xyd.tables.treasureSkill
local var_0_5 = xyd.tables.hero
local var_0_6 = import("app.model.Hero")
local var_0_7 = 3
local var_0_8 = cc.c4b(27, 151, 45, 255)
local var_0_9 = 45
local var_0_10 = xyd.tables.misc

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.locationId = arg_1_2.locationId
	arg_1_0.typeId = arg_1_2.typeId
	arg_1_0.startClick_ = true

	arg_1_0:sortHeroDatas()

	arg_1_0.nowHeroId = arg_1_0.datas[1].tableID_
	arg_1_0.nowHeroSkin = arg_1_0.datas[1].isSkinOn_
	arg_1_0.nowHeroSkinId = arg_1_0.datas[1].skinId_
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.sortHeroDatas(arg_3_0)
	arg_3_0.datas = {}

	local var_3_0 = {}
	local var_3_1 = {}

	for iter_3_0, iter_3_1 in pairs(var_0_5:getTreasureHeros(arg_3_0.locationId)) do
		local var_3_2 = arg_3_0.selfPlayer:getHeroIgnoreAwaken(iter_3_1)

		if var_3_2 then
			table.insert(var_3_0, var_3_2)

			if arg_3_0.treasureModel.MemeoryTeams and arg_3_0.treasureModel.MemeoryTeams[arg_3_0.locationId] then
				for iter_3_2, iter_3_3 in pairs(arg_3_0.treasureModel.MemeoryTeams[arg_3_0.locationId]) do
					if iter_3_3 == var_3_2:getHeroID() then
						var_3_2.isSelected = true

						break
					end
				end
			end
		else
			local var_3_3 = {
				tableID_ = iter_3_1
			}

			var_3_3.isNone = true

			table.insert(var_3_1, var_3_3)
		end
	end

	table.sort(var_3_0, function(arg_4_0, arg_4_1)
		return arg_4_0.level_ > arg_4_1.level_
	end)

	arg_3_0.datas = var_3_0

	for iter_3_4, iter_3_5 in pairs(var_3_1) do
		table.insert(arg_3_0.datas, iter_3_5)
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_name"):enableOutline(cc.c4b(95, 105, 161, 255))
	arg_5_0:nodeByName("txt_title"):setString(var_0_1:translation("TREASURE_SELECT_TITLE"))
	arg_5_0:nodeByName("txt_choose"):setString(var_0_1:translation("TREASURE_SELECT_TITLE"))
	arg_5_0:nodeByName("txt_increase"):setString(var_0_1:translation("TREASURE_SELECT_DES_1"))
	arg_5_0:nodeByName("txt_reward"):setString(var_0_1:translation("TREASURE_SELECT_DES_2"))
	arg_5_0:updateSelectHero()
	arg_5_0:updateHeros()
	arg_5_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_5_0:nodeByName("btn_ok"), arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {}

			for iter_6_0, iter_6_1 in pairs(arg_5_0.datas) do
				if iter_6_1.isSelected then
					table.insert(var_6_0, iter_6_1:getHeroID())
				end
			end

			arg_5_0.treasureModel:savedMemoryTeams(arg_5_0.locationId, var_6_0)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.TREASURE_SAVE_HEROS
			})
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)

	arg_5_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_5_0:nodeByName("list"):getWidth(), arg_5_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_5_0:nodeByName("list")):onScroll(handler(arg_5_0, arg_5_0.scrollListener))

	arg_5_0.listView_:setBounceable(true)
	arg_5_0.listView_:setDelegate(handler(arg_5_0, arg_5_0.delegate))
	arg_5_0.listView_:reload()
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayer()
	var_0_0.super:didOpen(arg_7_1)
end

function var_0_0.updateHeros(arg_8_0)
	local var_8_0 = 0
	local var_8_1 = {
		0,
		0,
		0,
		0
	}
	local var_8_2 = {}
	local var_8_3 = 0

	for iter_8_0, iter_8_1 in pairs(arg_8_0.datas) do
		if iter_8_1.isSelected then
			var_8_0 = var_8_0 + 1

			table.insert(var_8_2, iter_8_1)

			local var_8_4 = var_0_5:treasureSkill(iter_8_1.tableID_)

			if var_8_4 ~= 0 then
				var_8_1[var_8_4] = var_8_1[var_8_4] + var_0_4:num(var_8_4)
			end

			var_8_3 = var_8_3 + var_0_10.treasureColorParam * iter_8_1:getColor()
			var_8_3 = var_8_3 + var_0_10.treasureStarParam * iter_8_1:getStar()
			var_8_3 = var_8_3 + var_0_10.treasureLevelParam * iter_8_1:getLevel()
		end
	end

	local var_8_5 = 1

	for iter_8_2 = 1, 4 do
		if var_8_1[iter_8_2] ~= 0 then
			local var_8_6 = string.format(var_0_4:desc(iter_8_2), var_8_1[iter_8_2])

			arg_8_0:nodeByName("txt_increase_desc_" .. var_8_5):setString(var_8_6)

			var_8_5 = var_8_5 + 1
		end
	end

	for iter_8_3 = 4, var_8_5, -1 do
		arg_8_0:nodeByName("txt_increase_desc_" .. iter_8_3):setString("")
	end

	arg_8_0:nodeByName("node_reward"):removeAllChildren()

	if arg_8_0.treasureModel.teams[arg_8_0.locationId].with_external_award == 1 then
		local var_8_7 = arg_8_0.treasureModel.teams[arg_8_0.locationId].externa_crystal_award
		local var_8_8 = xyd.setItemWithTextNode(-1, var_8_7, var_0_8, var_0_9)

		arg_8_0:nodeByName("node_reward"):addChild(var_8_8)
		var_8_8:setPositionX(var_0_9 * 4.5)
	end

	local var_8_9 = xyd.tables.vip:tresureReward(arg_8_0.selfPlayer.vip)
	local var_8_10 = math.floor(var_8_9 * (var_0_10.treasureGoldParam1 + var_0_10.treasureGoldParam2 * var_8_0 + var_8_3))
	local var_8_11 = xyd.getTreasureItem(var_0_3:productType(arg_8_0.typeId), var_8_10)

	if arg_8_0.activities:isOpenDoubleTreasureAward() then
		var_8_11.item_num = var_8_11.item_num * 2
	end

	if var_8_0 == 0 then
		var_8_11.item_num = 0
	end

	local var_8_12 = xyd.setItemWithTextNode(var_8_11.item_id, var_8_11.item_num, var_0_8, var_0_9)

	arg_8_0:nodeByName("node_reward"):addChild(var_8_12)

	local var_8_13 = var_0_2:maxMember(arg_8_0.locationId)

	arg_8_0:nodeByName("txt_hero_num"):setString(var_8_0 .. " / " .. var_8_13)
end

function var_0_0.delegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return math.ceil(#arg_9_0.datas / var_0_7)
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		return arg_9_0:updateListView(arg_9_2, arg_9_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.updateHeroModel(arg_10_0, arg_10_1, arg_10_2)
	if arg_10_2 and not tolua.isnull(arg_10_2) then
		local var_10_0 = arg_10_1:getHeroModel()

		var_10_0:setTouchSwallowEnabled(false)
		arg_10_2:removeAllChildren()
		var_10_0:setScale(0.7)
		var_10_0:setName("model")
		var_10_0:addTo(arg_10_2)
	end
end

function var_0_0.updateListView(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0
	local var_11_1 = arg_11_0.listView_:dequeueItem()

	if not var_11_1 then
		var_11_1 = arg_11_0.listView_:newItem()
	else
		var_11_1:removeAllChildren(true)
	end

	local var_11_2 = 0
	local var_11_3 = 0
	local var_11_4 = display.newNode()
	local var_11_5 = arg_11_2 + math.ceil(#arg_11_0.datas / var_0_7)
	local var_11_6 = 0

	for iter_11_0 = var_0_7 - 1, 0, -1 do
		local var_11_7 = arg_11_2 * var_0_7 - iter_11_0

		if var_11_7 <= #arg_11_0.datas and var_11_7 > 0 then
			local var_11_8 = display.newNode()

			arg_11_0:initCell(var_11_8, arg_11_0.datas[var_11_7])

			var_11_2 = var_11_8:getContentSize().height

			local var_11_9 = var_11_8:getContentSize().width

			var_11_4:addChild(var_11_8)
			var_11_8:setPosition(var_11_6 * var_11_9, 0)

			var_11_6 = var_11_6 + 1
		end
	end

	var_11_1:setItemSize(arg_11_0:nodeByName("list"):getWidth(), var_11_2)
	var_11_4:setContentSize(arg_11_0:nodeByName("list"):getWidth(), var_11_2)
	var_11_1:addContent(var_11_4)

	return var_11_1
end

function var_0_0.scrollListener(arg_12_0, arg_12_1)
	arg_12_0.originY = arg_12_0.listView_.scrollNode:getPositionY()

	if arg_12_1.name == "began" then
		arg_12_0.startClick_ = true
		arg_12_0.prevY_ = arg_12_1.y
	elseif arg_12_1.name == "moved" and 20 <= math.abs(arg_12_1.y - arg_12_0.prevY_) then
		arg_12_0.startClick_ = false
	end
end

function var_0_0.updateSelectHero(arg_13_0)
	local var_13_0 = var_0_5:name(arg_13_0.nowHeroId)
	local var_13_1 = var_0_5:treasureDesc(arg_13_0.nowHeroId)
	local var_13_2 = var_0_5:treasureSkill(arg_13_0.nowHeroId)
	local var_13_3 = ""

	if var_13_2 ~= 0 then
		var_13_3 = string.format(var_0_4:desc(var_13_2), var_0_4:num(var_13_2))
	end

	arg_13_0:nodeByName("txt_increase_desc"):setString(var_13_3)
	arg_13_0:nodeByName("txt_name"):setString(var_13_0)
	arg_13_0:nodeByName("txt_desc"):setString(var_13_1)

	local var_13_4 = var_0_6.new()

	var_13_4:populateWithTableID(arg_13_0.nowHeroId)

	var_13_4.isSkinOn_ = arg_13_0.nowHeroSkin
	var_13_4.skinId_ = arg_13_0.nowHeroSkinId

	arg_13_0:updateHeroModel(var_13_4, arg_13_0:nodeByName("node_hero"))
end

function var_0_0.initCell(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/edit_team/select_item.csb")
	local var_14_1 = var_14_0:getChildByName("container")
	local var_14_2 = var_14_1:getContentSize()

	local function var_14_3()
		if arg_14_2.isNone ~= true then
			if arg_14_2.isSelected then
				var_14_1:getChildByName("select"):setVisible(false)

				arg_14_2.isSelected = false
			else
				var_14_1:getChildByName("select"):setVisible(true)

				arg_14_2.isSelected = true
			end

			arg_14_0:updateHeros()
		end

		if arg_14_0.nowHeroId == arg_14_2.tableID_ then
			return false
		end

		arg_14_0.nowHeroId = arg_14_2.tableID_
		arg_14_0.nowHeroSkin = arg_14_2.isSkinOn_
		arg_14_0.nowHeroSkinId = arg_14_2.skinId_

		if not tolua.isnull(arg_14_0.nowSelect) then
			arg_14_0.nowSelect:setVisible(false)
		end

		var_14_1:getChildByName("selected"):setVisible(true)

		arg_14_0.nowSelect = var_14_1:getChildByName("selected")

		arg_14_0:updateSelectHero()
	end

	var_14_0:setContentSize(var_14_2)
	arg_14_1:setContentSize(var_14_2)
	var_14_0:setName("layout")
	var_14_0:setPosition(cc.p(0, 0))

	if arg_14_0.nowHeroId ~= arg_14_2.tableID_ then
		var_14_1:getChildByName("selected"):setVisible(false)
	else
		arg_14_0.nowSelect = var_14_1:getChildByName("selected")

		arg_14_0.nowSelect:setVisible(true)
	end

	local var_14_4 = var_14_1:getChildByName("item_bg")
	local var_14_5 = display.newNode()

	var_14_5:setContentSize(var_14_4:getWidth(), var_14_4:getHeight())
	var_14_5:setTouchEnabled(true)
	var_14_5:setTouchSwallowEnabled(false)
	var_14_5:setAnchorPoint(cc.p(0, 0))
	var_14_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_16_0)
		if arg_16_0.name == "began" then
			return true
		elseif arg_16_0.name == "ended" then
			if arg_14_0.startClick_ then
				var_14_3()
			end
		elseif arg_16_0.name == "moved" then
			return true
		end
	end)
	var_14_4:addChild(var_14_5)
	var_14_5:setPosition(0, 0)

	if arg_14_2.isSelected then
		var_14_1:getChildByName("select"):setVisible(true)
	else
		var_14_1:getChildByName("select"):setVisible(false)
	end

	if arg_14_2.isNone == true then
		xyd.setAvatarBorderNewUI(arg_14_2.tableID_, var_14_1:getChildByName("icon"), 1, 0)
	else
		local var_14_6 = var_14_1:getChildByName("icon")
		local var_14_7 = display.newNode()

		var_14_7:setContentSize(var_14_6:getWidth(), var_14_6:getHeight())
		var_14_7:setTouchEnabled(true)
		var_14_7:setTouchSwallowEnabled(false)
		var_14_7:setAnchorPoint(cc.p(0, 0))
		var_14_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_17_0)
			if arg_17_0.name == "began" then
				return true
			elseif arg_17_0.name == "ended" then
				if arg_14_0.startClick_ then
					var_14_3()
				end
			elseif arg_17_0.name == "moved" then
				return true
			end
		end)
		var_14_6:addChild(var_14_7)
		var_14_7:setPosition(0, 0)
		var_14_1:getChildByName("shaddow"):setVisible(false)
		xyd.setAvatarBorderWithLevelAndHpNewUI(arg_14_2, var_14_1:getChildByName("icon"))
	end

	arg_14_1:addChild(var_14_0)
end

function var_0_0.willClose(arg_18_0, arg_18_1)
	var_0_0.super:willClose(arg_18_1)

	for iter_18_0, iter_18_1 in pairs(arg_18_0.datas) do
		if iter_18_1.isSelected then
			iter_18_1.isSelected = false
		end
	end
end

return var_0_0
