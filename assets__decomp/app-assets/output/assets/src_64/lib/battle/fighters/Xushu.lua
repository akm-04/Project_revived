local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Xushu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 40010671
local var_0_7 = 40010672
local var_0_8 = 10000666
local var_0_9 = 10000667
local var_0_10 = 10010016
local var_0_11 = 40010675
local var_0_12 = 40010676
local var_0_13 = 40010673
local var_0_14 = 80010023
local var_0_15 = 10001331
local var_0_16 = 10001332
local var_0_17 = 90
local var_0_18 = var_0_2.tables.elementEquip
local var_0_19 = 20001504
local var_0_20 = 10002516
local var_0_21 = 10002517

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("unit_info")
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.records_.green_target = {}
	arg_2_0.SkinSkillCDCounts = 0
end

function var_0_3.toDoPerFrames(arg_3_0)
	for iter_3_0, iter_3_1 in ipairs(arg_3_0:getInfoByKey("unit_info")) do
		local var_3_0 = iter_3_1.fighter

		if var_0_5:type(iter_3_1.skillID) == var_0_2.AttackType.AP and var_3_0:getTeamType() ~= arg_3_0:getTeamType() and not var_3_0:isDeath() then
			if var_3_0:isHasBuffByID(var_0_6) then
				var_3_0:removeBuffByID(var_0_6)

				local var_3_1 = var_0_4.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_3_0,
					target = var_3_0
				})

				var_3_0:addBuffs({
					var_3_1
				})

				local var_3_2 = arg_3_0:greenInfectTarget(var_3_0)

				if var_3_2 then
					local var_3_3 = var_0_4.new({
						tableID = var_0_7,
						start = var_0_1.ctx.battle.count,
						level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
						skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
						fighter = arg_3_0,
						target = var_3_2
					})

					var_3_2:addBuffs({
						var_3_3
					})
				end
			end

			if var_3_0:isHasBuffByID(var_0_7) then
				var_3_0:removeBuffByID(var_0_7)

				local var_3_4 = var_0_4.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green),
					fighter = arg_3_0,
					target = var_3_0
				})

				var_3_0:addBuffs({
					var_3_4
				})
			end
		end
	end

	for iter_3_2, iter_3_3 in ipairs(arg_3_0:getInfoByKey("buff_info")) do
		local var_3_5 = iter_3_3.target

		if not arg_3_0:isDeath() and var_3_5:getSummonType() == var_0_2.summonMonsterType.None and var_3_5:getTeamType() ~= arg_3_0:getTeamType() and iter_3_3:isApUnable() then
			if arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
				arg_3_0:addPurpleBuff()
			end

			local var_3_6 = var_3_5:getBuffByID(var_0_11)

			if var_3_6 then
				local var_3_7 = var_0_4.new({
					tableID = var_0_12,
					start = var_0_1.ctx.battle.count,
					level = arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue),
					skillID = arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue),
					fighter = arg_3_0,
					target = var_3_5
				})

				var_3_7:setExtraTime(var_3_6.leftCount_ - var_3_6:getTime())
				var_3_5:addBuffs({
					var_3_7
				})
			end
		end
	end

	if arg_3_0.SkinSkillCDCounts and arg_3_0.SkinSkillCDCounts > 0 then
		arg_3_0.SkinSkillCDCounts = arg_3_0.SkinSkillCDCounts - 1
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1.target:isDeath() then
		return
	end

	if arg_4_1:getTableID() == var_0_6 then
		if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
			local var_4_0 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_8)

			for iter_4_0, iter_4_1 in ipairs(var_4_0) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
				table.insert(arg_4_0.records_.special_units, iter_4_1)
			end
		end
	elseif arg_4_1:getTableID() == var_0_7 and var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
		local var_4_1 = arg_4_0:createAttackUnits({
			arg_4_1.target
		}, var_0_9)

		for iter_4_2, iter_4_3 in ipairs(var_4_1) do
			table.insert(arg_4_0.moveAttackUnits_, iter_4_3)
			table.insert(arg_4_0.records_.special_units, iter_4_3)
		end
	end

	if arg_4_0.isSkinSkillOn_ and arg_4_0.skinSkillID_ == var_0_14 and arg_4_1.target:getTeamType() ~= arg_4_0:getTeamType() and arg_4_1:isApUnable() and var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.ReplayReport then
		if arg_4_1.leftCount_ == 0 then
			local var_4_2 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_16)

			for iter_4_4, iter_4_5 in ipairs(var_4_2) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_5)
				table.insert(arg_4_0.records_.special_units, iter_4_5)
			end
		elseif arg_4_0.SkinSkillCDCounts and (arg_4_0.SkinSkillCDCounts == 0 or arg_4_0.SkinSkillCDCounts == var_0_17) then
			local var_4_3 = arg_4_0:createAttackUnits({
				arg_4_1.target
			}, var_0_15)

			for iter_4_6, iter_4_7 in ipairs(var_4_3) do
				table.insert(arg_4_0.moveAttackUnits_, iter_4_7)
				table.insert(arg_4_0.records_.special_units, iter_4_7)
			end

			arg_4_0.SkinSkillCDCounts = var_0_17
		end
	end
