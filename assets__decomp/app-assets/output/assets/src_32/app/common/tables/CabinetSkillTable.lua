local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("CabinetSkillTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.desc2_ = {}
	arg_1_0.skillbook_ = {}
	arg_1_0.partner_ = {}
	arg_1_0.time_ = {}
	arg_1_0.lastSkill_ = {}
	arg_1_0.afterSkill_ = {}
	arg_1_0.posX_ = {}
	arg_1_0.posY_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.attr_values_ = {}
	arg_1_0.attr_ids_ = {}
	arg_1_0.cost_res_type_ = {}
	arg_1_0.partner_to_skill_ = {}
	arg_1_0.action_type = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("event_centre_cabinetskill.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("event_centre_cabinetskill", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.id)

	arg_2_0.name_[var_2_0] = arg_2_1.name
	arg_2_0.desc_[var_2_0] = arg_2_1.desc
	arg_2_0.desc2_[var_2_0] = arg_2_1.desc2
	arg_2_0.skillbook_[var_2_0] = tonumber(arg_2_1.skillbook)
	arg_2_0.partner_[var_2_0] = tonumber(arg_2_1.partner)
	arg_2_0.time_[var_2_0] = var_0_1.splitToNumber(arg_2_1.time, "|")
	arg_2_0.lastSkill_[var_2_0] = var_0_1.splitToNumber(arg_2_1.last_skill, "|")
	arg_2_0.afterSkill_[var_2_0] = var_0_1.splitToNumber(arg_2_1.after_skill, "|")
	arg_2_0.posX_[var_2_0] = tonumber(arg_2_1.x)
	arg_2_0.posY_[var_2_0] = tonumber(arg_2_1.y)
	arg_2_0.icon_[var_2_0] = arg_2_1.icon
	arg_2_0.attr_values_[var_2_0] = tonumber(arg_2_1.attr_values)
	arg_2_0.attr_ids_[var_2_0] = tonumber(arg_2_1.attr_ids)
	arg_2_0.cost_res_type_[var_2_0] = tonumber(arg_2_1.cost_res_type)
	arg_2_0.action_type[var_2_0] = tonumber(arg_2_1.action_type)

	if arg_2_0.partner_to_skill_[arg_2_0.partner_[var_2_0]] == nil then
		arg_2_0.partner_to_skill_[arg_2_0.partner_[var_2_0]] = {}
	end

	table.insert(arg_2_0.partner_to_skill_[arg_2_0.partner_[var_2_0]], var_2_0)
end

function var_0_2.partnerSkills(arg_3_0, arg_3_1)
	return arg_3_0.partner_to_skill_[arg_3_1] or {}
end

function var_0_2.icon(arg_4_0, arg_4_1)
	return arg_4_0.icon_[arg_4_1] or ""
end

function var_0_2.name(arg_5_0, arg_5_1)
	return arg_5_0.name_[arg_5_1] or ""
end

function var_0_2.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1] or ""
end

function var_0_2.desc2(arg_7_0, arg_7_1)
	return arg_7_0.desc2_[arg_7_1] or "%d"
end

function var_0_2.skillbook(arg_8_0, arg_8_1)
	return arg_8_0.skillbook_[arg_8_1] or 0
end

function var_0_2.partner(arg_9_0, arg_9_1)
	return arg_9_0.partner_[arg_9_1] or 0
end

function var_0_2.time(arg_10_0, arg_10_1)
	return arg_10_0.time_[arg_10_1] or {}
end

function var_0_2.lastSkill(arg_11_0, arg_11_1)
	if arg_11_0.lastSkill_[arg_11_1][1] and arg_11_0.lastSkill_[arg_11_1][1] == 0 then
		return {}
	end

	return arg_11_0.lastSkill_[arg_11_1] or {}
end

function var_0_2.afterSkill(arg_12_0, arg_12_1)
	return arg_12_0.afterSkill_[arg_12_1] or {}
end

function var_0_2.costRes(arg_13_0, arg_13_1)
	return arg_13_0.costRes_[arg_13_1] or {}
end

function var_0_2.costNum(arg_14_0, arg_14_1)
	return arg_14_0.costNum_[arg_14_1] or {}
end

function var_0_2.posX(arg_15_0, arg_15_1)
	return arg_15_0.posX_[arg_15_1] or 0
end

function var_0_2.posY(arg_16_0, arg_16_1)
	return arg_16_0.posY_[arg_16_1] or 0
end

function var_0_2.attrValues(arg_17_0, arg_17_1)
	return arg_17_0.attr_values_[arg_17_1] or 0
end

function var_0_2.attrIds(arg_18_0, arg_18_1)
	return arg_18_0.attr_ids_[arg_18_1] or 0
end

function var_0_2.costResType(arg_19_0, arg_19_1)
	return arg_19_0.cost_res_type_[arg_19_1] or 1
end

function var_0_2.actionType(arg_20_0, arg_20_1)
	return arg_20_0.action_type[arg_20_1] or 0
end

return var_0_2
