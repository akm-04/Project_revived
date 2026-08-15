local var_0_0 = class("ActivityMarketDialogueTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.content_ = {}

	import("app.common.tables.TableParser").parse("activity_market_dialogue.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.content_[var_2_0] = arg_2_0.content
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.content(arg_4_0, arg_4_1)
	return arg_4_0.content_[arg_4_1] or ""
end

return var_0_0
