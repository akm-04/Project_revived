local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Yujin", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_2.tables.skill
local var_0_5 = var_0_2.tables.hero
local var_0_6 = var_0_2.tables.model
local var_0_7 = 10000126
local var_0_8 = 10000125
local var_0_9 = 10001240
local var_0_10 = 80010044
local var_0_11 = 150
local var_0_12 = 150

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.isSaber_ = false
	arg_1_0.selfSkinTargetsCount = {}
	arg_1_0.enemySkinTargetsCount = {}
	arg_1_0.selfSkinTargetsBuffCount = {}
	arg_1_0.enemySkinTargetsBuffCount = {}
end

function var_0_3.toDoPerFrames(arg_2_0)
	var_0_3.super.toDoPerFrames(arg_2_0)

	if var_0_1.ctx.battle.count % 10 > 0 then
		arg_2_0:attackModeJudge()
	end

	if arg_2_0.isSkinSkillOn_ and arg_2_0.skinSkillID_ == var_0_10 then
		arg_2_0:changeSkinTarget()

		for iter_2_0, iter_2_1 in pairs(arg_2_0.selfSkinTargetsCount) do
			arg_2_0.selfSkinTargetsCount[iter_2_0] = arg_2_0.selfSkinTargetsCount[iter_2_0] + 1

			if iter_2_1 > var_0_11 then
				arg_2_0.selfSkinTargetsCount[iter_2_0] = nil
			end
		end

		for iter_2_2, iter_2_3 in pairs(arg_2_0.enemySkinTargetsCount) do
			arg_2_0.enemySkinTargetsCount[iter_2_2] = arg_2_0.enemySkinTargetsCount[iter_2_2] + 1

			if iter_2_3 > var_0_12 then
				arg_2_0.enemySkinTargetsCount[iter_2_2] = nil
			end
		end

		for iter_2_4, iter_2_5 in pairs(arg_2_0.selfSkinTargetsBuffCount) do
			arg_2_0.selfSkinTargetsBuffCount[iter_2_4] = arg_2_0.selfSkinTargetsBuffCount[iter_2_4] + 1

			if iter_2_5 > var_0_11 then
				arg_2_0.selfSkinTargetsBuffCount[iter_2_4] = nil
			end
		end

		for iter_2_6, iter_2_7 in pairs(arg_2_0.enemySkinTargetsBuffCount) do
			arg_2_0.enemySkinTargetsBuffCount[iter_2_6] = arg_2_0.enemySkinTargetsBuffCount[iter_2_6] + 1

			if iter_2_7 > var_0_12 then
				arg_2_0.enemySkinTargetsBuffCount[iter_2_6] = nil
			end
		end
	end
end

function var_0_3.attackModeJudge(arg_3_0)
	local var_3_0 = arg_3_0:getFlipX() == true and -1 or 1
	local var_3_1 = true

	for iter_3_0, iter_3_1 in ipairs(arg_3_0.selfTeam_) do
		if not iter_3_1:isDeath() and var_0_5:distanceType(iter_3_1:getTableID()) == var_0_2.DistanceType.QIANPAI and (iter_3_1:getX() - arg_3_0:getX()) * var_3_0 > 0 then
			var_3_1 = false

			break
		end
	end

	arg_3_0.isSaber_ = var_3_1
end

function var_0_3.changeSkinTarget(arg_4_0)
	if not arg_4_0.skinTarget or arg_4_0.skinTarget:isDeath() then
		arg_4_0.skinTarget = arg_4_0:getNearestHero()
	end
end

function var_0_3.getNearestHero(arg_5_0)
	local var_5_0, var_5_1 = arg_5_0.fighterModel:getPosition()
	local var_5_2
	local var_5_3

	for iter_5_0, iter_5_1 in pairs(arg_5_0.sideTeam_) do
		if iter_5_1.summonType_ == var_0_2.summonMonsterType.None and not iter_5_1:isDeath() and not iter_5_1:isDeath() and not iter_5_1:isDeath() then
			local var_5_4, var_5_5 = iter_5_1.fighterModel:getPosition()
			local var_5_6 = math.abs(var_5_0 - var_5_4)
			local var_5_7 = var_5_4 < var_5_0 == arg_5_0:getFighterModel():getFlipX()

			if (not var_5_2 or var_5_6 < var_5_2) and var_5_7 then
				var_5_2 = var_5_6
				var_5_3 = iter_5_1
			end
		end
	end

	return var_5_3
end

function var_0_3.getFrontSkillDistance(arg_6_0)
	if var_0_4:father(arg_6_0:getOrbOfFrontSkill()) == arg_6_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_6_0.isSaber_ then
			return var_0_4:distance(var_0_7)
		end

		return var_0_4:distance(var_0_8)
	end

	return var_0_4:distance(arg_6_0:getOrbOfFrontSkill())
end

