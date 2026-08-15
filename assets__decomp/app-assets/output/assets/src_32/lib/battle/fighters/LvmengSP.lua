local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("LvmengSP", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = 40012082
local var_0_8 = 10001944
local var_0_9 = 180
local var_0_10 = {
	40012085,
	40012086
}
local var_0_11 = 90
local var_0_12 = 0.15
local var_0_13 = 0.001
local var_0_14 = 10002317
local var_0_15 = 80010249
local var_0_16 = 40012502
local var_0_17 = 30
local var_0_18 = 240

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.BlueBuffAddTimeSkill = 10002310
	else
		arg_1_0.BlueBuffAddTimeSkill = 10001946
	end
end

function var_0_3.ctor(arg_2_0, arg_2_1)
	var_0_3.super.ctor(arg_2_0, arg_2_1)
	arg_2_0:listenInfo("buff_info")
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.purpleCount = 0
	arg_3_0.bingdongCount = 0
	arg_3_0.skinCDCount = 0
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1:getTableID() == var_0_7 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_4_0 = var_0_8
			local var_4_1 = var_0_4.A8(arg_4_1.target, var_4_0)
			local var_4_2 = arg_4_0:createAttackUnits(var_4_1, var_4_0)

			for iter_4_0, iter_4_1 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1:getTableID() == var_0_16 and arg_4_0.skinSkillIndex_ == 1 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_3 = var_0_15
		local var_4_4 = var_0_4.B8(arg_4_0, var_4_3)
		local var_4_5 = arg_4_0:createAttackUnits(var_4_4, var_4_3)

		for iter_4_2, iter_4_3 in ipairs(var_4_5) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end
end

function var_0_3.buffAddAction(arg_5_0, arg_5_1)
	if arg_5_1:getTableID() == var_0_16 then
		arg_5_1.manualDharm = var_0_17 * arg_5_0:getLevel()
	end
end

function var_0_3.addBuffBySpecialHero(arg_6_0, arg_6_1)
	var_0_3.super.addBuffBySpecialHero(arg_6_0, arg_6_1)

	if arg_6_0.skinSkillIndex_ == 1 and arg_6_0.skinCDCount < 0 then
		for iter_6_0 = #arg_6_1, 1, -1 do
			local var_6_0 = arg_6_1[iter_6_0]
			local var_6_1 = var_6_0.fighter
			local var_6_2 = var_6_0.target

			if var_6_1 and var_6_1:getTeamType() == arg_6_0:getTeamType() and var_6_0:getTableID() ~= var_0_16 and var_0_6:dbuffType(var_6_0:getTableID()) == var_0_2.DBuffType.BING_DONG and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_3 = var_0_14
				local var_6_4 = arg_6_0:createAttackUnits({
					arg_6_0
				}, var_6_3)

				for iter_6_1, iter_6_2 in ipairs(var_6_4) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_2)
					table.insert(arg_6_0.records_.special_units, iter_6_2)
				end

				arg_6_0.skinCDCount = var_0_18

				break
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	if arg_7_1.skillID == arg_7_0.BlueBuffAddTimeSkill then
		local var_7_0 = arg_7_1.target:getBuffs()

		for iter_7_0 = #var_7_0, 1, -1 do
			local var_7_1 = var_7_0[iter_7_0]

			if var_7_1:getBuffForm() == var_0_2.BuffForm.DEBUFF then
				var_7_1:setLeftCount(var_7_1:getLeftCount() + var_0_9)
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_8_0)
	if arg_8_0:isDeath() then
		return
	end

	if arg_8_0.skinSkillIndex_ == 1 then
		arg_8_0.skinCDCount = arg_8_0.skinCDCount - 1
	end

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		if arg_8_0.purpleCount <= 0 then
			for iter_8_0, iter_8_1 in ipairs(arg_8_0:getInfoByKey("buff_info")) do
				if iter_8_1:dBuffType() == var_0_2.DBuffType.BING_DONG then
					local var_8_0 = arg_8_0:createNewBuffs(var_0_10, arg_8_0, arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

					arg_8_0:addBuffs(var_8_0)

					arg_8_0.purpleCount = var_0_11

					break
				end
			end
		else
			arg_8_0.purpleCount = arg_8_0.purpleCount - 1
		end

		if var_0_1.ctx.battle.count % 30 == 0 then
			local var_8_1 = 0

			for iter_8_2, iter_8_3 in ipairs(arg_8_0.selfTeam_) do
				if not iter_8_3:isDeath() and not iter_8_3:isAffected() then
					local var_8_2 = iter_8_3:getBuffs()

					for iter_8_4, iter_8_5 in ipairs(var_8_2) do
						if iter_8_5:dBuffType() == var_0_2.DBuffType.BING_DONG then
							var_8_1 = var_8_1 + 1
						end
					end
				end
			end

			for iter_8_6, iter_8_7 in ipairs(arg_8_0.sideTeam_) do
				if not iter_8_7:isDeath() and not iter_8_7:isAffected() then
					local var_8_3 = iter_8_7:getBuffs()

					for iter_8_8, iter_8_9 in ipairs(var_8_3) do
						if iter_8_9:dBuffType() == var_0_2.DBuffType.BING_DONG then
							var_8_1 = var_8_1 + 1
						end
					end
				end
			end

			arg_8_0.bingdongCount = var_8_1
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_0.bingdongCount > 0 and arg_9_4 > 0 then
		arg_9_4 = arg_9_4 * (1 + (var_0_12 + var_0_13 * arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)) * arg_9_0.bingdongCount)
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

return var_0_3
