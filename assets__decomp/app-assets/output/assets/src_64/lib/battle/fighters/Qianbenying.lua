local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Qianbenying", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = 0.5
local var_0_9 = 0
local var_0_10 = 10
local var_0_11 = 300
local var_0_12 = 180
local var_0_13 = 0
local var_0_14 = 0.005
local var_0_15 = 10000583
local var_0_16 = 40010450
local var_0_17 = 80010131
local var_0_18 = 80020131
local var_0_19 = 0.4
local var_0_20 = 40012033
local var_0_21 = 50010131
local var_0_22 = 10001888

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
	arg_1_0:listenInfo("buff_info")
end

function var_0_3.init(arg_2_0)
	var_0_3.super.init(arg_2_0)

	arg_2_0.shanbiCount_ = 0
	arg_2_0.energySkillTable_ = {}
end

function var_0_3.populateWithHero(arg_3_0, arg_3_1)
	var_0_3.super.populateWithHero(arg_3_0, arg_3_1)

	if arg_3_0.skinSkillIndex_ == 2 then
		arg_3_0.EnergySkill = var_0_22
	else
		arg_3_0.EnergySkill = var_0_21
	end
end

function var_0_3.deathFeedback(arg_4_0, arg_4_1)
	var_0_3.super.deathFeedback(arg_4_0, arg_4_1)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_4_0 = #arg_4_0.energySkillTable_, 1, -1 do
			local var_4_0 = arg_4_0.energySkillTable_[iter_4_0]
			local var_4_1 = var_4_0.target
			local var_4_2 = var_4_0.count

			if arg_4_1 == var_4_1 and var_4_2 > 0 then
				arg_4_0.energySkillTable_[iter_4_0].count = 0

				local var_4_3 = arg_4_0:createAttackUnits({
					arg_4_0
				}, var_0_15)

				for iter_4_1, iter_4_2 in ipairs(var_4_3) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_2)
					table.insert(arg_4_0.records_.special_units, iter_4_2)
				end
			end
		end
	end
end

function var_0_3.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
	if arg_5_1.skillID == arg_5_0.EnergySkill then
		local var_5_0 = var_0_13 + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_5_1 = math.min(arg_5_1.target:getHp() * var_5_0, arg_5_0:getHpLimit())
		local var_5_2 = {
			count = var_0_11,
			target = arg_5_1.target,
			hp = var_5_1
		}

		table.insert(arg_5_0.energySkillTable_, var_5_2)

		arg_5_4 = arg_5_4 + var_5_1
	elseif arg_5_1.skillID == var_0_17 then
		local var_5_3 = var_0_13 + var_0_14 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy)
		local var_5_4 = math.min(arg_5_1.target:getHp() * var_5_3 / 2, arg_5_0:getHpLimit())
		local var_5_5 = {
			count = var_0_11,
			target = arg_5_1.target,
			hp = var_5_4
		}

		table.insert(arg_5_0.energySkillTable_, var_5_5)

		arg_5_4 = arg_5_4 + var_5_4
	elseif arg_5_1.skillID == var_0_15 then
		local var_5_6

		for iter_5_0, iter_5_1 in ipairs(arg_5_0.energySkillTable_) do
			if iter_5_1.count == 0 then
				var_5_6 = iter_5_0
				arg_5_5 = arg_5_5 + iter_5_1.hp

				break
			end
		end

		if var_5_6 then
			table.remove(arg_5_0.energySkillTable_, var_5_6)
		end
	end

	return var_0_3.super.updateUnitDataByFighter(arg_5_0, arg_5_1, arg_5_2, arg_5_3, arg_5_4, arg_5_5, arg_5_6, arg_5_7)
end

