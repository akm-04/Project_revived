local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Badeer", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_6 = var_0_2.tables.skill
local var_0_7 = {}
local var_0_8 = 30
local var_0_9 = 60
local var_0_10 = 60
local var_0_11 = 20
local var_0_12 = 0
local var_0_13 = 0.006
local var_0_14 = 10001593
local var_0_15 = 40011695
local var_0_16 = -110
local var_0_17 = 10001596
local var_0_18 = 810002
local var_0_19 = 60
local var_0_20 = var_0_2.tables.elementEquip
local var_0_21 = 20001445

function var_0_3.ctor(arg_1_0, arg_1_1)
	var_0_3.super.ctor(arg_1_0, arg_1_1)
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.BlueSubSkillLight = 10002112
		arg_2_0.BlueSubSkillDark = 10002113
		arg_2_0.BlueSubSkillChaos = 10002114
		arg_2_0.PurpleSkillPhase2 = 10002116
		arg_2_0.EnergySubSkill1 = 10002117
		arg_2_0.EnergySubSkill2 = 10002118
		arg_2_0.EnergySkillID = 10002123
		arg_2_0.LightMarkBuff = 40012248
		arg_2_0.DarkMarkBuff = 40012249
		arg_2_0.ChaosMarkBuff = 40012250
		arg_2_0.LightDarkBuff = 40012251
		arg_2_0.DarkChaosBuff = 40012252
		arg_2_0.ChaosLightBuff = 40012253
		var_0_7[arg_2_0.LightMarkBuff] = {}
		var_0_7[arg_2_0.DarkMarkBuff] = {}
		var_0_7[arg_2_0.ChaosMarkBuff] = {}
		var_0_7[arg_2_0.LightMarkBuff][arg_2_0.DarkMarkBuff] = arg_2_0.LightDarkBuff
		var_0_7[arg_2_0.DarkMarkBuff][arg_2_0.LightMarkBuff] = arg_2_0.LightDarkBuff
		var_0_7[arg_2_0.DarkMarkBuff][arg_2_0.ChaosMarkBuff] = arg_2_0.DarkChaosBuff
		var_0_7[arg_2_0.ChaosMarkBuff][arg_2_0.DarkMarkBuff] = arg_2_0.DarkChaosBuff
		var_0_7[arg_2_0.ChaosMarkBuff][arg_2_0.LightMarkBuff] = arg_2_0.ChaosLightBuff
		var_0_7[arg_2_0.LightMarkBuff][arg_2_0.ChaosMarkBuff] = arg_2_0.ChaosLightBuff
	else
		arg_2_0.BlueSubSkillLight = 10001590
		arg_2_0.BlueSubSkillDark = 10001591
		arg_2_0.BlueSubSkillChaos = 10001592
		arg_2_0.PurpleSkillPhase2 = 10001595
		arg_2_0.EnergySubSkill1 = 10001598
		arg_2_0.EnergySubSkill2 = 10001599
		arg_2_0.EnergySkillID = 510002
		arg_2_0.LightMarkBuff = 40011696
		arg_2_0.DarkMarkBuff = 40011697
		arg_2_0.ChaosMarkBuff = 40011698
		arg_2_0.LightDarkBuff = 40011699
		arg_2_0.DarkChaosBuff = 40011700
		arg_2_0.ChaosLightBuff = 40011701
		var_0_7[arg_2_0.LightMarkBuff] = {}
		var_0_7[arg_2_0.DarkMarkBuff] = {}
		var_0_7[arg_2_0.ChaosMarkBuff] = {}
		var_0_7[arg_2_0.LightMarkBuff][arg_2_0.DarkMarkBuff] = arg_2_0.LightDarkBuff
		var_0_7[arg_2_0.DarkMarkBuff][arg_2_0.LightMarkBuff] = arg_2_0.LightDarkBuff
		var_0_7[arg_2_0.DarkMarkBuff][arg_2_0.ChaosMarkBuff] = arg_2_0.DarkChaosBuff
		var_0_7[arg_2_0.ChaosMarkBuff][arg_2_0.DarkMarkBuff] = arg_2_0.DarkChaosBuff
		var_0_7[arg_2_0.ChaosMarkBuff][arg_2_0.LightMarkBuff] = arg_2_0.ChaosLightBuff
		var_0_7[arg_2_0.LightMarkBuff][arg_2_0.ChaosMarkBuff] = arg_2_0.ChaosLightBuff
	end
