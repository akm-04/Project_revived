local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40011921
local var_0_7 = 40011922
local var_0_8 = 40011927
local var_0_9 = 40011923
local var_0_10 = {
	40011924,
	40011925
}
local var_0_11 = {
	40011928,
	40011929
}
local var_0_12 = 40011926
local var_0_13 = 10001786
local var_0_14 = 10001787
local var_0_15 = 0.1
local var_0_16 = 0.005
local var_0_17 = 0.01

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.energyCount = 0
	arg_1_0.greenCount = 0
	arg_1_0.setReMp = false
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_2_0.setReMp then
		arg_2_0.setReMp = true

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfTeam_) do
			if iter_2_1.hero_:getHeroType() == var_0_2.HeroType.STRENGTH and not iter_2_1.setReMp then
				local var_2_0 = iter_2_1.getAttackedReEnergy

				iter_2_1.setReMp = true

				function iter_2_1.getAttackedReEnergy(arg_3_0)
					local var_3_0 = var_0_17 * arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

					if not arg_2_0.isStarPurple_ then
						var_3_0 = var_3_0 * 0.5
					end

					return var_2_0(arg_3_0) * (1 + var_3_0)
				end
			end
		end
	end

	for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
		if not iter_2_3:isDeath() and not iter_2_3:isAffected() and iter_2_3:isWalking() and iter_2_3:isHasBuffByID(var_0_6) then
			iter_2_3:removeBuffByID(var_0_6)

			local var_2_1

			if not arg_2_0.isStarEnergy_ then
				local var_2_2 = arg_2_0:createNewBuffs({
					var_0_7
				}, iter_2_3, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_2_3:addBuffs(var_2_2)
			else
				local var_2_3 = arg_2_0:createNewBuffs({
					var_0_7,
					var_0_8
				}, iter_2_3, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

				iter_2_3:addBuffs(var_2_3)
			end
		end
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_7 then
		local var_4_0 = arg_4_1.target
		local var_4_1 = arg_4_0:createNewBuffs({
			var_0_9
		}, var_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy))

		var_4_0:addBuffs(var_4_1)
	end
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_5_0.greenCount = arg_5_0.greenCount + 1

		if arg_5_0.greenCount < 5 then
			local var_5_0 = arg_5_0:createNewBuffs(var_0_10, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			arg_5_1.target:addBuffs(var_5_0)
		else
			local var_5_1 = arg_5_0:createNewBuffs(var_0_11, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			arg_5_1.target:addBuffs(var_5_1)
		end

		if arg_5_0.isStarGreen_ then
			local var_5_2 = arg_5_0:createNewBuffs({
				var_0_12
			}, arg_5_1.target, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			arg_5_1.target:addBuffs(var_5_2)
		end
	end
end

function var_0_3.beginAttackEnd(arg_6_0, arg_6_1)
	if arg_6_1.rootID_ == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		arg_6_0.greenCount = 0
	end

	var_0_3.super.beginAttackEnd(arg_6_0, arg_6_1)
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and arg_7_4 > 0 and var_0_5:skillType(arg_7_1.skillID) == var_0_2.SkillType.PU_GONG and arg_7_1.target:getTeamType() == arg_7_0:getTeamType() then
		local var_7_0 = var_0_15 + var_0_16 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue)

		if var_0_2.weightedChoise({
			var_7_0,
			1 - var_7_0
		}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_1

			if arg_7_0.isStarBlue_ then
				var_7_1 = var_0_14
			else
				var_7_1 = var_0_13
			end

			local var_7_2 = arg_7_0:createAttackUnits({
				arg_7_1.fighter
			}, var_7_1, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue))

			for iter_7_0, iter_7_1 in ipairs(var_7_2) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

return var_0_3
