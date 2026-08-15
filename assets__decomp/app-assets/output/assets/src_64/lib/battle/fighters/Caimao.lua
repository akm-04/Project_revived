local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Caimao", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_8 = 40011864
local var_0_9 = 10001730
local var_0_10 = 40011852
local var_0_11 = 40011865
local var_0_12 = 100
local var_0_13 = 0.4
local var_0_14 = 10001740
local var_0_15 = 10001739
local var_0_16 = 400
local var_0_17 = 40012336
local var_0_18 = 0.25
local var_0_19 = 80010235

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.blueIndex = 0
	arg_1_0.skinTeamDHarmTime = {}
	arg_1_0.records_.summon_monster_count = {}
end

function var_0_3.populateWithHero(arg_2_0, arg_2_1)
	var_0_3.super.populateWithHero(arg_2_0, arg_2_1)

	if arg_2_0.skinSkillIndex_ == 1 then
		arg_2_0.BlueBuffID = {
			[var_0_2.HeroType.STRENGTH] = {
				{
					40012343
				},
				{
					40011856,
					40011857
				}
			},
			[var_0_2.HeroType.WISE] = {
				{
					40012344
				},
				{
					40011858
				}
			},
			[var_0_2.HeroType.AGILE] = {
				{
					40012345
				},
				{
					40011859
				}
			}
		}
	else
		arg_2_0.BlueBuffID = {
			[var_0_2.HeroType.STRENGTH] = {
				{
					40011853
				},
				{
					40011856,
					40011857
				}
			},
			[var_0_2.HeroType.WISE] = {
				{
					40011854
				},
				{
					40011858
				}
			},
			[var_0_2.HeroType.AGILE] = {
				{
					40011855
				},
				{
					40011859
				}
			}
		}
	end
end

function var_0_3.applySingleUnit(arg_3_0, arg_3_1)
	var_0_3.super.applySingleUnit(arg_3_0, arg_3_1)

	if var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green) then
		local var_3_0

		for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
			if not iter_3_1:isDeath() and not iter_3_1:isHasBuffByID(var_0_10) then
				var_3_0 = iter_3_1

				break
			end
		end

		if var_3_0 then
			local var_3_1 = arg_3_0:createNewBuffs({
				var_0_10
			}, var_3_0, arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Green))

			var_3_0:addBuffs(var_3_1)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_3_2 = arg_3_0:createAttackUnits({
					var_3_0
				}, var_0_9)

				for iter_3_2, iter_3_3 in ipairs(var_3_2) do
					table.insert(arg_3_0.moveAttackUnits_, iter_3_3)
					table.insert(arg_3_0.records_.special_units, iter_3_3)
				end
			end
		end
	elseif var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		arg_3_0:blueSkill()
	elseif var_0_4:father(arg_3_1.skillID) == arg_3_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple) then
		arg_3_0:purpleSkill()
	end
end

function var_0_3.blueSkill(arg_4_0)
	local var_4_0 = {
		0,
		0,
		0
	}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_1:isDeath() then
			local var_4_1 = var_0_5:heroType(iter_4_1:getTableID())

			if var_4_1 ~= var_0_2.HeroType.NONE then
				var_4_0[var_4_1] = var_4_0[var_4_1] + 1
			end
		end
	end

	local var_4_2 = 0

	arg_4_0.blueIndex = 0

	for iter_4_2, iter_4_3 in ipairs(var_4_0) do
		if var_4_2 < iter_4_3 then
			arg_4_0.blueIndex = iter_4_2
			var_4_2 = iter_4_3
		end
	end

	if var_4_2 == 0 then
		return
	end

	local var_4_3 = arg_4_0.BlueBuffID[arg_4_0.blueIndex]
	local var_4_4 = arg_4_0:createNewBuffs(var_4_3[1], arg_4_0, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

	arg_4_0:addBuffs(var_4_4)

	for iter_4_4, iter_4_5 in ipairs(arg_4_0.sideTeam_) do
		if not iter_4_5:isDeath() then
			local var_4_5 = arg_4_0:createNewBuffs(var_4_3[2], iter_4_5, arg_4_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue))

			iter_4_5:addBuffs(var_4_5)
		end
	end
end

