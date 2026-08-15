local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("BaseFighter")
local var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
local var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
local var_0_6 = var_0_1.ctx.battle.getRequire("MoveUnit")
local var_0_7 = var_0_1.ctx.battle.getRequire("AttackUnit")
local var_0_8 = var_0_1.ctx.battle.getRequire("SkillEffect")
local var_0_9 = var_0_1.ctx.battle.getRequire("FighterModel")
local var_0_10 = var_0_1.ctx.battle.getRequire("SpineEffect")
local var_0_11 = var_0_1.ctx.battle.getRequire("GetTarget")
local var_0_12 = var_0_2.tables.skill
local var_0_13 = var_0_2.tables.hero
local var_0_14 = var_0_2.tables.model
local var_0_15 = var_0_2.tables.dbuff
local var_0_16 = var_0_2.tables.skinSkill
local var_0_17 = var_0_2.tables.objectBook
local var_0_18 = var_0_2.tables.elementEquip
local var_0_19 = var_0_2.tables.battleConfig
local var_0_20 = 180
local var_0_21 = 90
local var_0_22 = 10001263
local var_0_23 = 3000
local var_0_24 = 30
local var_0_25 = 30
local var_0_26 = 10002002
local var_0_27 = 40012151
local var_0_28 = 0.08
local var_0_29 = 20000
local var_0_30 = 0.08
local var_0_31 = 30
local var_0_32 = 20000
local var_0_33 = 30
local var_0_34 = 90
local var_0_35 = 10002536
local var_0_36 = 10002455
local var_0_37 = 150
local var_0_38 = 100000
local var_0_39 = 0.05
local var_0_40 = 0.01
local var_0_41 = 10002457
local var_0_42 = 10002537
local var_0_43 = 40012714
local var_0_44 = 8
local var_0_45 = 90
local var_0_46 = 10002452
local var_0_47 = 10002538
local var_0_48 = 0.3
local var_0_49 = 0.2
local var_0_50 = 10002453
local var_0_51 = {
	40012649,
	40012650
}
local var_0_52 = 0.2
local var_0_53 = 10002451
local var_0_54 = 40012647
local var_0_55 = 0.03
local var_0_56 = 10002458
local var_0_57 = 0.12
local var_0_58 = 50000
local var_0_59 = 300
local var_0_60 = 10002449
local var_0_61 = 10002450
local var_0_62 = 10002456
local var_0_63 = 150
local var_0_64 = 0.3
local var_0_65 = 10002454
local var_0_66 = 360
local var_0_67 = 0.2
local var_0_68 = math.min
local var_0_69 = math.max
local var_0_70 = math.abs
local var_0_71 = math.floor
local var_0_72 = math.ceil
local var_0_73 = math.sqrt

function var_0_3.ctor(arg_1_0, arg_1_1)
	arg_1_0.hurtHp = 0
	arg_1_0.cureHp = 0
	arg_1_0.harms = 0
	arg_1_0.bearHarms = 0
	arg_1_0.killCount = 0
	arg_1_0.energy_ = 0
	arg_1_0.isInArena_ = arg_1_1.is_arena

	arg_1_0:init()

	arg_1_0.skinSkillJudge_ = false
	arg_1_0.isSkinSkillOn_ = false
	arg_1_0.skinSkillID_ = 0
	arg_1_0.skinSkillIndex_ = 0
	arg_1_0.heroScale = 1

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		arg_1_0.bottomWnd = var_0_2.WindowManager.get():getWindow(var_0_2.WindowName.battleBottomWnd)
		arg_1_0.topWnd = var_0_2.WindowManager.get():getWindow(var_0_2.WindowName.battleTopWnd)
	end

	var_0_4 = var_0_1.ctx.battle.getRequire("Buff")
	var_0_5 = var_0_1.ctx.battle.getRequire("Skill")
	var_0_6 = var_0_1.ctx.battle.getRequire("MoveUnit")
	var_0_7 = var_0_1.ctx.battle.getRequire("AttackUnit")
	var_0_8 = var_0_1.ctx.battle.getRequire("SkillEffect")
	var_0_9 = var_0_1.ctx.battle.getRequire("FighterModel")
	var_0_10 = var_0_1.ctx.battle.getRequire("SpineEffect")
	var_0_11 = var_0_1.ctx.battle.getRequire("GetTarget")
	arg_1_0.isMainRole_ = false
end

function var_0_3.init(arg_2_0)
	arg_2_0.isParalysis = false
	arg_2_0.skillRoll_ = false
	arg_2_0.behindWalk_ = false
	arg_2_0.isWalking_ = false
	arg_2_0.preWalk_ = false
	arg_2_0.isAdjustY_ = false
	arg_2_0.leftInterval_ = 0
	arg_2_0.isImmuneControl = false
	arg_2_0.energyDecreaseRatio_ = 0
	arg_2_0.overflowHarm_ = 0
	arg_2_0.isEnergySkill_ = false
	arg_2_0.tempHpLimit_ = 0
	arg_2_0.minHpPercentValue = 0
	arg_2_0.walk2Position_ = true
	arg_2_0.showDHarmbuff_ = nil
	arg_2_0.isAddCourseInitBuff_ = false
	arg_2_0.courseJianshang_ = 0
	arg_2_0.fearMoveDir_ = false
	arg_2_0.summonAutoFight_ = false
	arg_2_0.records_ = {}
	arg_2_0.records_.moveunit = {}
	arg_2_0.records_.attackunit = {}
	arg_2_0.records_.skills = {}
	arg_2_0.records_.energy = {}
	arg_2_0.records_.move = {
		x = {},
		y = {}
	}
	arg_2_0.records_.buff_move = {
		x = {},
		y = {}
	}
	arg_2_0.records_.walk_state = {}
	arg_2_0.records_.die_count = -1
	arg_2_0.records_.special_units = {}
	arg_2_0.records_.special_skills = {}
	arg_2_0.records_.buff_harms = {}
	arg_2_0.records_.break_stun = {}
	arg_2_0.records_.skill_course_buff = {}
	arg_2_0.buffs_ = {}
	arg_2_0.globalBuffs_ = {}
	arg_2_0.moveBuffs_ = {}
	arg_2_0.fearBuffs_ = {}
	arg_2_0.moveUnableBuffs_ = {}
	arg_2_0.adUnableBuffs_ = {}
	arg_2_0.apUnableBuffs_ = {}
	arg_2_0.pugongOnlyBuffs_ = {}
	arg_2_0.excuteAdCircle_ = {}
	arg_2_0.excuteApCircle_ = {}
	arg_2_0.ackFriendsBuffs_ = {}
	arg_2_0.isAffectedBuffs_ = {}
	arg_2_0.isTeamAffectedBuffs_ = {}
	arg_2_0.isInvisibleBuffs_ = {}
	arg_2_0.adImmortalBuffs_ = {}
	arg_2_0.apImmortalBuffs_ = {}
	arg_2_0.immuneControlBuffs_ = {}
	arg_2_0.adBreakImmortalBuffs_ = {}
	arg_2_0.dHarmBuffs_ = {}
	arg_2_0.pauseBuffs_ = {}
	arg_2_0.sleepBuffs_ = {}
	arg_2_0.shieldBuffs_ = {}
	arg_2_0.neverDieBuffs_ = {}
	arg_2_0.forverNeverDieBuffs_ = {}
	arg_2_0.possessBuffs_ = {}
	arg_2_0.spGiveBuffs_ = {}
	arg_2_0.invalidMpIncreaseBuffs_ = {}
	arg_2_0.invalidEnergySkillBuffs_ = {}
	arg_2_0.forceTargetBuffs_ = {}
	arg_2_0.skillDownBuff_ = {}
	arg_2_0.limitAttrBuff_ = {}
	arg_2_0.useSkillCount_ = {}
	arg_2_0.ignoreJianshang_ = {}
	arg_2_0.ignoreShield_ = {}
	arg_2_0.applyUnits_ = {}
	arg_2_0.moveUnits_ = {}
	arg_2_0.moveAttackUnits_ = {}
	arg_2_0.buffMovePath_ = {}
	arg_2_0.isChaos_ = {}
	arg_2_0.energyLimit_ = 1
	arg_2_0.___attrCache = {}
	arg_2_0.___ackSpeed = nil

	arg_2_0:updateTeamCache()

	arg_2_0.__debuffNum = nil
	arg_2_0.__gainBuffNum = nil
	arg_2_0.specialSkills_ = nil
	arg_2_0.unitSkills_ = nil
	arg_2_0.buffHalo_ = {}

	if arg_2_0.hero_ then
		arg_2_0.startSkillQueue_ = arg_2_0.hero_:getStartCircle()
		arg_2_0.skillQueue_ = arg_2_0.hero_:getCircle()

		arg_2_0:cleanAllBuffs()
		arg_2_0:popColorSkill()
		arg_2_0:initElementEquip()
	end

	arg_2_0.courseBuffCD_ = {}
	arg_2_0.courseSelfSkillCD_ = {}

	arg_2_0:initElement()
	arg_2_0:initHunqi()
end

function var_0_3.addInitBuffs(arg_3_0)
	local function var_3_0(arg_4_0, arg_4_1, arg_4_2)
		local var_4_0 = {}

		for iter_4_0, iter_4_1 in ipairs(arg_4_0) do
			local var_4_1 = var_0_4.new({
				tableID = iter_4_1,
				start = var_0_1.ctx.battle.count,
				level = arg_4_2,
				skillID = arg_4_1,
				fighter = arg_3_0,
				target = arg_3_0
			})

			table.insert(var_4_0, var_4_1)
		end

		return var_4_0
	end

	local var_3_1

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		var_3_1 = arg_3_0.initBuffRecord or {}
	else
		var_3_1 = arg_3_0.hero_.buffs_ or {}
		arg_3_0.records_.init_buff = var_3_1
	end

	if next(var_3_1) then
		local var_3_2 = var_3_0(var_3_1, arg_3_0:getEnergySkillID(), arg_3_0:getSkillLevelByColor(var_0_2.SKILL_INDEX.Energy))

		arg_3_0:addBuffs(var_3_2)
	end
end

function var_0_3.populateWithHero(arg_5_0, arg_5_1)
	arg_5_0.partnerID_ = arg_5_1:getTableID()
	arg_5_0.hero_ = arg_5_1

	arg_5_0:initHp()

	arg_5_0.level_ = arg_5_1:getLevel()
	arg_5_0.energySkillID_ = arg_5_1:getSkillId(var_0_2.SKILL_INDEX.Energy)
	arg_5_0.startSkillQueue_ = arg_5_0.hero_:getStartCircle()
	arg_5_0.skillQueue_ = arg_5_0.hero_:getCircle()
	arg_5_0.energy_ = var_0_13:initMp(arg_5_0.partnerID_)
	arg_5_0.summonType_ = var_0_13:summonType(arg_5_0.partnerID_)

	arg_5_0:checkSkinSkillInfo()
	arg_5_0:setupSkillLevel()
	arg_5_0:skillQueueTest()
	arg_5_0:popColorSkill()
	arg_5_0:initElementEquip()
end

function var_0_3.singleLoop(arg_6_0)
	arg_6_0:updateBaseInfo()
	arg_6_0:checkMove()

	if not arg_6_0:isDeath() then
		arg_6_0:createAttacks()
		arg_6_0:createSpecialAttacks()
	end

	arg_6_0:beginAttack()
	arg_6_0:beginSpecialAttack()

	if arg_6_0:acttionInBlack() then
		arg_6_0:applyUnitMoves()
		arg_6_0:applyUnitHarms()
		arg_6_0:applyBuffHarms()
	end

	arg_6_0:applyBuffMoves()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_6_0.reportDieCount_ > 0 and var_0_1.ctx.battle.count > arg_6_0.reportDieCount_ and arg_6_0.isDead_ ~= true then
		arg_6_0:forceUpdateHp(0)
		arg_6_0:forceDie()
	end

	arg_6_0:toDoPerFrames()
	arg_6_0:elementToDoPerFrames()
	arg_6_0:hunqiToDoPerFrames()

	if not arg_6_0.isAddCourseInitBuff_ then
		arg_6_0.isAddCourseInitBuff_ = true

		arg_6_0:addCourseInitBuff()
	end

	if var_0_1.ctx.battle.count % 10 == 0 and not arg_6_0:isDeath() then
		arg_6_0:checkBuffHaloEffect()
	end

	if var_0_1.ctx.battle.count % (var_0_1.ctx.battle.timeScale * 30) == 0 and not arg_6_0:isDeath() and arg_6_0.mpBar_ and arg_6_0.avatarIndex_ then
		arg_6_0.bottomWnd:updateBuffIconShow(nil, nil, arg_6_0.avatarIndex_, true)
	end

	arg_6_0:updateCourseBuffCD()
end

function var_0_3.updateBaseInfo(arg_7_0)
	if arg_7_0:isDeath() then
		return
	end

	if arg_7_0:acttionInBlack() then
		arg_7_0:clearFunctionsCache()
		arg_7_0:updateNearestTarget()
		arg_7_0:updateLeftInterval()
		arg_7_0:updateStateCount()
		arg_7_0:checkSkillRoll()
		arg_7_0:updateBuffCount()
		arg_7_0:updateEnergyByCount()
	end

	if arg_7_0:getTeamType() == var_0_2.TeamType.A and arg_7_0.bottomWnd and not tolua.isnull(arg_7_0.bottomWnd) then
		arg_7_0.bottomWnd:updateUIEffect(arg_7_0, var_0_1.ctx.battle.teamA, arg_7_0:checkEnergySkill())
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_7_0.reportEnergy_[1] and arg_7_0.reportEnergy_[1] <= var_0_1.ctx.battle.count then
			arg_7_0.isEnergySkill_ = true
			arg_7_0.leftInterval_ = 0
			arg_7_0.arenaEnergyFull_ = nil

			table.remove(arg_7_0.reportEnergy_, 1)
		end
	elseif arg_7_0:checkEnergySkill() and arg_7_0:isAutoFighter() and not arg_7_0:isCreatingUnits() then
		arg_7_0.isEnergySkill_ = true
		arg_7_0.leftInterval_ = 0
		arg_7_0.arenaEnergyFull_ = nil

		table.insert(arg_7_0.records_.energy, var_0_1.ctx.battle.count)
	end

	if arg_7_0:acttionInBlack() then
		if arg_7_0.unitSkills_ then
			arg_7_0.unitSkills_:updateCount()
		end

		if arg_7_0.specialSkills_ then
			arg_7_0.specialSkills_:updateCount()
		end
	end
end

function var_0_3.born(arg_8_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_8_0.bornCount_ = var_0_1.ctx.battle.count
	end

	if var_0_1.ctx.battle.infoListener.born_info then
		table.insert(var_0_1.ctx.battle.infoListener.born_info, arg_8_0)
	end

	arg_8_0:summon()
end

function var_0_3.die(arg_9_0)
	if arg_9_0:isForverNeverDie() then
		arg_9_0:updateHp(1)

		return
	end

	if arg_9_0:isNeverDie() then
		local var_9_0 = arg_9_0.neverDieBuffs_[1]
		local var_9_1 = var_9_0.fighter

		arg_9_0:removeBuffs(var_9_0)
		arg_9_0:updateHp(1)
		var_9_1:neverDieFeedBack(arg_9_0)

		return
	end

	arg_9_0:isLeadDeal()
	arg_9_0:forceDie()
end

function var_0_3.forceDie(arg_10_0)
	if var_0_1.ctx.battle.infoListener.death_info then
		table.insert(var_0_1.ctx.battle.infoListener.death_info, arg_10_0)
	end

	var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.model:deathSound(arg_10_0:getModelID()))

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_10_0.records_.die_count = var_0_1.ctx.battle.count
	else
		arg_10_0.isDead_ = true
	end

	arg_10_0:elementImmortal()
	arg_10_0:setParalysis(false)
	arg_10_0:updateHp(0)
	arg_10_0:playDrop()
	arg_10_0:updateEnergyTo(0)
	arg_10_0:deathFeedbacks()
	arg_10_0:deadForceRemoveSkill()
	arg_10_0:cleanAllBuffs()
	arg_10_0.fighterModel:hideHeaderView()
	arg_10_0.fighterModel:hideLayers()
	arg_10_0:getFighterModel():resume()
	arg_10_0:updateStateNumber()
	arg_10_0:unsetMaskColor()
	arg_10_0:clearBuffHalo()

	if arg_10_0:getTeamType() == var_0_2.TeamType.A and arg_10_0.bottomWnd then
		arg_10_0.bottomWnd:updateUIEffect(arg_10_0, var_0_1.ctx.battle.teamA, false)
	end

	local var_10_0 = var_0_2.tables.battleConfig.removeHeroModelDuration

	arg_10_0:getFighterModel():die()

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		arg_10_0.fighterModel:runActionOnce(cc.FadeOut:create(var_10_0), false, function()
			if not var_0_1.ctx.battle.isReleased(arg_10_0.fighterModel) then
				arg_10_0.fighterModel:setVisible(false)
				arg_10_0:getFighterModel():stop()
			end
		end, 1)
	end
end

function var_0_3.isLeadDeal(arg_12_0)
	local var_12_0 = false

	for iter_12_0, iter_12_1 in ipairs(arg_12_0.buffs_) do
		if iter_12_1:isLeadBuff() then
			var_12_0 = true

			arg_12_0:removeBuffs(iter_12_1)

			break
		end
	end

	if var_12_0 then
		for iter_12_2, iter_12_3 in ipairs(arg_12_0.selfTeam_) do
			if iter_12_3:getSummonType() ~= var_0_2.summonMonsterType.None then
				iter_12_3:die()
			end
		end

		for iter_12_4, iter_12_5 in ipairs(arg_12_0.selfTeam_) do
			if iter_12_5:getSummonType() == var_0_2.summonMonsterType.None then
				iter_12_5:forceDie()
			end
		end
	end
end

function var_0_3.deathFeedbacks(arg_13_0)
	for iter_13_0, iter_13_1 in ipairs(arg_13_0.selfTeam_) do
		if not iter_13_1:isDeath() then
			iter_13_1:deathFeedback(arg_13_0)
		end
	end

	for iter_13_2, iter_13_3 in ipairs(arg_13_0.sideTeam_) do
		if not iter_13_3:isDeath() then
			iter_13_3:deathFeedback(arg_13_0)
		end
	end
end

function var_0_3.deathFeedback(arg_14_0, arg_14_1)
	return
end

function var_0_3.shieldFeedBack(arg_15_0, arg_15_1, arg_15_2)
	return
end

function var_0_3.neverDieFeedBack(arg_16_0, arg_16_1)
	return
end

function var_0_3.dHarmBuffBreakFeedback(arg_17_0, arg_17_1, arg_17_2, arg_17_3)
	return
end

function var_0_3.dHarmBuffFeedback(arg_18_0, arg_18_1, arg_18_2)
	return
end

function var_0_3.playDrop(arg_19_0)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.CreateReport or var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return
	end

	if not arg_19_0.dropMana_ or not arg_19_0.dropItems_ then
		return
	end

	local var_19_0 = var_0_1.ctx.battle.distributeGuildIteams(arg_19_0)

	if var_19_0 then
		table.insert(arg_19_0.dropItems_, var_19_0)
	end

	local var_19_1 = 0
	local var_19_2, var_19_3 = arg_19_0.fighterModel:getPosition()
	local var_19_4
	local var_19_5
	local var_19_6

	if not var_0_1.ctx.battle.isUnlimitBattle then
		var_19_2 = var_0_68(var_19_2, var_0_2.STAGE_WIDTH - 100)

		local var_19_7 = var_0_68(100 * #arg_19_0.dropItems_, var_0_2.STAGE_WIDTH - 80)

		var_19_5 = var_19_7 / (#arg_19_0.dropItems_ + 1)
		var_19_6 = var_0_69(var_19_2 - var_19_7 / 2, 80)
		var_19_6 = var_0_68(var_19_6, var_0_2.STAGE_WIDTH - var_19_7)
	else
		var_19_2 = var_0_68(var_19_2, var_0_2.UNLIMIT_STAGE_WIDTH - 166)

		local var_19_8 = var_0_68(166 * #arg_19_0.dropItems_, var_0_2.UNLIMIT_STAGE_WIDTH - 133)

		var_19_5 = var_19_8 / (#arg_19_0.dropItems_ + 1)
		var_19_6 = var_0_69(var_19_2 - var_19_8 / 2, 133)
		var_19_6 = var_0_68(var_19_6, var_0_2.UNLIMIT_STAGE_WIDTH - var_19_8)
	end

	for iter_19_0, iter_19_1 in ipairs(arg_19_0.dropItems_) do
		local var_19_9 = "skeletons/ui_effect/common_effect_shine_box/common_effect_shine_box"
		local var_19_10 = var_0_10.new(var_19_9 .. ".json", var_19_9 .. ".atlas", 1)
		local var_19_11 = display.newNode()

		var_19_11:size(100, 100)
		var_19_11:setAnchorPoint(cc.p(0, 0))
		var_19_11:addTo(var_0_1.ctx.battle.playerLayer, 1)
		var_19_10:align(display.CENTER, var_19_11:getWidth() / 2, var_19_11:getHeight() / 2):addTo(var_19_11)
		var_19_10:play(nil, true)
		var_19_10:setTouchSwallowEnabled(false)
		var_19_11:pos(var_19_2, var_19_3)

		local var_19_12 = var_0_2.tables.battleConfig.itemDropOffY
		local var_19_13 = var_19_6 + var_19_1 * var_19_5
		local var_19_14 = var_19_13 / 2
		local var_19_15 = var_19_3 + var_19_12
		local var_19_16 = var_19_13
		local var_19_17

		if not var_0_1.ctx.battle.isUnlimitBattle then
			var_19_17 = {
				cc.p(0, 0),
				cc.p(var_19_14 - var_19_2 / 2, var_19_12),
				cc.p(var_19_16 - var_19_2, 170 - var_19_3)
			}
		else
			var_19_17 = {
				cc.p(0, 0),
				cc.p(var_19_14 - var_19_2 / 2, var_19_12),
				cc.p(var_19_16 - var_19_2, 280 - var_19_3)
			}
		end

		local var_19_18 = cc.CardinalSplineBy:create(0.5, var_19_17, 0)

		iter_19_1.sprite = var_19_11
		var_19_11.item = iter_19_1
		var_0_1.ctx.battle.dropAwardCount = var_0_1.ctx.battle.dropAwardCount + 1

		var_19_11:setTouchSwallowEnabled(false)
		var_19_11:runActionOnce(var_19_18, false, function()
			var_19_11:setTouchEnabled(true)
			var_19_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_21_0)
				if arg_21_0.name == "ended" then
					arg_19_0:showAwardAction(iter_19_1, true)
				end

				return true
			end)
		end)

		var_19_1 = var_19_1 + 1
	end

	if arg_19_0.dropMana_ > 0 then
		arg_19_0.fighterModel:playManaDrop(arg_19_0.dropMana_)

		var_0_1.ctx.battle.dropManaCount = var_0_1.ctx.battle.dropManaCount + arg_19_0.dropMana_

		arg_19_0.topWnd:getTongqianLabel():setString(var_0_1.ctx.battle.dropManaCount)
	end
end

function var_0_3.adjustyY(arg_22_0)
	return
end

function var_0_3.checkMove(arg_23_0)
	if var_0_1.ctx.battle.isEnergySkilling or arg_23_0:isDeath() or arg_23_0.isEscapeEnemyMove then
		return
	end

	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		if arg_23_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)] then
			arg_23_0:flipX(arg_23_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)] < arg_23_0:getX())
			arg_23_0:x(arg_23_0.reportMoveX_[tostring(var_0_1.ctx.battle.count)])
		end

		if arg_23_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] and arg_23_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] < 3 and not arg_23_0:isWalkAnimation() then
			arg_23_0:modelWalk()
		elseif not arg_23_0.reportWalkState_[tostring(var_0_1.ctx.battle.count)] and arg_23_0:isWalkAnimation() then
			arg_23_0:resumeIdle()
		end
	elseif var_0_1.ctx.battle.walk2NextBattle_ and arg_23_0:getTeamType() == var_0_2.TeamType.A then
		arg_23_0.isWalking_ = 1
		arg_23_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		arg_23_0:flipX(false)

		if not arg_23_0:isWalking() then
			arg_23_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_23_0:isWalking() == 2 then
			arg_23_0:moveByX(arg_23_0:getCurrentSpeed() * var_0_2.tables.battleConfig.speedAccelerate)
		end

		if not arg_23_0:isWalkAnimation() then
			arg_23_0:modelWalk()
		end
	elseif arg_23_0:isMoveUnable() or arg_23_0:isInSkillRoll() or arg_23_0.manualDirection_ then
		if arg_23_0:isWalkAnimation() then
			arg_23_0:resumeIdle()
		end

		arg_23_0.walk2Position_ = false
		arg_23_0.preWalk_ = false
		arg_23_0.isWalking_ = false
		arg_23_0.behindWalk_ = false
	elseif arg_23_0.walk2Position_ then
		if arg_23_0:isWalked2Position() then
			arg_23_0.walk2Position_ = false

			if arg_23_0:isTargetBeyondReach() then
				arg_23_0.isWalking_ = 1
			else
				arg_23_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk
			end
		else
			arg_23_0.isWalking_ = 1

			if not arg_23_0:isWalking() then
				arg_23_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
			elseif arg_23_0:isWalking() == 2 then
				local var_23_0 = arg_23_0:getFlipX() and -1 or 1

				arg_23_0:moveByX(arg_23_0:getCurrentSpeed() * var_23_0)
			end

			if not arg_23_0:isWalkAnimation() then
				arg_23_0:modelWalk()
			end
		end

		arg_23_0:writeWalkState()
	elseif arg_23_0:isFear() then
		arg_23_0.walk2Position_ = false
		arg_23_0.isWalking_ = 1
		arg_23_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		local var_23_1 = arg_23_0:getTeamType() == var_0_2.TeamType.A and -1 or 1

		if arg_23_0.fearMoveDir_ then
			var_23_1 = -var_23_1
		end

		arg_23_0:flipX(var_23_1 < 0)

		local var_23_2 = arg_23_0:getCurrentSpeed() * var_23_1

		if arg_23_0:getX() + var_23_2 < arg_23_0:getFighterModel():getWidth() / 2 and var_23_2 < 0 then
			var_23_2 = arg_23_0:getFighterModel():getWidth() / 2 - arg_23_0:getX()
		end

		if not var_0_1.ctx.battle.isUnlimitBattle then
			if arg_23_0:getX() + var_23_2 > var_0_2.STAGE_WIDTH - arg_23_0:getFighterModel():getWidth() / 2 and var_23_2 > 0 then
				var_23_2 = var_0_2.STAGE_WIDTH - arg_23_0:getFighterModel():getWidth() / 2 - arg_23_0:getX()
			end
		elseif arg_23_0:getX() + var_23_2 > var_0_2.UNLIMIT_STAGE_WIDTH - arg_23_0:getFighterModel():getWidth() / 2 and var_23_2 > 0 then
			var_23_2 = var_0_2.UNLIMIT_STAGE_WIDTH - arg_23_0:getFighterModel():getWidth() / 2 - arg_23_0:getX()
		end

		if not arg_23_0:isWalking() then
			arg_23_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_23_0:isWalking() == 2 then
			arg_23_0:moveByX(var_23_2)
		end

		if not arg_23_0:isWalkAnimation() then
			arg_23_0:modelWalk()
		end

		arg_23_0:writeWalkState()
	elseif arg_23_0:isTargetBeyondReach() then
		arg_23_0.isWalking_ = 1
		arg_23_0.behindWalk_ = var_0_1.ctx.battleConst.BehindWalk

		local var_23_3 = arg_23_0:getNearestTarget():getX() > arg_23_0:getX() and 1 or -1

		arg_23_0:flipX(var_23_3 < 0)

		if not arg_23_0:isWalking() then
			arg_23_0.preWalk_ = var_0_1.ctx.battleConst.PreWalk
		elseif arg_23_0:isWalking() == 2 then
			arg_23_0:moveByX(arg_23_0:getCurrentSpeed() * var_23_3)
		end

		if not arg_23_0:isWalkAnimation() then
			arg_23_0:modelWalk()
		end

		arg_23_0:writeWalkState()
	elseif arg_23_0:isWalking() ~= 3 then
		arg_23_0.preWalk_ = false
		arg_23_0.isWalking_ = false
		arg_23_0.behindWalk_ = false

		if arg_23_0:isWalkAnimation() then
			arg_23_0:resumeIdle()
		end
	else
		arg_23_0:writeWalkState()
	end
end

function var_0_3.canAttack(arg_24_0)
	if arg_24_0:isDeath() then
		return false
	end

	if arg_24_0:getLeftInterval() > 0 then
		return false
	end

	if arg_24_0:isBattleUnable() then
		return false
	end

	if arg_24_0.isEnergySkill_ and arg_24_0:isCreatingUnits() then
		return false
	end

	if arg_24_0.isEnergySkill_ then
		return true
	end

	if arg_24_0.invalidSkillQueue_ and (not var_0_1.ctx.battle.isActivity or not next(arg_24_0.startSkillQueue_)) then
		return false
	end

	if arg_24_0:isCreatingUnits() then
		return false
	end

	if arg_24_0:isInSkillRoll() then
		return false
	end

	if arg_24_0:isWalking() or arg_24_0:isAdjustY() or var_0_1.ctx.battle.isEnergySkilling then
		return false
	end

	if not arg_24_0:getNearestTarget() then
		return false
	end

	if arg_24_0:isTargetBeyondReach() then
		return false
	end

	if var_0_1.ctx.battle.count == 1 or var_0_1.ctx.battle.count == -2699 then
		return false
	end

	return true
end

function var_0_3.beginAttack(arg_25_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_25_0 = arg_25_0.reportSkills_[1]

		if not var_25_0 or var_0_1.ctx.battle.count ~= var_25_0.startCount_ then
			if arg_25_0.reportSkills_[2] and arg_25_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_25_0.reportSkills_, 1)
			else
				return
			end
		end

		if arg_25_0:isDeath() then
			return
		end
	elseif not arg_25_0:canAttack() then
		return
	end

	arg_25_0:resetLeftInterval()

	local var_25_1 = arg_25_0:popSkillByType()
	local var_25_2 = var_0_12:type(var_25_1)

	if var_25_1 == 0 or var_25_2 == var_0_2.AttackType.AD and arg_25_0:isExcuteAdCircle() or var_25_2 == var_0_2.AttackType.AP and arg_25_0:isExcuteApCircle() then
		return
	end

	if arg_25_0.manualTargets_ and next(arg_25_0.manualTargets_) then
		if arg_25_0.manualTargets_[1]:isDeath() then
			arg_25_0.manualTargets_ = nil
		else
			arg_25_0:flipX(arg_25_0.manualTargets_[1]:getX() < arg_25_0:getX())
		end
	elseif not arg_25_0.manualDirection_ and arg_25_0:getNearestTarget() then
		arg_25_0:flipX(arg_25_0:getNearestTarget():getX() < arg_25_0:getX())
	end

	arg_25_0:energyAction(var_25_1)

	local var_25_3 = var_0_12:sound(var_25_1)

	var_0_1.ctx.battle.pushSoundQueue(var_25_3)

	local var_25_4 = var_0_12:attackIndex(var_25_1)

	arg_25_0:playAttack(var_25_4)
	arg_25_0:selfSkillEffect()

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_25_0.unitSkills_ = arg_25_0.reportSkills_[1]
	else
		arg_25_0.unitSkills_ = var_0_5.new({
			fighter = arg_25_0,
			skillID = var_25_1
		})
	end

	arg_25_0:beginAttackEnd(arg_25_0.unitSkills_)
end

function var_0_3.beginSpecialAttack(arg_26_0)
	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		return
	end

	local var_26_0 = arg_26_0.reportSpecialSkills_[1]

	if not var_26_0 or var_0_1.ctx.battle.count ~= var_26_0.startCount_ then
		if arg_26_0.reportSpecialSkills_[2] and arg_26_0.reportSpecialSkills_[2].startCount_ == var_0_1.ctx.battle.count then
			table.remove(arg_26_0.reportSpecialSkills_, 1)
		else
			return
		end
	end

	arg_26_0.specialSkills_ = arg_26_0.reportSpecialSkills_[1]

	arg_26_0:beginAttackEnd(arg_26_0.specialSkills_)
end

function var_0_3.beginAttackEnd(arg_27_0, arg_27_1)
	if var_0_1.ctx.battle.infoListener.attack_info then
		table.insert(var_0_1.ctx.battle.infoListener.attack_info, arg_27_1)
	end

	if arg_27_0:isUseSkillCount() then
		for iter_27_0 = 1, #arg_27_0.useSkillCount_ do
			local var_27_0 = arg_27_0.useSkillCount_[iter_27_0]

			if var_27_0 then
				var_27_0.useSkillCount_ = var_27_0.useSkillCount_ - 1

				if var_27_0.useSkillCount_ <= 0 then
					arg_27_0:removeBuffs(var_27_0)
				end
			end
		end
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return
	end

	if arg_27_0.unitSkills_ and arg_27_1 == arg_27_0.unitSkills_ then
		table.insert(arg_27_0.records_.skills, arg_27_1)
	else
		table.insert(arg_27_0.records_.special_skills, arg_27_1)
	end
end

function var_0_3.createAttacks(arg_28_0)
	local var_28_0 = arg_28_0.unitSkills_

	if not var_28_0 then
		return
	end

	if var_28_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_28_0.reportSkills_, 1)
		end

		arg_28_0:clearUnitSkillAction(arg_28_0.unitSkills_)

		arg_28_0.unitSkills_ = nil

		return
	end

	local var_28_1, var_28_2 = var_28_0:getFront()

	while var_28_1 and var_28_1 < 1 do
		if var_0_1.ctx.battle.infoListener.createAttack_info then
			table.insert(var_0_1.ctx.battle.infoListener.createAttack_info, arg_28_0)
		end

		arg_28_0:createUnits(var_28_0)
		var_28_0:popQueue()

		local var_28_3

		var_28_1, var_28_3 = var_28_0:getFront()

		if not arg_28_0:isCreatingUnits() then
			arg_28_0:clearUnitSkillAction(arg_28_0.unitSkills_)

			arg_28_0.unitSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_28_0.reportSkills_, 1)
			end

			arg_28_0:updateEnergyBy(var_28_0:getRemp() * arg_28_0:getEnergyRate())
			arg_28_0:popFrontSkill()
		end
	end
end

function var_0_3.createSpecialAttacks(arg_29_0)
	local var_29_0 = arg_29_0.specialSkills_

	if not var_29_0 then
		return
	end

	if var_29_0:isEmptyQueue() then
		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			table.remove(arg_29_0.reportSpecialSkills_, 1)
		end

		arg_29_0:clearUnitSkillAction(arg_29_0.specialSkills_)

		arg_29_0.specialSkills_ = nil

		return
	end

	local var_29_1 = var_29_0:getFront()

	while var_29_1 and var_29_1 < 1 do
		arg_29_0:createUnits(var_29_0)
		var_29_0:popQueue()

		var_29_1, skillID = var_29_0:getFront()

		if not arg_29_0:isCreatingSpecialUnits() then
			arg_29_0:clearUnitSkillAction(arg_29_0.specialSkills_)

			arg_29_0.specialSkills_ = nil

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				table.remove(arg_29_0.reportSpecialSkills_, 1)
			end
		end
	end
