local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Dechuanjiakang", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 10001107
local var_0_12 = 10001109
local var_0_13 = 10001108
local var_0_14 = 0.25
local var_0_15 = 10001111
local var_0_16 = 10001110
local var_0_17 = 40011217
local var_0_18 = 10001112
local var_0_19 = 40011218
local var_0_20 = 40011219
local var_0_21 = 35
local var_0_22 = "skeletons/dechuanjiakang/dazhao_texture.plist"
local var_0_23 = 10001130
local var_0_24 = 10
local var_0_25 = 80010190
local var_0_26 = 0.1
local var_0_27 = 0.5

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("harm_info")
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.EnergyCureSkill = 10002139
		arg_2_0.EnergyJieLvSkill = 10002140
		arg_2_0.EnergyCureBuffID = 40012283
		arg_2_0.EnergyHarmBuffID = 40012284
		arg_2_0.JieLvBuff = 40012285
		arg_2_0.GreenSkillID = 10002142
		arg_2_0.BlueSkillID = 10002143
	else
		arg_2_0.EnergyCureSkill = 10001106
		arg_2_0.EnergyJieLvSkill = 10001113
		arg_2_0.EnergyCureBuffID = 40011209
		arg_2_0.EnergyHarmBuffID = 40011210
		arg_2_0.JieLvBuff = 40011211
		arg_2_0.GreenSkillID = 20010190
		arg_2_0.BlueSkillID = 30010190
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.jieLvHarm = {}
	arg_3_0.qiShiCount = 0
	arg_3_0.energyEffectTime_ = 0
	arg_3_0.energyEffect = nil
	arg_3_0.harmInfo = {}
end

function var_0_3.beginAttackEnd(arg_4_0, arg_4_1)
	var_0_3.super.beginAttackEnd(arg_4_0, arg_4_1)

	if arg_4_1.rootID_ == arg_4_0:getEnergySkillID() then
		arg_4_0.energyEffectTime_ = var_0_21

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			arg_4_0.energyEffect = cc.ParticleSystemQuad:create(var_0_22)

			arg_4_0.energyEffect:addTo(var_0_1.ctx.battle.unitLayer)
			arg_4_0.energyEffect:setPosition(var_0_2.STAGE_WIDTH / 2, var_0_2.STAGE_HEIGHT / 2 + 345)
		end
	end
end

