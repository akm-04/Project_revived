local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yuanshao", var_0_1.ctx.battle.requireFighter("Yuanshao"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = var_0_2.tables.dbuff

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.records_.awake_buff = {}
	arg_2_0.records_.buff_hit = {}
	arg_2_0.storeBuffs = {}
	arg_2_0.awakeBuffCount = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	var_0_3.super.toDoPerFrames(arg_3_0)

	if not arg_3_0:isDeath() then
		for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
			if iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_3_1.fighter ~= arg_3_0 and iter_3_1.fighter:getTeamType() == arg_3_0:getTeamType() and iter_3_1.target:getTeamType() ~= arg_3_0:getTeamType() then
				local var_3_0 = var_0_6:dbuffType(iter_3_1:getTableID())

				if var_3_0 > 0 and not arg_3_0.storeBuffs[var_3_0] then
					arg_3_0.storeBuffs[var_3_0] = iter_3_1:getTableID()
					arg_3_0.awakeBuffCount = arg_3_0.awakeBuffCount + 1
				end
			end
		end
	end
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID ~= arg_4_0:getPugongID() and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() then
		local var_4_0 = arg_4_0:getAwakeBuff(arg_4_1.target)

		if var_4_0 then
			local var_4_1

			if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
				if arg_4_0.buffHitRecord and next(arg_4_0.buffHitRecord) then
					var_4_1 = arg_4_0.buffHitRecord[1]

					table.remove(arg_4_0.buffHitRecord, 1)
				end
			else
				local var_4_2 = math.min(1 / (var_0_2.tables.battleConfig.buffHitParam1 * math.max(var_4_0.target:getLevel() - var_4_0.level_, 0) + var_0_2.tables.battleConfig.buffHitParam2), 1)

				var_4_1 = var_0_2.weightedChoise({
					var_4_2,
					1 - var_4_2
				}) == 1

				table.insert(arg_4_0.records_.buff_hit, var_4_1)
			end

			if var_4_1 then
				arg_4_1.target:addBuffs({
					var_4_0
				})
			else
				arg_4_1.target.fighterModel:playFloatText({
					var_0_2.BattleFloatType.BUFF_MISS
				}, arg_4_1.target:getTeamType())
			end
		end
	end
end

function var_0_3.getAwakeBuff(arg_5_0, arg_5_1)
	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake) < 1 then
		return
	end

	local var_5_0

	if var_0_1.ctx.battle.battleType == var_0_1.ctx.battle.ReplayReport then
		var_5_0 = arg_5_0.buffRecord[1]

		table.remove(arg_5_0.buffRecord, 1)
	else
		local var_5_1 = {}

		for iter_5_0, iter_5_1 in pairs(arg_5_0.storeBuffs) do
			table.insert(var_5_1, iter_5_0)
		end

		if not next(var_5_1) then
			return
		end

		var_5_0 = var_5_1[math.random(#var_5_1)]

		table.insert(arg_5_0.records_.awake_buff, var_5_0)
	end

	if not var_5_0 or not arg_5_0.storeBuffs[var_5_0] then
		return
	end

	local var_5_2 = var_0_4.new({
		tableID = arg_5_0.storeBuffs[var_5_0],
		start = var_0_1.ctx.battle.count,
		level = arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Awake),
		skillID = arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Awake),
		fighter = arg_5_0,
		target = arg_5_1
	})

	arg_5_0.storeBuffs[var_5_0] = nil
	arg_5_0.awakeBuffCount = arg_5_0.awakeBuffCount - 1

	return var_5_2
end

function var_0_3.setupReport(arg_6_0, arg_6_1)
	var_0_3.super.setupReport(arg_6_0, arg_6_1)

	arg_6_0.buffRecord = arg_6_1.awake_buff
	arg_6_0.buffHitRecord = arg_6_1.buff_hit
end

function var_0_3.writeReport(arg_7_0)
	local var_7_0 = var_0_3.super.writeReport(arg_7_0)

	var_7_0.awake_buff = arg_7_0.records_.awake_buff
	var_7_0.buff_hit = arg_7_0.records_.buff_hit

	return var_7_0
end

return var_0_3
