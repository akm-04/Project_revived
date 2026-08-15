local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xuhuang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.dbuff
local var_0_6 = 80010027
local var_0_7 = 10001327
local var_0_8 = 10001326
local var_0_9 = 0.15
local var_0_10 = 200

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.accumulatedHarm = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_3_0.skinSkillID_ == var_0_6 then
		if arg_3_0:isDeath() then
			return
		end

		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1.target:getTeamType() ~= arg_3_0:getTeamType() and var_0_5:dbuffType(iter_3_1:getTableID()) == var_0_2.DBuffType.XUAN_YUN then
				local var_3_0 = arg_3_0:createAttackUnits({
					arg_3_0
				}, var_0_7)

				for iter_3_2, iter_3_3 in ipairs(var_3_0) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end

		for iter_3_4, iter_3_5 in ipairs(arg_3_0:getInfoByKey("harm_info")) do
			if iter_3_5.target == arg_3_0 then
				arg_3_0.accumulatedHarm = arg_3_0.accumulatedHarm + iter_3_5.harm
			end
		end

		if arg_3_0.accumulatedHarm >= arg_3_0:getHpLimit() * var_0_9 then
			local var_3_1 = {}
			local var_3_2 = arg_3_0:getX() - var_0_10
			local var_3_3 = arg_3_0:getX() + var_0_10

			for iter_3_6, iter_3_7 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_7:isDeath() and not iter_3_7:isAffected() and var_3_2 < iter_3_7:getX() and var_3_3 > iter_3_7:getX() then
					table.insert(var_3_1, iter_3_7)
				end
			end

			local var_3_4 = arg_3_0:createAttackUnits(var_3_1, var_0_8)

			for iter_3_8, iter_3_9 in ipairs(var_3_4) do
				table.insert(arg_3_0.moveAttackUnits_, iter_3_9)
				table.insert(arg_3_0.records_.special_units, iter_3_9)
			end

			arg_3_0.accumulatedHarm = 0
		end
	end
end

return var_0_3
