local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Huangzu", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = 40011447
local var_0_8 = 10001351
local var_0_9 = 10001352
local var_0_10 = 40011446
local var_0_11 = 20010209
local var_0_12 = 10001864
local var_0_13 = 10001959

function var_0_3.populateWithHero(arg_1_0, arg_1_1)
	var_0_3.super.populateWithHero(arg_1_0, arg_1_1)

	if arg_1_0.skinSkillIndex_ == 1 then
		arg_1_0.GreenSkillID = var_0_12
		arg_1_0.IcedLemonadeBuffID = 40011444
		arg_1_0.CoolLemonadeAtkBuffID = 40011445
		arg_1_0.EnergyGainBuffSkillID = 10001349
		arg_1_0.EnergyDamageSkillID = 10001350
		arg_1_0.EnergySkillID = 50010209
		arg_1_0.GreenDamageSkillID = 10001367
	elseif arg_1_0.skinSkillIndex_ == 2 then
		arg_1_0.GreenSkillID = 10002491
		arg_1_0.IcedLemonadeBuffID = 40012685
		arg_1_0.CoolLemonadeAtkBuffID = 40012686
		arg_1_0.EnergyGainBuffSkillID = 10002488
		arg_1_0.EnergyDamageSkillID = 10002489
		arg_1_0.EnergySkillID = 10002492
		arg_1_0.GreenDamageSkillID = 10002493
	else
		arg_1_0.GreenSkillID = var_0_11
		arg_1_0.IcedLemonadeBuffID = 40011444
		arg_1_0.CoolLemonadeAtkBuffID = 40011445
		arg_1_0.EnergyGainBuffSkillID = 10001349
		arg_1_0.EnergyDamageSkillID = 10001350
		arg_1_0.EnergySkillID = 50010209
		arg_1_0.GreenDamageSkillID = 10001367
	end
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_1.target

	if var_0_6:father(arg_2_1.skillID) == arg_2_0:getSkillByColor(var_0_2.SKILL_INDEX.Energy) then
		if arg_2_1.skillID == arg_2_0.EnergyGainBuffSkillID and var_2_0:getTeamType() == arg_2_0:getTeamType() then
			if var_2_0:isHasBuffByID(var_0_7) then
				local var_2_1 = var_0_5.new({
					tableID = var_0_10,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByID(arg_2_0.EnergySkillID),
					skillID = arg_2_0.EnergySkillID,
					fighter = arg_2_0,
					target = var_2_0
				})

				var_2_0:addBuffs({
					var_2_1
				})
			else
				local var_2_2 = var_0_5.new({
					tableID = arg_2_0.CoolLemonadeAtkBuffID,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByID(arg_2_0.EnergySkillID),
					skillID = arg_2_0.EnergySkillID,
					fighter = arg_2_0,
					target = var_2_0
				})
				local var_2_3 = var_0_5.new({
					tableID = var_0_7,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByID(arg_2_0.EnergySkillID),
					skillID = arg_2_0.EnergySkillID,
					fighter = arg_2_0,
					target = var_2_0
				})

				var_2_0:addBuffs({
					var_2_2,
					var_2_3
				})
			end
		elseif arg_2_1.skillID == arg_2_0.EnergyDamageSkillID and var_2_0:getTeamType() ~= arg_2_0:getTeamType() then
			if var_2_0:isHasBuffByID(arg_2_0.IcedLemonadeBuffID) then
				var_2_0:removeBuffByID(arg_2_0.IcedLemonadeBuffID)
			else
				arg_2_1.basicHarm = 0

				local var_2_4 = var_0_5.new({
					tableID = arg_2_0.IcedLemonadeBuffID,
					start = var_0_1.ctx.battle.count,
					level = arg_2_0:getSkillLevelByID(arg_2_0.EnergySkillID),
					skillID = arg_2_0.EnergySkillID,
					fighter = arg_2_0,
					target = var_2_0
				})

				var_2_0:addBuffs({
					var_2_4
				})
			end
		end
	end

	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == arg_2_0.GreenSkillID and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_2_5 = {}
		local var_2_6 = var_0_6:scope(arg_2_0.GreenDamageSkillID) / 2

		for iter_2_0, iter_2_1 in ipairs(arg_2_0.sideTeam_) do
			if not iter_2_1:isDeath() and not iter_2_1:isAffected() and iter_2_1 ~= var_2_0 and var_2_6 > math.abs(iter_2_1:getX() - var_2_0:getX()) then
				table.insert(var_2_5, iter_2_1)
			end
		end

		local var_2_7 = arg_2_0:createAttackUnits(var_2_5, arg_2_0.GreenDamageSkillID)

		for iter_2_2, iter_2_3 in ipairs(var_2_7) do
			table.insert(arg_2_0.moveAttackUnits_, iter_2_3)
			table.insert(arg_2_0.records_.special_units, iter_2_3)
		end
	end