end

function var_0_3.updateAvatar(arg_30_0)
	return
end

function var_0_3.updateBuffs(arg_31_0)
	return
end

function var_0_3.updateOther(arg_32_0)
	return
end

function var_0_3.applyUnitMoves(arg_33_0)
	local var_33_0 = {}

	for iter_33_0 = 1, #arg_33_0.moveUnits_ do
		if next(arg_33_0.moveUnits_) and arg_33_0.moveUnits_[iter_33_0].arrived then
			local var_33_1 = arg_33_0.moveUnits_[iter_33_0]

			arg_33_0:moveUnitArrive(var_33_1)
			table.insert(var_33_0, iter_33_0)
		elseif arg_33_0.moveUnits_[iter_33_0] ~= nil then
			local var_33_2 = arg_33_0.moveUnits_[iter_33_0]

			var_33_2:rotate()
			var_33_2:movePosition()

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and var_33_2.selectType == "C11" then
				local var_33_3 = var_33_2:getReportUnits()

				for iter_33_1, iter_33_2 in ipairs(var_33_3) do
					table.insert(arg_33_0.applyUnits_, iter_33_2)
				end
			elseif var_33_2.selectType == "C11" then
				local var_33_4 = arg_33_0:getTargets(var_33_2.skillID, var_33_2)

				if next(var_33_4) then
					local var_33_5 = var_33_2:createAttacks(var_33_4)

					for iter_33_3, iter_33_4 in ipairs(var_33_5) do
						table.insert(arg_33_0.applyUnits_, iter_33_4)
					end
				end
			end
		end
	end

	for iter_33_5 = #var_33_0, 1, -1 do
		local var_33_6 = var_33_0[iter_33_5]

		table.remove(arg_33_0.moveUnits_, var_33_6)
	end

	local var_33_7 = {}

	for iter_33_6 = 1, #arg_33_0.moveAttackUnits_ do
		local var_33_8 = arg_33_0.moveAttackUnits_[iter_33_6]

		if var_33_8.arrived then
			if not var_0_0.table.keyof(arg_33_0.applyUnits_, var_33_8) then
				table.insert(arg_33_0.applyUnits_, var_33_8)
			end

			if var_33_8.collisionNum > 1 then
				-- block empty
			else
				if var_33_8.resource and not var_0_1.ctx.battle.isReleased(var_33_8.resource) then
					var_33_8.resource:stop()

					var_33_8.resource = nil
				else
					var_33_8.resource = nil
				end

				table.insert(var_33_7, iter_33_6)
			end
		end

		if var_33_8.speed == 0 and var_33_8.arrived and (var_33_8.unitEffectType == var_0_2.UnitEffectType.ShanDianLian or var_33_8.unitEffectType == var_0_2.UnitEffectType.ShenMieZhan) then
			local var_33_9 = #var_33_8.targets_ > 1 and var_33_8.targets_[#var_33_8.targets_ - 1] or arg_33_0
			local var_33_10 = var_33_8.target
			local var_33_11 = #var_33_8.targets_ > 1 and var_33_9:getX() + var_33_9:getFighterModel().attackedPoint.x or var_33_8:getIniPos("x")
			local var_33_12 = var_33_10:getX() + var_33_10:getFighterModel().attackedPoint.x
			local var_33_13 = #var_33_8.targets_ > 1 and var_33_9:getY() + var_33_9:getFighterModel().attackedPoint.y or var_33_8:getIniPos("y")
			local var_33_14 = var_33_10:getY() + var_33_10:getFighterModel().attackedPoint.y
			local var_33_15 = var_33_8:createResource()
			local var_33_16 = var_33_15:getSizeX() - 10

			var_33_16 = var_33_16 < 0 and 180 or var_33_16

			var_33_15:addTo(var_0_1.ctx.battle.unitLayer)
			var_33_15:setScaleX(var_0_73((var_33_12 - var_33_11) * (var_33_12 - var_33_11) + (var_33_14 - var_33_13) * (var_33_14 - var_33_13)) / var_33_16)
			var_33_15:setRotation(math.atan2(var_33_14 - var_33_13, var_33_12 - var_33_11) / math.pi * -180)
			var_33_15:x((var_33_12 + var_33_11) / 2)
			var_33_15:y((var_33_14 + var_33_13) / 2)
			var_33_15:playOnce()
			arg_33_0:flipX(var_33_8.target:getX() < arg_33_0:getX())
		end

		if var_33_8.speed > 0 and not var_33_8.arrived then
			if var_33_8.count ~= var_0_1.ctx.battle.count then
				var_33_8:rotate()
				var_33_8:movePosition()
			end

			if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
				if var_33_8.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)] then
					var_33_8:resetTarget(var_33_8.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)])
				end
			elseif var_33_8.isResetTarget and var_33_8.target:isDeath() then
				local var_33_17 = arg_33_0:getTargets(var_33_8.skillID, var_33_8)

				if var_33_17 and next(var_33_17) then
					var_33_8:resetTarget(var_33_17[1])
				end
			end
		elseif var_33_8.speed == 0 and not var_33_8.arrived then
			var_33_8.collisionCount = var_33_8.collisionCount - 1

			if var_33_8:getCollisionCount() <= 0 then
				if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
					if var_33_8.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)] then
						var_33_8:resetTarget(var_33_8.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)])
					end
				elseif var_33_8.isResetTarget and var_33_8.target:isDeath() then
					local var_33_18 = arg_33_0:getTargets(var_33_8.skillID, var_33_8)

					if var_33_18 and next(var_33_18) then
						var_33_8:resetTarget(var_33_18[1])
					end
				end

				var_33_8.arrived = true

				var_33_8:setCollisionCount()
			end
		end
	end

	for iter_33_7 = #var_33_7, 1, -1 do
		local var_33_19 = var_33_7[iter_33_7]

		table.remove(arg_33_0.moveAttackUnits_, var_33_19)
	end
end

function var_0_3.applyUnitHarms(arg_34_0)
	local var_34_0 = {}

	for iter_34_0 = 1, #arg_34_0.applyUnits_ do
		local var_34_1 = arg_34_0.applyUnits_[iter_34_0]
		local var_34_2 = var_34_1.target

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			if var_0_0.table.nums(var_34_1.reportData_.calculate) < 1 then
				table.insert(var_34_0, iter_34_0)
				var_34_1:clearCollisionNum()
				var_0_0.table.removebyvalue(arg_34_0.moveAttackUnits_, var_34_1)

				if var_34_1.resource and var_0_1.ctx.battle.isReleased(var_34_1.resource) ~= true then
					var_34_1.resource:stop()
					var_34_1.resource:removeSelf()

					var_34_1.resource = nil

					break
				end

				var_34_1.resource = nil

				break
			end

			if var_34_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)] then
				table.insert(var_34_0, iter_34_0)
				arg_34_0:applySingleUnit(var_34_1)

				var_34_1.isApply = true

				if var_34_1.collisionNum > 1 then
					var_34_1:setCollisionNum()

					if var_34_1.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)] then
						var_34_1:resetTarget(var_34_1.reportData_.resetTarget[tostring(var_0_1.ctx.battle.count)])

						var_34_1.applyCount = var_0_1.ctx.battle.count
						var_34_1.isApply = nil
						var_34_1.arrived = false
					else
						arg_34_0:unitCollisionBreak(var_34_1)
						var_34_1:clearCollisionNum()
						var_0_0.table.removebyvalue(arg_34_0.moveAttackUnits_, var_34_1)

						if var_34_1.resource and var_0_1.ctx.battle.isReleased(var_34_1.resource) ~= true then
							var_34_1.resource:stop()
							var_34_1.resource:removeSelf()

							var_34_1.resource = nil
						else
							var_34_1.resource = nil
						end
					end
				end
			end
		elseif var_34_1.applyCount <= var_0_1.ctx.battle.count then
			table.insert(var_34_0, iter_34_0)

			if var_34_1:isInvalidAfterDeath() and arg_34_0:isDeath() then
				var_34_1:clearCollisionNum()
				var_0_0.table.removebyvalue(arg_34_0.moveAttackUnits_, var_34_1)

				if var_34_1.resource and var_0_1.ctx.battle.isReleased(var_34_1.resource) ~= true then
					var_34_1.resource:stop()
					var_34_1.resource:removeSelf()

					var_34_1.resource = nil

					break
				end

				var_34_1.resource = nil

				break
			end

			arg_34_0:applySingleUnit(var_34_1)

			var_34_1.isApply = true

			if var_34_1.collisionNum > 1 then
				var_34_1:setCollisionNum()

				local var_34_3 = arg_34_0:getTargets(var_34_1.skillID, var_34_1)

				if next(var_34_3) then
					var_34_1:resetTarget(var_34_3[1])

					var_34_1.applyCount = var_0_1.ctx.battle.count
					var_34_1.isApply = nil
					var_34_1.arrived = false
				else
					arg_34_0:unitCollisionBreak(var_34_1)
					var_34_1:clearCollisionNum()
					var_0_0.table.removebyvalue(arg_34_0.moveAttackUnits_, var_34_1)

					if var_34_1.resource and var_0_1.ctx.battle.isReleased(var_34_1.resource) ~= true then
						var_34_1.resource:stop()
						var_34_1.resource:removeSelf()

						var_34_1.resource = nil
					else
						var_34_1.resource = nil
					end
				end
			end
		end
	end

	for iter_34_1 = #var_34_0, 1, -1 do
		local var_34_4 = var_34_0[iter_34_1]

		table.remove(arg_34_0.applyUnits_, var_34_4)
	end
end

function var_0_3.applyBuffHarms(arg_35_0)
	if arg_35_0:isDeath() or arg_35_0:isAffected() then
		return
	end

	local var_35_0 = var_0_2.tables.battleConfig.buffHarmBaseDuration

	if var_0_1.ctx.battle.count % var_35_0 > 0 then
		return
	end

	local var_35_1 = arg_35_0:applyBuffHarm()

	if arg_35_0:isDeath() then
		if var_35_1 and var_35_1.isAwakeHero and var_35_1.awakeMissionGoalType and var_35_1.awakeMissionGoalType == var_0_2.AwakeStage3MissionType.SELF_KILL and arg_35_0.hero_:getTableID() == var_35_1.awakeMonsterID then
			if var_35_1.summoner then
				var_35_1.summoner.isDoneSelfKill = true
			else
				var_35_1.isDoneSelfKill = true
			end
		end

		if var_35_1 and not var_35_1:isDeath() and arg_35_0:canReborn() ~= true and arg_35_0:getSummonType() == var_0_2.summonMonsterType.None then
			arg_35_0.killer_ = var_35_1
		end

		arg_35_0:die()
	end

	if arg_35_0:isDeath() and var_35_1 and not var_35_1:isDeath() and arg_35_0:canReborn() ~= true and arg_35_0:getSummonType() == var_0_2.summonMonsterType.None then
		var_35_1:checkKilling()
	end
end

function var_0_3.checkReHpMp(arg_36_0)
	if arg_36_0:isDeath() then
		return
	end

	arg_36_0:updateHp(arg_36_0:getHp() + arg_36_0:getReHP())
	arg_36_0:updateEnergyBy(arg_36_0:getReMP())
	arg_36_0.fighterModel:playReHPMPFloat(arg_36_0:getReHP(), arg_36_0:getReMP())
end

function var_0_3.playWin(arg_37_0)
	if arg_37_0:isDeath() then
		return
	end

	arg_37_0:getFighterModel():win(true)
end

function var_0_3.applyBuffMoves(arg_38_0)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		if next(arg_38_0.buffMovePath_) then
			table.remove(arg_38_0.buffMovePath_, 1)
		end

		if arg_38_0.reportBuffMoveX_[tostring(var_0_1.ctx.battle.count)] then
			arg_38_0:x(arg_38_0.reportBuffMoveX_[tostring(var_0_1.ctx.battle.count)])
		end

		if arg_38_0.reportBuffMoveY_[tostring(var_0_1.ctx.battle.count)] then
			arg_38_0:y(arg_38_0.reportBuffMoveY_[tostring(var_0_1.ctx.battle.count)])
		end

		return
	end

	if arg_38_0:isBreakImmortal() then
		return
	end

	if next(arg_38_0.buffMovePath_) == nil or var_0_1.ctx.battle.isReleased(arg_38_0.fighterModel) then
		return
	end

	local var_38_0, var_38_1 = unpack(arg_38_0.buffMovePath_[1])

	table.remove(arg_38_0.buffMovePath_, 1)

	if var_38_0 ~= 0 or var_38_1 ~= 0 then
		if arg_38_0:getX() + var_38_0 < arg_38_0:getFighterModel():getWidth() / 2 and var_38_0 < 0 then
			var_38_0 = arg_38_0:getFighterModel():getWidth() / 2 - arg_38_0:getX()
		end

		if not var_0_1.ctx.battle.isUnlimitBattle then
			if arg_38_0:getX() + var_38_0 > var_0_2.STAGE_WIDTH - arg_38_0:getFighterModel():getWidth() / 2 and var_38_0 > 0 then
				var_38_0 = var_0_2.STAGE_WIDTH - arg_38_0:getFighterModel():getWidth() / 2 - arg_38_0:getX()
			end
		elseif arg_38_0:getX() + var_38_0 > var_0_2.UNLIMIT_STAGE_WIDTH - arg_38_0:getFighterModel():getWidth() / 2 and var_38_0 > 0 then
			var_38_0 = var_0_2.UNLIMIT_STAGE_WIDTH - arg_38_0:getFighterModel():getWidth() / 2 - arg_38_0:getX()
		end

		arg_38_0:moveByX(var_38_0, false, true)
		arg_38_0:moveByY(var_38_1, false, true)
	end
end

function var_0_3.addBlackLayer(arg_39_0)
	if var_0_1.ctx.battle.isUnlimitBattle then
		if not arg_39_0.isNotFirstEnergySkill_ then
			arg_39_0.isNotFirstEnergySkill_ = true
		else
			return
		end
	end

	if var_0_1.ctx.battle.isEnergySkilling then
		var_0_1.ctx.battle.isEnergySkilling = var_0_69(var_0_1.ctx.battle.isEnergySkilling, arg_39_0:getEnergySkillPreTime())

		arg_39_0:unsetMaskColor()
		arg_39_0:resume()

		if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
			transition.scaleTo(arg_39_0.fighterModel, {
				time = 0.2,
				scale = 1.1
			})
		end

		arg_39_0.acttionInBlack_ = true

		return
	end

	arg_39_0.acttionInBlack_ = true

	if var_0_2.BattleType.CreateReport ~= var_0_1.ctx.battle.battleType then
		transition.scaleTo(arg_39_0.fighterModel, {
			time = 0.2,
			scale = 1.1
		})
	end

	var_0_1.ctx.battle.stopAllFighter()
	var_0_1.ctx.battle.blackLayer:show()

	var_0_1.ctx.battle.isEnergySkilling = arg_39_0:getEnergySkillPreTime()
end

function var_0_3.clearFunctionsCache(arg_40_0)
	arg_40_0.___isTargetBeyondReach = nil
end

function var_0_3.updateNearestTarget(arg_41_0)
	if arg_41_0:getForceTarget() and not arg_41_0:getForceTarget():isDeath() then
		arg_41_0.nearestTarget_ = arg_41_0:getForceTarget()

		return
	end

	local var_41_0, var_41_1 = arg_41_0.fighterModel:getPosition()
	local var_41_2
	local var_41_3

	for iter_41_0, iter_41_1 in ipairs(arg_41_0.targetTeam_) do
		if not iter_41_1:isDeath() and not iter_41_1:isAffected() and iter_41_1 ~= arg_41_0 then
			local var_41_4, var_41_5 = iter_41_1.fighterModel:getPosition()
			local var_41_6 = var_0_70(var_41_0 - var_41_4)

			if not var_41_2 or var_41_6 < var_41_2 then
				var_41_2 = var_41_6
				var_41_3 = iter_41_1
			end
		end
	end

	arg_41_0.nearestTarget_ = var_41_3
end

function var_0_3.updateLeftInterval(arg_42_0)
	if not arg_42_0:isBattleUnable() then
		arg_42_0.leftInterval_ = arg_42_0.leftInterval_ - 1 * arg_42_0:getCurrentAckSpeed()
	end
end

function var_0_3.updateStateCount(arg_43_0)
	arg_43_0.skillRoll_ = arg_43_0.skillRoll_ and arg_43_0.skillRoll_ - 1 or false
	arg_43_0.preWalk_ = arg_43_0.preWalk_ and arg_43_0.preWalk_ - 1 or false
	arg_43_0.isWalking_ = arg_43_0.isWalking_ and arg_43_0.isWalking_ - 1 or false
	arg_43_0.behindWalk_ = arg_43_0.behindWalk_ and arg_43_0.behindWalk_ - 1 or false
	arg_43_0.isAdjustY_ = arg_43_0.isAdjustY_ and arg_43_0.isAdjustY_ - 1 or false
end

function var_0_3.updateBuffCount(arg_44_0)
	for iter_44_0, iter_44_1 in ipairs(arg_44_0.buffs_) do
		iter_44_1.leftCount_ = iter_44_1.leftCount_ - 1

		if iter_44_1.leftCount_ < 1 or iter_44_1:totalDHarm() > 0 and iter_44_1:getDHarm() <= 0 then
			arg_44_0:removeBuffs(iter_44_1)
		end
	end

	if var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		arg_44_0.fighterModel:updateHeaderViewTime(var_0_1.ctx.battle.count, arg_44_0.showDHarmbuff_)
	end
end

function var_0_3.getFrontSkill(arg_45_0)
	if arg_45_0:isPugongOnly() then
		return arg_45_0:getPugongID()
	end

	if arg_45_0.isEnergySkill_ and arg_45_0:getEnergySkillID() > 0 then
		return arg_45_0:getEnergySkillID()
	end

	if next(arg_45_0.startSkillQueue_) then
		return arg_45_0.startSkillQueue_[1]
	end

	return arg_45_0.skillQueue_[1]
end

function var_0_3.popFrontSkill(arg_46_0)
	if arg_46_0.invalidSkillQueue_ and (not var_0_1.ctx.battle.isActivity or not next(arg_46_0.startSkillQueue_)) then
		if arg_46_0.isEnergySkill_ then
			arg_46_0.isEnergySkill_ = false
		end

		return
	end

	if arg_46_0.isEnergySkill_ then
		arg_46_0.isEnergySkill_ = false
	elseif next(arg_46_0.startSkillQueue_) ~= nil then
		local var_46_0 = arg_46_0.startSkillQueue_[1]

		table.remove(arg_46_0.startSkillQueue_, 1)

		if arg_46_0:getSkillLevelByID(var_46_0) <= 0 then
			arg_46_0:popFrontSkill()
		end
	else
		local var_46_1 = table.remove(arg_46_0.skillQueue_, 1)

		table.insert(arg_46_0.skillQueue_, var_46_1)

		if arg_46_0:getSkillLevelByID(arg_46_0.skillQueue_[1]) <= 0 then
			arg_46_0:popFrontSkill()
		end
	end
end

function var_0_3.popSkillByType(arg_47_0)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		return arg_47_0.reportSkills_[1].rootID_
	end

	if arg_47_0.isEnergySkill_ then
		return arg_47_0:getOrbOfFrontSkill()
	end

	if arg_47_0:isApUnable() or arg_47_0:isAttackFriend() and not arg_47_0:isPossessed() then
		return arg_47_0:popAdSkill()
	elseif arg_47_0:isAdUnable() and not arg_47_0:isExcuteAdCircle() then
		return arg_47_0:popApSkill()
	end

	return arg_47_0:popColorSkill()
end

function var_0_3.skillQueueTest(arg_48_0)
	local var_48_0 = true

	for iter_48_0, iter_48_1 in ipairs(arg_48_0.skillQueue_) do
		if arg_48_0:getSkillLevelByID(iter_48_1) > 0 and arg_48_0:checkActivitySkill(iter_48_1) then
			var_48_0 = false

			break
		end
	end

	if var_48_0 then
		arg_48_0.invalidSkillQueue_ = true
	end
end

function var_0_3.popColorSkill(arg_49_0)
	if var_0_1.ctx.battle.isActivity then
		return arg_49_0:popActivityColorSkill()
	end

	if arg_49_0.invalidSkillQueue_ then
		return arg_49_0:getOrbOfFrontSkill()
	end

	if next(arg_49_0.startSkillQueue_) ~= nil then
		local var_49_0 = arg_49_0.startSkillQueue_[1]

		if arg_49_0:getSkillLevelByID(var_49_0) <= 0 then
			table.remove(arg_49_0.startSkillQueue_, 1)
			arg_49_0:popColorSkill()
		end
	elseif arg_49_0:getSkillLevelByID(arg_49_0.skillQueue_[1]) <= 0 then
		local var_49_1 = table.remove(arg_49_0.skillQueue_, 1)

		table.insert(arg_49_0.skillQueue_, var_49_1)
		arg_49_0:popColorSkill()
	end

	return arg_49_0:getOrbOfFrontSkill()
end

function var_0_3.popAdSkill(arg_50_0)
	local var_50_0 = 0

	local function var_50_1()
		if next(arg_50_0.startSkillQueue_) ~= nil then
			local var_51_0 = arg_50_0.startSkillQueue_[1]

			table.remove(arg_50_0.startSkillQueue_, 1)
		else
			local var_51_1 = table.remove(arg_50_0.skillQueue_, 1)

			table.insert(arg_50_0.skillQueue_, var_51_1)

			var_50_0 = var_50_0 + 1
		end
	end

	local function var_50_2()
		local var_52_0

		if next(arg_50_0.startSkillQueue_) ~= nil then
			var_52_0 = arg_50_0.startSkillQueue_[1]
		else
			var_52_0 = arg_50_0.skillQueue_[1]
		end

		return var_0_12:type(var_52_0)
	end

	local function var_50_3()
		local var_53_0

		if next(arg_50_0.startSkillQueue_) ~= nil then
			var_53_0 = arg_50_0.startSkillQueue_[1]
		else
			var_53_0 = arg_50_0.skillQueue_[1]
		end

		return arg_50_0:getSkillLevelByID(var_53_0)
	end

	while (var_50_2() ~= var_0_2.AttackType.AD or var_50_3() < 1) and var_50_0 <= #arg_50_0.skillQueue_ do
		var_50_1()
	end

	if var_50_0 > #arg_50_0.skillQueue_ then
		return 0
	end

	return arg_50_0:getOrbOfFrontSkill()
end

function var_0_3.popApSkill(arg_54_0)
	local var_54_0 = 0

	local function var_54_1()
		if next(arg_54_0.startSkillQueue_) ~= nil then
			local var_55_0 = arg_54_0.startSkillQueue_[1]

			table.remove(arg_54_0.startSkillQueue_, 1)
		else
			local var_55_1 = table.remove(arg_54_0.skillQueue_, 1)

			table.insert(arg_54_0.skillQueue_, var_55_1)

			var_54_0 = var_54_0 + 1
		end
	end

	local function var_54_2()
		local var_56_0

		if next(arg_54_0.startSkillQueue_) ~= nil then
			var_56_0 = arg_54_0.startSkillQueue_[1]
		else
			var_56_0 = arg_54_0.skillQueue_[1]
		end

		return var_0_12:type(var_56_0)
	end

	local function var_54_3()
		local var_57_0

		if next(arg_54_0.startSkillQueue_) ~= nil then
			var_57_0 = arg_54_0.startSkillQueue_[1]
		else
			var_57_0 = arg_54_0.skillQueue_[1]
		end

		return arg_54_0:getSkillLevelByID(var_57_0)
	end

	while (var_54_2() ~= var_0_2.AttackType.AP and var_54_2() ~= var_0_2.AttackType.CURE or var_54_3() < 1) and var_54_0 <= #arg_54_0.skillQueue_ do
		var_54_1()
	end

	if var_54_0 > #arg_54_0.skillQueue_ then
		return 0
	end

	return arg_54_0:getOrbOfFrontSkill()
end

function var_0_3.skillIsBreak(arg_58_0, arg_58_1)
	arg_58_0:popFrontSkill()

	arg_58_0.manualTargets_ = nil

	arg_58_0:clearUnitSkillAction(arg_58_0.unitSkills_)

	arg_58_0.unitSkills_ = nil

	if arg_58_1 then
		arg_58_1.fighter:skillIsBreakAction(arg_58_1)
	end
end

function var_0_3.skillIsBreakAction(arg_59_0, arg_59_1)
	return
end

function var_0_3.clearUnitSkillAction(arg_60_0, arg_60_1)
	return
end

function var_0_3.getOrbOfFrontSkill(arg_61_0)
	local var_61_0 = arg_61_0:getFrontSkill()

	if arg_61_0.___getFrontSkill and arg_61_0.___getFrontSkill == var_61_0 then
		return arg_61_0.___getOrbOfFrontSkill
	end

	local var_61_1 = var_0_12:orb(var_61_0)

	if var_61_1 > 0 and arg_61_0:getSkillLevelByID(var_61_1) > 0 then
		arg_61_0.___getFrontSkill = var_61_0

		if arg_61_0.hero_.isSkinOn_ and arg_61_0.hero_.isSkinOn_ ~= 0 and var_61_1 ~= arg_61_0:getEnergySkillID() or arg_61_0.isSkinSkillOn_ and var_61_1 ~= arg_61_0:getEnergySkillID() then
			var_61_1 = var_0_12:skinSkill(var_61_1, arg_61_0.skinSkillIndex_)
		end

		arg_61_0.___getOrbOfFrontSkill = var_61_1

		return var_61_1
	end

	arg_61_0.___getFrontSkill = var_61_0

	if arg_61_0.hero_.isSkinOn_ and arg_61_0.hero_.isSkinOn_ ~= 0 or arg_61_0.isSkinSkillOn_ then
		var_61_0 = var_0_12:skinSkill(var_61_0, arg_61_0.skinSkillIndex_)
	end

	arg_61_0.___getOrbOfFrontSkill = var_61_0

	return var_61_0
end

function var_0_3.getSkillLevelByID(arg_62_0, arg_62_1)
	if var_0_1.ctx.battle.isActivity and not arg_62_0:isMainRole() and var_0_12:snowmanUsable(arg_62_1) <= 0 then
		return 0
	end

	local var_62_0 = var_0_12:father(arg_62_1)

	if var_62_0 == arg_62_0.specialAttackSkillID_ then
		return arg_62_0.specialAttackSkillLevel_
	end

	local var_62_1 = arg_62_0.skillLevelByID_[var_62_0]

	if var_62_1 and var_62_1 > 0 then
		for iter_62_0, iter_62_1 in ipairs(arg_62_0.skillDownBuff_) do
			var_62_1 = math.max(1, var_62_1 - math.ceil(iter_62_1:getLevel() / var_0_15:skillDownReq(iter_62_1:getTableID())))
		end
	end

	return var_62_1 or 0
end

function var_0_3.getFrontSkillDistance(arg_63_0)
	return var_0_12:distance(arg_63_0:getOrbOfFrontSkill())
end

function var_0_3.isTargetBeyondReach(arg_64_0)
	if var_0_1.ctx.battle.isActivity and not arg_64_0:isMainRole() then
		return false
	end

	if arg_64_0.___isTargetBeyondReach then
		return arg_64_0.___isTargetBeyondReach
	end

	local var_64_0 = arg_64_0:getNearestTarget()

	if not var_64_0 or arg_64_0:getFrontSkillDistance() <= 0 then
		arg_64_0.___isTargetBeyondReach = false

		return false
	end

	arg_64_0.___isTargetBeyondReach = var_0_70(var_64_0:getX() - arg_64_0:getX()) > arg_64_0:getFrontSkillDistance()

	return arg_64_0.___isTargetBeyondReach
end

function var_0_3.checkSkillRoll(arg_65_0)
	if arg_65_0.skillRoll_ and arg_65_0.skillRoll_ <= 0 then
		arg_65_0.skillRoll_ = false
		arg_65_0.isWalking_ = false
		arg_65_0.preWalk_ = false
		arg_65_0.behindWalk_ = false
		arg_65_0.isAdjustY_ = false
	end

	return (arg_65_0.skillRoll_ or 0) > 0
end

function var_0_3.isInSkillRoll(arg_66_0)
	return (arg_66_0.skillRoll_ or 0) > 0
end

function var_0_3.isWalking(arg_67_0)
	if not arg_67_0.preWalk_ then
		return false
	end

	local var_67_0 = 0

	if (arg_67_0.preWalk_ or 0) > 0 then
		var_67_0 = 1
	elseif (arg_67_0.isWalking_ or 0) > 0 then
		var_67_0 = 2
	elseif (arg_67_0.behindWalk_ or 0) > 0 then
		var_67_0 = 3
	end

	return var_67_0
end

function var_0_3.writeWalkState(arg_68_0)
	if not arg_68_0:isWalking() then
		return
	end

	arg_68_0.records_.walk_state[tostring(var_0_1.ctx.battle.count)] = arg_68_0:isWalking()
end

function var_0_3.isAdjustY(arg_69_0)
	return var_0_1.ctx.battle.count < (arg_69_0.isAdjustY_ or 0)
end

function var_0_3.isCreatingUnits(arg_70_0)
	if not arg_70_0.unitSkills_ or arg_70_0.unitSkills_:isEmptyQueue() then
		return false
	end

	return true
end

function var_0_3.isCreatingSpecialUnits(arg_71_0)
	if not arg_71_0.specialSkills_ or arg_71_0.specialSkills_:isEmptyQueue() then
		return false
	end

	return true
end

function var_0_3.isImmortal(arg_72_0, arg_72_1)
	if arg_72_0.isImmortal_ then
		return true
	end

	if arg_72_1 == var_0_2.AttackType.AD then
		return arg_72_0:isAdImmortal()
	elseif arg_72_1 == var_0_2.AttackType.AP then
		return arg_72_0:isApImmortal()
	end
end

function var_0_3.isIgnoreImmortal(arg_73_0, arg_73_1)
	local var_73_0 = arg_73_1.skillID
	local var_73_1 = arg_73_1.target
	local var_73_2 = arg_73_1.attackType

	if var_73_1.isImmortal_ then
		return false
	end

	local var_73_3 = var_0_12:ignoreImmortal(var_73_0)

	if var_73_2 == var_0_2.AttackType.AD and var_73_3 == var_0_2.IgnoreImmortalType.AD then
		return true
	elseif var_73_2 == var_0_2.AttackType.AP and var_73_3 == var_0_2.IgnoreImmortalType.AP then
		return true
	end

	return false
end

function var_0_3.isBattleUnable(arg_74_0)
	return arg_74_0:isAdUnable() and arg_74_0:isApUnable()
end

function var_0_3.isMoveUnable(arg_75_0)
	if next(arg_75_0.buffMovePath_) or not var_0_13:canMove(arg_75_0:getTableID()) then
		return true
	end

	return next(arg_75_0.moveUnableBuffs_) ~= nil
end

function var_0_3.isFear(arg_76_0)
	return next(arg_76_0.fearBuffs_) ~= nil
end

function var_0_3.isAdUnable(arg_77_0)
	return next(arg_77_0.adUnableBuffs_) ~= nil
end

function var_0_3.isApUnable(arg_78_0)
	return next(arg_78_0.apUnableBuffs_) ~= nil
end

function var_0_3.isPugongOnly(arg_79_0)
	return next(arg_79_0.pugongOnlyBuffs_) ~= nil
end

function var_0_3.isExcuteAdCircle(arg_80_0)
	return next(arg_80_0.excuteAdCircle_) ~= nil
end

function var_0_3.isExcuteApCircle(arg_81_0)
	return next(arg_81_0.excuteApCircle_) ~= nil
end

function var_0_3.isAttackFriend(arg_82_0)
	return next(arg_82_0.ackFriendsBuffs_) ~= nil
end

function var_0_3.isAdBreakImmortal(arg_83_0)
	return next(arg_83_0.adBreakImmortalBuffs_) ~= nil
end

function var_0_3.isBreakImmortal(arg_84_0)
	return arg_84_0.isImmuneControl or next(arg_84_0.immuneControlBuffs_) ~= nil
end

function var_0_3.isBuffMove(arg_85_0)
	return next(arg_85_0.moveBuffs_) ~= nil
end

function var_0_3.isApImmortal(arg_86_0)
	return arg_86_0.isAPImmortal_ or next(arg_86_0.apImmortalBuffs_) ~= nil
end

function var_0_3.isAdImmortal(arg_87_0)
	return arg_87_0.isADImmortal_ or next(arg_87_0.adImmortalBuffs_) ~= nil
end

function var_0_3.isAffected(arg_88_0)
	if var_0_1.ctx.battle.isActivity and not arg_88_0:isMainRole() then
		return true
	end

	return next(arg_88_0.isAffectedBuffs_) ~= nil or arg_88_0:isInvisible()
end

function var_0_3.isTeamAffected(arg_89_0)
	return next(arg_89_0.isTeamAffectedBuffs_) ~= nil
end

function var_0_3.isInvisible(arg_90_0)
	return next(arg_90_0.isAffectedBuffs_) == nil and next(arg_90_0.isInvisibleBuffs_) ~= nil
end

function var_0_3.isPause(arg_91_0)
	return next(arg_91_0.pauseBuffs_) ~= nil
end

function var_0_3.isSleep(arg_92_0)
	return next(arg_92_0.sleepBuffs_) ~= nil
end

function var_0_3.isShield(arg_93_0)
	return next(arg_93_0.shieldBuffs_) ~= nil
end

function var_0_3.isDHarm(arg_94_0)
	return next(arg_94_0.dHarmBuffs_) ~= nil
end

function var_0_3.isNeverDie(arg_95_0)
	return next(arg_95_0.neverDieBuffs_) ~= nil
end

function var_0_3.isChaos(arg_96_0)
	return next(arg_96_0.isChaos_) ~= nil
end

function var_0_3.isEnergyLimit(arg_97_0)
	return arg_97_0.energyLimit_ < 1
end

function var_0_3.isForverNeverDie(arg_98_0)
	if arg_98_0:getSummonType() ~= var_0_2.summonMonsterType.None then
		return false
	end

	return next(arg_98_0.forverNeverDieBuffs_) ~= nil
end

function var_0_3.isPossessed(arg_99_0)
	return next(arg_99_0.possessBuffs_) ~= nil
end

function var_0_3.isSpGive(arg_100_0)
	return next(arg_100_0.spGiveBuffs_) ~= nil
end

function var_0_3.isSkillDown(arg_101_0)
	return next(arg_101_0.skillDownBuff_) ~= nil
end

function var_0_3.limitAttr(arg_102_0)
	return next(arg_102_0.limitAttrBuff_) ~= nil
end

function var_0_3.isUseSkillCount(arg_103_0)
	return next(arg_103_0.useSkillCount_) ~= nil
end

function var_0_3.isIgnoreJianshang(arg_104_0)
	return next(arg_104_0.ignoreJianshang_) ~= nil
