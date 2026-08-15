local var_0_0 = class("PlayoffsMatchListItem", function()
	return cc.Node:create()
end)

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.match_item = arg_2_1
	arg_2_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)

	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.contentView_:nodeByName("name_1"):setString(arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].player_name)

	local var_3_0 = {
		conquerLev = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].conquer_lev,
		lev = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].lev,
		loopID = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].conquer_loop_id
	}

	xyd.setLev(arg_3_0.contentView_:nodeByName("lv_1"), var_3_0)
	xyd.setPlayerAvatar(arg_3_0.contentView_:nodeByName("icon_1"), {
		avatar_id = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].avatar_id,
		avatar_frame_id = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.A_player_id)].avatar_frame_id
	})
	arg_3_0.contentView_:nodeByName("btn_1"):getChildByName("text_check_1"):setString(xyd.tables.translation:translation("CHECK"))
	arg_3_0.contentView_:nodeByName("btn_1"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0.PlayoffsModel:getMatchList(function(arg_5_0, arg_5_1)
				xyd.WindowManager.get():openWindow("playoffs_player_info", arg_3_0.match_item.A_player_id)
			end)
		end
	end)
	arg_3_0.contentView_:nodeByName("name_2"):setString(arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].player_name)

	local var_3_1 = {
		conquerLev = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].conquer_lev,
		lev = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].lev,
		loopID = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].conquer_loop_id
	}

	xyd.setLev(arg_3_0.contentView_:nodeByName("lv_2"), var_3_1)
	xyd.setPlayerAvatar(arg_3_0.contentView_:nodeByName("icon_2"), {
		avatar_id = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].avatar_id,
		avatar_frame_id = arg_3_0.PlayoffsModel.players_info[tostring(arg_3_0.match_item.B_player_id)].avatar_frame_id
	})
	arg_3_0.contentView_:nodeByName("btn_2"):getChildByName("text_check_2"):setString(xyd.tables.translation:translation("CHECK"))
	arg_3_0.contentView_:nodeByName("btn_2"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			arg_3_0.PlayoffsModel:getMatchList(function(arg_7_0, arg_7_1)
				xyd.WindowManager.get():openWindow("playoffs_player_info", arg_3_0.match_item.B_player_id)
			end)
		end
	end)
end

function var_0_0.contentView(arg_8_0)
	if arg_8_0.contentView_ == nil then
		arg_8_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_8_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/vs_main/match_item.csb"))
		arg_8_0.contentView_:addTo(arg_8_0)
		arg_8_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_8_0.contentView_
end

return var_0_0