end

function var_0_3.buffAddAction(arg_3_0, arg_3_1)
	local var_3_0 = arg_3_1.target

	if arg_3_1.tableID_ == arg_3_0.CoolLemonadeAtkBuffID then
		if arg_3_0.isSkinSkillOn_ and var_3_0:getTeamType() == arg_3_0:getTeamType() then
			local var_3_1 = var_3_0:getBuffs()

			for iter_3_0, iter_3_1 in ipairs(var_3_1) do
				if iter_3_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and iter_3_1:canRemove() then
					var_3_0:removeBuffs(iter_3_1)

					break
				end
			end
		end

		local var_3_2 = false

		for iter_3_2, iter_3_3 in ipairs(arg_3_0.sideTeam_) do
			if not iter_3_3:isDeath() then
				for iter_3_4, iter_3_5 in ipairs(iter_3_3:getBuffsByID(arg_3_0.IcedLemonadeBuffID)) do
					var_3_2 = true

					iter_3_5:setActNum(2)
				end
			end
		end

		if var_3_2 then
			for iter_3_6, iter_3_7 in ipairs(arg_3_0.selfTeam_) do
				if not iter_3_7:isDeath() then
					for iter_3_8, iter_3_9 in ipairs(iter_3_7:getBuffsByID(arg_3_0.CoolLemonadeAtkBuffID)) do
						iter_3_9:setActNum(2)
					end
				end
			end

			arg_3_1:setActNum(2)
		else
			arg_3_1:setActNum(1)
		end
	elseif arg_3_1.tableID_ == arg_3_0.IcedLemonadeBuffID then
		if arg_3_0.isSkinSkillOn_ and var_3_0:getTeamType() ~= arg_3_0:getTeamType() then
			local var_3_3 = var_3_0:getBuffs()

			for iter_3_10, iter_3_11 in ipairs(var_3_3) do
				if iter_3_11:getBuffForm() == var_0_2.BuffForm.GAIN and iter_3_11:canRemove() then
					var_3_0:removeBuffs(iter_3_11)

					break
				end
			end
		end

		local var_3_4 = false

		for iter_3_12, iter_3_13 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_13:isDeath() then
				for iter_3_14, iter_3_15 in ipairs(iter_3_13:getBuffsByID(arg_3_0.CoolLemonadeAtkBuffID)) do
					var_3_4 = true

					iter_3_15:setActNum(2)
				end
			end
		end

		if var_3_4 then
			for iter_3_16, iter_3_17 in ipairs(arg_3_0.sideTeam_) do
				if not iter_3_17:isDeath() then
					for iter_3_18, iter_3_19 in ipairs(iter_3_17:getBuffsByID(arg_3_0.IcedLemonadeBuffID)) do
						iter_3_19:setActNum(2)
					end
				end
			end

			arg_3_1:setActNum(2)
		else
			arg_3_1:setActNum(1)
		end
	end
end

function var_0_3.buffRemoveAction(arg_4_0, arg_4_1)
	if arg_4_1.tableID_ == arg_4_0.CoolLemonadeAtkBuffID then
		for iter_4_0, iter_4_1 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_1:isDeath() and iter_4_1:isHasBuffByID(arg_4_0.CoolLemonadeAtkBuffID) then
				return
			end
		end

		for iter_4_2, iter_4_3 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_3:isDeath() then
				for iter_4_4, iter_4_5 in ipairs(iter_4_3:getBuffsByID(arg_4_0.IcedLemonadeBuffID)) do
					iter_4_5:setActNum(1)
				end
			end
		end
	elseif arg_4_1.tableID_ == arg_4_0.IcedLemonadeBuffID then
		for iter_4_6, iter_4_7 in ipairs(arg_4_0.sideTeam_) do
			if not iter_4_7:isDeath() and iter_4_7:isHasBuffByID(arg_4_0.IcedLemonadeBuffID) then
				return
			end
		end

		for iter_4_8, iter_4_9 in ipairs(arg_4_0.selfTeam_) do
			if not iter_4_9:isDeath() then
				for iter_4_10, iter_4_11 in ipairs(iter_4_9:getBuffsByID(arg_4_0.CoolLemonadeAtkBuffID)) do
					iter_4_11:setActNum(1)
				end
			end
		end
	end
