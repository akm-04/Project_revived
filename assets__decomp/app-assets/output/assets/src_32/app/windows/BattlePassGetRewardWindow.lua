local var_0_0 = class("BattlePassGetRewardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 200

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.items = arg_1_2
	arg_1_0.listLine = math.ceil(#arg_1_0.items / 6)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("BATTLE_PASS_TEXT_9"))
	arg_4_0:nodeByName("txt_ok"):setString(var_0_1:translation("SURE"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UITableView.new({
		async = true,
		itemGap = 16,
		size = var_4_0,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_4_0.width, 96)
	}):addTo(arg_4_0:nodeByName("list"))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()

	local var_4_1 = 112 * arg_4_0.listLine - 16

	if var_4_1 > var_4_0.height then
		local var_4_2 = (var_4_1 - var_4_0.height) / var_0_2

		arg_4_0.list:scrollMoveToEnd(math.min(var_4_2, 1))
	end

	xyd.nodeEventSample(arg_4_0:nodeByName("btn_ok"), nil, function()
		arg_4_0:close()
	end)
end

function var_0_0.delegate(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	if arg_6_2 == cc.ui.UITableView.COUNT_TAG then
		return arg_6_0.listLine
	elseif arg_6_2 == cc.ui.UITableView.CELL_TAG then
		local var_6_0 = arg_6_0.list:getItem()
		local var_6_1 = arg_6_0:createContent(arg_6_3)

		var_6_0:addContent(var_6_1)

		return var_6_0
	end
end

function var_0_0.createContent(arg_7_0, arg_7_1)
	local var_7_0 = display.newNode()

	for iter_7_0 = 1, 6 do
		local var_7_1 = (arg_7_1 - 1) * 6 + iter_7_0

		if not arg_7_0.items[var_7_1] then
			break
		end

		local var_7_2 = display.newNode()

		var_7_2:setContentSize(96, 96)
		var_7_2:setPosition((iter_7_0 - 1) * 115, 0)

		if arg_7_0.items[var_7_1].table_id > 0 then
			xyd.setItemAndAddTips(var_7_2, arg_7_0.items[var_7_1].table_id, arg_7_0.items[var_7_1].item_num)
		else
			arg_7_0:setSpecialItemBorder(var_7_2, arg_7_0.items[var_7_1])
		end

		var_7_0:addChild(var_7_2)
	end

	return var_7_0
end

function var_0_0.setSpecialItemBorder(arg_8_0, arg_8_1, arg_8_2)
	if arg_8_2.table_id ~= -1 then
		return
	end

	local var_8_0 = xyd.tables.asset:getIdByBackendName(arg_8_2.type)

	if not var_8_0 then
		return
	end

	xyd.setItemAndAddTips(arg_8_1, var_8_0, arg_8_2.item_num)
end

return var_0_0