end

function var_0_3.greenInfectTarget(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.fighterIndex

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		if arg_5_0.greenTarget and arg_5_0.greenTarget[var_5_0] then
			local var_5_1 = arg_5_0.greenTarget[var_5_0][tostring(var_0_1.ctx.battle.count)]

			for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
				if iter_5_1.fighterIndex == var_5_1 then
					return iter_5_1
				end
			end
		end
	else
		local var_5_2 = {}

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_3:isDeath() and iter_5_3:getSummonType() == var_0_2.summonMonsterType.None then
				table.insert(var_5_2, iter_5_3)
			end
		end

		if next(var_5_2) then
			local var_5_3 = var_5_2[math.random(#var_5_2)]

			if not arg_5_0.records_.green_target[var_5_0] then
				arg_5_0.records_.green_target[var_5_0] = {}
			end

			arg_5_0.records_.green_target[var_5_0][tostring(var_0_1.ctx.battle.count)] = var_5_3.fighterIndex

			return var_5_3
		end
	end
end

function var_0_3.addPurpleBuff(arg_6_0)
	if #arg_6_0:getBuffsByID(var_0_13) < 5 then
		local var_6_0 = var_0_4.new({
			tableID = var_0_13,
			start = var_0_1.ctx.battle.count,
			level = arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple),
			skillID = arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple),
			fighter = arg_6_0,
			target = arg_6_0
		})

		arg_6_0:addBuffs({
			var_6_0
		})
	end
end

function var_0_3.dHarmBuffBreakFeedback(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if arg_7_2:getTableID() == var_0_13 and arg_7_0:hasElementEquipByID(var_0_19) then
		local var_7_0 = var_0_19
		local var_7_1 = var_0_18:battleAttr(var_7_0, arg_7_0:getElementEquipLevelByID(var_7_0))
		local var_7_2 = arg_7_0.hero_:getElementEquipActiveRate(var_7_0)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_3 = arg_7_0:createAttackUnits({
				arg_7_0
			}, var_0_20)

			for iter_7_0, iter_7_1 in ipairs(var_7_3) do
				iter_7_1:setExtraHarm(arg_7_2:totalDHarm() * var_7_1 * var_7_2)
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end

			local var_7_4 = arg_7_0:createAttackUnits({
				arg_7_3
			}, var_0_21)

			for iter_7_2, iter_7_3 in ipairs(var_7_4) do
				iter_7_3:setExtraHarm(arg_7_2:totalDHarm() * var_7_1 * var_7_2)
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		end
	end
end

function var_0_3.setupReport(arg_8_0, arg_8_1)
	var_0_3.super.setupReport(arg_8_0, arg_8_1)

	arg_8_0.greenTarget = arg_8_1.green_target
end

function var_0_3.writeReport(arg_9_0)
	local var_9_0 = var_0_3.super.writeReport(arg_9_0)

	var_9_0.green_target = arg_9_0.records_.green_target

	return var_9_0
end

return var_0_3
