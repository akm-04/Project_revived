local var_0_0 = class("InviteQuestItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.twoYearsMission
local var_0_3 = 1000
local var_0_4 = xyd.tables.hero

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/two_years/quest_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_4_1 = var_0_2:item(arg_4_1.mission)
	local var_4_2 = 0

	if var_4_1 ~= 0 then
		var_4_2 = var_4_0:getBackpack():getItemNumByID(var_4_1)

		arg_4_0.contentView_:nodeByName("have_num"):setVisible(true)
		arg_4_0.contentView_:nodeByName("have_num"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT29"), var_4_2))
	else
		arg_4_0.contentView_:nodeByName("have_num"):setVisible(false)
	end

	arg_4_0.contentView_:nodeByName("quest_process"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT10"), arg_4_1.progress, arg_4_1.condition))
	arg_4_0.contentView_:nodeByName("quest_detail"):setString(string.format(var_0_2:desc(arg_4_1.mission), arg_4_1.condition))

	if var_4_2 < arg_4_1.condition then
		arg_4_0.contentView_:nodeByName("pay_btn"):setVisible(false)
	elseif arg_4_1.isFinish == 0 then
		arg_4_0.contentView_:nodeByName("pay_btn"):setVisible(true)
	else
		arg_4_0.contentView_:nodeByName("pay_btn"):setVisible(false)
	end

	if arg_4_1.isFinish == 1 then
		arg_4_0.contentView_:nodeByName("invite_finish_flag"):setVisible(true)
	end

	arg_4_0.contentView_:nodeByName("pay_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and var_4_1 ~= 0 then
			local var_5_0 = {
				table_id = arg_4_1.tableID,
				item_id = var_4_1,
				item_num = arg_4_1.condition
			}

			arg_4_0.twoYearsModel:giveAnniMissionItem(var_5_0, function()
				local var_6_0 = {
					itemID = var_4_1,
					itemNum = var_5_0.item_num
				}
			end)
		end
	end)
end

local var_0_5 = class("TwoYearsQuestDetailItem", function()
	return cc.Node:create()
end)
local var_0_6 = xyd.tables.translation
local var_0_7 = xyd.tables.model
local var_0_8 = import("app.model.Hero")
local var_0_9 = 460
local var_0_10 = "windows/two_years/concentrate/mask.png"
local var_0_11 = 1
local var_0_12 = 2

function var_0_5.ctor(arg_8_0)
	arg_8_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_8_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)

	arg_8_0:contentView()
end

function var_0_5.setParams(arg_9_0, arg_9_1)
	arg_9_0.info = arg_9_1

	arg_9_0:initQuestList()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_9_0):addEventListener(xyd.event.TWO_YEARS_MISSION_COMPLETE, function(arg_10_0)
		if arg_9_0 and not tolua.isnull(arg_9_0) and arg_10_0.params.table_id == arg_9_0.info.table_id then
			arg_9_0.info = arg_10_0.params

			if arg_9_0.info then
				arg_9_0:initQuestList()
			end
		end
	end)
end

function var_0_5.checkQuestProgress(arg_11_0, arg_11_1)
	local var_11_0 = 0
	local var_11_1 = 0

	for iter_11_0, iter_11_1 in pairs(arg_11_1) do
		var_11_1 = var_11_1 + 1

		if iter_11_1.is_finish == 1 then
			var_11_0 = var_11_0 + 1
		end
	end

	return var_11_0, var_11_1
end

function var_0_5.initQuestList(arg_12_0)
	if not arg_12_0.listView_ then
		arg_12_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 405, 400),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_12_0:contentView():nodeByName("quest_list"))
	else
		arg_12_0.listView_:removeAllItems()
	end

	for iter_12_0, iter_12_1 in pairs(arg_12_0.info.mission_info) do
		local var_12_0 = {
			mission = tonumber(iter_12_0),
			isFinish = iter_12_1.is_finish,
			condition = iter_12_1.condition,
			progress = iter_12_1.progress,
			tableID = arg_12_0.info.table_id
		}
		local var_12_1 = arg_12_0.listView_:newItem()
		local var_12_2 = var_0_0.new()

		var_12_2:setParams(var_12_0)
		var_12_1:addContent(var_12_2)
		var_12_1:setItemSize(var_12_2:getContentSize().width, var_12_2:getContentSize().height + 8)
		arg_12_0.listView_:addItem(var_12_1)
	end

	arg_12_0.listView_:reload()
end

function var_0_5.contentView(arg_13_0)
	if arg_13_0.contentView_ == nil then
		arg_13_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_13_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/two_years/quest_detail_item.csb"))
		arg_13_0.contentView_:addTo(arg_13_0)
		arg_13_0:setContentSize(arg_13_0.contentView_:getContentSize().width, arg_13_0.contentView_:getContentSize().height)
		arg_13_0.contentView_:setTouchSwallowEnabled(false)
		arg_13_0.contentView_:setAnchorPoint(0, 0)
	end

	return arg_13_0.contentView_
end

return var_0_5
