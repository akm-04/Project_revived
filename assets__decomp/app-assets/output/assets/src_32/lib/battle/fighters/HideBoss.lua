local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("HideBossMonster", var_0_1.ctx.battle.getRequire("BaseFighter"))
local var_0_4 = var_0_1.ctx.battle.getRequire("Hero")
local var_0_5 = var_0_1.ctx.battle.getRequire("SpineEffect")
local var_0_6 = var_0_2.tables.dbuff
local var_0_7 = var_0_2.tables.skill
local var_0_8 = var_0_2.tables.hero
local var_0_9 = var_0_2.tables.model
local var_0_10 = 2

function var_0_3.init(arg_1_0)
	var_0_3.super.init(arg_1_0)

	arg_1_0.hpIndex_ = 10
	arg_1_0.progressDrop_ = {}
end

function var_0_3.singleLoop(arg_2_0)
	var_0_3.super.singleLoop(arg_2_0)
	arg_2_0:checkAwaken()
end

function var_0_3.checkAwaken(arg_3_0)
	if arg_3_0.awakenFinish_ and arg_3_0.awakenFinish_ == var_0_1.ctx.battle.count then
		arg_3_0.awakenFinish_ = nil
		arg_3_0.awakened = true

		arg_3_0:awakenBoss()
	end

	if var_0_1.ctx.battle.count < var_0_2.tables.battleConfig.bossAwakenCount * var_0_1.ctx.battleConst.frames or arg_3_0:isBattleUnable() or arg_3_0:isCreatingUnits() or arg_3_0.hero_:awakenID() < 1 or arg_3_0.playAwaken_ then
		return
	end

	arg_3_0.playAwaken_ = true

	local var_3_0 = var_0_9:changeDuration(arg_3_0:getModelID())

	arg_3_0.awakenFinish_ = var_0_1.ctx.battle.count + var_3_0

	arg_3_0:awaken()
end

function var_0_3.setupDrop(arg_4_0)
	var_0_3.super.setupDrop(arg_4_0)

	if not arg_4_0.hero_.monsterDrop then
		return
	end

	arg_4_0.monsterDrop = arg_4_0.hero_.monsterDrop
end

function var_0_3.setBossAvatar(arg_5_0)
	if not arg_5_0.topWnd then
		return
	end

	arg_5_0.topWnd:getBossAvatarBackground():show()
	arg_5_0.topWnd:hideElementLabel()

	local var_5_0 = arg_5_0.hero_
	local var_5_1 = arg_5_0.topWnd:getAvatarBossContainer()

	var_5_1:removeAllChildren()

	local var_5_2 = var_5_0:getAvatar(2)
	local var_5_3 = var_0_2.AssetLoader.get():loadSprite(var_5_2)

	var_5_3:align(display.CENTER_BOTTOM, var_5_1:getWidth() / 2, 0):addTo(var_5_1)
	var_5_3:scale(100 / var_5_3:getWidth())
end

function var_0_3.updateHpBar(arg_6_0, arg_6_1)
	if arg_6_0.topWnd then
		arg_6_0.hpIndex_ = 10 - math.floor(arg_6_0:getHp() / arg_6_0:getPartTotalHp())
		arg_6_0.hpIndex_ = arg_6_0.hpIndex_ < 1 and 1 or arg_6_0.hpIndex_

		local var_6_0 = arg_6_0:getHp() - (10 - arg_6_0.hpIndex_) * arg_6_0:getPartTotalHp()

		arg_6_0:setProgress(var_6_0 / arg_6_0:getPartTotalHp(), true)
		arg_6_0.topWnd:getBossHpLabel():setString("x" .. tostring(11 - arg_6_0.hpIndex_))
	end
end

function var_0_3.getPartTotalHp(arg_7_0)
	if not arg_7_0.singleHp_ then
		arg_7_0.singleHp_ = arg_7_0:getHpLimit() / 10
	end

	return arg_7_0.singleHp_
end

function var_0_3.getProgressDrop(arg_8_0)
	if arg_8_0.monsterDrop and arg_8_0.monsterDrop[arg_8_0.progressIndex_] then
		return arg_8_0.monsterDrop[arg_8_0.progressIndex_]
	end
end