function var_0_3.addBuffBySpecialHero(arg_7_0, arg_7_1)
	var_0_3.super.addBuffBySpecialHero(arg_7_0, arg_7_1)

	if arg_7_0.isSkinSkillOn_ and arg_7_0.skinSkillID_ == var_0_10 then
		for iter_7_0 = #arg_7_1, 1, -1 do
			local var_7_0 = arg_7_1[iter_7_0]

			if var_7_0.target == arg_7_0 and var_7_0.fighter:getTeamType() ~= arg_7_0:getTeamType() and var_7_0:canRemove() then
				if arg_7_0.selfSkinTargetsBuffCount[var_7_0.fighter] and arg_7_0.selfSkinTargetsBuffCount[var_7_0.fighter] <= var_0_11 then
					table.remove(arg_7_1, iter_7_0)
				elseif not arg_7_0.selfSkinTargetsBuffCount[var_7_0.fighter] then
					arg_7_0.selfSkinTargetsBuffCount[var_7_0.fighter] = 0
				end
			end

			if arg_7_0.skinTarget and var_7_0.target == arg_7_0.skinTarget and var_7_0.fighter:getTeamType() ~= arg_7_0:getTeamType() and not var_7_0.fighter:isBoss() and var_7_0:canRemove() then
				if arg_7_0.enemySkinTargetsBuffCount[var_7_0.fighter] and arg_7_0.enemySkinTargetsBuffCount[var_7_0.fighter] <= var_0_12 then
					table.remove(arg_7_1, iter_7_0)
				elseif not arg_7_0.enemySkinTargetsBuffCount[var_7_0.fighter] then
					arg_7_0.enemySkinTargetsBuffCount[var_7_0.fighter] = 0
				end
			end
		end
	end
end

function var_0_3.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)
	local var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5 = var_0_3.super.updateUnitDataBySpecialHero(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4, arg_8_5, arg_8_6, arg_8_7)

	if arg_8_0.isSkinSkillOn_ and arg_8_0.skinSkillID_ == var_0_10 then
		if arg_8_0.skinTarget and arg_8_1.target == arg_8_0.skinTarget and arg_8_1.target:getTeamType() == arg_8_1.fighter:getTeamType() then
			if arg_8_0.enemySkinTargetsCount[arg_8_1.fighter] and arg_8_0.enemySkinTargetsCount[arg_8_1.fighter] <= var_0_12 then
				var_8_3 = 0
				var_8_4 = 0
			end
		elseif arg_8_1.target == arg_8_0 and arg_8_1.fighter:getTeamType() ~= arg_8_0:getTeamType() and arg_8_0.selfSkinTargetsCount[arg_8_1.fighter] and arg_8_0.selfSkinTargetsCount[arg_8_1.fighter] <= var_0_11 then
			var_8_2 = 0
			var_8_3 = 0
			var_8_4 = 0
			var_8_5 = 0
			var_8_0 = false
			var_8_1 = false
		end
	end

	return var_8_0, var_8_1, var_8_2, var_8_3, var_8_4, var_8_5
end

function var_0_3.updateUnitInfoBySpecialHero(arg_9_0, arg_9_1)
	var_0_3.super.updateUnitInfoBySpecialHero(arg_9_0, arg_9_1)

	if arg_9_0.isSkinSkillOn_ and arg_9_0.skinSkillID_ == var_0_10 then
		if arg_9_0.skinTarget and arg_9_1.target == arg_9_0.skinTarget and arg_9_1.target:getTeamType() == arg_9_1.fighter:getTeamType() then
			if arg_9_0.enemySkinTargetsCount[arg_9_1.fighter] and arg_9_0.enemySkinTargetsCount[arg_9_1.fighter] <= var_0_12 then
				-- block empty
			elseif not arg_9_0.enemySkinTargetsCount[arg_9_1.fighter] then
				arg_9_0.enemySkinTargetsCount[arg_9_1.fighter] = 0
			end
		elseif arg_9_1.target ~= arg_9_0 or arg_9_1.fighter:getTeamType() == arg_9_0:getTeamType() or arg_9_0.selfSkinTargetsCount[arg_9_1.fighter] and arg_9_0.selfSkinTargetsCount[arg_9_1.fighter] <= var_0_11 then
			-- block empty
		elseif not arg_9_0.selfSkinTargetsCount[arg_9_1.fighter] then
			arg_9_0.selfSkinTargetsCount[arg_9_1.fighter] = 0
		end
	end
end

function var_0_3.getOrbOfFrontSkill(arg_10_0)
	local var_10_0 = arg_10_0:getFrontSkill()
	local var_10_1 = var_0_4:orb(var_10_0)

	if var_10_1 == 0 or arg_10_0:getSkillLevelByID(var_10_1) < 1 then
		return var_0_3.super.getOrbOfFrontSkill(arg_10_0)
	end

	if var_10_1 == arg_10_0:getSkillByColor(var_0_2.SKILL_INDEX.Blue) then
		if arg_10_0.isSaber_ then
			return var_0_7
		elseif arg_10_0.hero_.isSkinOn_ and arg_10_0.hero_.isSkinOn_ ~= 0 then
			return var_0_9
		else
			return var_0_8
		end
	end

	return var_10_1
end

return var_0_3