end

function var_0_3.isIgnoreShield(arg_105_0)
	return next(arg_105_0.ignoreShield_) ~= nil
end

function var_0_3.isInvalidMpIncrease(arg_106_0)
	return next(arg_106_0.invalidMpIncreaseBuffs_) ~= nil
end

function var_0_3.isInvalidEnergySkill(arg_107_0)
	return next(arg_107_0.invalidEnergySkillBuffs_) ~= nil
end

function var_0_3.getForceTarget(arg_108_0)
	if arg_108_0.forceTargetBuffs_[1] then
		return arg_108_0.forceTargetBuffs_[1]:getForceTarget()
	end
end

function var_0_3.heroWakeup(arg_109_0)
	if next(arg_109_0.sleepBuffs_) ~= nil then
		for iter_109_0 = #arg_109_0.sleepBuffs_, 1, -1 do
			arg_109_0:removeBuffs(arg_109_0.sleepBuffs_[iter_109_0])
		end
	end
end

function var_0_3.modelWalk(arg_110_0)
	if var_0_1.ctx.battle.infoListener.action_info then
		local var_110_0 = {
			fighter = arg_110_0,
			action_type = var_0_2.ActionType.walk
		}

		table.insert(var_0_1.ctx.battle.infoListener.action_info, var_110_0)
	end

	if arg_110_0.fighterModel:getScale() ~= 1 then
		arg_110_0.fighterModel:scale(1)
	end

	arg_110_0:getFighterModel():walk(true)
end

function var_0_3.playAttack(arg_111_0, arg_111_1, arg_111_2)
	if not arg_111_1 then
		return
	end

	if var_0_1.ctx.battle.infoListener.action_info then
		local var_111_0 = {
			fighter = arg_111_0,
			action_type = var_0_2.ActionType.attack
		}

		table.insert(var_0_1.ctx.battle.infoListener.action_info, var_111_0)
	end

	arg_111_0.skillRoll_ = var_0_14:duration(arg_111_0:getModelID(), arg_111_1)

	arg_111_0:getFighterModel():attack(arg_111_1, nil, nil, function()
		if arg_111_2 then
			arg_111_2()
		end

		if arg_111_0.fighterModel:getScale() ~= 1 then
			arg_111_0.fighterModel:scale(1)
		end

		if arg_111_0:getFighterModel().currentAnimation_ == string.format("gongji%02d", arg_111_1) then
			arg_111_0:resumeIdle()
		end
	end)
end

function var_0_3.attacked(arg_113_0)
	if arg_113_0:getFighterModel().currentAnimation_ and arg_113_0:getFighterModel().currentAnimation_ == "hurt" then
		return
	end

	if arg_113_0.fighterModel:getScale() ~= 1 then
		arg_113_0.fighterModel:scale(1)
	end

	local var_113_0 = var_0_14:hurtDuration(arg_113_0:getModelID())

	arg_113_0.skillRoll_ = var_113_0
	arg_113_0.unableEnergySkill_ = var_0_1.ctx.battle.count + var_113_0

	arg_113_0:getFighterModel():attacked(function()
		if arg_113_0:getFighterModel().currentAnimation_ == "hurt" then
			arg_113_0:resumeIdle()
		end
	end)
end

function var_0_3.summon(arg_115_0)
	if not arg_115_0:getFighterModel():hasAnimation("summon") then
		arg_115_0:resumeIdle()

		return
	end

	arg_115_0.skillRoll_ = var_0_14:summonDuration(arg_115_0:getModelID())

	arg_115_0:getFighterModel():summon(function()
		if arg_115_0:getFighterModel().currentAnimation_ == "summon" then
			arg_115_0:resumeIdle()
		end
	end)
end

function var_0_3.resumeIdle(arg_117_0)
	if not arg_117_0:isDeath() and arg_117_0:getFighterModel() then
		arg_117_0:getFighterModel():idle()
	end
end

function var_0_3.setTimeScale(arg_118_0, arg_118_1)
	arg_118_0.timeScale_ = arg_118_1

	if arg_118_1 and arg_118_1 > 0 then
		arg_118_0:getFighterModel():setTimeScale(arg_118_1)
	end
end

function var_0_3.isWalkAnimation(arg_119_0)
	local var_119_0 = arg_119_0:getFighterModel()

	if not var_119_0.currentAnimation_ then
		return false
	end

	if string.sub(var_119_0.currentAnimation_, 1, 3) == "run" then
		return true
	else
		return false
	end
end

function var_0_3.getCurrentAnimation(arg_120_0)
	return arg_120_0:getFighterModel().currentAnimation_
end

function var_0_3.resetLeftInterval(arg_121_0)
	arg_121_0.leftInterval_ = arg_121_0:getInterval()
end

function var_0_3.setBreakInterval(arg_122_0)
	local var_122_0 = var_0_14:hurtDuration(arg_122_0:getModelID())

	arg_122_0.leftInterval_ = var_0_69(arg_122_0.leftInterval_, 0)
	arg_122_0.leftInterval_ = var_0_68(arg_122_0.leftInterval_ + var_122_0, arg_122_0:getInterval())
end

function var_0_3.initHp(arg_123_0)
	arg_123_0:setupHpLimit()

	arg_123_0.hp_ = arg_123_0:getHpLimit()
end

function var_0_3.updateHp(arg_124_0, arg_124_1, arg_124_2)
	if not arg_124_1 then
		return
	end

	local var_124_0 = arg_124_0:updateSpecialHP(arg_124_1)
	local var_124_1 = arg_124_0:getHp()

	if var_124_0 < var_124_1 then
		arg_124_0.hurtHp = arg_124_0.hurtHp + var_124_1 - var_124_0
	end

	if arg_124_0.isParalysis then
		return
	end

	if var_124_0 < 0 then
		arg_124_0.overflowHarm_ = -var_124_0
	end

	arg_124_0:setHp(var_124_0)

	if arg_124_2 ~= false then
		arg_124_2 = true
	end

	arg_124_0:updateHpBar(arg_124_2)
end

function var_0_3.forceUpdateHp(arg_125_0, arg_125_1)
	arg_125_0:setHp(arg_125_1)
	arg_125_0:updateHpBar(true)
end

function var_0_3.updateHpBar(arg_126_0, arg_126_1)
	if arg_126_0.hpBar_ and arg_126_0.avatarIndex_ then
		arg_126_0.bottomWnd:setHPProgress(arg_126_0:getHp() / arg_126_0:getHpLimit(), arg_126_0.avatarIndex_, arg_126_1)
	end

	local var_126_0 = arg_126_0:getHp() / arg_126_0:getHpLimit()

	arg_126_0.fighterModel:setHPProgress(var_126_0, arg_126_1, nil, var_0_1.ctx.battle.count)
	arg_126_0.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, arg_126_0.showDHarmbuff_)
end

function var_0_3.updateSpecialHP(arg_127_0, arg_127_1)
	if arg_127_0:isForverNeverDie() and arg_127_0.minHpPercentValue > 0 then
		local var_127_0 = arg_127_1 / arg_127_0:getHpLimit()
		local var_127_1 = arg_127_0:getHp()

		if var_127_0 < arg_127_0.minHpPercentValue then
			if var_127_1 < arg_127_1 then
				arg_127_1 = var_127_1
			else
				arg_127_1 = arg_127_0.minHpPercentValue * arg_127_0:getHpLimit()
			end
		end
	end

	return arg_127_1
end

function var_0_3.setMinHpValue(arg_128_0, arg_128_1, arg_128_2)
	if arg_128_1 > arg_128_0.minHpPercentValue or arg_128_2 then
		arg_128_0.minHpPercentValue = arg_128_1
	end
end

function var_0_3.setHp(arg_129_0, arg_129_1)
	arg_129_0.hp_ = var_0_68(arg_129_1, arg_129_0:getHpLimit())
	arg_129_0.hp_ = var_0_69(arg_129_0.hp_, 0)
end

function var_0_3.updateEnergyTo(arg_130_0, arg_130_1)
	if arg_130_0:isInvalidMpIncrease() and arg_130_1 > arg_130_0:getEnergy() then
		return
	end

	if arg_130_0:isPossessed() and arg_130_1 > arg_130_0.energy_ then
		for iter_130_0, iter_130_1 in ipairs(arg_130_0.possessBuffs_) do
			if iter_130_1.fighter and not iter_130_1.fighter:isDeath() and not iter_130_1.fighter:isPossessed() then
				iter_130_1.fighter:updateEnergyBy(arg_130_1 - arg_130_0.energy_)
			end
		end

		return
	elseif arg_130_0:isSpGive() and arg_130_1 > arg_130_0.energy_ then
		for iter_130_2, iter_130_3 in ipairs(arg_130_0.spGiveBuffs_) do
			if iter_130_3.fighter and not iter_130_3.fighter:isDeath() and not iter_130_3.fighter:isSpGive() and not iter_130_3.fighter:isPossessed() then
				local var_130_0 = (arg_130_1 - arg_130_0.energy_) * iter_130_3:spGiveRate()
				local var_130_1 = iter_130_3.fighter:checkSpGive(iter_130_3, var_130_0)

				if not iter_130_3:isSpReduce() and iter_130_3.fighter:spGiveIsSelf(iter_130_3, var_130_1) then
					iter_130_3.fighter:updateEnergyBy(var_130_1)
				end

				iter_130_3.fighter:spGiveValue(iter_130_3, var_130_1)

				arg_130_1 = arg_130_1 - var_130_1
			end
		end
	end

	local var_130_2 = arg_130_1 or 0
	local var_130_3 = var_0_69(var_130_2, 0)
	local var_130_4 = var_0_68(var_130_3, var_0_2.ENERGY_DECIMAL_BASE)

	if arg_130_0:isEnergyLimit() and arg_130_1 > arg_130_0.energy_ then
		local var_130_5 = arg_130_0.energyLimit_ * arg_130_0:energyDecimalBase()

		if var_130_5 < arg_130_0.energy_ and var_130_5 < var_130_4 then
			return
		end

		var_130_4 = var_0_68(var_130_4, var_130_5)
	end

	arg_130_0.energy_ = var_130_4

	arg_130_0:updateEnergyBar()
end

function var_0_3.updateEnergyBy(arg_131_0, arg_131_1, arg_131_2)
	if arg_131_0:isInvalidMpIncrease() and arg_131_1 > 0 then
		return
	end

	if arg_131_0:isPossessed() and arg_131_1 > 0 then
		for iter_131_0, iter_131_1 in ipairs(arg_131_0.possessBuffs_) do
			if iter_131_1.fighter and not iter_131_1.fighter:isDeath() and not iter_131_1.fighter:isPossessed() then
				iter_131_1.fighter:updateEnergyBy(arg_131_1)
			end
		end

		return
	elseif arg_131_0:isSpGive() and arg_131_1 > 0 then
		for iter_131_2, iter_131_3 in ipairs(arg_131_0.spGiveBuffs_) do
			if iter_131_3.fighter and not iter_131_3.fighter:isDeath() and not iter_131_3.fighter:isSpGive() and not iter_131_3.fighter:isPossessed() then
				local var_131_0 = arg_131_1 * iter_131_3:spGiveRate()
				local var_131_1 = iter_131_3.fighter:checkSpGive(iter_131_3, var_131_0)

				if not iter_131_3:isSpReduce() and iter_131_3.fighter:spGiveIsSelf(iter_131_3, var_131_1) then
					iter_131_3.fighter:updateEnergyBy(var_131_1)
				end

				iter_131_3.fighter:spGiveValue(iter_131_3, var_131_1)

				arg_131_1 = arg_131_1 - var_131_1
			end
		end
	end

	if arg_131_0:isEnergyLimit() and arg_131_1 > 0 and arg_131_0.energyLimit_ * arg_131_0:energyDecimalBase() < arg_131_0.energy_ then
		return
	end

	local var_131_2 = (arg_131_1 or 0) + arg_131_0.energy_
	local var_131_3 = var_0_69(var_131_2, 0)
	local var_131_4 = var_0_68(var_131_3, var_0_2.ENERGY_DECIMAL_BASE)

	if arg_131_0:isEnergyLimit() and arg_131_1 > 0 then
		local var_131_5 = arg_131_0.energyLimit_ * arg_131_0:energyDecimalBase()

		var_131_4 = var_0_68(var_131_4, var_131_5)
	end

	local var_131_6 = arg_131_0.energy_

	arg_131_0.energy_ = var_131_4

	if arg_131_0.energy_ >= var_0_2.ENERGY_DECIMAL_BASE and var_131_6 < var_0_2.ENERGY_DECIMAL_BASE then
		var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.sound:getSound("battle_energy_full"))
	end

	arg_131_0:updateEnergyBar(arg_131_2)
end

function var_0_3.spGiveValue(arg_132_0, arg_132_1, arg_132_2)
	return
end

function var_0_3.checkSpGive(arg_133_0, arg_133_1, arg_133_2)
	return arg_133_2
end

function var_0_3.spGiveIsSelf(arg_134_0, arg_134_1, arg_134_2)
	return true
end

function var_0_3.updateEnergyByHarm(arg_135_0, arg_135_1)
	if arg_135_0:isInvalidMpIncrease() then
		return
	end

	local var_135_0 = arg_135_1 / arg_135_0:getHpLimit() * arg_135_0:getHurtMP() / var_0_2.DECIMAL_BASE * var_0_2.ENERGY_DECIMAL_BASE * arg_135_0:getAttackedReEnergy()
	local var_135_1 = arg_135_0.energy_

	if arg_135_0:isPossessed() and var_135_0 > 0 then
		for iter_135_0, iter_135_1 in ipairs(arg_135_0.possessBuffs_) do
			if iter_135_1.fighter and not iter_135_1.fighter:isDeath() then
				iter_135_1.fighter:updateEnergyBy(var_135_0)
			end
		end

		return
	elseif arg_135_0:isSpGive() and var_135_0 > 0 then
		for iter_135_2, iter_135_3 in ipairs(arg_135_0.spGiveBuffs_) do
			if iter_135_3.fighter and not iter_135_3.fighter:isDeath() and not iter_135_3.fighter:isSpGive() then
				local var_135_2 = var_135_0 * iter_135_3:spGiveRate()
				local var_135_3 = iter_135_3.fighter:checkSpGive(iter_135_3, var_135_2)

				if not iter_135_3:isSpReduce() and iter_135_3.fighter:spGiveIsSelf(iter_135_3, var_135_3) then
					iter_135_3.fighter:updateEnergyBy(var_135_3)
				end

				iter_135_3.fighter:spGiveValue(iter_135_3, var_135_3)

				var_135_0 = var_135_0 - var_135_3
			end
		end
	end

	if arg_135_0:isEnergyLimit() and arg_135_0.energyLimit_ * arg_135_0:energyDecimalBase() < arg_135_0.energy_ then
		return
	end

	local var_135_4 = var_0_68(arg_135_0.energy_ + var_135_0, var_0_2.ENERGY_DECIMAL_BASE)

	if arg_135_0:isEnergyLimit() then
		local var_135_5 = arg_135_0.energyLimit_ * arg_135_0:energyDecimalBase()

		var_135_4 = var_0_68(arg_135_0.energy_ + var_135_0, var_135_5)
	end

	arg_135_0.energy_ = var_135_4

	if arg_135_0.energy_ >= var_0_2.ENERGY_DECIMAL_BASE then
		if var_135_1 < var_0_2.ENERGY_DECIMAL_BASE then
			var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.sound:getSound("battle_energy_full"))
		end

		if var_0_2.CampaignType.ARENA == var_0_1.ctx.battle.campaignType or var_0_2.CampaignType.SUPER_ARENA == var_0_1.ctx.battle.campaignType then
			arg_135_0.arenaEnergyFull_ = true
		end
	end

	arg_135_0:updateEnergyBar()
end

function var_0_3.updateEnergyBar(arg_136_0, arg_136_1)
	if arg_136_0.mpBar_ then
		if arg_136_0.avatarIndex_ then
			arg_136_0.bottomWnd:setMPProgress(arg_136_0.energy_ / var_0_2.ENERGY_DECIMAL_BASE, arg_136_0.avatarIndex_, arg_136_1)
		else
			arg_136_0.bottomWnd:setPetMPProgress(arg_136_0.energy_ / var_0_2.ENERGY_DECIMAL_BASE, false)
		end
	end
end

function var_0_3.energyAction(arg_137_0, arg_137_1)
	if var_0_12:father(arg_137_1) == arg_137_0:getEnergySkillID() then
		arg_137_0:getFighterModel():playEnergyEffect_()
		arg_137_0:updateEnergyTo(arg_137_0:getDMP() / var_0_2.PERCENT_BASE * var_0_2.ENERGY_DECIMAL_BASE)

		for iter_137_0, iter_137_1 in ipairs(arg_137_0.selfTeam_) do
			if not iter_137_1:isDeath() then
				iter_137_1:energyActionBySpecialHero(arg_137_0, arg_137_1)
			end
		end

		for iter_137_2, iter_137_3 in ipairs(arg_137_0.sideTeam_) do
			if not iter_137_3:isDeath() then
				iter_137_3:energyActionBySpecialHero(arg_137_0, arg_137_1)
			end
		end

		if arg_137_0:getTeamType() == var_0_2.TeamType.A or arg_137_0.isInArena_ or arg_137_0:isMainRole() then
			arg_137_0:addBlackLayer()
		end
	end
end

function var_0_3.createUnits(arg_138_0, arg_138_1)
	local var_138_0 = arg_138_1 or arg_138_0.unitSkills_
	local var_138_1, var_138_2 = var_138_0:getFront()
	local var_138_3 = var_0_12:father(var_138_2)
	local var_138_4 = var_0_12:speed(var_138_2)
	local var_138_5 = var_0_12:selectType(var_138_2)
	local var_138_6 = {}

	if string.find(var_138_5, "C") then
		local var_138_7 = 250

		if var_0_1.ctx.battle.isUnlimitBattle then
			var_138_7 = 416.6666666666667
		end

		local var_138_8

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_138_8 = var_138_0.reportData_[1].unit
		else
			var_138_8 = arg_138_0:createToPosUnit(var_138_2)
		end

		table.insert(arg_138_0.moveUnits_, var_138_8)

		if var_138_8.resource then
			var_138_8.resource:addTo(var_0_1.ctx.battle.unitLayer)
			var_138_8.resource:pos(var_138_8:getIniPos())
			var_138_8.resource:playRepeat()
			var_138_8:rotate()
		end

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_138_6 = var_0_1.ctx.battle.getFighters(var_138_0.reportData_[1].targets)
		else
			var_138_6 = arg_138_0:getTargets(var_138_2, var_138_8)
		end

		if var_138_4 == 0 or var_138_5 ~= "C11" and var_138_5 ~= "C29" then
			if #var_138_6 > 1 and var_138_8.unitEffectType == var_0_2.UnitEffectType.TargetsCenter then
				local var_138_9 = var_138_6[1]:getX()
				local var_138_10 = var_138_6[1]:getX()

				for iter_138_0, iter_138_1 in ipairs(var_138_6) do
					var_138_10 = var_138_10 < iter_138_1:getX() and iter_138_1:getX() or var_138_10
					var_138_9 = var_138_9 > iter_138_1:getX() and iter_138_1:getX() or var_138_9
				end

				var_138_8:setDesition(var_138_9 / 2 + var_138_10 / 2, var_138_7)
			elseif var_138_6[1] and var_138_8.unitEffectType == var_0_2.UnitEffectType.TargetFootPos then
				var_138_8:setDesition(var_138_6[1]:getX(), var_138_6[1]:getY())
			elseif next(var_138_6) and var_138_5 ~= "C21" then
				var_138_8:setDesition(var_138_6[1]:getX(), var_138_7)
			else
				var_138_8:setDesition(nil, var_138_7)
			end

			if next(var_138_6) and var_138_5 ~= "C21" then
				var_138_8.manualTargets_ = var_138_6
			end
		end

		if #var_0_12:areaPosition(var_138_2) > 1 then
			var_138_8:setDesition(unpack(var_0_12:areaPosition(var_138_2)))
		end

		if arg_138_0.manualPosition_ then
			var_138_8.manualTargets_ = arg_138_0.manualTargets_

			if var_138_8.unitEffectType ~= var_0_2.UnitEffectType.TargetFootPos then
				var_138_8:setDesition(arg_138_0.manualPosition_[1], var_138_7)
			end
		elseif arg_138_0.manualTargets_ then
			var_138_8.manualTargets_ = arg_138_0.manualTargets_

			if var_138_8.unitEffectType ~= var_0_2.UnitEffectType.TargetFootPos then
				var_138_8:setDesition(var_138_8.manualTargets_[1]:getX(), var_138_7)
			else
				var_138_8:setDesition(var_138_8.manualTargets_[1]:getX(), var_138_8.manualTargets_[1]:getY())
			end
		end

		if var_138_4 == 0 and var_138_8.unitEffectType ~= var_0_2.UnitEffectType.FollowFighter then
			var_138_8.arrived = true

			if var_138_8.resource then
				var_138_8.resource:pos(var_138_8.desX_, var_138_8.desY_)
			end
		end

		arg_138_0.manualTargets_ = nil
		arg_138_0.manualPosition_ = nil
		arg_138_0.manualDirection_ = nil

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			var_138_0:record_1(var_138_6, var_138_8)
		else
			var_138_8:setDesition(var_138_0.reportData_[1].pos.x, var_138_0.reportData_[1].pos.y)
		end

		arg_138_0:unitAfterCreate(var_138_8)

		return
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_138_6 = var_0_1.ctx.battle.getFighters(var_138_0.reportData_[1].targets)
	elseif arg_138_0.manualTargets_ and not arg_138_0.manualPosition_ then
		var_138_6 = arg_138_0.manualTargets_

		if not var_0_12:isFixedTarget(var_138_3) or var_138_0:lastQueue() then
			arg_138_0.manualTargets_ = nil
		end
	else
		var_138_6 = arg_138_0:getTargets(var_138_2)

		if var_0_12:isFixedTarget(var_138_3) and var_138_0:lastQueue() ~= true then
			arg_138_0.manualTargets_ = var_138_6
		end
	end

	local var_138_11

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_138_11 = var_138_0.reportData_[1].units
	else
		var_138_11 = arg_138_0:createAttackUnits(var_138_6, var_138_2)
	end

	arg_138_0.manualDirection_ = nil

	if arg_138_0.manualPosition_ then
		for iter_138_2, iter_138_3 in ipairs(var_138_11) do
			iter_138_3.manualPosition_ = var_0_0.clone(arg_138_0.manualPosition_)
		end

		arg_138_0.manualPosition_ = nil
	end

	if var_138_4 > 0 then
		for iter_138_4, iter_138_5 in ipairs(var_138_11) do
			table.insert(arg_138_0.moveAttackUnits_, iter_138_5)

			if iter_138_5.resource then
				iter_138_5.resource:pos(iter_138_5:getIniPos())
				iter_138_5:rotate()
				iter_138_5:movePosition()
				iter_138_5.resource:addTo(var_0_1.ctx.battle.unitLayer)
				iter_138_5.resource:playRepeat()
			end
		end
	else
		for iter_138_6, iter_138_7 in ipairs(var_138_11) do
			iter_138_7.arrived = true

			table.insert(arg_138_0.moveAttackUnits_, iter_138_7)
		end
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		var_138_0:record_2(var_138_6, var_138_11)
	end

	arg_138_0:unitAfterCreate(nil, var_138_11)
end

function var_0_3.unitAfterCreate(arg_139_0, arg_139_1, arg_139_2)
	return
end

function var_0_3.getTargets(arg_140_0, arg_140_1, arg_140_2)
	local var_140_0 = {}
	local var_140_1 = var_0_12:selectType(arg_140_1)

	if arg_140_0:getForceTarget() and not arg_140_0:getForceTarget():isDeath() and var_0_12:father(arg_140_1) == arg_140_0:getPugongID() then
		if var_140_1 == "C11" then
			local var_140_2 = arg_140_0:getForceTarget()

			if (arg_140_2.iniX_ < var_140_2:getX() and var_140_2:getX() <= arg_140_2:getX() or arg_140_2.iniX_ > var_140_2:getX() and var_140_2:getX() >= arg_140_2:getX()) and not arg_140_2.targets[var_140_2.fighterIndex] then
				arg_140_2.targets[var_140_2.fighterIndex] = var_140_2

				return {
					var_140_2
				}
			end

			return {}
		end

		return {
			arg_140_0:getForceTarget()
		}
	end

	if arg_140_0:isChaos() then
		arg_140_0:changeTeamCache()
	end

	if arg_140_0["selectTargetByType" .. var_140_1] then
		var_140_0 = arg_140_0["selectTargetByType" .. var_140_1](arg_140_0, arg_140_1, arg_140_2)
	else
		if not var_140_1 then
			print("invallid select type skillID = " .. arg_140_1)
		end

		var_140_0 = var_0_11[var_140_1](arg_140_0, arg_140_1, arg_140_2)
	end

	return var_140_0
end

function var_0_3.createAttackUnits(arg_141_0, arg_141_1, arg_141_2)
	local function var_141_0(arg_142_0)
		local var_142_0 = {
			skillID = arg_141_2,
			fighter = arg_141_0,
			target = arg_142_0,
			count = var_0_1.ctx.battle.count
		}

		return var_0_7.new(var_142_0)
	end

	if arg_141_1 == nil or next(arg_141_1) == nil or not arg_141_2 or arg_141_2 == 0 then
		return {}
	end

	if #arg_141_0.records_.attackunit >= var_0_23 then
		arg_141_0:attackUnitErrorLog(arg_141_2)

		return {}
	end

	if #arg_141_0.records_.attackunit >= var_0_23 then
		arg_141_0:attackUnitErrorLog(arg_141_2)

		return {}
	end

	local var_141_1 = {}

	for iter_141_0, iter_141_1 in ipairs(arg_141_1) do
		local var_141_2 = var_141_0(iter_141_1)

		table.insert(arg_141_0.records_.attackunit, var_141_2)
		table.insert(var_141_1, var_141_2)

		var_141_2.recordIndex_ = #arg_141_0.records_.attackunit
	end

	return var_141_1
end

function var_0_3.createToPosUnit(arg_143_0, arg_143_1)
	local var_143_0 = {
		skillID = arg_143_1,
		count = var_0_0.clone(var_0_1.ctx.battle.count),
		fighter = arg_143_0
	}
	local var_143_1 = var_0_6.new(var_143_0)

	table.insert(arg_143_0.records_.moveunit, var_143_1)

	var_143_1.recordIndex_ = #arg_143_0.records_.moveunit

	return var_143_1
end

function var_0_3.applySingleUnit(arg_144_0, arg_144_1)
	if var_0_1.ctx.battle.infoListener.unit_info then
		table.insert(var_0_1.ctx.battle.infoListener.unit_info, arg_144_1)
	end

	local var_144_0 = false

	if arg_144_1.target:isDeath() then
		return
	end

	local var_144_1, var_144_2, var_144_3, var_144_4, var_144_5, var_144_6 = arg_144_0:getUnitData(arg_144_1)

	for iter_144_0, iter_144_1 in ipairs(arg_144_0.selfTeam_) do
		if not iter_144_1:isDeath() then
			iter_144_1:updateUnitInfoBySpecialHero(arg_144_1, var_144_1, var_144_2, var_144_3, var_144_4, var_144_5, var_144_6)
		end
	end

	for iter_144_2, iter_144_3 in ipairs(arg_144_0.sideTeam_) do
		if not iter_144_3:isDeath() then
			iter_144_3:updateUnitInfoBySpecialHero(arg_144_1, var_144_1, var_144_2, var_144_3, var_144_4, var_144_5, var_144_6)
		end
	end

	local var_144_7 = arg_144_1.target

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType and arg_144_1.reportData_.doge then
		var_144_7:dodge(arg_144_1, var_144_1, var_144_2, var_144_3, var_144_4, var_144_5, var_144_6)

		return
	elseif var_144_7:dodge(arg_144_1, var_144_1, var_144_2, var_144_3, var_144_4, var_144_5, var_144_6) then
		return
	end

	if var_144_1 then
		if var_0_1.ctx.battle.infoListener.shanbi_info then
			table.insert(var_0_1.ctx.battle.infoListener.shanbi_info, arg_144_1)
		end

		var_144_7:playShanbi(arg_144_1)

		return
	end

	if var_144_2 and var_0_12:type(arg_144_1.skillID) == var_0_2.AttackType.AP and var_0_1.ctx.battle.infoListener.magic_crit_info then
		table.insert(var_0_1.ctx.battle.infoListener.magic_crit_info, {
			arg_144_1,
			var_144_3
		})
	end

	if var_144_2 and var_0_1.ctx.battle.infoListener.crit_info then
		local var_144_8 = {
			unit = arg_144_1,
			harm = var_144_3
		}

		table.insert(var_0_1.ctx.battle.infoListener.crit_info, var_144_8)
	end

	if not var_0_12:ignoreDefence(arg_144_1.skillID) then
		var_144_7:setOriHurt(var_144_3)
	end

	var_0_1.ctx.battle.pushSoundQueue(arg_144_1:getHitSound())

	if var_144_6 ~= 0 then
		var_144_7:updateEnergyBy(var_144_6)
		var_144_7.fighterModel:playEnergyFloat(var_144_6)
	end

	if var_144_3 ~= 0 and var_144_7:isSleep() then
		var_144_7:heroWakeup()
	end

	arg_144_1.target:beforeDamageHarm(var_144_3, arg_144_1)

	if arg_144_1.attackType == var_0_2.AttackType.CURE then
		local var_144_9 = var_144_4 * var_144_7:getDCureRate()

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			var_144_7:updateHp(arg_144_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][1])
			var_144_7:updateEnergyTo(arg_144_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][2])

			if var_144_9 > 0 then
				var_144_7.fighterModel:playHPDeltas({
					{
						var_144_9,
						var_144_2
					}
				}, nil, arg_144_1.attackType)
			end
		elseif var_144_9 > 0 and (var_0_1.ctx.battle.campaignType ~= var_0_2.CampaignType.GUILD or var_144_7:getTeamType() ~= var_0_2.TeamType.B) then
			local var_144_10 = var_0_68(var_144_7:getHpLimit(), var_144_7:getHp() + var_144_9)

			var_144_7:updateHp(var_144_10)
			var_144_7.fighterModel:playHPDeltas({
				{
					var_144_9,
					var_144_2
				}
			}, nil, arg_144_1.attackType)

			if var_0_1.ctx.battle.infoListener.unit_cure_info then
				local var_144_11 = {
					unit = arg_144_1,
					cure = var_144_9
				}

				table.insert(var_0_1.ctx.battle.infoListener.unit_cure_info, var_144_11)
			end
		end

		var_144_7.cureHp = var_144_7.cureHp + var_144_9

		arg_144_1:recordTargetState("after")
	else
		if arg_144_1.target:isAffected() then
			var_144_3 = 0
		end

		if not arg_144_0:isIgnoreImmortal(arg_144_1) and var_144_7:isImmortal(arg_144_1.attackType) then
			var_144_3, var_144_5 = 0, 0
			var_144_0 = true

			var_144_7.fighterModel:playHPDeltas({
				{
					var_144_3,
					false
				}
			}, nil, arg_144_1.attackType)
		else
			local var_144_12 = var_144_3

			if arg_144_0:hasElementEquipByID(var_0_2.ElementEquip.DHARM_EXTRA_HARM) then
				local var_144_13 = var_0_2.ElementEquip.DHARM_EXTRA_HARM

				var_144_3 = var_144_3 * (1 + var_0_18:battleAttr(var_144_13, arg_144_0:getElementEquipLevelByID(var_144_13)) * arg_144_0.hero_:getElementEquipActiveRate(var_144_13))
			end

			local var_144_14 = var_144_3
			local var_144_15 = 0
			local var_144_16
			local var_144_17, var_144_18

			var_144_3, var_144_17, var_144_18 = var_144_7:getDHarmBuff(var_144_3, arg_144_1.attackType, arg_144_1.fighter)

			if arg_144_0:hasElementEquipByID(var_0_2.ElementEquip.DHARM_EXTRA_HARM) then
				var_144_3 = var_0_68(var_144_3, var_144_12)
			end

			if (var_144_3 < var_144_14 or var_144_18) and var_144_3 == 0 then
				var_144_5 = 0
			end

			if var_144_17 > 0 then
				var_144_7:updateHp(var_144_7:getHp() + var_144_17)
			end

			if var_144_18 then
				var_144_7:updateHpBar(false)
			end
		end
	end

	local var_144_19, var_144_20, var_144_21, var_144_22 = var_144_7:applyHurtFighterHunqi(arg_144_1, var_144_3, var_144_5, var_144_2, var_144_0)
	local var_144_23, var_144_24, var_144_25, var_144_26 = var_144_7:applyHurtFighter(arg_144_1, var_144_19, var_144_20, var_144_21, var_144_22)

	if var_144_24 > 1 and not arg_144_0:isDeath() and (var_0_1.ctx.battle.campaignType ~= var_0_2.CampaignType.GUILD or arg_144_0:getTeamType() ~= var_0_2.TeamType.B) then
		arg_144_0.fighterModel:playHPDeltas({
			{
				var_144_24,
				false
			}
		}, nil, arg_144_1.attackType)
		arg_144_0:updateHp(arg_144_0:getHp() + var_144_24)
	end

	if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_144_0:updateHarms(var_144_23)
		arg_144_1.target:updateBearHarms(var_144_23)
		arg_144_0:awakeMissionHandle()
	end

	arg_144_0:afterDamageHarm(var_144_23, arg_144_1)
	arg_144_0:shake(arg_144_1, var_144_23)

	local var_144_27, var_144_28, var_144_29, var_144_30, var_144_31 = arg_144_0:checkUnitBuffs(arg_144_1, var_144_26)

	if arg_144_0:getSummonType() == var_0_2.summonMonsterType.None then
		var_144_27 = arg_144_0:updateBuffsByCourse(arg_144_1, var_144_27)
	end

	var_144_7:applyUnitBuffs(var_144_27, var_144_28, var_144_29, var_144_30, var_144_31, arg_144_1)
	var_144_7:applyUnitBuffsHunqi(var_144_27, var_144_28, var_144_29, var_144_30, var_144_31, arg_144_1)

	if var_144_7:isDeath() and arg_144_0.isAwakeHero and arg_144_0.awakeMissionGoalType and arg_144_0.awakeMissionGoalType == var_0_2.AwakeStage3MissionType.SELF_KILL and var_144_7.hero_:getTableID() == arg_144_0.awakeMonsterID then
		if arg_144_0.summoner then
			arg_144_0.summoner.isDoneSelfKill = true
		else
			arg_144_0.isDoneSelfKill = true
		end
	end

	if var_144_7:isDeath() and var_144_7:canReborn() ~= true and var_144_7:getSummonType() == var_0_2.summonMonsterType.None then
		arg_144_0:checkKilling(arg_144_1)
	end

	if arg_144_0:getSummonType() == var_0_2.summonMonsterType.None then
		local var_144_32 = arg_144_0:getSkillColorByID(arg_144_1.skillID)
		local var_144_33 = arg_144_0.hero_:getCourseIDByColor(var_144_32)

		if var_144_33 > 0 and arg_144_0.hero_:getCourseTypeByID(var_144_33) == var_0_2.CourseType.ADD_BUFF then
			arg_144_0:addCourseBuff(var_144_33, arg_144_1)
		end
	end

	if arg_144_0:getElementType() == var_0_2.ElementType.FIRE and arg_144_1.target:getElementType() == var_0_2.ElementType.THUNDER and arg_144_0:getTeamType() ~= arg_144_1.target:getTeamType() then
		local var_144_34 = var_0_26
		local var_144_35 = var_0_27
		local var_144_36 = arg_144_0:createNewBuffs({
			var_144_35
		}, arg_144_1.target, var_144_34)

		arg_144_1.target:addBuffs(var_144_36)
	end

	if var_144_23 > 0 and arg_144_0:getTeamType() ~= arg_144_1.target:getTeamType() then
		arg_144_0:elementLeiting(arg_144_1)
		arg_144_0:elementDcure(arg_144_1)
	end

	if var_144_23 > 0 then
		arg_144_1.target:hunqiKongchang(arg_144_1, var_144_23)
	end