function var_0_3.purpleSkill(arg_5_0)
	local var_5_0 = {}

	for iter_5_0, iter_5_1 in ipairs(arg_5_0.sideTeam_) do
		if not iter_5_1:isDeath() and not iter_5_1:isAffected() and iter_5_1.summoner and not iter_5_1.summoner:isDeath() then
			table.insert(var_5_0, iter_5_1)
		end
	end

	local var_5_1

	arg_5_0.transHp = 0

	if #var_5_0 ~= 0 then
		local var_5_2 = 1

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_5_2 = arg_5_0.summonMonsterCount_[tostring(var_0_1.ctx.battle.count)] or 1
		else
			var_5_2 = math.random(1, #var_5_0)
			arg_5_0.records_.summon_monster_count[tostring(var_0_1.ctx.battle.count)] = var_5_2
		end

		local var_5_3 = var_5_0[var_5_2]
		local var_5_4 = arg_5_0:createNewBuffs({
			var_0_11
		}, var_5_3, arg_5_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple))

		var_5_3:addBuffs(var_5_4)

		var_5_1 = var_5_3.summoner
		arg_5_0.transHp = var_5_3:getHpLimit() * var_0_13 + var_0_12 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	else
		var_5_1 = var_0_7.B14(arg_5_0)[1]
		arg_5_0.transHp = var_0_12 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple)
	end

	arg_5_0.transHp = math.min(var_0_16 * arg_5_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple), arg_5_0.transHp)

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		local var_5_5 = var_0_7.A4(arg_5_0)[1]
		local var_5_6 = arg_5_0:createAttackUnits({
			var_5_5
		}, var_0_14)

		for iter_5_2, iter_5_3 in ipairs(var_5_6) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_3)
			table.insert(arg_5_0.records_.special_units, iter_5_3)
		end

		local var_5_7 = arg_5_0:createAttackUnits({
			var_5_1
		}, var_0_15)

		for iter_5_4, iter_5_5 in ipairs(var_5_7) do
			table.insert(arg_5_0.moveAttackUnits_, iter_5_5)
			table.insert(arg_5_0.records_.special_units, iter_5_5)
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)
	arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7 = var_0_3.super.updateUnitDataBySpecialHero(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7)

	local var_6_0 = arg_6_1.target
	local var_6_1 = arg_6_1.fighter

	if var_6_0:isHasBuffByID(var_0_8) then
		arg_6_4 = math.min(arg_6_4, var_6_0:getHpLimit() * 0.1)
	end

	if arg_6_0.skinSkillIndex_ == 1 and var_6_1:getTeamType() ~= arg_6_0:getTeamType() and var_6_0:getTeamType() == arg_6_0:getTeamType() and not arg_6_2 then
		local var_6_2 = var_6_0:getHpLimit() * var_0_18

		if var_6_2 < arg_6_4 then
			if not arg_6_0.skinTeamDHarmTime[var_6_0] then
				arg_6_0.skinTeamDHarmTime[var_6_0] = 0
			end

			if arg_6_0.skinTeamDHarmTime[var_6_0] < 2 then
				arg_6_4 = var_6_2

				local var_6_3 = arg_6_0:createNewBuffs({
					var_0_17
				}, var_6_0, var_0_19)

				var_6_0:addBuffs(var_6_3)

				arg_6_0.skinTeamDHarmTime[var_6_0] = arg_6_0.skinTeamDHarmTime[var_6_0] + 1
			end
		end
	end

	return arg_6_2, arg_6_3, arg_6_4, arg_6_5, arg_6_6, arg_6_7
end

function var_0_3.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)
	arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7 = var_0_3.super.updateUnitDataByFighter(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7)

	if arg_7_1.skillID == var_0_14 then
		arg_7_5 = arg_7_5 + arg_7_0.transHp
	elseif arg_7_1.skillID == var_0_15 then
		arg_7_4 = arg_7_4 + arg_7_0.transHp
	end

	return arg_7_2, arg_7_3, arg_7_4, arg_7_5, arg_7_6, arg_7_7
end

function var_0_3.die(arg_8_0)
	if arg_8_0.blueIndex ~= 0 then
		for iter_8_0, iter_8_1 in ipairs(arg_8_0.sideTeam_) do
			if not iter_8_1:isDeath() then
				for iter_8_2, iter_8_3 in ipairs(arg_8_0.BlueBuffID[arg_8_0.blueIndex][2]) do
					iter_8_1:removeBuffByID(iter_8_3)
				end
			end
		end
	end

	var_0_3.super.die(arg_8_0)
end

function var_0_3.setupReport(arg_9_0, arg_9_1)
	var_0_3.super.setupReport(arg_9_0, arg_9_1)

	arg_9_0.summonMonsterCount_ = arg_9_1.summon_monster_count or {}
end

function var_0_3.writeReport(arg_10_0)
	local var_10_0 = var_0_3.super.writeReport(arg_10_0)

	var_10_0.summon_monster_count = arg_10_0.records_.summon_monster_count

	return var_10_0
end

return var_0_3
