local var_0_0 = class("ApplyRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.records = arg_1_2.records
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 731, 525),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0:nodeByName("title"):setString(var_0_1:translation("APPLY_RECORD_TITLE"))
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.list:removeAllItems()

	for iter_4_0 = 1, #arg_4_0.records do
		local var_4_0 = arg_4_0.records[iter_4_0]
		local var_4_1 = display.newNode()
		local var_4_2 = arg_4_0.list:newItem()
		local var_4_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/corporation_window/apply_reward/apply_record_item.csb")
		local var_4_4 = var_4_3:getChildByName("container")

		var_4_4:getChildByName("desc"):setString(var_0_1:translation("APPLY_AUTO_BY_SYS"))
		xyd.setItemBorder(var_4_4:getChildByName("item"), var_4_0.item_id)
		var_4_4:getChildByName("name_txt"):setString(var_4_0.player_name)

		local var_4_5 = var_4_4:getChildByName("name_txt"):getPositionX()
		local var_4_6 = var_4_4:getChildByName("name_txt"):getContentSize().width

		var_4_4:getChildByName("time_txt"):setPositionX(var_4_5 + var_4_6 + 6)
		var_4_4:getChildByName("time_txt"):setString(arg_4_0:createTimeLabel(var_4_0.time))
		var_4_3:setContentSize(720, 132)
		var_4_1:addChild(var_4_3)
		var_4_1:setContentSize(720, 132)
		var_4_2:addContent(var_4_1)
		var_4_2:setItemSize(720, 140)
		arg_4_0.list:addItem(var_4_2)
	end

	arg_4_0.list:reload()
end

function var_0_0.createTimeLabel(arg_5_0, arg_5_1)
	local var_5_0 = os.date("%Y", arg_5_1)
	local var_5_1 = os.date("%m", arg_5_1)
	local var_5_2 = os.date("%d", arg_5_1)
	local var_5_3, var_5_4 = os.date("%X", arg_5_1), var_5_0 .. var_0_1:translation("YEAR") .. var_5_1 .. var_0_1:translation("MONTH") .. var_5_2 .. var_0_1:translation("DAY")

	return (string.format(var_0_1:translation("GUILD_RECORD_DESC"), var_5_4, var_5_3))
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
