local var_0_0 = class("SendKiteRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.id = arg_1_2.id
	arg_1_0.grabPlayers = arg_1_2.players
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(1, 1, 557, 470),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0:updateRecordList()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 220))
end

function var_0_0.createLabel(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = {
		color = arg_4_1,
		size = arg_4_2
	}
	local var_4_1 = xyd.AssetLoader.get():loadLabel(var_4_0)

	if arg_4_3 then
		var_4_1:setMaxLineWidth(arg_4_3)
	end

	return var_4_1
end

function var_0_0.updateRecordList(arg_5_0)
	for iter_5_0 = 1, #arg_5_0.grabPlayers do
		local var_5_0 = arg_5_0.grabPlayers[iter_5_0]
		local var_5_1 = display.newNode()
		local var_5_2 = arg_5_0.list:newItem()
		local var_5_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/kite/grab_record_item.csb")
		local var_5_4 = var_5_3:getChildByName("container")
		local var_5_5 = {
			50001091,
			50001092,
			50001093
		}
		local var_5_6 = {
			avatar_id = var_5_0.avatar_id,
			avatar_frame_id = var_5_0.avatar_frame_id
		}

		xyd.setPlayerAvatar(var_5_4:getChildByName("avatar_container"), var_5_6)
		var_5_4:getChildByName("player_server"):setString("S" .. var_5_0.region)
		var_5_4:getChildByName("name_txt"):setString(var_5_0.player_name)
		xyd.setItemBorder(var_5_4:getChildByName("kite_container"), var_5_5[arg_5_0.id])
		var_5_4:getChildByName("get_desc_txt"):setString(var_0_1:translation("KITE_RECORD_TIP"))
		var_5_4:getChildByName("reward_num_txt"):setString(var_5_0.award)
		var_5_3:addTo(var_5_1)
		var_5_3:setAnchorPoint(cc.p(0, 0))
		var_5_1:setContentSize(var_5_4:getContentSize())
		var_5_2:addContent(var_5_1)
		var_5_2:setItemSize(var_5_4:getWidth(), var_5_4:getHeight() + 10)
		arg_5_0.list:addItem(var_5_2)
	end

	arg_5_0.list:reload()
end

return var_0_0
