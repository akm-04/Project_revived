local var_0_0 = class("LibraryDiaryTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.words_ = {}

	import("app.common.tables.TableParser").parse("library_diary.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.words_[var_2_0] = arg_2_0.content
	end)
end

function var_0_0.words(arg_3_0, arg_3_1)
	return arg_3_0.words_[arg_3_1] or nil
end

return var_0_0
