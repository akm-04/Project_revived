local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Guotu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 0.005
local var_0_8 = 0
local var_0_9 = 40010871
local var_0_10 = 40010872
local var_0_11 = 10000802
local var_0_12 = 40010875
local var_0_13 = 10
local var_0_14 = 40010873
local var_0_15 = 40010874
local var_0_16 = 0.008
local var_0_17 = 0
local var_0_18 = 1
local var_0_19 = 80010161
local var_0_20 = 10001637
local var_0_21 = 0.04
local var_0_22 = 40011736
local var_0_23 = 40011737
local var_0_24 = 40011738
local var_0_25 = 2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)
	arg_1_0:listenInfo("harm_info")

	arg_1_0.blueHarmFighter_ = {}
	arg_1_0.blueChangeAD_ = 0
	arg_1_0.blueChangeAP_ = 0
	arg_1_0.purpleFighterInfo_ = {}
	arg_1_0.purpleCount = 0
end

function var_0_3.toDoPerFrames(arg_2_0)
	if arg_2_0:isDeath() then
		return
	end

	if var_0_1.ctx.battle.count % 30 == 0 then
		arg_2_0.purpleCount = 0
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 then
		for iter_2_0, iter_2_1 in ipairs(arg_2_0:getInfoByKey("harm_info")) do
			local var_2_0 = iter_2_1.harm
			local var_2_1 = iter_2_1.fighter

			if not var_2_1:isDeath() and var_2_1:getSummonType() == var_0_2.summonMonsterType.None then
				if not arg_2_0.blueHarmFighter_[var_2_1] then
					arg_2_0.blueHarmFighter_[var_2_1] = 0
				end

				arg_2_0.blueHarmFighter_[var_2_1] = arg_2_0.blueHarmFighter_[var_2_1] + var_2_0
			end
		end
	end

	if arg_2_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and arg_2_0.purpleCount < 2 then
		for iter_2_2, iter_2_3 in ipairs(arg_2_0.sideTeam_) do
			if #arg_2_0:getBuffsByID(var_0_12) > var_0_13 then
				break
			end

			if not iter_2_3:isDeath() and iter_2_3:getSummonType() == var_0_2.summonMonsterType.None then
				if not arg_2_0.purpleFighterInfo_[iter_2_3] then
					arg_2_0.purpleFighterInfo_[iter_2_3] = {
						AD = iter_2_3:getAD(),
						AP = iter_2_3:getAP()
					}
				else
					local var_2_2 = arg_2_0.purpleFighterInfo_[iter_2_3]

					if var_2_2.AD ~= iter_2_3:getAD() or var_2_2.AP ~= iter_2_3:getAP() then
						arg_2_0.purpleFighterInfo_[iter_2_3] = {
							AD = iter_2_3:getAD(),
							AP = iter_2_3:getAP()
						}

						local var_2_3 = arg_2_0:newBuff({
							var_0_12
						}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						if arg_2_0.skinSkillID_ == var_0_19 then
							local var_2_4 = var_0_5.aliveTargets(arg_2_0.selfTeam_)

							if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
								local var_2_5 = arg_2_0:createAttackUnits(var_2_4, var_0_19)

								for iter_2_4, iter_2_5 in ipairs(var_2_5) do
									iter_2_5.basicHarm = var_2_3[1]:totalDHarm()

									table.insert(arg_2_0.moveAttackUnits_, iter_2_5)
									table.insert(arg_2_0.records_.special_units, iter_2_5)
								end
							end

							for iter_2_6, iter_2_7 in ipairs(var_2_4) do
								if iter_2_7 ~= arg_2_0 then
									local var_2_6 = arg_2_0:newBuff({
										var_0_24
									}, iter_2_7, var_0_19)

									var_2_6[1].manualDharm = var_2_3[1]:totalDHarm()

									iter_2_7:addBuffs(var_2_6)
								end
							end
						end

						arg_2_0:addBuffs(var_2_3)

						arg_2_0.purpleCount = arg_2_0.purpleCount + 1
					end
				end
			end
		end

		for iter_2_8, iter_2_9 in ipairs(arg_2_0.selfTeam_) do
			if #arg_2_0:getBuffsByID(var_0_12) > var_0_13 then
				break
			end

			if not iter_2_9:isDeath() and iter_2_9:getSummonType() == var_0_2.summonMonsterType.None then
				if not arg_2_0.purpleFighterInfo_[iter_2_9] then
					arg_2_0.purpleFighterInfo_[iter_2_9] = {
						AD = iter_2_9:getAD(),
						AP = iter_2_9:getAP()
					}
				else
					local var_2_7 = arg_2_0.purpleFighterInfo_[iter_2_9]

					if var_2_7.AD ~= iter_2_9:getAD() or var_2_7.AP ~= iter_2_9:getAP() then
						arg_2_0.purpleFighterInfo_[iter_2_9] = {
							AD = iter_2_9:getAD(),
							AP = iter_2_9:getAP()
						}

						local var_2_8 = arg_2_0:newBuff({
							var_0_12
						}, arg_2_0, arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

						if arg_2_0.skinSkillID_ == var_0_19 then
							local var_2_9 = var_0_5.aliveTargets(arg_2_0.selfTeam_)

							if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
								local var_2_10 = arg_2_0:createAttackUnits(var_2_9, var_0_19)

								for iter_2_10, iter_2_11 in ipairs(var_2_10) do
									iter_2_11.basicHarm = var_2_8[1]:totalDHarm()

									table.insert(arg_2_0.moveAttackUnits_, iter_2_11)
									table.insert(arg_2_0.records_.special_units, iter_2_11)
								end
							end

							for iter_2_12, iter_2_13 in ipairs(var_2_9) do
								if iter_2_13 ~= arg_2_0 then
									local var_2_11 = arg_2_0:newBuff({
										var_0_24
									}, iter_2_13, var_0_19)

									var_2_11[1].manualDharm = var_2_8[1]:totalDHarm()

									iter_2_13:addBuffs(var_2_11)
								end
							end
						end

						arg_2_0:addBuffs(var_2_8)

						arg_2_0.purpleCount = arg_2_0.purpleCount + 1
					end
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD1(arg_3_0)
	local var_3_0
	local var_3_1 = 0
	local var_3_2 = var_0_6:scope(arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	for iter_3_0, iter_3_1 in pairs(arg_3_0.blueHarmFighter_) do
		if var_3_1 < iter_3_1 and not iter_3_0:isDeath() and not iter_3_0:isAffected() and iter_3_0:getTeamType() ~= arg_3_0:getTeamType() and var_3_2 >= math.abs(iter_3_0:getX() - arg_3_0:getX()) then
			var_3_0 = iter_3_0
			var_3_1 = iter_3_1
		end
	end

	return {
		var_3_0
	}
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == var_0_20 then
		local var_4_0 = arg_4_0:newBuff({
			var_0_22,
			var_0_23
		}, arg_4_0, var_0_19)

		var_4_0[1].manualRevise = arg_4_1.target:getAD() * var_0_21
		var_4_0[2].manualRevise = arg_4_1.target:getAP() * var_0_21

		arg_4_0:addBuffs(var_4_0, arg_4_0, var_0_19)

		local var_4_1 = arg_4_0:newBuff({
			var_0_22,
			var_0_23
		}, arg_4_1.target, var_0_19)

		var_4_1[1].manualRevise = -arg_4_1.target:getAD() * var_0_21
		var_4_1[2].manualRevise = -arg_4_1.target:getAP() * var_0_21

		arg_4_1.target:addBuffs(var_4_1, arg_4_1.target, var_0_19)
	end

	if arg_4_1.skillID == arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) and arg_4_1.target ~= arg_4_0 then
		arg_4_0:useBlueSkillToSelf()
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	local var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5 = var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)

	if arg_5_1.skillID == arg_5_0:getEnergySkillID() then
		var_5_2 = (var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_17) * (arg_5_1.target:getAD() + arg_5_1.target:getAP()) * var_0_18

		if var_5_2 > arg_5_0:getAD() + arg_5_0:getAP() then
			var_5_2 = arg_5_0:getAD() + arg_5_0:getAP()
		end
	end

	return var_5_0, var_5_1, var_5_2, var_5_3, var_5_4, var_5_5
end

function var_0_3.useBlueSkillToSelf(arg_6_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	local var_6_0
	local var_6_1
	local var_6_2 = var_0_6:scope(arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	for iter_6_0, iter_6_1 in pairs(arg_6_0.blueHarmFighter_) do
		if (not var_6_1 or iter_6_1 < var_6_1) and not iter_6_0:isDeath() and not iter_6_0:isAffected() and iter_6_0:getTeamType() == arg_6_0:getTeamType() and var_6_2 >= math.abs(iter_6_0:getX() - arg_6_0:getX()) then
			var_6_0 = iter_6_0
			var_6_1 = iter_6_1
		end
	end

	if not var_6_0 then
		return
	end

	local var_6_3 = arg_6_0:createAttackUnits({
		arg_6_0
	}, var_0_11)

	for iter_6_2, iter_6_3 in ipairs(var_6_3) do
		table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
		table.insert(arg_6_0.records_.special_units, iter_6_3)
	end
end

function var_0_3.buffAddAction(arg_7_0, arg_7_1)
	var_0_3.super:buffAddAction(arg_7_0, arg_7_1)

	if arg_7_1:getTableID() == var_0_10 then
		if arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() then
			local var_7_0 = var_0_7 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) + var_0_8

			arg_7_0.blueChangeAP_ = arg_7_1.target:getAP() * var_7_0
			arg_7_1.manualRevise = -arg_7_0.blueChangeAP_
		else
			arg_7_1.manualRevise = arg_7_0.blueChangeAP_
		end
	elseif arg_7_1:getTableID() == var_0_9 then
		local var_7_1 = var_0_7 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) + var_0_8

		if arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() then
			arg_7_0.blueChangeAD_ = arg_7_1.target:getAD() * var_7_1
			arg_7_1.manualRevise = -arg_7_0.blueChangeAD_
		else
			arg_7_1.manualRevise = arg_7_0.blueChangeAD_
		end
	elseif arg_7_1:getTableID() == var_0_15 then
		local var_7_2 = var_0_16 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_17

		arg_7_1.manualRevise = -arg_7_1.target:getAP() * var_7_2

		if arg_7_1.target:isBoss() then
			arg_7_1.manualRevise = arg_7_1.manualRevise / 10
		end
	elseif arg_7_1:getTableID() == var_0_14 then
		local var_7_3 = var_0_16 * arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy) + var_0_17

		arg_7_1.manualRevise = -arg_7_1.target:getAD() * var_7_3

		if arg_7_1.target:isBoss() then
			arg_7_1.manualRevise = arg_7_1.manualRevise / 10
		end
	end
end

function var_0_3.newBuff(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_1) do
		local var_8_1 = var_0_4.new({
			tableID = iter_8_1,
			start = var_0_1.ctx.battle.count,
			level = arg_8_0:getSkillLevelByID(arg_8_3) or arg_8_0:getLevel(),
			skillID = arg_8_3,
			fighter = arg_8_0,
			target = arg_8_2
		})

		var_8_1:setIsHit(true)
		var_8_1:setDirection(arg_8_0:getFighterModel():getFlipX())
		table.insert(var_8_0, var_8_1)
	end

	return var_8_0
end

return var_0_3