function var_0_3.playProgressDrop(arg_9_0)
	local var_9_0 = 0
	local var_9_1 = arg_9_0:getProgressDrop()

	if not var_9_1 or next(var_9_1) == nil then
		return
	end

	local var_9_2 = 0
	local var_9_3, var_9_4 = arg_9_0.fighterModel:getPosition()
	local var_9_5 = math.min(var_9_3, var_0_2.STAGE_WIDTH - 100)

	for iter_9_0, iter_9_1 in ipairs(var_9_1) do
		local var_9_6 = "skeletons/ui_effect/common_effect_shine_box/common_effect_shine_box"
		local var_9_7 = var_0_5.new(var_9_6 .. ".json", var_9_6 .. ".atlas", 1)
		local var_9_8 = display.newNode()

		var_9_8:size(100, 100)
		var_9_8:setAnchorPoint(cc.p(0, 0))
		var_9_8:addTo(var_0_1.ctx.battle.playerLayer, 1)
		var_9_7:align(display.CENTER, var_9_8:getWidth() / 2, var_9_8:getHeight() / 2):addTo(var_9_8)
		var_9_7:play(nil, true)
		var_9_7:setTouchSwallowEnabled(false)
		var_9_8:pos(var_9_5, var_9_4)

		local var_9_9 = var_0_2.tables.battleConfig.itemDropOffY
		local var_9_10 = var_0_2.tables.battleConfig.itemDropOffX + var_9_2 * 80
		local var_9_11 = math.min(var_9_10 + var_9_5, var_0_2.STAGE_WIDTH - 100)
		local var_9_12 = var_9_4 + var_9_9
		local var_9_13 = math.min(2 * var_9_10 + var_9_5, var_0_2.STAGE_WIDTH - 100)
		local var_9_14 = {
			cc.p(0, 0),
			cc.p(var_9_11 - var_9_5, var_9_9),
			cc.p(var_9_13 - var_9_5, 170 - var_9_4)
		}
		local var_9_15 = cc.CardinalSplineBy:create(0.5, var_9_14, 0)

		iter_9_1.sprite = var_9_8
		var_9_8.item = iter_9_1
		var_0_1.ctx.battle.dropAwardCount = var_0_1.ctx.battle.dropAwardCount + 1

		var_9_8:setTouchSwallowEnabled(false)
		var_9_8:runActionOnce(var_9_15, false, function()
			var_9_8:setTouchEnabled(true)
			var_9_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
				if arg_11_0.name == "ended" then
					arg_9_0:showAwardAction(iter_9_1)
				end

				return true
			end)
		end)

		var_9_2 = var_9_2 + 1

		table.insert(arg_9_0.progressDrop_, iter_9_1)
	end

	var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.sound:getSound("battle_loot"))
end

function var_0_3.progressAwardAction(arg_12_0)
	for iter_12_0, iter_12_1 in ipairs(arg_12_0.progressDrop_) do
		arg_12_0:showAwardAction(iter_12_1)
	end
end

function var_0_3.isBoss(arg_13_0)
	return true
end

function var_0_3.avoidHeroMoveBehind(arg_14_0)
	return var_0_8:avoidHeroMoveBehind(arg_14_0:getTableID())
end

function var_0_3.getADJianShang(arg_15_0)
	return var_0_10 * var_0_3.super.getADJianShang(arg_15_0)
end

function var_0_3.getAPJianShang(arg_16_0)
	return var_0_10 * var_0_3.super.getAPJianShang(arg_16_0)
end

function var_0_3.getHpBarSp(arg_17_0)
	local var_17_0 = arg_17_0.hpIndex_ > 5 and arg_17_0.hpIndex_ - 5 or arg_17_0.hpIndex_
	local var_17_1 = "images/battle/boss_hp_progress" .. var_17_0 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_17_1)
end

function var_0_3.getHpBackSp(arg_18_0)
	local var_18_0 = arg_18_0.hpIndex_ > 4 and arg_18_0.hpIndex_ - 4 or arg_18_0.hpIndex_ + 1

	if var_18_0 > 5 then
		return nil
	end

	local var_18_1 = "images/battle/boss_hp_progress" .. var_18_0 .. ".png"

	return var_0_2.AssetLoader.get():loadSprite(var_18_1)
end

