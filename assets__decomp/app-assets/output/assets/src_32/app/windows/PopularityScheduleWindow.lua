local var_0_0 = class("PopularityScheduleWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityVoteTimeline

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.popularContest = xyd.ModelManager.get():loadModel(xyd.ModelType.POPULARITY_CONTEST)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0.popularContest.startTime
	local var_4_1 = arg_4_0.popularContest.endTime
	local var_4_2 = var_0_2:ids()

	for iter_4_0 = 1, #var_4_2 do
		local var_4_3 = var_4_2[iter_4_0]
		local var_4_4 = var_0_2:time(var_4_3)

		arg_4_0:nodeByName("text_date_" .. iter_4_0):setString(os.date("%Y-%m-%d", var_4_0 + var_4_4[1] * 24 * 3600))
		arg_4_0:nodeByName("text_time_" .. iter_4_0):setString(os.date("%X", var_4_0))

		local var_4_5 = var_0_2:longDes(var_4_3)
		local var_4_6 = string.gsub(var_4_5, "|", "\n")

		arg_4_0:nodeByName("text_desc_" .. iter_4_0):setString(var_4_6)
	end
end

return var_0_0
