local var_0_0 = class("PlayoffsApplyListItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0, arg_2_1, arg_2_2)
	arg_2_0:contentView()

	arg_2_0.rankNum = arg_2_1
	arg_2_0.rank_info = arg_2_2
	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:contentView():nodeByName("first")
	local var_3_1 = arg_3_0:contentView():nodeByName("second")
	local var_3_2 = arg_3_0:contentView():nodeByName("third")

	if arg_3_0.rankNum == 1 then
		var_3_0:setVisible(true)
		var_3_1:setVisible(false)
		var_3_2:setVisible(false)
	elseif arg_3_0.rankNum == 2 then
		var_3_0:setVisible(false)
		var_3_1:setVisible(true)
		var_3_2:setVisible(false)
	elseif arg_3_0.rankNum == 3 then
		var_3_0:setVisible(false)
		var_3_1:setVisible(false)
		var_3_2:setVisible(true)
	else
		var_3_0:setVisible(false)
		var_3_1:setVisible(false)
		var_3_2:setVisible(false)

		local var_3_3 = xyd.AssetLoader.get():loadLabel(nil, "rankFonts")

		var_3_3:setString(arg_3_0.rankNum)
		var_3_3:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_3:setPosition(arg_3_0:contentView():nodeByName("third"):getPosition())
		var_3_3:addTo(arg_3_0)
	end

	arg_3_0:contentView():nodeByName("name"):setString("( S" .. arg_3_0.rank_info.region .. " )" .. arg_3_0.rank_info.player_name)
	xyd.setLev(arg_3_0:contentView():nodeByName("dengjiquan"), {
		conquerLev = arg_3_0.rank_info.conquerLev,
		lev = arg_3_0.rank_info.lev
	})
	xyd.setPlayerAvatar(arg_3_0:contentView():nodeByName("icon"), {
		avatar_id = arg_3_0.rank_info.avatar_id,
		avatar_frame_id = arg_3_0.rank_info.avatar_frame_id
	})
end

function var_0_0.registerTouchEvent(arg_4_0)
	local var_4_0 = arg_4_0.container

	arg_4_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0.prevX_ = arg_5_0.x
			arg_4_0.prevY_ = arg_5_0.y
			arg_4_0.startClick_ = true
		elseif arg_5_0.name == "moved" then
			if math.abs(arg_5_0.y - arg_4_0.prevY_) > 10 or math.abs(arg_5_0.x - arg_4_0.prevX_) > 20 then
				arg_4_0.startClick_ = false
			end
		elseif arg_5_0.name == "ended" and arg_4_0.startClick_ then
			local var_5_0 = var_4_0:convertToNodeSpace(cc.p(arg_5_0.x, arg_5_0.y))
		end

		return true
	end)
end

function var_0_0.contentView(arg_6_0)
	if arg_6_0.contentView_ == nil then
		arg_6_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_6_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/apply_list/apply_list_item.csb"))
		arg_6_0.contentView_:addTo(arg_6_0)
		arg_6_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_6_0.contentView_
end

return var_0_0
