local var_0_0 = class("PetSkillBookTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.skillbook_ = {}

	import("app.common.tables.TableParser").parse("pet_skillbook.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.skill_level)

		arg_1_0.skillbook_[var_2_0] = tonumber(arg_2_0.skillbook)
	end)
end

function var_0_0.getBookNum(arg_3_0, arg_3_1)
	return arg_3_0.skillbook_[arg_3_1] or 0
end

return var_0_0