end

function var_0_3.updateBuffsByCourse(arg_145_0, arg_145_1, arg_145_2)
	local var_145_0 = arg_145_0:getSkillColorByID(arg_145_1.skillID)
	local var_145_1 = arg_145_0.hero_:getCourseIDByColor(var_145_0)

	if not arg_145_1.target:isDeath() and var_145_1 and var_145_1 > 0 then
		local var_145_2 = var_0_2.tables.objectBook:number(var_145_1)[1]
		local var_145_3 = var_0_2.tables.objectBook:stepUp(var_145_1)[1]
		local var_145_4 = arg_145_0.hero_:getCourseLevelByID(var_145_1)

		if not var_145_2 or not var_145_3 or not var_145_4 then
			return arg_145_2
		end

		local var_145_5 = var_145_2 + var_145_3 * var_145_4
		local var_145_6 = arg_145_0.hero_:getCourseTypeByID(var_145_1)

		if var_145_6 and var_145_6 == var_0_2.CourseType.BUFF_EXTRA_TIME then
			for iter_145_0 = 1, #arg_145_2 do
				local var_145_7 = arg_145_2[iter_145_0]

				if var_145_7:getType() ~= var_0_2.BuffType.JUST_SHOW then
					local var_145_8 = (var_145_7:getTime() or 0) * var_145_5

					var_145_7:setExtraTime(var_145_8)
				end
			end
		elseif var_145_6 and var_145_6 == var_0_2.CourseType.EXTRA_D_HARM then
			for iter_145_1 = 1, #arg_145_2 do
				local var_145_9 = arg_145_2[iter_145_1]

				if var_145_9:getType() == var_0_2.BuffType.D_HARM then
					local var_145_10 = var_145_9:getDHarm() or 0

					var_145_9.dHarm_ = var_145_10 + var_145_10 * var_145_5
				end
			end
		end
	end

	return arg_145_2
end

function var_0_3.updateCourseBuffCD(arg_146_0)
	for iter_146_0, iter_146_1 in pairs(arg_146_0.courseBuffCD_) do
		for iter_146_2, iter_146_3 in pairs(iter_146_1) do
			if iter_146_3 > 0 then
				iter_146_1[iter_146_2] = iter_146_1[iter_146_2] - 1
			end
		end
	end
end

function var_0_3.addCourseBuff(arg_147_0, arg_147_1, arg_147_2)
	local function var_147_0(arg_148_0, arg_148_1, arg_148_2, arg_148_3)
		local var_148_0 = {}

		for iter_148_0 = 1, #arg_148_0 do
			if arg_148_0[iter_148_0] and arg_148_0[iter_148_0] > 0 then
				local var_148_1 = var_0_4.new({
					tableID = arg_148_0[iter_148_0],
					start = var_0_1.ctx.battle.count,
					level = arg_148_2,
					skillID = arg_148_1,
					fighter = arg_147_0,
					target = arg_148_3
				})

				var_148_1:setIsHit(true)
				var_148_1:setDirection(arg_147_0:getFighterModel():getFlipX())
				table.insert(var_148_0, var_148_1)
			end
		end

		return var_148_0
	end

	local var_147_1 = var_0_17:target(arg_147_1)
	local var_147_2

	if var_147_1 == var_0_2.CourseTarget.FIGHTER then
		var_147_2 = arg_147_0
	elseif var_147_1 == var_0_2.CourseTarget.TARGET then
		if arg_147_2.target == arg_147_0 then
			return
		end

		var_147_2 = arg_147_2.target
	elseif var_147_1 == var_0_2.CourseTarget.SIDE_TEAM then
		if arg_147_2.target:getTeamType() == arg_147_0:getTeamType() then
			return
		end

		var_147_2 = arg_147_2.target
	elseif var_147_1 == var_0_2.CourseTarget.SELF_TEAM then
		if arg_147_2.target:getTeamType() ~= arg_147_0:getTeamType() then
			return
		end

		var_147_2 = arg_147_2.target
	end

	if not var_147_2 or var_147_2:isDeath() then
		return
	end

	local var_147_3 = var_0_17:buffs(arg_147_1)
	local var_147_4 = false
	local var_147_5 = arg_147_0.hero_:getCourseLevelByID(arg_147_1)
	local var_147_6 = var_147_2.fighterIndex
	local var_147_7 = arg_147_2.skillID

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if arg_147_0.skillCourseBuff_[var_147_6] then
			var_147_4 = arg_147_0.skillCourseBuff_[var_147_6][tostring(var_0_1.ctx.battle.count)]
		end
	else
		local var_147_8 = tostring(var_147_7)

		if arg_147_0.courseBuffCD_[var_147_8] and arg_147_0.courseBuffCD_[var_147_8][var_147_6] and arg_147_0.courseBuffCD_[var_147_8][var_147_6] > 0 then
			-- block empty
		else
			local var_147_9 = var_0_17:number(arg_147_1)[1] + var_0_17:number(arg_147_1)[1] * var_147_5

			var_147_4 = var_0_2.weightedChoise({
				var_147_9,
				1 - var_147_9
			}) == 1

			if var_147_4 then
				if not arg_147_0.records_.skill_course_buff[var_147_6] then
					arg_147_0.records_.skill_course_buff[var_147_6] = {}
				end

				arg_147_0.records_.skill_course_buff[var_147_6][tostring(var_0_1.ctx.battle.count)] = true

				if not arg_147_0.courseBuffCD_[var_147_8] then
					arg_147_0.courseBuffCD_[var_147_8] = {}
				end

				arg_147_0.courseBuffCD_[var_147_8][var_147_6] = var_0_20
			end
		end
	end

	if var_147_4 then
		local var_147_10 = var_147_0(var_147_3, var_147_7, var_147_5, var_147_2)

		var_147_2:addBuffs(var_147_10)
	end
end

function var_0_3.addCourseHarm(arg_149_0, arg_149_1, arg_149_2, arg_149_3)
	local var_149_0

	if arg_149_1.attackType == var_0_2.AttackType.AD then
		var_149_0 = arg_149_1.target:getADJianShang()
	elseif arg_149_1.attackType == var_0_2.AttackType.AP then
		var_149_0 = arg_149_1.target:getAPJianShang()
	else
		return arg_149_2
	end

	local var_149_1 = arg_149_0.hero_:getCourseLevelByID(arg_149_3)
	local var_149_2 = var_0_17:number(arg_149_3)
	local var_149_3 = var_0_17:stepUp(arg_149_3)

	arg_149_2 = arg_149_2 + (var_149_2[1] + var_149_3[1] * var_149_1 + arg_149_0:getCourseAddNum(arg_149_3)) * var_149_0

	return arg_149_2
end

function var_0_3.addCourseCure(arg_150_0, arg_150_1, arg_150_2, arg_150_3)
	local var_150_0 = arg_150_0.hero_:getCourseLevelByID(arg_150_3)
	local var_150_1 = var_0_17:number(arg_150_3)
	local var_150_2 = var_0_17:stepUp(arg_150_3)

	arg_150_2 = arg_150_2 + (var_150_1[1] + var_150_2[1] * var_150_0 + arg_150_0:getCourseAddNum(arg_150_3))

	return arg_150_2
end

function var_0_3.getCourseAddNum(arg_151_0, arg_151_1)
	local var_151_0 = arg_151_0.hero_:getCourseLevelByID(arg_151_1)
	local var_151_1 = var_0_17:stepType(arg_151_1)
	local var_151_2 = var_0_17:stepStart(arg_151_1)
	local var_151_3 = var_0_17:step(arg_151_1)
	local var_151_4 = 0

	for iter_151_0 = 1, #var_151_1 do
		if not var_151_1[iter_151_0] or not var_151_2[iter_151_0] or not var_151_3[iter_151_0] then
			break
		end

		local var_151_5 = var_151_1[iter_151_0]
		local var_151_6 = 0

		if var_151_5 == var_0_2.AttributeType.AD then
			var_151_6 = arg_151_0:getAD()
		elseif var_151_5 == var_0_2.AttributeType.AP then
			var_151_6 = arg_151_0:getAP()
		elseif var_151_5 == var_0_2.AttributeType.HUJIA then
			var_151_6 = arg_151_0:getHuJia()
		elseif var_151_5 == var_0_2.AttributeType.MOKANG then
			var_151_6 = arg_151_0:getMoKang()
		end

		var_151_4 = var_151_4 + (var_151_2[iter_151_0] + var_151_3[iter_151_0] * var_151_0) * var_151_6
	end

	return var_151_4
end

function var_0_3.addCourseInitBuff(arg_152_0)
	local function var_152_0(arg_153_0, arg_153_1, arg_153_2, arg_153_3)
		local var_153_0 = {}

		for iter_153_0 = 1, #arg_153_0 do
			if arg_153_0[iter_153_0] and arg_153_0[iter_153_0] > 0 then
				local var_153_1 = var_0_4.new({
					tableID = arg_153_0[iter_153_0],
					start = var_0_1.ctx.battle.count,
					level = arg_153_2,
					skillID = arg_153_1,
					fighter = arg_152_0,
					target = arg_153_3
				})

				var_153_1:setIsHit(true)
				var_153_1:setDirection(arg_152_0:getFighterModel():getFlipX())
				table.insert(var_153_0, var_153_1)
			end
		end

		return var_153_0
	end

	if arg_152_0:getSummonType() ~= var_0_2.summonMonsterType.None then
		return
	end

	for iter_152_0 = 1, var_0_2.SKILL_INDEX.TotalNum do
		if arg_152_0:getSkillLevelByColor(iter_152_0) > 0 then
			local var_152_1 = arg_152_0.hero_:getCourseIDByColor(iter_152_0)

			if var_152_1 > 0 then
				local var_152_2 = arg_152_0.hero_:getCourseLevelByID(var_152_1)
				local var_152_3 = var_0_17:target(var_152_1)

				if arg_152_0.hero_:getCourseTypeByID(var_152_1) == var_0_2.CourseType.ADD_BUFF and var_152_3 == var_0_2.CourseTarget.MYSELF then
					local var_152_4 = var_0_17:buffs(var_152_1)
					local var_152_5 = var_152_0(var_152_4, arg_152_0:getSkillByColor(iter_152_0), var_152_2, arg_152_0)

					arg_152_0:addBuffs(var_152_5)
				elseif arg_152_0.hero_:getCourseTypeByID(var_152_1) == var_0_2.CourseType.JIANSHANG then
					local var_152_6 = var_0_17:number(var_152_1)
					local var_152_7 = var_0_17:stepUp(var_152_1)
					local var_152_8 = var_152_6[1] + var_152_7[1] * var_152_2

					arg_152_0:setCourseJianshang(var_152_8)
				end
			end
		end
	end
end

function var_0_3.setCourseJianshang(arg_154_0, arg_154_1)
	arg_154_0.courseJianshang_ = arg_154_1 or 0
end

function var_0_3.getCourseJianshang(arg_155_0)
	return arg_155_0.courseJianshang_ or 0
end

function var_0_3.beforeDamageHarm(arg_156_0, arg_156_1, arg_156_2)
	return
end

function var_0_3.afterDamageHarm(arg_157_0, arg_157_1, arg_157_2)
	return
end

function var_0_3.shake(arg_158_0, arg_158_1, arg_158_2)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType or arg_158_2 < 1 then
		return
	end

	local var_158_0 = var_0_12:shakeLevel(arg_158_1.skillID)

	if var_0_12:shakeLevel(arg_158_1.skillID) > 0 then
		local var_158_1 = var_0_12:shakeDelay(arg_158_1.skillID)
		local var_158_2 = var_0_2.tables.shake:time(var_158_0)
		local var_158_3 = var_0_2.tables.shake:range(var_158_0)

		if var_158_1 > 0 then
			var_0_0.import("framework.scheduler").performWithDelayGlobal(function()
				var_0_2.playSceneShaking(var_158_2, var_158_3)
			end, var_158_1)
		else
			var_0_2.playSceneShaking(var_158_2, var_158_3)
		end
	end
end

