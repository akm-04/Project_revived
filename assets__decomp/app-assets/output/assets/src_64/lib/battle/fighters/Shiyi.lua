local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Shiyi", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 0
local var_0_6 = 0.0005
local var_0_7 = 10001618
local var_0_8 = 10
local var_0_9 = 40011711
local var_0_10 = 40011710
local var_0_11 = 0.5
local var_0_12 = 40011714
local var_0_13 = 10001622
local var_0_14 = 0
local var_0_15 = 0.0001
local var_0_16 = 5000

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.lovePoint = {}

	arg_1_0:listenInfo("death_info")

	arg_1_0.lovee = nil
	arg_1_0.lover = nil
end

function var_0_3.toDoPerFrames(arg_2_0)
	for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("death_info")) do
		if iter_2_1 == arg_2_0.lovee and not arg_2_0.lover:isDeath() and arg_2_0.lover:isHasBuffByID(var_0_12) and arg_2_0:isPVP() then
			arg_2_0.lover:forceDie()
		end
	end
end

function var_0_3.updateLovePointBy(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.lovePoint[arg_3_1] = math.min((arg_3_0.lovePoint[arg_3_1] or 0) + arg_3_2, var_0_16 * arg_3_0:getLevel())
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		if arg_4_1.target:getTeamType() == arg_4_0:getTeamType() then
			arg_4_1.target:removeBuffByID(var_0_9)
		else
			arg_4_1.target:removeBuffByID(var_0_10)
		end
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		for iter_4_0, iter_4_1 in ipairs(arg_4_1.target:getBuffs()) do
			if iter_4_1:getTableID() == var_0_12 and iter_4_1.fighter == arg_4_0 then
				local var_4_0

				for iter_4_2, iter_4_3 in ipairs(arg_4_0.sideTeam_) do
					if not iter_4_3:isDeath() and not iter_4_3:isAffected() and (not var_4_0 or (arg_4_0.lovePoint[var_4_0] or 0) < (arg_4_0.lovePoint[iter_4_3] or 0)) then
						var_4_0 = iter_4_3
					end
				end

				if var_4_0 then
					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_4_1 = arg_4_0:createAttackUnits({
							var_4_0
						}, var_0_13)

						for iter_4_4, iter_4_5 in ipairs(var_4_1) do
							table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
							table.insert(arg_4_0.records_.special_units, iter_4_5)
						end
					end

					if arg_4_0.lovee then
						arg_4_0.lovee:removeBuffByID(var_0_12)
					end

					if arg_4_0.lover then
						arg_4_0.lover:removeBuffByID(var_0_12)
					end

					arg_4_0.lovee = arg_4_1.target
					arg_4_0.lover = var_4_0

					break
				end

				arg_4_1.target:removeBuffs(iter_4_1)

				break
			end
		end
	end
end

function var_0_3.unitAfterCreate(arg_5_0, arg_5_1, arg_5_2)
	if arg_5_2[1] and arg_5_2[1].skillID == var_0_7 then
		for iter_5_0, iter_5_1 in ipairs(arg_5_2) do
			arg_5_0:updateLovePointBy(iter_5_1.target, var_0_8 * arg_5_0:getAP())
			iter_5_1:setExtraHarm((var_0_5 + var_0_6 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)) * arg_5_0.lovePoint[iter_5_1.target])
		end

		arg_5_0.lovePoint = {}
	end
end

function var_0_3.selectTargetByTypeD2(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() then
			table.insert(var_6_0, iter_6_1)
		end
	end

	for iter_6_2, iter_6_3 in ipairs(arg_6_0.sideTeam_) do
		if not iter_6_3:isDeath() and not iter_6_3:isAffected() then
			table.insert(var_6_0, iter_6_3)
		end
	end

	if #var_6_0 > 0 then
		local var_6_1 = math.random(tonumber(os.time()))

		math.randomseed(var_6_1)

		return {
			var_6_0[math.random(#var_6_0)]
		}
	else
		return {}
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = arg_7_1.target:getBuffByID(var_0_12)

	if var_7_0 and var_7_0.fighter == arg_7_0 and var_7_0.ShiyiLover == arg_7_1.fighter then
		arg_7_4 = 0
	end

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() and arg_7_1.fighter:getTeamType() == arg_7_0:getTeamType() and arg_7_4 > 0 then
		arg_7_4 = arg_7_4 + ((arg_7_0.lovePoint[arg_7_1.fighter] or 0) + (arg_7_0.lovePoint[arg_7_1.target] or 0)) * (var_0_14 + var_0_15 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple))
	end

	return var_0_3.super.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
end

function var_0_3.updateUnitInfoBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		arg_8_0:updateLovePointBy(arg_8_1.fighter, math.max(arg_8_4, arg_8_5) * var_0_11)
	end
end

function var_0_3.selectTargetByTypeD3(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and (not var_9_0 or (arg_9_0.lovePoint[var_9_0] or 0) < (arg_9_0.lovePoint[iter_9_1] or 0)) then
			var_9_0 = iter_9_1
		end
	end

	return {
		var_9_0
	}
end

return var_0_3
