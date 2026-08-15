local var_0_0 = class("ZhugeNoteTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.type_ = {}
	arg_1_0.battleID_ = {}
	arg_1_0.skillTitle1_ = {}
	arg_1_0.skillTitle2_ = {}
	arg_1_0.skillTranslation1_ = {}
	arg_1_0.skillTranslation2_ = {}

	import("app.common.tables.TableParser").parse("zhuge_note.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.battleID_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.skillTitle1_[var_2_0] = arg_2_0.skill_title1
		arg_1_0.skillTitle2_[var_2_0] = arg_2_0.skill_title2
		arg_1_0.skillTranslation1_[var_2_0] = arg_2_0.skill_translation1
		arg_1_0.skillTranslation2_[var_2_0] = arg_2_0.skill_translation2
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or {}
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.type_[arg_5_1] or 0
end

function var_0_0.battleID(arg_6_0, arg_6_1)
	return arg_6_0.battleID_[arg_6_1] or 0
end

function var_0_0.getSkill(arg_7_0, arg_7_1)
	local var_7_0 = {}

	table.insert(var_7_0, {
		title = arg_7_0.skillTitle1_[arg_7_1],
		desc = arg_7_0.skillTranslation1_[arg_7_1]
	})
	table.insert(var_7_0, {
		title = arg_7_0.skillTitle2_[arg_7_1],
		desc = arg_7_0.skillTranslation2_[arg_7_1]
	})

	return var_7_0 or {}
end

return var_0_0