end

function var_0_3.init(arg_3_0)
	var_0_3.super.init(arg_3_0)

	arg_3_0.lightBuffCount = {}
	arg_3_0.darkBuffCount = {}
	arg_3_0.chaosBuffCount = {}
	arg_3_0.skinCDCount = 0
end

function var_0_3.applySingleUnit(arg_4_0, arg_4_1)
	local var_4_0 = arg_4_1.target

	if arg_4_1.skillID == arg_4_0:getPugongID() and arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) > 0 and arg_4_0:getTeamType() ~= var_4_0:getTeamType() and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_4_1 = arg_4_0:createAttackUnits({
			var_4_0
		}, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

		for iter_4_0, iter_4_1 in ipairs(var_4_1) do
			local var_4_2 = (var_0_12 + arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Green) * var_0_13) * arg_4_0:getAP()

			iter_4_1:setExtraHarm(var_4_2)
			table.insert(arg_4_0.moveAttackUnits_, iter_4_1)
			table.insert(arg_4_0.records_.special_units, iter_4_1)
		end
	end

	var_0_3.super.applySingleUnit(arg_4_0, arg_4_1)

	if arg_4_1.skillID == arg_4_0.PurpleSkillPhase2 then
		local var_4_3 = var_4_0:getBuffByID(var_0_15)

		if var_4_3 and arg_4_0.purpleCenterX then
			var_4_3.resetXchange_ = (arg_4_0.purpleCenterX - var_4_0:getX()) * (arg_4_0:getFlipX() and -1 or 1)
			var_4_3.resetYchange_ = arg_4_0.purpleCenterY - var_4_0:getY()
			var_4_0.buffMovePath_ = var_4_3:getPath()
		end
	end

	if arg_4_1.skillID == arg_4_0.EnergySkillID then
		arg_4_0:createSkillByID(arg_4_0.EnergySubSkill1, arg_4_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy), var_0_6:attackIndex(arg_4_0.EnergySubSkill1))

		arg_4_0.energyCount = 0
	end

	if arg_4_1.skillID == arg_4_0.EnergySubSkill1 and arg_4_0.energyCount and arg_4_0.energyCount > 90 then
		arg_4_0.energyCount = nil

		local var_4_4 = var_0_5.B2(arg_4_0)
		local var_4_5 = {
			0,
			0,
			0
		}

		for iter_4_2, iter_4_3 in ipairs(var_4_4) do
			for iter_4_4, iter_4_5 in ipairs(iter_4_3:getBuffs()) do
				local var_4_6 = true

				if iter_4_5:getTableID() == arg_4_0.LightMarkBuff then
					var_4_5[1] = var_4_5[1] + 1
				elseif iter_4_5:getTableID() == arg_4_0.DarkMarkBuff then
					var_4_5[2] = var_4_5[2] + 1
				elseif iter_4_5:getTableID() == arg_4_0.ChaosMarkBuff then
					var_4_5[3] = var_4_5[3] + 1
				elseif iter_4_5:getTableID() == arg_4_0.LightDarkBuff then
					var_4_5[1] = var_4_5[1] + 1
					var_4_5[2] = var_4_5[2] + 1
				elseif iter_4_5:getTableID() == arg_4_0.DarkChaosBuff then
					var_4_5[2] = var_4_5[2] + 1
					var_4_5[3] = var_4_5[3] + 1
				elseif iter_4_5:getTableID() == arg_4_0.ChaosLightBuff then
					var_4_5[3] = var_4_5[3] + 1
					var_4_5[1] = var_4_5[1] + 1
				else
					var_4_6 = false
				end

				if var_4_6 then
					iter_4_3:removeBuffs(iter_4_5)
				end
			end
		end

		for iter_4_6 = 1, math.min(var_4_5[1], var_4_5[2], var_4_5[3]) do
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_4_7 = arg_4_0:createAttackUnits(var_4_4, arg_4_0.EnergySubSkill2)

				for iter_4_7, iter_4_8 in ipairs(var_4_7) do
					table.insert(arg_4_0.moveAttackUnits_, iter_4_8)
					table.insert(arg_4_0.records_.special_units, iter_4_8)
				end
			end
		end
	end
end

