local var_0_0 = class("TeamTeaTalkQuestWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 1
local var_0_4 = 2
local var_0_5 = 6
local var_0_6 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.listView_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list")):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0:initDatas()
	arg_2_0.listView_:setDelegate(handler(arg_2_0, arg_2_0.delegate))
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.listView_:reload()
	arg_3_0:nodeByName("title"):setString(var_0_2:translation("SHE_TUAN_TEXT_32"))
end

function var_0_0.didOpen(arg_4_0, arg_4_1)
	var_0_0.super:didOpen(arg_4_1)

	arg_4_0.dispatcher = xyd.EventDispatcher.get():addEventListener(xyd.event.FRESH_STONE_QUEST, function(arg_5_0)
		arg_4_0.listView_:reload()
	end)

	arg_4_0:addBlockLayer()
end

function var_0_0.initDatas(arg_6_0)
	arg_6_0.listData = {}

	local var_6_0 = {}
	local var_6_1 = {}
	local var_6_2 = {}
	local var_6_3 = {}
	local var_6_4 = 0
	local var_6_5 = 0
	local var_6_6 = 0
	local var_6_7 = 0
	local var_6_8 = {}

	for iter_6_0, iter_6_1 in pairs(arg_6_0.selfPlayer.heros_) do
		if xyd.tables.hero:canGuildRequest(iter_6_1:getTableID()) == 1 then
			var_6_8[iter_6_1:getTableID()] = iter_6_1
		end
	end

	for iter_6_2, iter_6_3 in pairs(xyd.tables.hero:getPartnerDistanceType()) do
		local var_6_9 = xyd.tables.hero:afterAwaken(iter_6_2)

		if var_6_9 > 0 and var_6_8[iter_6_2] == nil and var_6_8[var_6_9] == nil then
			local var_6_10 = var_0_6.new()

			var_6_10:initUnCollected(iter_6_2)

			if var_6_10:getSuiPian() > 0 and xyd.tables.hero:canGuildRequest(var_6_10:getTableID()) == 1 then
				var_6_8[iter_6_2] = var_6_10
				var_6_10.unCollected = true
			end
		end
	end

	for iter_6_4, iter_6_5 in pairs(var_6_8) do
		if xyd.tables.hero:isSX(iter_6_4) then
			if xyd.tables.hero:guildRequestCrossService(iter_6_4) == 0 then
				table.insert(var_6_1, iter_6_5)

				var_6_5 = var_6_5 + 1
			else
				table.insert(var_6_3, iter_6_5)

				var_6_7 = var_6_7 + 1
			end
		elseif xyd.tables.hero:guildRequestCrossService(iter_6_4) == 0 then
			table.insert(var_6_0, iter_6_5)

			var_6_4 = var_6_4 + 1
		else
			table.insert(var_6_2, iter_6_5)

			var_6_6 = var_6_6 + 1
		end
	end

	table.sort(var_6_0, function(arg_7_0, arg_7_1)
		if arg_7_0.unCollected and arg_7_1.unCollected then
			return arg_7_0:getSuiPian() > arg_7_1:getSuiPian()
		end

		if arg_7_0.unCollected then
			return false
		end

		if arg_7_1.unCollected then
			return true
		end

		if arg_7_0.star_ == arg_7_1.star_ then
			return arg_7_0:getSuiPian() > arg_7_1:getSuiPian()
		end

		return arg_7_0.star_ < arg_7_1.star_
	end)
	table.sort(var_6_1, function(arg_8_0, arg_8_1)
		if arg_8_0.unCollected and arg_8_1.unCollected then
			return arg_8_0:getSuiPian() > arg_8_1:getSuiPian()
		end

		if arg_8_0.unCollected then
			return false
		end

		if arg_8_1.unCollected then
			return true
		end

		if arg_8_0.star_ == arg_8_1.star_ then
			return arg_8_0:getSuiPian() > arg_8_1:getSuiPian()
		end

		return arg_8_0.star_ < arg_8_1.star_
	end)
	table.sort(var_6_2, function(arg_9_0, arg_9_1)
		if arg_9_0.unCollected and arg_9_1.unCollected then
			return arg_9_0:getSuiPian() > arg_9_1:getSuiPian()
		end

		if arg_9_0.unCollected then
			return false
		end

		if arg_9_1.unCollected then
			return true
		end

		if arg_9_0.star_ == arg_9_1.star_ then
			return arg_9_0:getSuiPian() > arg_9_1:getSuiPian()
		end

		return arg_9_0.star_ < arg_9_1.star_
	end)
	table.sort(var_6_3, function(arg_10_0, arg_10_1)
		if arg_10_0.unCollected and arg_10_1.unCollected then
			return arg_10_0:getSuiPian() > arg_10_1:getSuiPian()
		end

		if arg_10_0.unCollected then
			return false
		end

		if arg_10_1.unCollected then
			return true
		end

		if arg_10_0.star_ == arg_10_1.star_ then
			return arg_10_0:getSuiPian() > arg_10_1:getSuiPian()
		end

		return arg_10_0.star_ < arg_10_1.star_
	end)

	if var_6_6 ~= 0 then
		local var_6_11 = {
			type = var_0_3,
			str = string.format(var_0_2:translation("ASK_STONE_TITLE"), xyd.tables.misc.guildNormalScrollRequestNum)
		}

		table.insert(arg_6_0.listData, var_6_11)

		local var_6_12 = {}
		local var_6_13 = 0
		local var_6_14 = 0

		for iter_6_6, iter_6_7 in pairs(var_6_2) do
			var_6_13 = var_6_13 + 1
			var_6_14 = var_6_14 + 1

			table.insert(var_6_12, iter_6_7)

			if var_6_13 == var_0_5 or var_6_14 == var_6_6 then
				local var_6_15 = {
					row = var_6_12,
					type = var_0_4
				}

				table.insert(arg_6_0.listData, var_6_15)

				var_6_13 = 0
				var_6_12 = {}
			end
		end
	end

	local var_6_16 = {
		type = var_0_3,
		str = string.format(var_0_2:translation("ASK_STONE_TITLE1"), xyd.tables.misc.guildNormalScrollRequestNum)
	}

	table.insert(arg_6_0.listData, var_6_16)

	local var_6_17 = {}
	local var_6_18 = 0
	local var_6_19 = 0

	for iter_6_8, iter_6_9 in pairs(var_6_0) do
		var_6_18 = var_6_18 + 1
		var_6_19 = var_6_19 + 1

		table.insert(var_6_17, iter_6_9)

		if var_6_18 == var_0_5 or var_6_19 == var_6_4 then
			local var_6_20 = {
				row = var_6_17,
				type = var_0_4
			}

			table.insert(arg_6_0.listData, var_6_20)

			var_6_18 = 0
			var_6_17 = {}
		end
	end

	if var_6_7 ~= 0 then
		local var_6_21 = {
			type = var_0_3,
			str = string.format(var_0_2:translation("ASK_STONE_TITLE"), xyd.tables.misc.guildSXScrollRequestNum)
		}

		table.insert(arg_6_0.listData, var_6_21)

		local var_6_22 = {}
		local var_6_23 = 0
		local var_6_24 = 0

		for iter_6_10, iter_6_11 in pairs(var_6_3) do
			var_6_23 = var_6_23 + 1
			var_6_24 = var_6_24 + 1

			table.insert(var_6_22, iter_6_11)

			if var_6_23 == var_0_5 or var_6_24 == var_6_7 then
				local var_6_25 = {
					row = var_6_22,
					type = var_0_4
				}

				table.insert(arg_6_0.listData, var_6_25)

				var_6_23 = 0
				var_6_22 = {}
			end
		end
	end

	if var_6_5 ~= 0 then
		local var_6_26 = {
			type = var_0_3,
			str = string.format(var_0_2:translation("ASK_STONE_TITLE1"), xyd.tables.misc.guildSXScrollRequestNum)
		}

		table.insert(arg_6_0.listData, var_6_26)

		local var_6_27 = {}
		local var_6_28 = 0
		local var_6_29 = 0

		for iter_6_12, iter_6_13 in pairs(var_6_1) do
			var_6_28 = var_6_28 + 1
			var_6_29 = var_6_29 + 1

			table.insert(var_6_27, iter_6_13)

			if var_6_28 == var_0_5 or var_6_29 == var_6_5 then
				local var_6_30 = {
					row = var_6_27,
					type = var_0_4
				}

				table.insert(arg_6_0.listData, var_6_30)

				var_6_28 = 0
				var_6_27 = {}
			end
		end
	end
end

function var_0_0.scrollListener(arg_11_0, arg_11_1)
	if arg_11_1.name == "began" then
		arg_11_0.scrollViewMoved_ = false
		arg_11_0.prevY_ = arg_11_1.y
	elseif arg_11_1.name == "moved" and 10 <= math.abs(arg_11_1.y - arg_11_0.prevY_) then
		arg_11_0.scrollViewMoved_ = true
	end
end

function var_0_0.delegate(arg_12_0, arg_12_1, arg_12_2, arg_12_3)
	if cc.ui.UIListView.COUNT_TAG == arg_12_2 then
		return #arg_12_0.listData
	elseif cc.ui.UIListView.CELL_TAG == arg_12_2 then
		return arg_12_0:updateListView(arg_12_2, arg_12_3)
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_12_2 then
		-- block empty
	end
end

function var_0_0.updateListView(arg_13_0, arg_13_1, arg_13_2)
	local var_13_0
	local var_13_1 = arg_13_0.listView_:dequeueItem()

	if not var_13_1 then
		var_13_1 = arg_13_0.listView_:newItem()
	else
		var_13_1:removeAllChildren(true)
	end

	local var_13_2 = display.newNode()

	if not arg_13_0.listData[arg_13_2] then
		return
	end

	if arg_13_0.listData[arg_13_2].type == var_0_3 then
		local var_13_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_tea_talk/quest_item.csb")
		local var_13_4 = var_13_3:getChildByName("container")
		local var_13_5 = var_13_4:getChildByName("text")
		local var_13_6 = var_13_4:getContentSize()

		var_13_3:setContentSize(var_13_6)
		var_13_2:setContentSize(var_13_6)
		var_13_1:setItemSize(var_13_6.width, var_13_6.height + 10)
		var_13_2:addChild(var_13_3)
		var_13_5:setString(arg_13_0.listData[arg_13_2].str)
		var_13_4:getChildByName("star_1"):setPositionX(var_13_5:getPositionX() - var_13_5:getWidth() / 2 - 70)
		var_13_4:getChildByName("star_2"):setPositionX(var_13_5:getPositionX() + var_13_5:getWidth() / 2 + 70)
	elseif arg_13_0.listData[arg_13_2].row then
		local var_13_7 = arg_13_0:nodeByName("list"):getWidth()
		local var_13_8 = 0

		for iter_13_0, iter_13_1 in pairs(arg_13_0.listData[arg_13_2].row) do
			local var_13_9 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/team_tea_talk/quest_avatar.csb")
			local var_13_10 = var_13_9:getChildByName("container")
			local var_13_11 = var_13_10:getChildByName("avatar_icon")
			local var_13_12 = var_13_10:getChildByName("own_num_text")
			local var_13_13 = var_13_10:getContentSize()

			var_13_8 = var_13_13.height

			var_13_9:setContentSize(var_13_13)
			var_13_2:addChild(var_13_9)
			var_13_9:setPosition(5 + (var_13_13.width + 30) * (iter_13_0 - 1), 0)

			local var_13_14 = display.newNode()

			var_13_14:setContentSize(var_13_11:getContentSize())
			var_13_14:setTouchEnabled(true)
			var_13_14:setTouchSwallowEnabled(false)
			var_13_14:setAnchorPoint(cc.p(0.5, 0.5))
			var_13_14:setPosition(var_13_11:getWidth() / 2, var_13_11:getHeight() / 2)
			var_13_14:addTo(var_13_11)
			var_13_14:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
				if arg_14_0.name == "began" then
					var_13_14:setScale(0.95)

					return true
				elseif arg_14_0.name == "ended" then
					var_13_14:setScale(1)

					if not arg_13_0.scrollViewMoved_ then
						local var_14_0 = {
							item_id = iter_13_1:getSuiPianID()
						}
						local var_14_1 = xyd.tables.item:name(var_14_0.item_id)
						local var_14_2 = string.format(var_0_2:translation("TEAM_TALK_REQUIRE"), var_14_1)

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_2, function()
							arg_13_0.guild:teaTalkRequest(var_14_0, function(arg_16_0)
								if arg_16_0 == xyd.error.OK then
									if arg_13_0.dispatcher then
										xyd.EventDispatcher.get():removeEventListener(arg_13_0.dispatcher)
									end

									xyd.EventDispatcher.get():dispatchEvent({
										name = xyd.event.FRESH_STONE_QUEST
									})
									xyd.WindowManager.get():closeWindow(arg_13_0)

									return true
								end
							end)
						end, nil, nil, arg_13_0.colorMode)
					end
				elseif arg_14_0.name == "moved" then
					var_13_14:setScale(1)

					return true
				end
			end)

			if iter_13_1.unCollected then
				xyd.setItemBorder(var_13_14, iter_13_1:getSuiPianID())
			else
				xyd.setAvatarBorderNewUI(iter_13_1, var_13_14)
			end

			var_13_12:setString(var_0_2:translation("ITEM_OWN") .. var_0_2:translation("COLON") .. iter_13_1:getSuiPian())
		end

		var_13_2:setContentSize(var_13_7, var_13_8 + 10)
		var_13_1:setItemSize(var_13_7, var_13_8 + 10)
	end

	var_13_1:addContent(var_13_2)

	return var_13_1
end

function var_0_0.didClose(arg_17_0, arg_17_1)
	var_0_0.super:didClose(arg_17_1)

	if arg_17_0.dispatcher then
		xyd.EventDispatcher.get():removeEventListener(arg_17_0.dispatcher)
	end
end

return var_0_0
