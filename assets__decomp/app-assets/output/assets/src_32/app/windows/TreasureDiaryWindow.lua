local var_0_0 = class("TreasureDiaryWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.treasureLocation
local var_0_3 = xyd.tables.treasureType
local var_0_4 = import("app.model.Hero")
local var_0_5 = import("app.common.ui.SplitLine")
local var_0_6 = 50
local var_0_7 = 80
local var_0_8 = {
	BATTLE_LOSE = 4,
	TITLE = 1,
	CHEST = 5,
	NORMAL = 2,
	BATTLE_WIN = 3
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.treasureModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TREASURE)
	arg_1_0.paramData = arg_1_2 or {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:sortDatas()
	arg_2_0:layout()
end

function var_0_0.sortDatas(arg_3_0)
	arg_3_0.datas = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.paramData) do
		local var_3_0 = {
			location = iter_3_1.team_id,
			treasureType = iter_3_1.treasure_type,
			type = var_0_8.TITLE
		}

		if not iter_3_1.award.normal_award then
			return
		end

		table.insert(arg_3_0.datas, var_3_0)

		local var_3_1 = {}
		local var_3_2 = {}
		local var_3_3 = {}

		var_3_2.items = var_3_3

		if iter_3_1.award.normal_award.award_time then
			var_3_2.awardTime = iter_3_1.award.normal_award.award_time
			var_3_1.itemId = iter_3_1.award.normal_award.item_id
			var_3_1.itemNum = iter_3_1.award.normal_award.item_num
			var_3_1.items = iter_3_1.award.normal_award.items
			var_3_1.awardType = iter_3_1.award.normal_award.award_type
			var_3_2.type = var_0_8.NORMAL

			arg_3_0:makeNormalItem(var_3_1)
		end

		table.insert(var_3_3, var_3_1)

		if iter_3_1.award.externa_crystal_award and iter_3_1.award.externa_crystal_award > 0 then
			local var_3_4 = {}

			var_3_4.itemId = -1
			var_3_4.itemNum = iter_3_1.award.externa_crystal_award

			table.insert(var_3_3, var_3_4)
		end

		table.insert(arg_3_0.datas, var_3_2)

		local var_3_5 = {}

		if iter_3_1.award.chest_award.award_time then
			var_3_5.awardTime = iter_3_1.award.chest_award.award_time
			var_3_5.itemId = iter_3_1.award.chest_award.item_id
			var_3_5.itemNum = iter_3_1.award.chest_award.item_num
			var_3_5.type = var_0_8.CHEST
		end

		local var_3_6 = {}

		if iter_3_1.with_battle == 1 or iter_3_1.award.battle_award.award_time then
			var_3_6.awardTime = iter_3_1.award.battle_award.award_time or iter_3_1.time
			var_3_6.heros = iter_3_1.partners_info

			if iter_3_1.is_win == 0 then
				var_3_6.type = var_0_8.BATTLE_LOSE
			else
				var_3_6.type = var_0_8.BATTLE_WIN
				var_3_6.itemId = iter_3_1.award.battle_award.item_id
				var_3_6.itemNum = iter_3_1.award.battle_award.item_num
			end
		end

		if var_3_5.itemId and var_3_6.itemId then
			if var_3_5.awardTime > var_3_6.awardTime then
				table.insert(arg_3_0.datas, var_3_5)
				table.insert(arg_3_0.datas, var_3_6)
			else
				table.insert(arg_3_0.datas, var_3_6)
				table.insert(arg_3_0.datas, var_3_5)
			end

			table.insert(var_3_3, var_3_6)
			table.insert(var_3_3, var_3_5)
		elseif var_3_5.itemId then
			table.insert(arg_3_0.datas, var_3_5)
			table.insert(var_3_3, var_3_5)
		elseif var_3_6.itemId then
			table.insert(arg_3_0.datas, var_3_6)
			table.insert(var_3_3, var_3_6)
		elseif var_3_6.type == var_0_8.BATTLE_LOSE then
			table.insert(arg_3_0.datas, var_3_6)
		end
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("TREASURE_DIARY"))

	arg_4_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list"):getWidth(), arg_4_0:nodeByName("list"):getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.listView_:setBounceable(true)
	arg_4_0.listView_:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.listView_:reload()
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	arg_5_0:addBlockLayer()
	var_0_0.super:didOpen(arg_5_1)
end