function var_0_3.getUnitData(arg_160_0, arg_160_1)
	local var_160_0
	local var_160_1
	local var_160_2
	local var_160_3
	local var_160_4
	local var_160_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = unpack(arg_160_1.reportData_.calculate[tostring(var_0_1.ctx.battle.count)])
	else
		var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_0:calculateUnitData(arg_160_1)
		var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_1.target:updateUnitDataByTargetHunqi(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
		var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_1.target:updateUnitDataByTarget(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)

		if not var_0_12:isReflect(arg_160_1.skillID) then
			var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_0:updateUnitDataByFighterElement(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
			var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_0:updateUnitDataByFighterHunqi(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
			var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = arg_160_0:updateUnitDataByFighter(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
		end

		for iter_160_0, iter_160_1 in ipairs(arg_160_0.selfTeam_) do
			if not iter_160_1:isDeath() and not var_0_12:isTriggerSkill(arg_160_1.skillID) and not var_0_12:isReflect(arg_160_1.skillID) then
				var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = iter_160_1:updateUnitDataBySpecialHero(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
			end
		end

		for iter_160_2, iter_160_3 in ipairs(arg_160_0.sideTeam_) do
			if not iter_160_3:isDeath() and not var_0_12:isTriggerSkill(arg_160_1.skillID) and not var_0_12:isReflect(arg_160_1.skillID) then
				var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = iter_160_3:updateUnitDataBySpecialHero(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
			end
		end

		if var_0_1.ctx.battle.schoolSceneFighter then
			var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5 = var_0_1.ctx.battle.schoolSceneFighter:updateUnitDataBySpecialHero(arg_160_1, var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
		end

		if var_0_1.ctx.battle.isActivity and not arg_160_0:isMainRole() then
			var_160_3 = 0
			var_160_2 = 0
		end

		arg_160_1:recordData(var_160_0, var_160_1, var_160_2, var_160_3, var_160_4, var_160_5)
	end

	local var_160_6 = arg_160_0:checkHarmValid(var_160_2)

	return var_160_0, var_160_1, var_160_6, var_160_3, var_160_4, var_160_5
end

function var_0_3.calculateUnitData(arg_161_0, arg_161_1)
	return arg_161_1:calculate()
end

function var_0_3.updateUnitDataBySpecialHero(arg_162_0, arg_162_1, arg_162_2, arg_162_3, arg_162_4, arg_162_5, arg_162_6, arg_162_7)
	return arg_162_2, arg_162_3, arg_162_4, arg_162_5, arg_162_6, arg_162_7
end

function var_0_3.updateUnitInfoBySpecialHero(arg_163_0, arg_163_1, arg_163_2, arg_163_3, arg_163_4, arg_163_5, arg_163_6, arg_163_7)
	return
end

function var_0_3.updateUnitDataByTarget(arg_164_0, arg_164_1, arg_164_2, arg_164_3, arg_164_4, arg_164_5, arg_164_6, arg_164_7)
	if arg_164_0:getAttrByType(var_0_2.AttributeType.EXTRA_XIXUE) > 0 and arg_164_4 > 0 then
		arg_164_6 = arg_164_6 + arg_164_4 * arg_164_0:getAttrByType(var_0_2.AttributeType.EXTRA_XIXUE)
	end

	if arg_164_0:isTeamAffected() and arg_164_0:getTeamType() == arg_164_1.fighter:getTeamType() and arg_164_0 ~= arg_164_1.fighter then
		arg_164_5 = 0
	end

	return arg_164_2, arg_164_3, arg_164_4, arg_164_5, arg_164_6, arg_164_7
end

function var_0_3.updateUnitDataByTargetHunqi(arg_165_0, arg_165_1, arg_165_2, arg_165_3, arg_165_4, arg_165_5, arg_165_6, arg_165_7)
	if arg_165_0:getHunQiSuitID() == var_0_2.HunqiSuitID.COUNT_FANSHANG and arg_165_4 > 0 and arg_165_1.fighter:getTeamType() ~= arg_165_0:getTeamType() and (arg_165_0.hunqiFanshangCDCount == 0 or var_0_1.ctx.battle.count - arg_165_0.hunqiFanshangCDCount > var_0_45) then
		if arg_165_0:isHasBuffByID(var_0_43) then
			arg_165_0:removeBuffByID(var_0_43)

			local var_165_0 = arg_165_0:createAttackUnits({
				arg_165_1.fighter
			}, var_0_41)

			for iter_165_0, iter_165_1 in ipairs(var_165_0) do
				iter_165_1.hunqiHarm = arg_165_4

				table.insert(arg_165_0.moveAttackUnits_, iter_165_1)
				table.insert(arg_165_0.records_.special_units, iter_165_1)
			end

			arg_165_4 = 0
			arg_165_0.hunqiFanshangCount = 0
			arg_165_0.hunqiFanshangCDCount = var_0_1.ctx.battle.count
		else
			arg_165_0.hunqiFanshangCount = arg_165_0.hunqiFanshangCount + 1

			if arg_165_0.hunqiFanshangCount >= var_0_44 then
				local var_165_1 = arg_165_0:createAttackUnits({
					arg_165_0
				}, var_0_42)

				for iter_165_2, iter_165_3 in ipairs(var_165_1) do
					table.insert(arg_165_0.moveAttackUnits_, iter_165_3)
					table.insert(arg_165_0.records_.special_units, iter_165_3)
				end
			end
		end
	end

	return arg_165_2, arg_165_3, arg_165_4, arg_165_5, arg_165_6, arg_165_7
end

function var_0_3.updateUnitDataByFighterHunqi(arg_166_0, arg_166_1, arg_166_2, arg_166_3, arg_166_4, arg_166_5, arg_166_6, arg_166_7)
	if arg_166_1.hunqiCure then
		arg_166_5 = arg_166_5 + arg_166_1.hunqiCure
	end

	if arg_166_1.hunqiHarm then
		arg_166_4 = arg_166_4 + arg_166_1.hunqiHarm
	end

	if arg_166_0:getHunQiSuitID() == var_0_2.HunqiSuitID.BAOJI_EXTRAHARM and arg_166_4 > 0 and arg_166_3 and arg_166_1.target:getTeamType() ~= arg_166_0:getTeamType() then
		if arg_166_0.hunqiBaojiExtraHarmCount == 0 or var_0_1.ctx.battle.count - arg_166_0.hunqiBaojiExtraHarmCount > var_0_37 then
			arg_166_4 = arg_166_4 + var_0_68(var_0_38, arg_166_0:getHp() * var_0_39 + arg_166_1.target:getHpLimit() * var_0_40)
			arg_166_0.hunqiBaojiExtraHarmCount = var_0_1.ctx.battle.count

			local var_166_0 = arg_166_0:createAttackUnits({
				arg_166_1.target
			}, var_0_36)

			for iter_166_0, iter_166_1 in ipairs(var_166_0) do
				table.insert(arg_166_0.moveAttackUnits_, iter_166_1)
				table.insert(arg_166_0.records_.special_units, iter_166_1)
			end
		end
	elseif arg_166_0:getHunQiSuitID() == var_0_2.HunqiSuitID.LOSS_HP_HARM and arg_166_4 > 0 then
		if arg_166_0.hunqiLossHpHarmCount == 0 or var_0_1.ctx.battle.count - arg_166_0.hunqiLossHpHarmCount > var_0_59 then
			local var_166_1 = (arg_166_1.target:getHpLimit() - arg_166_1.target:getHp()) * var_0_57

			arg_166_4 = arg_166_4 + var_0_68(var_0_58, var_166_1)
			arg_166_0.hunqiLossHpHarmCount = var_0_1.ctx.battle.count

			local var_166_2 = arg_166_0:createAttackUnits({
				arg_166_1.target
			}, var_0_56)

			for iter_166_2, iter_166_3 in ipairs(var_166_2) do
				table.insert(arg_166_0.moveAttackUnits_, iter_166_3)
				table.insert(arg_166_0.records_.special_units, iter_166_3)
			end
		end
	elseif arg_166_0:getHunQiSuitID() == var_0_2.HunqiSuitID.JIANSHE and arg_166_4 > 0 and arg_166_3 and arg_166_1.target:getTeamType() ~= arg_166_0:getTeamType() and arg_166_1.skillID ~= var_0_62 and (arg_166_0.hunqiJianSheCount == 0 or var_0_1.ctx.battle.count - arg_166_0.hunqiJianSheCount > var_0_63) then
		local var_166_3 = arg_166_0:getHunQiJianSheTarget(arg_166_0, var_0_62, arg_166_1.target)
		local var_166_4 = arg_166_0:createAttackUnits(var_166_3, var_0_62)

		for iter_166_4, iter_166_5 in ipairs(var_166_4) do
			iter_166_5.hunqiHarm = arg_166_4 * var_0_64

			table.insert(arg_166_0.moveAttackUnits_, iter_166_5)
			table.insert(arg_166_0.records_.special_units, iter_166_5)
		end

		arg_166_0.hunqiJianSheCount = var_0_1.ctx.battle.count
	end

	return arg_166_2, arg_166_3, arg_166_4, arg_166_5, arg_166_6, arg_166_7
end

function var_0_3.updateUnitDataByFighterElement(arg_167_0, arg_167_1, arg_167_2, arg_167_3, arg_167_4, arg_167_5, arg_167_6, arg_167_7)
	if arg_167_1.elementCure then
		arg_167_5 = arg_167_5 + arg_167_1.elementCure
	end

	if arg_167_1.elementHarm then
		arg_167_4 = arg_167_4 + arg_167_1.elementHarm
	end

	if arg_167_4 > 0 and arg_167_0:getElementType() == var_0_2.ElementType.THUNDER and arg_167_1.target:getElementType() == var_0_2.ElementType.WATER and arg_167_0:getTeamType() ~= arg_167_1.target:getTeamType() and arg_167_0.elementThunderCount <= 0 then
		arg_167_7 = arg_167_7 - var_0_24
		arg_167_0.elementThunderCount = var_0_25
	elseif arg_167_4 > 0 and arg_167_0:getElementType() == var_0_2.ElementType.WATER and arg_167_1.target:getElementType() == var_0_2.ElementType.FIRE and arg_167_0:getTeamType() ~= arg_167_1.target:getTeamType() then
		arg_167_4 = arg_167_4 + math.min(var_0_28 * arg_167_1.target:getHp(), var_0_29)
	elseif arg_167_4 > 0 and arg_167_0:getElementType() ~= var_0_2.ElementType.NONE and arg_167_1.target:getElementType() == var_0_2.ElementType.NONE and arg_167_0:getTeamType() ~= arg_167_1.target:getTeamType() then
		arg_167_4 = arg_167_4 * (1 + var_0_30)
	end

	if var_0_12:father(arg_167_1.skillID) == arg_167_0:getPugongID() and arg_167_0:hasElementEquipByID(var_0_2.ElementEquip.PUGONG_XIXUE) then
		local var_167_0 = var_0_2.ElementEquip.PUGONG_XIXUE
		local var_167_1 = var_0_18:battleAttr(var_167_0, arg_167_0:getElementEquipLevelByID(var_167_0))
		local var_167_2 = arg_167_0.hero_:getElementEquipActiveRate(var_167_0)
		local var_167_3 = (arg_167_1.fighter:getXixue() + var_167_1 * var_167_2) / (100 + arg_167_1.target:getLevel() + arg_167_1.fighter:getXixue())

		if arg_167_1.attackType == var_0_2.AttackType.AP then
			var_167_3 = 1 + arg_167_1.fighter:getAddCure()
		end

		arg_167_6 = var_167_3 * arg_167_1.harm * var_0_12:xixue(arg_167_1.skillID) / var_0_2.DECIMAL_BASE
	end

	return arg_167_2, arg_167_3, arg_167_4, arg_167_5, arg_167_6, arg_167_7
end

function var_0_3.updateUnitDataByFighter(arg_168_0, arg_168_1, arg_168_2, arg_168_3, arg_168_4, arg_168_5, arg_168_6, arg_168_7)
	if arg_168_0:getSummonType() == var_0_2.summonMonsterType.None then
		local var_168_0 = arg_168_0:getSkillColorByID(arg_168_1.skillID)
		local var_168_1 = arg_168_0.hero_:getCourseIDByColor(var_168_0)
		local var_168_2 = var_0_1.ctx.battle.count

		if var_168_1 > 0 and (not arg_168_0.courseSelfSkillCD_[var_168_1] or var_168_2 - arg_168_0.courseSelfSkillCD_[var_168_1] >= var_0_21) then
			arg_168_0.courseSelfSkillCD_[var_168_1] = var_168_2

			local var_168_3 = var_0_17:target(var_168_1)

			if arg_168_0.hero_:getCourseTypeByID(var_168_1) == var_0_2.CourseType.CURE then
				arg_168_6 = arg_168_0:addCourseCure(arg_168_1, arg_168_6, var_168_1)
			elseif arg_168_0.hero_:getCourseTypeByID(var_168_1) == var_0_2.CourseType.HARM then
				arg_168_4 = arg_168_0:addCourseHarm(arg_168_1, arg_168_4, var_168_1)
			end
		end
	end

	return arg_168_2, arg_168_3, arg_168_4, arg_168_5, arg_168_6, arg_168_7
end

function var_0_3.checkHarmValid(arg_169_0, arg_169_1)
	if arg_169_1 and arg_169_1 > 0 and arg_169_0.hpLimit_ then
		local var_169_0 = arg_169_0.hpLimit_ * var_0_19.harmLimitPara

		if var_169_0 < arg_169_1 then
			arg_169_1 = var_169_0
		end
	end

	return arg_169_1
end

function var_0_3.updateUnitBaseByFighter(arg_170_0, arg_170_1, arg_170_2, arg_170_3)
	return arg_170_2 * arg_170_0:getAD() / var_0_2.DECIMAL_BASE + arg_170_3 * arg_170_0:getAP() / var_0_2.DECIMAL_BASE
end

function var_0_3.checkKilling(arg_171_0, arg_171_1)
	if arg_171_0.summoner then
		arg_171_0.summoner:checkKilling()

		return
	end

	arg_171_0.killCount = arg_171_0.killCount + 1

	if arg_171_0:isDeath() then
		return
	end

	local var_171_0

	if arg_171_1 and arg_171_1.target then
		var_171_0 = arg_171_1.target:getHalfKillMp()
	end

	if var_171_0 and var_0_2.weightedChoise({
		var_171_0,
		1 - var_171_0
	}) == 1 then
		arg_171_0:updateEnergyBy(arg_171_0:getKillingMp() / 2)
		arg_171_0.fighterModel:playEnergyFloat(arg_171_0:getKillingMp() / 2)
	else
		arg_171_0:updateEnergyBy(arg_171_0:getKillingMp())
		arg_171_0.fighterModel:playEnergyFloat(arg_171_0:getKillingMp())
	end
end

function var_0_3.applyHurtFighter(arg_172_0, arg_172_1, arg_172_2, arg_172_3, arg_172_4, arg_172_5)
	if var_0_1.ctx.battle.isActivity and not arg_172_1.fighter:isMainRole() and arg_172_1.fighter:getTeamType() ~= arg_172_0:getTeamType() then
		return 0, 0, false, true
	end

	if var_0_1.ctx.battle.infoListener.harm_info then
		local var_172_0 = {
			harm = arg_172_2,
			target = arg_172_1.target,
			fighter = arg_172_1.fighter,
			type = arg_172_1.attackType,
			skillID = arg_172_1.skillID,
			isBaoji = arg_172_4
		}

		table.insert(var_0_1.ctx.battle.infoListener.harm_info, var_172_0)
	end

	arg_172_2 = arg_172_2 > 0 and var_0_69(arg_172_2, 1) or 0

	if arg_172_0:isHurtBreak(arg_172_2, arg_172_1) and not arg_172_0:isAdBreakImmortal() and not arg_172_0:isBreakImmortal() then
		arg_172_0:setBreakInterval()

		if not arg_172_0:isPause() and arg_172_2 > 0 and var_0_1.ctx.battle.isEnergySkilling then
			arg_172_0:getFighterModel():resume()
		end

		if not arg_172_0:isPause() then
			arg_172_0:attacked()
		end

		if arg_172_0:isCreatingUnits() then
			arg_172_0:skillIsBreak(arg_172_1)
		end
	end

	local var_172_1 = arg_172_2 - arg_172_0:getHp()
	local var_172_2 = var_0_69(0, arg_172_0:getHp() - arg_172_2)
	local var_172_3 = arg_172_0:getHp()
	local var_172_4 = arg_172_2

	if var_172_1 > 0 then
		var_172_2 = arg_172_0:getLastDHarmBuff(var_172_1, arg_172_1.attackType) > 0 and 0 or 1
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		if next(arg_172_0.shieldBuffs_) and (not arg_172_1.fighter or not arg_172_1.fighter:isIgnoreShield()) and arg_172_2 > 0 and (arg_172_1.attackType ~= var_0_2.AttackType.CURE or arg_172_1.target:getTeamType() ~= arg_172_1.fighter:getTeamType()) then
			local var_172_5 = arg_172_0.shieldBuffs_[1]
			local var_172_6 = arg_172_0.shieldBuffs_[1].fighter
			local var_172_7 = var_172_5:getShieldNum() - 1

			if arg_172_2 > var_172_5:getShieldMaxHarm() then
				arg_172_2 = arg_172_2 - var_172_5:getShieldMaxHarm()
			else
				arg_172_2 = 0
			end

			if var_172_7 <= 0 then
				arg_172_0:removeBuffByID(var_172_5:getTableID())
			else
				var_172_5:setShieldNum(var_172_7)
			end

			var_172_6:shieldFeedBack(arg_172_0, var_172_5)
		end

		arg_172_0:updateHp(arg_172_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][1])
		arg_172_0:updateEnergyTo(arg_172_1.reportData_.target_after[tostring(var_0_1.ctx.battle.count)][2])

		if arg_172_0:isPossessed() and var_0_12:isRemp(arg_172_1.skillID) ~= 1 then
			arg_172_0:updateEnergyByHarm(arg_172_2)
		end
	else
		if next(arg_172_0.shieldBuffs_) and (not arg_172_1.fighter or not arg_172_1.fighter:isIgnoreShield()) and arg_172_2 > 0 and (arg_172_1.attackType ~= var_0_2.AttackType.CURE or arg_172_1.target:getTeamType() ~= arg_172_1.fighter:getTeamType()) then
			local var_172_8 = arg_172_0.shieldBuffs_[1]
			local var_172_9 = arg_172_0.shieldBuffs_[1].fighter
			local var_172_10 = var_172_8:getShieldNum() - 1

			if arg_172_2 > var_172_8:getShieldMaxHarm() then
				var_172_2 = var_0_69(0, arg_172_0:getHp() - arg_172_2 + var_172_8:getShieldMaxHarm())

				arg_172_0:updateHp(var_172_2)

				arg_172_2 = arg_172_2 - var_172_8:getShieldMaxHarm()
				var_172_4 = arg_172_2
			else
				arg_172_2 = 0
			end

			if var_172_10 <= 0 then
				arg_172_0:removeBuffByID(var_172_8:getTableID())
			else
				var_172_8:setShieldNum(var_172_10)
			end

			var_172_9:shieldFeedBack(arg_172_0, var_172_8)
		else
			arg_172_0:updateHp(var_172_2)
		end

		if var_0_12:isRemp(arg_172_1.skillID) ~= 1 then
			arg_172_0:updateEnergyByHarm(arg_172_2)
		end
	end

	arg_172_0:hurtSkillEffect(arg_172_1)

	if arg_172_2 > 0 then
		local var_172_11 = var_0_69(1, var_172_4)

		arg_172_0.fighterModel:playHPDeltas({
			{
				-var_172_11,
				arg_172_4
			}
		}, nil, arg_172_1.attackType)
	end

	arg_172_1:recordTargetState("after")

	if arg_172_0:isDeath() then
		arg_172_1.target.killer_ = arg_172_1.fighter

		arg_172_0:die()
	end

	arg_172_0:hurtTrueHarm(arg_172_1, arg_172_2)

	arg_172_2 = var_0_68(arg_172_2, var_172_3)

	return arg_172_2, arg_172_3, arg_172_4, arg_172_5
end

function var_0_3.hurtTrueHarm(arg_173_0, arg_173_1, arg_173_2)
	return
end

function var_0_3.isHurtBreak(arg_174_0, arg_174_1, arg_174_2)
	if arg_174_2:isForceBreak() then
		return true
	end

	local var_174_0 = arg_174_0:getBreakStun()

	if var_174_0 > 0 then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			if var_0_2.weightedChoise({
				var_174_0,
				1 - var_174_0
			}) == 1 then
				arg_174_0.records_.break_stun[tostring(var_0_1.ctx.battle.count)] = true

				return false
			end
		elseif arg_174_0.breakStun_[tostring(var_0_1.ctx.battle.count)] then
			return false
		end
	end

	if arg_174_1 > arg_174_0:getHpLimit() * var_0_2.SHOW_HURT_EFFECT_RATE and arg_174_0.isEnergySkill_ ~= true and not arg_174_0:isPause() then
		return true
	end

	return false
end

function var_0_3.checkUnitBuffs(arg_175_0, arg_175_1, arg_175_2)
	local var_175_0 = arg_175_1.target
	local var_175_1
	local var_175_2
	local var_175_3
	local var_175_4
	local var_175_5

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_175_1, var_175_2, var_175_3, var_175_4, var_175_5 = arg_175_1:getReportBuffs()
	else
		var_175_1, var_175_2, var_175_3, var_175_4, var_175_5 = arg_175_1:getBuffs(arg_175_2)

		arg_175_1:recordBuff(var_175_1, var_175_2, var_175_3, var_175_4, var_175_5)
	end

	return var_175_1, var_175_2, var_175_3, var_175_4, var_175_5
end

function var_0_3.applyUnitBuffs(arg_176_0, arg_176_1, arg_176_2, arg_176_3, arg_176_4, arg_176_5, arg_176_6)
	if arg_176_0:isDeath() then
		for iter_176_0, iter_176_1 in ipairs(arg_176_1 or {}) do
			if iter_176_1:getYx() > 0 then
				arg_176_0.buffMovePath_ = iter_176_1:getPath()
			end
		end

		return
	end

	if next(arg_176_2) then
		arg_176_0.fighterModel:playFloatText({
			var_0_2.BattleFloatType.BUFF_MISS
		}, arg_176_0:getTeamType())
	end

	if next(arg_176_1) then
		arg_176_0:addBuffs(arg_176_1)
	end

	if arg_176_5 and not arg_176_0:isCreatingUnits() then
		arg_176_0.leftInterval_ = 0
	elseif arg_176_5 and arg_176_0:isCreatingUnits() and var_0_12:type(arg_176_0.unitSkills_.rootID_) ~= var_0_2.AttackType.AD then
		arg_176_0.leftInterval_ = 0

		arg_176_0:skillIsBreak(arg_176_6)
	end

	if arg_176_3 then
		arg_176_0:checkSkillBreak(var_0_2.BreakSkillType.AD, arg_176_6)
	end

	if arg_176_4 then
		arg_176_0:checkSkillBreak(var_0_2.BreakSkillType.AP, arg_176_6)
	end
end

function var_0_3.checkSkillBreak(arg_177_0, arg_177_1, arg_177_2)
	if arg_177_0:isBreakImmortal() then
		return
	end

	if arg_177_1 == var_0_2.BreakSkillType.AP then
		if arg_177_0:getCurrentSkillType() == var_0_2.AttackType.AP or arg_177_0:getCurrentSkillType() == var_0_2.AttackType.CURE then
			if arg_177_0:isCreatingUnits() then
				arg_177_0:skillIsBreak(arg_177_2)

				local var_177_0 = arg_177_0:getFighterModel().currentAnimation_ or ""

				if not arg_177_0:isPause() and var_177_0:find("gongji") then
					arg_177_0:resumeIdle()
				end
			end

			arg_177_0.isEnergySkill_ = false
		end
	elseif arg_177_1 == var_0_2.BreakSkillType.AD then
		if arg_177_0:isAdBreakImmortal() then
			return
		end

		arg_177_0:setBreakInterval()

		if not arg_177_0:isPause() then
			arg_177_0:attacked()
		end

		if arg_177_0:getCurrentSkillType() == var_0_2.AttackType.AD then
			if arg_177_0:isCreatingUnits() then
				arg_177_0:skillIsBreak(arg_177_2)
			end

			arg_177_0.isEnergySkill_ = false
		end
	end
end

function var_0_3.hurtSkillEffect(arg_178_0, arg_178_1)
	local var_178_0 = arg_178_1.skillID
	local var_178_1 = arg_178_1.fighter
	local var_178_2, var_178_3 = var_0_12:hurtResource(var_178_0)

	if not var_178_2 or not var_178_3 or var_178_2 == "" or var_178_3 == "" then
		return
	end

	local var_178_4 = arg_178_0:getFighterModel().attackedPoint.x
	local var_178_5 = arg_178_0:getFighterModel().attackedPoint.y
	local var_178_6 = var_0_1.ctx.battle.getSpine(var_178_0, "hurt", arg_178_0:getScale())

	if var_0_12:hurtEffectType(var_178_0) == var_0_2.hurtEffectType.Back then
		var_178_6:addTo(var_0_1.ctx.battle.unitLayer)
		var_178_6:x(var_178_4 + arg_178_0:getX()):y(var_178_5 + arg_178_0:getY())
	else
		var_178_6:addTo(arg_178_0.fighterModel:getBuffLayer())
		var_178_6:x(var_178_4):y(var_178_5)
	end

	var_178_6:playOnce()
	var_178_6:flipX(var_178_1:getFlipX())
end

function var_0_3.selfSkillEffect(arg_179_0)
	local var_179_0 = arg_179_0:getFrontSkill()

	if not var_0_12:selfResource(var_179_0) or var_0_12:selfResource(var_179_0) == "" then
		return
	end

	arg_179_0:getFighterModel():playAttackEffectIfNecessary_()
end

function var_0_3.createNewBuffs(arg_180_0, arg_180_1, arg_180_2, arg_180_3, arg_180_4)
	local var_180_0 = {}

	for iter_180_0, iter_180_1 in ipairs(arg_180_1) do
		local var_180_1 = var_0_4.new({
			tableID = iter_180_1,
			start = var_0_1.ctx.battle.count,
			level = arg_180_4 or arg_180_0:getSkillLevelByID(arg_180_3),
			skillID = arg_180_3,
			fighter = arg_180_0,
			target = arg_180_2
		})

		var_180_1:setIsHit(true)
		var_180_1:setDirection(arg_180_0:getFighterModel():getFlipX())
		table.insert(var_180_0, var_180_1)
	end

	return var_180_0
end

function var_0_3.addBuffs(arg_181_0, arg_181_1)
	arg_181_0:fliterBuffs(arg_181_1)
	arg_181_0:fliterBuffsHunqi(arg_181_1)

	for iter_181_0, iter_181_1 in ipairs(arg_181_0.selfTeam_) do
		if not iter_181_1:isDeath() then
			iter_181_1:addBuffBySpecialHero(arg_181_1)
			iter_181_1:elementEquipBuffSkill(arg_181_1)
		end
	end

	for iter_181_2, iter_181_3 in ipairs(arg_181_0.sideTeam_) do
		if not iter_181_3:isDeath() then
			iter_181_3:addBuffBySpecialHero(arg_181_1)
			iter_181_3:elementEquipBuffSkill(arg_181_1)
		end
	end

	for iter_181_4, iter_181_5 in ipairs(arg_181_1) do
		if iter_181_5.fighter then
			iter_181_5.fighter:buffAddAction(iter_181_5)
			iter_181_5.fighter:buffAddActionHunqi(iter_181_5)
		end

		if iter_181_5:getDHarm() > 0 then
			arg_181_0.showDHarmbuff_ = iter_181_5

			arg_181_0:updateHpBar(true)
		end

		if iter_181_5:isCover() and iter_181_5:getDHarm() <= 0 then
			local var_181_0

			for iter_181_6, iter_181_7 in ipairs(arg_181_0.buffs_) do
				if iter_181_7:getTableID() == iter_181_5:getTableID() then
					arg_181_0:removeBuffs(iter_181_7)

					break
				end
			end

			arg_181_0:distributeBuff(iter_181_5)
			arg_181_0.fighterModel:addBuffs({
				iter_181_5
			})
		else
			arg_181_0:distributeBuff(iter_181_5)
			arg_181_0.fighterModel:addBuffs({
				iter_181_5
			})
		end

		if arg_181_0:getBuffsByID(iter_181_5.tableID_) and #arg_181_0:getBuffsByID(iter_181_5.tableID_) > iter_181_5:CoverLimit() then
			local var_181_1 = arg_181_0:getBuffsByID(iter_181_5.tableID_)
			local var_181_2

			for iter_181_8, iter_181_9 in ipairs(var_181_1) do
				if not var_181_2 or iter_181_9.leftCount_ < var_181_2.leftCount_ then
					var_181_2 = iter_181_9
				end
			end

			if var_181_2 then
				arg_181_0:removeBuffs(var_181_2)
			end
		end

		arg_181_0:specialBuffCheck(iter_181_5)
	end
end

function var_0_3.addBuffBySpecialHero(arg_182_0, arg_182_1)
	return
end

function var_0_3.energyActionBySpecialHero(arg_183_0, arg_183_1, arg_183_2)
	return
end

function var_0_3.isPartnerControl(arg_184_0, arg_184_1)
	local var_184_0 = arg_184_1.target
	local var_184_1 = arg_184_1.fighter

	if arg_184_1:isPartnerControl() and var_184_0:getTeamType() == var_184_1:getTeamType() then
		return true
	end

	return false
end

function var_0_3.fliterBuffs(arg_185_0, arg_185_1)
	if arg_185_0:isBreakImmortal() then
		for iter_185_0 = #arg_185_1, 1, -1 do
			local var_185_0 = arg_185_1[iter_185_0]

			if not arg_185_0:isPartnerControl(var_185_0) and (var_185_0:isFear() or var_185_0:isApUnable() or var_185_0:isAdUnable() or var_185_0:isExcuteAdCircle() or var_185_0:isAttackFriend() or var_185_0:isPugongOnly()) then
				table.remove(arg_185_1, iter_185_0)
			end
		end
	end

	for iter_185_1 = #arg_185_1, 1, -1 do
		local var_185_1 = arg_185_1[iter_185_1]

		if var_185_1:getBuffForm() == var_0_2.BuffForm.GAIN and var_185_1:canRemove() then
			for iter_185_2, iter_185_3 in ipairs(arg_185_0.buffs_) do
				if iter_185_3:getDGainBuffCount() > 0 then
					iter_185_3:setDGainBuffCount(-1)

					if iter_185_3:getDGainBuffCount() < 1 then
						arg_185_0:removeBuffs(iter_185_3)
					end

					table.remove(arg_185_1, iter_185_1)
				end
			end
		elseif var_185_1:getBuffForm() == var_0_2.BuffForm.DEBUFF and var_185_1:canRemove() then
			for iter_185_4, iter_185_5 in ipairs(arg_185_0.buffs_) do
				if iter_185_5:getdDebuffCount() > 0 then
					iter_185_5:setdDebuffCount(-1)

					if iter_185_5:getdDebuffCount() < 1 then
						arg_185_0:removeBuffs(iter_185_5)
					end

					table.remove(arg_185_1, iter_185_1)
				end
			end
		end

		if arg_185_0:isTeamAffected() and var_185_1.fighter:getTeamType() == arg_185_0:getTeamType() and var_185_1.fighter ~= arg_185_0 then
			table.remove(arg_185_1, iter_185_1)
		end
	end

	if var_0_1.ctx.battle.isActivity then
		for iter_185_6 = #arg_185_1, 1, -1 do
			local var_185_2 = arg_185_1[iter_185_6]

			if not var_185_2.fighter:isMainRole() and var_185_2.fighter:getTeamType() ~= arg_185_0:getTeamType() then
				table.remove(arg_185_1, iter_185_6)
			end
		end
	end

	return arg_185_1
end

function var_0_3.distributeBuff(arg_186_0, arg_186_1)
	if var_0_1.ctx.battle.infoListener.buff_info then
		table.insert(var_0_1.ctx.battle.infoListener.buff_info, arg_186_1)
	end

	table.insert(arg_186_0.buffs_, arg_186_1)

	if arg_186_1:isAffected() then
		table.insert(arg_186_0.isAffectedBuffs_, arg_186_1)
	end

	if arg_186_1:isTeamAffected() then
		table.insert(arg_186_0.isTeamAffectedBuffs_, arg_186_1)
	end

	if arg_186_1:isInvisible() then
		table.insert(arg_186_0.isInvisibleBuffs_, arg_186_1)
	end

	if arg_186_1:isMoveUnable() then
		table.insert(arg_186_0.moveUnableBuffs_, arg_186_1)
	end

	if arg_186_1:isFear() then
		arg_186_0.fearMoveDir_ = arg_186_1:fearDir()

		table.insert(arg_186_0.fearBuffs_, arg_186_1)
	end

	if arg_186_1:isApUnable() then
		table.insert(arg_186_0.apUnableBuffs_, arg_186_1)
	end

	if arg_186_1:isAdUnable() then
		table.insert(arg_186_0.adUnableBuffs_, arg_186_1)
	end

	if arg_186_0:getDKongzhi() > 0 and (arg_186_1:isApUnable() and arg_186_1:isAdUnable() or arg_186_1:isPugongOnly()) then
		arg_186_1.leftCount_ = arg_186_1.leftCount_ * (1 - arg_186_0:getDKongzhi() / 100)
	end

	if arg_186_0:getDChenmo() > 0 and (arg_186_1:isApUnable() and not arg_186_1:isAdUnable() or arg_186_1:isPugongOnly()) then
		arg_186_1.leftCount_ = arg_186_1.leftCount_ * (1 - arg_186_0:getDChenmo() / 100)
	end

	if arg_186_1:isPugongOnly() then
		table.insert(arg_186_0.pugongOnlyBuffs_, arg_186_1)
	end

	if arg_186_1:isExcuteAdCircle() then
		table.insert(arg_186_0.excuteAdCircle_, arg_186_1)
	end

	if arg_186_1:isExcuteApCircle() then
		table.insert(arg_186_0.excuteApCircle_, arg_186_1)
	end

	if arg_186_1:isApImmortal() then
		table.insert(arg_186_0.apImmortalBuffs_, arg_186_1)
	end

	if arg_186_1:isAdImmortal() then
		table.insert(arg_186_0.adImmortalBuffs_, arg_186_1)
	end

	if arg_186_1:isImmuneControl() then
		table.insert(arg_186_0.immuneControlBuffs_, arg_186_1)
	end

	if arg_186_1:isAttackFriend() then
		table.insert(arg_186_0.ackFriendsBuffs_, arg_186_1)
		arg_186_0:updateTeamCache()
	end

	if arg_186_1:isAdBreakImmortal() then
		table.insert(arg_186_0.adBreakImmortalBuffs_, arg_186_1)
	end

	if arg_186_1:pause() then
		table.insert(arg_186_0.pauseBuffs_, arg_186_1)
	end

	if arg_186_1:isSleep() then
		table.insert(arg_186_0.sleepBuffs_, arg_186_1)
	end

	if arg_186_1:isHeroNeverDieBuff() then
		table.insert(arg_186_0.neverDieBuffs_, arg_186_1)
	end

	if arg_186_1:isForverNeverDie() then
		table.insert(arg_186_0.forverNeverDieBuffs_, arg_186_1)
	end

	if arg_186_1:isShieldBuff() then
		table.insert(arg_186_0.shieldBuffs_, arg_186_1)
	end

	if arg_186_1:isDHarmBuff() then
		table.insert(arg_186_0.dHarmBuffs_, arg_186_1)
	end

	if arg_186_1:isPossessed() then
		table.insert(arg_186_0.possessBuffs_, arg_186_1)
	end

	if arg_186_1:isSpGive() then
		table.insert(arg_186_0.spGiveBuffs_, arg_186_1)
	end

	if arg_186_1:getForceTarget() then
		table.insert(arg_186_0.forceTargetBuffs_, arg_186_1)
	end

	if arg_186_1:isInvalidMpIncrease() then
		table.insert(arg_186_0.invalidMpIncreaseBuffs_, arg_186_1)
	end

	if arg_186_1:isInvalidEnergySkill() then
		table.insert(arg_186_0.invalidEnergySkillBuffs_, arg_186_1)
	end

	if arg_186_1:isSkillDown() then
		table.insert(arg_186_0.skillDownBuff_, arg_186_1)
	end

	if arg_186_1:limitAttr() then
		table.insert(arg_186_0.limitAttrBuff_, arg_186_1)
	end

	if arg_186_1:isUseSkillCount() then
		arg_186_1.useSkillCount_ = var_0_15:useSkillCount(arg_186_1:getTableID())

		table.insert(arg_186_0.useSkillCount_, arg_186_1)
	end

	if arg_186_1:isIgnoreJianshang() then
		table.insert(arg_186_0.ignoreJianshang_, arg_186_1)
	end

	if arg_186_1:isIgnoreShield() then
		table.insert(arg_186_0.ignoreShield_, arg_186_1)
	end

	if arg_186_1:isChaos() then
		table.insert(arg_186_0.isChaos_, arg_186_1)
	end

	if arg_186_1:energyLimit() < 1 then
		arg_186_0.energyLimit_ = arg_186_1:energyLimit()
	end

	if arg_186_1:getAttrType() > 0 then
		arg_186_0.___attrCache[arg_186_1:getAttrType()] = nil

		if arg_186_1:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
			arg_186_0.___ackSpeed = nil
		end
	end

	if arg_186_1:getAttrType() == var_0_2.AttributeType.HP then
		local var_186_0 = 0
		local var_186_1 = 0
		local var_186_2, var_186_3 = arg_186_1:getAttr()

		if not var_186_3 then
			var_186_0 = var_186_0 + var_186_2
		else
			local var_186_4 = var_186_1 + var_186_2

			var_186_0 = arg_186_0:getHpLimit() * var_186_4
		end

		arg_186_0:setupHpLimit()

		hp = math.min(arg_186_0:getHpLimit(), arg_186_0:getHp() + var_186_0)
		hp = math.max(1, hp)

		arg_186_0:updateHp(hp)
	end

	if arg_186_0.mpBar_ and arg_186_0.avatarIndex_ then
		local var_186_5 = arg_186_1:getIconTypes()

		if #var_186_5 > 0 then
			local var_186_6 = {}

			for iter_186_0 = 1, #var_186_5 do
				var_186_6[iter_186_0] = 1
			end

			arg_186_0.bottomWnd:updateBuffIconShow(var_186_5, var_186_6, arg_186_0.avatarIndex_)
		end
	end

	arg_186_0.__debuffNum = nil
	arg_186_0.__gainBuffNum = nil

	arg_186_0:distributeBuffMove(arg_186_1)
end

function var_0_3.distributeBuffMove(arg_187_0, arg_187_1)
	if arg_187_0:isBreakImmortal() then
		return
	end

	if arg_187_1:getYx() > 0 and arg_187_0.buffMovePath_ and next(arg_187_0.buffMovePath_) then
		local var_187_0 = arg_187_1:getPath()

		for iter_187_0, iter_187_1 in pairs(var_187_0) do
			arg_187_0.buffMovePath_[iter_187_0] = arg_187_0.buffMovePath_[iter_187_0] or {
				0,
				0
			}
			arg_187_0.buffMovePath_[iter_187_0][1] = arg_187_0.buffMovePath_[iter_187_0][1] + var_187_0[iter_187_0][1]
			arg_187_0.buffMovePath_[iter_187_0][2] = arg_187_0.buffMovePath_[iter_187_0][2] + var_187_0[iter_187_0][2]
		end
	elseif arg_187_1:getYx() > 0 then
		arg_187_0.buffMovePath_ = arg_187_1:getPath()
	end
end

function var_0_3.buffAddAction(arg_188_0, arg_188_1)
	return
end

function var_0_3.specialBuffCheck(arg_189_0, arg_189_1)
	for iter_189_0, iter_189_1 in ipairs(arg_189_0.buffs_) do
		if var_0_15:type(iter_189_1:getTableID()) == var_0_2.BuffType.SPECIFIC and iter_189_1.fighter then
			iter_189_1.fighter:specialBuffExecute(arg_189_1)
		end
	end
end

function var_0_3.specialBuffExecute(arg_190_0, arg_190_1)
	return
end

function var_0_3.removeBuffs(arg_191_0, arg_191_1)
	if not arg_191_1 then
		return
	end

	for iter_191_0, iter_191_1 in ipairs(arg_191_0.selfTeam_) do
		if not iter_191_1:isDeath() then
			iter_191_1:removeBuffBySpecialHero(arg_191_1)
		end
	end

	for iter_191_2, iter_191_3 in ipairs(arg_191_0.sideTeam_) do
		if not iter_191_3:isDeath() then
			iter_191_3:removeBuffBySpecialHero(arg_191_1)
		end
	end

	if arg_191_0.showDHarmbuff_ == arg_191_1 then
		arg_191_0.showDHarmbuff_ = nil

		for iter_191_4, iter_191_5 in ipairs(arg_191_0:getBuffs()) do
			if iter_191_5:getDHarm() > 0 and iter_191_5 ~= arg_191_1 then
				arg_191_0.showDHarmbuff_ = iter_191_5
			end
		end

		arg_191_0.fighterModel:updateHeroHeaderView(var_0_1.ctx.battle.count, arg_191_0.showDHarmbuff_)
	end

	if arg_191_1.fighter then
		arg_191_1.fighter:buffRemoveAction(arg_191_1)
		arg_191_1.fighter:buffRemoveActionHunqi(arg_191_1)
	end

	if arg_191_0:getFighterModel() ~= nil then
		arg_191_0.fighterModel:removeBuffs({
			arg_191_1
		}, var_0_1.ctx.battle.count)
	end

	if arg_191_1:pause() then
		arg_191_0:pauseResume(arg_191_1)
	end

	var_0_0.table.removebyvalue(arg_191_0.buffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.isAffectedBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.isTeamAffectedBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.isInvisibleBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.fearBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.moveUnableBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.apUnableBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.adUnableBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.pugongOnlyBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.excuteAdCircle_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.excuteApCircle_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.apImmortalBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.adImmortalBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.immuneControlBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.ackFriendsBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.adBreakImmortalBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.pauseBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.sleepBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.neverDieBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.forverNeverDieBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.shieldBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.dHarmBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.possessBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.spGiveBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.forceTargetBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.invalidMpIncreaseBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.invalidEnergySkillBuffs_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.skillDownBuff_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.limitAttrBuff_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.useSkillCount_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.ignoreJianshang_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.ignoreShield_, arg_191_1)
	var_0_0.table.removebyvalue(arg_191_0.isChaos_, arg_191_1)

	if arg_191_1:energyLimit() < 1 then
		arg_191_0.energyLimit_ = 1
	end

	if arg_191_1:getAttrType() > 0 then
		arg_191_0.___attrCache[arg_191_1:getAttrType()] = nil

		if arg_191_1:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
			arg_191_0.___ackSpeed = nil
		end
	end

	if arg_191_1:getAttrType() == var_0_2.AttributeType.HP then
		arg_191_0:setupHpLimit()

		hp = math.min(arg_191_0:getHp(), arg_191_0:getHpLimit())

		arg_191_0:updateHp(hp)
	end

	if arg_191_0.mpBar_ and arg_191_0.avatarIndex_ then
		local var_191_0 = arg_191_1:getIconTypes()

		if #var_191_0 > 0 then
			local var_191_1 = {}

			for iter_191_6 = 1, #var_191_0 do
				var_191_1[iter_191_6] = -1
			end

			arg_191_0.bottomWnd:updateBuffIconShow(var_191_0, var_191_1, arg_191_0.avatarIndex_)
		end
	end

	if arg_191_1:isAttackFriend() then
		arg_191_0:updateTeamCache()
	elseif arg_191_1:isChaos() then
		arg_191_0:changeTeamCache()
	end

	arg_191_0.__debuffNum = nil
	arg_191_0.__gainBuffNum = nil
end

function var_0_3.removeBuffBySpecialHero(arg_192_0, arg_192_1)
	return
end

function var_0_3.buffRemoveAction(arg_193_0, arg_193_1)
	return
end

function var_0_3.deadForceRemoveSkill(arg_194_0)
	for iter_194_0, iter_194_1 in ipairs(arg_194_0.buffs_) do
		if iter_194_1:getType() == var_0_2.BuffType.Force_RemoveSkill and iter_194_1.fighter then
			iter_194_1.fighter:buffRemoveAction(iter_194_1)
		end
	end
end

function var_0_3.cleanAllBuffs(arg_195_0)
	if arg_195_0:getFighterModel() ~= nil then
		arg_195_0.fighterModel:cleanAllBuffs()
	end

	if arg_195_0.mpBar_ and arg_195_0.avatarIndex_ then
		arg_195_0.bottomWnd:updateBuffIconShow(nil, nil, arg_195_0.avatarIndex_, true, true)
	end

	arg_195_0.showDHarmbuff_ = nil
	arg_195_0.buffs_ = {}
	arg_195_0.isAffectedBuffs_ = {}
	arg_195_0.isTeamAffectedBuffs_ = {}
	arg_195_0.isInvisibleBuffs_ = {}
	arg_195_0.fearBuffs_ = {}
	arg_195_0.moveUnableBuffs_ = {}
	arg_195_0.apUnableBuffs_ = {}
	arg_195_0.adUnableBuffs_ = {}
	arg_195_0.pugongOnlyBuffs_ = {}
	arg_195_0.excuteAdCircle_ = {}
	arg_195_0.excuteApCircle_ = {}
	arg_195_0.apImmortalBuffs_ = {}
	arg_195_0.adImmortalBuffs_ = {}
	arg_195_0.immuneControlBuffs_ = {}
	arg_195_0.ackFriendsBuffs_ = {}
	arg_195_0.adBreakImmortalBuffs_ = {}
	arg_195_0.pauseBuffs_ = {}
	arg_195_0.sleepBuffs_ = {}
	arg_195_0.shieldBuffs_ = {}
	arg_195_0.dHarmBuffs_ = {}
	arg_195_0.neverDieBuffs_ = {}
	arg_195_0.forverNeverDieBuffs_ = {}
	arg_195_0.possessBuffs_ = {}
	arg_195_0.spGiveBuffs_ = {}
	arg_195_0.forceTargetBuffs_ = {}
	arg_195_0.skillDownBuff_ = {}
	arg_195_0.limitAttrBuff_ = {}
	arg_195_0.useSkillCount_ = {}
	arg_195_0.ignoreJianshang_ = {}
	arg_195_0.ignoreShield_ = {}
	arg_195_0.isChaos_ = {}
	arg_195_0.energyLimit_ = 1

	for iter_195_0 = #var_0_1.ctx.battle.globalBuffs, 1, -1 do
		local var_195_0 = var_0_1.ctx.battle.globalBuffs

		if var_195_0.fighter == arg_195_0 then
			table.remove(var_0_1.ctx.battle.globalBuffs, iter_195_0)
			var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, var_195_0:getAttrType())
			var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, var_195_0:getAttrType())
		end
	end

	for iter_195_1, iter_195_2 in ipairs(var_0_1.ctx.battle.globalBuffsA) do
		local var_195_1 = var_0_1.ctx.battle.globalBuffsA

		if var_195_1.fighter == arg_195_0 then
			table.remove(var_0_1.ctx.battle.globalBuffsA, iter_195_1)
			var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, var_195_1:getAttrType())
		end
	end

	for iter_195_3, iter_195_4 in ipairs(var_0_1.ctx.battle.globalBuffsB) do
		local var_195_2 = var_0_1.ctx.battle.globalBuffsB

		if var_195_2.fighter == arg_195_0 then
			var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, var_195_2:getAttrType())
			table.remove(var_0_1.ctx.battle.globalBuffsB, iter_195_3)
		end
	end
end

function var_0_3.isHasBuffByID(arg_196_0, arg_196_1)
	for iter_196_0, iter_196_1 in ipairs(arg_196_0.buffs_) do
		if iter_196_1:getTableID() == arg_196_1 then
			return true
		end
	end

	return false
end

function var_0_3.getBuffs(arg_197_0)
	return arg_197_0.buffs_
end

function var_0_3.getBuffByID(arg_198_0, arg_198_1)
	for iter_198_0, iter_198_1 in ipairs(arg_198_0.buffs_) do
		if iter_198_1:getTableID() == arg_198_1 then
			return iter_198_1
		end
	end
end

function var_0_3.getBuffsByID(arg_199_0, arg_199_1)
	local var_199_0 = {}

	for iter_199_0, iter_199_1 in ipairs(arg_199_0.buffs_) do
		if iter_199_1:getTableID() == arg_199_1 then
			table.insert(var_199_0, iter_199_1)
		end
	end

	return var_199_0
end

function var_0_3.removeBuffByID(arg_200_0, arg_200_1)
	for iter_200_0 = #arg_200_0.buffs_, 1, -1 do
		local var_200_0 = arg_200_0.buffs_[iter_200_0]

		if not var_200_0 then
			print("buff is nil ! BuffID = " .. arg_200_1)
			arg_200_0:buffErrorLog(arg_200_1)
		end

		if var_200_0 and var_200_0:getTableID() == arg_200_1 then
			arg_200_0:removeBuffs(var_200_0)
		end
	end
end

function var_0_3.removeImmortalBuff(arg_201_0)
	for iter_201_0 = #arg_201_0.buffs_, 1, -1 do
		local var_201_0 = arg_201_0.buffs_[iter_201_0]

		if var_201_0:isApImmortal() and var_201_0:isAdImmortal() then
			arg_201_0:removeBuffs(var_201_0)
		end
	end
end

function var_0_3.removeBreakImmortalBuff(arg_202_0)
	for iter_202_0 = #arg_202_0.buffs_, 1, -1 do
		local var_202_0 = arg_202_0.buffs_[iter_202_0]

		if var_202_0:isImmuneControl() then
			arg_202_0:removeBuffs(var_202_0)
		end
	end
end

function var_0_3.getDebuffNum(arg_203_0)
	if arg_203_0.__debuffNum then
		return arg_203_0.__debuffNum
	end

	arg_203_0.__debuffNum = 0

	for iter_203_0 = #arg_203_0.buffs_, 1, -1 do
		if arg_203_0.buffs_[iter_203_0]:getBuffForm() == var_0_2.BuffForm.DEBUFF then
			arg_203_0.__debuffNum = arg_203_0.__debuffNum + 1
		end
	end

	return arg_203_0.__debuffNum
end

function var_0_3.getGainBuffNum(arg_204_0)
	if arg_204_0.__gainBuffNum then
		return arg_204_0.__gainBuffNum
	end

	arg_204_0.__gainBuffNum = 0

	for iter_204_0 = #arg_204_0.buffs_, 1, -1 do
		if arg_204_0.buffs_[iter_204_0]:getBuffForm() == var_0_2.BuffForm.GAIN then
			arg_204_0.__gainBuffNum = arg_204_0.__gainBuffNum + 1
		end
	end

	return arg_204_0.__gainBuffNum
end

function var_0_3.updateTeamCache(arg_205_0)
	arg_205_0.selfTeam_ = arg_205_0.teamType_ == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	arg_205_0.sideTeam_ = arg_205_0.teamType_ ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
	arg_205_0.targetTeam_ = arg_205_0:isAttackFriend() and arg_205_0.selfTeam_ or arg_205_0.sideTeam_
end

function var_0_3.changeTeamCache(arg_206_0)
	if not arg_206_0:isChaos() then
		arg_206_0:updateTeamCache()
	else
		arg_206_0.selfTeam_ = arg_206_0.teamType_ == var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB
		arg_206_0.sideTeam_ = arg_206_0.teamType_ ~= var_0_2.TeamType.A and var_0_1.ctx.battle.teamA or var_0_1.ctx.battle.teamB

		if math.random(0, 1) == 1 then
			arg_206_0.targetTeam_ = arg_206_0.sideTeam_
		else
			arg_206_0.targetTeam_ = arg_206_0.selfTeam_
		end
	end

	arg_206_0:updateNearestTarget()
end

function var_0_3.setTeamType(arg_207_0, arg_207_1)
	arg_207_0.teamType_ = arg_207_1

	arg_207_0:updateTeamCache()
end

function var_0_3.setTeamTypeByIndex(arg_208_0, arg_208_1)
	local var_208_0 = string.sub(arg_208_1, 1, 1)

	if var_208_0 == "A" then
		arg_208_0.teamType_ = var_0_2.TeamType.A
	elseif var_208_0 == "B" then
		arg_208_0.teamType_ = var_0_2.TeamType.B
	end

	return arg_208_0.teamType_
end

function var_0_3.initModels(arg_209_0)
	if not arg_209_0.fighterModel then
		arg_209_0.fighterModel = var_0_9.new(arg_209_0.hero_, arg_209_0:getFighterModelScale())

		if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
			arg_209_0.fighterModel:retain()
		end
	end
end

function var_0_3.setFormationDelay(arg_210_0, arg_210_1, arg_210_2)
	arg_210_0.formationDelay_ = arg_210_1 or 0
	arg_210_0.formationWalk2Position_ = arg_210_2 or 100
end

function var_0_3.isDeath(arg_211_0)
	return arg_211_0.hp_ <= 0
end

function var_0_3.isWalked2Position(arg_212_0)
	if not arg_212_0.walk2Position_ then
		return true
	end

	if arg_212_0.isEnterFromLeft_ == nil and arg_212_0:getTeamType() == var_0_2.TeamType.A or arg_212_0.isEnterFromLeft_ then
		return arg_212_0:getX() > arg_212_0:getFormationWalkPosition()
	elseif not var_0_1.ctx.battle.isUnlimitBattle then
		return arg_212_0:getX() < var_0_2.STAGE_WIDTH - arg_212_0:getFormationWalkPosition() or not arg_212_0:getFlipX()
	else
		return arg_212_0:getX() < var_0_2.UNLIMIT_STAGE_WIDTH - arg_212_0:getFormationWalkPosition() or not arg_212_0:getFlipX()
	end
end

function var_0_3.canReborn(arg_213_0)
	return false
end

function var_0_3.hasReborned(arg_214_0)
	return false
end

function var_0_3.setupHpLimit(arg_215_0)
	arg_215_0.hpLimit_ = var_0_69(1, arg_215_0.isInArena_ and arg_215_0:getHeroHp() * var_0_2.tables.battleConfig.arenaHpIncrease or arg_215_0:getHeroHp())
end

function var_0_3.setupBattleAttrInfo(arg_216_0)
	arg_216_0.hero_:setupBattleAttrInfo()
end

function var_0_3.setGlobalBuffs(arg_217_0)
	local function var_217_0(arg_218_0, arg_218_1, arg_218_2)
		local var_218_0 = {}

		for iter_218_0, iter_218_1 in ipairs(arg_218_0) do
			local var_218_1 = var_0_4.new({
				tableID = iter_218_1,
				start = var_0_1.ctx.battle.count,
				level = arg_218_2,
				skillID = arg_218_1,
				fighter = arg_217_0
			})

			var_218_1:setYongJiu()
			table.insert(var_218_0, var_218_1)
		end

		return var_218_0
	end

	local var_217_1 = arg_217_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB
	local var_217_2 = arg_217_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsB or var_0_1.ctx.battle.globalBuffsA
	local var_217_3 = arg_217_0:buffSkill()

	for iter_217_0, iter_217_1 in pairs(var_217_3) do
		if arg_217_0:getSkillLevelByID(iter_217_1) > 0 then
			local var_217_4 = var_0_12:skillType(iter_217_1)
			local var_217_5 = var_217_0(var_0_12:buffs(iter_217_1), iter_217_1, arg_217_0:getSkillLevelByID(iter_217_1))

			if var_217_4 == var_0_2.SkillType.BUFF_ALL then
				for iter_217_2, iter_217_3 in ipairs(var_217_5) do
					table.insert(var_0_1.ctx.battle.globalBuffs, iter_217_3)
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_217_3:getAttrType())
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_217_3:getAttrType())
				end
			elseif var_217_4 == var_0_2.SkillType.BUFF_ENEMY and not var_0_1.ctx.battle.isActivity then
				for iter_217_4, iter_217_5 in ipairs(var_217_5) do
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamB, iter_217_5:getAttrType())
					table.insert(var_217_2, iter_217_5)
				end
			elseif var_217_4 == var_0_2.SkillType.BUFF_FRIEND then
				for iter_217_6, iter_217_7 in ipairs(var_217_5) do
					var_0_1.ctx.battle.clearAttrCache(var_0_1.ctx.battle.teamA, iter_217_7:getAttrType())
					table.insert(var_217_1, iter_217_7)
				end
			elseif var_217_4 == var_0_2.SkillType.SELF_FUNCTION_BUFF then
				for iter_217_8, iter_217_9 in ipairs(var_217_5) do
					iter_217_9.target = arg_217_0
				end

				arg_217_0:addBuffs(var_217_5)
			end
		end
	end
end

