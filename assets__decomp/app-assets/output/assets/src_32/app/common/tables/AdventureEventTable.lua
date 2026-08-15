local var_0_0 = class("AdventureEventTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.list = {}
	arg_1_0.titlePic_ = {}
	arg_1_0.titleBg_ = {}
	arg_1_0.contentBg_ = {}
	arg_1_0.windowName_ = {}
	arg_1_0.timeLimit_ = {}

	import("app.common.tables.TableParser").parse("adventure_event.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.id

		arg_1_0.list[var_2_0] = var_2_0
		arg_1_0.titlePic_[var_2_0] = arg_2_0.title_pic
		arg_1_0.titleBg_[var_2_0] = arg_2_0.title_bg
		arg_1_0.contentBg_[var_2_0] = arg_2_0.content_bg
		arg_1_0.windowName_[var_2_0] = arg_2_0.window_name
		arg_1_0.timeLimit_[var_2_0] = tonumber(arg_2_0.time_limit)
	end)
end

function var_0_0.timeLimit(arg_3_0, arg_3_1)
	return arg_3_0.timeLimit_[arg_3_1] or 0
end

function var_0_0.titlePic(arg_4_0, arg_4_1)
	return arg_4_0.titlePic_[arg_4_1] or ""
end

function var_0_0.titleBg(arg_5_0, arg_5_1)
	return arg_5_0.titleBg_[arg_5_1] or ""
end

function var_0_0.contentBg(arg_6_0, arg_6_1)
	return arg_6_0.contentBg_[arg_6_1] or ""
end

function var_0_0.windowName(arg_7_0, arg_7_1)
	return arg_7_0.windowName_[arg_7_1] or ""
end

function var_0_0.getEventTableIds(arg_8_0)
	return arg_8_0.list or {}
end

return var_0_0