function var_0_3.toDoPerFrames(arg_5_0)
	if arg_5_0:isDeath() then
		return
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_0:getInfoByKey("harm_info")) do
		local var_5_0 = iter_5_1.harm
		local var_5_1 = iter_5_1.fighter

		if not arg_5_0.harmInfo[var_5_1] then
			arg_5_0.harmInfo[var_5_1] = var_5_0
		else
			arg_5_0.harmInfo[var_5_1] = arg_5_0.harmInfo[var_5_1] + var_5_0
		end
	end

	arg_5_0.energyEffectTime_ = arg_5_0.energyEffectTime_ - 1

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		arg_5_0:updateStateNumber(arg_5_0.qiShiCount)
	end

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_5_2, iter_5_3 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_3:isDeath() and not iter_5_3:isAffected() and iter_5_3:getSummonType() == var_0_2.summonMonsterType.None and iter_5_3:isHasBuffByID(arg_5_0.JieLvBuff) and arg_5_0.jieLvHarm[iter_5_3] and arg_5_0.jieLvHarm[iter_5_3] >= 0 and arg_5_0.harmInfo[iter_5_3] and arg_5_0.harmInfo[iter_5_3] - arg_5_0.jieLvHarm[iter_5_3] > iter_5_3:getHpLimit() * var_0_14 then
				iter_5_3:removeBuffByID(arg_5_0.JieLvBuff)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_5_2 = arg_5_0:createAttackUnits({
						iter_5_3
					}, var_0_15)

					for iter_5_4, iter_5_5 in ipairs(var_5_2) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
						table.insert(arg_5_0.records_.special_units, iter_5_5)
					end

					if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
						local var_5_3 = arg_5_0:createAttackUnits({
							arg_5_0
						}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						for iter_5_6, iter_5_7 in ipairs(var_5_3) do
							table.insert(arg_5_0.moveAttackUnits_, iter_5_7)
							table.insert(arg_5_0.records_.special_units, iter_5_7)
						end
					end
				end
			end
		end

		for iter_5_8, iter_5_9 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_9:isDeath() and not iter_5_9:isAffected() and iter_5_9:getSummonType() == var_0_2.summonMonsterType.None and iter_5_9:isHasBuffByID(arg_5_0.JieLvBuff) and arg_5_0.jieLvHarm[iter_5_9] and arg_5_0.jieLvHarm[iter_5_9] >= 0 and arg_5_0.harmInfo[iter_5_9] and arg_5_0.harmInfo[iter_5_9] - arg_5_0.jieLvHarm[iter_5_9] > iter_5_9:getHpLimit() * var_0_14 then
				iter_5_9:removeBuffByID(arg_5_0.JieLvBuff)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_5_4 = arg_5_0:createAttackUnits({
						iter_5_9
					}, var_0_16)

					for iter_5_10, iter_5_11 in ipairs(var_5_4) do
						table.insert(arg_5_0.moveAttackUnits_, iter_5_11)
						table.insert(arg_5_0.records_.special_units, iter_5_11)
					end

					if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
						local var_5_5 = arg_5_0:createAttackUnits({
							arg_5_0
						}, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						for iter_5_12, iter_5_13 in ipairs(var_5_5) do
							table.insert(arg_5_0.moveAttackUnits_, iter_5_13)
							table.insert(arg_5_0.records_.special_units, iter_5_13)
						end
					end
				end
			end
		end
	end

	if arg_5_0.energyEffectTime_ <= 0 then
		if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
			return
		end

		if arg_5_0.energyEffect and not tolua.isnull(arg_5_0.energyEffect) then
			arg_5_0.energyEffect:removeSelf()
		end

		arg_5_0.energyEffect = nil
	end
end

function var_0_3.deathFeedback(arg_6_0, arg_6_1)
	if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_6_1:isHasBuffByID(arg_6_0.JieLvBuff) and arg_6_1:getSummonType() == var_0_2.summonMonsterType.None and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_6_0 = arg_6_0:createAttackUnits({
			arg_6_0
		}, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		for iter_6_0, iter_6_1 in ipairs(var_6_0) do
			table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
			table.insert(arg_6_0.records_.special_units, iter_6_1)
		end
	end
end

function var_0_3.applySingleUnit(arg_7_0, arg_7_1)
	var_0_3.super.applySingleUnit(arg_7_0, arg_7_1)

	local var_7_0 = arg_7_1.skillID

	if var_7_0 == arg_7_0.GreenSkillID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_7_1 = arg_7_0:selectTargetByTypeD1(arg_7_1.target)
		local var_7_2 = arg_7_0:createAttackUnits(var_7_1, var_0_11)

		for iter_7_0, iter_7_1 in ipairs(var_7_2) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	elseif var_7_0 == arg_7_0.BlueSkillID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if arg_7_1.target:getTeamType() == arg_7_0:getTeamType() then
			local var_7_3 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_12)

			for iter_7_2, iter_7_3 in ipairs(var_7_3) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
				table.insert(arg_7_0.records_.special_units, iter_7_3)
			end
		else
			local var_7_4 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_13)

			for iter_7_4, iter_7_5 in ipairs(var_7_4) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_5)
				table.insert(arg_7_0.records_.special_units, iter_7_5)
			end
		end

		if arg_7_0.skinSkillIndex_ == 1 then
			local var_7_5 = var_0_27

			isAdd = var_0_2.weightedChoise({
				var_7_5,
				1 - var_7_5
			}) == 1

			if isAdd then
				local var_7_6 = arg_7_0:selectSkinTarget(arg_7_1.target)
				local var_7_7 = arg_7_0:createAttackUnits(var_7_6, var_0_13)

				for iter_7_6, iter_7_7 in ipairs(var_7_7) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_7)
					table.insert(arg_7_0.records_.special_units, iter_7_7)
				end

				if var_7_6 and next(var_7_6) then
					for iter_7_8, iter_7_9 in ipairs(var_7_6) do
						local var_7_8 = arg_7_0:newBuff(arg_7_0.JieLvBuff, arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue), iter_7_9)

						iter_7_9:addBuffs({
							var_7_8
						})
					end
				end
			end
		end
	elseif var_7_0 == arg_7_0.EnergyCureSkill and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		local var_7_9 = arg_7_0:selectTargetByTypeD3()
		local var_7_10 = arg_7_0:createAttackUnits(var_7_9, arg_7_0.EnergyJieLvSkill)

		for iter_7_10, iter_7_11 in ipairs(var_7_10) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_11)
			table.insert(arg_7_0.records_.special_units, iter_7_11)
		end
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	return (var_0_7.new({
		tableID = arg_8_1,
		start = var_0_1.ctx.battle.count,
		level = arg_8_0:getSkillLevelByID(arg_8_2),
		skillID = arg_8_2,
		fighter = arg_8_0,
		target = arg_8_3
	}))