function var_0_3.applySingleUnit(arg_6_0, arg_6_1)
	if arg_6_0.skinSkillID_ == var_0_17 and arg_6_1.skillID == arg_6_0.EnergySkill then
		local var_6_0 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0.targetTeam_) do
			if iter_6_1 ~= arg_6_1.target and not iter_6_1:isDeath() and not iter_6_1:isAffected() then
				table.insert(var_6_0, iter_6_1)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_6_1 = arg_6_0:createAttackUnits(var_6_0, var_0_17)

			for iter_6_2, iter_6_3 in ipairs(var_6_1) do
				table.insert(arg_6_0.moveAttackUnits_, iter_6_3)
				table.insert(arg_6_0.records_.special_units, iter_6_3)
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_6_0, arg_6_1)

	if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_18 and arg_6_1.skillID == arg_6_0.EnergySkill then
		for iter_6_4, iter_6_5 in ipairs(arg_6_0.energySkillTable_) do
			if iter_6_5.target == arg_6_1.target then
				for iter_6_6, iter_6_7 in ipairs(arg_6_0.selfTeam_) do
					if not iter_6_7:isDeath() and not iter_6_7:isAffected() then
						local var_6_2 = arg_6_0:createNewBuffs({
							var_0_20
						}, iter_6_7, arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

						var_6_2[1].manualDharm = iter_6_5.hp * var_0_19

						iter_6_7:addBuffs(var_6_2)
					end
				end

				break
			end
		end
	end
end

function var_0_3.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5 = var_0_3.super.updateUnitDataByTarget(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Blue) > 0 and not var_7_0 and not arg_7_0:isCreatingUnits() and arg_7_1.fighter:getTeamType() ~= arg_7_0:getTeamType() and arg_7_0.shanbiCount_ <= 0 then
		arg_7_0.shanbiCount_ = var_0_12
		var_7_0 = true

		if arg_7_1.fighter:getX() - arg_7_0:getX() < 0 then
			arg_7_0:flipX(true)
		else
			arg_7_0:flipX(false)
		end

		local var_7_6 = arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue)
		local var_7_7 = var_0_7:sound(var_7_6)

		var_0_1.ctx.battle.pushSoundQueue(var_7_7)

		local var_7_8 = var_0_7:attackIndex(var_7_6)

		arg_7_0:playAttack(var_7_8)

		arg_7_0.unitSkills_ = var_0_4.new({
			fighter = arg_7_0,
			skillID = var_7_6
		})

		arg_7_0:beginAttackEnd(arg_7_0.unitSkills_)

		arg_7_0.manualTarget_ = {
			arg_7_1.fighter
		}
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

function var_0_3.toDoPerFrames(arg_8_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_8_0 = #arg_8_0.energySkillTable_, 1, -1 do
			local var_8_0 = arg_8_0.energySkillTable_[iter_8_0]

			if var_8_0.count > 0 then
				var_8_0.count = var_8_0.count - 1

				if var_8_0.count == 0 then
					local var_8_1

					if not var_8_0.target:isDeath() then
						if arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_18 then
							local var_8_2 = false

							for iter_8_1, iter_8_2 in ipairs(arg_8_0.selfTeam_) do
								if iter_8_2:isHasBuffByID(var_0_20) then
									var_8_2 = true

									break
								end
							end

							if var_8_2 then
								var_8_1 = var_8_0.target
								arg_8_0.harms = math.max(0, arg_8_0.harms - var_8_0.hp)
							end
						else
							var_8_1 = var_8_0.target
							arg_8_0.harms = math.max(0, arg_8_0.harms - var_8_0.hp)
						end
					elseif not arg_8_0:isDeath() then
						var_8_1 = arg_8_0
					end

					if var_8_1 then
						local var_8_3 = arg_8_0:createAttackUnits({
							var_8_1
						}, var_0_15)

						for iter_8_3, iter_8_4 in ipairs(var_8_3) do
							table.insert(arg_8_0.moveAttackUnits_, iter_8_4)
							table.insert(arg_8_0.records_.special_units, iter_8_4)
						end
					end
				end
			end
		end
	end

	if arg_8_0.shanbiCount_ > 0 then
		arg_8_0.shanbiCount_ = arg_8_0.shanbiCount_ - 1
	end

	if arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 then
		for iter_8_5, iter_8_6 in ipairs(arg_8_0:getInfoByKey("buff_info")) do
			local var_8_4 = iter_8_6:getTableID()
			local var_8_5 = var_0_6:type(var_8_4)
			local var_8_6 = iter_8_6.target

			if var_8_6:getTeamType() ~= arg_8_0:getTeamType() and var_8_5 == var_0_2.BuffType.CONTINUE_HARM and var_0_6:baseMana(var_8_4) == 0 and var_0_6:stepBaseMana(var_8_4) == 0 then
				local var_8_7 = var_0_9 + var_0_10 * arg_8_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
				local var_8_8 = var_8_6:getTempHpLimit()
				local var_8_9 = math.min(var_8_6:getHpLimit() * var_0_8, var_8_7 + var_8_8)

				var_8_6:setTempHpLimit(var_8_9)

				local var_8_10 = var_8_6:getHpLimit()

				if var_8_10 < var_8_6:getHp() then
					var_8_6:updateHp(var_8_10)
				end

				if not var_8_6:isHasBuffByID(var_0_16) then
					local var_8_11 = arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
					local var_8_12 = var_0_5.new({
						tableID = var_0_16,
						start = var_0_1.ctx.battle.count,
						level = arg_8_0:getSkillLevelByID(var_8_11),
						skillID = var_8_11,
						fighter = arg_8_0,
						target = var_8_6
					})

					var_8_12:setIsHit(true)
					var_8_12:setDirection(arg_8_0:getFighterModel():getFlipX())
					var_8_6:addBuffs({
						var_8_12
					})
				end
			end
		end
	end
end

return var_0_3