function var_0_0.makeNormalItem(arg_6_0, arg_6_1)
	if arg_6_1.awardType == xyd.TreasureProductType.MANA then
		arg_6_1.itemId = -2
	elseif arg_6_1.awardType == xyd.TreasureProductType.DRINK then
		-- block empty
	elseif arg_6_1.awardType == xyd.TreasureProductType.STONE then
		arg_6_1.itemId = -4
		arg_6_1.itemNum = 0

		if arg_6_1.items then
			for iter_6_0, iter_6_1 in pairs(arg_6_1.items) do
				if iter_6_1.item_num then
					arg_6_1.itemNum = arg_6_1.itemNum + iter_6_1.item_num
				end
			end
		end
	elseif arg_6_1.awardType == xyd.TreasureProductType.DUST then
		arg_6_1.itemId = -11
	elseif arg_6_1.awardType == xyd.TreasureProductType.LIQUID then
		arg_6_1.itemId = -12
	end
end

function var_0_0.delegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return #arg_7_0.datas
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		if arg_7_3 > #arg_7_0.datas then
			return nil
		end

		local var_7_0 = arg_7_0.listView_:dequeueItem()

		if not var_7_0 then
			var_7_0 = arg_7_0.listView_:newItem()
		else
			var_7_0:removeAllChildren(true)
		end

		local var_7_1 = arg_7_0.datas[arg_7_3]
		local var_7_2 = display.newNode()

		arg_7_0:initCell(var_7_2, var_7_1)

		local var_7_3 = display.newNode()

		var_7_3:addChild(var_7_2)
		var_7_2:setPosition(0, 0)
		var_7_3:setContentSize(var_7_2:getContentSize())
		var_7_0:setItemSize(var_7_2:getContentSize().width, var_7_2:getContentSize().height + 10)
		var_7_0:addContent(var_7_3)

		return var_7_0
	end
end

function var_0_0.scrollListener(arg_8_0, arg_8_1)
	if arg_8_1.name == "began" then
		arg_8_0.startClick_ = true
		arg_8_0.prevY_ = arg_8_1.y
	elseif arg_8_1.name == "moved" and 20 <= math.abs(arg_8_1.y - arg_8_0.prevY_) then
		arg_8_0.startClick_ = false
	end
end