end

function var_0_3.deathFeedback(arg_5_0, arg_5_1)
	if arg_5_1:getTeamType() == arg_5_0:getTeamType() then
		for iter_5_0, iter_5_1 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_1:isDeath() and iter_5_1:isHasBuffByID(arg_5_0.CoolLemonadeAtkBuffID) then
				return
			end
		end

		for iter_5_2, iter_5_3 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_3:isDeath() then
				for iter_5_4, iter_5_5 in ipairs(iter_5_3:getBuffsByID(arg_5_0.IcedLemonadeBuffID)) do
					iter_5_5:setActNum(1)
				end
			end
		end
	else
		for iter_5_6, iter_5_7 in ipairs(arg_5_0.sideTeam_) do
			if not iter_5_7:isDeath() and iter_5_7:isHasBuffByID(arg_5_0.IcedLemonadeBuffID) then
				return
			end
		end

		for iter_5_8, iter_5_9 in ipairs(arg_5_0.selfTeam_) do
			if not iter_5_9:isDeath() then
				for iter_5_10, iter_5_11 in ipairs(iter_5_9:getBuffsByID(arg_5_0.CoolLemonadeAtkBuffID)) do
					iter_5_11:setActNum(1)
				end
			end
		end
	end
end

function var_0_3.selectTargetByTypeD3(arg_6_0, arg_6_1, arg_6_2)
	if not var_0_4.timeSeed_ then
		var_0_4.timeSeed_ = 1
	end

	math.randomseed(tonumber(tostring(os.time() + var_0_4.timeSeed_):reverse():sub(1, 6)))

	local var_6_0 = math.random(tonumber(os.time()))

	var_0_4.timeSeed_ = var_6_0

	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_0.selfTeam_) do
		if not iter_6_1:isDeath() and not iter_6_1:isAffected() and iter_6_1 ~= arg_6_0 and iter_6_1.hero_:getHeroType() == var_0_2.AttributeType.AGILE then
			table.insert(var_6_1, iter_6_1)
		end
	end

	math.randomseed(var_6_0)

	local var_6_2 = {}

	table.insert(var_6_2, arg_6_0)

	if #var_6_1 > 0 then
		table.insert(var_6_2, var_6_1[math.random(#var_6_1)])
	end

	return var_6_2
end

function var_0_3.updateUnitDataBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = arg_7_2
	local var_7_1 = arg_7_3
	local var_7_2 = arg_7_4
	local var_7_3 = arg_7_5
	local var_7_4 = arg_7_6
	local var_7_5 = arg_7_7

	if arg_7_0:getSkillLevelByID(arg_7_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)) > 0 and var_7_2 > 0 and arg_7_1.skillID ~= var_0_8 and arg_7_1.fighter:getTeamType() == arg_7_0:getTeamType() and arg_7_1.fighter:isHasBuffByID(arg_7_0.CoolLemonadeAtkBuffID) and arg_7_1.target:getTeamType() ~= arg_7_0:getTeamType() and arg_7_1.target:isHasBuffByID(arg_7_0.IcedLemonadeBuffID) then
		if arg_7_1.skillID ~= var_0_13 then
			local var_7_6 = arg_7_0:createAttackUnits({
				arg_7_1.target
			}, var_0_8)

			for iter_7_0, iter_7_1 in ipairs(var_7_6) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_1)
				table.insert(arg_7_0.records_.special_units, iter_7_1)
			end
		end

		local var_7_7 = arg_7_0:createAttackUnits({
			arg_7_1.fighter
		}, var_0_9)

		for iter_7_2, iter_7_3 in ipairs(var_7_7) do
			table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
			table.insert(arg_7_0.records_.special_units, iter_7_3)
		end
	end

	return var_7_0, var_7_1, var_7_2, var_7_3, var_7_4, var_7_5
end

return var_0_3
