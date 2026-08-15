local var_0_0 = class("PlayoffsMatchTimeItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0:contentView()

	arg_2_0.idx = arg_2_1
	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
	arg_2_0.playoffTimeTable = xyd.tables.playoffTimeTable

	arg_2_0:setContentSize(arg_2_0.container:getContentSize())
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:contentView():nodeByName("text"):setString(string.format(var_0_1:translation("PLAYOFFS_MATCH_TIME"), arg_3_0.playoffTimeTable:project(arg_3_0.idx + 1), arg_3_0.playoffTimeTable:hour(arg_3_0.idx + 1), arg_3_0.playoffTimeTable:minute(arg_3_0.idx + 1)))
end

function var_0_0.contentView(arg_4_0)
	if arg_4_0.contentView_ == nil then
		arg_4_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_4_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/playoffs/playoffs_resource/match_time/match_time_item.csb"))
		arg_4_0.contentView_:addTo(arg_4_0)
		arg_4_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_4_0.contentView_
end

return var_0_0
