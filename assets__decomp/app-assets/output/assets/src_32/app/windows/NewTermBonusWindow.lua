local var_0_0 = class("NewTermBonusItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = 80
local var_0_4 = xyd.tables.hero
local var_0_5 = xyd.tables.newTermCharm
local var_0_6 = xyd.tables.newTermCollection
local var_0_7 = xyd.tables.newTermConnection
local var_0_8 = 1
local var_0_9 = 2
local var_0_10 = 3
local var_0_11 = 1
local var_0_12 = 2
local var_0_13 = 3

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.newTermModel = xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/new_term/bonus_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local function var_4_0(arg_5_0)
		if arg_5_0 == var_0_11 then
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):setBright(false)
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):setTouchEnabled(false)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setVisible(true)
			arg_4_0.contentView_:nodeByName("already_get"):setVisible(false)
			arg_4_0.contentView_:nodeByName("get_txt"):setVisible(false)
			arg_4_0.contentView_:nodeByName("get_gray"):setVisible(true)
			arg_4_0.contentView_:nodeByName("mask"):setVisible(false)
		elseif arg_5_0 == var_0_12 then
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):setVisible(true)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setVisible(true)
			arg_4_0.contentView_:nodeByName("already_get"):setVisible(false)
			arg_4_0.contentView_:nodeByName("mask"):setVisible(false)
			arg_4_0.contentView_:nodeByName("get_txt"):setVisible(true)
			arg_4_0.contentView_:nodeByName("get_gray"):setVisible(false)
		elseif arg_5_0 == var_0_13 then
			arg_4_0.contentView_:nodeByName("already_get"):setVisible(true)
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):setVisible(false)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setVisible(false)
			arg_4_0.contentView_:nodeByName("mask"):setVisible(true)
		end
	end

	arg_4_0.contentView_:nodeByName("bonus_request_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0.contentView_:nodeByName("get_txt"):setString(var_0_1:translation("OBTAIN"))
	arg_4_0.contentView_:nodeByName("get_gray"):setString(var_0_1:translation("OBTAIN"))

	local function var_4_1(arg_6_0, arg_6_1)
		xyd.addGiftTips(arg_6_0, {
			gift_id = arg_6_1
		})
	end

	arg_4_0.contentView_:nodeByName("item_icon"):setContentSize(var_0_3, var_0_3)
	arg_4_0.contentView_:nodeByName("item_icon"):setAnchorPoint(0.5, 0.5)

	if arg_4_1.mode == var_0_8 then
		local var_4_2 = arg_4_0.newTermModel.charm

		arg_4_0.contentView_:nodeByName("item_name"):setString(var_0_5:giftName(arg_4_1.id))
		arg_4_0.contentView_:nodeByName("item_desc"):setString(var_0_5:giftText(arg_4_1.id))
		xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item_icon"), xyd.tables.misc.newTermCharmBonusIcon)

		local var_4_3 = var_0_5:charmGift(arg_4_1.id)

		var_4_1(arg_4_0.contentView_:nodeByName("item_icon"), var_4_3)

		if var_4_2 >= arg_4_1.condition then
			var_4_0(var_0_12)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(string.format(var_0_1:translation("LIANYI_TEXT17"), arg_4_1.condition))
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
				if arg_7_1 == ccui.TouchEventType.ended then
					local var_7_0 = {
						award_id = arg_4_1.id,
						activity_id = xyd.Activities.NewTerms,
						sub_award_id = 3 - var_0_8
					}

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_7_0, function(arg_8_0, arg_8_1)
						arg_4_0.newTermModel.baseInfo.charm_awards[arg_4_1.id] = 1

						arg_4_0:updateInfo(arg_8_1)
						var_4_0(var_0_13)
						arg_4_0.selfPlayer:handleRewards(arg_8_1.awards)
					end)
				end
			end)

			if arg_4_0.newTermModel.baseInfo.charm_awards[arg_4_1.id] ~= 0 then
				var_4_0(var_0_13)
			end
		else
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(string.format(var_0_1:translation("LIANYI_TEXT17"), arg_4_1.condition))
			var_4_0(var_0_11)
		end
	elseif arg_4_1.mode == var_0_9 then
		local var_4_4 = arg_4_0.newTermModel.connection

		arg_4_0.contentView_:nodeByName("item_name"):setString(var_0_7:giftName(arg_4_1.id))
		arg_4_0.contentView_:nodeByName("item_desc"):setString(var_0_7:giftText(arg_4_1.id))
		xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item_icon"), xyd.tables.misc.newTermConnectionBonusIcon)

		local var_4_5 = var_0_7:connectionGift(arg_4_1.id)

		var_4_1(arg_4_0.contentView_:nodeByName("item_icon"), var_4_5)

		if var_4_4 >= arg_4_1.condition then
			var_4_0(var_0_12)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(string.format(var_0_1:translation("LIANYI_TEXT18"), arg_4_1.condition))
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
				if arg_9_1 == ccui.TouchEventType.ended then
					local var_9_0 = {
						award_id = arg_4_1.id,
						activity_id = xyd.Activities.NewTerms,
						sub_award_id = 3 - var_0_9
					}

					xyd.Backend.get():request(xyd.mid.GET_ACTIVITY_REWARD, var_9_0, function(arg_10_0, arg_10_1)
						arg_4_0.newTermModel.baseInfo.connection_awards[arg_4_1.id] = 1

						arg_4_0:updateInfo(arg_10_1)
						var_4_0(var_0_13)
						arg_4_0.selfPlayer:handleRewards(arg_10_1.awards)
					end)
				end
			end)

			if arg_4_0.newTermModel.baseInfo.connection_awards[arg_4_1.id] ~= 0 then
				var_4_0(var_0_13)
			end
		else
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(string.format(var_0_1:translation("LIANYI_TEXT18"), arg_4_1.condition))
			var_4_0(var_0_11)
		end
	else
		arg_4_0.contentView_:nodeByName("item_name"):setString(var_0_6:name(arg_4_1.id))
		arg_4_0.contentView_:nodeByName("item_desc"):setString(var_0_6:text(arg_4_1.id))
		xyd.setItemBorder(arg_4_0.contentView_:nodeByName("item_icon"), arg_4_1.id)

		local var_4_6 = var_0_6:collectionGift(arg_4_1.id)

		var_4_1(arg_4_0.contentView_:nodeByName("item_icon"), var_4_6)

		if xyd.isInTable(arg_4_0.newTermModel.collectionItems, tostring(arg_4_1.id)) or arg_4_1.isLast and arg_4_1.isAllCollected then
			var_4_0(var_0_12)
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(var_0_1:translation("LIANYI_TEXT26"))
			arg_4_0.contentView_:nodeByName("get_bonus_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
				if arg_11_1 == ccui.TouchEventType.ended then
					local var_11_0 = {
						item_id = arg_4_1.id
					}

					arg_4_0.newTermModel:getPresent(var_11_0, function(arg_12_0, arg_12_1)
						table.insert(arg_4_0.newTermModel.gotItems, tostring(arg_4_1.id))
						var_4_0(var_0_13)
						arg_4_0.selfPlayer:handleRewards(arg_12_1.awards)
					end)
				end
			end)

			if xyd.isInTable(arg_4_0.newTermModel.gotItems, tostring(arg_4_1.id)) then
				var_4_0(var_0_13)
			end
		else
			arg_4_0.contentView_:nodeByName("bonus_request_txt"):setString(var_0_1:translation("LIANYI_TEXT26"))
			var_4_0(var_0_11)
		end
	end
