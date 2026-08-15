local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Mingzhiguangxiu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = math.abs
local var_0_10 = math.min
local var_0_11 = 6
local var_0_12 = 5
local var_0_13 = 7
local var_0_14 = 6
local var_0_15 = 10001045
local var_0_16 = 10001046
local var_0_17 = 10001047
local var_0_18 = 10001042
local var_0_19 = 10001043
local var_0_20 = 10001044
local var_0_21 = 40011147
local var_0_22 = {
	10001057,
	10001058,
	10001059,
	10001060
}
local var_0_23 = 40011165
local var_0_24 = 30010185
local var_0_25 = 10001062
local var_0_26 = 10001063
local var_0_27 = var_0_2.tables.cabinetSkillTable
local var_0_28 = 20040003

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueSkillTarget_ = nil
	arg_1_0.energySkillTarget_ = nil
	arg_1_0.blueBackCount_ = nil
	arg_1_0.extraSkillJudge = false
	arg_1_0.extraSkillLevel1 = 0
	arg_1_0.addDHuJiaRate = 0
end

function var_0_3.getOrbOfFrontSkill(arg_2_0)
	local var_2_0 = var_0_3.super.getOrbOfFrontSkill(arg_2_0)

	if var_2_0 == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_2_0:getBirdState() then
		var_2_0 = var_0_17
	end

	return var_2_0
end

function var_0_3.getBirdState(arg_3_0)
	if not (arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0) then
		return false
	end

	local var_3_0, var_3_1 = arg_3_0:getPos()
	local var_3_2
	local var_3_3
	local var_3_4 = 0
	local var_3_5 = 0

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and not iter_3_1:isAffected() and iter_3_1 ~= arg_3_0 and iter_3_1:getSummonType() == var_0_2.summonMonsterType.None then
			if iter_3_1.hero_:getHeroType() == var_0_2.AttributeType.STRENGTH then
				var_3_5 = var_3_5 + 1
			elseif iter_3_1.hero_:getHeroType() == var_0_2.AttributeType.AGILE then
				var_3_4 = var_3_4 + 1
			end

			local var_3_6, var_3_7 = iter_3_1:getPos()
			local var_3_8 = math.abs(var_3_0 - var_3_6)

			if not var_3_2 or var_3_8 < var_3_2 then
				var_3_2 = var_3_8
				var_3_3 = iter_3_1
			end
		end
	end

	if var_3_3 and (var_3_3.hero_:getHeroType() == var_0_2.AttributeType.AGILE or var_3_5 < var_3_4) then
		return true
	end

	return false
end

function var_0_3.toDoPerFrames(arg_4_0)
	if arg_4_0:isDeath() then
		return
	end

	if not arg_4_0.extraSkillJudge then
		arg_4_0.extraSkillJudge = true
		arg_4_0.extraSkillLevel1 = arg_4_0.hero_:skillBook()[tostring(var_0_28)] or 0
		arg_4_0.addDHuJiaRate = arg_4_0.extraSkillLevel1 * var_0_27:attrValues(var_0_28) * 0.01
	end

	if arg_4_0.blueBackCount_ then
		arg_4_0.blueBackCount_ = arg_4_0.blueBackCount_ - 1

		if arg_4_0.blueBackCount_ <= 0 then
			if arg_4_0.bluePreX_ and arg_4_0.bluePreY_ then
				arg_4_0:x(arg_4_0.bluePreX_)
				arg_4_0:y(arg_4_0.bluePreY_)
			end

			arg_4_0.blueBackCount_ = nil
		end
	end
end

function var_0_3.getDHuJia(arg_5_0)
	local var_5_0 = var_0_3.super.getDHuJia(arg_5_0)

	if arg_5_0.extraSkillLevel1 > 0 then
		var_5_0 = var_5_0 + arg_5_0:getDMoKang() * arg_5_0.addDHuJiaRate
	end

	return var_5_0
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	local var_6_0 = arg_6_1.skillID

	if var_6_0 == var_0_18 then
		local var_6_1, var_6_2 = arg_6_1.target:getPos()

		if arg_6_1.target:getTeamType() == var_0_2.TeamType.B then
			arg_6_1.target:x(var_0_2.STAGE_WIDTH - 100)
		else
			arg_6_1.target:x(100)
		end
	elseif var_6_0 == var_0_19 then
		arg_6_1.target:removeBuffByID(var_0_21)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_3 = arg_6_0:selectTargetByTypeD1(arg_6_1.target)
			local var_6_4 = arg_6_0:createAttackUnits(var_6_3, var_0_20)

			for iter_6_0, iter_6_1 in ipairs(var_6_4) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
				table.insert(arg_6_0.records_.special_units, iter_6_1)
			end
		end
	elseif var_6_0 == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		if not arg_6_0:getBirdState() then
			local var_6_5 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_15)

			for iter_6_2, iter_6_3 in ipairs(var_6_5) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end

			if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
				for iter_6_4 = 1, arg_6_0:getHeroNumByAttrType(var_0_2.AttributeType.STRENGTH) do
					local var_6_6 = arg_6_0:createAttackUnits({
						arg_6_1.target
					}, var_0_25)

					for iter_6_5, iter_6_6 in ipairs(var_6_6) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_6)
						table.insert(arg_6_0.records_.special_units, iter_6_6)
					end
				end
			end
		else
			local var_6_7 = arg_6_0:createAttackUnits({
				arg_6_1.target
			}, var_0_16)

			for iter_6_7, iter_6_8 in ipairs(var_6_7) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_8)
				table.insert(arg_6_0.records_.special_units, iter_6_8)
			end

			if arg_6_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
				for iter_6_9 = 1, arg_6_0:getHeroNumByAttrType(var_0_2.AttributeType.AGILE) do
					local var_6_8 = arg_6_0:createAttackUnits({
						arg_6_1.target
					}, var_0_26)

					for iter_6_10, iter_6_11 in ipairs(var_6_8) do
						table.insert(arg_6_0.moveAttackUnits_, iter_6_11)
						table.insert(arg_6_0.records_.special_units, iter_6_11)
					end
				end
			end
		end
	elseif var_0_8:father(arg_6_1.skillID) == var_0_24 and arg_6_0:getBirdState() then
		local var_6_9 = arg_6_1.target:getX()
		local var_6_10 = arg_6_1.target:getY()
		local var_6_11

		if arg_6_0:getTeamType() == var_0_2.TeamType.A then
			var_6_11 = -1

			arg_6_0:flipX(false)
		else
			var_6_11 = 1

			arg_6_0:flipX(true)
		end

		arg_6_0:x(var_6_9 + 100 * var_6_11)
		arg_6_0:y(var_6_10)

		if arg_6_1.skillID == var_0_22[1] then
			arg_6_0.blueBackCount_ = var_0_11
		end

		if arg_6_1.skillID == var_0_22[2] then
			arg_6_0.blueBackCount_ = var_0_12
		end

		if arg_6_1.skillID == var_0_22[3] then
			arg_6_0.blueBackCount_ = var_0_13
		end

		if arg_6_1.skillID == var_0_22[4] then
			arg_6_0.blueSkillTarget_ = nil
			arg_6_0.blueBackCount_ = var_0_14
		end
	end