function var_0_3.forceDie(arg_5_0)
	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		for iter_5_2, iter_5_3 in ipairs(iter_5_1:getBuffs()) do
			if iter_5_3:getTableID() == arg_5_0.LightMarkBuff or iter_5_3:getTableID() == arg_5_0.DarkMarkBuff or iter_5_3:getTableID() == arg_5_0.ChaosMarkBuff or iter_5_3:getTableID() == arg_5_0.LightDarkBuff or iter_5_3:getTableID() == arg_5_0.DarkChaosBuff or iter_5_3:getTableID() == arg_5_0.ChaosLightBuff then
				iter_5_1:removeBuffs(iter_5_3)
			end
		end
	end

	var_0_3.super.forceDie(arg_5_0)
end

function var_0_3.toDoPerFrames(arg_6_0)
	if arg_6_0:isDeath() then
		return
	end

	if arg_6_0.energyCount then
		arg_6_0.energyCount = arg_6_0.energyCount + 1

		if arg_6_0.energyCount == 4 or arg_6_0.energyCount == 10 or arg_6_0.energyCount == 18 or arg_6_0.energyCount == 24 or arg_6_0.energyCount == 34 or arg_6_0.energyCount == 45 or arg_6_0.energyCount == 52 or arg_6_0.energyCount == 61 or arg_6_0.energyCount == 73 or arg_6_0.energyCount == 84 then
			local var_6_0 = var_0_5.B2(arg_6_0, arg_6_0.EnergySubSkill1)

			if var_0_1.ctx.battle.unitBottomLayer.getContentSize then
				local var_6_1 = var_0_1.ctx.battle.unitBottomLayer:getContentSize()

				if type(var_6_1) == "table" and var_6_1.width and var_6_1.height then
					arg_6_0.energyEffect = var_0_1.ctx.battle.getSpine(arg_6_0.EnergySubSkill1, "area", 1)

					arg_6_0.energyEffect:addTo(var_0_1.ctx.battle.unitBottomLayer)
					arg_6_0.energyEffect:pos(var_6_1.width / 2, var_6_1.height / 2)
					arg_6_0.energyEffect:setScale(0.6 / var_0_1.ctx.battle.unitBottomLayer:getScale())
					arg_6_0.energyEffect:playOnce()
				end
			end

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_6_2 = arg_6_0:createAttackUnits(var_6_0, arg_6_0.EnergySubSkill1)

				for iter_6_0, iter_6_1 in ipairs(var_6_2) do
					table.insert(arg_6_0.moveAttackUnits_, iter_6_1)
					table.insert(arg_6_0.records_.special_units, iter_6_1)
				end
			end
		end
	end

	if arg_6_0.isSkinSkillOn_ and arg_6_0.skinSkillID_ == var_0_18 then
		arg_6_0.skinCDCount = arg_6_0.skinCDCount - 1
	end
end