end

function var_0_3.updateUnitDataByTarget(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)
	arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7 = var_0_3.super.updateUnitDataByFighter(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7)

	if arg_9_0.skinSkillIndex_ == 1 and arg_9_1.skillID == var_0_25 then
		arg_9_5 = arg_9_1.target:getHpLimit() * var_0_26
	end

	return arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6, arg_9_7
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	if arg_10_1:getTableID() == arg_10_0.JieLvBuff then
		arg_10_0.jieLvHarm[arg_10_1.target] = arg_10_0.harmInfo[arg_10_1.target] or 0
	elseif arg_10_1:getTableID() == var_0_17 then
		arg_10_0.qiShiCount = arg_10_0.qiShiCount + 1

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_10_0 = arg_10_0:getTargets(var_0_18)
			local var_10_1 = arg_10_0:createAttackUnits(var_10_0, var_0_18)

			for iter_10_0, iter_10_1 in ipairs(var_10_1) do
				table.insert(arg_10_0.moveAttackUnits_, iter_10_1)
				table.insert(arg_10_0.records_.special_units, iter_10_1)
			end

			if arg_10_0.skinSkillIndex_ == 1 then
				local var_10_2 = arg_10_0:createAttackUnits(var_10_0, var_0_25)

				for iter_10_2, iter_10_3 in ipairs(var_10_2) do
					table.insert(arg_10_0.moveAttackUnits_, iter_10_3)
					table.insert(arg_10_0.records_.special_units, iter_10_3)
				end
			end
		end
	elseif arg_10_1:getTableID() == var_0_19 or arg_10_1:getTableID() == var_0_20 then
		arg_10_1:setExtraTime(arg_10_0.qiShiCount * 30)
	elseif arg_10_1:getTableID() == arg_10_0.EnergyHarmBuffID or arg_10_1:getTableID() == arg_10_0.EnergyCureBuffID then
		arg_10_1.manualHarmRevise = arg_10_1:getHarm() * (1 + math.min((1 - arg_10_1.target:getHp() / arg_10_1.target:getHpLimit()) * 2, 1))
	end
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	if arg_11_1:getTableID() == arg_11_0.JieLvBuff then
		-- block empty
	end
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1)
	local var_12_0 = {}
	local var_12_1 = var_0_8:scope(var_0_11) / 2

	if not arg_12_1 then
		return {}
	end

	x1, y1 = arg_12_1.fighterModel:getPosition()

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.sideTeam_) do
		local var_12_2, var_12_3 = iter_12_1.fighterModel:getPosition()

		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and var_12_1 >= math.abs(x1 - var_12_2) and iter_12_1 ~= arg_12_1 then
			table.insert(var_12_0, iter_12_1)
		end
	end

	return var_12_0
end

