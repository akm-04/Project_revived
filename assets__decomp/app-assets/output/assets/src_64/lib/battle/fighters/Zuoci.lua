local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zuoci", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = var_0_2.tables.dbuff
local var_0_10 = 80010064
local var_0_11 = 40011294
local var_0_12 = 0.1
local var_0_13 = 10010111
local var_0_14 = 10001175
local var_0_15 = 20010159
local var_0_16 = 40011938
local var_0_17 = 40011937
local var_0_18 = 0.3
local var_0_19 = 80020064

function var_0_3.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
	if arg_1_2 > arg_1_0:getHpLimit() * var_0_12 and arg_1_0.isSkinSkillOn_ and arg_1_0.skinSkillID_ == var_0_10 then
		local var_1_0 = arg_1_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

		if var_1_0 < 1 then
			var_1_0 = 1
		end

		arg_1_0:setImmuneControl(true)
		arg_1_0:createSkillByID(var_0_14, var_1_0, 4)

		local var_1_1 = var_0_7.new({
			level = 1,
			tableID = var_0_11,
			start = var_0_1.ctx.battle.count,
			skillID = var_0_10,
			fighter = arg_1_0,
			target = arg_1_0
		})

		arg_1_0:addBuffs({
			var_1_1
		})
	end

	return var_0_3.super.applyHurtFighter(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4, arg_1_5)
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_14 and arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_10 then
		arg_2_0:setImmuneControl(false)
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_19 then
		local var_2_0 = var_0_18

		if var_0_2.weightedChoise({
			var_2_0,
			1 - var_2_0
		}) == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_2_1 = arg_2_0:createAttackUnits({
				arg_2_1.target
			}, var_0_19)

			for iter_2_0, iter_2_1 in ipairs(var_2_1) do
				table.insert(arg_2_0.moveAttackUnits_, iter_2_1)
				table.insert(arg_2_0.records_.special_units, iter_2_1)
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	local var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if var_3_2 > 0 and arg_3_1.skillID ~= var_0_10 and arg_3_0.isSkinSkillOn_ and arg_3_0.skinSkillID_ == var_0_10 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_3_6 = arg_3_0:selectTargetByTypeD1(arg_3_1.target)
		local var_3_7 = arg_3_0:createAttackUnits(var_3_6, var_0_10)

		for iter_3_0, iter_3_1 in ipairs(var_3_7) do
			iter_3_1.totalHarm = var_3_2

			table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
			table.insert(arg_3_0.records_.special_units, iter_3_1)
		end
	end

	if arg_3_1.skillID == var_0_10 and arg_3_1.totalHarm then
		var_3_2 = arg_3_1.totalHarm
	end

	return var_3_0, var_3_1, var_3_2, var_3_3, var_3_4, var_3_5
end

function var_0_3.selectTargetByTypeD1(arg_4_0, arg_4_1)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() and not iter_4_1:isAffected() and iter_4_1 ~= arg_4_1 then
			local var_4_1 = iter_4_1:getBuffs()

			for iter_4_2, iter_4_3 in ipairs(var_4_1) do
				if var_0_9:dbuffType(iter_4_3:getTableID()) == var_0_2.DBuffType.CHEN_MO then
					table.insert(var_4_0, iter_4_1)

					break
				end
			end
		end
	end

	return var_4_0
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0.isSkinSkillOn_ and arg_5_0.skinSkillID_ == var_0_19 and var_0_1.ctx.battle.count % 30 == 0 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_1:isApUnable() and iter_5_1:isHasBuffByID(var_0_16) then
				iter_5_1:removeBuffByID(var_0_16)
			end
		end

		if arg_5_0:isDeath() then
			return
		end

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
			if iter_5_3:isApUnable() and not iter_5_3:isHasBuffByID(var_0_15) and not iter_5_3:isHasBuffByID(var_0_16) then
				local var_5_0 = arg_5_0:createNewBuffs({
					var_0_16
				}, iter_5_3, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

				iter_5_3:addBuffs(var_5_0)
			end
		end
	end
end

return var_0_3
