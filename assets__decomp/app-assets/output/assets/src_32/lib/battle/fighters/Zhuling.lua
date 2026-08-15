local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Zhuling", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_2.tables.skill
local var_0_6 = 1000
local var_0_7 = 120
local var_0_8 = 120
local var_0_9 = 10001666
local var_0_10 = 0.2
local var_0_11 = 250
local var_0_12 = 80010230
local var_0_13 = 0.15

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.magic = 0
	arg_1_0.footmanMode = false
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.GreenFootmanBuffs = {
			40011764,
			40011765,
			40011766,
			40012392
		}
		arg_2_0.FootmanPugong = 10002243
		arg_2_0.PurpleMarkBuff = 40012393
		arg_2_0.EnergyFootmanSkill = 10002242
		arg_2_0.EnergySelfMarkBuff = 40012391
		arg_2_0.PugongID = 10002244
		arg_2_0.GreenSkillID = 10002245
		arg_2_0.BlueSkillID = 10002246
		arg_2_0.EnergySkillID = 10002247
	else
		arg_2_0.GreenFootmanBuffs = {
			40011764,
			40011765,
			40011766,
			40011767
		}
		arg_2_0.FootmanPugong = 10001665
		arg_2_0.PurpleMarkBuff = 40011769
		arg_2_0.EnergyFootmanSkill = 10001664
		arg_2_0.EnergySelfMarkBuff = 40011762
		arg_2_0.PugongID = 10020230
		arg_2_0.GreenSkillID = 20020230
		arg_2_0.BlueSkillID = 30010230
		arg_2_0.EnergySkillID = 50010230
	end
end

function var_0_3.toDoPerFrames(arg_3_0)
	if arg_3_0.skinSkillIndex_ == 1 and not arg_3_0.SkinAddMagic and var_0_1.ctx.battle.count % 10 == 1 then
		arg_3_0:updateMagicBy(var_0_11)

		arg_3_0.SkinAddMagic = true
	end
end

function var_0_3.getFrontSkill(arg_4_0)
	local var_4_0 = var_0_3.super.getFrontSkill(arg_4_0)

	if arg_4_0.footmanMode then
		if var_4_0 == arg_4_0:getPugongID() or var_4_0 == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
			var_4_0 = arg_4_0.FootmanPugong
		elseif var_4_0 == arg_4_0:getEnergySkillID() then
			var_4_0 = arg_4_0.EnergyFootmanSkill
		end
	end

	return var_4_0
end

function var_0_3.applySingleUnit(arg_5_0, arg_5_1)
	if arg_5_1.target:isHasBuffByID(arg_5_0.PurpleMarkBuff) and arg_5_1.basicHarm > 0 and arg_5_0.footmanMode then
		arg_5_1.target:removeBuffByID(arg_5_0.PurpleMarkBuff)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_5_0 = arg_5_0:createAttackUnits({
				arg_5_1.target
			}, var_0_9)

			for iter_5_0, iter_5_1 in ipairs(var_5_0) do
				table.insert(arg_5_0.moveAttackUnits_, iter_5_1)
				table.insert(arg_5_0.records_.special_units, iter_5_1)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_5_0, arg_5_1)

	if arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 then
		if arg_5_1.skillID == arg_5_0.FootmanPugong then
			arg_5_0:updateMagicBy(-var_0_8)
		elseif arg_5_1.skillID == arg_5_0.PugongID then
			arg_5_0:updateMagicBy(var_0_7)
		elseif arg_5_1.skillID == arg_5_0.GreenSkillID then
			arg_5_0:x(arg_5_1.target:getX() + (arg_5_1.target:getFlipX() and 50 or -50))
		elseif arg_5_1.skillID == arg_5_0.BlueSkillID then
			arg_5_0:updateEnergyBy(60)
			arg_5_0:updateMagicBy(90)
		end
	end
end

function var_0_3.updateMagicBy(arg_6_0, arg_6_1)
	if arg_6_0:isHasBuffByID(arg_6_0.EnergySelfMarkBuff) and arg_6_1 > 0 then
		arg_6_1 = 2 * arg_6_1
	end

	if arg_6_0.skinSkillIndex_ == 1 and arg_6_1 > 0 then
		arg_6_1 = (1 + var_0_10) * arg_6_1
	end

	arg_6_0.magic = math.max(math.min(arg_6_0.magic + arg_6_1, var_0_6), 0)

	if arg_6_0.footmanMode and arg_6_0.magic <= 0 then
		arg_6_0:turnIntoShooterMode()
	elseif not arg_6_0.footmanMode and arg_6_0.magic >= var_0_6 then
		arg_6_0:turnIntoFootmanMode()
	end
end

function var_0_3.turnIntoFootmanMode(arg_7_0)
	arg_7_0.footmanMode = true

	arg_7_0:addBuffs(arg_7_0:newBuffs(arg_7_0.GreenFootmanBuffs, arg_7_0, arg_7_0.GreenSkillID))
	arg_7_0:createSkillByID(arg_7_0.GreenSkillID, arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green), var_0_5:attackIndex(arg_7_0.GreenSkillID))

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_7_0.skinSkillIndex_ == 1 then
		local var_7_0 = arg_7_0:createAttackUnits({
			arg_7_0
		}, var_0_12)

		for iter_7_0, iter_7_1 in ipairs(var_7_0) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
			table.insert(arg_7_0.records_.special_units, iter_7_1)
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7 = var_0_3.super.updateUnitDataByFighter(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0.skinSkillIndex_ == 1 and arg_8_1.skillID == var_0_12 then
		arg_8_5 = arg_8_0:getHpLimit() * var_0_13
	end

	return arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7
end

function var_0_3.turnIntoShooterMode(arg_9_0)
	arg_9_0.footmanMode = false

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.GreenFootmanBuffs) do
		arg_9_0:removeBuffByID(iter_9_1)
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType and arg_9_0.skinSkillIndex_ == 1 then
		local var_9_0 = arg_9_0:createAttackUnits({
			arg_9_0
		}, var_0_12)

		for iter_9_2, iter_9_3 in ipairs(var_9_0) do
			table.insert(arg_9_0.moveAttackUnits_, iter_9_3)
			table.insert(arg_9_0.records_.special_units, iter_9_3)
		end
	end
end

function var_0_3.newBuffs(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_1) do
		local var_10_1 = var_0_4.new({
			tableID = iter_10_1,
			start = var_0_1.ctx.battle.count,
			level = arg_10_4 or arg_10_0:getSkillLevelByID(arg_10_3),
			skillID = arg_10_3,
			fighter = arg_10_0,
			target = arg_10_2
		})

		var_10_1:setIsHit(true)
		var_10_1:setDirection(arg_10_0:getFighterModel():getFlipX())
		table.insert(var_10_0, var_10_1)
	end

	return var_10_0
end

return var_0_3
