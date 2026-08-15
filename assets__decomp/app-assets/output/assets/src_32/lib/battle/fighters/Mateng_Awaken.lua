local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mateng", var_0_1.ctx.battle.requireFighter("Mateng"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 10001262
local var_0_9 = 40011327
local var_0_10 = 10001258
local var_0_11 = 80010203
local var_0_12 = 0.3

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 1 then
		arg_3_0.AwakeSkillID = 10002231
		arg_3_0.EnergyBuff1 = 40012379
		arg_3_0.AwakeBuffID = 40012381
	else
		arg_3_0.AwakeSkillID = 60010203
		arg_3_0.EnergyBuff1 = 40011326
		arg_3_0.AwakeBuffID = 40011335
	end
end

function var_0_3.toDoPerFrames(arg_4_0)
	var_0_3.super.toDoPerFrames(arg_4_0)

	for iter_4_0, iter_4_1 in ipairs(arg_4_0:getInfoByKey("buff_info")) do
		local var_4_0 = iter_4_1.target

		if var_4_0 and not var_4_0:isDeath() and var_4_0:getTeamType() == arg_4_0:getTeamType() and var_4_0:isHasBuffByID(arg_4_0.AwakeBuffID) and var_0_6:dbuffType(iter_4_1:getTableID()) > 0 then
			local var_4_1 = var_0_5.new({
				tableID = iter_4_1:getTableID(),
				start = var_0_1.ctx.battle.count,
				level = iter_4_1.level_,
				skillID = iter_4_1.skillID_,
				fighter = iter_4_1.fighter,
				target = arg_4_0
			})

			arg_4_0:addBuffs({
				var_4_1
			})
			var_4_0:removeBuffs(iter_4_1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == arg_5_0.EnergyBuff1 and not arg_5_0.energyBuffJudge then
		arg_5_0.energyBuffJudge = true

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = arg_5_0:selectTargetByTypeD2()
			local var_5_1 = arg_5_0:createAttackUnits(var_5_0, var_0_10)

			for iter_5_0, iter_5_1 in ipairs(var_5_1) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end

			local var_5_2 = arg_5_0:selectTargetByTypeD3()
			local var_5_3 = arg_5_0:createAttackUnits(var_5_2, arg_5_0.AwakeSkillID)

			for iter_5_2, iter_5_3 in ipairs(var_5_3) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
				table.insert(arg_5_0.records_.special_units, iter_5_3)
			end

			local var_5_4 = arg_5_0:createAttackUnits({
				arg_5_0
			}, var_0_8)

			for iter_5_4, iter_5_5 in ipairs(var_5_4) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
				table.insert(arg_5_0.records_.special_units, iter_5_5)
			end

			if arg_5_0.skinSkillIndex_ == 1 then
				local var_5_5 = arg_5_0:createAttackUnits(var_0_4.A2(arg_5_0, var_0_11), var_0_11)

				for iter_5_6, iter_5_7 in ipairs(var_5_5) do
					iter_5_7.extraHarm = math.max(arg_5_0.EnergyBuff2Harm * var_0_12, 0)

					table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
					table.insert(arg_5_0.records_.special_units, iter_5_7)
				end
			end
		end
	elseif arg_5_1:getTableID() == var_0_9 then
		arg_5_0.EnergyBuff2Harm = 0
	end
end

function var_0_3.selectTargetByTypeD3(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1 ~= arg_6_0 and iter_6_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_6_0, iter_6_1)
		end
	end

	return var_6_0
end

return var_0_3
