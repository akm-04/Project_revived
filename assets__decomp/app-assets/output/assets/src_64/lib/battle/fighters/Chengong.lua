local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Chengong", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = 80010020
local var_0_6 = 10001533
local var_0_7 = 10001534
local var_0_8 = 10001535
local var_0_9 = 0.001

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if arg_2_0.skinSkillID_ == var_0_5 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("buff_info")) do
			if iter_2_1.fighter:getTeamType() == arg_2_0:getTeamType() and (iter_2_1:dBuffType() > 0 or iter_2_1:getBuffForm() == var_0_2.BuffForm.DEBUFF) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_2_0 = arg_2_0:createAttackUnits({
					arg_2_0
				}, var_0_6)

				for iter_2_2, iter_2_3 in ipairs(var_2_0) do
					table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
					table.insert(arg_2_0.records_.special_units, iter_2_3)
				end
			end

			if iter_2_1.fighter == arg_2_0 and iter_2_1:dBuffType() == var_0_2.DBuffType.ZHI_MANG then
				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_2_1 = arg_2_0:createAttackUnits({
						iter_2_1.target
					}, var_0_7)

					for iter_2_4, iter_2_5 in ipairs(var_2_1) do
						table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
						table.insert(arg_2_0.records_.special_units, iter_2_5)
					end
				end

				local var_2_2 = {}
				local var_2_3 = var_0_4:scope(var_0_8) / 2

				for iter_2_6, iter_2_7 in ipairs(arg_2_0.targetTeam_) do
					if not iter_2_7:isDeath() and not iter_2_7:isAffected() and var_2_3 > math.abs(iter_2_7:getX() - iter_2_1.target:getX()) then
						table.insert(var_2_2, iter_2_7)
					end
				end

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_2_4 = arg_2_0:createAttackUnits(var_2_2, var_0_8)

					for iter_2_8, iter_2_9 in ipairs(var_2_4) do
						table.insert(arg_2_0.moveAttackUnits_, iter_2_9)
						table.insert(arg_2_0.records_.special_units, iter_2_9)
					end
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_7 then
		arg_3_7 = arg_3_7 - arg_3_0:getLevel() * var_0_9 * arg_3_1.target:getEnergy()
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

return var_0_3
