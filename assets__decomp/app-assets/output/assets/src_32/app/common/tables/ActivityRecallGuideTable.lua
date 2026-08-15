local var_0_0 = class("ActivityRecallGuideTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.bg_ = {}
	arg_1_0.word_ = {}

	import("app.common.tables.TableParser").parse("activity_recall_guide.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.bg_[var_2_0] = arg_2_0.bg
		arg_1_0.word_[var_2_0] = arg_2_0.word
	end)
end

function var_0_0.bg(arg_3_0, arg_3_1)
	return arg_3_0.bg_[arg_3_1] or ""
end

function var_0_0.word(arg_4_0, arg_4_1)
	return arg_4_0.word_[arg_4_1] or ""
end

function var_0_0.ids(arg_5_0)
	return table.keys(arg_5_0.bg_) or {}
end

return var_0_0
