local var_0_0 = class("SkillLevelTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.color_ = {}
	arg_1_0.start_ = {}
	arg_1_0.awakenSkill_ = {}
	arg_1_0.bookOpen_ = {}

	import("app.common.tables.TableParser").parse("skill_level.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.color_[var_2_0] = tonumber(arg_2_0.color)
		arg_1_0.start_[var_2_0] = tonumber(arg_2_0.start)
		arg_1_0.awakenSkill_[var_2_0] = tonumber(arg_2_0.awaken_skill)
		arg_1_0.bookOpen_[var_2_0] = tonumber(arg_2_0.book_open)
	end)
end

function var_0_0.color(arg_3_0, arg_3_1)
	return arg_3_0.color_[arg_3_1] or 0
end

function var_0_0.start(arg_4_0, arg_4_1)
	return arg_4_0.start_[arg_4_1] or 0
end

function var_0_0.awakenSkill(arg_5_0, arg_5_1)
	return arg_5_0.awakenSkill_[arg_5_1] or 0
end

function var_0_0.bookOpen(arg_6_0, arg_6_1)
	return arg_6_0.bookOpen_[arg_6_1] or 0
end

return var_0_0
