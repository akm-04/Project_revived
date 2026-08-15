local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huatuo", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = 450
local var_0_6 = var_0_2.tables.elementEquip
local var_0_7 = 20001433

function var_0_3.toDoPerFrames(arg_1_0)
	if arg_1_0:isDeath() then
		return
	end

	if arg_1_0.isSkinSkillOn_ and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and var_0_1.ctx.battle.count % var_0_5 < 1 then
		local var_1_0
		local var_1_1

		for iter_1_0, iter_1_1 in ipairs(arg_1_0.selfTeam_) do
			if not iter_1_1:isDeath() and not iter_1_1:isAffected() and iter_1_1:getSummonType() == var_0_2.summonMonsterType.None then
				local var_1_2 = iter_1_1:getHp() / iter_1_1:getHpLimit()

				if not var_1_1 or var_1_2 < var_1_1 then
					var_1_0 = iter_1_1
					var_1_1 = var_1_2
				end
			end
		end

		local var_1_3 = arg_1_0:createAttackUnits({
			var_1_0
		}, arg_1_0.skinSkillID_)

		for iter_1_2, iter_1_3 in ipairs(var_1_3) do
			table.insert(arg_1_0.moveAttackUnits_, iter_1_3)
			table.insert(arg_1_0.records_.special_units, iter_1_3)
		end
	end

	if arg_1_0:hasElementEquipByID(var_0_7) and not arg_1_0.hasSetElementGlobalBuff then
		arg_1_0.hasSetElementGlobalBuff = true

		local function var_1_4(arg_2_0, arg_2_1, arg_2_2)
			local var_2_0 = {}

			for iter_2_0, iter_2_1 in ipairs(arg_2_0) do
				local var_2_1 = var_0_4.new({
					tableID = iter_2_1,
					start = var_0_1.ctx.battle.count,
					level = arg_2_2,
					skillID = arg_2_1,
					fighter = arg_1_0
				})

				var_2_1:setYongJiu()
				table.insert(var_2_0, var_2_1)
			end

			return var_2_0
		end

		local var_1_5 = var_0_7
		local var_1_6 = var_0_6:battleAttr(var_1_5, arg_1_0:getElementEquipLevelByID(var_1_5))
		local var_1_7 = arg_1_0.hero_:getElementEquipActiveRate(var_1_5)
		local var_1_8 = var_0_6:skillIDs(var_1_5)
		local var_1_9 = var_0_6:buffIDs(var_1_5)
		local var_1_10 = var_1_4(var_1_9, var_1_8[1], 1)

		for iter_1_4, iter_1_5 in ipairs(var_1_10) do
			iter_1_5.manualRevise = var_1_6 * var_1_7
		end

		for iter_1_6, iter_1_7 in ipairs(var_1_10) do
			local var_1_11 = arg_1_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsB or var_0_1.ctx.battle.globalBuffsA

			var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_1_7:getAttrType())
			table.insert(var_1_11, iter_1_7)
		end
	end
end

function var_0_3.buffRemoveAction(arg_3_0, arg_3_1)
	if arg_3_1:getRemoveSkill() < 1 or var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_3_0 = arg_3_1:getRemoveSkill()
	local var_3_1 = {
		arg_3_1.target
	}
	local var_3_2 = arg_3_0:createAttackUnits(var_3_1, var_3_0)

	for iter_3_0, iter_3_1 in ipairs(var_3_2) do
		table.insert(arg_3_0.moveAttackUnits_, iter_3_1)
		table.insert(arg_3_0.records_.special_units, iter_3_1)
	end
end

return var_0_3