end

function var_0_0.updateInfo(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_1.act_info

	if not var_13_0 then
		return
	end

	if var_13_0.base_info then
		arg_13_0.newTermModel.baseInfo = var_13_0.base_info
	end

	if var_13_0.collection_items then
		arg_13_0.newTermModel.collectionItems = var_13_0.collection_items
	end

	if var_13_0.got_items then
		arg_13_0.newTermModel.gotItems = var_13_0.got_items
	end

	if var_13_0.connection then
		arg_13_0.newTermModel.connection = var_13_0.connection
	end
end

local var_0_14 = class("NewTermBonusWindow", import("app.common.ui.BaseWindow"))
local var_0_15 = import("app.common.ui.SpineEffect")
local var_0_16 = xyd.tables.translation
local var_0_17 = import("framework.scheduler")
local var_0_18 = xyd.tables.newTermCharm
local var_0_19 = xyd.tables.newTermCollection
local var_0_20 = xyd.tables.newTermConnection
local var_0_21 = 1
local var_0_22 = 2
local var_0_23 = 3

function var_0_14.ctor(arg_14_0, arg_14_1, arg_14_2)
	var_0_14.super.ctor(arg_14_0, arg_14_1, arg_14_2)

	arg_14_0.newTermModel = xyd.ModelManager.get():loadModel(xyd.ModelType.NEW_TERMS)
	arg_14_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_14_0.showMode = var_0_21
end

function var_0_14.willOpen(arg_15_0, arg_15_1)
	var_0_14.super.willOpen(arg_15_0, arg_15_1)
end

function var_0_14.didOpen(arg_16_0, arg_16_1)
	var_0_14.super.didOpen(arg_16_0, arg_16_1)
	arg_16_0:addBlockLayer()
	arg_16_0:layout()
end

function var_0_14.layout(arg_17_0)
	arg_17_0:nodeByName("speaking_txt"):setString(var_0_16:translation("LIANYI_TEXT19"))
	arg_17_0:nodeByName("charm_bonus_txt"):setString(var_0_16:translation("LIANYI_TIP1"))
	arg_17_0:nodeByName("connection_bonus_txt"):setString(var_0_16:translation("LIANYI_TIP2"))
	arg_17_0:nodeByName("collect_present_txt"):setString(var_0_16:translation("LIANYI_TIP3"))
	arg_17_0:nodeByName("text_label"):enableOutline(cc.c4b(255, 243, 220, 255), 2)
	arg_17_0:initListView()
	arg_17_0:initPageButtons()
	arg_17_0:showContainerByMode(var_0_21)
	arg_17_0:updateButtonStatus()
end

function var_0_14.initPageButtons(arg_18_0)
	arg_18_0.pages = {
		arg_18_0:nodeByName("charm_bonus_btn"),
		arg_18_0:nodeByName("connection_bonus_btn"),
		arg_18_0:nodeByName("gift_collect_btn")
	}
	arg_18_0.txts = {
		arg_18_0:nodeByName("charm_bonus_txt"),
		arg_18_0:nodeByName("connection_bonus_txt"),
		arg_18_0:nodeByName("collect_present_txt")
	}

	for iter_18_0 = 1, var_0_23 do
		arg_18_0.pages[iter_18_0]:addTouchEventListener(function(arg_19_0, arg_19_1)
			if arg_19_1 == ccui.TouchEventType.ended then
				arg_18_0.showMode = iter_18_0

				arg_18_0:showContainerByMode(iter_18_0)
			end
		end)
	end
end

function var_0_14.delegate(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if cc.ui.UIListView.COUNT_TAG == arg_20_2 then
		return #arg_20_0.showList
	elseif cc.ui.UIListView.CELL_TAG == arg_20_2 then
		local var_20_0 = arg_20_1:dequeueItem()

		if not var_20_0 then
			var_20_0 = arg_20_1:newItem()
		else
			var_20_0:removeAllChildren()
		end

		local var_20_1 = var_0_0.new()

		var_20_1:setContentSize(722, 127)

		local var_20_2 = arg_20_0.showList[arg_20_3]

		if arg_20_3 == #arg_20_0.showList and arg_20_0.showMode == var_0_23 then
			var_20_2.isLast = arg_20_3 == #arg_20_0.showList
			var_20_2.isAllCollected = arg_20_0:isAllCollected()
		end

		var_20_1:setParams(var_20_2)
		var_20_0:addContent(var_20_1)
		var_20_0:setItemSize(722, 127)

		return var_20_0
	end
end

function var_0_14.isAllCollected(arg_21_0)
	if arg_21_0.showMode == var_0_23 then
		for iter_21_0 = 1, #arg_21_0.showList - 1 do
			local var_21_0 = arg_21_0.showList[iter_21_0]

			if not xyd.isInTable(arg_21_0.newTermModel.collectionItems, tostring(var_21_0.id)) then
				return false
			end
		end
	end

	return true
end

function var_0_14.showContainerByMode(arg_22_0, arg_22_1)
	arg_22_0.showList = arg_22_0:initDataByMode(arg_22_1)

	if arg_22_1 == var_0_21 then
		arg_22_0:nodeByName("num"):setVisible(true)
		arg_22_0:nodeByName("text_label"):setVisible(true)
		arg_22_0:nodeByName("num"):setString(arg_22_0.newTermModel.charm)
		arg_22_0:nodeByName("text_label"):setString(var_0_16:translation("LIANYI_TEXT15"))
	elseif arg_22_1 == var_0_22 then
		arg_22_0:nodeByName("num"):setVisible(true)
		arg_22_0:nodeByName("text_label"):setVisible(true)
		arg_22_0:nodeByName("num"):setString(arg_22_0.newTermModel.connection)
		arg_22_0:nodeByName("text_label"):setString(var_0_16:translation("LIANYI_TEXT16"))
	else
		arg_22_0:nodeByName("num"):setVisible(false)
		arg_22_0:nodeByName("text_label"):setVisible(false)
	end

	arg_22_0:updateButtonStatus()
	arg_22_0:updateList()
end

function var_0_14.initDataByMode(arg_23_0, arg_23_1)
	local var_23_0 = {}
	local var_23_1 = {}

	if arg_23_1 == var_0_21 then
		local var_23_2 = var_0_18:ids()

		for iter_23_0, iter_23_1 in pairs(var_23_2) do
			local var_23_3 = {
				id = iter_23_1,
				condition = var_0_18:charm(iter_23_1),
				item_id = var_0_18:charmGift(iter_23_1),
				mode = arg_23_1
			}

			table.insert(var_23_0, var_23_3)
		end
	elseif arg_23_1 == var_0_22 then
		local var_23_4 = var_0_20:ids()

		for iter_23_2, iter_23_3 in pairs(var_23_4) do
			local var_23_5 = {
				id = iter_23_3,
				condition = var_0_20:connection(iter_23_3),
				item_id = var_0_20:connectionGift(iter_23_3),
				mode = arg_23_1
			}

			table.insert(var_23_0, var_23_5)
		end
	else
		local var_23_6 = var_0_19:ids()

		for iter_23_4, iter_23_5 in pairs(var_23_6) do
			local var_23_7 = {
				id = iter_23_5,
				item_id = var_0_19:collectionGift(iter_23_5),
				mode = arg_23_1
			}

			table.insert(var_23_0, var_23_7)
		end
	end

	return var_23_0
end

function var_0_14.updateList(arg_24_0)
	arg_24_0.listView_:reload()
end

function var_0_14.updateButtonStatus(arg_25_0)
	for iter_25_0 = 1, var_0_23 do
		if iter_25_0 == arg_25_0.showMode then
			arg_25_0.pages[iter_25_0]:setBrightStyle(ccui.BrightStyle.highlight)
			arg_25_0.txts[iter_25_0]:setColor(cc.c3b(123, 55, 0))
		else
			arg_25_0.txts[iter_25_0]:setColor(cc.c3b(65, 74, 84))
			arg_25_0.pages[iter_25_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_14.initListView(arg_26_0)
	if not arg_26_0.listView_ then
		arg_26_0.listView_ = cc.ui.UIListView.new({
			async = true,
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 730, 372),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_26_0:nodeByName("bonus_list"))

		arg_26_0.listView_:setDelegate(handler(arg_26_0, arg_26_0.delegate))
	else
		arg_26_0.listView_:removeAllItems()
	end
end

function var_0_14.updateListView(arg_27_0)
	for iter_27_0 = 1, 10 do
		local var_27_0 = arg_27_0.listView_:newItem()
		local var_27_1 = var_0_0.new()

		var_27_1:setParams()
		var_27_0:addContent(var_27_1)
		var_27_0:setItemSize(722, 135)
		arg_27_0.listView_:addItem(var_27_0)
	end

	arg_27_0.listView_:reload()
end

function var_0_14.willClose(arg_28_0)
	if arg_28_0.handle then
		var_0_17.unscheduleGlobal(arg_28_0.handle)

		arg_28_0.handle = nil
	end
end

return var_0_14
