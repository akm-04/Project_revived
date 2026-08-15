local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("XiahoujuanSmallBlueCotton", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_6 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_7 = var_0_2.tables.skill
local var_0_8 = math.abs
local var_0_9 = math.min
local var_0_10 = 10001251
local var_0_11 = 100
local var_0_12 = 60
local var_0_13 = 2

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.checkMove(arg_2_0)
	return false
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.attackCount = 0
	arg_3_0.flyCount = 0
end

function var_0_3.isAffected(arg_4_0)
	return true
end

function var_0_3.toDoPerFrames(arg_5_0)
	local var_5_0 = false

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
		if not iter_5_1:isDeath() or iter_5_1:canReborn() then
			var_5_0 = true
		end
	end

	if not var_5_0 then
		arg_5_0:updateHp(0)
		arg_5_0:die()
	end

	if arg_5_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.walk2NextBattle_ then
		arg_5_0:updateHp(0)
		arg_5_0:die()

		return
	end

	arg_5_0.flyCount = arg_5_0.flyCount - 1

	for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
		if iter_5_3:getTeamType() ~= arg_5_0:getTeamType() and not iter_5_3:isDeath() and not iter_5_3:isAffected() and math.abs(iter_5_3:getX() - arg_5_0:getX()) <= var_0_11 and math.abs(iter_5_3:getY() - arg_5_0:getY()) <= var_0_11 and arg_5_0.attackCount < var_0_13 and arg_5_0.flyCount <= 0 then
			arg_5_0.attackCount = arg_5_0.attackCount + 1
			arg_5_0.flyCount = var_0_12

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_5_1 = arg_5_0:createAttackUnits({
					iter_5_3
				}, var_0_10)

				for iter_5_4, iter_5_5 in ipairs(var_5_1) do
					table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
					table.insert(arg_5_0.records_.special_units, iter_5_5)
				end
			end
		end
	end

	if arg_5_0.attackCount >= var_0_13 then
		arg_5_0:die()
	end
end

return var_0_3
