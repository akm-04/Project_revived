local var_0_0 = class("TranslationTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.translations_ = {}

	import("app.common.tables.TableParser").parse("translation.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.name
		local var_2_1 = arg_2_0.translation
		local var_2_2 = string.gsub(var_2_1, "|", "\n")

		assert(arg_1_0.translations_[var_2_0] == nil, string.format("Duplicate translation for key: %s", var_2_0))

		arg_1_0.translations_[var_2_0] = var_2_2
	end)
end

function var_0_0.translation(arg_3_0, arg_3_1)
	return arg_3_0.translations_[arg_3_1] or ""
end

return var_0_0