function var_0_3.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	local var_7_0 = var_0_1.ctx.battle.count
	local var_7_1 = arg_7_1.target:getBuffByID(arg_7_0.LightMarkBuff) or arg_7_1.target:getBuffByID(arg_7_0.LightDarkBuff) or arg_7_1.target:getBuffByID(arg_7_0.ChaosLightBuff)
	local var_7_2 = arg_7_1.target:getBuffByID(arg_7_0.DarkMarkBuff) or arg_7_1.target:getBuffByID(arg_7_0.DarkChaosBuff) or arg_7_1.target:getBuffByID(arg_7_0.LightDarkBuff)
	local var_7_3 = arg_7_1.target:getBuffByID(arg_7_0.ChaosMarkBuff) or arg_7_1.target:getBuffByID(arg_7_0.ChaosLightBuff) or arg_7_1.target:getBuffByID(arg_7_0.DarkChaosBuff)

	if var_7_1 and var_7_1.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.lightBuffCount[arg_7_1.fighter] or 0) + var_0_8 then
		arg_7_1.fighter:updateEnergyBy(var_0_11)

		arg_7_0.lightBuffCount[arg_7_1.fighter] = var_7_0
	end

	if var_7_2 and var_7_2.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.darkBuffCount[arg_7_1.target] or 0) + var_0_9 then
		arg_7_0.darkBuffCount[arg_7_1.target] = var_7_0

		local var_7_4 = math.random(tonumber(os.time()))

		math.randomseed(var_7_4)

		local var_7_5 = {}

		for iter_7_0, iter_7_1 in ipairs(arg_7_1.target.selfTeam_) do
			if not iter_7_1:isDeath() and not iter_7_1:isAffected() and iter_7_1 ~= arg_7_1.target then
				table.insert(var_7_5, iter_7_1)
			end
		end

		if next(var_7_5) then
			local var_7_6 = var_7_5[math.random(#var_7_5)]
			local var_7_7 = {
				{
					arg_7_0.BlueSubSkillDark,
					{
						var_7_2,
						arg_7_0.DarkChaosBuff,
						arg_7_0.LightDarkBuff
					}
				},
				var_7_1 and {
					arg_7_0.BlueSubSkillLight,
					{
						var_7_1,
						arg_7_0.LightDarkBuff,
						arg_7_0.ChaosLightBuff
					}
				} or var_7_3 and {
					arg_7_0.BlueSubSkillChaos,
					{
						var_7_3,
						arg_7_0.ChaosLightBuff,
						arg_7_0.DarkChaosBuff
					}
				}
			}
			local var_7_8 = var_7_7[math.random(#var_7_7)]
			local var_7_9 = var_7_8[1]
			local var_7_10 = var_7_8[2]

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_7_11 = arg_7_0:createAttackUnits({
					var_7_6
				}, var_7_9)

				for iter_7_2, iter_7_3 in ipairs(var_7_11) do
					table.insert(arg_7_0.moveAttackUnits_, iter_7_3)
					table.insert(arg_7_0.records_.special_units, iter_7_3)
				end

				for iter_7_4, iter_7_5 in ipairs(var_7_6:getBuffs()) do
					if iter_7_5:getTableID() == var_7_10[1] or iter_7_5:getTableID() == var_7_10[2] or iter_7_5:getTableID() == var_7_10[3] then
						local var_7_12 = arg_7_0:createAttackUnits({
							var_7_6
						}, var_0_14)

						for iter_7_6, iter_7_7 in ipairs(var_7_12) do
							table.insert(arg_7_0.moveAttackUnits_, iter_7_7)
							table.insert(arg_7_0.records_.special_units, iter_7_7)
						end
					end
				end
			end
		end
	end

	if var_7_3 and var_7_3.fighter == arg_7_0 and arg_7_4 > 0 and var_7_0 > (arg_7_0.chaosBuffCount[arg_7_1.target] or 0) + var_0_10 then
		arg_7_0.chaosBuffCount[arg_7_1.target] = var_7_0

		arg_7_1.target:updateEnergyBy(var_0_16)

		local var_7_13 = {}
		local var_7_14 = var_0_6:scope(var_0_17) / 2

		for iter_7_8, iter_7_9 in ipairs(arg_7_1.target.selfTeam_) do
			if not iter_7_9:isDeath() and not iter_7_9:isAffected() and var_7_14 > math.abs(iter_7_9:getX() - arg_7_1.target:getX()) then
				table.insert(var_7_13, iter_7_9)
			end
		end

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_7_15 = arg_7_0:createAttackUnits(var_7_13, var_0_17)

			for iter_7_10, iter_7_11 in ipairs(var_7_15) do
				table.insert(arg_7_0.moveAttackUnits_, iter_7_11)
				table.insert(arg_7_0.records_.special_units, iter_7_11)
			end
		end
	end

	return var_0_3.super.updateUnitInfoBySpecialHero(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
end

function var_0_3.buffAddAction(arg_8_0, arg_8_1)
	if arg_8_1.target.BadeerLastMarkBuffID and var_0_7[arg_8_1.target.BadeerLastMarkBuffID] then
		local var_8_0 = var_0_7[arg_8_1.target.BadeerLastMarkBuffID][arg_8_1:getTableID()]

		if var_8_0 then
			arg_8_1.leftCount_ = 1

			for iter_8_0, iter_8_1 in ipairs(arg_8_1.target:getBuffs()) do
				if iter_8_1:getTableID() == arg_8_0.LightMarkBuff or iter_8_1:getTableID() == arg_8_0.DarkMarkBuff or iter_8_1:getTableID() == arg_8_0.ChaosMarkBuff or iter_8_1:getTableID() == arg_8_0.LightDarkBuff or iter_8_1:getTableID() == arg_8_0.DarkChaosBuff or iter_8_1:getTableID() == arg_8_0.ChaosLightBuff then
					iter_8_1.leftCount_ = 1
				end
			end

			arg_8_1.target:addBuffs({
				var_0_4.new({
					tableID = var_8_0,
					start = var_0_1.ctx.battle.count,
					level = arg_8_0:getLevel(),
					skillID = arg_8_0:getLevel(),
					fighter = arg_8_0,
					target = arg_8_1.target
				})
			})
		end
	end

	if var_0_7[arg_8_1:getTableID()] then
		arg_8_1.target.BadeerLastMarkBuffID = arg_8_1:getTableID()
	end

	if arg_8_0.skinSkillIndex_ == 1 and (arg_8_1:getTableID() == arg_8_0.LightMarkBuff or arg_8_1:getTableID() == arg_8_0.DarkMarkBuff or arg_8_1:getTableID() == arg_8_0.ChaosMarkBuff) and arg_8_0.skinCDCount <= 0 then
		arg_8_0:useSkinSkill(arg_8_1.target)
	end
end

function var_0_3.useSkinSkill(arg_9_0, arg_9_1)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_9_0.skinCDCount = var_0_19

	local var_9_0 = arg_9_0:createAttackUnits({
		arg_9_0
	}, var_0_18)

	for iter_9_0, iter_9_1 in ipairs(var_9_0) do
		table.insert(arg_9_0.moveAttackUnits_, iter_9_1)
		table.insert(arg_9_0.records_.special_units, iter_9_1)
	end
end

function var_0_3.selectTargetByTypeC29(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = {}

	for iter_10_0, iter_10_1 in ipairs(arg_10_0.targetTeam_) do
		if not iter_10_1:isDeath() and not iter_10_1:isAffected() and (arg_10_0:getFlipX() and iter_10_1:getX() < arg_10_0:getX() or iter_10_1:getX() > arg_10_0:getX()) then
			table.insert(var_10_0, iter_10_1)
		end
	end

	return var_10_0
end

function var_0_3.selectTargetByTypeC30(arg_11_0, arg_11_1, arg_11_2)
	local function var_11_0(arg_12_0, arg_12_1)
		local var_12_0, var_12_1 = var_0_5.getTeam(arg_12_0)
		local var_12_2 = {}

		table.insert(var_12_2, arg_12_0)

		for iter_12_0, iter_12_1 in ipairs(var_12_0) do
			if not iter_12_1:isDeath() and not iter_12_1:isAffected() and iter_12_1 ~= arg_12_0 and arg_12_1 >= math.abs(iter_12_1:getX() - arg_12_0:getX()) then
				table.insert(var_12_2, iter_12_1)
			end
		end

		return var_12_2
	end

	local var_11_1 = {}
	local var_11_2 = 0
	local var_11_3 = var_0_6:scope(arg_11_1) * 0.5
	local var_11_4, var_11_5 = var_0_5.getTeam(arg_11_0)

	arg_11_0.purpleCenterX = nil
	arg_11_0.purpleCenterY = nil

	for iter_11_0, iter_11_1 in ipairs(var_11_5) do
		if not iter_11_1:isDeath() and not iter_11_1:isAffected() then
			local var_11_6 = var_11_0(iter_11_1, var_11_3)

			if var_11_2 < #var_11_6 then
				arg_11_0.purpleCenterX = iter_11_1:getX()
				arg_11_0.purpleCenterY = iter_11_1:getY()
				var_11_1 = var_11_6
				var_11_2 = #var_11_6
			end
		end
	end

	return var_11_1
end

function var_0_3.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)
	arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7 = var_0_3.super.updateUnitDataByFighter(arg_13_0, arg_13_1, arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7)

	if arg_13_0:hasElementEquipByID(var_0_21) and arg_13_4 > 0 then
		local var_13_0 = var_0_21
		local var_13_1 = var_0_20:battleAttr(var_13_0, arg_13_0:getElementEquipLevelByID(var_13_0))
		local var_13_2 = arg_13_0.hero_:getElementEquipActiveRate(var_13_0)

		arg_13_6 = arg_13_6 + arg_13_4 * var_13_1 * var_13_2
	end

	return arg_13_2, arg_13_3, arg_13_4, arg_13_5, arg_13_6, arg_13_7
end

return var_0_3