function var_0_3.setProgress(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local function var_19_0()
		arg_19_0.topWnd:getBossHpBar(1):removeAllChildren()
		arg_19_0.topWnd:getBossHpBar(2):removeAllChildren()

		arg_19_0.progressIndex_ = arg_19_0.hpIndex_

		local var_20_0 = var_0_2.AssetLoader.get():loadSprite("images/battle/boss_hp_progress6.png")

		arg_19_0.easeBar_ = display.newProgressTimer(var_20_0, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_19_0.topWnd:getBossHpBar(1))

		arg_19_0.easeBar_:setMidpoint(cc.p(0, 0))
		arg_19_0.easeBar_:setBarChangeRate(cc.p(1, 0))
		arg_19_0.easeBar_:setPercentage(100)

		local var_20_1 = arg_19_0:getHpBarSp()

		arg_19_0.hpBarBack_ = arg_19_0:getHpBackSp()
		arg_19_0.hpBar_ = display.newProgressTimer(var_20_1, display.PROGRESS_TIMER_BAR):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_19_0.topWnd:getBossHpBar(1))

		arg_19_0.hpBar_:setMidpoint(cc.p(0, 0))
		arg_19_0.hpBar_:setBarChangeRate(cc.p(1, 0))
		arg_19_0.hpBar_:setPercentage(100)

		if arg_19_0.hpBarBack_ then
			arg_19_0.hpBarBack_:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_19_0.topWnd:getBossHpBar(2))
		end
	end

	if arg_19_0.progressIndex_ == nil then
		var_19_0()

		arg_19_2 = false
	elseif arg_19_0.progressIndex_ ~= arg_19_0.hpIndex_ then
		arg_19_0:playProgressDrop()
		var_19_0()
	end

	arg_19_0:setBarProgress_(arg_19_0.hpBar_, arg_19_1, false, arg_19_3)
	arg_19_0:setBarProgress_(arg_19_0.easeBar_, arg_19_1, arg_19_2, arg_19_3)
end

function var_0_3.setBarProgress_(arg_21_0, arg_21_1, arg_21_2, arg_21_3, arg_21_4)
	if tolua.isnull(arg_21_1) then
		return
	end

	arg_21_1:stopAllActions()

	arg_21_2 = arg_21_2 * 100

	if tonumber(arg_21_3) then
		arg_21_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_21_3), arg_21_2), false, arg_21_4)
	elseif arg_21_3 then
		local var_21_0 = arg_21_1:getPercentage()
		local var_21_1 = arg_21_2 - var_21_0
		local var_21_2 = var_0_2.tables.battleConfig.hpProgressMoveBase + var_0_2.tables.battleConfig.hpProgressMoveStep * math.abs(var_21_1)
		local var_21_3 = var_0_2.tables.battleConfig.hpProgressBrakeBase
		local var_21_4 = var_21_0 + var_21_1 * (1 - var_0_2.tables.battleConfig.hpProgressBrakePercent)
		local var_21_5 = arg_21_2
		local var_21_6 = cc.Sequence:create(cc.ProgressTo:create(var_21_2, var_21_4), cc.ProgressTo:create(var_21_3, var_21_5))

		arg_21_1:runActionOnce(var_21_6, false, arg_21_4)
	else
		arg_21_1:setPercentage(arg_21_2)

		if arg_21_4 ~= nil then
			arg_21_4()
		end
	end
end

function var_0_3.awaken(arg_22_0)
	if not arg_22_0:getFighterModel():hasAnimation("change") then
		arg_22_0:getFighterModel():idle()
		arg_22_0.fighterModel:hide()

		return
	end

	arg_22_0.skillRoll_ = var_0_9:changeDuration(arg_22_0:getModelID())

	arg_22_0:getFighterModel():change(function()
		if arg_22_0:getFighterModel().currentAnimation_ == "change" then
			arg_22_0:resumeIdle()
		end

		arg_22_0.fighterModel:hide()
	end)
end

function var_0_3.afterAwaken(arg_24_0)
	if not arg_24_0:getFighterModel():hasAnimation("change") then
		arg_24_0:getFighterModel():idle()

		return
	end

	arg_24_0.skillRoll_ = var_0_9:changeDuration(arg_24_0:getModelID())

	arg_24_0:getFighterModel():change(function()
		if arg_24_0:getFighterModel().currentAnimation_ == "change" then
			arg_24_0:resumeIdle()
		end
	end)
end