end

function var_0_3.beginAttackEnd(arg_7_0, arg_7_1)
	var_0_3.super.beginAttackEnd(arg_7_0, arg_7_1)

	if var_0_8:father(arg_7_1.rootID_) == var_0_24 and arg_7_0:getBirdState() then
		arg_7_0.bluePreX_ = arg_7_0:getX()
		arg_7_0.bluePreY_ = arg_7_0:getY()
	end
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1:getTableID() == var_0_23 then
		local var_8_0

		if not arg_8_0:getFlipX() then
			var_8_0 = math.abs(var_0_2.STAGE_WIDTH - 100 - arg_8_1.target:getX())
		else
			var_8_0 = math.abs(100 - arg_8_1.target:getX())
		end

		arg_8_1.resetXchange_ = var_8_0

		arg_8_1:setIsHit(true)
		arg_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
	end
end

function var_0_3.getHeroNumByAttrType(arg_9_0, arg_9_1)
	local var_9_0 = 0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.selfTeam_) do
		if not iter_9_1:isDeath() and not iter_9_1:isAffected() and iter_9_1 ~= arg_9_0 and iter_9_1:getSummonType() == var_0_2.summonMonsterType.None and iter_9_1.hero_:getHeroType() == arg_9_1 then
			var_9_0 = var_9_0 + 1
		end
	end

	return var_9_0
end

function var_0_3.selectTargetByTypeD1(arg_10_0, arg_10_1)
	local var_10_0 = {}
	local var_10_1 = var_0_8:scope(var_0_20) / 2

	x1, y1 = arg_10_1.fighterModel:getPosition()

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.sideTeam_) do
		local var_10_2, var_10_3 = iter_10_1.fighterModel:getPosition()

		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and var_10_1 >= math.abs(x1 - var_10_2) and iter_10_1 ~= arg_10_1 then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeD2(arg_11_0)
	if arg_11_0.energySkillTarget_ and not arg_11_0.energySkillTarget_:isDeath() and not arg_11_0.energySkillTarget_:isAffected() then
		return {
			arg_11_0.energySkillTarget_
		}
	end

	local var_11_0
	local var_11_1

	for iter_11_0, iter_11_1 in pairs(arg_11_0.sideTeam_) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() and iter_11_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_11_0 or var_11_1 > iter_11_1:getHp() / iter_11_1:getHpLimit() or var_11_1 == iter_11_1:getHp() / iter_11_1:getHpLimit() and var_11_0:getHp() > iter_11_1:getHp()) then
			var_11_0 = iter_11_1
			var_11_1 = var_11_0:getHp() / var_11_0:getHpLimit()
		end
	end

	if var_11_0 then
		arg_11_0.energySkillTarget_ = var_11_0

		return {
			var_11_0
		}
	else
		return {}
	end
end

function var_0_3.selectTargetByTypeD3(arg_12_0)
	if arg_12_0.blueSkillTarget_ and not arg_12_0.blueSkillTarget_:isDeath() and not arg_12_0.blueSkillTarget_:isAffected() then
		return {
			arg_12_0.blueSkillTarget_
		}
	end

	local var_12_0
	local var_12_1

	for iter_12_0, iter_12_1 in pairs(arg_12_0.sideTeam_) do
		if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1:getSummonType() == var_0_2.summonMonsterType.None and (not var_12_0 or var_12_1 > iter_12_1:getHp() / iter_12_1:getHpLimit() or var_12_1 == iter_12_1:getHp() / iter_12_1:getHpLimit() and var_12_0:getHp() > iter_12_1:getHp()) then
			var_12_0 = iter_12_1
			var_12_1 = var_12_0:getHp() / var_12_0:getHpLimit()
		end
	end

	if var_12_0 then
		arg_12_0.blueSkillTarget_ = var_12_0

		return {
			var_12_0
		}
	else
		return {}
	end
end

return var_0_3
