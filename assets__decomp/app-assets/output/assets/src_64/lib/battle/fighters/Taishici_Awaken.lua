local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Taishici", var_0_1.ctx.battle.requireFighter("Taishici"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 20010013
local var_0_7 = 40011797
local var_0_8 = 40011798
local var_0_9 = 40011799
local var_0_10 = 40011800
local var_0_11 = 21010030

function var_0_3.buffAddAction(arg_1_0, arg_1_1)
	var_0_3.super.buffAddAction(arg_1_0, arg_1_1)

	if arg_1_1:getTableID() == var_0_6 then
		arg_1_0:addBuffs({
			var_0_4.new({
				tableID = var_0_7,
				start = var_0_1.ctx.battle.count,
				level = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
				skillID = arg_1_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
				fighter = arg_1_0,
				target = arg_1_0
			})
		})
	end
end

function var_0_3.deathFeedback(arg_2_0, arg_2_1)
	if arg_2_1.killer_ == arg_2_0 then
		arg_2_0:createSkillByID(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue), var_0_5:attackIndex(arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)))

		if arg_2_1:getSummonType() == var_0_2.summonMonsterType.None then
			arg_2_0:addBuffs({
				var_0_4.new({
					tableID = var_0_8,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_2_0,
					target = arg_2_0
				}),
				var_0_4.new({
					tableID = var_0_9,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_2_0,
					target = arg_2_0
				})
			})
		else
			arg_2_0:addBuffs({
				var_0_4.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
					skillID = arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
					fighter = arg_2_0,
					target = arg_2_0
				})
			})
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_3_0)
	local var_3_0 = var_0_3.super.getOrbOfFrontSkill(arg_3_0)

	if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.AwakeTwice) > 0 and (var_3_0 == var_0_11 or var_0_5:father(var_3_0) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green)) then
		var_3_0 = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.AwakeTwice)

		if arg_3_0.hero_.isSkinOn_ and arg_3_0.hero_.isSkinOn_ ~= 0 or arg_3_0.isSkinSkillOn_ then
			var_3_0 = var_0_5:skinSkill(var_3_0, arg_3_0.skinSkillIndex_)
		end
	end

	return var_3_0
end

return var_0_3