function var_0_3.awakenBoss(arg_26_0)
	local var_26_0 = arg_26_0.hero_:toParams()

	var_26_0.table_id = arg_26_0.hero_:awakenID()

	local var_26_1 = var_0_4.new()

	var_26_1:populate(var_26_0)

	var_26_1.monsterDrop = arg_26_0.hero_.monsterDrop
	var_26_1.guildDrop = arg_26_0.hero_.guildDrop

	var_0_0.table.removebyvalue(var_0_1.ctx.battle.teamB, arg_26_0)
	var_0_0.table.removebyvalue(var_0_1.ctx.battle.yOrder, arg_26_0)

	local var_26_2 = var_26_1:className()
	local var_26_3 = var_0_1.ctx.battle.requireFighter(var_26_2).new({
		is_arena = var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.ARENA
	})

	var_26_3:populateWithHero(var_26_1)
	var_26_3:setTeamType(arg_26_0:getTeamType())
	var_26_3:initModels()
	var_26_3.fighterModel:addTo(var_0_1.ctx.battle.playerLayer)
	var_26_3:getFighterModel():idle()
	var_26_3:getFighterModel():flipX(arg_26_0:getFlipX())
	var_26_3.fighterModel:initHeaderView(1)

	var_26_3.fighterIndex = arg_26_0.fighterIndex

	table.insert(var_0_1.ctx.battle.teamB, var_26_3)
	table.insert(var_0_1.ctx.battle.yOrder, var_26_3)

	var_26_3.dropItems_ = arg_26_0.dropItems_
	var_26_3.dropMana_ = arg_26_0.dropMana_

	var_26_3:setFormationDelay(arg_26_0.formationDelay_, arg_26_0.formationWalk2Position_)
	var_26_3:setBossAvatar()
	var_26_3:setupBattleAttrInfo()
	var_26_3:setGlobalBuffs()

	var_26_3.hasReborn_ = arg_26_0.hasReborn_
	var_26_3.harms = arg_26_0.harms
	var_26_3.playAwaken_ = arg_26_0.playAwaken_

	var_26_3:updateHp(arg_26_0:getHp(), false)
	var_26_3:updateEnergyTo(arg_26_0:getEnergy())
	var_26_3:setBossAvatar()
	var_26_3:setupDrop()
	var_26_3.fighterModel:pos(arg_26_0:getX(), arg_26_0:getY())
	var_26_3:afterAwaken()

	var_26_3.walk2Position_ = false

	arg_26_0.fighterModel:hide()
end

function var_0_3.setFormation(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	return var_0_3.super.setFormation(arg_27_0, 4, arg_27_2, arg_27_3)
end

function var_0_3.setFormationDelay(arg_28_0, arg_28_1, arg_28_2)
	var_0_3.super.setFormationDelay(arg_28_0, 0, var_0_2.tables.battleConfig.formationWalkQueue[4])
end

function var_0_3.applyBuffMoves(arg_29_0)
	arg_29_0.buffMovePath_ = {}
end

function var_0_3.checkSkillBreak(arg_30_0, arg_30_1, arg_30_2)
	return
end

function var_0_3.addBuffs(arg_31_0, arg_31_1)
	local var_31_0 = {}

	for iter_31_0, iter_31_1 in ipairs(arg_31_1) do
		if var_0_6:attr(iter_31_1:getTableID()) ~= var_0_2.AttributeType.SPEED and var_0_6:attr(iter_31_1:getTableID()) ~= var_0_2.AttributeType.ACK_SPEED and not iter_31_1:isFear() and not iter_31_1:isApUnable() and not iter_31_1:isAdUnable() and not iter_31_1:isExcuteAdCircle() and not iter_31_1:isAttackFriend() and not iter_31_1:isPugongOnly() and iter_31_1:getType() ~= var_0_2.BuffType.REVIVIE then
			table.insert(var_31_0, iter_31_1)
		end
	end

	var_0_3.super.addBuffs(arg_31_0, var_31_0)
end

function var_0_3.applyUnitBuffs(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4, arg_32_5, arg_32_6)
	var_0_3.super.applyUnitBuffs(arg_32_0, arg_32_1, arg_32_2)
end

function var_0_3.getUnitData(arg_33_0, arg_33_1)
	local var_33_0, var_33_1, var_33_2, var_33_3, var_33_4, var_33_5 = var_0_3.super.getUnitData(arg_33_0, arg_33_1)

	if var_33_3 > 0 then
		var_33_3 = 0
	end

	if var_33_4 > 0 then
		var_33_4 = 0
	end

	return var_33_0, var_33_1, var_33_2, var_33_3, var_33_4, var_33_5
end

return var_0_3
