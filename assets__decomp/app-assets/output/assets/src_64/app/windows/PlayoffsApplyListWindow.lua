local var_0_0 = class("PlayoffsApplyListWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.applyListInfo = arg_1_2.sign_list
	arg_1_0.selfInfo = arg_1_2.self_info
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0.applyList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_3_0:nodeByName("player_list"):getContentSize().width, arg_3_0:nodeByName("player_list"):getContentSize().height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIListView.DIRECTION_VERTICAL
	}):addTo(arg_3_0:nodeByName("player_list")):align(display.BOTTOM_CENTER, 0, 0):setTouchType(true):pos(0, 0)

	arg_3_0.applyList:setDelegate(handler(arg_3_0, arg_3_0.applyListDelegate))
	arg_3_0.applyList:reload()
	arg_3_0:layout()
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("REGION_ARENA_TEXT_19"))

	local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_4_0.selfInfo.rank then
		-- block empty
	else
		arg_4_0:nodeByName("player_rank_label"):setVisible(false)
		arg_4_0:nodeByName("player_rank"):setVisible(false)
		arg_4_0:nodeByName("no_rank_label"):setVisible(true)
		arg_4_0:nodeByName("no_rank_label"):setString(var_0_1:translation("PLAYOFFS_NO_RANK_LABEL"))
	end

	arg_4_0:nodeByName("player_name"):setString(var_4_0.playerName)
	xyd.setLev(arg_4_0:nodeByName("dengjiquan"), {
		conquerLev = var_4_0.conquerLev,
		lev = var_4_0.lev
	})
	arg_4_0:nodeByName("player_rank"):setString(arg_4_0.selfInfo.rank)
	arg_4_0:nodeByName("player_rank_label"):setString(var_0_1:translation("MY_RANKING"))
	xyd.setPlayerAvatar(arg_4_0:nodeByName("player_icon"), {
		avatar_id = var_4_0:getMyCurrentAvatarID(),
		avatar_frame_id = var_4_0.avatarFrame
	})
end

function var_0_0.applyListDelegate(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0
	local var_5_1 = 0
	local var_5_2 = arg_5_0.applyList

	if cc.ui.UIListView.COUNT_TAG == arg_5_2 then
		return #arg_5_0.applyListInfo or 0
	elseif cc.ui.UIListView.CELL_TAG == arg_5_2 then
		local var_5_3 = var_5_2:dequeueItem()

		if not var_5_3 then
			var_5_3 = var_5_2:newItem()
		else
			var_5_3:removeAllChildren(true)
		end

		local var_5_4
		local var_5_5 = import("app.windows.PlayoffsApplyListItem").new(arg_5_3, arg_5_0.applyListInfo[arg_5_3])
		local var_5_6 = {}

		var_5_5:setPosition(0, (var_5_1 - arg_5_3) * 150 + 34)

		local var_5_7 = var_5_5:getContentSize()

		var_5_3:addContent(var_5_5)
		var_5_3:setItemSize(var_5_7.width + 5, var_5_7.height + 7)

		return var_5_3
	end
end

return var_0_0
