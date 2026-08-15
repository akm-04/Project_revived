local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("Fenlier", var_0_1.ctx.battle.requireFighter("Boss"))
local var_0_4 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_7 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_8 = var_0_2.tables.skill
local var_0_9 = 81210006
local var_0_10 = 0.3
local var_0_11 = 100
local var_0_12 = 81210011
local var_0_13 = 0.25
local var_0_14 = 40012272
local var_0_15 = 40012274
local var_0_16 = 15
local var_0_17 = 40012282
local var_0_18 = 7

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.angerCount = 0

	arg_1_0:initAngerProgress()
end

function var_0_3.applySingleUnit(arg_2_0, arg_2_1)
	var_0_3.super.applySingleUnit(arg_2_0, arg_2_1)

	if arg_2_1.skillID == var_0_9 then
		arg_2_0.greenTarget = arg_2_1.target
	end
end

function var_0_3.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)
	arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7 = var_0_3.super.updateUnitDataByFighter(arg_3_0, arg_3_1, arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7)

	if arg_3_1.skillID == var_0_12 then
		local var_3_0 = arg_3_1.target

		arg_3_4 = arg_3_4 + (var_3_0:getHpLimit() - var_3_0:getHp() + arg_3_4) * var_0_13
	end

	if arg_3_1.target:isHasBuffByID(var_0_14) then
		arg_3_4 = arg_3_4 * (1 + var_0_10)
	end

	return arg_3_2, arg_3_3, arg_3_4, arg_3_5, arg_3_6, arg_3_7
end

function var_0_3.energyActionBySpecialHero(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1:getTeamType() ~= arg_4_0:getTeamType() then
		if arg_4_0:isHasBuffByID(var_0_17) then
			arg_4_0:updateAnger(var_0_18)
		else
			arg_4_0:updateAnger(var_0_16)
		end
	end
end

function var_0_3.updateAnger(arg_5_0, arg_5_1)
	arg_5_0.angerCount = math.min(arg_5_0.angerCount + arg_5_1, var_0_11)
	arg_5_0.angerCount = math.max(arg_5_0.angerCount, 0)

	local var_5_0 = arg_5_0.angerCount / var_0_11 * 100

	arg_5_0.angerProgress:runActionOnce(cc.ProgressTo:create(1, var_5_0))
end

function var_0_3.initAngerProgress(arg_6_0)
	arg_6_0.bottomWnd = var_0_2.WindowManager.get():getWindow(var_0_2.WindowName.battleBottomWnd)

	local var_6_0 = var_0_2.AssetLoader.get():loadSprite("skeletons/fenlier/bg_anger_progress.png")

	var_6_0:addTo(arg_6_0.bottomWnd)
	var_6_0:setPosition(200, 550)

	local var_6_1 = var_0_2.AssetLoader.get():loadSprite("skeletons/fenlier/anger_progress.png")

	arg_6_0.angerProgress = display.newProgressTimer(var_6_1, display.PROGRESS_TIMER_BAR):align(display.CENTER, x2, y2):addTo(arg_6_0.bottomWnd)

	arg_6_0.angerProgress:setMidpoint(cc.p(0, 0))
	arg_6_0.angerProgress:setBarChangeRate(cc.p(1, 0))
	arg_6_0.angerProgress:setPercentage(0)
	arg_6_0.angerProgress:setPosition(200, 550)
	arg_6_0.angerProgress:setPercentage(0)

	arg_6_0.icon = var_0_2.AssetLoader.get():loadSprite("skeletons/fenlier/icon.png")
	arg_6_0.iconGray = var_0_2.AssetLoader.get():loadSprite("skeletons/fenlier/icon_gray.png")

	arg_6_0.icon:addTo(arg_6_0.bottomWnd)
	arg_6_0.iconGray:addTo(arg_6_0.bottomWnd)
	arg_6_0.icon:setPosition(50, 550)
	arg_6_0.iconGray:setPosition(50, 550)
	arg_6_0:updateAngerIcon(true)
end

function var_0_3.updateAngerIcon(arg_7_0, arg_7_1)
	arg_7_0.icon:setVisible(not arg_7_1)
	arg_7_0.iconGray:setVisible(arg_7_1)
end

function var_0_3.getOrbOfFrontSkill(arg_8_0)
	local var_8_0 = var_0_3.super.getOrbOfFrontSkill(arg_8_0)

	if arg_8_0:checkPurpleSkill() then
		return arg_8_0:getSkillByColor(var_0_2.SKILL_INDEX.Purple)
	end

	return var_8_0
end

function var_0_3.checkPurpleSkill(arg_9_0)
	if arg_9_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Purple) > 0 and not arg_9_0:isHasBuffByID(var_0_15) and arg_9_0.angerCount == var_0_11 then
		return true
	else
		return false
	end
end

function var_0_3.buffAddAction(arg_10_0, arg_10_1)
	if arg_10_1:getTableID() == var_0_15 then
		arg_10_0:updateAngerIcon(false)
	end
end

function var_0_3.buffRemoveAction(arg_11_0, arg_11_1)
	if arg_11_1:getTableID() == var_0_15 then
		arg_11_0:updateAnger(-var_0_11)
		arg_11_0:updateAngerIcon(true)
	end
end

function var_0_3.selectTargetByTypeD1(arg_12_0, arg_12_1, arg_12_2)
	return {
		arg_12_0.greenTarget
	}
end

function var_0_3.isBreakImmortal(arg_13_0)
	return true
end

return var_0_3
