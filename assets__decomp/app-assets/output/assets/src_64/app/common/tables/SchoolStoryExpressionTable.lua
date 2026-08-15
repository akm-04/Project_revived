local var_0_0 = class("SchoolStoryExpressionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.expression_ = {}

	import("app.common.tables.TableParser").parse("school_story_expression.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.expression_[var_2_0] = arg_2_0.expression
	end)
end

function var_0_0.expression(arg_3_0, arg_3_1)
	return arg_3_0.expression_[arg_3_1]
end

return var_0_0
