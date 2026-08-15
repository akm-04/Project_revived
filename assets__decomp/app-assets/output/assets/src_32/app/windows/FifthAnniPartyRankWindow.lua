local var_0_0 = class("FifthAnniPartyRankWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.data = arg_1_2.rank_list
	arg_1_0.rank = arg_1_2.self_rank
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_12"))
	arg_4_0:nodeByName("txt_my_rank"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_13"))
	arg_4_0:nodeByName("txt_my_send_point"):setString(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_14"))

	local var_4_0 = arg_4_0:nodeByName("list"):getContentSize()

	arg_4_0.list = cc.ui.UITableView.new({
		async = true,
		itemGap = 0,
		size = var_4_0,
		direction = cc.ui.UITableView.DIRECTION_VERTICAL,
		itemSize = cc.size(var_4_0.width, 138)
	}):addTo(arg_4_0:nodeByName("list"))

	arg_4_0.list:setDelegate(handler(arg_4_0, arg_4_0.delegate))
	arg_4_0.list:reload()
	arg_4_0:nodeByName("my_rank"):setString(arg_4_0.rank)
	arg_4_0:nodeByName("my_send_point"):setString(arg_4_0.model:getSendPoint())
end

function var_0_0.delegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	if arg_5_2 == cc.ui.UITableView.COUNT_TAG then
		return #arg_5_0.data
	elseif arg_5_2 == cc.ui.UITableView.CELL_TAG then
		local var_5_0 = arg_5_0.list:getItem()
		local var_5_1 = arg_5_0:createContent(arg_5_3)

		var_5_0:addContent(var_5_1)

		return var_5_0
	end
end

function var_0_0.createContent(arg_6_0, arg_6_1)
	local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1232/party/rank_item.csb")
	local var_6_1 = var_6_0:getChildByName("container")
	local var_6_2 = arg_6_0.data[arg_6_1]

	if arg_6_1 <= 3 then
		local var_6_3 = "windows/activities/1232/party/icon_rank_" .. arg_6_1 .. ".png"
		local var_6_4 = "windows/activities/1232/party/bg_rank_" .. arg_6_1 .. ".png"
		local var_6_5 = xyd.AssetLoader.get():loadSprite(var_6_3)

		var_6_1:getChildByName("txt_rank"):setVisible(false)
		var_6_1:getChildByName("pos_icon_rank"):addChild(var_6_5)
		var_6_1:getChildByName("bg"):loadTexture(var_6_4, 1)
	else
		var_6_1:getChildByName("txt_rank"):setString(arg_6_1)
		var_6_1:getChildByName("txt_rank"):enableOutline(cc.c4b(89, 138, 174, 255), 3)
	end

	var_6_1:getChildByName("txt_region"):setString("S" .. xyd.getPlayerRegion(var_6_2.player_info.player_id))
	var_6_1:getChildByName("txt_name"):setString(var_6_2.player_info.player_name)
	var_6_1:getChildByName("txt_count"):setString(string.format(var_0_1:translation("FIFTH_ANNI_PARTY_TEXT_15"), var_6_2.point))

	local var_6_6 = {
		is_new = true,
		avatar_frame_id = var_6_2.player_info.avatar_frame_id,
		avatar_id = var_6_2.player_info.avatar_id
	}

	xyd.setPlayerAvatar(var_6_1:getChildByName("avatar"), var_6_6)

	local var_6_7 = {
		lev = var_6_2.player_info.lev,
		conquerLev = var_6_2.player_info.conquer_lev,
		loopID = var_6_2.player_info.conquer_loop_id,
		fontColor = cc.c3b(80, 12, 26)
	}

	xyd.setLev(var_6_1:getChildByName("lv"), var_6_7)

	return var_6_0
end

return var_0_0