function var_0_3.getDHarmBuff(arg_219_0, arg_219_1, arg_219_2, arg_219_3)
	local var_219_0 = arg_219_1
	local var_219_1 = 0
	local var_219_2 = false

	for iter_219_0 = #arg_219_0.buffs_, 1, -1 do
		local var_219_3 = arg_219_0.buffs_[iter_219_0]
		local var_219_4 = var_0_0.clone(var_219_0)

		if var_219_3:getDHarm() > 0 and (var_219_3:dHarmType() == arg_219_2 or var_219_3:dHarmType() == var_0_2.HarmType.All) and not var_219_3:isDHarmLast() then
			if var_219_0 == 0 then
				return 0, 0, true
			end

			var_219_0 = var_219_3:setDHarm(var_219_0)

			if var_219_3:getDHarm() == 0 and var_219_3.fighter then
				var_219_3.fighter:dHarmBuffBreakFeedback(arg_219_0, var_219_3, arg_219_3)
			end

			if var_219_3.fighter and not var_219_3.fighter:isDeath() then
				var_219_3.fighter:dHarmBuffFeedback(var_219_3, arg_219_0)
			end

			if var_219_3:harmToHP() > 0 then
				var_219_1 = var_219_1 + var_219_3:harmToHP() * (var_219_4 - var_219_0)
			end

			if var_219_0 == 0 then
				return var_219_0, var_219_1, true
			end

			var_219_2 = true
		end
	end

	return var_219_0, var_219_1, var_219_2
end

function var_0_3.getLastDHarmBuff(arg_220_0, arg_220_1, arg_220_2)
	local var_220_0 = arg_220_1

	for iter_220_0 = #arg_220_0.buffs_, 1, -1 do
		local var_220_1 = arg_220_0.buffs_[iter_220_0]

		if var_220_1:getDHarm() > 0 and (var_220_1:dHarmType() == arg_220_2 or var_220_1:dHarmType() == var_0_2.HarmType.All) and var_220_1:isDHarmLast() then
			var_220_0 = var_220_1:setDHarm(var_220_0)

			if var_220_0 == 0 then
				break
			end
		end
	end

	return var_220_0
end

function var_0_3.buffHarmFeedBack(arg_221_0, arg_221_1)
	return
end

function var_0_3.applyBuffHarm(arg_222_0)
	local var_222_0 = 0
	local var_222_1 = 0
	local var_222_2 = 0
	local var_222_3

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		var_222_0, var_222_1, var_222_2 = unpack(arg_222_0.reportBuffHarms_[tostring(var_0_1.ctx.battle.count)] or {
			0,
			0,
			0
		})
	else
		local function var_222_4(arg_223_0)
			for iter_223_0 = #arg_223_0, 1, -1 do
				local var_223_0 = arg_223_0[iter_223_0]

				if var_223_0:getType() == var_0_2.BuffType.CONTINUE_HARM and not arg_222_0:isImmortal() then
					local var_223_1 = var_223_0:getHarm() * var_223_0.fighter:getBuffHarmRate()

					var_222_0 = var_222_0 + var_223_1
					var_222_3 = var_223_0.fighter

					if var_223_0:getHarm() > 0 and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						var_222_3:updateHarms(var_223_1)
						arg_222_0:updateBearHarms(var_223_1)
						var_222_3:buffHarmFeedBack(var_223_1)
					end
				elseif var_223_0:getType() == var_0_2.BuffType.GAIN or var_223_0:getType() == var_0_2.BuffType.REVIVIE then
					if var_0_1.ctx.battle.isActivity and not var_223_0.fighter:isMainRole() then
						-- block empty
					else
						var_222_1 = var_222_1 + var_223_0:getHarm()
					end
				elseif var_223_0:getType() == var_0_2.BuffType.ENERGY_CHANGE then
					var_222_2 = var_222_2 + var_223_0:getMana()
				end

				if var_0_1.ctx.battle.infoListener.buff_harm then
					table.insert(var_0_1.ctx.battle.infoListener.buff_harm, {
						target = arg_222_0,
						harm = var_222_0,
						cure = var_222_1,
						mp = var_222_2,
						buff = var_223_0
					})
				end
			end
		end

		var_222_4(arg_222_0.buffs_)
		var_222_4(arg_222_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB)

		var_222_1 = var_222_1 * arg_222_0:getDCureRate()

		if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD and arg_222_0:getTeamType() == var_0_2.TeamType.B then
			var_222_1 = 0
		end

		arg_222_0.records_.buff_harms[tostring(var_0_1.ctx.battle.count)] = {
			var_222_0,
			var_222_1,
			var_222_2
		}
	end

	if var_222_1 == 0 and var_222_0 == 0 and var_222_2 == 0 then
		return
	end

	var_222_0, var_222_1, var_222_2 = arg_222_0:updateBuffHarm(arg_222_0.buffs_, var_222_0, var_222_1, var_222_2)

	for iter_222_0, iter_222_1 in ipairs(arg_222_0.selfTeam_) do
		if not iter_222_1:isDeath() then
			var_222_0, var_222_1, var_222_2 = iter_222_1:updateBuffDataBySpecialHero(arg_222_0.buffs_, var_222_0, var_222_1, var_222_2)
		end
	end

	for iter_222_2, iter_222_3 in ipairs(arg_222_0.sideTeam_) do
		if not iter_222_3:isDeath() then
			var_222_0, var_222_1, var_222_2 = iter_222_3:updateBuffDataBySpecialHero(arg_222_0.buffs_, var_222_0, var_222_1, var_222_2)
		end
	end

	local var_222_5 = var_0_69(0, arg_222_0:getHp() - var_222_0 + var_222_1)

	if var_222_1 - var_222_0 > 0 then
		var_222_5 = var_0_68(arg_222_0:getHp() - var_222_0 + var_222_1, arg_222_0:getHpLimit())
	end

	if var_222_1 ~= 0 then
		arg_222_0.cureHp = arg_222_0.cureHp + var_222_1
	end

	if var_222_0 - var_222_1 > 0 and next(arg_222_0.shieldBuffs_) then
		local var_222_6 = arg_222_0.shieldBuffs_[1]
		local var_222_7 = arg_222_0.shieldBuffs_[1].fighter
		local var_222_8 = var_222_6:getShieldNum() - 1

		if var_222_0 - var_222_1 > var_222_6:getShieldMaxHarm() then
			var_222_5 = var_0_69(0, arg_222_0:getHp() - var_222_0 + var_222_1 + var_222_6:getShieldMaxHarm())

			arg_222_0:updateHp(var_222_5)
		end

		if var_222_8 <= 0 then
			arg_222_0:removeBuffByID(var_222_6:getTableID())
		else
			var_222_6:setShieldNum(var_222_8)
		end

		var_222_7:shieldFeedBack(arg_222_0, var_222_6)
	else
		arg_222_0:updateHp(var_222_5)
	end

	arg_222_0:updateEnergyTo(arg_222_0:getEnergy() + var_222_2)
	arg_222_0:setOriHurt(var_222_0)

	return var_222_3
end

function var_0_3.updateBuffHarm(arg_224_0, arg_224_1, arg_224_2, arg_224_3, arg_224_4)
	return arg_224_2, arg_224_3, arg_224_4
end

function var_0_3.updateBuffDataBySpecialHero(arg_225_0, arg_225_1, arg_225_2, arg_225_3, arg_225_4)
	return arg_225_2, arg_225_3, arg_225_4
end

function var_0_3.checkEnergySkill(arg_226_0)
	if var_0_1.ctx.battle.battleType == var_0_2.BattleType.ReplayReport then
		return false
	end

	if arg_226_0:isDeath() then
		return false
	end

	if arg_226_0.energy_ < arg_226_0:energyDecimalBase() then
		return false
	end

	if arg_226_0:getDelaySkill() > var_0_1.ctx.battle.count then
		return false
	end

	if arg_226_0.walk2Position_ then
		return false
	end

	if arg_226_0:isBattleUnable() then
		return false
	end

	if arg_226_0:isApUnable() and (var_0_12:type(arg_226_0:getEnergySkillID()) == var_0_2.AttackType.AP or var_0_12:type(arg_226_0:getEnergySkillID()) == var_0_2.AttackType.CURE) then
		return false
	end

	if arg_226_0:isAdUnable() and var_0_12:type(arg_226_0:getEnergySkillID()) == var_0_2.AttackType.AD then
		return false
	end

	if arg_226_0.isEnergySkill_ and arg_226_0:isCreatingUnits() then
		return false
	end

	if arg_226_0:isAutoFighter() and arg_226_0:isInSkillRoll() then
		return false
	end

	if arg_226_0:isPugongOnly() then
		return false
	end

	if arg_226_0:isInvalidEnergySkill() then
		return false
	end

	if not arg_226_0:getNearestTarget() then
		return false
	end

	local var_226_0 = var_0_12:distance(arg_226_0:getEnergySkillID())

	if var_226_0 > 0 and var_226_0 < var_0_70(arg_226_0:getNearestTarget():getX() - arg_226_0:getX()) then
		return false
	end

	if arg_226_0.leftInterval_ > 0 and arg_226_0.arenaEnergyFull_ ~= true and (var_0_2.CampaignType.ARENA == var_0_1.ctx.battle.campaignType or var_0_2.CampaignType.SUPER_ARENA == var_0_1.ctx.battle.campaignType) then
		return false
	end

	if var_0_1.ctx.battle.isActivity and not arg_226_0:isMainRole() then
		return false
	end

	return true
end

function var_0_3.isAutoFighter(arg_227_0)
	if arg_227_0:getSummonType() == var_0_2.summonMonsterType.Copy and arg_227_0.summonAutoFight_ then
		return true
	end

	if arg_227_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.autoA then
		return true
	elseif arg_227_0:getTeamType() == var_0_2.TeamType.B and var_0_1.ctx.battle.autoB then
		return true
	end

	return false
end

function var_0_3.setSummonAutoFight(arg_228_0, arg_228_1)
	arg_228_0.summonAutoFight_ = arg_228_1
end

function var_0_3.setAvatar(arg_229_0, arg_229_1, arg_229_2, arg_229_3, arg_229_4)
	if not arg_229_1 then
		return
	end

	arg_229_0.avatar_ = arg_229_1
	arg_229_0.hpBar_ = arg_229_2
	arg_229_0.mpBar_ = arg_229_3

	arg_229_0:updateHpBar(true)

	arg_229_0.avatarIndex_ = arg_229_4
end

function var_0_3.clickAvatar(arg_230_0, arg_230_1)
	return
end

function var_0_3.setFormation(arg_231_0, arg_231_1, arg_231_2, arg_231_3, arg_231_4)
	local var_231_0 = arg_231_4 and arg_231_4 == var_0_2.Direction.Left or arg_231_0:getTeamType() == var_0_2.TeamType.A

	if var_231_0 then
		arg_231_0:x(-160 * (arg_231_1 - arg_231_2))
		arg_231_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_231_3 - 90 * ((arg_231_1 - arg_231_2 - 1) % 2))
	else
		arg_231_0:x(var_0_2.STAGE_WIDTH + 160 * (arg_231_1 - arg_231_2))
		arg_231_0:y(var_0_2.STAGE_HEIGHT / 2 - 50 + arg_231_3 - 90 * ((arg_231_1 - arg_231_2 - 1) % 2))
	end

	arg_231_0.isEnterFromLeft_ = var_231_0

	return arg_231_2
end

function var_0_3.clearResource(arg_232_0)
	for iter_232_0, iter_232_1 in pairs(arg_232_0.applyUnits_) do
		if iter_232_1.resource and var_0_1.ctx.battle.isReleased(iter_232_1.resource) ~= true then
			iter_232_1.resource:removeSelf()

			iter_232_1.resource = nil
		elseif iter_232_1.resource then
			iter_232_1.resource = nil
		end
	end

	for iter_232_2, iter_232_3 in ipairs(arg_232_0.moveAttackUnits_) do
		if iter_232_3.resource and var_0_1.ctx.battle.isReleased(iter_232_3.resource) ~= true then
			iter_232_3.resource:removeSelf()

			iter_232_3.resource = nil
		elseif iter_232_3.resource then
			iter_232_3.resource = nil
		end
	end

	for iter_232_4, iter_232_5 in ipairs(arg_232_0.moveUnits_) do
		if iter_232_5.resource and var_0_1.ctx.battle.isReleased(iter_232_5.resource) ~= true then
			iter_232_5.resource:removeSelf()

			iter_232_5.resource = nil
		elseif iter_232_5.resource then
			iter_232_5.resource = nil
		end
	end

	arg_232_0:clearBuffHalo()
end

function var_0_3.moveUnitArrive(arg_233_0, arg_233_1)
	if arg_233_1.resource then
		arg_233_1.resource:stop()
	end

	arg_233_1:arrive()

	if arg_233_1:getAreaResource() then
		local var_233_0 = arg_233_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_233_1.fighter:getY() or arg_233_1.desY_
		local var_233_1 = arg_233_1.unitEffectType == var_0_2.UnitEffectType.SelfFootPos and arg_233_1.fighter:getX() or arg_233_1.desX_

		arg_233_1:getAreaResource():addTo(var_0_1.ctx.battle.unitLayer)
		arg_233_1:getAreaResource():pos(var_233_1, var_233_0)
		arg_233_1:getAreaResource():playOnce()
		arg_233_1:getAreaResource():flipX(arg_233_1.fighter:getX() > arg_233_1.desX_)
	end

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_233_2 = arg_233_1:getReportUnits()

		for iter_233_0, iter_233_1 in ipairs(var_233_2) do
			table.insert(arg_233_0.applyUnits_, iter_233_1)
		end
	else
		local var_233_3 = arg_233_0:getTargets(arg_233_1.skillID, arg_233_1)

		if next(var_233_3) then
			local var_233_4 = arg_233_1:createAttacks(var_233_3)

			for iter_233_2, iter_233_3 in ipairs(var_233_4) do
				table.insert(arg_233_0.applyUnits_, iter_233_3)
			end
		end
	end
end

function var_0_3.acttionInBlack(arg_234_0)
	return arg_234_0.acttionInBlack_ or not var_0_1.ctx.battle.isEnergySkilling
end

function var_0_3.playShanbi(arg_235_0, arg_235_1)
	arg_235_0.fighterModel:playFloatText({
		var_0_2.BattleFloatType.MISS
	}, arg_235_0:getTeamType())
end

function var_0_3.showAwardActions(arg_236_0)
	local function var_236_0()
		if not arg_236_0 or tolua.isnull(var_0_1.ctx.battle.playerLayer) or next(arg_236_0.dropItems_ or {}) == nil then
			return
		end

		for iter_237_0, iter_237_1 in ipairs(arg_236_0.dropItems_ or {}) do
			arg_236_0:showAwardAction(iter_237_1)
		end

		local var_237_0 = require("framework.scheduler")
		local var_237_1 = 0
		local var_237_2 = math.min(#arg_236_0.dropItems_, 3)

		arg_236_0.handle_ = var_237_0.scheduleGlobal(function()
			var_237_1 = var_237_1 + 1

			if var_237_1 > var_237_2 and arg_236_0.handle_ then
				var_237_0.unscheduleGlobal(arg_236_0.handle_)

				return
			end

			var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.sound:getSound("battle_loot"))
		end, 0.2)
	end

	var_0_1.ctx.battle.playerLayer:performWithDelay(var_0_0.handler(arg_236_0, var_236_0), 0.6)
end

function var_0_3.showAwardAction(arg_239_0, arg_239_1, arg_239_2)
	if arg_239_1.isShow then
		return
	end

	if arg_239_2 then
		var_0_1.ctx.battle.pushSoundQueue(var_0_2.tables.sound:getSound("battle_loot"))
	end

	arg_239_0.topWnd:getAwardLabel():setString(var_0_1.ctx.battle.dropAwardCount)

	local var_239_0 = arg_239_1.sprite
	local var_239_1 = display.newNode()

	var_239_1:size(100, 100)
	var_0_2.setItemBorder(var_239_1, arg_239_1:getTableID())
	var_239_1:setAnchorPoint(cc.p(0, 0))
	var_239_1:addTo(arg_239_0.topWnd, 10)
	var_239_1:setScale(0)

	local var_239_2 = arg_239_0.topWnd:convertToNodeSpace(cc.p(var_239_0:getPosition()))

	var_239_1:setPosition(var_239_2)

	local var_239_3 = cc.Spawn:create(cc.ScaleTo:create(0.2, 1), cc.MoveBy:create(0.2, cc.p(0, 50)))
	local var_239_4 = cc.Spawn:create(cc.ScaleTo:create(0.5, 0.2), cc.MoveTo:create(0.5, cc.p(arg_239_0.topWnd:getAwardLabel():getPosition())))
	local var_239_5 = cc.Sequence:create(var_239_3, cc.DelayTime:create(0.3), var_239_4)

	var_239_1:runActionOnce(var_239_5, true)
	var_239_0:removeSelf()

	arg_239_1.isShow = true
end

function var_0_3.writeReport(arg_240_0)
	local var_240_0 = {
		skills = {}
	}

	for iter_240_0, iter_240_1 in ipairs(arg_240_0.records_.skills) do
		table.insert(var_240_0.skills, iter_240_1:writeReport())
	end

	var_240_0.special_skills = {}

	for iter_240_2, iter_240_3 in ipairs(arg_240_0.records_.special_skills) do
		table.insert(var_240_0.special_skills, iter_240_3:writeReport())
	end

	var_240_0.energy = arg_240_0.records_.energy
	var_240_0.move = arg_240_0.records_.move
	var_240_0.buff_move = arg_240_0.records_.buff_move
	var_240_0.hero = arg_240_0.hero_:toParams()
	var_240_0.walk_state = arg_240_0.records_.walk_state
	var_240_0.die_count = arg_240_0.records_.die_count
	var_240_0.special_units = {}

	for iter_240_4, iter_240_5 in ipairs(arg_240_0.records_.special_units) do
		table.insert(var_240_0.special_units, iter_240_5:writeReport())
	end

	var_240_0.summon_type = arg_240_0.summonType_
	var_240_0.born_count = arg_240_0.bornCount_
	var_240_0.harms = arg_240_0.harms
	var_240_0.bear_harms = arg_240_0.bearHarms
	var_240_0.kill_count = arg_240_0.killCount
	var_240_0.attribute_value = arg_240_0:getAttributeValues()
	var_240_0.skill_table_value = arg_240_0:getSkillTableValues()
	var_240_0.health_status = arg_240_0.healthStatus
	var_240_0.buff_harms = arg_240_0.records_.buff_harms
	var_240_0.break_stun = arg_240_0.records_.break_stun
	var_240_0.skill_course_buff = arg_240_0.records_.skill_course_buff
	var_240_0.init_buff = arg_240_0.records_.init_buff
	var_240_0.is_main_role = arg_240_0:isMainRole() and 1 or 0

	if arg_240_0.summoner then
		var_240_0.summoner_fighter_index = arg_240_0.summoner.fighterIndex
	end

	return var_240_0
end

function var_0_3.setupReport(arg_241_0, arg_241_1)
	arg_241_0.skillCourseBuff_ = arg_241_1.skill_course_buff
	arg_241_0.breakStun_ = arg_241_1.break_stun or {}
	arg_241_0.reportMoveX_ = arg_241_1.move.x
	arg_241_0.reportMoveY_ = arg_241_1.move.y
	arg_241_0.reportBuffMoveX_ = arg_241_1.buff_move.x
	arg_241_0.reportBuffMoveY_ = arg_241_1.buff_move.y
	arg_241_0.reportWalkState_ = arg_241_1.walk_state
	arg_241_0.reportEnergy_ = arg_241_1.energy
	arg_241_0.reportDieCount_ = tonumber(arg_241_1.die_count)
	arg_241_0.bornCount_ = tonumber(arg_241_1.born_count) or 0
	arg_241_0.harms = tonumber(arg_241_1.harms)
	arg_241_0.bearHarms = tonumber(arg_241_1.bear_harms)
	arg_241_0.reportBuffHarms_ = arg_241_1.buff_harms or {}

	arg_241_0:getReportSkills(arg_241_1.skills or {})
	arg_241_0:getReportSpecialSkills(arg_241_1.special_skills or {})
	arg_241_0:getReportSpecialUnits(arg_241_1.special_units)

	arg_241_0.initBuffRecord = arg_241_1.init_buff
	arg_241_0.reportSummonType = arg_241_1.summon_type
	arg_241_0.reportSummonerIndex = arg_241_1.summoner_fighter_index
end

function var_0_3.getReportSkills(arg_242_0, arg_242_1)
	local function var_242_0(arg_243_0)
		local var_243_0 = var_0_5.new({
			fighter = arg_242_0,
			skillID = arg_243_0.rootID_
		})

		var_243_0:readReport(arg_243_0)

		return var_243_0
	end

	arg_242_0.reportSkills_ = {}

	for iter_242_0, iter_242_1 in ipairs(arg_242_1) do
		table.insert(arg_242_0.reportSkills_, var_242_0(iter_242_1))
	end
end

function var_0_3.getReportSpecialSkills(arg_244_0, arg_244_1)
	local function var_244_0(arg_245_0)
		local var_245_0 = var_0_5.new({
			fighter = arg_244_0,
			skillID = arg_245_0.rootID_
		})

		var_245_0:readReport(arg_245_0)

		return var_245_0
	end

	arg_244_0.reportSpecialSkills_ = {}

	for iter_244_0, iter_244_1 in ipairs(arg_244_1) do
		table.insert(arg_244_0.reportSpecialSkills_, var_244_0(iter_244_1))
	end
end

function var_0_3.getReportSpecialUnits(arg_246_0, arg_246_1)
	arg_246_0.reportUnits_ = {}

	for iter_246_0, iter_246_1 in ipairs(arg_246_1) do
		local var_246_0 = {
			skillID = tonumber(iter_246_1.skillID),
			fighter = arg_246_0,
			target = var_0_1.ctx.battle.getFighter(iter_246_1.initTarget),
			count = tonumber(iter_246_1.start),
			reportdata = iter_246_1
		}
		local var_246_1 = var_0_7.new(var_246_0)

		table.insert(arg_246_0.reportUnits_, var_246_1)
		table.insert(arg_246_0.applyUnits_, var_246_1)
	end
end

function var_0_3.setupDrop(arg_247_0)
	if arg_247_0.hero_.guildDrop and next(arg_247_0.hero_.guildDrop) then
		arg_247_0.dropItems_ = arg_247_0.dropItems_ or {}

		for iter_247_0, iter_247_1 in ipairs(arg_247_0.hero_.guildDrop) do
			table.insert(arg_247_0.dropItems_, iter_247_1)
		end
	end

	if arg_247_0:isDeath() then
		arg_247_0.dropItems_ = {}
	end
end

function var_0_3.isBoss(arg_248_0)
	return false
end

function var_0_3.unitCollisionBreak(arg_249_0, arg_249_1)
	return
end

function var_0_3.updateEnergyByCount(arg_250_0)
	if var_0_1.ctx.battle.count % 30 > 0 then
		return
	end

	arg_250_0:updateEnergyBy(arg_250_0:getCountReMp())
end

function var_0_3.getNearestTarget(arg_251_0)
	return arg_251_0.nearestTarget_
end

function var_0_3.getLeftInterval(arg_252_0)
	return arg_252_0.leftInterval_
end

function var_0_3.getEnergySkillID(arg_253_0)
	return tonumber(arg_253_0.energySkillID_)
end

function var_0_3.getX(arg_254_0)
	local var_254_0, var_254_1 = arg_254_0:getPos()

	return var_254_0
end

function var_0_3.getY(arg_255_0)
	local var_255_0, var_255_1 = arg_255_0:getPos()

	return var_255_1
end

function var_0_3.getPos(arg_256_0)
	local var_256_0, var_256_1 = arg_256_0.fighterModel:getPosition()

	return var_256_0, var_256_1
end

function var_0_3.pos(arg_257_0, arg_257_1, arg_257_2)
	if var_0_1.ctx.battle.infoListener.move_info then
		table.insert(var_0_1.ctx.battle.infoListener.move_info, {
			fighter = arg_257_0,
			x = arg_257_1 - arg_257_0:getX(),
			y = arg_257_2 - arg_257_0:getY()
		})
	end

	arg_257_0.fighterModel:pos(arg_257_1, arg_257_2)
end

function var_0_3.x(arg_258_0, arg_258_1)
	if var_0_1.ctx.battle.infoListener.move_info then
		table.insert(var_0_1.ctx.battle.infoListener.move_info, {
			fighter = arg_258_0,
			x = arg_258_1 - arg_258_0:getX()
		})
	end

	arg_258_0.fighterModel:x(arg_258_1)
end

function var_0_3.y(arg_259_0, arg_259_1)
	if var_0_1.ctx.battle.infoListener.move_info then
		table.insert(var_0_1.ctx.battle.infoListener.move_info, {
			fighter = arg_259_0,
			y = arg_259_1 - arg_259_0:getY()
		})
	end

	arg_259_0.fighterModel:y(arg_259_1)
end

function var_0_3.moveByX(arg_260_0, arg_260_1, arg_260_2, arg_260_3)
	local var_260_0, var_260_1 = arg_260_0.fighterModel:getPosition()

	if arg_260_2 ~= false then
		arg_260_0.records_.move.x[tostring(var_0_1.ctx.battle.count)] = var_260_0 + arg_260_1
	elseif arg_260_3 then
		arg_260_0.records_.buff_move.x[tostring(var_0_1.ctx.battle.count)] = var_260_0 + arg_260_1
	end

	arg_260_0.fighterModel:pos(var_260_0 + arg_260_1, var_260_1)

	if var_0_1.ctx.battle.infoListener.move_info then
		table.insert(var_0_1.ctx.battle.infoListener.move_info, {
			fighter = arg_260_0,
			x = arg_260_1,
			isBuff = arg_260_3
		})
	end
end

function var_0_3.moveByY(arg_261_0, arg_261_1, arg_261_2, arg_261_3)
	local var_261_0, var_261_1 = arg_261_0.fighterModel:getPosition()

	if arg_261_2 ~= false then
		arg_261_0.records_.move.y[tostring(var_0_1.ctx.battle.count)] = var_261_1 + arg_261_1
	elseif arg_261_3 then
		arg_261_0.records_.buff_move.y[tostring(var_0_1.ctx.battle.count)] = var_261_1 + arg_261_1
	end

	arg_261_0.fighterModel:pos(var_261_0, var_261_1 + arg_261_1)

	if var_0_1.ctx.battle.infoListener.move_info then
		table.insert(var_0_1.ctx.battle.infoListener.move_info, {
			fighter = arg_261_0,
			y = arg_261_1,
			isBuff = arg_261_3
		})
	end
end

function var_0_3.getFlipX(arg_262_0)
	return arg_262_0:getFighterModel():getFlipX()
end

function var_0_3.flipX(arg_263_0, arg_263_1)
	if var_0_1.ctx.battle.infoListener.flip_info then
		table.insert(var_0_1.ctx.battle.infoListener.flip_info, arg_263_0)
	end

	arg_263_0:getFighterModel():flipX(arg_263_1)
end

function var_0_3.getInterval(arg_264_0)
	if var_0_1.ctx.battle.isActivity and not arg_264_0:isMainRole() then
		return var_0_19.activityArenaPartnerInterval
	end

	return var_0_13:interval(arg_264_0:getTableID())
end

function var_0_3.getTableID(arg_265_0)
	return arg_265_0.partnerID_
end

function var_0_3.getModelID(arg_266_0)
	return arg_266_0.hero_:getModelID()
end

function var_0_3.getSkillModelID(arg_267_0)
	return arg_267_0.hero_:getOldModelID()
end

function var_0_3.getTeamType(arg_268_0)
	return arg_268_0.teamType_
end

function var_0_3.getFighterModelScale(arg_269_0)
	return var_0_14:scale(arg_269_0:getModelID()) * arg_269_0.heroScale
end

function var_0_3.setHeroScale(arg_270_0, arg_270_1)
	arg_270_0.heroScale = arg_270_1
end

function var_0_3.getFighterModel(arg_271_0)
	if not arg_271_0.fighterModel then
		return
	end

	return arg_271_0.fighterModel:getHeroAnimation()
end

function var_0_3.getCurrentSkillType(arg_272_0)
	return var_0_12:type(arg_272_0:getOrbOfFrontSkill())
end

function var_0_3.getScope(arg_273_0)
	return var_0_12:scope(arg_273_0:getOrbOfFrontSkill())
end

function var_0_3.getEnergySkillPreTime(arg_274_0)
	return var_0_12:pretime(arg_274_0:getEnergySkillID())
end

function var_0_3.getScale(arg_275_0)
	return arg_275_0.hero_:getScale()
end

function var_0_3.getLevel(arg_276_0)
	return arg_276_0.level_
end

function var_0_3.getDistance(arg_277_0)
	return var_0_13:distance(arg_277_0:getTableID())
end

function var_0_3.getName(arg_278_0)
	return arg_278_0.hero_:getName()
end

function var_0_3.getAvatar(arg_279_0)
	if var_0_1.ctx.battle.isReleased(arg_279_0.avatar_) then
		arg_279_0.avatar_ = nil
	end

	return arg_279_0.avatar_
end

function var_0_3.manualType(arg_280_0)
	return var_0_12:manualType(arg_280_0:getEnergySkillID())
end

function var_0_3.getSkillByColor(arg_281_0, arg_281_1)
	return arg_281_0.hero_:getSkillId(arg_281_1)
end

function var_0_3.getAncestor(arg_282_0, arg_282_1)
	if not arg_282_0.ancestorCount then
		arg_282_0.ancestorCount = 0
	elseif arg_282_0.ancestorCount >= 10 then
		return arg_282_1
	else
		arg_282_0.ancestorCount = arg_282_0.ancestorCount + 1

		if var_0_12:father(arg_282_1) > 0 and var_0_12:father(arg_282_1) ~= arg_282_1 then
			arg_282_1 = var_0_12:father(arg_282_1)

			return arg_282_0:getAncestor(arg_282_1)
		else
			arg_282_0.ancestorCount = 0

			return arg_282_1
		end
	end
end

function var_0_3.getSkillColorByID(arg_283_0, arg_283_1)
	local var_283_0 = arg_283_0:getAncestor(arg_283_1)

	for iter_283_0 = 1, var_0_2.SKILL_INDEX.TotalNum do
		local var_283_1 = arg_283_0:getSkillByColor(iter_283_0)

		if var_283_1 and var_283_0 == var_283_1 then
			return iter_283_0
		end
	end

	return 0
end

function var_0_3.getSkillLevelByColor(arg_284_0, arg_284_1)
	local var_284_0 = arg_284_0.hero_:getSkillId(arg_284_1)

	if var_0_1.ctx.battle.isActivity and (not var_284_0 or not arg_284_0:isMainRole() and var_0_12:snowmanUsable(var_284_0) <= 0) then
		return 0
	end

	local var_284_1 = arg_284_0.skillLevelByColor_[arg_284_1]

	if var_284_1 and var_284_1 > 0 then
		for iter_284_0, iter_284_1 in ipairs(arg_284_0.skillDownBuff_) do
			var_284_1 = math.max(1, var_284_1 - math.ceil(iter_284_1:getLevel() / var_0_15:skillDownReq(iter_284_1:getTableID())))
		end
	end

	return var_284_1 or 0
end

function var_0_3.getSummonType(arg_285_0)
	return arg_285_0.summonType_
end

function var_0_3.buffSkill(arg_286_0)
	return var_0_13:buffSkill(arg_286_0:getTableID())
end

function var_0_3.getPugongID(arg_287_0)
	return var_0_13:pugong(arg_287_0:getTableID())
end

function var_0_3.dodge(arg_288_0, arg_288_1, arg_288_2, arg_288_3, arg_288_4, arg_288_5, arg_288_6, arg_288_7)
	return false
end

function var_0_3.getHurtHp(arg_289_0)
	return arg_289_0.hurtHp
end

function var_0_3.getCureHp(arg_290_0)
	return arg_290_0.cureHp
end

function var_0_3.setHurtHp(arg_291_0, arg_291_1)
	arg_291_0.hurtHp = arg_291_1
end

function var_0_3.setCureHp(arg_292_0, arg_292_1)
	arg_292_0.cureHp = arg_292_1
end

function var_0_3.setOriHurt(arg_293_0, arg_293_1)
	if not arg_293_0.oriHurt then
		arg_293_0.oriHurt = arg_293_1
	else
		arg_293_0.oriHurt = arg_293_0.oriHurt + arg_293_1
	end
end

function var_0_3.getOriHurt(arg_294_0)
	return arg_294_0.oriHurt or 0
end

function var_0_3.avoidHeroMoveBehind(arg_295_0)
	return false
end

function var_0_3.getAttackPoint(arg_296_0, arg_296_1)
	return arg_296_0:getFighterModel().attackPoints[arg_296_1]
end

function var_0_3.getAttackedPoint(arg_297_0)
	return arg_297_0:getFighterModel().attackedPoint
end

function var_0_3.getLeftPoint(arg_298_0)
	return arg_298_0:getFighterModel().leftPoint
end

function var_0_3.getRightPoint(arg_299_0)
	return arg_299_0:getFighterModel().rightPoint
end

function var_0_3.getChestPoint(arg_300_0)
	return arg_300_0:getFighterModel().chestPoint
end

function var_0_3.getFootPoint(arg_301_0)
	return arg_301_0:getFighterModel().footPoint
end

function var_0_3.getHeadPoint(arg_302_0)
	return arg_302_0:getFighterModel().headPoint
end

function var_0_3.energyDecimalBase(arg_303_0)
	return var_0_2.ENERGY_DECIMAL_BASE - arg_303_0.energyDecreaseRatio_
end

function var_0_3.getDamage(arg_304_0)
	return arg_304_0.harms
end

function var_0_3.getKillCount(arg_305_0)
	return arg_305_0.killCount
end

function var_0_3.updateHarms(arg_306_0, arg_306_1)
	if arg_306_0.summoner then
		arg_306_0.summoner.harms = arg_306_0.summoner.harms + arg_306_1

		return
	end

	arg_306_0.harms = arg_306_0.harms + arg_306_1
end

function var_0_3.updateBearHarms(arg_307_0, arg_307_1)
	if arg_307_0.summoner then
		arg_307_0.summoner.bearHarms = arg_307_0.summoner.bearHarms + arg_307_1

		return
	end

	arg_307_0.bearHarms = arg_307_0.bearHarms + arg_307_1
end

function var_0_3.listenInfo(arg_308_0, arg_308_1)
	var_0_1.ctx.battle.infoListener[arg_308_1] = var_0_1.ctx.battle.infoListener[arg_308_1] or {}
	var_0_1.ctx.battle.infoList[arg_308_1] = {}
end

function var_0_3.getInfoByKey(arg_309_0, arg_309_1)
	return var_0_1.ctx.battle.infoList[arg_309_1]
end

function var_0_3.getAttachAttr(arg_310_0, arg_310_1)
	if arg_310_1 == 1 then
		return arg_310_0:getHpLimit() - arg_310_0:getHp()
	elseif arg_310_1 == 2 then
		return arg_310_0:getHp()
	elseif arg_310_1 == 3 then
		return 1 - arg_310_0:getHp() / arg_310_0:getHpLimit()
	elseif arg_310_1 == 4 then
		return arg_310_0:getHp() / arg_310_0:getHpLimit()
	elseif arg_310_1 == 5 then
		return arg_310_0:getHpLimit()
	end

	return 0