function var_0_0.initCell(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0

	if arg_9_2.type == var_0_8.TITLE then
		var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/diary/title_item.csb")
	elseif arg_9_2.type == var_0_8.BATTLE_WIN then
		var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/diary/diary_item2.csb")
	else
		var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/treasure/diary/diary_item.csb")
	end

	local var_9_1 = var_9_0:getChildByName("container")

	if arg_9_2.type ~= var_0_8.TITLE then
		local var_9_2 = {
			size = 700,
			offset = 9,
			align = xyd.SplitLineAlign.CENTER
		}
		local var_9_3 = var_0_5.new(var_9_2)

		var_9_3:addTo(var_9_0:getChildByName("container"))
		var_9_3:setPosition(var_9_1:getWidth() / 2, 0)
	end

	local var_9_4 = var_9_1:getContentSize()

	if arg_9_2.type == var_0_8.TITLE then
		var_9_1:getChildByName("txt_title"):setString(var_0_2:name(arg_9_2.location) .. " " .. var_0_3:name(arg_9_2.treasureType))
	else
		var_9_1:getChildByName("txt_time"):setString(arg_9_0:getTimeDes(arg_9_2.awardTime))

		local var_9_5 = var_9_1:getChildByName("enemy_container")
		local var_9_6 = ""
		local var_9_7
		local var_9_8

		if arg_9_2.type == var_0_8.BATTLE_LOSE then
			var_9_6 = var_0_1:translation("TREASURE_LOSE")

			var_9_5:getChildByName("txt_enemy"):setString(var_0_1:translation("TREASURE_ENEMY"))

			var_9_7 = var_9_5:getChildByName("icons_pos")
		elseif arg_9_2.type == var_0_8.BATTLE_WIN then
			var_9_6 = var_0_1:translation("TREASURE_WIN")

			var_9_5:getChildByName("txt_enemy"):setString(var_0_1:translation("TREASURE_ENEMY"))

			local var_9_9 = var_9_1:getChildByName("reward_container")

			var_9_9:getChildByName("txt_reward"):setString(var_0_1:translation("TREASURE_BOX"))

			var_9_7 = var_9_5:getChildByName("icons_pos")
			var_9_8 = var_9_9:getChildByName("item_pos")
		elseif arg_9_2.type == var_0_8.NORMAL then
			var_9_6 = var_0_1:translation("TREASURE_FINISH")

			var_9_5:getChildByName("txt_enemy"):setString(var_0_1:translation("TREASURE_BOX"))

			var_9_8 = var_9_5:getChildByName("icons_pos")
		elseif arg_9_2.type == var_0_8.CHEST then
			var_9_6 = var_0_1:translation("TREASURE_GET_CHEST")

			var_9_5:getChildByName("txt_enemy"):setString(var_0_1:translation("TREASURE_BOX"))

			var_9_8 = var_9_5:getChildByName("icons_pos")
		end

		var_9_1:getChildByName("txt_desc"):setString(var_9_6)

		if var_9_7 and arg_9_2.heros then
			for iter_9_0, iter_9_1 in pairs(arg_9_2.heros) do
				local var_9_10 = var_0_4.new()

				if xyd.tables.hero:getRowTable(iter_9_1.table_id) then
					var_9_10:populate(iter_9_1)

					local var_9_11 = cc.Node:create()

					var_9_11:setContentSize(var_0_7, var_0_7)
					var_9_11:setAnchorPoint(cc.p(0, 0.5))
					xyd.setAvatarBorder(iter_9_1.table_id, var_9_11, iter_9_1.color, iter_9_1.star)
					var_9_7:addChild(var_9_11)
					var_9_11:setPositionX((iter_9_0 - 1) * var_0_7 * 6 / 5)
				end
			end
		end

		if var_9_8 then
			if arg_9_2.itemId then
				local var_9_12 = arg_9_2.itemId < 0 and var_0_6 or var_0_7
				local var_9_13 = xyd.setItemWithTextNode(arg_9_2.itemId, arg_9_2.itemNum, cc.c4b(255, 119, 0, 255), var_9_12, nil, 24)

				var_9_13:setAnchorPoint(cc.p(0, 0.5))
				var_9_8:addChild(var_9_13)
			else
				local var_9_14 = 0

				for iter_9_2, iter_9_3 in pairs(arg_9_2.items) do
					local var_9_15 = iter_9_3.itemId < 0 and var_0_6 or var_0_7
					local var_9_16 = xyd.setItemWithTextNode(iter_9_3.itemId, iter_9_3.itemNum, cc.c4b(255, 119, 0, 255), var_9_15, nil, 24)

					var_9_16:setAnchorPoint(cc.p(0, 0.5))
					var_9_8:addChild(var_9_16)
					var_9_16:setPositionX(var_9_14)

					var_9_14 = var_9_14 + var_9_16:getWidth() - 15
				end
			end
		end
	end

	var_9_0:setContentSize(var_9_4)
	arg_9_1:setContentSize(var_9_4)
	var_9_0:setName("layout")
	var_9_0:setPosition(cc.p(0, 0))
	arg_9_1:addChild(var_9_0)
end

function var_0_0.getTimeDes(arg_10_0, arg_10_1)
	local var_10_0 = ""
	local var_10_1 = xyd.ServerTime.get():getServerTime()
	local var_10_2 = os.date("%M", var_10_1)
	local var_10_3 = os.date("%H", var_10_1)
	local var_10_4 = os.date("%S", var_10_1)
	local var_10_5 = var_10_1 - var_10_2 * 60 - var_10_3 * 3600 - var_10_4
	local var_10_6 = os.date("%M", arg_10_1)
	local var_10_7 = os.date("%H", arg_10_1)
	local var_10_8 = os.date("%S", arg_10_1)
	local var_10_9 = var_10_5 - arg_10_1

	if var_10_9 <= 0 then
		var_10_0 = var_0_1:translation("TODAY") .. var_10_7 .. ":" .. var_10_6
	elseif var_10_9 <= 86400 then
		var_10_0 = var_0_1:translation("YESTERDAY") .. var_10_7 .. ":" .. var_10_6
	elseif var_10_9 <= 172800 then
		var_10_0 = var_0_1:translation("THE_DAY_BEFORE_YESTERDAY") .. var_10_7 .. ":" .. var_10_6
	else
		var_10_0 = string.format(var_0_1:translation("DAYS_AGO"), math.ceil(var_10_9 / 86400))
	end

	return var_10_0
end

return var_0_0
