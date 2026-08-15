local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = var_0_0.getXinyoudi(ngx)
local var_0_2 = var_0_0.class("SkinSkillTable")

function var_0_2.ctor(arg_1_0)
	arg_1_0.skinID_ = {}
	arg_1_0.heroID_ = {}
	arg_1_0.skillID_ = {}
	arg_1_0.skinNum_ = {}
	arg_1_0.modelID_ = {}
	arg_1_0.modelIDs_ = {}
	arg_1_0.rare_ = {}

	if isClient then
		var_0_0.import("app.common.tables.TableParser").parse("skin_skill.lua", var_0_0.handler(arg_1_0, arg_1_0.parse))
	else
		var_0_0.import("lib.battle.app.common.tables.TableParser").parse("skin_skill", var_0_0.handler(arg_1_0, arg_1_0.parse))
	end
end

function var_0_2.parse(arg_2_0, arg_2_1)
	local var_2_0 = tonumber(arg_2_1.skin_id)

	table.insert(arg_2_0.skinID_, var_2_0)

	arg_2_0.heroID_[var_2_0] = tonumber(arg_2_1.hero)
	arg_2_0.skillID_[var_2_0] = tonumber(arg_2_1.skill)
	arg_2_0.skinNum_[var_2_0] = tonumber(arg_2_1.skin_numb)
	arg_2_0.modelID_[var_2_0] = tonumber(arg_2_1.model)
	arg_2_0.modelIDs_[var_2_0] = var_0_1.splitToNumber(arg_2_1.modelids, "|")
	arg_2_0.rare_[var_2_0] = tonumber(arg_2_1.rare)
end

function var_0_2.getSkinID(arg_3_0)
	return arg_3_0.skinID_
end

function var_0_2.getHeroID(arg_4_0, arg_4_1)
	return arg_4_0.heroID_[arg_4_1]
end

function var_0_2.getSkillID(arg_5_0, arg_5_1)
	return arg_5_0.skillID_[arg_5_1]
end

function var_0_2.getSkinNum(arg_6_0, arg_6_1)
	return arg_6_0.skinNum_[arg_6_1]
end

function var_0_2.getModelID(arg_7_0, arg_7_1)
	return arg_7_0.modelID_[arg_7_1]
end

function var_0_2.getModelIDs(arg_8_0, arg_8_1)
	return arg_8_0.modelIDs_[arg_8_1]
end

function var_0_2.getRareLev(arg_9_0, arg_9_1)
	return arg_9_0.rare_[arg_9_1]
end

return var_0_2