end

function var_0_3.getEnergy(arg_311_0)
	return arg_311_0.energy_
end

function var_0_3.getHp(arg_312_0)
	return arg_312_0.hp_
end

function var_0_3.getOverflowHarm(arg_313_0)
	return arg_313_0.overflowHarm_
end

function var_0_3.getHpLimit(arg_314_0)
	return math.max(arg_314_0.hpLimit_ - arg_314_0.tempHpLimit_, 1)
end

function var_0_3.resetHpLimit(arg_315_0, arg_315_1)
	if arg_315_0:isDeath() then
		return
	end

	local var_315_0 = arg_315_0:getHp() / arg_315_0:getHpLimit()

	arg_315_0.hpLimit_ = arg_315_1

	arg_315_0:updateHp(arg_315_0.hpLimit_ * var_315_0)
end

function var_0_3.setTempHpLimit(arg_316_0, arg_316_1)
	arg_316_0.tempHpLimit_ = var_0_68(arg_316_0.hpLimit_, arg_316_1)
end

function var_0_3.getTempHpLimit(arg_317_0)
	return arg_317_0.tempHpLimit_
end

function var_0_3.getFormationWalkPosition(arg_318_0)
	return arg_318_0.formationWalk2Position_
end

function var_0_3.getAttrByType(arg_319_0, arg_319_1)
	if not arg_319_0.___attrCache[arg_319_1] then
		local var_319_0 = arg_319_0.hero_:getBattleAttr(arg_319_1)
		local var_319_1, var_319_2 = arg_319_0:getBuffAttrChange(arg_319_1)
		local var_319_3 = var_0_69(1 + var_319_2, 0) * var_319_0 + var_319_1

		arg_319_0.___attrCache[arg_319_1] = var_0_69(var_319_3, 0)
	end

	return arg_319_0.___attrCache[arg_319_1]
end

function var_0_3.buffAttr2HP(arg_320_0, arg_320_1)
	return var_0_2.STRENGTH_HP_RATE * arg_320_1
end

function var_0_3.buffAttr2AD(arg_321_0, arg_321_1, arg_321_2, arg_321_3)
	if arg_321_0.hero_:getHeroType() == var_0_2.HeroType.STRENGTH then
		return arg_321_1 + arg_321_3 * var_0_2.AGILE_AD_RATE
	elseif arg_321_0.hero_:getHeroType() == var_0_2.HeroType.WISE then
		return arg_321_2 + arg_321_3 * var_0_2.AGILE_AD_RATE
	else
		return arg_321_3 + arg_321_3 * var_0_2.AGILE_AD_RATE
	end
end

function var_0_3.buffAttr2AP(arg_322_0, arg_322_1)
	return arg_322_1 * var_0_2.WISE_AP_RATE
end

function var_0_3.buffAttr2Hujia(arg_323_0, arg_323_1, arg_323_2)
	return var_0_2.AGILE_HUJIA_RATE * arg_323_2 + var_0_2.STRENGTH_HUJIA_RATE * arg_323_1
end

function var_0_3.buffAttr2Mokang(arg_324_0, arg_324_1)
	return var_0_2.WISE_MOKANG_RATE * arg_324_1
end

function var_0_3.buffAttr2Baoji(arg_325_0, arg_325_1)
	return var_0_2.AGILE_AD_BAOJI_RATE * arg_325_1
end

function var_0_3.getBuff2Attr(arg_326_0, arg_326_1, arg_326_2, arg_326_3, arg_326_4)
	if arg_326_1 == var_0_2.AttributeType.HP then
		return arg_326_0:buffAttr2HP(arg_326_2)
	elseif arg_326_1 == var_0_2.AttributeType.AD then
		return arg_326_0:buffAttr2AD(arg_326_2, arg_326_3, arg_326_4)
	elseif arg_326_1 == var_0_2.AttributeType.AP then
		return arg_326_0:buffAttr2AP(arg_326_3)
	elseif arg_326_1 == var_0_2.AttributeType.HUJIA then
		return arg_326_0:buffAttr2Hujia(arg_326_2, arg_326_4)
	elseif arg_326_1 == var_0_2.AttributeType.MOKANG then
		return arg_326_0:buffAttr2Mokang(arg_326_3)
	elseif arg_326_1 == var_0_2.AttributeType.AD_BAOJI then
		return arg_326_0:buffAttr2Baoji(arg_326_4)
	end

	return 0
end

function var_0_3.getBuffAttrChange(arg_327_0, arg_327_1)
	local var_327_0 = 0
	local var_327_1 = 0
	local var_327_2 = 0
	local var_327_3 = 0
	local var_327_4 = 0
	local var_327_5 = 0
	local var_327_6 = 0
	local var_327_7 = 0

	local function var_327_8(arg_328_0, arg_328_1)
		for iter_328_0, iter_328_1 in ipairs(arg_328_0) do
			if not arg_328_1 or iter_328_1:getBuffForm() ~= var_0_2.BuffForm.GAIN then
				if iter_328_1:getAttrType() == arg_327_1 then
					local var_328_0, var_328_1 = iter_328_1:getAttr()

					if not var_328_1 then
						var_327_0 = var_327_0 + var_328_0
					else
						var_327_1 = var_327_1 + var_328_0
					end
				end

				if iter_328_1:getAttrType() == var_0_2.HeroType.STRENGTH then
					local var_328_2, var_328_3 = iter_328_1:getAttr()

					if not var_328_3 then
						var_327_2 = var_327_2 + var_328_2
					else
						var_327_5 = var_327_5 + var_328_2
					end
				elseif iter_328_1:getAttrType() == var_0_2.HeroType.WISE then
					local var_328_4, var_328_5 = iter_328_1:getAttr()

					if not var_328_5 then
						var_327_3 = var_327_3 + var_328_4
					else
						var_327_6 = var_327_6 + var_328_4
					end
				elseif iter_328_1:getAttrType() == var_0_2.HeroType.AGILE then
					local var_328_6, var_328_7 = iter_328_1:getAttr()

					if not var_328_7 then
						var_327_4 = var_327_4 + var_328_6
					else
						var_327_7 = var_327_7 + var_328_6
					end
				end
			end
		end
	end

	local var_327_9 = arg_327_0:limitAttr()

	var_327_8(arg_327_0.buffs_, var_327_9)
	var_327_8(arg_327_0:getTeamType() == var_0_2.TeamType.A and var_0_1.ctx.battle.globalBuffsA or var_0_1.ctx.battle.globalBuffsB, var_327_9)
	var_327_8(var_0_1.ctx.battle.globalBuffs, var_327_9)

	if arg_327_1 == var_0_2.AttributeType.HP then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2HP(var_327_2)
	elseif arg_327_1 == var_0_2.AttributeType.AD then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2AD(var_327_2, var_327_3, var_327_4)
	elseif arg_327_1 == var_0_2.AttributeType.AP then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2AP(var_327_3)
	elseif arg_327_1 == var_0_2.AttributeType.HUJIA then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2Hujia(var_327_2, var_327_4)
	elseif arg_327_1 == var_0_2.AttributeType.MOKANG then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2Mokang(var_327_3)
	elseif arg_327_1 == var_0_2.AttributeType.AD_BAOJI then
		var_327_0 = var_327_0 + arg_327_0:buffAttr2Baoji(var_327_4)
	end

	return var_327_0, var_327_1
end

function var_0_3.getHeroHp(arg_329_0)
	return arg_329_0:getAttrByType(var_0_2.AttributeType.HP)
end

function var_0_3.getAD(arg_330_0)
	return arg_330_0:getAttrByType(var_0_2.AttributeType.AD)
end

function var_0_3.getAP(arg_331_0)
	return arg_331_0:getAttrByType(var_0_2.AttributeType.AP)
end

function var_0_3.getCurrentSpeed(arg_332_0)
	return arg_332_0:getAttrByType(var_0_2.AttributeType.SPEED)
end

function var_0_3.getShanBi(arg_333_0)
	return arg_333_0:getAttrByType(var_0_2.AttributeType.SHANBI)
end

function var_0_3.getAPShanBi(arg_334_0)
	return 0
end

function var_0_3.getADBaoJi(arg_335_0)
	return arg_335_0:getAttrByType(var_0_2.AttributeType.AD_BAOJI)
end

function var_0_3.getAPBaoJi(arg_336_0)
	return arg_336_0:getAttrByType(var_0_2.AttributeType.AP_BAOJI)
end

function var_0_3.getADBaoJiHarm(arg_337_0)
	return arg_337_0:getAttrByType(var_0_2.AttributeType.AD_BAOJIHARM)
end

function var_0_3.getAPBaoJiHarm(arg_338_0)
	return arg_338_0:getAttrByType(var_0_2.AttributeType.AP_BAOJIHARM)
end

function var_0_3.getADBaoJiJianShang(arg_339_0)
	return arg_339_0:getAttrByType(var_0_2.AttributeType.AD_BAOJI_JIANSHANG)
end

function var_0_3.getAPBaoJiJianShang(arg_340_0)
	return arg_340_0:getAttrByType(var_0_2.AttributeType.AP_BAOJI_JIANSHANG)
end

function var_0_3.getBothBaoji(arg_341_0)
	return arg_341_0:getAttrByType(var_0_2.AttributeType.BAOJI_RATE) / var_0_2.DECIMAL_BASE
end

function var_0_3.getBothBaojiHarm(arg_342_0)
	return arg_342_0:getAttrByType(var_0_2.AttributeType.BAOJIHARM)
end

function var_0_3.getHuJia(arg_343_0)
	return arg_343_0:getAttrByType(var_0_2.AttributeType.HUJIA)
end

function var_0_3.getDHuJia(arg_344_0)
	return arg_344_0:getAttrByType(var_0_2.AttributeType.D_HUJIA)
end

function var_0_3.getMoKang(arg_345_0)
	return arg_345_0:getAttrByType(var_0_2.AttributeType.MOKANG)
end

function var_0_3.getDMoKang(arg_346_0)
	return arg_346_0:getAttrByType(var_0_2.AttributeType.D_MOKANG)
end

function var_0_3.getMingZhong(arg_347_0)
	return arg_347_0:getAttrByType(var_0_2.AttributeType.MINGZHONG)
end

function var_0_3.getBasicSpeed(arg_348_0)
	return arg_348_0.hero_:getSpeed()
end

function var_0_3.getCureRate(arg_349_0)
	return arg_349_0:getAttrByType(var_0_2.AttributeType.CURE)
end

function var_0_3.getDCureRate(arg_350_0)
	return arg_350_0:getAttrByType(var_0_2.AttributeType.D_CURE)
end

function var_0_3.getAddCure(arg_351_0)
	return arg_351_0:getAttrByType(var_0_2.AttributeType.ADD_CURE) / 100
end

function var_0_3.getReMP(arg_352_0)
	local var_352_0 = var_0_19.rehpmpLimitChapter
	local var_352_1 = var_0_19.rehpmpLimitRate

	if (var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.NORMAL or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.SUPER or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD) and var_0_1.ctx.battle.chapter and var_0_0.table.indexof(var_352_0, var_0_1.ctx.battle.chapter) then
		return arg_352_0:getAttrByType(var_0_2.AttributeType.REMP) * var_352_1
	end

	return arg_352_0:getAttrByType(var_0_2.AttributeType.REMP)
end

function var_0_3.getReHP(arg_353_0)
	local var_353_0 = var_0_19.rehpmpLimitChapter
	local var_353_1 = var_0_19.rehpmpLimitRate

	if (var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.NORMAL or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.SUPER or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.GUILD) and var_0_1.ctx.battle.chapter and var_0_0.table.indexof(var_353_0, var_0_1.ctx.battle.chapter) then
		return arg_353_0:getAttrByType(var_0_2.AttributeType.REHP) * var_353_1
	end

	return arg_353_0:getAttrByType(var_0_2.AttributeType.REHP)
end

function var_0_3.getDMP(arg_354_0)
	return arg_354_0:getAttrByType(var_0_2.AttributeType.D_MP)
end

function var_0_3.getHurtMP(arg_355_0)
	return arg_355_0:getAttrByType(var_0_2.AttributeType.GETMP)
end

function var_0_3.getXixue(arg_356_0)
	return arg_356_0:getAttrByType(var_0_2.AttributeType.XIXUE)
end

function var_0_3.getADHitRate(arg_357_0)
	return arg_357_0:getAttrByType(var_0_2.AttributeType.AD_HIT_RATE)
end

function var_0_3.getEnergyRate(arg_358_0)
	return arg_358_0:getAttrByType(var_0_2.AttributeType.ENERGY_RATE)
end

function var_0_3.getADJianShang(arg_359_0)
	local var_359_0 = 1 - (1 - arg_359_0:getAttrByType(var_0_2.AttributeType.AD_JIANSHANG)) * (1 + arg_359_0:getCourseJianshang())

	if var_359_0 <= 0.1 then
		var_359_0 = 0.1
	end

	return var_359_0
end

function var_0_3.getAPJianShang(arg_360_0)
	local var_360_0 = 1 - (1 - arg_360_0:getAttrByType(var_0_2.AttributeType.AP_JIANSHANG)) * (1 + arg_360_0:getCourseJianshang())

	if var_360_0 <= 0.1 then
		var_360_0 = 0.1
	end

	return var_360_0
end

function var_0_3.getKillingMp(arg_361_0)
	return arg_361_0:getAttrByType(var_0_2.AttributeType.KILLING_MP)
end

function var_0_3.getDKongzhi(arg_362_0)
	return var_0_68(arg_362_0:getAttrByType(var_0_2.AttributeType.D_KONGZHI), 80)
end

function var_0_3.getDChenmo(arg_363_0)
	return arg_363_0:getAttrByType(var_0_2.AttributeType.D_CHENGMO)
end

function var_0_3.getCountReMp(arg_364_0)
	return arg_364_0:getAttrByType(var_0_2.AttributeType.COUNT_REMP)
end

function var_0_3.getAttackedReEnergy(arg_365_0)
	return arg_365_0:getAttrByType(var_0_2.AttributeType.ATTACKED_RE_ENERGY)
end

function var_0_3.getBuffHarmRate(arg_366_0)
	return arg_366_0:getAttrByType(var_0_2.AttributeType.BUFF_HARM_RATE)
end

function var_0_3.getCurrentAckSpeed(arg_367_0)
	if not arg_367_0.___ackSpeed then
		local var_367_0 = var_0_68(arg_367_0:getAttrByType(var_0_2.AttributeType.ACK_SPEED) / var_0_2.DECIMAL_BASE, var_0_2.MAX_ATTACK_SPEED)

		arg_367_0.___ackSpeed = var_0_69(var_367_0, var_0_2.MIN_ATTACK_SPEED)
	end

	return arg_367_0.___ackSpeed
end

function var_0_3.getBasicAckSpeed(arg_368_0)
	return var_0_13:getInitialAttr(arg_368_0.partnerID, var_0_2.AttributeType.ACK_SPEED)
end

function var_0_3.getDelaySkill(arg_369_0)
	return var_0_13:delaySkill(arg_369_0:getTableID()) + (arg_369_0.formationDelay_ or 0)
end

function var_0_3.getBreakStun(arg_370_0)
	return arg_370_0:getAttrByType(var_0_2.AttributeType.DIKANG_YINGZHI) / 100
end

function var_0_3.getHalfKillMp(arg_371_0)
	return arg_371_0:getAttrByType(var_0_2.AttributeType.HALF_MP) / 100
end

function var_0_3.getZhuangtaiDIkang(arg_372_0)
	return arg_372_0:getAttrByType(var_0_2.AttributeType.ZHUANGTAI_KANGXING) / var_0_2.DECIMAL_BASE
end

function var_0_3.getZhuangtaiMingzhong(arg_373_0)
	return arg_373_0:getAttrByType(var_0_2.AttributeType.ZHUANGTAI_MINGZHONG) / var_0_2.DECIMAL_BASE
end

function var_0_3.canBeStop(arg_374_0)
	return true
end

function var_0_3.setParalysis(arg_375_0, arg_375_1)
	arg_375_0.isParalysis = arg_375_1
end

function var_0_3.setImmuneControl(arg_376_0, arg_376_1)
	arg_376_0.isImmuneControl = arg_376_1
end

function var_0_3.setEnergyDecrease(arg_377_0, arg_377_1)
	if arg_377_1 < 0 then
		arg_377_0.energyDecreaseRatio_ = 0
	elseif arg_377_1 > var_0_2.ENERGY_DECIMAL_BASE then
		arg_377_0.energyDecreaseRatio_ = var_0_2.ENERGY_DECIMAL_BASE
	else
		arg_377_0.energyDecreaseRatio_ = arg_377_1
	end
end

function var_0_3.getEnergyDecrease(arg_378_0)
	return arg_378_0.energyDecreaseRatio_
end

function var_0_3.getParalysis(arg_379_0)
	return arg_379_0.isParalysis
end

function var_0_3.awakeMissionHandle(arg_380_0)
	if arg_380_0.isAwakeHero and arg_380_0.awakeMissionGoalType == var_0_2.AwakeStage3MissionType.DAMAGE_ACHIEVE and arg_380_0.awakeDamageGoal then
		local var_380_0 = arg_380_0.harms / arg_380_0.awakeDamageGoal

		if var_380_0 > 1 then
			var_380_0 = 1
		elseif var_380_0 < 0 then
			var_380_0 = 0
		end

		local var_380_1 = math.floor(arg_380_0.awakeDamageGoal - arg_380_0.harms)

		if var_380_1 <= 0 then
			var_380_1 = 0
		end

		arg_380_0.topWnd:getAwakeDamageLabel():setString(var_380_1)
		arg_380_0.topWnd:getAwakeDamageBar():setPercent(var_380_0 * 100)
	end
end

function var_0_3.setupSkillLevel(arg_381_0)
	arg_381_0.extraSkillLevel_ = arg_381_0.hero_:getExtraSkillLevel()
	arg_381_0.skillLevelByColor_ = var_0_0.clone(arg_381_0.hero_:getSkillLevel())
	arg_381_0.skillLevelByID_ = {}

	for iter_381_0, iter_381_1 in pairs(arg_381_0.skillLevelByColor_) do
		arg_381_0.skillLevelByColor_[iter_381_0] = iter_381_1 and iter_381_1 > 0 and iter_381_1 + arg_381_0.extraSkillLevel_ or 0
		arg_381_0.skillLevelByID_[arg_381_0.hero_:getSkillId(iter_381_0)] = iter_381_1 and iter_381_1 > 0 and iter_381_1 + arg_381_0.extraSkillLevel_ or 0
	end

	arg_381_0.skillLevelByID_[arg_381_0:getPugongID()] = arg_381_0:getLevel() + arg_381_0.extraSkillLevel_

	for iter_381_2, iter_381_3 in pairs(arg_381_0.skillLevelByID_) do
		if isClient and type(iter_381_3) == "number" and iter_381_3 > var_0_2.MAX_SKILL_LEV then
			var_0_2.exitProgram()
		end
	end
end

function var_0_3.pauseResume(arg_382_0, arg_382_1)
	if (arg_382_0:getFighterModel().currentAnimation_ or ""):find("gongji") then
		arg_382_0:resumeIdle()
	end
end

function var_0_3.checkSkinSkillInfo(arg_383_0)
	if not arg_383_0.skinSkillJudge_ then
		arg_383_0.skinSkillJudge_ = true

		local var_383_0 = var_0_2.tables.hero:skinItem(arg_383_0:getTableID())

		if var_383_0 and next(var_383_0) then
			for iter_383_0 = 1, #var_383_0 do
				local var_383_1 = var_383_0[iter_383_0]
				local var_383_2 = var_0_16:getModelID(var_383_1)
				local var_383_3 = var_0_16:getSkillID(var_383_1)

				if var_383_2 and arg_383_0:getSkillModelID() == var_383_2 then
					arg_383_0.skinSkillIndex_ = iter_383_0

					if var_383_3 > 0 then
						arg_383_0.isSkinSkillOn_ = true
						arg_383_0.skinSkillID_ = var_383_3
					end

					break
				end
			end
		end
	end
end

function var_0_3.toDoPerFrames(arg_384_0)
	return
end

function var_0_3.updateStateNumber(arg_385_0, arg_385_1, arg_385_2, arg_385_3)
	if arg_385_0.fighterModel then
		arg_385_0.fighterModel:updateStateNumber(arg_385_1, arg_385_2, arg_385_3)
	end
end