function var_0_3.selectSkinTarget(arg_13_0, arg_13_1)
	local var_13_0 = {}
	local var_13_1
	local var_13_2 = {}
	local var_13_3 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_1:isDeath() and not iter_13_1:isAffected() and iter_13_1:getSummonType() == var_0_2.summonMonsterType.None and not iter_13_1:isHasBuffByID(arg_13_0.JieLvBuff) and iter_13_1 ~= arg_13_1 then
			var_13_1 = iter_13_1

			table.insert(var_13_2, var_13_1)
			table.insert(var_13_3, 1)
		end

		if next(var_13_2) then
			var_13_1 = var_13_2[var_0_2.weightedChoise(var_13_3)]
		end
	end

	if var_13_1 then
		table.insert(var_13_0, var_13_1)

		return var_13_0
	else
		local var_13_4 = {}
		local var_13_5 = {}
		local var_13_6

		for iter_13_2, iter_13_3 in ipairs(arg_13_0.sideTeam_) do
			if not iter_13_3:isDeath() and not iter_13_3:isAffected() and iter_13_3:getSummonType() == var_0_2.summonMonsterType.None then
				var_13_6 = iter_13_3

				table.insert(var_13_4, var_13_6)
				table.insert(var_13_5, 1)
			end

			if next(var_13_4) then
				var_13_6 = var_13_4[var_0_2.weightedChoise(var_13_5)]
			end

			table.insert(var_13_0, var_13_6)

			return var_13_0
		end
	end
end

function var_0_3.selectTargetByTypeD2(arg_14_0)
	local var_14_0 = {}
	local var_14_1 = -1
	local var_14_2

	for iter_14_0, iter_14_1 in ipairs(arg_14_0.sideTeam_) do
		if not iter_14_1:isDeath() and not iter_14_1:isAffected() and iter_14_1:getSummonType() == var_0_2.summonMonsterType.None and var_14_1 < iter_14_1:getAttrByType(var_0_2.AttributeType.AGILE) and not iter_14_1:isHasBuffByID(arg_14_0.JieLvBuff) then
			var_14_2 = iter_14_1
			var_14_1 = iter_14_1:getAttrByType(var_0_2.AttributeType.AGILE)
		end
	end

	for iter_14_2, iter_14_3 in ipairs(arg_14_0.selfTeam_) do
		if not iter_14_3:isDeath() and not iter_14_3:isAffected() and iter_14_3:getSummonType() == var_0_2.summonMonsterType.None and var_14_1 < iter_14_3:getAttrByType(var_0_2.AttributeType.AGILE) and not iter_14_3:isHasBuffByID(arg_14_0.JieLvBuff) then
			var_14_2 = iter_14_3
			var_14_1 = iter_14_3:getAttrByType(var_0_2.AttributeType.AGILE)
		end
	end

	if var_14_2 then
		table.insert(var_14_0, var_14_2)

		return var_14_0
	else
		local var_14_3 = -1
		local var_14_4

		for iter_14_4, iter_14_5 in ipairs(arg_14_0.sideTeam_) do
			if not iter_14_5:isDeath() and not iter_14_5:isAffected() and iter_14_5:getSummonType() == var_0_2.summonMonsterType.None and var_14_3 < iter_14_5:getAttrByType(var_0_2.AttributeType.AGILE) then
				var_14_4 = iter_14_5
				var_14_3 = iter_14_5:getAttrByType(var_0_2.AttributeType.AGILE)
			end
		end

		for iter_14_6, iter_14_7 in ipairs(arg_14_0.selfTeam_) do
			if not iter_14_7:isDeath() and not iter_14_7:isAffected() and iter_14_7:getSummonType() == var_0_2.summonMonsterType.None and var_14_3 < iter_14_7:getAttrByType(var_0_2.AttributeType.AGILE) then
				var_14_4 = iter_14_7
				var_14_3 = iter_14_7:getAttrByType(var_0_2.AttributeType.AGILE)
			end
		end

		table.insert(var_14_0, var_14_4)

		return var_14_0
	end
end

function var_0_3.selectTargetByTypeD3(arg_15_0)
	local var_15_0 = {}

	for iter_15_0, iter_15_1 in ipairs(arg_15_0.sideTeam_) do
		if not iter_15_1:isDeath() and not iter_15_1:isAffected() and iter_15_1:getSummonType() == var_0_2.summonMonsterType.None then
			table.insert(var_15_0, iter_15_1)
		end
	end

	for iter_15_2, iter_15_3 in ipairs(arg_15_0.selfTeam_) do
		if not iter_15_3:isDeath() and not iter_15_3:isAffected() and iter_15_3:getSummonType() == var_0_2.summonMonsterType.None and iter_15_3 ~= arg_15_0 then
			table.insert(var_15_0, iter_15_3)
		end
	end

	return var_15_0
end

return var_0_3
