local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Pet", var_0_1.ctx.battle.getRequire("BasePet"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 0
local var_0_7 = 0.05
local var_0_8 = 0.001
local var_0_9 = 0.1

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.energySkillTime = 0
	arg_2_0.records_.purple_buff_remove = {}
	arg_2_0.awakenBuffTargets_ = {}
end

function var_0_3.toDoPerFrames(arg_3_0)
	local var_3_0 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)

	if var_3_0 > 0 then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target and not iter_3_1.target:isDeath() and iter_3_1.target:getTeamType() == arg_3_0:getTeamType() and iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_3_1:canRemove() then
				local var_3_1 = false

				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if arg_3_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)] and type(arg_3_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)]) == "table" and arg_3_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex] and arg_3_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex][1] == iter_3_1:getTableID() then
						var_3_1 = true

						table.remove(arg_3_0.purpleBuffRemove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex], 1)
					end
				else
					local var_3_2 = arg_3_0:getChance(var_3_0)
					local var_3_3 = math.min(1, var_3_2)

					var_3_1 = var_0_2.weightedChoise({
						var_3_3,
						1 - var_3_3
					}) == 1

					if var_3_1 then
						if not arg_3_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)] then
							arg_3_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)] = {}
						end

						if not arg_3_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex] then
							arg_3_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex] = {}
						end

						table.insert(arg_3_0.records_.purple_buff_remove[tostring(var_0_1.ctx.battle.count)][iter_3_1.target.fighterIndex], iter_3_1:getTableID())
					end
				end

				if var_3_1 then
					iter_3_1.target:removeBuffs(iter_3_1)
					table.insert(arg_3_0.awakenBuffTargets_, iter_3_1.target)
				end
			end
		end
	end

	local var_3_4 = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green)

	if not (var_3_4 > 0) or var_0_1.ctx.battle.count % 30 >= 1 then
		-- block empty
	else
		local var_3_5 = var_0_6 + var_0_7 * var_3_4

		for iter_3_2, iter_3_3 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_3:isDeath() and not iter_3_3:isAffected() then
				iter_3_3:updateEnergyBy(var_3_5)
			end
		end
	end
end

function var_0_3.getChance(arg_4_0, arg_4_1)
	local var_4_0 = var_0_8 * arg_4_1 + var_0_9

	if arg_4_0.isStarPurple_ then
		local var_4_1 = arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
		local var_4_2 = var_0_5:desc4NumStep(var_4_1)[2]

		var_4_0 = arg_4_1 * var_4_2 / 100 + var_4_0
	end

	return var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_5_0 = arg_5_1.target:getBuffs()

		for iter_5_0 = 1, #var_5_0 do
			local var_5_1 = var_5_0[iter_5_0]

			if var_5_1 and var_5_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_5_1:canRemove() then
				arg_5_1.target:removeBuffs(var_5_1)
				table.insert(arg_5_0.awakenBuffTargets_, arg_5_1.target)

				break
			end
		end
	elseif arg_5_1.skillID == arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		local var_5_2 = arg_5_1.target:getBuffs()
		local var_5_3 = 0
		local var_5_4 = false

		for iter_5_1 = #var_5_2, 1, -1 do
			local var_5_5 = var_5_2[iter_5_1]

			if var_5_5 and var_5_5:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_5_5:canRemove() then
				local var_5_6 = var_5_5:getStartTime()
				local var_5_7 = var_0_1.ctx.battle.count - var_5_6

				var_5_3 = var_5_7 < var_5_3 and var_5_3 or var_5_7

				arg_5_1.target:removeBuffs(var_5_5)

				if not var_5_4 then
					var_5_4 = true

					table.insert(arg_5_0.awakenBuffTargets_, arg_5_1.target)
				end
			end
		end

		arg_5_0.energySkillTime = var_5_3
	end
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.purpleBuffRemove = arg_6_1.purple_buff_remove
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.purple_buff_remove = arg_7_0.records_.purple_buff_remove

	return var_7_0
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	var_0_3.super.buffAddAction(arg_8_0, arg_8_1)

	if arg_8_1:getSkillID() == arg_8_0:getEnergySkillID() then
		local var_8_0 = arg_8_0.energySkillTime

		arg_8_1:setExtraTime(var_8_0)
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	if arg_9_0.isStarEnergy_ and arg_9_1.skillID == arg_9_0:getEnergySkillID() then
		local var_9_0 = var_0_5:desc4NumStep(arg_9_1.skillID)[2]

		arg_9_5 = arg_9_0:getSkillLevelByID(arg_9_1.skillID) * var_9_0 * arg_9_5 * 0.01 + arg_9_5
	elseif arg_9_0.isStarBlue_ and arg_9_1.skillID == arg_9_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		local var_9_1 = var_0_5:desc4NumStep(arg_9_1.skillID)[2]

		arg_9_5 = arg_9_0:getSkillLevelByID(arg_9_1.skillID) * var_9_1 + arg_9_5
	end

	return var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
end

return var_0_3
