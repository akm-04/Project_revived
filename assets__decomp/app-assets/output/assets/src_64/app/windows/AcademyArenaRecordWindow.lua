local var_0_0 = class("AcademyArenaRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.academyArenaMap

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.ACADEMY_ARENA)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.records = arg_1_0.model.recordList
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:nodeByName("list_container")
	local var_2_1 = var_2_0:getContentSize()

	arg_2_0.width = var_2_1.width
	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_1.width, var_2_1.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0)

	arg_2_0:updateList()
end

function var_0_0.updateList(arg_3_0)
	arg_3_0.list:removeAllItems()

	local var_3_0 = 130
	local var_3_1 = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.records) do
		local var_3_2 = arg_3_0.list:newItem()
		local var_3_3 = arg_3_0:createRecordItem(iter_3_1)

		var_3_3:setContentSize(arg_3_0.width, var_3_0)
		var_3_2:setItemSize(arg_3_0.width, var_3_0)
		var_3_2:addContent(var_3_3)
		arg_3_0.list:addItem(var_3_2)
	end

	arg_3_0.list:reload()
end

function var_0_0.createRecordItem(arg_4_0, arg_4_1)
	local var_4_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/academy_arena/record/record_item.csb")
	local var_4_1 = var_4_0:getChildByName("bg")
	local var_4_2 = arg_4_1.A_player_id == arg_4_0.player.playerID

	if arg_4_1.is_win < 1 == var_4_2 then
		var_4_1:getChildByName("win"):setVisible(false)
		var_4_1:getChildByName("lose"):setVisible(true)
	end

	local var_4_3 = arg_4_0.model:getRecordPlayer(var_4_2 and arg_4_1.B_player_id or arg_4_1.A_player_id)

	var_4_1:getChildByName("txt_status"):setString(var_0_1:translation(var_4_2 and "ACADEMY_ARENA_WAR_COMMUNIQUE_ATTACK" or "ACADEMY_ARENA_WAR_COMMUNIQUE_DEFEND"))

	local var_4_4 = {
		avatar_id = var_4_3.avatar_id,
		avatar_frame_id = var_4_3.avatar_frame_id
	}

	xyd.setPlayerAvatar(var_4_1:getChildByName("avatar"), var_4_4)

	if var_4_3.conquer_lev and var_4_3.conquer_lev > 0 then
		xyd.setConquerLev(var_4_3.conquer_lev, var_4_1:getChildByName("lev"), var_4_1:getChildByName("bg_lev"), nil, nil, nil, nil, var_4_3.conquer_loop_id)
	else
		var_4_1:getChildByName("lev"):setString(var_4_3.lev)
	end

	var_4_1:getChildByName("text_player_name"):setString(var_4_3.player_name)

	local var_4_5 = xyd.ServerTime.get():getServerTime() - arg_4_1.time

	var_4_1:getChildByName("text_time"):setString(xyd.secondsToString(var_4_5, {
		short = true,
		toText = true
	}) .. var_0_1:translation("BEFORE"))
	var_4_1:getChildByName("txt_area_name"):setString(var_0_2:name(arg_4_1.map_id))
	var_4_1:getChildByName("detail_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			arg_4_0.model:getRecordDetail(arg_4_1.record_id, function(arg_6_0)
				xyd.WindowManager.get():openWindow("academy_arena_record_detail", {
					list = arg_6_0.sub_record_list,
					playerAId = arg_4_1.A_player_id,
					playerBId = arg_4_1.B_player_id
				})
			end)
		end
	end)

	return var_4_0
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