function var_0_3.setDefaultMaskColor(arg_386_0, arg_386_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	arg_386_0.defaultMaskColor = arg_386_1
end

function var_0_3.setMaskColor(arg_387_0, arg_387_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_387_0:isGLStateDiff(arg_387_1 or var_0_2.shader.Default_Dusk_Color) then
		return
	end

	if arg_387_0.fighterModel then
		arg_387_0.glState_ = arg_387_1 or var_0_2.shader.Default_Dusk_Color

		arg_387_0.fighterModel:setMaskColor(arg_387_1)
	end
end

function var_0_3.unsetMaskColor(arg_388_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_388_0:isGLStateDiff(var_0_2.shader.Default_Color) then
		return
	end

	if arg_388_0.fighterModel then
		arg_388_0.glState_ = var_0_2.shader.Default_Color

		arg_388_0.fighterModel:unsetMaskColor()
	end

	if arg_388_0.defaultMaskColor then
		arg_388_0:setMaskColor(arg_388_0.defaultMaskColor)
	end
end

function var_0_3.setGrayScale(arg_389_0, arg_389_1)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_389_0:isGLStateDiff(arg_389_1) then
		return
	end

	if arg_389_0.fighterModel then
		arg_389_0.glStateGray_ = arg_389_1

		arg_389_0.fighterModel:setGrayScale(arg_389_1)
	end
end

function var_0_3.unsetGrayScale(arg_390_0)
	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not arg_390_0:isGLStateDiff(var_0_2.shader.Default_Gray_Ratio) then
		return
	end

	if arg_390_0.fighterModel then
		arg_390_0.glStateGray_ = var_0_2.shader.Default_Gray_Ratio

		arg_390_0.fighterModel:unsetGrayScale()
	end
end

function var_0_3.isGLStateDiff(arg_391_0, arg_391_1)
	arg_391_0.glState_ = arg_391_0.glState_ or var_0_2.shader.Default_Color
	arg_391_0.glStateGray_ = arg_391_0.glStateGray_ or var_0_2.shader.Default_Gray_Ratio

	if type(arg_391_1) == "number" then
		return arg_391_0.glStateGray_ ~= arg_391_1
	end

	if type(arg_391_1) == "table" and arg_391_0.glState_ == arg_391_1 then
		return false
	end

	for iter_391_0, iter_391_1 in pairs(arg_391_0.glState_) do
		if arg_391_1[iter_391_0] ~= iter_391_1 then
			return true
		end
	end

	return false
end

function var_0_3.pause(arg_392_0, arg_392_1)
	if not arg_392_0.fighterModel then
		return
	end

	local var_392_0 = arg_392_1 or {}

	if not var_392_0.no_model then
		arg_392_0:getFighterModel():pause()
	end

	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not var_392_0.no_buff then
		local var_392_1 = arg_392_0.fighterModel:getBuffLayer():getChildren()

		for iter_392_0, iter_392_1 in ipairs(var_392_1) do
			iter_392_1:pause()
		end

		local var_392_2 = arg_392_0.fighterModel:getBuffLayerBack():getChildren()

		for iter_392_2, iter_392_3 in ipairs(var_392_2) do
			iter_392_3:pause()
		end
	end
end

function var_0_3.resume(arg_393_0, arg_393_1)
	if not arg_393_0.fighterModel then
		return
	end

	local var_393_0 = arg_393_1 or {}

	if not var_393_0.no_model then
		arg_393_0:getFighterModel():resume()
	end

	if var_0_2.BattleType.CreateReport == var_0_1.ctx.battle.battleType then
		return
	end

	if not var_393_0.no_buff then
		local var_393_1 = arg_393_0.fighterModel:getBuffLayer():getChildren()

		for iter_393_0, iter_393_1 in ipairs(var_393_1) do
			iter_393_1:resume()
		end

		local var_393_2 = arg_393_0.fighterModel:getBuffLayerBack():getChildren()

		for iter_393_2, iter_393_3 in ipairs(var_393_2) do
			iter_393_3:resume()
		end
	end
end

function var_0_3.getAttributeValues(arg_394_0)
	local var_394_0 = {}

	for iter_394_0 = 1, var_0_2.AttributeType.BATTLE_COUNT do
		var_394_0[iter_394_0] = arg_394_0:getAttrByType(iter_394_0)
	end

	return var_394_0
end

function var_0_3.getSkillTableValues(arg_395_0)
	local var_395_0 = {}

	for iter_395_0, iter_395_1 in ipairs(arg_395_0.hero_:getSkillId()) do
		local var_395_1 = {
			init = var_0_12:init(iter_395_1),
			step = var_0_12:step(iter_395_1),
			ap = var_0_12:step(iter_395_1),
			ad = var_0_12:step(iter_395_1)
		}

		var_395_0[tostring(iter_395_1)] = var_395_1
	end

	return var_395_0
end

function var_0_3.playDuskEffect(arg_396_0, arg_396_1)
	if arg_396_0.fighterModel then
		arg_396_0.fighterModel:playDuskEffect(arg_396_1)
	end
end

function var_0_3.playTargetCircle(arg_397_0, arg_397_1)
	if arg_397_0:isDeath() then
		return
	end

	if not arg_397_0.targetCircles_ then
		arg_397_0.targetCircles_ = {}
	end

	for iter_397_0, iter_397_1 in ipairs(arg_397_0.targetCircles_) do
		if iter_397_1 == arg_397_1 then
			arg_397_0.fighterModel:playTargetCircle(true)

			return
		end
	end

	table.insert(arg_397_0.targetCircles_, arg_397_1)
	arg_397_0.fighterModel:playTargetCircle(true)
end

function var_0_3.removeTargetCircle(arg_398_0, arg_398_1, arg_398_2)
	if not arg_398_0.targetCircles_ then
		return
	end

	if arg_398_2 then
		arg_398_0.fighterModel:playTargetCircle(false)
	end

	for iter_398_0 = #arg_398_0.targetCircles_, 1, -1 do
		if arg_398_0.targetCircles_[iter_398_0] == arg_398_1 then
			table.remove(arg_398_0.targetCircles_, iter_398_0)

			break
		end
	end

	if not next(arg_398_0.targetCircles_) and not arg_398_0:isDeath() then
		arg_398_0.fighterModel:playTargetCircle(false)
	end
end

function var_0_3.processAfterBattleEnd(arg_399_0, arg_399_1)
	return
end

function var_0_3.setLeader(arg_400_0)
	arg_400_0.isLeader_ = true

	if arg_400_0.fighterModel and var_0_1.ctx.battle.battleType ~= var_0_2.BattleType.CreateReport then
		arg_400_0.fighterModel:setLeader()
	end

	if arg_400_0:getFighterModel() then
		arg_400_0:getFighterModel():scale(1.2)
	end
end

function var_0_3.getBuffHalo(arg_401_0)
	return arg_401_0.buffHalo_
end

function var_0_3.addBuffHalo(arg_402_0, arg_402_1)
	for iter_402_0, iter_402_1 in ipairs(arg_402_0.buffHalo_) do
		if iter_402_1 == arg_402_1 then
			return
		end
	end

	table.insert(arg_402_0.buffHalo_, arg_402_1)
end

function var_0_3.clearBuffHalo(arg_403_0)
	for iter_403_0 = #arg_403_0.buffHalo_, 1, -1 do
		local var_403_0 = arg_403_0.buffHalo_[iter_403_0]

		arg_403_0:buffHaloRemoveFeedBack(var_403_0)
		table.remove(arg_403_0.buffHalo_, iter_403_0)
	end
end

function var_0_3.removeBuffHalo(arg_404_0, arg_404_1)
	for iter_404_0, iter_404_1 in ipairs(arg_404_0.buffHalo_) do
		if iter_404_1 == arg_404_1 then
			arg_404_0:buffHaloRemoveFeedBack(arg_404_1)
			table.remove(arg_404_0.buffHalo_, iter_404_0)

			break
		end
	end
end

function var_0_3.buffHaloRemoveFeedBack(arg_405_0, arg_405_1)
	local var_405_0 = arg_405_1.target_type
	local var_405_1 = arg_405_1.buffs

	if var_405_0 == var_0_2.HaloEffect.selfTeam or var_405_0 == var_0_2.HaloEffect.allTeam then
		for iter_405_0, iter_405_1 in ipairs(arg_405_0.selfTeam_) do
			if not iter_405_1:isDeath() then
				for iter_405_2, iter_405_3 in ipairs(var_405_1) do
					iter_405_1:removeBuffByID(iter_405_3)
				end
			end
		end
	end

	if var_405_0 == var_0_2.HaloEffect.sideTeam or var_405_0 == var_0_2.HaloEffect.allTeam then
		for iter_405_4, iter_405_5 in ipairs(arg_405_0.sideTeam_) do
			if not iter_405_5:isDeath() then
				for iter_405_6, iter_405_7 in ipairs(var_405_1) do
					iter_405_5:removeBuffByID(iter_405_7)
				end
			end
		end
	end
end

function var_0_3.checkBuffHaloEffect(arg_406_0)
	if not next(arg_406_0.buffHalo_) then
		return
	end

	local function var_406_0(arg_407_0, arg_407_1, arg_407_2, arg_407_3, arg_407_4, arg_407_5)
		local var_407_0 = {}

		for iter_407_0, iter_407_1 in ipairs(arg_407_0) do
			local var_407_1 = var_0_4.new({
				tableID = iter_407_1,
				start = var_0_1.ctx.battle.count,
				level = arg_407_2,
				skillID = arg_407_1,
				fighter = arg_406_0,
				target = arg_407_3
			})

			if arg_407_4 then
				var_407_1.manualHarmRevise = arg_407_4
			end

			if arg_407_5 then
				var_407_1.manualRevise = arg_407_5
			end

			var_407_1:setYongJiu()
			table.insert(var_407_0, var_407_1)
		end

		return var_407_0
	end

	for iter_406_0, iter_406_1 in ipairs(arg_406_0.buffHalo_) do
		local var_406_1 = iter_406_1.target_type
		local var_406_2 = iter_406_1.buffs
		local var_406_3 = iter_406_1.effect_area
		local var_406_4 = iter_406_1.level
		local var_406_5 = iter_406_1.skillID
		local var_406_6 = iter_406_1.effect_hero or {}
		local var_406_7
		local var_406_8

		local function var_406_9(arg_408_0)
			for iter_408_0, iter_408_1 in ipairs(arg_408_0) do
				local var_408_0 = var_406_6[iter_408_1]

				if (not iter_406_1.summonType or iter_408_1:getSummonType() == iter_406_1.summonType) and not iter_408_1:isDeath() and not iter_408_1:isAffected() then
					if iter_406_1.manualHarm then
						var_406_7 = iter_406_1.manualHarm(iter_408_1)
					end

					if iter_406_1.manualAttr then
						var_406_8 = iter_406_1.manualAttr(iter_408_1)
					end

					if not var_408_0 and var_406_3(iter_408_1) then
						local var_408_1 = var_406_0(var_406_2, var_406_5, var_406_4, iter_408_1, var_406_7, var_406_8)

						iter_408_1:addBuffs(var_408_1)

						if not iter_406_1.effect_hero then
							iter_406_1.effect_hero = {}
						end

						iter_406_1.effect_hero[iter_408_1] = true
					elseif var_408_0 and not var_406_3(iter_408_1) then
						for iter_408_2, iter_408_3 in ipairs(var_406_2) do
							iter_408_1:removeBuffByID(iter_408_3)
						end

						if not iter_406_1.effect_hero then
							iter_406_1.effect_hero = {}
						end

						iter_406_1.effect_hero[iter_408_1] = false
					elseif var_408_0 and var_406_3(iter_408_1) and (var_406_7 or var_406_8) then
						for iter_408_4, iter_408_5 in ipairs(var_406_2) do
							if iter_408_1:isHasBuffByID(iter_408_5) then
								if var_406_7 then
									iter_408_1:getBuffByID(iter_408_5).manualHarmRevise = var_406_7
								end

								if var_406_8 then
									local var_408_2 = iter_408_1:getBuffByID(iter_408_5)

									var_408_2.manualRevise = var_406_8

									if var_408_2:getAttrType() > 0 then
										iter_408_1.___attrCache[var_408_2:getAttrType()] = nil

										if var_408_2:getAttrType() == var_0_2.AttributeType.ACK_SPEED then
											iter_408_1.___ackSpeed = nil
										end
									end
								end
							end
						end
					end
				end
			end
		end

		if var_406_1 == var_0_2.HaloEffect.selfTeam or var_406_1 == var_0_2.HaloEffect.allTeam then
			var_406_9(arg_406_0.selfTeam_)
		end

		if var_406_1 == var_0_2.HaloEffect.sideTeam or var_406_1 == var_0_2.HaloEffect.allTeam then
			var_406_9(arg_406_0.sideTeam_)
		end
	end
end

function var_0_3.createSkillByID(arg_409_0, arg_409_1, arg_409_2, arg_409_3)
	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		local var_409_0 = arg_409_0.reportSkills_[1]

		if not var_409_0 or var_0_1.ctx.battle.count ~= var_409_0.startCount_ then
			if arg_409_0.reportSkills_[2] and arg_409_0.reportSkills_[2].startCount_ == var_0_1.ctx.battle.count then
				table.remove(arg_409_0.reportSkills_, 1)
			else
				return
			end
		end

		if arg_409_0:isDeath() then
			return
		end
	end

	arg_409_0:resetLeftInterval()
	arg_409_0:playAttack(arg_409_3 or 1)
	arg_409_0:selfSkillEffect()

	arg_409_0.specialAttackSkillID_ = arg_409_1
	arg_409_0.specialAttackSkillLevel_ = arg_409_2

	if var_0_2.BattleType.ReplayReport == var_0_1.ctx.battle.battleType then
		arg_409_0.unitSkills_ = arg_409_0.reportSkills_[1]
	else
		arg_409_0.unitSkills_ = var_0_5.new({
			fighter = arg_409_0,
			skillID = arg_409_1
		})
	end

	arg_409_0:beginAttackEnd(arg_409_0.unitSkills_)
end

function var_0_3.setInitialColor(arg_410_0, arg_410_1)
	arg_410_0.initialColor = arg_410_1

	arg_410_0:getFighterModel():setMaskColor(arg_410_1)
end

function var_0_3.setEscapeEnemyMove(arg_411_0, arg_411_1)
	arg_411_0.isEscapeEnemyMove = arg_411_1
end

function var_0_3.setIsMainRole(arg_412_0, arg_412_1)
	arg_412_0.isMainRole_ = arg_412_1
end

function var_0_3.isMainRole(arg_413_0)
	return arg_413_0.isMainRole_
end

function var_0_3.checkActivitySkill(arg_414_0, arg_414_1)
	if var_0_1.ctx.battle.isActivity and var_0_12:snowmanUsable(arg_414_1) <= 0 then
		return false
	end

	return true
end

function var_0_3.popActivityColorSkill(arg_415_0)
	if next(arg_415_0.startSkillQueue_) ~= nil then
		local var_415_0 = arg_415_0.startSkillQueue_[1]

		if arg_415_0:getSkillLevelByID(var_415_0) <= 0 or var_0_12:snowmanUsable(var_415_0) <= 0 then
			table.remove(arg_415_0.startSkillQueue_, 1)
			arg_415_0:popActivityColorSkill()
		end
	elseif arg_415_0.invalidSkillQueue_ then
		return arg_415_0:getOrbOfFrontSkill()
	else
		local var_415_1 = arg_415_0.skillQueue_[1]

		if arg_415_0:getSkillLevelByID(var_415_1) <= 0 or var_0_12:snowmanUsable(var_415_1) <= 0 then
			table.remove(arg_415_0.skillQueue_, 1)
			table.insert(arg_415_0.skillQueue_, var_415_1)
			arg_415_0:popActivityColorSkill()
		end
	end

	return arg_415_0:getOrbOfFrontSkill()
end

function var_0_3.summonMonstersErrorLog(arg_416_0, arg_416_1)
	if arg_416_0.addErrorLog then
		return
	end

	arg_416_0.addErrorLog = true

	local var_416_0 = ""
	local var_416_1 = ""

	for iter_416_0, iter_416_1 in ipairs(var_0_1.ctx.battle.teamA) do
		var_416_0 = var_416_0 .. iter_416_1:getTableID() .. "|"
	end

	for iter_416_2, iter_416_3 in ipairs(var_0_1.ctx.battle.teamB) do
		var_416_1 = var_416_1 .. iter_416_3:getTableID() .. "|"
	end

	local var_416_2 = "ZHIDIAN&DAZHUANG: SummonMonster Error! teamFormation:TeamA:" .. var_416_0 .. "TeamB:" .. var_416_1

	if arg_416_1 then
		var_416_2 = var_416_2 .. "fighterIndex" .. arg_416_1
	end

	var_0_2.db.errorLog:add(var_416_2)
end

function var_0_3.attackUnitErrorLog(arg_417_0, arg_417_1)
	if arg_417_0.hadSendAttackUnitError then
		return
	end

	arg_417_0.hadSendAttackUnitError = true

	local var_417_0 = ""
	local var_417_1 = ""

	for iter_417_0, iter_417_1 in ipairs(var_0_1.ctx.battle.teamA) do
		var_417_0 = var_417_0 .. iter_417_1:getTableID() .. "|"
	end

	for iter_417_2, iter_417_3 in ipairs(var_0_1.ctx.battle.teamB) do
		var_417_1 = var_417_1 .. iter_417_3:getTableID() .. "|"
	end

	local var_417_2 = "HAMAN: AttackUnit Error! SkillID:" .. arg_417_1 .. " teamFormation:TeamA:" .. var_417_0 .. "TeamB:" .. var_417_1

	var_0_2.db.errorLog:add(var_417_2)
end

function var_0_3.buffErrorLog(arg_418_0, arg_418_1)
	if arg_418_0.hadSendBuffError then
		return
	end

	arg_418_0.hadSendBuffError = true

	local var_418_0 = ""
	local var_418_1 = ""

	for iter_418_0, iter_418_1 in ipairs(var_0_1.ctx.battle.teamA) do
		var_418_0 = var_418_0 .. iter_418_1:getTableID() .. "|"
	end

	for iter_418_2, iter_418_3 in ipairs(var_0_1.ctx.battle.teamB) do
		var_418_1 = var_418_1 .. iter_418_3:getTableID() .. "|"
	end

	local var_418_2 = "SHUIMEN: BUFF Error! BuffID:" .. arg_418_1 .. " teamFormation:TeamA:" .. var_418_0 .. "TeamB:" .. var_418_1

	var_0_2.db.errorLog:add(var_418_2)
end

function var_0_3.isPVP(arg_419_0)
	if var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.ARENA or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.SUPER_ARENA_OLD or var_0_1.ctx.battle.campaignType == var_0_2.CampaignType.REGION_ARENA or var_0_1.ctx.battle.campaignType == ARENA_MODE or var_0_1.ctx.battle.campaignType == GUILD_ARENA or var_0_1.ctx.battle.campaignType == PLAYOFFS or var_0_1.ctx.battle.campaignType == PLAYOFFS_RECORD or var_0_1.ctx.battle.campaignType == FRIEND_FIGHT then
		return true
	else
		return false
	end
end

function var_0_3.isSuper(arg_420_0)
	return arg_420_0.hero_:isSuper() or false
end

function var_0_3.recordSummonMonster(arg_421_0)
	arg_421_0.records_.summon_num = arg_421_0.records_.summon_num + 1
end

function var_0_3.getSummonMonster(arg_422_0)
	if not arg_422_0.summonCount then
		arg_422_0.summonCount = 1
	end

	local var_422_0 = 6 + var_0_1.ctx.battle.summonMonsterNum[arg_422_0:getTeamType()]
	local var_422_1 = 0

	for iter_422_0 = 1, var_422_0 do
		local var_422_2 = arg_422_0:getTeamType() == var_0_2.TeamType.A and "A|" .. tostring(iter_422_0) or "B|" .. tostring(iter_422_0)
		local var_422_3 = var_0_1.ctx.battle.getFighter(var_422_2)

		if not var_422_3 then
			arg_422_0:summonMonstersErrorLog(var_422_2)

			return
		elseif var_422_3.reportSummonType ~= var_0_2.summonMonsterType.None and var_422_3.reportSummonerIndex == arg_422_0.fighterIndex then
			var_422_1 = var_422_1 + 1

			if var_422_1 == arg_422_0.summonCount then
				arg_422_0.summonCount = arg_422_0.summonCount + 1

				return var_422_3
			end
		end
	end

	arg_422_0:summonMonstersErrorLog()
end

function var_0_3.initElementEquip(arg_423_0)
	arg_423_0.elementEquips_ = {}
	arg_423_0.elementEquipsLevel_ = {}

	local var_423_0, var_423_1 = arg_423_0.hero_:getElementEquips()

	if var_423_0 then
		for iter_423_0 = 1, #var_423_0 do
			local var_423_2 = tonumber(var_423_0[iter_423_0])
			local var_423_3 = var_0_18:itemID(var_423_2)

			if var_423_2 ~= 0 then
				arg_423_0.elementEquips_[var_423_3] = true
				arg_423_0.elementEquipsLevel_[var_423_3] = var_423_1[iter_423_0]
			end
		end
	end
end

function var_0_3.initElement(arg_424_0)
	arg_424_0.elementLeitingCount = 0
	arg_424_0.elementThunderCount = 0
	arg_424_0.elementReboundCount = {}
	arg_424_0.elementHujiaCount = 0
	arg_424_0.elementCureCount = 0
end

function var_0_3.initHunqi(arg_425_0)
	arg_425_0.hunqiFanshangCount = 0
	arg_425_0.hunqiFanshangCDCount = 0
	arg_425_0.hunqiBaojiExtraHarmCount = 0
	arg_425_0.hunqiKongchangHarmCount = 0
	arg_425_0.hunqiEnchanceControlBuffCount = 0
	arg_425_0.hunqiRecoverTimes = 1
	arg_425_0.hunqiLossHpHarmCount = 0
	arg_425_0.hunqiJianSheCount = 0
	arg_425_0.hunqiDControlCount = 0
	arg_425_0.hunqiKaichangReMp = false
	arg_425_0.hunqiSelfKaichangReMp = false
end

function var_0_3.elementToDoPerFrames(arg_426_0)
	arg_426_0:elementCureSelf()
	arg_426_0:elementTotalHarmRebound()
	arg_426_0:elementHujiaMokang()

	if arg_426_0:hasElementEquipByID(var_0_2.ElementEquip.LEITING) and arg_426_0.elementLeitingCount > 0 then
		arg_426_0.elementLeitingCount = arg_426_0.elementLeitingCount - 1
	end

	if arg_426_0.elementThunderCount > 0 then
		arg_426_0.elementThunderCount = arg_426_0.elementThunderCount - 1
	end

	arg_426_0.elementCureCount = arg_426_0.elementCureCount + 1

	arg_426_0:elementKaichangCure()
end

function var_0_3.getElementType(arg_427_0)
	return arg_427_0.hero_:getElementType()
end

function var_0_3.hasElementEquipByID(arg_428_0, arg_428_1)
	return arg_428_0.elementEquips_[arg_428_1]
end

function var_0_3.getElementEquipLevelByID(arg_429_0, arg_429_1)
	return arg_429_0.elementEquipsLevel_[arg_429_1]
end

function var_0_3.isElementStrengthenByID(arg_430_0, arg_430_1)
	return arg_430_0.hero_:getElementEquips()[var_0_2.ElementCoreIndex] == arg_430_1
end

function var_0_3.elementEquipBuffSkill(arg_431_0, arg_431_1)
	for iter_431_0, iter_431_1 in ipairs(arg_431_1) do
		if iter_431_1.tableID_ ~= 0 then
			if iter_431_1:getAttrType() > 0 then
				if arg_431_0:hasElementEquipByID(var_0_2.ElementEquip.AD_BUFF_ENHANCE) then
					local var_431_0 = iter_431_1:initAttr() + iter_431_1:getLevel() * iter_431_1:step()

					if (iter_431_1:getAttrType() == var_0_2.AttributeType.AD or iter_431_1:getAttrType() == var_0_2.AttributeType.AD_BAOJI) and var_431_0 > 0 and iter_431_1.fighter == arg_431_0 and iter_431_1.target ~= arg_431_0 and iter_431_1.target:getTeamType() == arg_431_0:getTeamType() then
						local var_431_1 = var_0_2.ElementEquip.AD_BUFF_ENHANCE
						local var_431_2 = var_0_18:battleAttr(var_431_1, arg_431_0:getElementEquipLevelByID(var_431_1))
						local var_431_3 = arg_431_0.hero_:getElementEquipActiveRate(var_431_1)

						iter_431_1.manualRevise = iter_431_1.manualRevise + var_431_0 * var_431_2 * var_431_3
					end
				end

				if arg_431_0:hasElementEquipByID(var_0_2.ElementEquip.AP_BUFF_ENHANCE) then
					local var_431_4 = iter_431_1:initAttr() + iter_431_1:getLevel() * iter_431_1:step()

					if (iter_431_1:getAttrType() == var_0_2.AttributeType.AP or iter_431_1:getAttrType() == var_0_2.AttributeType.AP_BAOJI) and var_431_4 > 0 and iter_431_1.fighter == arg_431_0 and iter_431_1.target ~= arg_431_0 and iter_431_1.target:getTeamType() == arg_431_0:getTeamType() then
						local var_431_5 = var_0_2.ElementEquip.AP_BUFF_ENHANCE
						local var_431_6 = var_0_18:battleAttr(var_431_5, arg_431_0:getElementEquipLevelByID(var_431_5))
						local var_431_7 = arg_431_0.hero_:getElementEquipActiveRate(var_431_5)

						iter_431_1.manualRevise = iter_431_1.manualRevise + var_431_4 * var_431_6 * var_431_7
					end
				end
			end

			if arg_431_0:hasElementEquipByID(var_0_2.ElementEquip.SELF_BUFF_EXTRA_TIME) and iter_431_1:getBuffForm() == var_0_2.BuffForm.GAIN and iter_431_1.fighter == arg_431_0 and iter_431_1.target == arg_431_0 then
				local var_431_8 = var_0_2.ElementEquip.SELF_BUFF_EXTRA_TIME
				local var_431_9 = var_0_18:battleAttr(var_431_8, arg_431_0:getElementEquipLevelByID(var_431_8))
				local var_431_10 = arg_431_0.hero_:getElementEquipActiveRate(var_431_8)

				iter_431_1:setExtraTime(iter_431_1.extraTime_ + iter_431_1:getTime() * var_431_9 * var_431_10)
			end

			if arg_431_0:hasElementEquipByID(var_0_2.ElementEquip.TEAM_BUFF_EXTRA_TIME) and (iter_431_1:getBuffForm() == var_0_2.BuffForm.GAIN and iter_431_1.target:getTeamType() == arg_431_0:getTeamType() or iter_431_1:dBuffType() > 0 and iter_431_1:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and iter_431_1.target:getTeamType() ~= arg_431_0:getTeamType()) then
				local var_431_11 = var_0_2.ElementEquip.TEAM_BUFF_EXTRA_TIME
				local var_431_12 = var_0_18:battleAttr(var_431_11, arg_431_0:getElementEquipLevelByID(var_431_11))
				local var_431_13 = arg_431_0.hero_:getElementEquipActiveRate(var_431_11)

				iter_431_1:setExtraTime(iter_431_1.extraTime_ + iter_431_1:getTime() * var_431_12 * var_431_13)
			end
		end
	end
end

function var_0_3.buffAddActionHunqi(arg_432_0, arg_432_1)
	if arg_432_0:getHunQiSuitID() == var_0_2.HunqiSuitID.ENHANCE_CONTROL then
		if arg_432_1.tableID_ ~= 0 and arg_432_1:dBuffType() > 0 and arg_432_1:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and arg_432_1.target:getTeamType() ~= arg_432_0:getTeamType() and arg_432_1:canRemove() then
			local var_432_0 = arg_432_1:getTime()

			arg_432_1:setExtraTime(arg_432_1:getTime() * var_0_49)

			arg_432_1.hunqiEnchanceControlBuffCount = arg_432_0.hunqiEnchanceControlBuffCount

			local var_432_1 = arg_432_0:createNewBuffs(var_0_51, arg_432_1.target, var_0_50)

			for iter_432_0, iter_432_1 in ipairs(var_432_1) do
				iter_432_1.hunqiEnchanceControlBuffCount = arg_432_0.hunqiEnchanceControlBuffCount

				iter_432_1:setExtraTime(arg_432_1:getTime())
			end

			arg_432_0.hunqiEnchanceControlBuffCount = arg_432_0.hunqiEnchanceControlBuffCount + 1

			arg_432_1.target:addBuffs(var_432_1)
		end
	elseif arg_432_0:getHunQiSuitID() == var_0_2.HunqiSuitID.RECOVER and arg_432_1.tableID_ ~= 0 and arg_432_1:getTableID() == var_0_54 then
		arg_432_1.manualHarmRevise = arg_432_0:getHpLimit() * var_0_55
	end
end

function var_0_3.fliterBuffsHunqi(arg_433_0, arg_433_1)
	if arg_433_0:getHunQiSuitID() == var_0_2.HunqiSuitID.D_CONTROL then
		for iter_433_0, iter_433_1 in ipairs(arg_433_1) do
			if iter_433_1.tableID_ ~= 0 and iter_433_1:dBuffType() > 0 and iter_433_1:dBuffType() ~= var_0_2.DBuffType.ATTR_CHANGE and iter_433_1.fighter:getTeamType() ~= arg_433_0:getTeamType() and iter_433_1:canRemove() then
				iter_433_1:setExtraTime(-iter_433_1:getTime() * var_0_67)
			end
		end
	end
end

function var_0_3.elementADExtraHarm(arg_434_0, arg_434_1)
	local var_434_0 = 0

	if arg_434_1.attackType == var_0_2.AttackType.AD and arg_434_0:hasElementEquipByID(var_0_2.ElementEquip.AD_EXTRA_HARM) then
		local var_434_1 = var_0_2.ElementEquip.AD_EXTRA_HARM

		var_434_0 = var_0_18:battleAttr(var_434_1, arg_434_0:getElementEquipLevelByID(var_434_1))
		var_434_0 = var_434_0 * arg_434_0.hero_:getElementEquipActiveRate(var_434_1)
	end

	return var_434_0
end

function var_0_3.elementCureSelf(arg_435_0)
	if arg_435_0:isDeath() then
		return
	end

	if arg_435_0:hasElementEquipByID(var_0_2.ElementEquip.CURE_SELF) then
		if not var_0_1.ctx.battle.infoListener.unit_cure_info then
			arg_435_0:listenInfo("unit_cure_info")
		end

		for iter_435_0, iter_435_1 in ipairs(arg_435_0:getInfoByKey("unit_cure_info")) do
			local var_435_0 = iter_435_1.unit

			if var_435_0.fighter == arg_435_0 and var_435_0.target ~= arg_435_0 and var_435_0.target:getTeamType() == arg_435_0:getTeamType() then
				local var_435_1 = var_0_2.ElementEquip.CURE_SELF
				local var_435_2 = var_0_18:battleAttr(var_435_1, arg_435_0:getElementEquipLevelByID(var_435_1))
				local var_435_3 = arg_435_0.hero_:getElementEquipActiveRate(var_435_1)
				local var_435_4 = var_0_18:skillIDs(var_435_1)

				if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
					local var_435_5 = arg_435_0:createAttackUnits({
						arg_435_0
					}, var_435_4[1])

					for iter_435_2, iter_435_3 in ipairs(var_435_5) do
						iter_435_3.elementCure = iter_435_1.cure * var_435_2 * var_435_3

						table.insert(arg_435_0.moveAttackUnits_, iter_435_3)
						table.insert(arg_435_0.records_.special_units, iter_435_3)
					end
				end
			end
		end
	end
end

function var_0_3.elementLeiting(arg_436_0, arg_436_1)
	if arg_436_0:hasElementEquipByID(var_0_2.ElementEquip.LEITING) and arg_436_0.elementLeitingCount <= 0 then
		local var_436_0 = var_0_2.ElementEquip.LEITING
		local var_436_1 = var_0_18:skillIDs(var_436_0)
		local var_436_2 = var_0_18:buffIDs(var_436_0)
		local var_436_3 = arg_436_1.target:getBuffsByID(var_436_2[1])
		local var_436_4 = {}

		for iter_436_0, iter_436_1 in ipairs(var_436_3) do
			if iter_436_1.fighter == arg_436_0 then
				table.insert(var_436_4, iter_436_1)
			end
		end

		if #var_436_4 >= 2 then
			arg_436_0.elementLeitingCount = var_0_31

			for iter_436_2 = #var_436_4, 1, -1 do
				arg_436_1.target:removeBuffs(var_436_4[iter_436_2])
			end

			local var_436_5 = var_0_18:battleAttr(var_436_0, arg_436_0:getElementEquipLevelByID(var_436_0))
			local var_436_6 = arg_436_0.hero_:getElementEquipActiveRate(var_436_0)

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_436_7 = arg_436_0:createAttackUnits({
					arg_436_1.target
				}, var_436_1[1])

				for iter_436_3, iter_436_4 in ipairs(var_436_7) do
					iter_436_4.elementHarm = var_436_5 * var_436_6

					table.insert(arg_436_0.moveAttackUnits_, iter_436_4)
					table.insert(arg_436_0.records_.special_units, iter_436_4)
				end
			end
		else
			local var_436_8 = arg_436_0:createNewBuffs(var_436_2, arg_436_1.target, var_436_1[1])

			arg_436_1.target:addBuffs(var_436_8)
		end
	end
end

function var_0_3.elementTotalHarmRebound(arg_437_0)
	if arg_437_0:isDeath() then
		return
	end

	if arg_437_0:hasElementEquipByID(var_0_2.ElementEquip.TOTAL_HARM_REBOUND) and var_0_1.ctx.battle.count % 30 == 0 then
		for iter_437_0, iter_437_1 in ipairs(arg_437_0.sideTeam_) do
			if not iter_437_1:isDeath() and not iter_437_1:isAffected() then
				if not arg_437_0.elementReboundCount[iter_437_1] then
					arg_437_0.elementReboundCount[iter_437_1] = 0
				end

				local var_437_0 = var_0_32

				if var_0_71(iter_437_1:getDamage() / var_437_0) > arg_437_0.elementReboundCount[iter_437_1] then
					arg_437_0.elementReboundCount[iter_437_1] = arg_437_0.elementReboundCount[iter_437_1] + 1

					local var_437_1 = var_0_2.ElementEquip.TOTAL_HARM_REBOUND
					local var_437_2 = var_0_18:battleAttr(var_437_1, arg_437_0:getElementEquipLevelByID(var_437_1))
					local var_437_3 = arg_437_0.hero_:getElementEquipActiveRate(var_437_1)
					local var_437_4 = var_0_18:skillIDs(var_437_1)

					if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
						local var_437_5 = arg_437_0:createAttackUnits({
							iter_437_1
						}, var_437_4[1])

						for iter_437_2, iter_437_3 in ipairs(var_437_5) do
							iter_437_3.elementHarm = var_0_32 * var_437_2 * var_437_3

							table.insert(arg_437_0.moveAttackUnits_, iter_437_3)
							table.insert(arg_437_0.records_.special_units, iter_437_3)
						end
					end
				end
			end
		end
	end
end

function var_0_3.elementHujiaMokang(arg_438_0)
	if arg_438_0:hasElementEquipByID(var_0_2.ElementEquip.KAICHANG_HUJIAMOKANG) then
		local var_438_0 = var_0_2.ElementEquip.KAICHANG_HUJIAMOKANG
		local var_438_1 = var_0_18:battleAttr(var_438_0, arg_438_0:getElementEquipLevelByID(var_438_0))
		local var_438_2 = arg_438_0.hero_:getElementEquipActiveRate(var_438_0)
		local var_438_3 = var_0_18:skillIDs(var_438_0)
		local var_438_4 = var_0_18:buffIDs(var_438_0)

		if not arg_438_0.addElementHujiaMokang then
			arg_438_0.addElementHujiaMokang = true

			for iter_438_0, iter_438_1 in ipairs(arg_438_0.selfTeam_) do
				if not iter_438_1:isDeath() and not iter_438_1:isAffected() then
					local var_438_5 = arg_438_0:createNewBuffs(var_438_4, iter_438_1, var_438_3[1])

					for iter_438_2, iter_438_3 in ipairs(var_438_5) do
						iter_438_3.manualRevise = iter_438_1:getAttrByType(iter_438_3:getType()) * var_438_1 * var_438_2
					end

					iter_438_1:addBuffs(var_438_5)
				end
			end
		else
			arg_438_0.elementHujiaCount = arg_438_0.elementHujiaCount + 1

			if arg_438_0.elementHujiaCount % var_0_33 == 0 then
				for iter_438_4, iter_438_5 in ipairs(arg_438_0.selfTeam_) do
					local var_438_6
					local var_438_7 = iter_438_5:getBuffs()

					for iter_438_6, iter_438_7 in ipairs(var_438_7) do
						if iter_438_7:getTableID() == var_438_4[1] and iter_438_7.fighter == arg_438_0 then
							var_438_6 = iter_438_7

							break
						end
					end

					if var_438_6 then
						var_438_6.manualRevise = var_438_1 * var_438_2 * (90 - arg_438_0.elementHujiaCount / var_0_33) / 90

						local var_438_8 = iter_438_5.hero_:getBattleAttr(var_0_2.AttributeType.HUJIA)
						local var_438_9, var_438_10 = iter_438_5:getBuffAttrChange(var_0_2.AttributeType.HUJIA)
						local var_438_11 = math.max(1 + var_438_10, 0) * var_438_8 + var_438_9

						iter_438_5.___attrCache[var_0_2.AttributeType.HUJIA] = math.max(var_438_11, 0)
					end

					local var_438_12
					local var_438_13 = iter_438_5:getBuffs()

					for iter_438_8, iter_438_9 in ipairs(var_438_13) do
						if iter_438_9:getTableID() == var_438_4[2] and iter_438_9.fighter == arg_438_0 then
							var_438_12 = iter_438_9

							break
						end
					end

					if var_438_12 then
						var_438_12.manualRevise = var_438_1 * var_438_2 * (90 - arg_438_0.elementHujiaCount / var_0_33) / 90

						local var_438_14 = iter_438_5.hero_:getBattleAttr(var_0_2.AttributeType.MOKANG)
						local var_438_15, var_438_16 = iter_438_5:getBuffAttrChange(var_0_2.AttributeType.MOKANG)
						local var_438_17 = math.max(1 + var_438_16, 0) * var_438_14 + var_438_15

						iter_438_5.___attrCache[var_0_2.AttributeType.MOKANG] = math.max(var_438_17, 0)
					end
				end
			end
		end
	end
end

function var_0_3.elementKaichangCure(arg_439_0)
	if arg_439_0:isDeath() then
		return
	end

	if arg_439_0:hasElementEquipByID(var_0_2.ElementEquip.KAICHANG_CURE) and arg_439_0.elementCureCount % var_0_34 == 0 then
		local var_439_0 = {}

		for iter_439_0, iter_439_1 in ipairs(arg_439_0.selfTeam_) do
			if not iter_439_1:isDeath() and not iter_439_1:isAffected() then
				table.insert(var_439_0, iter_439_1)
			end
		end

		local var_439_1 = var_0_2.ElementEquip.KAICHANG_CURE
		local var_439_2 = var_0_18:battleAttr(var_439_1, arg_439_0:getElementEquipLevelByID(var_439_1))
		local var_439_3 = arg_439_0.hero_:getElementEquipActiveRate(var_439_1)
		local var_439_4 = var_0_18:skillIDs(var_439_1)

		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_439_5 = arg_439_0:createAttackUnits(var_439_0, var_439_4[1])

			for iter_439_2, iter_439_3 in ipairs(var_439_5) do
				iter_439_3.elementCure = var_439_2 * var_439_3

				table.insert(arg_439_0.moveAttackUnits_, iter_439_3)
				table.insert(arg_439_0.records_.special_units, iter_439_3)
			end
		end
	end
end

function var_0_3.elementDcure(arg_440_0, arg_440_1)
	if arg_440_0:hasElementEquipByID(var_0_2.ElementEquip.DCURE) then
		local var_440_0 = var_0_2.ElementEquip.DCURE
		local var_440_1 = var_0_18:battleAttr(var_440_0, arg_440_0:getElementEquipLevelByID(var_440_0))
		local var_440_2 = arg_440_0.hero_:getElementEquipActiveRate(var_440_0)
		local var_440_3 = var_0_18:skillIDs(var_440_0)
		local var_440_4 = var_0_18:buffIDs(var_440_0)
		local var_440_5 = arg_440_0:createNewBuffs(var_440_4, arg_440_1.target, var_440_3[1])

		for iter_440_0, iter_440_1 in ipairs(var_440_5) do
			iter_440_1.manualRevise = var_440_1 * var_440_2
		end

		arg_440_1.target:addBuffs(var_440_5)
	end
end

function var_0_3.elementImmortal(arg_441_0)
	if arg_441_0:hasElementEquipByID(var_0_2.ElementEquip.IMMORTAL) then
		local var_441_0
		local var_441_1

		for iter_441_0, iter_441_1 in ipairs(arg_441_0.selfTeam_) do
			if iter_441_1 ~= arg_441_0 and not iter_441_1:isDeath() and not iter_441_1:isAffected() and (not var_441_0 or var_441_1 > var_441_0:getHp() / var_441_0:getHpLimit()) then
				var_441_0 = iter_441_1
				var_441_1 = var_441_0:getHp() / var_441_0:getHpLimit()
			end
		end

		if var_441_0 then
			local var_441_2 = var_0_2.ElementEquip.IMMORTAL
			local var_441_3 = var_0_18:battleAttr(var_441_2, arg_441_0:getElementEquipLevelByID(var_441_2))
			local var_441_4 = arg_441_0.hero_:getElementEquipActiveRate(var_441_2)
			local var_441_5 = var_0_18:skillIDs(var_441_2)
			local var_441_6 = var_0_18:buffIDs(var_441_2)
			local var_441_7 = arg_441_0:createNewBuffs(var_441_6, var_441_0, var_441_5[1])

			for iter_441_2, iter_441_3 in ipairs(var_441_7) do
				iter_441_3:setExtraTime(var_441_3 * var_441_4)
			end

			var_441_0:addBuffs(var_441_7)
		end
	end
end

function var_0_3.getHunQiSuitID(arg_442_0)
	if not arg_442_0.hunQiSuitID then
		local var_442_0
		local var_442_1

		if arg_442_0.hero_.getSpiritSuitID then
			local var_442_2

			var_442_2, var_442_1 = arg_442_0.hero_:getSpiritSuitID()
		end

		arg_442_0.hunQiSuitID = var_442_1 or 0
	end

	return arg_442_0.hunQiSuitID
end

function var_0_3.hunqiKongchang(arg_443_0, arg_443_1, arg_443_2)
	if arg_443_0:getHunQiSuitID() == var_0_2.HunqiSuitID.KONGCHANG then
		arg_443_0.hunqiKongchangHarmCount = arg_443_0.hunqiKongchangHarmCount + arg_443_2

		if arg_443_0.hunqiKongchangHarmCount >= arg_443_0:getHpLimit() * var_0_48 then
			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_443_0 = arg_443_0:getTargets(var_0_46)
				local var_443_1 = arg_443_0:createAttackUnits(var_443_0, var_0_46)

				for iter_443_0, iter_443_1 in ipairs(var_443_1) do
					table.insert(arg_443_0.moveAttackUnits_, iter_443_1)
					table.insert(arg_443_0.records_.special_units, iter_443_1)
				end

				local var_443_2 = arg_443_0:createAttackUnits({
					arg_443_0
				}, var_0_47)

				for iter_443_2, iter_443_3 in ipairs(var_443_2) do
					table.insert(arg_443_0.moveAttackUnits_, iter_443_3)
					table.insert(arg_443_0.records_.special_units, iter_443_3)
				end
			end

			arg_443_0.hunqiKongchangHarmCount = 0
		end
	end
end

function var_0_3.buffRemoveActionHunqi(arg_444_0, arg_444_1)
	if arg_444_1.hunqiEnchanceControlBuffCount and arg_444_0:getHunQiSuitID() == var_0_2.HunqiSuitID.ENHANCE_CONTROL and arg_444_1:getTableID() ~= var_0_51[1] and arg_444_1:getTableID() ~= var_0_51[2] then
		for iter_444_0 = 1, 2 do
			local var_444_0
			local var_444_1 = arg_444_1.target:getBuffsByID(var_0_51[iter_444_0])

			for iter_444_1, iter_444_2 in ipairs(var_444_1) do
				if iter_444_2.hunqiEnchanceControlBuffCount == arg_444_1.hunqiEnchanceControlBuffCount then
					var_444_0 = iter_444_2
				end
			end

			if var_444_0 then
				arg_444_1.target:removeBuffs(var_444_0)
			end
		end
	end
end

function var_0_3.applyHurtFighterHunqi(arg_445_0, arg_445_1, arg_445_2, arg_445_3, arg_445_4, arg_445_5)
	if arg_445_0:getHunQiSuitID() == var_0_2.HunqiSuitID.RECOVER and arg_445_2 > 0 and arg_445_0.hunqiRecoverTimes > 0 then
		local var_445_0 = math.max(0, arg_445_0:getHp() - arg_445_2)
		local var_445_1 = arg_445_0:getHpLimit() * var_0_52

		if var_445_0 < var_445_1 then
			arg_445_2 = arg_445_0:getHp() - var_445_1

			if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
				local var_445_2 = arg_445_0:createAttackUnits({
					arg_445_0
				}, var_0_53)

				for iter_445_0, iter_445_1 in ipairs(var_445_2) do
					table.insert(arg_445_0.moveAttackUnits_, iter_445_1)
					table.insert(arg_445_0.records_.special_units, iter_445_1)
				end
			end

			arg_445_0.hunqiRecoverTimes = arg_445_0.hunqiRecoverTimes - 1
		end
	end

	return arg_445_2, arg_445_3, arg_445_4, arg_445_5
end

function var_0_3.hunqiToDoPerFrames(arg_446_0)
	arg_446_0:hunqiKaichang()
end

function var_0_3.hunqiKaichang(arg_447_0)
	if arg_447_0:getHunQiSuitID() == var_0_2.HunqiSuitID.KAICHANG_REMP and not arg_447_0.hunqiKaichangReMp and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		for iter_447_0, iter_447_1 in ipairs(arg_447_0.selfTeam_) do
			iter_447_1.hunqiKaichangReMp = true
		end

		local var_447_0 = arg_447_0:getTargets(var_0_60)
		local var_447_1 = arg_447_0:createAttackUnits(var_447_0, var_0_60)

		for iter_447_2, iter_447_3 in ipairs(var_447_1) do
			table.insert(arg_447_0.moveAttackUnits_, iter_447_3)
			table.insert(arg_447_0.records_.special_units, iter_447_3)
		end
	end

	if arg_447_0:getHunQiSuitID() == var_0_2.HunqiSuitID.KAICHANG_REMP and not arg_447_0.hunqiSelfKaichangReMp and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_447_0.hunqiSelfKaichangReMp = true

		local var_447_2 = arg_447_0:createAttackUnits({
			arg_447_0
		}, var_0_61)

		for iter_447_4, iter_447_5 in ipairs(var_447_2) do
			table.insert(arg_447_0.moveAttackUnits_, iter_447_5)
			table.insert(arg_447_0.records_.special_units, iter_447_5)
		end
	end

	if arg_447_0:getHunQiSuitID() == var_0_2.HunqiSuitID.CHUANTOU and not arg_447_0.hunqiChuantouBuff and var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
		arg_447_0.hunqiChuantouBuff = true

		local var_447_3 = arg_447_0:createAttackUnits({
			arg_447_0
		}, var_0_35)

		for iter_447_6, iter_447_7 in ipairs(var_447_3) do
			table.insert(arg_447_0.moveAttackUnits_, iter_447_7)
			table.insert(arg_447_0.records_.special_units, iter_447_7)
		end
	end
end

function var_0_3.getHunQiJianSheTarget(arg_448_0, arg_448_1, arg_448_2, arg_448_3)
	local var_448_0 = var_0_11.B2(arg_448_1, arg_448_2)
	local var_448_1
	local var_448_2

	for iter_448_0, iter_448_1 in pairs(var_448_0) do
		if iter_448_1:getSummonType() == var_0_2.summonMonsterType.None and iter_448_1 ~= arg_448_3 and (not var_448_1 or var_448_2 > iter_448_1:getHpLimit()) then
			var_448_1 = iter_448_1
			var_448_2 = var_448_1:getHpLimit()
		end
	end

	if var_448_1 then
		return {
			var_448_1
		}
	else
		return {}
	end
end

function var_0_3.applyUnitBuffsHunqi(arg_449_0, arg_449_1, arg_449_2, arg_449_3, arg_449_4, arg_449_5, arg_449_6)
	if arg_449_0:getHunQiSuitID() == var_0_2.HunqiSuitID.D_CONTROL and #arg_449_2 > 0 and (arg_449_0.hunqiDControlCount == 0 or var_0_1.ctx.battle.count - arg_449_0.hunqiDControlCount > var_0_66) then
		if var_0_2.BattleType.ReplayReport ~= var_0_1.ctx.battle.battleType then
			local var_449_0 = arg_449_0:createAttackUnits({
				arg_449_0
			}, var_0_65)

			for iter_449_0, iter_449_1 in ipairs(var_449_0) do
				table.insert(arg_449_0.moveAttackUnits_, iter_449_1)
				table.insert(arg_449_0.records_.special_units, iter_449_1)
			end
		end

		arg_449_0.hunqiDControlCount = var_0_1.ctx.battle.count
	end
end

return var_0_3
