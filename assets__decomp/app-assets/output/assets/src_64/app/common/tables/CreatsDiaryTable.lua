local var_0_0 = class("CreatsDiaryTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.logType_ = {}
	arg_1_0.logDes_ = {}
	arg_1_0.content_ = {}

	import("app.common.tables.TableParser").parse("creats_diary.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.logType_[var_2_0] = tonumber(arg_2_0.log_type)
		arg_1_0.logDes_[var_2_0] = arg_2_0.log_des
		arg_1_0.content_[var_2_0] = arg_2_0.content
	end)
end

function var_0_0.logType(arg_3_0, arg_3_1)
	return arg_3_0.logType_[arg_3_1] or 0
end

function var_0_0.logDes(arg_4_0, arg_4_1)
	return arg_4_0.logDes_[arg_4_1] or ""
end

function var_0_0.content(arg_5_0, arg_5_1)
	return arg_5_0.content_[arg_5_1] or ""
end

return var_0_0
