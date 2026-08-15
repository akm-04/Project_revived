local var_0_0 = class("ChatConfigTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.isRecordOpen_ = {}
	arg_1_0.maxRecords_ = {}

	import("app.common.tables.TableParser").parse("chat_config.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.isRecordOpen_[var_2_0] = tonumber(arg_2_0.is_record_open)
		arg_1_0.maxRecords_[var_2_0] = tonumber(arg_2_0.max_record_num)
	end)
end

function var_0_0.isRecordOpen(arg_3_0, arg_3_1)
	return arg_3_0.isRecordOpen_[arg_3_1] or 0
end

function var_0_0.maxRecordNum(arg_4_0, arg_4_1)
	return arg_4_0.maxRecords_[arg_4_1] or 0
end

return var_0_0
