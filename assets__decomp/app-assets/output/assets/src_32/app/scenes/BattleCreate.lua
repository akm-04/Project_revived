local var_0_0 = class("BattleCreate", import("app.common.ui.BaseScene"))
local var_0_1 = ngx.ctx.battle.getRequire("SkillEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.battle
local var_0_4 = xyd.tables.skill
local var_0_5 = require("framework.scheduler")
local var_0_6 = require("cjson")
local var_0_7 = import("app.model.Hero")
local var_0_8 = import("app.model.Item")
local var_0_9 = ngx.ctx.battle.getRequire("Buff")
local var_0_10 = xyd.tables.campaign
local var_0_11 = import("app.common.ui.SpineEffect")
local var_0_12 = xyd
local var_0_13 = ngx
local var_0_14 = math.min
local var_0_15 = math.max
local var_0_16 = math.abs
local var_0_17 = math.floor
local var_0_18 = math.ceil
local var_0_19 = math.sqrt
local var_0_20 = 6

function var_0_0.ctor(arg_1_0, arg_1_1)
	cc.Director:getInstance():purgeCachedData()
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.addtime = 0
	arg_1_0.selfPlayer = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SELF_PLAYER)
	arg_1_0.marchModel = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.MARCH)
	arg_1_0.playoffsModel = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.PLAYOFFS)
	arg_1_0.socialSystem = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SOCIAL_SYSTEM)
	arg_1_0.regionCasualArena = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.REGION_CASUAL_ARENA)
	arg_1_0.isReplay = arg_1_1.is_replay

	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		arg_1_0.allParams = clone(arg_1_1)
	else
		arg_1_0.allParams = {}
	end

	arg_1_0.battleType = arg_1_1.battleType or var_0_12.BattleType.Normal
	arg_1_0.jsonData_ = arg_1_1.jsonData or ""
	arg_1_0.group_ = 1
	arg_1_0.pvp = arg_1_1.pvp
	arg_1_0.memories_awards = arg_1_1.memories_awards
	arg_1_0.twoYearsAwards = arg_1_1.twoYearsAwards
	arg_1_0.awards = arg_1_1.awards
	arg_1_0.stories = arg_1_1.stories or {}
	arg_1_0.campaignType = arg_1_1.campaignType
	arg_1_0.campaignID = arg_1_1.campaignID
	arg_1_0.isWatchReplay = arg_1_1.isWatchReplay
	arg_1_0.favorDegreeUp = arg_1_1.favorDegreeUp
	arg_1_0.formation = arg_1_1.formation
	arg_1_0.battleID = arg_1_1.battleID or 0
	arg_1_0.extraMonsterBuffers = var_0_3:extraMonsterBuffers(arg_1_0.battleID)
	arg_1_0.star_ = arg_1_1.star or 0
	arg_1_0.rentFlag_ = arg_1_1.rentFlag
	arg_1_0.fighterInfo = arg_1_1.fighterInfo
	arg_1_0.isGuide = arg_1_1.isGuide
	arg_1_0.canceleMusic_ = arg_1_1.cancleMusic
	arg_1_0.dropMana = arg_1_1.dropMana
	arg_1_0.dropItems = arg_1_1.drops or {}
	arg_1_0.isAwakeCampaign = arg_1_1.isAwakeCampaign or false
	arg_1_0.awakeMissionID = arg_1_1.awakeMissionID
	arg_1_0.awakeHero = arg_1_1.awakeHero
	arg_1_0.awakeStage = arg_1_1.awakeStage
	arg_1_0.awakeMissionGoalType = arg_1_1.awakeMissionGoalType

	if arg_1_0.awakeMissionGoalType and arg_1_0.awakeMissionGoalType == 1 then
		arg_1_0.awakeMissionMonster = var_0_12.tables.mission:challengeNums(arg_1_0.awakeMissionID)
	elseif arg_1_0.awakeMissionGoalType and arg_1_0.awakeMissionGoalType == 2 then
		arg_1_0.awakeMissionDamage = var_0_12.tables.mission:challengeNums(arg_1_0.awakeMissionID)
	end

	arg_1_0.ifPlayHeroShow = true

	local var_1_0 = var_0_12.tables.abtest:uniqueKey(var_0_12.Abtests.N7GSO)

	if not arg_1_0.selfPlayer.abtestGroup then
		arg_1_0.selfPlayer:initABtest()
	end

	if not arg_1_0.selfPlayer.abtestGroup[var_1_0] then
		arg_1_0.selfPlayer:getAbtestGroupByKey(var_1_0)
	end

	local var_1_1 = arg_1_0.selfPlayer.abtestGroup[var_1_0]

	dump(arg_1_0.selfPlayer.abtestGroup)

	if var_1_1 and var_1_1 == "A" then
		arg_1_0.ifPlayHeroShow = false
	end

	arg_1_0.isPetAwakeCampaign = arg_1_1.isPetAwakeCampaign or false
	arg_1_0.awakePet = arg_1_1.awakePet
	arg_1_0.petAwakeMissionID = arg_1_1.petAwakeMissionID
	arg_1_0.petAwakeMissionGoalType = arg_1_1.petAwakeMissionGoalType
	arg_1_0.mapID_ = var_0_12.tables.battle:maps(arg_1_0.battleID)
	arg_1_0.rentPetID = arg_1_1.rent_pet_id or 0
	arg_1_0.isBattleEnded_ = false
	arg_1_0.location = arg_1_1.location
	arg_1_0.noResult = arg_1_1.noResult
	arg_1_0.guideMonsterID = arg_1_1.guideMonsterID
	arg_1_0.notClickAvatar = false
	arg_1_0.preBattleShow = arg_1_1.preBattleShow or {}
	arg_1_0.medicineNum = 0
	arg_1_0.petFloor = arg_1_1.petFloor
	arg_1_0.petFloorType = arg_1_1.petFloorType
	arg_1_0.isEscapeStory = arg_1_1.isEscapeStory or false
	arg_1_0.monsterPos = arg_1_1.monster_pos

	arg_1_0:initBaseData(arg_1_1)
end

function var_0_0.initBaseData(arg_2_0, arg_2_1)
	arg_2_0.herosA = arg_2_1.herosA or {}
	arg_2_0.heroGroupB = arg_2_1.herosB or {}
	arg_2_0.summonMonsters = arg_2_1.summonMonsters or {}
	arg_2_0.reportStar_ = arg_2_1.reportStar or nil
	arg_2_0.responseData_ = arg_2_1.responseData or {}
	arg_2_0.fightParams = arg_2_1.fightParams or {}
	arg_2_0.petsA = arg_2_1.petsA or {}
	arg_2_0.petsB = arg_2_1.petsB or {}

	if arg_2_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
		arg_2_0.herosB = arg_2_0.heroGroupB[1]
	elseif arg_2_0.campaignType == var_0_12.CampaignType.SUPER_ARENA then
		arg_2_0.peakArena = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.PEAK_ARENA)

		arg_2_0.peakArena:clear()
		arg_2_0.peakArena:setCurrentBattleRound(1)

		arg_2_0.heroGroupA = arg_2_1.herosA
		arg_2_0.herosA = arg_2_0.heroGroupA.team1
		arg_2_0.summonGroup = arg_2_1.summonMonsters
		arg_2_0.starGroup = arg_2_1.reportStar
		arg_2_0.petsA = arg_2_0.heroGroupA["pet" .. arg_2_0.peakArena:getCurrentBattleRound(1)]
		arg_2_0.petsB = arg_2_0.heroGroupB["pet" .. arg_2_0.peakArena:getCurrentBattleRound(1)]
	elseif arg_2_0.campaignType == var_0_12.CampaignType.MARCH and arg_2_0.marchModel.mapInfo then
		arg_2_0.medicineNum = arg_2_0.marchModel.mapInfo.power_drink or 0
	elseif arg_2_0.campaignType == var_0_12.CampaignType.TREASURE then
		arg_2_0.mapID_ = var_0_12.tables.treasure:map(arg_2_1.treasureAwardType)
	elseif arg_2_0.campaignType == var_0_12.CampaignType.GUILD then
		arg_2_0.group_ = arg_2_1.currentGroup or 1
		arg_2_0.guildNormalDrop = arg_2_1.guildNormalDrop or {}
	elseif arg_2_0.campaignType == var_0_12.CampaignType.CHALLENGE then
		arg_2_0.challengeType = arg_2_1.challengeType

		if arg_2_0.challengeType == var_0_12.ChallengeType.SecondTeam or arg_2_0.challengeType == var_0_12.ChallengeType.BackwardSecondTeam then
			arg_2_0.secondTeamBCount_ = var_0_3:timingOfReinforcement(arg_2_0.battleID)
			arg_2_0.specialMonsterWave_ = var_0_3:specialMonsterWave(arg_2_0.battleID)
			arg_2_0.specialMonsterBuff_ = var_0_3:specialMonsterBuff(arg_2_0.battleID)
		else
			arg_2_0.secondTeamBCount_ = {}
		end

		arg_2_0.secondTeamB_ = {}
	elseif arg_2_0.campaignType == var_0_12.CampaignType.CLOUD_LADDER or arg_2_0.campaignType == var_0_12.CampaignType.CLOUD_ROAD or arg_2_0.campaignType == var_0_12.CampaignType.CLOUD_TEMPLE then
		arg_2_0.battleBuffs = arg_2_1.add_buff_ids or {}
		arg_2_0.addBuffHeros = arg_2_1.addBuffHeros or {}
		arg_2_0.xixueBuff = arg_2_1.xixueBuff or {}
	elseif arg_2_0.campaignType == var_0_12.CampaignType.SINGLE_DAY then
		arg_2_0.missionID = arg_2_1.missionID
	elseif arg_2_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL then
		arg_2_0.sceneFighterHero = arg_2_1.sceneFighter
		arg_2_0.conquerSchoolTeamID = arg_2_1.conquerSchoolTeamID
	elseif arg_2_0.campaignType == var_0_12.CampaignType.MEMORIES_OF_SCHOOL and arg_2_1.pvp == 1 then
		arg_2_0.herosB = arg_2_0.heroGroupB

		if arg_2_1.memories_awards then
			arg_2_0.memories_awards = arg_2_1.memories_awards
		end
	elseif arg_2_0.campaignType == var_0_12.CampaignType.MEMORIES_OF_SCHOOL then
		arg_2_0.herosB = arg_2_0.heroGroupB
		arg_2_0.group_ = arg_2_1.currentGroup or 1
	elseif arg_2_0.campaignType == var_0_12.CampaignType.OCCULT then
		arg_2_0.subId = arg_2_1.sub_id
		arg_2_0.chapterId = arg_2_1.chapter_id
	elseif arg_2_0.campaignType == var_0_12.CampaignType.TWO_YEARS then
		arg_2_0.herosB = arg_2_0.heroGroupB
		arg_2_0.group_ = arg_2_1.currentGroup or 1
	elseif arg_2_0.campaignType == var_0_12.CampaignType.CHAPTER_BOSS then
		arg_2_0.chapterId = arg_2_1.chapter_id
	else
		arg_2_0.assistPartner = arg_2_1.assistPartner
		arg_2_0.isAssist = arg_2_1.isAssist
		arg_2_0.assistID = arg_2_1.assistID
		arg_2_0.isPartnerdrop = arg_2_1.isPartnerdrop
	end
end

function var_0_0.onEnterTransitionFinish(arg_3_0)
	var_0_0.super.onEnterTransitionFinish(arg_3_0)
	arg_3_0:setupConfig()
	arg_3_0:setupWindows()
	arg_3_0:setupButtons()
	arg_3_0:setAnimationInterval()
	arg_3_0:init()
end

function var_0_0.onEnter(arg_4_0)
	arg_4_0:setupMusic()
end

function var_0_0.onExit(arg_5_0)
	audio.stopAllSounds()
	audio.stopMusic()
	arg_5_0:pauseBattle()
	arg_5_0:setAnimationInterval(true)

	local var_5_0 = var_0_12.tables.sound:getSound("home_bg_music")

	audio.playMusic(var_5_0, true)
	collectgarbage("collect")
	var_0_13.ctx.battle.releaseCache()
	cc.Director:getInstance():purgeCachedData()
end

function var_0_0.setAnimationInterval(arg_6_0, arg_6_1)
	local var_6_0 = cc.Director:getInstance()

	if arg_6_1 then
		var_6_0:setAnimationInterval(1 / var_0_12.tables.misc.fps)

		return
	end

	if var_0_13.ctx.battle.timeScale == 1 then
		var_6_0:setAnimationInterval(1 / var_0_12.tables.misc.fps)
	else
		var_6_0:setAnimationInterval(0.022222222222222223)
	end
end

function var_0_0.formatRegionArenaHeros(arg_7_0, arg_7_1)
	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		if var_0_12.isSuperHero(iter_7_1) then
			local var_7_0 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_7_1 = {
				0,
				0,
				0,
				0,
				0,
				0
			}
			local var_7_2 = {
				31,
				31,
				31,
				31,
				31,
				31
			}

			arg_7_0:renewSuperHeroInfo(iter_7_1, var_7_0, var_7_1, var_7_2)
		elseif iter_7_1:isCanAwaken() then
			local var_7_3 = {
				90,
				90,
				70,
				50,
				30
			}
			local var_7_4 = {
				1,
				1,
				1,
				1,
				1,
				1
			}
			local var_7_5 = {
				1,
				1,
				1,
				1,
				1,
				1
			}

			arg_7_0:renewHeroInfo(iter_7_1, var_7_3, var_7_4, var_7_5)
		else
			local var_7_6 = {
				90,
				90,
				70,
				50,
				0
			}
			local var_7_7 = {
				0,
				1,
				1,
				1,
				1,
				1
			}
			local var_7_8 = {
				0,
				1,
				1,
				1,
				1,
				1
			}

			arg_7_0:renewHeroInfo(iter_7_1, var_7_6, var_7_7, var_7_8)
		end

		iter_7_1.practice_attr_ = {
			0,
			0,
			0
		}

		iter_7_1:updatePracticeAwardAttr()
	end
end

function var_0_0.renewHeroInfo(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = 14
	local var_8_1 = 90

	if not arg_8_0.isfriend and arg_8_1:isCanAwaken() and not arg_8_1:isAwaken() then
		arg_8_1:setTableID(arg_8_1:afterAwakenID())
	end

	arg_8_1.color_ = var_8_0
	arg_8_1.level_ = var_8_1
	arg_8_1.skillLev_ = {}
	arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Energy] = tonumber(arg_8_2[var_0_12.SKILL_INDEX.Energy]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Energy]

	if arg_8_1.color_ >= var_0_12.EquipQuality.GREEN then
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Green] = tonumber(arg_8_2[var_0_12.SKILL_INDEX.Green]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Green]
	else
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Green] = false
	end

	if arg_8_1.color_ >= var_0_12.EquipQuality.BLUE then
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Blue] = tonumber(arg_8_2[var_0_12.SKILL_INDEX.Blue]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Blue]
	else
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Blue] = false
	end

	if arg_8_1.color_ >= var_0_12.EquipQuality.PURPLE then
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Purple] = tonumber(arg_8_2[var_0_12.SKILL_INDEX.Purple]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Purple]
	else
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Purple] = false
	end

	if arg_8_1:isAwaken() then
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Awake] = tonumber(arg_8_2[var_0_12.SKILL_INDEX.Awake]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Awake]
	else
		arg_8_1.skillLev_[var_0_12.SKILL_INDEX.Awake] = false
	end

	arg_8_1.equips_ = {}

	for iter_8_0 = 1, var_0_20 do
		table.insert(arg_8_1.equips_, tonumber(arg_8_4[iter_8_0]))
	end

	arg_8_1.fumo_ = {}

	for iter_8_1 = 1, var_0_20 do
		table.insert(arg_8_1.fumo_, tonumber(arg_8_3[iter_8_1]))
	end

	arg_8_1.fumoLev_ = {}

	for iter_8_2 = 1, var_0_20 do
		local var_8_2 = arg_8_1:getEquipByIndex(iter_8_2)

		table.insert(arg_8_1.fumoLev_, tonumber(var_8_2:getMaxFumoStar()))
	end
end

function var_0_0.renewSuperHeroInfo(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4)
	local var_9_0 = 1
	local var_9_1 = 100

	if not arg_9_0.isfriend and arg_9_1:isCanAwaken() and not arg_9_1:isAwaken() then
		arg_9_1:setTableID(arg_9_1:afterAwakenID())
	end

	arg_9_1.color_ = var_9_0
	arg_9_1.level_ = var_9_1
	arg_9_1.skillLev_ = {}
	arg_9_1.skillLev_[var_0_12.SKILL_INDEX.Energy] = tonumber(arg_9_2[var_0_12.SKILL_INDEX.Energy]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Energy]
	arg_9_1.skillLev_[var_0_12.SKILL_INDEX.Green] = tonumber(arg_9_2[var_0_12.SKILL_INDEX.Green]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Green]
	arg_9_1.skillLev_[var_0_12.SKILL_INDEX.Blue] = tonumber(arg_9_2[var_0_12.SKILL_INDEX.Blue]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Blue]
	arg_9_1.skillLev_[var_0_12.SKILL_INDEX.Purple] = tonumber(arg_9_2[var_0_12.SKILL_INDEX.Purple]) + var_0_12.SKILL_EXTRA[var_0_12.SKILL_INDEX.Purple]
	arg_9_1.equips_ = {}

	for iter_9_0 = 1, var_0_20 do
		table.insert(arg_9_1.equips_, tonumber(arg_9_4[iter_9_0]))
	end

	arg_9_1.fumo_ = {}

	for iter_9_1 = 1, var_0_20 do
		table.insert(arg_9_1.fumo_, tonumber(arg_9_3[iter_9_1]))
	end

	arg_9_1.fumoLev_ = {}

	for iter_9_2 = 1, var_0_20 do
		local var_9_2 = arg_9_1:getEquipByIndex(iter_9_2)

		table.insert(arg_9_1.fumoLev_, tonumber(var_9_2:getMaxFumoStar()))
	end
end

function var_0_0.init(arg_10_0)
	collectgarbage("collect")

	if arg_10_0.campaignType == var_0_12.CampaignType.SUPER_ARENA then
		arg_10_0.herosB = arg_10_0.heroGroupB["team" .. arg_10_0.peakArena:getCurrentBattleRound()]
		arg_10_0.summonMonsters = arg_10_0.summonGroup["team" .. arg_10_0.peakArena:getCurrentBattleRound()]
		arg_10_0.reportStar_ = arg_10_0.starGroup["team" .. arg_10_0.peakArena:getCurrentBattleRound()]
	elseif arg_10_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
		arg_10_0.herosB = arg_10_0.heroGroupB[1]
	else
		arg_10_0.herosB = arg_10_0.heroGroupB[arg_10_0.group_]
	end

	arg_10_0:setupBasicData()

	if arg_10_0.battleTopWindow:getGuanQiaLabel() then
		if arg_10_0.campaignType == var_0_12.CampaignType.SUPER_ARENA then
			arg_10_0.battleTopWindow:getGuanQiaContainer():hide()

			if arg_10_0.leftScoreSp_ then
				arg_10_0.leftScoreSp_:removeSelf()
				arg_10_0.rightScoreSp_:removeSelf()
				arg_10_0.roundSp_:removeSelf()
			end

			arg_10_0.leftScoreSp_ = var_0_12.AssetLoader.get():loadSprite("images/battle/arena_score" .. arg_10_0.peakArena:getWinScore() .. ".png")

			arg_10_0.leftScoreSp_:align(display.CENTER, 436, 615):addTo(arg_10_0, -1)

			arg_10_0.rightScoreSp_ = var_0_12.AssetLoader.get():loadSprite("images/battle/arena_score" .. arg_10_0.peakArena:getLoseScore() .. ".png")

			arg_10_0.rightScoreSp_:align(display.CENTER, 802, 615):addTo(arg_10_0, -1)

			arg_10_0.roundSp_ = var_0_12.AssetLoader.get():loadSprite("images/battle/arena_round" .. arg_10_0.peakArena:getCurrentBattleRound() .. ".png")

			arg_10_0.roundSp_:align(display.CENTER, 621, 631):addTo(arg_10_0, -1)
		elseif arg_10_0.campaignType == var_0_12.CampaignType.ARENA or arg_10_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_10_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_10_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_10_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD or arg_10_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT or arg_10_0.campaignType == var_0_12.CampaignType.LVBU_FESTIVAL or arg_10_0.campaignType == var_0_12.CampaignType.SNOW then
			arg_10_0.battleTopWindow:getGuanQiaContainer():hide()
		else
			arg_10_0.battleTopWindow:getGuanQiaLabel():setString(arg_10_0.group_ .. " / " .. #arg_10_0.heroGroupB)
		end
	end

	if arg_10_0.group_ == 1 and arg_10_0.stories[1] and arg_10_0.stories[1] > 0 then
		local var_10_0 = var_0_12.WindowManager.get():openWindow("story", {
			story_state = 1,
			story_id = arg_10_0.stories[1],
			battle_id = arg_10_0.battleID
		})

		cc.EventProxy.new(var_10_0, var_10_0):addEventListener(var_0_12.event.STORY_COMPLETE, function(arg_11_0)
			if arg_11_0.state == 1 then
				arg_10_0:sendStoryOperationLog(1)
				arg_10_0:startBattle()
			end
		end)
	else
		arg_10_0:startBattle()
	end

	if arg_10_0.noResult then
		arg_10_0.battleTopWindow:getAwardLabel():hide()
		arg_10_0.battleTopWindow:getTongqianLabel():hide()
	end

	if arg_10_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL then
		arg_10_0.sceneFighter:initSpecial()
	end
end

function var_0_0.setupBasicData(arg_12_0)
	arg_12_0:setupBackground_()
	arg_12_0:resetConfig()
	arg_12_0:clearFormation()
	arg_12_0:setFormation()
	arg_12_0:updateFighters()
	arg_12_0:setChallengeConfig()
end

function var_0_0.setupConfig(arg_13_0)
	var_0_13.ctx.battle.teamA = {}
	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.schoolSceneFighter = nil
	var_0_13.ctx.battle.summonMonsters = {}
	var_0_13.ctx.battle.summonMonsterNum = {}
	var_0_13.ctx.battle.globalBuffsA = {}
	var_0_13.ctx.battle.globalBuffsB = {}
	var_0_13.ctx.battle.globalBuffs = {}
	var_0_13.ctx.battle.applyUnits = {}
	var_0_13.ctx.battle.moveUnits = {}
	var_0_13.ctx.battle.moveAttackUnits = {}
	var_0_13.ctx.battle.yOrder = {}
	var_0_13.ctx.battle.count = 0
	var_0_13.ctx.battle.isSpecialSkill = false
	var_0_13.ctx.battle.isActivity = false
	var_0_13.ctx.battle.nightCount = 0
	var_0_13.ctx.battle.timeCount = 0
	var_0_13.ctx.battle.soundQueue = {}
	var_0_13.ctx.battle.isEnergySkilling = false
	var_0_13.ctx.battle.playerLayer = display.newNode()

	var_0_13.ctx.battle.playerLayer:size(var_0_12.STAGE_WIDTH, var_0_12.STAGE_HEIGHT)
	var_0_13.ctx.battle.playerLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0, 1)

	var_0_13.ctx.battle.unitLayer = display.newNode()

	var_0_13.ctx.battle.unitLayer:size(var_0_12.STAGE_WIDTH, var_0_12.STAGE_HEIGHT)
	var_0_13.ctx.battle.unitLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0, 2)

	var_0_13.ctx.battle.blackLayer = display.newColorLayer(cc.c4b(0, 0, 0, 170))

	var_0_13.ctx.battle.blackLayer:size(arg_13_0:getContentSize())
	var_0_13.ctx.battle.blackLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0, 0)
	var_0_13.ctx.battle.blackLayer:hide()

	var_0_13.ctx.battle.unitBottomLayer = display.newNode()

	var_0_13.ctx.battle.unitBottomLayer:size(var_0_12.STAGE_WIDTH, var_0_12.STAGE_HEIGHT)
	var_0_13.ctx.battle.unitBottomLayer:align(display.LEFT_BOTTOM, 0, 0):addTo(arg_13_0, 0)

	var_0_13.ctx.battle.battleType = arg_13_0.battleType
	var_0_13.ctx.battle.autoA = arg_13_0:isAutoA()
	var_0_13.ctx.battle.autoB = true
	var_0_13.ctx.battle.dropAwardCount = 0
	var_0_13.ctx.battle.dropManaCount = 0
	var_0_13.ctx.battle.isEnd = false
	var_0_13.ctx.battle.walk2NextBattle_ = false

	if arg_13_0.campaignType == var_0_12.CampaignType.GUILD then
		var_0_13.ctx.battle.guildNormalDrop = arg_13_0.guildNormalDrop
	else
		var_0_13.ctx.battle.guildNormalDrop = {}
	end

	var_0_13.ctx.battle.campaignType = arg_13_0.campaignType
	var_0_13.ctx.battle.battleID = arg_13_0.battleID

	if arg_13_0.campaignID then
		var_0_13.ctx.battle.chapter = var_0_10:chapter(arg_13_0.campaignID)
	else
		var_0_13.ctx.battle.chapter = nil
	end

	var_0_13.ctx.battle.allFighterHurt = 0
	var_0_13.ctx.battle.isCountHurtNum = false
	var_0_13.ctx.battle.infoListener = {}
	var_0_13.ctx.battle.infoList = {}
end

function var_0_0.resetConfig(arg_14_0)
	var_0_13.ctx.battle.globalBuffsA = {}
	var_0_13.ctx.battle.globalBuffsB = {}
	var_0_13.ctx.battle.globalBuffs = {}
	var_0_13.ctx.battle.yOrder = {}
	var_0_13.ctx.battle.count = 0
	var_0_13.ctx.battle.isSpecialSkill = false
	var_0_13.ctx.battle.isActivity = false
	var_0_13.ctx.battle.nightCount = 0

	if arg_14_0.campaignType ~= var_0_12.CampaignType.GUILD then
		var_0_13.ctx.battle.timeCount = 0
	end

	var_0_13.ctx.battle.isEnergySkilling = false

	var_0_13.ctx.battle.unitLayer:removeAllChildren()
	var_0_13.ctx.battle.unitBottomLayer:removeAllChildren()
	var_0_13.ctx.battle.unitLayer:show()
	var_0_13.ctx.battle.unitBottomLayer:show()

	arg_14_0.battleStar_ = nil
	arg_14_0.stopTimeCount_ = false
	arg_14_0.isBattleEnded_ = false
	var_0_13.ctx.battle.isEnd = false
	arg_14_0.timeOut_ = false
	var_0_13.ctx.battle.isCountHurtNum = false
	var_0_13.ctx.battle.allFighterHurt = 0
	var_0_13.ctx.battle.teamAEnd = false
	var_0_13.ctx.battle.teamBEnd = false

	arg_14_0:clearPreBattleShow()
end

function var_0_0.clear(arg_15_0)
	for iter_15_0, iter_15_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if not iter_15_1:isDeath() then
			iter_15_1:cleanAllBuffs()
		end

		iter_15_1:clearResource()
	end

	for iter_15_2, iter_15_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if not iter_15_3:isDeath() then
			iter_15_3:cleanAllBuffs()
		end

		iter_15_3:clearResource()
	end

	for iter_15_4, iter_15_5 in ipairs(var_0_13.ctx.battle.summonMonsters) do
		iter_15_5:cleanAllBuffs()
		iter_15_5:clearResource()
	end

	if var_0_13.ctx.battle.schoolSceneFighter then
		var_0_13.ctx.battle.schoolSceneFighter:cleanAllBuffs()
		var_0_13.ctx.battle.schoolSceneFighter:clearResource()
	end

	var_0_13.ctx.battle.unitLayer:removeAllChildren()
	var_0_13.ctx.battle.unitBottomLayer:removeAllChildren()
end

function var_0_0.clearFormation(arg_16_0, arg_16_1)
	if arg_16_1 then
		for iter_16_0 = #var_0_13.ctx.battle.teamA, 1, -1 do
			local var_16_0 = var_0_13.ctx.battle.teamA[iter_16_0]

			if not tolua.isnull(var_16_0.fighterModel) then
				var_16_0:getFighterModel():stopAttackEffect_()
				var_16_0.fighterModel:removeSelf()
			end

			if var_16_0:getSummonType() ~= var_0_12.summonMonsterType.None then
				table.remove(var_0_13.ctx.battle.teamA, iter_16_0)
			end
		end

		for iter_16_1 = #var_0_13.ctx.battle.teamB, 1, -1 do
			local var_16_1 = var_0_13.ctx.battle.teamB[iter_16_1]

			if not tolua.isnull(var_16_1.fighterModel) then
				var_16_1:getFighterModel():stopAttackEffect_()
				var_16_1.fighterModel:removeSelf()
			end

			if var_16_1:getSummonType() ~= var_0_12.summonMonsterType.None then
				table.remove(var_0_13.ctx.battle.teamB, iter_16_1)
			end
		end

		var_0_13.ctx.battle.playerLayer:removeAllChildren()

		return
	end

	for iter_16_2, iter_16_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_16_3:getFighterModel():clearTracks()
		transition.stopTarget(iter_16_3.fighterModel)
		iter_16_3.fighterModel:removeSelf()
	end

	for iter_16_4 = #var_0_13.ctx.battle.teamA, 1, -1 do
		local var_16_2 = var_0_13.ctx.battle.teamA[iter_16_4]

		if var_16_2:getSummonType() ~= var_0_12.summonMonsterType.None and var_16_2:getSummonType() ~= var_0_12.summonMonsterType.Mirrow and var_16_2:getSummonType() ~= var_0_12.summonMonsterType.Pet then
			table.remove(var_0_13.ctx.battle.teamA, iter_16_4)
			var_16_2:getFighterModel():clearTracks()
			transition.stopTarget(var_16_2.fighterModel)
			var_16_2.fighterModel:removeSelf()
		end
	end

	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.schoolSceneFighter = nil
end

function var_0_0.setFormation(arg_17_0)
	local var_17_0 = arg_17_0:initFormation()

	arg_17_0:setFormationPosition(var_17_0)
	arg_17_0:setAvatar()
end

function var_0_0.newFighter(arg_18_0, arg_18_1, arg_18_2, arg_18_3)
	local var_18_0 = arg_18_1:className()
	local var_18_1 = var_0_13.ctx.battle.requireFighter(var_18_0).new({
		is_arena = arg_18_0:isArena()
	})

	var_18_1:populateWithHero(arg_18_1)
	var_18_1:setTeamType(arg_18_2)
	var_18_1:initModels()
	var_18_1:setTimeScale(var_0_13.ctx.battle.timeScale)
	var_18_1.fighterModel:addTo(var_0_13.ctx.battle.playerLayer)
	var_18_1:getFighterModel():idle()

	local var_18_2 = arg_18_2 - 1

	var_18_1.fighterModel:initHeaderView(var_18_2)
	var_18_1:getFighterModel():flipX(arg_18_3)

	return var_18_1
end

function var_0_0.initFormation(arg_19_0)
	local var_19_0 = next(var_0_13.ctx.battle.teamA) == nil

	if next(var_0_13.ctx.battle.teamA) == nil then
		for iter_19_0, iter_19_1 in ipairs(arg_19_0.herosA) do
			table.insert(var_0_13.ctx.battle.teamA, arg_19_0:newFighter(iter_19_1, var_0_12.TeamType.A, false))
		end

		for iter_19_2, iter_19_3 in ipairs(arg_19_0.petsA or {}) do
			table.insert(var_0_13.ctx.battle.teamA, arg_19_0:newFighter(iter_19_3, var_0_12.TeamType.A, false))
		end
	else
		for iter_19_4, iter_19_5 in ipairs(var_0_13.ctx.battle.teamA) do
			if not iter_19_5:isDeath() then
				iter_19_5.fighterModel.headerView_:setCount(0)
				iter_19_5:getFighterModel():idle()
				iter_19_5:init()
			end
		end
	end

	if arg_19_0.challengeType == var_0_12.ChallengeType.LimitDistance then
		for iter_19_6, iter_19_7 in ipairs(var_0_13.ctx.battle.teamA) do
			local var_19_1 = iter_19_7.getFrontSkillDistance

			function iter_19_7.getFrontSkillDistance(arg_20_0)
				return math.min(var_0_12.tables.misc.maxChallengeDistance, var_19_1(arg_20_0))
			end
		end
	end

	for iter_19_8, iter_19_9 in ipairs(arg_19_0.herosB) do
		local var_19_2 = arg_19_0:newFighter(iter_19_9, var_0_12.TeamType.B, true)

		arg_19_0:setupChallengeFighterImmortal(1, var_19_2)
		table.insert(var_0_13.ctx.battle.teamB, var_19_2)

		if iter_19_8 == #arg_19_0.herosB and arg_19_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst then
			var_19_2:setLeader()
		end

		var_19_2.dropItems_ = {}
		var_19_2.dropMana_ = 0

		if arg_19_0.dropMana then
			var_19_2.dropMana_ = arg_19_0.dropMana[arg_19_0.group_][iter_19_8]
		end

		for iter_19_10, iter_19_11 in ipairs(arg_19_0.dropItems) do
			if iter_19_11.drop_[1] == arg_19_0.group_ and iter_19_11.drop_[2] == iter_19_8 then
				table.insert(var_19_2.dropItems_, iter_19_11)
			end
		end
	end

	for iter_19_12, iter_19_13 in ipairs(arg_19_0.secondTeamBCount_ or {}) do
		arg_19_0.secondTeamB_[iter_19_12] = {}

		for iter_19_14, iter_19_15 in ipairs(arg_19_0.herosB) do
			local var_19_3 = arg_19_0:newFighter(iter_19_15, var_0_12.TeamType.B, true)

			arg_19_0:setupChallengeFighterImmortal(iter_19_12 + 1, var_19_3)
			table.insert(arg_19_0.secondTeamB_[iter_19_12], var_19_3)

			if iter_19_12 == #arg_19_0.herosB and arg_19_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst then
				var_19_3:setLeader()
			end

			var_19_3.fighterModel:hide()

			var_19_3.dropItems_ = {}
			var_19_3.dropMana_ = 0
		end
	end

	for iter_19_16, iter_19_17 in ipairs(arg_19_0.petsB or {}) do
		table.insert(var_0_13.ctx.battle.teamB, arg_19_0:newFighter(iter_19_17, var_0_12.TeamType.B, true))
	end

	if arg_19_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL then
		arg_19_0.sceneFighter = var_0_13.ctx.battle.requireFighter("School_SceneFighter").new({
			inspireBuffLev = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.CONQUER_SCHOOL):getIsBuffOn(),
			buffType = var_0_12.tables.conquerSchoolCampaign:buffID(arg_19_0.campaignID)
		})

		arg_19_0.sceneFighter:populateWithHero(arg_19_0.sceneFighterHero)

		var_0_13.ctx.battle.schoolSceneFighter = arg_19_0.sceneFighter
	end

	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		for iter_19_18, iter_19_19 in pairs(arg_19_0.summonMonsters) do
			local var_19_4 = string.sub(iter_19_18, 1, 1) == "A" and var_0_12.TeamType.A or var_0_12.TeamType.B
			local var_19_5 = arg_19_0:newFighter(iter_19_19, var_19_4, false)

			var_19_5.fighterIndex = iter_19_18

			var_19_5:setFormationDelay(0, 100)
			var_19_5.fighterModel:removeSelf()

			var_0_13.ctx.battle.summonMonsters[iter_19_18] = var_19_5

			if not var_0_13.ctx.battle.summonMonsterNum[var_19_4] then
				var_0_13.ctx.battle.summonMonsterNum[var_19_4] = 0
			end

			var_0_13.ctx.battle.summonMonsterNum[var_19_4] = var_0_13.ctx.battle.summonMonsterNum[var_19_4] + 1
		end
	end

	return var_19_0
end

function var_0_0.setupChallengeFighterImmortal(arg_21_0, arg_21_1, arg_21_2)
	if arg_21_0.challengeType ~= var_0_12.ChallengeType.SecondTeam and arg_21_0.challengeType ~= var_0_12.ChallengeType.BackwardSecondTeam then
		return arg_21_2
	end

	for iter_21_0, iter_21_1 in ipairs(arg_21_0.specialMonsterWave_ or {}) do
		if arg_21_1 == iter_21_0 then
			if arg_21_0.specialMonsterBuff_[iter_21_0] == var_0_12.ChallengeSpecialMonsterBuff.AD_IMMORTAL then
				arg_21_2.isADImmortal_ = true
			elseif arg_21_0.specialMonsterBuff_[iter_21_0] == var_0_12.ChallengeSpecialMonsterBuff.AP_IMMORTAL then
				arg_21_2.isAPImmortal_ = true
			elseif arg_21_0.specialMonsterBuff_[iter_21_0] == var_0_12.ChallengeSpecialMonsterBuff.ALL_IMMORTAL then
				arg_21_2.isImmortal_ = true
			end
		end
	end
end

function var_0_0.setFormationPosition(arg_22_0, arg_22_1)
	if var_0_13.ctx.battle.battleType ~= var_0_12.BattleType.ReplayReport then
		if arg_22_1 then
			table.sort(var_0_13.ctx.battle.teamA, function(arg_23_0, arg_23_1)
				return arg_23_0:getDistance() < arg_23_1:getDistance()
			end)
		end

		table.sort(var_0_13.ctx.battle.teamB, function(arg_24_0, arg_24_1)
			return arg_24_0:getDistance() < arg_24_1:getDistance()
		end)
	end

	local var_22_0 = 1
	local var_22_1 = 0
	local var_22_2 = 9

	for iter_22_0 = 1, #var_0_13.ctx.battle.teamA do
		local var_22_3 = var_0_13.ctx.battle.teamA[iter_22_0]

		if not var_22_3:isDeath() then
			var_22_3.fighterIndex = "A|" .. iter_22_0
			var_22_1 = var_22_3:setFormation(var_22_0, var_22_1, var_22_2)

			var_22_3:setFormationDelay(var_0_12.tables.battleConfig.skillDelayQueue[var_22_0], var_0_12.tables.battleConfig.formationWalkQueue[var_22_0])
			table.insert(var_0_13.ctx.battle.yOrder, var_22_3)

			var_22_0 = var_22_0 + 1
			var_22_2 = var_22_2 - 2
		end
	end

	local var_22_4 = 0
	local var_22_5 = 10

	for iter_22_1 = 1, #var_0_13.ctx.battle.teamB do
		local var_22_6 = var_0_13.ctx.battle.teamB[iter_22_1]

		var_22_6.fighterIndex = "B|" .. iter_22_1
		var_22_4 = var_22_6:setFormation(iter_22_1, var_22_4, var_22_5)

		var_22_6:setFormationDelay(var_0_12.tables.battleConfig.skillDelayQueue[iter_22_1], var_0_12.tables.battleConfig.formationWalkQueue[iter_22_1])
		table.insert(var_0_13.ctx.battle.yOrder, var_22_6)

		var_22_5 = var_22_5 - 2
	end

	if arg_22_0.sceneFighter then
		arg_22_0.sceneFighter.fighterIndex = "C|1"
	end
end

function var_0_0.setAvatar(arg_25_0)
	local var_25_0 = var_0_13.ctx.battle.teamA

	if arg_25_0.location and arg_25_0.location == 0 then
		var_25_0 = var_0_13.ctx.battle.teamB
	end

	local var_25_1 = 0

	for iter_25_0, iter_25_1 in ipairs(var_25_0) do
		if iter_25_1:getSummonType() == var_0_12.summonMonsterType.None then
			var_25_1 = var_25_1 + 1

			local var_25_2 = arg_25_0.battleBottomWindow:getButtonByIndex(var_25_1)

			var_25_2:removeAllNodeEventListeners()
			var_25_2:setTouchEnabled(true)
			var_25_2:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_26_0)
				arg_25_0:clickAvatar(iter_25_1, arg_26_0)

				return true
			end)

			local var_25_3 = arg_25_0.battleBottomWindow:getHpBarByIndex(var_25_1)
			local var_25_4 = arg_25_0.battleBottomWindow:getMpBarByIndex(var_25_1)

			iter_25_1:setAvatar(var_25_2, var_25_3, var_25_4, var_25_1)
		elseif iter_25_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			local var_25_5 = arg_25_0.battleBottomWindow:getPetAvatar()

			var_25_5:removeAllNodeEventListeners()
			var_25_5:setTouchEnabled(true)
			var_25_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
				arg_25_0:clickAvatar(iter_25_1, arg_27_0)

				return true
			end)

			local var_25_6 = arg_25_0.battleBottomWindow:getPetMPBar()

			iter_25_1:setAvatar(var_25_5, nil, var_25_6)
		end
	end

	for iter_25_2, iter_25_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_25_3:isBoss() then
			iter_25_3:setBossAvatar()
		end
	end
end

function var_0_0.setupGlobalBuffs(arg_28_0)
	for iter_28_0, iter_28_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_28_1:setupBattleAttrInfo()
		iter_28_1:setGlobalBuffs()
	end

	for iter_28_2, iter_28_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_28_3:setupBattleAttrInfo()
		iter_28_3:setGlobalBuffs()
	end
end

function var_0_0.updateFighters(arg_29_0)
	for iter_29_0, iter_29_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if var_0_13.ctx.battle.battleType == var_0_12.BattleType.ReplayReport then
			iter_29_1:setupReport(iter_29_1.hero_:getReportData())
		end
	end

	for iter_29_2, iter_29_3 in pairs(var_0_13.ctx.battle.teamB) do
		if var_0_13.ctx.battle.battleType == var_0_12.BattleType.ReplayReport then
			iter_29_3:setupReport(iter_29_3.hero_:getReportData())
		end
	end

	if var_0_13.ctx.battle.battleType == var_0_12.BattleType.ReplayReport and arg_29_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL then
		arg_29_0.sceneFighter:setupReport(arg_29_0.sceneFighter.hero_:getReportData())
	end

	for iter_29_4, iter_29_5 in pairs(var_0_13.ctx.battle.summonMonsters) do
		if var_0_13.ctx.battle.battleType == var_0_12.BattleType.ReplayReport then
			iter_29_5:setupReport(iter_29_5.hero_:getReportData())
		end
	end

	arg_29_0:setupGlobalBuffs()

	local function var_29_0(arg_30_0, arg_30_1, arg_30_2, arg_30_3)
		local var_30_0 = {}

		for iter_30_0, iter_30_1 in ipairs(arg_30_0) do
			local var_30_1 = var_0_9.new({
				tableID = iter_30_1,
				start = var_0_13.ctx.battle.count,
				level = arg_30_1:getSkillLevelByID(arg_30_3),
				skillID = arg_30_3,
				fighter = arg_30_1,
				target = arg_30_2
			})

			var_30_1:setIsHit(true)
			var_30_1:setDirection(arg_30_1:getFighterModel():getFlipX())
			table.insert(var_30_0, var_30_1)
		end

		return var_30_0
	end

	for iter_29_6, iter_29_7 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_29_7:setupHpLimit()

		if iter_29_7.hero_.healthStatus and iter_29_7.hero_.healthStatus.health == 1 and (arg_29_0.campaignType == var_0_12.CampaignType.MARCH or arg_29_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_29_0.campaignType == var_0_12.CampaignType.MEMORIES_OF_SCHOOL or arg_29_0.campaignType == var_0_12.CampaignType.TWO_YEARS or arg_29_0.campaignType == var_0_12.CampaignType.WAR_CAMP or arg_29_0.campaignType == var_0_12.CampaignType.WAR_CAMP_ENEMY) then
			iter_29_7:updateHp(iter_29_7.hero_.healthStatus.hp)
			iter_29_7:updateEnergyTo(iter_29_7.hero_.healthStatus.mp)

			if (iter_29_7.hero_.healthStatus.is_reborn or 0) > 0 and iter_29_7:canReborn() then
				iter_29_7.hasReborn_ = true
			end
		elseif iter_29_7.hero_.healthStatus and (arg_29_0.campaignType == var_0_12.CampaignType.ZHUGE_ENEMY or arg_29_0.campaignType == var_0_12.CampaignType.OCCULT or arg_29_0.campaignType == var_0_12.CampaignType.OCCULT_COOPERATION) then
			iter_29_7:updateHp(iter_29_7.hero_.healthStatus.hp)
			iter_29_7:updateEnergyTo(iter_29_7.hero_.healthStatus.mp or 0)

			if (iter_29_7.hero_.healthStatus.is_reborn or 0) > 0 and iter_29_7:canReborn() then
				iter_29_7.hasReborn_ = true
			end
		elseif (arg_29_0.group_ == 1 or arg_29_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_29_0.campaignType == var_0_12.CampaignType.GUILD) and not iter_29_7:isDeath() then
			iter_29_7:updateHp(iter_29_7:getHpLimit())
		end

		iter_29_7.hero_.healthStatus = nil

		if arg_29_0.isAwakeCampaign and iter_29_7.hero_.type == 1 and iter_29_7.hero_:getTableID() == arg_29_0.awakeHero:getTableID() then
			iter_29_7.isAwakeHero = true
			iter_29_7.awakeMissionGoalType = arg_29_0.awakeMissionGoalType

			if arg_29_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
				iter_29_7.awakeMonsterID = var_0_12.tables.mission:challengeNums(arg_29_0.awakeMissionID)
			elseif arg_29_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				iter_29_7.awakeDamageGoal = var_0_12.tables.mission:challengeNums(arg_29_0.awakeMissionID)
			end

			arg_29_0.awakeFighter = iter_29_7
		end

		if arg_29_0.isPetAwakeCampaign and iter_29_7:getTableID() == arg_29_0.awakePet:getTableID() then
			iter_29_7.isAwakeHero = true
			iter_29_7.awakeMissionGoalType = arg_29_0.petAwakeMissionGoalType

			if arg_29_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
				iter_29_7.awakeMonsterID = var_0_12.tables.mission:challengeNums(arg_29_0.petAwakeMissionID)
			elseif arg_29_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				iter_29_7.awakeDamageGoal = var_0_12.tables.mission:challengeNums(arg_29_0.petAwakeMissionID)
			end

			arg_29_0.petAwakeFighter = iter_29_7
		end

		if iter_29_7:isDeath() and not iter_29_7.reviveCount_ then
			iter_29_7.fighterModel:hide()
		end

		if arg_29_0.campaignType == var_0_12.CampaignType.CLOUD_LADDER or arg_29_0.campaignType == var_0_12.CampaignType.CLOUD_ROAD or arg_29_0.campaignType == var_0_12.CampaignType.CLOUD_TEMPLE then
			iter_29_7:addBuffs(var_29_0(arg_29_0.xixueBuff, iter_29_7, iter_29_7, iter_29_7:getEnergySkillID()))

			if next(arg_29_0.battleBuffs) and arg_29_0.addBuffHeros[iter_29_7:getTableID()] and not iter_29_7:isDeath() then
				iter_29_7:addBuffs(var_29_0(arg_29_0.battleBuffs, iter_29_7, iter_29_7, iter_29_7:getEnergySkillID()))
			end
		end

		if arg_29_0.campaignType == var_0_12.CampaignType.SAKURA2_WAR then
			local var_29_1 = iter_29_7:getTableID()

			if var_0_12.tables.hero:beforeAwaken(var_29_1) > 0 then
				var_29_1 = var_0_12.tables.hero:beforeAwaken(var_29_1)
			end

			local var_29_2 = var_0_12.tables.activitySakura2Buff:buff(var_29_1)

			if var_29_2 and next(var_29_2) then
				iter_29_7:addBuffs(var_29_0(var_29_2, iter_29_7, iter_29_7, iter_29_7:getEnergySkillID()))
			end
		end

		if arg_29_0.campaignType == var_0_12.CampaignType.OCCULT then
			local var_29_3 = var_0_12.tables.creatsChapterSelect:chapterBuff(arg_29_0.chapterId)

			if var_29_3 and next(var_29_3) then
				iter_29_7:addBuffs(var_29_0(var_29_3, iter_29_7, iter_29_7, iter_29_7:getEnergySkillID()))
			end
		end

		iter_29_7:addInitBuffs()
	end

	for iter_29_8, iter_29_9 in pairs(var_0_13.ctx.battle.teamB) do
		iter_29_9:setupHpLimit()

		if iter_29_9.hero_.healthStatus and iter_29_9.hero_.healthStatus.health == 1 and (arg_29_0.campaignType == var_0_12.CampaignType.MARCH or arg_29_0.campaignType == var_0_12.CampaignType.TREASURE or arg_29_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_29_0.campaignType == var_0_12.CampaignType.MEMORIES_OF_SCHOOL or arg_29_0.campaignType == var_0_12.CampaignType.TWO_YEARS or arg_29_0.campaignType == var_0_12.CampaignType.OCCULT or arg_29_0.campaignType == var_0_12.CampaignType.OCCULT_COOPERATION or arg_29_0.campaignType == var_0_12.CampaignType.CHAPTER_BOSS or arg_29_0.campaignType == var_0_12.CampaignType.RAGNAROK) then
			iter_29_9:updateHp(iter_29_9.hero_.healthStatus.hp)
			iter_29_9:updateEnergyTo(iter_29_9.hero_.healthStatus.mp)

			if (iter_29_9.hero_.healthStatus.is_reborn or 0) > 0 and iter_29_9:canReborn() then
				iter_29_9.hasReborn_ = true
			end
		elseif iter_29_9.hero_.healthStatus and iter_29_9.hero_.healthStatus.health == 1 and arg_29_0.campaignType == var_0_12.CampaignType.GUILD then
			iter_29_9:updateHp(iter_29_9.hero_.healthStatus.hp)

			if (iter_29_9.hero_.healthStatus.is_reborn or 0) > 0 and iter_29_9:canReborn() then
				iter_29_9.hasReborn_ = true
			end

			if iter_29_9:canReborn() and iter_29_9:isDeath() then
				iter_29_9.reviveCount_ = var_0_13.ctx.battle.count + var_0_12.tables.battleConfig.reviveCount
			end
		elseif iter_29_9.hero_.healthStatus and (not iter_29_9.hero_.healthStatus.health or iter_29_9.hero_.healthStatus.health == 0) and arg_29_0.campaignType == var_0_12.CampaignType.MARCH then
			iter_29_9:updateHp(iter_29_9:getHpLimit())
			iter_29_9:updateEnergyTo(iter_29_9.hero_.healthStatus.mp)
		else
			iter_29_9:updateHp(iter_29_9:getHpLimit())
		end

		iter_29_9.hero_.healthStatus = nil

		iter_29_9:setupDrop()

		if iter_29_9:isDeath() and not iter_29_9.reviveCount_ then
			iter_29_9.fighterModel:hide()
		end

		iter_29_9:addInitBuffs()

		if arg_29_0.campaignType == var_0_12.CampaignType.RAGNAROK then
			local var_29_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.RAGNAROK)
			local var_29_5 = var_29_4:getBuffs()

			if var_29_4:getPos() == 1 and next(var_29_5) then
				iter_29_9:addBuffs(var_29_0(var_29_5, iter_29_9, iter_29_9, iter_29_9:getEnergySkillID()))
			end
		end

		if next(arg_29_0.extraMonsterBuffers) and next(arg_29_0.extraMonsterBuffers) then
			iter_29_9:addBuffs(var_29_0(arg_29_0.extraMonsterBuffers, iter_29_9, iter_29_9, iter_29_9:getEnergySkillID()))
		end
	end

	for iter_29_10, iter_29_11 in pairs(var_0_13.ctx.battle.summonMonsters) do
		iter_29_11:setupBattleAttrInfo()

		if iter_29_11.hero_.healthStatus and iter_29_11.hero_.healthStatus.health == 1 and (arg_29_0.campaignType == var_0_12.CampaignType.MARCH or arg_29_0.campaignType == var_0_12.CampaignType.TREASURE) then
			iter_29_11:updateHp(iter_29_11.hero_.healthStatus.hp)
			iter_29_11:updateEnergyTo(iter_29_11.hero_.healthStatus.mp)

			if (iter_29_11.hero_.healthStatus.is_reborn or 0) > 0 and iter_29_11:canReborn() then
				iter_29_11.hasReborn_ = true
			end
		else
			iter_29_11:updateHp(iter_29_11:getHpLimit())
		end

		iter_29_11.hero_.healthStatus = nil
	end
end

function var_0_0.setChallengeConfig(arg_31_0)
	if arg_31_0.campaignType ~= var_0_12.CampaignType.CHALLENGE then
		return
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.SecondTeam or arg_31_0.challengeType == var_0_12.ChallengeType.BackwardSecondTeam then
		arg_31_0.teamBJoinCount_ = clone(arg_31_0.secondTeamBCount_)
	else
		arg_31_0.teamBJoinCount_ = {}
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.LimitTime or arg_31_0.challengeType == var_0_12.ChallengeType.KillSteal or arg_31_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst then
		arg_31_0:listenInfo("death_info")
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.BackwardSecondTeam then
		arg_31_0.secondTeamIndex_ = 0
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.KillSteal then
		for iter_31_0, iter_31_1 in ipairs(var_0_13.ctx.battle.teamA) do
			if iter_31_1.hero_.isChallengeKillSteal_ then
				iter_31_1.isChallengeKillSteal_ = true
				arg_31_0.killTheft_ = iter_31_1
			end
		end

		arg_31_0.battleTopWindow:nodeByName("challenge_kill"):show()
		arg_31_0.battleTopWindow:nodeByName("text_challenge_kill_name"):setString(arg_31_0.killTheft_:getName())
		arg_31_0.battleTopWindow:nodeByName("text_challenge_kill"):setString(string.format("(%d/%d)", arg_31_0.killTheft_:getKillCount(), var_0_3:killingNumber(arg_31_0.battleID)))
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.Protect then
		for iter_31_2, iter_31_3 in ipairs(var_0_13.ctx.battle.teamA) do
			if iter_31_3.hero_.isChallengeProtected_ then
				iter_31_3.isChallengeProtected_ = true
				arg_31_0.protectedFighter_ = iter_31_3

				break
			end
		end

		arg_31_0.battleTopWindow:nodeByName("challenge_protect"):show()
		arg_31_0.battleTopWindow:nodeByName("text_challenge_protect1"):setString(var_0_2:translation("CHALLENGE_PROTECT_LABEL1"))
		arg_31_0.battleTopWindow:nodeByName("text_challenge_protect2"):setString(arg_31_0.protectedFighter_:getName())
		arg_31_0.battleTopWindow:nodeByName("text_challenge_protect3"):setString(var_0_2:translation("CHALLENGE_PROTECT_LABEL2"))
		arg_31_0.battleTopWindow:nodeByName("text_challenge_protect4"):setString(arg_31_0.protectedFighter_:getName())
		arg_31_0.battleTopWindow:nodeByName("text_challenge_protect5"):setString(var_0_2:translation("CHALLENGE_PROTECT_LABEL3"))
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst then
		for iter_31_4, iter_31_5 in ipairs(var_0_13.ctx.battle.teamB) do
			if not iter_31_5.isLeader_ then
				iter_31_5.isImmortal_ = true
			end
		end
	end

	if arg_31_0.challengeType == var_0_12.ChallengeType.OneHeroKillAll then
		for iter_31_6, iter_31_7 in ipairs(var_0_13.ctx.battle.teamA) do
			iter_31_7:updateEnergyTo(var_0_12.ENERGY_DECIMAL_BASE)
		end
	end
end

function var_0_0.setTimeScale(arg_32_0, arg_32_1)
	for iter_32_0, iter_32_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_32_1:setTimeScale(arg_32_1)
	end

	for iter_32_2, iter_32_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_32_3:setTimeScale(arg_32_1)
	end

	local var_32_0 = var_0_13.ctx.battle.unitLayer:getChildren()

	for iter_32_4, iter_32_5 in ipairs(var_32_0) do
		if iter_32_5.setTimeScale then
			iter_32_5:setTimeScale(arg_32_1)
		end
	end

	local var_32_1 = var_0_13.ctx.battle.unitBottomLayer:getChildren()

	for iter_32_6, iter_32_7 in ipairs(var_32_1) do
		if iter_32_7.setTimeScale then
			iter_32_7:setTimeScale(arg_32_1)
		end
	end
end

function var_0_0.startBattle(arg_33_0)
	if not arg_33_0.handler then
		if arg_33_0.campaignType == var_0_12.CampaignType.CHALLENGE then
			arg_33_0.handler = var_0_5.scheduleUpdateGlobal(handler(arg_33_0, arg_33_0.mainLoopOfChallenge))
		else
			arg_33_0.handler = var_0_5.scheduleUpdateGlobal(handler(arg_33_0, arg_33_0.mainLoop))
		end
	end
end

function var_0_0.pauseBattle(arg_34_0)
	if arg_34_0.handler ~= nil then
		var_0_5.unscheduleGlobal(arg_34_0.handler)

		arg_34_0.handler = nil
	end
end

function var_0_0.battleEnd(arg_35_0)
	arg_35_0.isBattleEnded_ = true

	arg_35_0:pauseBattle()
	audio.stopMusic()

	var_0_13.ctx.battle.isEnd = true
	var_0_13.ctx.battle.isActivity = nil

	var_0_13.ctx.battle.popSoundQueue()
	arg_35_0:writeReport()
	arg_35_0:recordAutoStatus()
	var_0_5.performWithDelayGlobal(function()
		arg_35_0:playStory()
	end, 0.5)
end

function var_0_0.checkBlackLayerState(arg_37_0)
	if var_0_13.ctx.battle.isEnergySkilling then
		var_0_13.ctx.battle.isEnergySkilling = var_0_13.ctx.battle.isEnergySkilling - 1

		if var_0_13.ctx.battle.isEnergySkilling < 1 then
			arg_37_0:removeBlackLayer()
		end
	end
end

function var_0_0.removeBlackLayer(arg_38_0)
	if var_0_13.ctx.battle.blackLayer == nil or tolua.isnull(var_0_13.ctx.battle.blackLayer) then
		return
	end

	if arg_38_0.natureVolume then
		audio.setMusicVolume(arg_38_0.natureVolume)

		arg_38_0.natureVolume = nil
	end

	var_0_13.ctx.battle.blackLayer:hide()
	var_0_13.ctx.battle.resumeAllFighter()

	var_0_13.ctx.battle.isEnergySkilling = false
end

function var_0_0.mainLoop(arg_39_0)
	if var_0_13.ctx.battle.isSpecialSkill then
		return
	end

	if tolua.isnull(arg_39_0) then
		arg_39_0:pauseBattle()

		return
	end

	if arg_39_0:checkEnds() then
		arg_39_0:processAfterBattleEnd()
		arg_39_0:battleEnd()

		return
	end

	var_0_13.ctx.battle.count = var_0_13.ctx.battle.count + 1

	if var_0_13.ctx.battle.nightCount > 0 and not arg_39_0.stopTimeCount_ then
		var_0_13.ctx.battle.nightCount = math.max(var_0_13.ctx.battle.nightCount - 1, 0)
	end

	if not arg_39_0.stopTimeCount_ then
		var_0_13.ctx.battle.timeCount = var_0_13.ctx.battle.timeCount + 1
	end

	arg_39_0:checkBlackLayerState()
	arg_39_0:checkWindowState()
	arg_39_0:adjustYs()
	arg_39_0:sceneBuff()

	for iter_39_0, iter_39_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_39_1:singleLoop()
	end

	for iter_39_2, iter_39_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_39_3:singleLoop()
	end

	if var_0_13.ctx.battle.isCountHurtNum then
		arg_39_0:setTotalHurt()
	end

	arg_39_0:updateInfoListener()
	arg_39_0:updateWalk2Next()
	var_0_13.ctx.battle.popSoundQueue()

	if not arg_39_0.stopTimeCount_ and var_0_13.ctx.battle.timeCount % 30 == 0 then
		local var_39_0 = var_0_13.ctx.battleConst.seconds - var_0_13.ctx.battle.timeCount
		local var_39_1 = var_0_17(var_39_0 / 1800)
		local var_39_2 = var_0_17(var_39_0 % 1800 / 30)
		local var_39_3 = string.format("%02d:%02d", var_39_1, var_39_2)

		arg_39_0.battleTopWindow:getTimeLabel():setString(var_39_3)
	end

	arg_39_0:playGuide()

	if arg_39_0.ifPlayHeroShow then
		arg_39_0:playHeroShow()
	end

	if arg_39_0.isEscapeStory then
		arg_39_0:checkEscapeStory()
	elseif arg_39_0.isEscapeEnemyMove then
		arg_39_0:playEscapeMove()
	end
end

function var_0_0.sceneBuff(arg_40_0)
	if arg_40_0.sceneFighter and not arg_40_0.stopTimeCount_ then
		arg_40_0.sceneFighter:singleLoop()
	end
end

function var_0_0.updateInfoListener(arg_41_0)
	for iter_41_0, iter_41_1 in pairs(var_0_13.ctx.battle.infoListener) do
		var_0_13.ctx.battle.infoList[iter_41_0] = {}

		for iter_41_2 = #iter_41_1, 1, -1 do
			var_0_13.ctx.battle.infoList[iter_41_0][iter_41_2] = iter_41_1[iter_41_2]
		end

		var_0_13.ctx.battle.infoListener[iter_41_0] = {}
	end
end

function var_0_0.updateWalk2Next(arg_42_0)
	if not var_0_13.ctx.battle.walk2NextBattle_ then
		return
	end

	for iter_42_0, iter_42_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_42_1:isDeath() ~= true and iter_42_1:getX() < var_0_12.STAGE_WIDTH + 100 then
			return
		end
	end

	var_0_13.ctx.battle.walk2NextBattle_ = false
	arg_42_0.stopTimeCount_ = false
	arg_42_0.group_ = arg_42_0.group_ + 1

	if arg_42_0.isGuide then
		if arg_42_0.group_ == 2 then
			if var_0_12.StoryData.get():getGuideID() < var_0_12.GuideStoryType.GUIDE_CAMPAIGN_END then
				arg_42_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_CLICK_CAMPAIGN_NEXT1)
			end
		elseif arg_42_0.group_ == 3 and var_0_12.StoryData.get():getGuideID() < var_0_12.GuideStoryType.GUIDE_CAMPAIGN_END then
			arg_42_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_CLICK_CAMPAIGN_NEXT2)
		end
	end

	arg_42_0:pauseBattle()
	arg_42_0:init()
end

function var_0_0.checkSaveHealthStatus(arg_43_0)
	if arg_43_0.campaignType == var_0_12.CampaignType.GUILD or arg_43_0.campaignType == var_0_12.CampaignType.OCCULT then
		return true
	end

	return false
end

function var_0_0.checkEnds(arg_44_0)
	local function var_44_0()
		for iter_45_0, iter_45_1 in ipairs(var_0_13.ctx.battle.teamB) do
			if iter_45_1:isDeath() then
				iter_45_1:showAwardActions()
			end

			if iter_45_1:isBoss() then
				iter_45_1:progressAwardAction()
			end
		end
	end

	if arg_44_0.isBattleEnded_ then
		return true
	end

	if var_0_13.ctx.battleConst.seconds - var_0_13.ctx.battle.timeCount <= 0 then
		if arg_44_0:checkSaveHealthStatus() then
			for iter_44_0, iter_44_1 in ipairs(var_0_13.ctx.battle.teamB) do
				if iter_44_1:isDeath() and iter_44_1:canReborn() then
					iter_44_1:forceReborn()
				end
			end

			for iter_44_2, iter_44_3 in ipairs(var_0_13.ctx.battle.teamA) do
				if iter_44_3:isDeath() and iter_44_3:canReborn() then
					iter_44_3:forceReborn()
				end
			end
		end

		arg_44_0.timeOut_ = true

		return true
	end

	if arg_44_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL and arg_44_0.sceneFighter:checkNotEnd() then
		return false
	end

	if arg_44_0:checkEnd(var_0_12.TeamType.A) then
		var_0_13.ctx.battle.teamBEnd = true
		arg_44_0.stopTimeCount_ = true

		if arg_44_0.group_ < #arg_44_0.heroGroupB then
			local var_44_1 = arg_44_0.battleBottomWindow:nextBattleBtn()

			if not var_0_13.ctx.battle.walk2NextBattle_ and var_0_13.ctx.battle.autoA then
				var_0_13.ctx.battle.walk2NextBattle_ = true

				arg_44_0:reMpHp()
				arg_44_0:clear()
				var_44_0()

				if arg_44_0.battleID <= var_0_13.ctx.battleConst.guideCampaignId - 1 and var_0_12.StoryData.get():getStoryID() <= arg_44_0.battleID then
					arg_44_0.battleBottomWindow:showGuideNext(false)
				end

				if var_44_1:isVisible() then
					var_44_1:hide()
				end
			elseif var_0_13.ctx.battle.autoA ~= true and var_44_1:isVisible() ~= true and var_0_13.ctx.battle.walk2NextBattle_ ~= true then
				arg_44_0:clear()
				var_44_0()

				if arg_44_0.battleBottomWindow then
					arg_44_0.battleBottomWindow:show()
					arg_44_0.battleBottomWindow:playNextBattle()

					if arg_44_0.battleID <= var_0_13.ctx.battleConst.guideCampaignId - 1 and var_0_12.StoryData.get():getStoryID() <= arg_44_0.battleID then
						arg_44_0.battleBottomWindow:showGuideNext(true)
					end
				end
			end

			arg_44_0:processAfterBattleEnd(true)

			return false
		end

		arg_44_0.battleBottomWindow:showGuideNext(false)
		arg_44_0:playWin(var_0_13.ctx.battle.teamA)
		var_44_0()
		arg_44_0:clear()
		var_0_13.ctx.battle.pushSoundQueue(var_0_12.tables.sound:getSound("battle_win"))

		return true
	elseif arg_44_0:checkEnd(var_0_12.TeamType.B) then
		var_0_13.ctx.battle.teamAEnd = true

		arg_44_0:clear()
		arg_44_0:playWin(var_0_13.ctx.battle.teamB)
		arg_44_0.battleBottomWindow:showGuideNext(false)
		var_0_13.ctx.battle.pushSoundQueue(var_0_12.tables.sound:getSound("battle_lose"))

		return true
	end

	return false
end

function var_0_0.processAfterBattleEnd(arg_46_0, arg_46_1)
	for iter_46_0, iter_46_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_46_1:processAfterBattleEnd(arg_46_1)
	end

	if not arg_46_1 then
		for iter_46_2, iter_46_3 in ipairs(var_0_13.ctx.battle.teamB) do
			iter_46_3:processAfterBattleEnd(false)
		end
	end

	if not arg_46_1 then
		var_0_13.ctx.battle.unitLayer:hide()
		var_0_13.ctx.battle.unitBottomLayer:hide()
	end
end

function var_0_0.checkEnd(arg_47_0, arg_47_1)
	for iter_47_0, iter_47_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_47_1:canReborn() and iter_47_1:isDeath() then
			return false
		end
	end

	if arg_47_0.campaignType == var_0_12.CampaignType.GUILD then
		for iter_47_2, iter_47_3 in ipairs(var_0_13.ctx.battle.teamB) do
			if iter_47_3:canReborn() and iter_47_3:isDeath() then
				return false
			end
		end
	end

	if arg_47_1 == var_0_12.TeamType.B then
		for iter_47_4, iter_47_5 in ipairs(var_0_13.ctx.battle.teamA) do
			if not iter_47_5:isDeath() or iter_47_5:canReborn() then
				return false
			end
		end

		return true
	else
		for iter_47_6, iter_47_7 in ipairs(var_0_13.ctx.battle.teamB) do
			if not iter_47_7:isDeath() or iter_47_7:canReborn() then
				return false
			end
		end

		return true
	end
end

function var_0_0.reMpHp(arg_48_0)
	for iter_48_0, iter_48_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_48_1:checkReHpMp()
	end

	for iter_48_2, iter_48_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_48_3:checkReHpMp()
	end
end

function var_0_0.playWin(arg_49_0, arg_49_1)
	arg_49_0:removeBlackLayer()

	for iter_49_0, iter_49_1 in ipairs(arg_49_1) do
		iter_49_1:playWin()
	end
end

function var_0_0.adjustYs(arg_50_0)
	if var_0_13.ctx.battle.count < 30 or var_0_13.ctx.battle.isEnergySkilling then
		return
	end

	arg_50_0.aOrders = {}
	arg_50_0.bOrders = {}

	for iter_50_0, iter_50_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if not iter_50_1:isDeath() and not iter_50_1:isAffected() then
			table.insert(arg_50_0.aOrders, iter_50_1)
		end
	end

	for iter_50_2, iter_50_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if not iter_50_3:isDeath() and not iter_50_3:isAffected() then
			table.insert(arg_50_0.bOrders, iter_50_3)
		end
	end

	table.sort(arg_50_0.aOrders, function(arg_51_0, arg_51_1)
		return arg_51_0:getY() < arg_51_1:getY()
	end)
	table.sort(arg_50_0.bOrders, function(arg_52_0, arg_52_1)
		return arg_52_0:getY() < arg_52_1:getY()
	end)
	arg_50_0:adjustY(arg_50_0.aOrders)
	arg_50_0:adjustY(arg_50_0.bOrders)
end

function var_0_0.adjustY(arg_53_0, arg_53_1)
	local var_53_0 = 100
	local var_53_1 = 400

	for iter_53_0 = 1, #arg_53_1 do
		local var_53_2 = arg_53_1[iter_53_0]
		local var_53_3 = iter_53_0 > 1 and arg_53_1[iter_53_0 - 1]
		local var_53_4 = iter_53_0 < #arg_53_1 and arg_53_1[iter_53_0 + 1]
		local var_53_5 = var_53_2:getX()
		local var_53_6 = var_53_2:getY()
		local var_53_7
		local var_53_8
		local var_53_9
		local var_53_10

		if var_53_3 then
			var_53_7, var_53_8 = var_53_3:getX(), var_53_3:getY()
		end

		if var_53_4 then
			var_53_9, var_53_10 = var_53_4:getX(), var_53_4:getY()
		end

		if not var_53_3 and not var_53_2:isMoveUnable() and not var_53_2:isInSkillRoll() and var_53_4 then
			if var_0_16(var_53_9 - var_53_5) < 80 and var_53_10 - var_53_6 < 35 and var_53_0 < var_53_6 then
				local var_53_11 = var_0_14(var_53_2:getBasicSpeed(), var_53_6 - var_53_0) * -1

				var_53_2:moveByY(var_53_11)

				var_53_2.isAdjustY_ = 1
			end
		elseif var_53_3 and not var_53_2:isMoveUnable() and not var_53_2:isInSkillRoll() and var_0_16(var_53_7 - var_53_5) < 80 and var_53_6 - var_53_8 < 35 and var_53_8 < var_53_1 then
			local var_53_12 = var_53_2:getBasicSpeed()

			var_53_2:moveByY(var_53_12)

			var_53_2.isAdjustY_ = 1
		elseif var_53_4 and not var_53_2:isMoveUnable() and not var_53_2:isInSkillRoll() and var_0_16(var_53_9 - var_53_5) < 80 and var_53_10 - var_53_6 < 35 and var_0_16(var_53_5 - var_53_7) < 80 and var_53_10 - var_53_6 > 100 + var_53_2:getBasicSpeed() then
			local var_53_13 = var_53_2:getBasicSpeed() * -1

			var_53_2:moveByY(var_53_13)

			var_53_2.isAdjustY_ = 1
		end
	end

	arg_53_0:updateZorder()
end

function var_0_0.updateZorder(arg_54_0)
	table.sort(var_0_13.ctx.battle.yOrder, function(arg_55_0, arg_55_1)
		return arg_55_0:getY() > arg_55_1:getY()
	end)

	for iter_54_0 = 1, #var_0_13.ctx.battle.yOrder do
		local var_54_0 = var_0_13.ctx.battle.yOrder[iter_54_0]:getY()

		if iter_54_0 > 1 and var_54_0 == var_0_13.ctx.battle.yOrder[iter_54_0 - 1]:getY() then
			var_0_13.ctx.battle.yOrder[iter_54_0]:y(var_54_0 - 0.01)
		end

		var_0_13.ctx.battle.yOrder[iter_54_0].fighterModel:setLocalZOrder(iter_54_0)
	end
end

function var_0_0.clickNextBattle(arg_56_0)
	if var_0_13.ctx.battle.walk2NextBattle_ then
		return
	end

	var_0_13.ctx.battle.walk2NextBattle_ = true
	arg_56_0.stopTimeCount_ = false

	arg_56_0.battleBottomWindow:nextBattleBtn():hide()

	if arg_56_0.battleID <= var_0_13.ctx.battleConst.guideCampaignId - 1 and var_0_12.StoryData.get():getStoryID() <= arg_56_0.battleID then
		arg_56_0.battleBottomWindow:showGuideNext(false)
	end

	arg_56_0:clear()
	arg_56_0:reMpHp()
end

function var_0_0.clickAvatar(arg_57_0, arg_57_1, arg_57_2)
	if arg_57_0.notClickAvatar then
		return
	end

	arg_57_1:clickAvatar(arg_57_2)

	if not arg_57_1:checkEnergySkill() then
		if arg_57_2.name == "ended" and arg_57_0.medicineNum > 0 and arg_57_1:getEnergy() < arg_57_1:energyDecimalBase() then
			arg_57_1:updateEnergyTo(arg_57_1:getEnergy() + 100)

			arg_57_0.medicineNum = arg_57_0.medicineNum - 1

			arg_57_0.battleBottomWindow:getMedicineNum():setString(arg_57_0.medicineNum)
		end

		return
	end

	if arg_57_1:manualType() == var_0_12.ManualType.None then
		if arg_57_2.name == "ended" and not arg_57_1.isEnergySkill_ then
			if arg_57_1:isCreatingUnits() then
				arg_57_1:skillIsBreak()
			end

			arg_57_1.isEnergySkill_ = true

			if not arg_57_0.natureVolume then
				arg_57_0.natureVolume = audio.getMusicVolume()

				audio.setMusicVolume(arg_57_0.natureVolume * 0.3)
			end

			arg_57_1.leftInterval_ = 0

			arg_57_0.battleBottomWindow:energySkillEffect(arg_57_1, var_0_13.ctx.battle.teamA)
			var_0_13.ctx.battle.pushSoundQueue(var_0_12.tables.sound:getSound("battle_use_skill"))
		end

		return
	end

	if arg_57_2.name == "began" then
		if not arg_57_1.isEnergySkill_ then
			if arg_57_1:isCreatingUnits() then
				arg_57_1:skillIsBreak()
			end

			arg_57_1.isEnergySkill_ = true

			if not arg_57_0.natureVolume then
				arg_57_0.natureVolume = audio.getMusicVolume()

				audio.setMusicVolume(arg_57_0.natureVolume * 0.3)
			end

			arg_57_1.leftInterval_ = 0
			arg_57_0.startX_ = arg_57_2.x
			arg_57_0.startY_ = arg_57_2.y

			arg_57_0:pauseBattle()
			arg_57_0:manulTargetBegin(arg_57_1)
		end
	elseif arg_57_2.name == "moved" then
		local var_57_0 = var_0_16(arg_57_2.x - (arg_57_0.startX_ or arg_57_2.x)) > 10 or var_0_16(arg_57_2.y - (arg_57_0.startY_ or arg_57_2.y)) > 10

		if arg_57_1.isEnergySkill_ and var_57_0 then
			arg_57_0:manualTarget(arg_57_1, arg_57_2)
		end
	elseif arg_57_2.name == "ended" then
		if arg_57_1.isEnergySkill_ then
			arg_57_0:manulTargetEnd(arg_57_1)

			for iter_57_0, iter_57_1 in pairs(var_0_13.ctx.battle.teamA) do
				if not iter_57_1:isDeath() and iter_57_1.isEnergySkill_ and iter_57_1:acttionInBlack() then
					if iter_57_1:isPause() then
						iter_57_1:getFighterModel():setGrayScale(0.7)
						iter_57_1.fighterModel:unsetBackMaskColor()
						iter_57_1:resume({
							no_model = true
						})
					elseif iter_57_1.fighterModel.filterBuff_ then
						iter_57_1:getFighterModel():setMaskColor(iter_57_1.fighterModel.filterBuff_:getFilter().color)
						iter_57_1.fighterModel:unsetBackMaskColor()
						iter_57_1:resume()
					else
						iter_57_1:unsetMaskColor()
						iter_57_1:resume()
					end
				end
			end

			for iter_57_2, iter_57_3 in pairs(var_0_13.ctx.battle.teamB) do
				if not iter_57_3:isDeath() and iter_57_3.isEnergySkill_ and iter_57_3:acttionInBlack() then
					if iter_57_3:isPause() then
						iter_57_3:getFighterModel():setGrayScale(0.7)
						iter_57_3.fighterModel:unsetBackMaskColor()
						iter_57_3:resume({
							no_model = true
						})
					elseif iter_57_3.fighterModel.filterBuff_ then
						iter_57_3:getFighterModel():setMaskColor(iter_57_3.fighterModel.filterBuff_:getFilter().color)
						iter_57_3.fighterModel:unsetBackMaskColor()
						iter_57_3:resume()
					else
						iter_57_3:unsetMaskColor()
						iter_57_3:resume()
					end
				end
			end
		end

		arg_57_0:startBattle()
		arg_57_0.battleBottomWindow:energySkillEffect(arg_57_1, var_0_13.ctx.battle.teamA)
	end
end

function var_0_0.manulTargetBegin(arg_58_0, arg_58_1)
	if arg_58_1:manualType() ~= var_0_12.ManualType.Single and arg_58_1:manualType() ~= var_0_12.ManualType.Area and arg_58_1:manualType() ~= var_0_12.ManualType.Direction and arg_58_1:manualType() ~= var_0_12.ManualType.MoonLight then
		return
	end

	arg_58_1:playDuskEffect(true)
end

function var_0_0.manulTargetEnd(arg_59_0, arg_59_1)
	if arg_59_1:manualType() ~= var_0_12.ManualType.Single and arg_59_1:manualType() ~= var_0_12.ManualType.Area and arg_59_1:manualType() ~= var_0_12.ManualType.Direction and arg_59_1:manualType() ~= var_0_12.ManualType.MoonLight then
		return
	end

	if arg_59_0.manualSp1_ then
		arg_59_0.manualSp1_:setVisible(false)
	end

	if arg_59_0.manualSp2_ then
		arg_59_0.manualSp2_:setVisible(false)
	end

	if arg_59_0.manualSp1_1 then
		arg_59_0.manualSp1_3:setVisible(false)
		arg_59_0.manualSp1_2:setVisible(false)
		arg_59_0.manualSp1_1:setVisible(false)
		arg_59_0.manualSp1_1:setScale(1)
	end

	if arg_59_0.manualSp3_1 then
		arg_59_0.manualSp3_1:setVisible(false)
		arg_59_0.manualSp1_2:setVisible(false)
	end

	arg_59_1:playDuskEffect(false)
end

function var_0_0.manualTarget(arg_60_0, arg_60_1, arg_60_2)
	if arg_60_1:manualType() == var_0_12.ManualType.Single then
		arg_60_0:manualTargetType_1(arg_60_1, arg_60_2)
	elseif arg_60_1:manualType() == var_0_12.ManualType.Area then
		arg_60_0:manualTargetType_2(arg_60_1, arg_60_2)
	elseif arg_60_1:manualType() == var_0_12.ManualType.Direction then
		arg_60_0:manualTargetType_3(arg_60_1, arg_60_2)
	elseif arg_60_1:manualType() == var_0_12.ManualType.MoonLight then
		arg_60_0:manualTargetType_4(arg_60_1, arg_60_2)
	end
end

function var_0_0.manualTargetType_1(arg_61_0, arg_61_1, arg_61_2)
	if not arg_61_0.manualSp1_1 then
		arg_61_0.manualSp1_1 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_61_0.manualSp1_1:addTo(var_0_13.ctx.battle.playerLayer, 0)

		arg_61_0.manualSp1_2 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_61_0.manualSp1_2:addTo(var_0_13.ctx.battle.playerLayer, 0)

		arg_61_0.manualSp1_3 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_3.png")

		arg_61_0.manualSp1_3:addTo(var_0_13.ctx.battle.playerLayer, 0)
	end

	local var_61_0 = arg_61_2.x
	local var_61_1 = arg_61_2.y
	local var_61_2, var_61_3 = arg_61_1.fighterModel:getPosition()

	if var_61_0 > arg_61_1:getX() then
		arg_61_1:getFighterModel():flipX(false)
	else
		arg_61_1:getFighterModel():flipX(true)
	end

	local var_61_4 = math.atan2(var_61_1 - var_61_3, var_61_0 - var_61_2)
	local var_61_5
	local var_61_6
	local var_61_7 = var_0_4:type(arg_61_1:getEnergySkillID()) == var_0_12.AttackType.CURE and var_0_13.ctx.battle.teamA or var_0_13.ctx.battle.teamB
	local var_61_8 = {}

	for iter_61_0, iter_61_1 in ipairs(var_61_7) do
		if not iter_61_1:isDeath() and not iter_61_1:isAffected() then
			table.insert(var_61_8, iter_61_1)
		end
	end

	table.sort(var_61_8, function(arg_62_0, arg_62_1)
		return var_0_16(arg_62_0:getX() - var_61_0) < var_0_16(arg_62_1:getX() - var_61_0)
	end)

	for iter_61_2 = 1, #var_61_8 do
		if not var_61_6 then
			var_61_6 = var_61_8[iter_61_2]
			var_61_5 = var_0_16(var_61_6:getY() - var_61_1)
		elseif var_0_16(var_61_8[iter_61_2]:getX() - var_61_0) < var_0_12.tables.battleConfig.manualSelectWidth and var_61_5 > var_0_16(var_61_8[iter_61_2]:getY() - var_61_1) then
			var_61_6 = var_61_8[iter_61_2]
			var_61_5 = var_0_16(var_61_8[iter_61_2]:getY() - var_61_1)
		end

		if var_0_16(var_61_8[iter_61_2]:getX() - var_61_0) >= var_0_12.tables.battleConfig.manualSelectWidth then
			break
		end
	end

	if not var_61_6 then
		arg_61_0.manualSp1_3:setVisible(false)
		arg_61_0.manualSp1_2:setVisible(false)
		arg_61_0.manualSp1_1:setVisible(false)

		return
	end

	local var_61_9 = math.atan2(var_61_6:getY() - var_61_3, var_61_6:getX() - var_61_2) / math.pi * -180
	local var_61_10 = var_0_19((var_61_6:getY() - var_61_3) * (var_61_6:getY() - var_61_3) + (var_61_6:getX() - var_61_2) * (var_61_6:getX() - var_61_2)) - arg_61_0.manualSp1_3:getWidth() / 2 - arg_61_0.manualSp1_2:getWidth() / 2 + 30
	local var_61_11 = var_0_15(var_61_10, 0)

	arg_61_0.manualSp1_2:setVisible(true)
	arg_61_0.manualSp1_2:pos(arg_61_1:getX(), arg_61_1:getY())
	arg_61_0.manualSp1_3:setVisible(true)
	arg_61_0.manualSp1_3:pos(var_61_6:getX(), var_61_6:getY())
	arg_61_0.manualSp1_1:setVisible(true)
	arg_61_0.manualSp1_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_61_0.manualSp1_1:setScaleX(var_61_11 / arg_61_0.manualSp1_1:getWidth())
	arg_61_0.manualSp1_1:pos(var_61_6:getX() / 2 + var_61_2 / 2, var_61_6:getY() / 2 + var_61_3 / 2)
	arg_61_0.manualSp1_1:setRotation(var_61_9)
	var_0_13.ctx.battle.blackLayer:show()
	var_0_13.ctx.battle.pauseAndDuskAllEffectAllRole({
		arg_61_1,
		var_61_6
	})
	var_61_6:pause()
	var_61_6:unsetMaskColor()

	arg_61_1.manualTargets_ = {
		var_61_6
	}
end

function var_0_0.manualTargetType_2(arg_63_0, arg_63_1, arg_63_2)
	if not arg_63_0.manualSp2_ then
		arg_63_0.manualSp2_ = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_2_1.png")

		arg_63_0.manualSp2_:addTo(var_0_13.ctx.battle.playerLayer, 0)
	end

	arg_63_0.manualSp2_:setVisible(true)
	arg_63_0.manualSp2_:setAnchorPoint(cc.p(0.5, 0.5))
	arg_63_0.manualSp2_:scale(arg_63_1:getScope() / arg_63_0.manualSp2_:getWidth())

	local var_63_0 = arg_63_2.x

	if var_63_0 > arg_63_1:getX() then
		arg_63_1:getFighterModel():flipX(false)
	else
		arg_63_1:getFighterModel():flipX(true)
	end

	if arg_63_1:getFlipX() then
		var_63_0 = var_0_15(var_63_0, arg_63_1:getX() - arg_63_1:getFrontSkillDistance())
		var_63_0 = var_0_15(arg_63_1:getScope() / 2, var_63_0)
	else
		var_63_0 = var_0_14(var_63_0, arg_63_1:getX() + arg_63_1:getFrontSkillDistance())
		var_63_0 = var_0_14(var_0_12.STAGE_WIDTH - arg_63_1:getScope() / 2, var_63_0)
	end

	arg_63_0.manualSp2_:pos(var_63_0, arg_63_2.y)

	local var_63_1 = {}
	local var_63_2 = var_0_4:type(arg_63_1:getEnergySkillID()) == var_0_12.AttackType.CURE and var_0_13.ctx.battle.teamA or var_0_13.ctx.battle.teamB

	var_0_13.ctx.battle.blackLayer:show()
	var_0_13.ctx.battle.pauseAndDuskAllEffectAllRole({
		arg_63_1
	})

	local var_63_3 = {
		arg_63_1
	}

	for iter_63_0, iter_63_1 in ipairs(var_63_2) do
		if not iter_63_1:isDeath() and iter_63_1:getX() > var_63_0 - arg_63_1:getScope() / 2 and iter_63_1:getX() < var_63_0 + arg_63_1:getScope() / 2 then
			table.insert(var_63_1, iter_63_1)
			table.insert(var_63_3, iter_63_1)
			iter_63_1:unsetMaskColor()
			iter_63_1:pause()
		end
	end

	var_0_13.ctx.battle.blackLayer:show()
	var_0_13.ctx.battle.pauseAndDuskAllEffectAllRole(var_63_3)

	arg_63_1.manualTargets_ = var_63_1
	arg_63_1.manualPosition_ = {
		var_63_0,
		arg_63_2.y
	}
end

function var_0_0.manualTargetType_3(arg_64_0, arg_64_1, arg_64_2)
	if not arg_64_0.manualSp3_1 then
		arg_64_0.manualSp3_1 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_3_1.png")

		arg_64_0.manualSp3_1:addTo(var_0_13.ctx.battle.playerLayer, 0)
	end

	if not arg_64_0.manualSp1_2 then
		arg_64_0.manualSp1_2 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_64_0.manualSp1_2:addTo(var_0_13.ctx.battle.playerLayer, 0)
	end

	local var_64_0 = arg_64_2.x
	local var_64_1 = arg_64_2.y
	local var_64_2, var_64_3 = arg_64_1.fighterModel:getPosition()

	if var_64_0 >= arg_64_1:getX() then
		arg_64_1:getFighterModel():flipX(false)
		arg_64_0.manualSp3_1:flipX(false)
		arg_64_0.manualSp3_1:pos(var_64_2 + arg_64_0.manualSp3_1:getWidth() / 2 + arg_64_0.manualSp1_2:getWidth() / 2 - 15, var_64_3)
	else
		arg_64_1:getFighterModel():flipX(true)
		arg_64_0.manualSp3_1:flipX(true)
		arg_64_0.manualSp3_1:pos(var_64_2 - arg_64_0.manualSp3_1:getWidth() / 2 - arg_64_0.manualSp1_2:getWidth() / 2 + 15, var_64_3)
	end

	arg_64_0.manualSp1_2:setVisible(true)
	arg_64_0.manualSp1_2:pos(arg_64_1:getX(), arg_64_1:getY())
	arg_64_0.manualSp3_1:setVisible(true)
	arg_64_0.manualSp3_1:align(display.CENTER)
	var_0_13.ctx.battle.blackLayer:show()
	var_0_13.ctx.battle.pauseAndDuskAllEffectAllRole({
		arg_64_1
	})

	arg_64_1.manualDirection_ = var_64_0 >= arg_64_1:getX() and 1 or 0
end

function var_0_0.manualTargetType_4(arg_65_0, arg_65_1, arg_65_2)
	local var_65_0 = 10010055

	if not arg_65_0.manualSp1_1 then
		arg_65_0.manualSp1_1 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

		arg_65_0.manualSp1_1:addTo(var_0_13.ctx.battle.playerLayer, 0)

		arg_65_0.manualSp1_2 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_2.png")

		arg_65_0.manualSp1_2:addTo(var_0_13.ctx.battle.playerLayer, 0)

		arg_65_0.manualSp1_3 = var_0_12.AssetLoader.get():loadSprite("images/battle_manual_1_3.png")

		arg_65_0.manualSp1_3:addTo(var_0_13.ctx.battle.playerLayer, 0)
	end

	local var_65_1 = arg_65_2.x
	local var_65_2 = arg_65_2.y
	local var_65_3, var_65_4 = arg_65_1.fighterModel:getPosition()

	if var_65_1 > arg_65_1:getX() then
		arg_65_1:getFighterModel():flipX(false)
	else
		arg_65_1:getFighterModel():flipX(true)
	end

	local var_65_5 = math.atan2(var_65_2 - var_65_4, var_65_1 - var_65_3)
	local var_65_6
	local var_65_7
	local var_65_8 = var_0_4:type(arg_65_1:getEnergySkillID()) == var_0_12.AttackType.CURE and var_0_13.ctx.battle.teamA or var_0_13.ctx.battle.teamB
	local var_65_9 = {}
	local var_65_10
	local var_65_11

	for iter_65_0, iter_65_1 in ipairs(var_65_8) do
		if not iter_65_1:isDeath() and not iter_65_1:isAffected() and iter_65_1:isHasBuffByID(var_65_0) then
			table.insert(var_65_9, iter_65_1)
		end

		if not iter_65_1:isDeath() and not iter_65_1:isAffected() and (not var_65_11 or var_65_11 > var_0_16(iter_65_1:getX() - arg_65_1:getX())) then
			var_65_10 = iter_65_1
			var_65_11 = var_0_16(iter_65_1:getX() - arg_65_1:getX())
		end
	end

	if not next(var_65_9) and var_65_10 then
		var_65_9 = {
			var_65_10
		}
	end

	table.sort(var_65_9, function(arg_66_0, arg_66_1)
		return var_0_16(arg_66_0:getX() - var_65_1) < var_0_16(arg_66_1:getX() - var_65_1)
	end)

	for iter_65_2 = 1, #var_65_9 do
		if not var_65_7 then
			var_65_7 = var_65_9[iter_65_2]
			var_65_6 = var_0_16(var_65_7:getY() - var_65_2)
		elseif var_0_16(var_65_9[iter_65_2]:getX() - var_65_1) < var_0_12.tables.battleConfig.manualSelectWidth and var_65_6 > var_0_16(var_65_9[iter_65_2]:getY() - var_65_2) then
			var_65_7 = var_65_9[iter_65_2]
			var_65_6 = var_0_16(var_65_9[iter_65_2]:getY() - var_65_2)
		end

		if var_0_16(var_65_9[iter_65_2]:getX() - var_65_1) >= var_0_12.tables.battleConfig.manualSelectWidth then
			break
		end
	end

	if not var_65_7 then
		arg_65_0.manualSp1_3:setVisible(false)
		arg_65_0.manualSp1_2:setVisible(false)
		arg_65_0.manualSp1_1:setVisible(false)

		return
	end

	local var_65_12 = math.atan2(var_65_7:getY() - var_65_4, var_65_7:getX() - var_65_3) / math.pi * -180
	local var_65_13 = var_0_19((var_65_7:getY() - var_65_4) * (var_65_7:getY() - var_65_4) + (var_65_7:getX() - var_65_3) * (var_65_7:getX() - var_65_3)) - arg_65_0.manualSp1_3:getWidth() / 2 - arg_65_0.manualSp1_2:getWidth() / 2 + 30
	local var_65_14 = var_0_15(var_65_13, 0)

	arg_65_0.manualSp1_2:setVisible(true)
	arg_65_0.manualSp1_2:pos(arg_65_1:getX(), arg_65_1:getY())
	arg_65_0.manualSp1_3:setVisible(true)
	arg_65_0.manualSp1_3:pos(var_65_7:getX(), var_65_7:getY())
	arg_65_0.manualSp1_1:setVisible(true)
	arg_65_0.manualSp1_1:setAnchorPoint(cc.p(0.5, 0.5))
	arg_65_0.manualSp1_1:setScaleX(var_65_14 / arg_65_0.manualSp1_1:getWidth())
	arg_65_0.manualSp1_1:pos(var_65_7:getX() / 2 + var_65_3 / 2, var_65_7:getY() / 2 + var_65_4 / 2)
	arg_65_0.manualSp1_1:setRotation(var_65_12)
	var_0_13.ctx.battle.blackLayer:show()
	var_0_13.ctx.battle.pauseAndDuskAllEffectAllRole({
		arg_65_1,
		var_65_7
	})
	var_65_7:pause()
	var_65_7:unsetMaskColor()

	arg_65_1.manualTargetsMoon_ = {
		var_65_7
	}
end

function var_0_0.writeReport(arg_67_0)
	if arg_67_0.report_ then
		return ""
	end

	arg_67_0.report_ = {}
	arg_67_0.report_.fighter = {}

	for iter_67_0, iter_67_1 in ipairs(var_0_13.ctx.battle.teamA) do
		arg_67_0.report_.fighter[iter_67_1.fighterIndex] = iter_67_1:writeReport()
	end

	for iter_67_2, iter_67_3 in ipairs(var_0_13.ctx.battle.teamB) do
		arg_67_0.report_.fighter[iter_67_3.fighterIndex] = iter_67_3:writeReport()
	end

	if arg_67_0.sceneFighter then
		arg_67_0.report_.fighter[arg_67_0.sceneFighter.fighterIndex] = arg_67_0.sceneFighter:writeReport()
	end

	arg_67_0.report_.star = arg_67_0:getBattleStar()

	return ""
end

function var_0_0.checkBattleReport(arg_68_0)
	for iter_68_0, iter_68_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_68_1:getSummonType() == var_0_12.summonMonsterType.None and table.nums(iter_68_1.hero_.errorData_) > 0 then
			return 1
		end
	end

	for iter_68_2, iter_68_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_68_3:getSummonType() == var_0_12.summonMonsterType.None and table.nums(iter_68_3.hero_.errorData_) > 0 then
			return 1
		end
	end

	return 0
end

function var_0_0.getAwakeMissionResult(arg_69_0)
	if arg_69_0.isPetAwakeCampaign and arg_69_0.petAwakeFighter and arg_69_0.awakeStage == 2 then
		if arg_69_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
			if arg_69_0.petAwakeFighter.isDoneSelfKill then
				return true
			else
				return false
			end
		elseif arg_69_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
			if arg_69_0.petAwakeFighter.harms >= var_0_12.tables.mission:challengeNums(arg_69_0.petAwakeMissionID) then
				return true
			else
				return false
			end
		elseif arg_69_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.ALL_ALIVE then
			for iter_69_0, iter_69_1 in pairs(var_0_13.ctx.battle.teamA) do
				if iter_69_1:getHp() <= 0 and iter_69_1.hero_:getTableID() > 0 and iter_69_1:getSummonType() == var_0_12.summonMonsterType.None then
					return false
				end
			end

			return true
		end
	end

	if arg_69_0.isAwakeCampaign and arg_69_0.awakeFighter and var_0_12.tables.mission:sufMissionID(arg_69_0.awakeMissionID) == 0 then
		if arg_69_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
			if arg_69_0.awakeFighter.isDoneSelfKill then
				return true
			else
				return false
			end
		elseif arg_69_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
			if arg_69_0.awakeFighter.harms >= var_0_12.tables.mission:challengeNums(arg_69_0.awakeMissionID) then
				return true
			else
				return false
			end
		elseif arg_69_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.ALONE_KILL then
			local var_69_0 = 0

			for iter_69_2, iter_69_3 in pairs(var_0_13.ctx.battle.teamA) do
				if iter_69_3.hero_:getTableID() > 0 and iter_69_3:getSummonType() == var_0_12.summonMonsterType.None then
					var_69_0 = var_69_0 + 1
				end
			end

			if arg_69_0.awakeFighter and var_69_0 == 1 and (not arg_69_0.petsA or #arg_69_0.petsA < 1) then
				return true
			else
				return false
			end
		elseif arg_69_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.ALL_ALIVE then
			for iter_69_4, iter_69_5 in pairs(var_0_13.ctx.battle.teamA) do
				if iter_69_5:getHp() <= 0 and iter_69_5.hero_:getTableID() > 0 and iter_69_5:getSummonType() == var_0_12.summonMonsterType.None then
					return false
				end
			end

			return true
		end
	end

	return false
end

function var_0_0.playoffsResult(arg_70_0, arg_70_1)
	local var_70_0 = arg_70_0.playoffsModel:getCurrentBattleRound()
	local var_70_1 = arg_70_0.playoffsModel:setBattleResult(var_70_0)

	if var_70_1 then
		arg_70_0:runActionOnce(cc.CallFunc:create(function()
			arg_70_0:finishPlayoffs(var_70_1)
		end), false, nil, 2)

		return
	end

	local var_70_2 = arg_70_0.responseData_

	local function var_70_3(arg_72_0)
		if arg_72_0 > 0 then
			arg_70_0:runActionOnce(cc.CallFunc:create(function()
				arg_70_0:finishPlayoffs(false)
				arg_70_0.playoffsModel:clear()
			end), false, nil, arg_72_0)
		else
			arg_70_0:finishPlayoffs(false)
			arg_70_0.playoffsModel:clear()
		end
	end

	if var_70_2 and var_70_2.items and next(var_70_2.items) and not arg_70_0.isReplay then
		local var_70_4 = {}

		for iter_70_0, iter_70_1 in ipairs(var_70_2.items) do
			for iter_70_2 = 1, iter_70_1.item_num do
				local var_70_5 = var_0_8.new()

				var_70_5:populate({
					table_id = iter_70_1.item_id
				})
				table.insert(var_70_4, var_70_5)
			end

			arg_70_0.selfPlayer:getBackpack():addItemsByID(iter_70_1.item_id, iter_70_1.item_num)
		end

		local var_70_6 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_70_7 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_70_8 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_70_9 = {
			var_70_6,
			var_70_7,
			var_70_8
		}
		local var_70_10 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_70_4,
			labels = var_70_9
		})

		cc.EventProxy.new(var_70_10, var_70_10):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_70_3(1)
		end)
	elseif arg_70_1 then
		var_70_3(0)
	else
		var_70_3(2)
	end
end

function var_0_0.friendResult(arg_75_0, arg_75_1)
	local var_75_0 = arg_75_0.socialSystem:getCurrentBattleRound()
	local var_75_1 = arg_75_0.socialSystem:setBattleResult(var_75_0)

	if not var_75_1 then
		local var_75_2 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.LIBRARY)

		if var_75_2.retainHistoryTmp then
			var_75_2.retainHistory = var_75_2.retainHistoryTmp
			var_75_2.retainHistoryTmp = nil
		end
	end

	if var_75_1 then
		arg_75_0:runActionOnce(cc.CallFunc:create(function()
			arg_75_0:finishFriend(var_75_1)
		end), false, nil, 2)

		return
	end

	local var_75_3 = arg_75_0.responseData_

	local function var_75_4(arg_77_0)
		if arg_77_0 > 0 then
			arg_75_0:runActionOnce(cc.CallFunc:create(function()
				arg_75_0:finishFriend(false)
				arg_75_0.socialSystem:clear()
			end), false, nil, arg_77_0)
		else
			arg_75_0:finishFriend(false)
			arg_75_0.socialSystem:clear()
		end
	end

	if var_75_3 and var_75_3.items and next(var_75_3.items) and not arg_75_0.isReplay then
		local var_75_5 = {}

		for iter_75_0, iter_75_1 in ipairs(var_75_3.items) do
			for iter_75_2 = 1, iter_75_1.item_num do
				local var_75_6 = var_0_8.new()

				var_75_6:populate({
					table_id = iter_75_1.item_id
				})
				table.insert(var_75_5, var_75_6)
			end

			arg_75_0.selfPlayer:getBackpack():addItemsByID(iter_75_1.item_id, iter_75_1.item_num)
		end

		local var_75_7 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_75_8 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_75_9 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_75_10 = {
			var_75_7,
			var_75_8,
			var_75_9
		}
		local var_75_11 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_75_5,
			labels = var_75_10
		})

		cc.EventProxy.new(var_75_11, var_75_11):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_75_4(1)
		end)
	elseif arg_75_1 then
		var_75_4(0)
	else
		var_75_4(2)
	end
end

function var_0_0.RegionCasualResult(arg_80_0, arg_80_1)
	local var_80_0 = arg_80_0.regionCasualArena:getCurrentBattleRound()
	local var_80_1 = arg_80_0.regionCasualArena:setBattleResult(var_80_0)

	if not var_80_1 then
		local var_80_2 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.LIBRARY)

		if var_80_2.retainHistoryTmp then
			var_80_2.retainHistory = var_80_2.retainHistoryTmp
			var_80_2.retainHistoryTmp = nil
		end
	end

	if var_80_1 then
		arg_80_0:runActionOnce(cc.CallFunc:create(function()
			arg_80_0:finishCasual(var_80_1)
		end), false, nil, 2)

		return
	end

	local var_80_3 = arg_80_0.responseData_

	local function var_80_4(arg_82_0)
		if arg_82_0 > 0 then
			arg_80_0:runActionOnce(cc.CallFunc:create(function()
				arg_80_0:finishCasual(false)
				arg_80_0.regionCasualArena:clear()
			end), false, nil, arg_82_0)
		else
			arg_80_0:finishCasual(false)
			arg_80_0.regionCasualArena:clear()
		end
	end

	if var_80_3 and var_80_3.items and next(var_80_3.items) and not arg_80_0.isReplay then
		local var_80_5 = {}

		for iter_80_0, iter_80_1 in ipairs(var_80_3.items) do
			for iter_80_2 = 1, iter_80_1.item_num do
				local var_80_6 = var_0_8.new()

				var_80_6:populate({
					table_id = iter_80_1.item_id
				})
				table.insert(var_80_5, var_80_6)
			end

			arg_80_0.selfPlayer:getBackpack():addItemsByID(iter_80_1.item_id, iter_80_1.item_num)
		end

		local var_80_7 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_80_8 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_80_9 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_80_10 = {
			var_80_7,
			var_80_8,
			var_80_9
		}
		local var_80_11 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_80_5,
			labels = var_80_10
		})

		cc.EventProxy.new(var_80_11, var_80_11):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_80_4(1)
		end)
	elseif arg_80_1 then
		var_80_4(0)
	else
		var_80_4(2)
	end
end

function var_0_0.superArenaResult(arg_85_0, arg_85_1)
	local var_85_0 = arg_85_0.peakArena:getCurrentBattleRound()

	arg_85_0.peakArena:setBattleReport(var_85_0, arg_85_0:writeReport(), arg_85_0:checkBattleReport())

	local var_85_1 = arg_85_0.peakArena:setBattleResult(var_85_0, arg_85_0:getBattleStar())

	if var_85_1 then
		arg_85_0:runActionOnce(cc.CallFunc:create(function()
			arg_85_0:finishSuperArena(var_85_1)
		end), false, nil, 2)

		return
	end

	local var_85_2 = arg_85_0.responseData_

	local function var_85_3(arg_87_0)
		if arg_87_0 > 0 then
			arg_85_0:runActionOnce(cc.CallFunc:create(function()
				arg_85_0:finishSuperArena(false)
				arg_85_0.peakArena:clear()
			end), false, nil, arg_87_0)
		else
			arg_85_0:finishSuperArena(false)
			arg_85_0.peakArena:clear()
		end
	end

	if var_85_2 and var_85_2.items and next(var_85_2.items) and not arg_85_0.isReplay then
		local var_85_4 = {}

		for iter_85_0, iter_85_1 in ipairs(var_85_2.items) do
			for iter_85_2 = 1, iter_85_1.item_num do
				local var_85_5 = var_0_8.new()

				var_85_5:populate({
					table_id = iter_85_1.item_id
				})
				table.insert(var_85_4, var_85_5)
			end

			arg_85_0.selfPlayer:getBackpack():addItemsByID(iter_85_1.item_id, iter_85_1.item_num)
		end

		local var_85_6 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_85_7 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_85_8 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_85_9 = {
			var_85_6,
			var_85_7,
			var_85_8
		}
		local var_85_10 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_85_4,
			labels = var_85_9
		})

		cc.EventProxy.new(var_85_10, var_85_10):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_85_3(1)
		end)
	elseif arg_85_1 then
		var_85_3(0)
	else
		var_85_3(2)
	end
end

function var_0_0.arenaResult(arg_90_0, arg_90_1)
	local var_90_0 = arg_90_0.responseData_

	local function var_90_1(arg_91_0)
		if arg_91_0 > 0 then
			arg_90_0:runActionOnce(cc.CallFunc:create(function()
				arg_90_0:finishBattle()
			end), false, nil, arg_91_0)
		else
			arg_90_0:finishBattle()
		end
	end

	if var_90_0 and var_90_0.items and next(var_90_0.items) and not arg_90_0.isReplay then
		local var_90_2 = {}

		for iter_90_0, iter_90_1 in ipairs(var_90_0.items) do
			for iter_90_2 = 1, iter_90_1.item_num do
				local var_90_3 = var_0_8.new()

				var_90_3:populate({
					table_id = iter_90_1.item_id
				})
				table.insert(var_90_2, var_90_3)
			end

			arg_90_0.selfPlayer:getBackpack():addItemsByID(iter_90_1.item_id, iter_90_1.item_num)
		end

		local var_90_4 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_90_5 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_90_6 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_90_7 = {
			var_90_4,
			var_90_5,
			var_90_6
		}
		local var_90_8 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_90_2,
			labels = var_90_7
		})

		cc.EventProxy.new(var_90_8, var_90_8):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_90_1(1)
		end)
	elseif arg_90_1 then
		var_90_1(0)
	else
		var_90_1(2)
	end
end

function var_0_0.regionArenaResult(arg_94_0, arg_94_1)
	local var_94_0 = arg_94_0.responseData_

	local function var_94_1(arg_95_0)
		if arg_95_0 > 0 then
			arg_94_0:runActionOnce(cc.CallFunc:create(function()
				arg_94_0:finishBattle()
			end), false, nil, arg_95_0)
		else
			arg_94_0:finishBattle()
		end
	end

	if var_94_0 and var_94_0.items and next(var_94_0.items) and not arg_94_0.isReplay then
		local var_94_2 = {}

		for iter_94_0, iter_94_1 in ipairs(var_94_0.items) do
			for iter_94_2 = 1, iter_94_1.item_num do
				local var_94_3 = var_0_8.new()

				var_94_3:populate({
					table_id = iter_94_1.item_id
				})
				table.insert(var_94_2, var_94_3)
			end

			arg_94_0.selfPlayer:getBackpack():addItemsByID(iter_94_1.item_id, iter_94_1.item_num)
		end

		local var_94_4 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
		local var_94_5 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
		local var_94_6 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
		local var_94_7 = {
			var_94_4,
			var_94_5,
			var_94_6
		}
		local var_94_8 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
			items = var_94_2,
			labels = var_94_7
		})

		cc.EventProxy.new(var_94_8, var_94_8):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
			var_94_1(1)
		end)
	elseif arg_94_1 then
		var_94_1(0)
	else
		var_94_1(2)
	end
end

function var_0_0.campaignResult(arg_98_0, arg_98_1)
	local function var_98_0(arg_99_0, arg_99_1)
		if arg_99_0 > 0 then
			arg_98_0:runActionOnce(cc.CallFunc:create(function()
				arg_98_0:finishBattle(arg_99_1)
			end), false, nil, arg_99_0)
		else
			arg_98_0:finishBattle(arg_99_1)
		end
	end

	local var_98_1

	if #arg_98_0.petsA ~= 0 and arg_98_0.petsA[1].petID_ ~= arg_98_0.rentPetID then
		var_98_1 = arg_98_0.petsA[1].petID_
	end

	local var_98_2 = {
		campaign_id = arg_98_0.campaignID,
		star = arg_98_0:getBattleStar(),
		campaign_type = arg_98_0.campaignType,
		formation = arg_98_0.formation,
		pet_id = var_98_1
	}

	if arg_98_0:getAwakeMissionResult() then
		if arg_98_0.awakeMissionID then
			var_98_2.awake_mission = arg_98_0.awakeMissionID
		elseif arg_98_0.petAwakeMissionID then
			var_98_2.pet_awaken_mission = arg_98_0.petAwakeMissionID
		end
	end

	if arg_98_0.isAssist and arg_98_0.assistID and var_98_2.star and var_98_2.star > 0 then
		var_98_2.assist_partner = var_0_10:assistPartner(arg_98_0.campaignID)[arg_98_0.assistID]
	end

	local var_98_3 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SELF_PLAYER)

	var_0_12.Backend.get():request(var_0_12.mid.FIGHT_RESULT, var_98_2, function(arg_101_0, arg_101_1)
		if arg_101_0 == var_0_12.error.OK or tonumber(arg_101_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			local var_101_0 = arg_101_1.chapter_info

			if var_101_0 ~= nil then
				var_98_3.normal_chapter_id = var_101_0.normal_chapter_id
				var_98_3.normal_campaign_id = var_101_0.normal_campaign_id
				var_98_3.super_chapter_id = var_101_0.super_chapter_id
				var_98_3.super_campaign_id = var_101_0.super_campaign_id
				var_98_3.super_stars = var_101_0.super_stars
				var_98_3.normal_stars = var_101_0.normal_stars
			end

			var_98_3:handleChapterEvent(arg_101_1)

			if arg_101_1.campaigns ~= nil then
				for iter_101_0, iter_101_1 in pairs(arg_101_1.campaigns) do
					local var_101_1 = tonumber(iter_101_1.campaign_id)

					if var_101_1 then
						var_98_3.worldMaps_[var_101_1] = {}
						var_98_3.worldMaps_[var_101_1].star = tonumber(iter_101_1.star)
						var_98_3.worldMaps_[var_101_1].dailyLimit = tonumber(iter_101_1.daily_limit)
						var_98_3.worldMaps_[var_101_1].resetCount = tonumber(iter_101_1.reset_count)
						var_98_3.worldMaps_[var_101_1].is_partner_drop = tonumber(iter_101_1.is_partner_drop)

						if iter_101_1.star and tonumber(iter_101_1.star) == 0 and var_101_1 ~= arg_98_0.campaignID then
							var_98_3.newOpenCampaignId = var_101_1
							var_98_3.oldCampaignId = arg_98_0.campaignID
						end
					end
				end
			end

			if arg_101_1.trial ~= nil then
				local var_101_2 = arg_101_1.trial
				local var_101_3 = tonumber(var_101_2.id)

				if var_101_3 then
					var_98_3.trialInfos_[var_101_3] = {}
					var_98_3.trialInfos_[var_101_3].id = tonumber(var_101_2.id)
					var_98_3.trialInfos_[var_101_3].leftTimes = tonumber(var_101_2.left_times)
					var_98_3.trialInfos_[var_101_3].isOpen = tonumber(var_101_2.is_open)
					var_98_3.trialInfos_[var_101_3].maxTimes = tonumber(var_101_2.max_times)
					var_98_3.trialInfos_[var_101_3].lastID = tonumber(var_101_2.last_id)
				end
			end

			if arg_101_1.challenge ~= nil then
				local var_101_4 = arg_101_1.challenge
				local var_101_5 = tonumber(var_101_4.id)

				if var_101_5 then
					var_98_3.challengeInfos_[var_101_5] = {}
					var_98_3.challengeInfos_[var_101_5].id = tonumber(var_101_4.id)
					var_98_3.challengeInfos_[var_101_5].leftTimes = tonumber(var_101_4.left_times)
					var_98_3.challengeInfos_[var_101_5].isOpen = tonumber(var_101_4.is_open)
					var_98_3.challengeInfos_[var_101_5].maxTimes = tonumber(var_101_4.max_times)
					var_98_3.challengeInfos_[var_101_5].lastID = tonumber(var_101_4.last_id)
				end
			end

			if arg_101_1.pet_exps ~= nil then
				for iter_101_2, iter_101_3 in ipairs(arg_101_1.pet_exps) do
					local var_101_6 = iter_101_3
					local var_101_7 = var_0_12.tables.player:heroMaxLev(var_98_3.lev)
					local var_101_8 = var_0_12.tables.petExp:totalExp(var_101_7)
					local var_101_9 = arg_98_0.petsA[1]:getExp()

					if tonumber(var_101_6.exp) then
						var_98_3:getPetByID(var_101_6.pet_id):setExp(tonumber(var_101_6.exp), var_101_7)
					end

					arg_98_0.petsA[1].add_exp = var_98_3:getPetByID(var_101_6.pet_id):getExp() - var_101_9
				end
			end

			if arg_101_1 and arg_101_1.items and next(arg_101_1.items) and not arg_98_0.isReplay then
				local var_101_10 = {}

				for iter_101_4, iter_101_5 in ipairs(arg_101_1.items) do
					for iter_101_6 = 1, iter_101_5.item_num do
						local var_101_11 = var_0_8.new()

						var_101_11:populate({
							table_id = iter_101_5.item_id
						})
						table.insert(var_101_10, var_101_11)
					end

					arg_98_0.selfPlayer:getBackpack():addItemsByID(iter_101_5.item_id, iter_101_5.item_num)
				end

				if arg_101_1.star_caystal ~= nil then
					local var_101_12 = table.insert(var_101_10, item)
				end

				local var_101_13 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
				local var_101_14 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
				local var_101_15 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
				local var_101_16 = {
					var_101_13,
					var_101_14,
					var_101_15
				}
				local var_101_17 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
					items = var_101_10,
					labels = var_101_16
				})

				cc.EventProxy.new(var_101_17, var_101_17):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
					var_98_0(1, arg_101_1)
				end)
			elseif arg_101_1.assist_awards and next(arg_101_1.assist_awards) then
				if var_0_12.WindowManager.get():getWindow("levelup") then
					var_0_12.WindowManager.get():closeWindow("levelup")
				end

				arg_98_0.selfPlayer:handleRewards(arg_101_1.assist_awards, function()
					var_98_0(1, arg_101_1)
				end)
			elseif not arg_98_1 then
				var_98_0(2, arg_101_1)
			end
		end
	end, nil, nil, true)
end

function var_0_0.treasureResult(arg_104_0, arg_104_1)
	if arg_104_1 then
		return
	end

	local var_104_0 = {
		win = arg_104_0:getBattleStar() > 0,
		report = arg_104_0:writeReport(),
		hero_status = {}
	}

	for iter_104_0, iter_104_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_104_1.summonType_ == var_0_12.summonMonsterType.None then
			local var_104_1 = {
				hero_id = iter_104_1.hero_:getHeroID(),
				hp = arg_104_0.timeOut_ and 0 or iter_104_1:getHp(),
				mp = arg_104_0.timeOut_ and 0 or iter_104_1:getEnergy(),
				is_reborn = iter_104_1:hasReborned() and 1 or 0
			}

			table.insert(var_104_0.hero_status, var_104_1)
		end
	end

	var_104_0.enemy_status = {}

	for iter_104_2, iter_104_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_104_3.summonType_ == var_0_12.summonMonsterType.None then
			local var_104_2 = {
				hero_id = iter_104_3.hero_:getHeroID(),
				hp = arg_104_0.timeOut_ and 0 or iter_104_3:getHp(),
				mp = arg_104_0.timeOut_ and 0 or iter_104_3:getEnergy(),
				is_reborn = iter_104_3:hasReborned() and 1 or 0
			}

			table.insert(var_104_0.enemy_status, var_104_2)
		end
	end

	if arg_104_0:getBattleStar() <= 0 then
		local var_104_3 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.TREASURE)

		var_104_3:updateHeroStatus(var_104_0.hero_status, true)
		var_104_3:updateHeroStatus(var_104_0.enemy_status, false)
	end

	var_0_12.Backend.get():request(var_0_12.mid.TREASURE_SAVE_BATTLE_RESULT, var_104_0, function(arg_105_0, arg_105_1)
		if (arg_105_0 == var_0_12.error.OK or tonumber(arg_105_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_104_1 then
			arg_104_0:runActionOnce(cc.CallFunc:create(function()
				arg_104_0:finishBattle(arg_105_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.marchResult(arg_107_0, arg_107_1)
	if arg_107_1 then
		return
	end

	local var_107_0 = {
		is_reborn = 0,
		win = arg_107_0:getBattleStar() > 0
	}

	if var_107_0.win == true then
		arg_107_0:reMpHp()
	end

	var_107_0.formation = arg_107_0.formation
	var_107_0.hero_status = {}

	for iter_107_0, iter_107_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_107_1:getSummonType() == var_0_12.summonMonsterType.None then
			local var_107_1 = {}

			if iter_107_1.hero_.player_id then
				var_107_1.player_id = iter_107_1.hero_.player_id
			else
				var_107_1.player_id = arg_107_0.selfPlayer.playerID
			end

			var_107_1.hero_id = iter_107_1.hero_:getHeroID()
			var_107_1.hp = arg_107_0.timeOut_ and 0 or iter_107_1:getHp()
			var_107_1.mp = arg_107_0.timeOut_ and 0 or iter_107_1:getEnergy()
			var_107_1.is_reborn = iter_107_1:hasReborned() and 1 or 0

			table.insert(var_107_0.hero_status, var_107_1)
		end
	end

	var_107_0.enemy_status = {}

	for iter_107_2, iter_107_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_107_3:getSummonType() == var_0_12.summonMonsterType.None then
			local var_107_2 = {
				hero_id = iter_107_3.hero_:getHeroID(),
				hp = arg_107_0.timeOut_ and 0 or iter_107_3:getHp(),
				mp = arg_107_0.timeOut_ and 0 or iter_107_3:getEnergy(),
				is_reborn = iter_107_3:hasReborned() and 1 or 0
			}

			table.insert(var_107_0.enemy_status, var_107_2)
		end
	end

	if arg_107_0.marchModel.mapInfo and arg_107_0.marchModel.mapInfo.power_drink then
		var_107_0.cost_drink = arg_107_0.marchModel.mapInfo.power_drink - arg_107_0.medicineNum
	else
		var_107_0.cost_drink = 0
	end

	var_0_12.Backend.get():request(var_0_12.mid.MARCH_FIGHT_RESULT, var_107_0, function(arg_108_0, arg_108_1)
		if (arg_108_0 == var_0_12.error.OK or tonumber(arg_108_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_107_1 then
			arg_107_0:runActionOnce(cc.CallFunc:create(function()
				arg_107_0:finishBattle(arg_108_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.guildResult(arg_110_0, arg_110_1)
	local var_110_0

	if #arg_110_0.petsA ~= 0 then
		var_110_0 = arg_110_0.petsA[1].petID_
	end

	local var_110_1 = 0
	local var_110_2 = 0
	local var_110_3 = 0

	for iter_110_0, iter_110_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_110_1 = var_110_1 + iter_110_1.harms
	end

	local var_110_4 = {
		total_damage = var_110_1,
		star = arg_110_0:getBattleStar(),
		chapter_id = arg_110_0.fightParams.chapter_id,
		copy_id = arg_110_0.fightParams.copy_id,
		current_index = arg_110_0.group_,
		formation = arg_110_0.fightParams.formation,
		pet_id = var_110_0
	}

	if arg_110_0.fightParams.rent_formation then
		var_110_4.rent_formation = arg_110_0.fightParams.rent_formation
		var_110_4.rent_player_id = arg_110_0.fightParams.rent_player_id
	end

	var_110_4.enemy_status = {}

	for iter_110_2 = 1, #arg_110_0.heroGroupB do
		local var_110_5 = arg_110_0.heroGroupB[iter_110_2]

		if iter_110_2 < arg_110_0.group_ then
			for iter_110_3, iter_110_4 in ipairs(var_110_5) do
				local var_110_6 = {
					hero_id = iter_110_4:getHeroID()
				}

				var_110_6.hp = 0
				var_110_6.is_reborn = 0
				var_110_6.index = iter_110_2

				table.insert(var_110_4.enemy_status, var_110_6)

				var_110_2 = var_110_2 + iter_110_4:getBattleAttr(var_0_12.AttributeType.HP)
				var_110_3 = var_110_3 + var_110_6.hp
			end
		elseif iter_110_2 == arg_110_0.group_ then
			for iter_110_5, iter_110_6 in ipairs(var_0_13.ctx.battle.teamB) do
				if iter_110_6.summonType_ == var_0_12.summonMonsterType.None then
					local var_110_7 = {
						hero_id = iter_110_6.hero_:getHeroID(),
						hp = iter_110_6:getHp(),
						is_reborn = iter_110_6:hasReborned() and 1 or 0,
						index = iter_110_2
					}

					table.insert(var_110_4.enemy_status, var_110_7)

					var_110_2 = var_110_2 + iter_110_6.hero_:getBattleAttr(var_0_12.AttributeType.HP)
					var_110_3 = var_110_3 + var_110_7.hp
				end
			end
		else
			for iter_110_7, iter_110_8 in ipairs(var_110_5) do
				local var_110_8 = {
					hero_id = iter_110_8:getHeroID(),
					hp = iter_110_8:getBattleAttr(var_0_12.AttributeType.HP)
				}

				var_110_8.is_reborn = 0
				var_110_8.index = iter_110_2

				table.insert(var_110_4.enemy_status, var_110_8)

				var_110_2 = var_110_2 + iter_110_8:getBattleAttr(var_0_12.AttributeType.HP)
				var_110_3 = var_110_3 + var_110_8.hp
			end
		end
	end

	local var_110_9 = {
		totalHp = var_110_2,
		currentHp = var_110_3,
		totalHarm = var_110_1
	}

	local function var_110_10(arg_111_0, arg_111_1, arg_111_2)
		arg_111_2 = arg_111_2 or 2

		arg_110_0:runActionOnce(cc.CallFunc:create(function()
			if arg_111_0.normal_drop and next(arg_111_0.normal_drop) then
				local var_112_0 = {}

				for iter_112_0, iter_112_1 in ipairs(arg_111_0.normal_drop) do
					for iter_112_2 = 1, iter_112_1.item_num do
						local var_112_1 = var_0_8.new()

						var_112_1:populate({
							table_id = iter_112_1.item_id
						})
						table.insert(var_112_0, var_112_1)
					end
				end

				arg_111_1.items = var_112_0
			end

			if arg_111_0.guild_drop and next(arg_111_0.guild_drop) then
				local var_112_2 = {}

				for iter_112_3, iter_112_4 in ipairs(arg_111_0.guild_drop) do
					for iter_112_5 = 1, iter_112_4.item_num do
						local var_112_3 = var_0_8.new()

						var_112_3:populate({
							table_id = iter_112_4.item_id
						})
						table.insert(var_112_2, var_112_3)
					end
				end

				arg_111_1.guild_items = var_112_2
			end

			arg_110_0:finishBattle(arg_111_0, arg_111_1)
		end), false, nil, arg_111_2)
	end

	var_0_12.Backend.get():request(var_0_12.mid.GUILD_FIGHT_RESULT, var_110_4, function(arg_113_0, arg_113_1)
		if arg_113_0 == var_0_12.error.OK or tonumber(arg_113_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			if arg_113_1.rank_award and arg_113_1.rank_award.crystal > 0 or arg_113_1.rank_award.guild_coin > 0 then
				local var_113_0 = {
					crystal = arg_113_1.rank_award.crystal,
					guild_coin = arg_113_1.rank_award.guild_coin,
					harm = var_110_1
				}
				local var_113_1 = var_0_12.WindowManager.get():openWindow("guild_top_damage_award", var_113_0)

				cc.EventProxy.new(var_113_1, var_113_1):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
					var_110_10(arg_113_1, var_110_9, 1)
				end)

				return
			end

			var_110_10(arg_113_1, var_110_9, 2)
		elseif (arg_113_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdTimeEnd then
			local var_113_2 = var_0_12.tables.message:getContent(var_0_13.ctx.battleConst.errorIdTimeEnd)

			var_0_12.WindowManager.get():openWindow("toast", {
				message = var_113_2
			})
			arg_110_0:runActionOnce(cc.CallFunc:create(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.elementResult(arg_116_0, arg_116_1)
	local var_116_0 = 0

	for iter_116_0, iter_116_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_116_0 = var_116_0 + iter_116_1.harms
	end

	local var_116_1 = 0

	for iter_116_2, iter_116_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_116_3:isBoss() then
			var_116_1 = var_0_17(iter_116_3:getHpLimit() - iter_116_3:getHp())

			break
		end
	end

	local var_116_2 = {
		campaign_id = arg_116_0.campaignID,
		total_damage = var_116_1 > 1 and var_116_1 or var_0_17(var_116_0),
		campaign_type = arg_116_0.campaignType,
		formation = arg_116_0.fightParams.formation
	}

	if arg_116_0.fightParams.rent_formation then
		var_116_2.rent_formation = arg_116_0.fightParams.rent_formation
		var_116_2.rent_player_id = arg_116_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.WORLD_BOSS_FIGHT_RESULT, var_116_2, function(arg_117_0, arg_117_1)
		if (arg_117_0 == var_0_12.error.OK or tonumber(arg_117_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_116_1 then
			arg_116_0:runActionOnce(cc.CallFunc:create(function()
				arg_116_0:finishElement(arg_117_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.adventureDefenseResult(arg_119_0, arg_119_1)
	local var_119_0

	if #arg_119_0.petsA ~= 0 then
		var_119_0 = arg_119_0.petsA[1].petID_
	end

	local var_119_1 = arg_119_0:getTotalHarms(var_0_13.ctx.battle.teamA)
	local var_119_2 = {
		star = arg_119_0:getBattleStar(),
		monster_pos = arg_119_0.monsterPos,
		formation = arg_119_0.formation,
		pet_id = var_119_0,
		table_id = var_0_12.AdventureEventType.DEFENSE,
		total_damage = var_119_1
	}

	if arg_119_0.fightParams.rent_pet_id then
		var_119_2.rent_pet_id = arg_119_0.fightParams.rent_pet_id
		var_119_2.rent_pet_player_id = arg_119_0.fightParams.rent_pet_player_id
	end

	if arg_119_0.fightParams.rent_formation then
		var_119_2.rent_formation = arg_119_0.fightParams.rent_formation
		var_119_2.rent_player_id = arg_119_0.fightParams.rent_player_id
	end

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ADVENTURE_EVENT):fightRoomResult(var_119_2, function(arg_120_0, arg_120_1)
		if arg_120_0 == var_0_12.error.OK or tonumber(arg_120_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			if not arg_119_1 then
				arg_119_0:runActionOnce(cc.CallFunc:create(function()
					arg_119_0:finishBattle(arg_120_1, {})
				end), false, nil, 2)
			end
		else
			arg_119_0:runActionOnce(cc.CallFunc:create(function()
				var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
				var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
				arg_119_0:clearFormation(true)
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end), false, nil, 2)
		end
	end)
end

function var_0_0.adventureIllusionSingleResult(arg_123_0, arg_123_1)
	local var_123_0 = 0

	for iter_123_0, iter_123_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_123_0 = var_123_0 + iter_123_1.harms
	end

	local var_123_1 = 0
	local var_123_2 = false

	for iter_123_2, iter_123_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_123_3:isBoss() then
			if iter_123_3:getHp() < 1 then
				var_123_2 = true
			end

			var_123_1 = var_0_17(iter_123_3:getHpLimit() - iter_123_3:getHp())

			break
		end
	end

	local var_123_3 = {
		star = 0,
		total_damage = var_123_1 > 1 and var_123_1 or var_0_17(var_123_0),
		formation = arg_123_0.fightParams.formation
	}

	if var_123_2 then
		var_123_3.star = 1
	end

	if arg_123_0.fightParams.rent_pet_id then
		var_123_3.rent_pet_id = arg_123_0.fightParams.rent_pet_id
		var_123_3.rent_pet_player_id = arg_123_0.fightParams.rent_pet_player_id
	end

	if arg_123_0.fightParams.rent_formation then
		var_123_3.rent_formation = arg_123_0.fightParams.rent_formation
		var_123_3.rent_player_id = arg_123_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.FIGHT_PARADISE_FIGHT, var_123_3, function(arg_124_0, arg_124_1)
		if arg_124_0 == var_0_12.error.OK or tonumber(arg_124_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			if not arg_123_1 then
				arg_123_0:runActionOnce(cc.CallFunc:create(function()
					arg_123_0:finishAdventureIllusionSingle(arg_124_1)
				end), false, nil, 2)
			end
		else
			arg_123_0:runActionOnce(cc.CallFunc:create(function()
				var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
				var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
				arg_123_0:clearFormation(true)
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.illusionResult(arg_127_0, arg_127_1)
	local var_127_0

	if #arg_127_0.petsA ~= 0 then
		var_127_0 = arg_127_0.petsA[1].petID_
	end

	local var_127_1 = 0

	for iter_127_0, iter_127_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_127_1 = var_127_1 + iter_127_1.harms
	end

	local var_127_2 = 0
	local var_127_3 = false

	for iter_127_2, iter_127_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_127_3:isBoss() then
			if iter_127_3:getHp() < 1 then
				var_127_3 = true
			end

			var_127_2 = var_0_17(iter_127_3:getHpLimit() - iter_127_3:getHp())

			break
		end
	end

	local var_127_4 = {
		star = 0,
		total_damage = var_127_2 > 1 and var_127_2 or var_0_17(var_127_1),
		formation = arg_127_0.fightParams.formation,
		cost_time = var_0_13.ctx.battle.count
	}

	if var_127_3 then
		var_127_4.star = 1
	end

	if var_127_0 then
		var_127_4.pet_id = var_127_0
	end

	if arg_127_0.fightParams.rent_formation then
		var_127_4.rent_formation = arg_127_0.fightParams.rent_formation
		var_127_4.rent_player_id = arg_127_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.ILLUSION_FIGHT_RESULT, var_127_4, function(arg_128_0, arg_128_1)
		if (arg_128_0 == var_0_12.error.OK or tonumber(arg_128_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_127_1 then
			arg_127_0:runActionOnce(cc.CallFunc:create(function()
				arg_127_0:finishIllusion(arg_128_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.illusionCooperationResult(arg_130_0, arg_130_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_130_0 = {}
	local var_130_1 = {}
	local var_130_2 = {}
	local var_130_3 = {}

	for iter_130_0, iter_130_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_130_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_130_0, iter_130_1)
		elseif iter_130_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_130_2, iter_130_1)
		end
	end

	for iter_130_2, iter_130_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_130_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_130_1, iter_130_3)
		elseif iter_130_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_130_3, iter_130_3)
		end
	end

	arg_130_0:clearFormation(true)

	local var_130_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ILLUSION):getDamageResult()
	local var_130_5 = {
		rank = var_130_4.rank,
		damage = var_130_4.now_hurt,
		damageHighest = var_130_4.highest_hurt,
		fighterA = var_130_0,
		fighterB = var_130_1,
		petA = var_130_2
	}

	if var_130_4.pre_info then
		var_130_5.pre_name = var_130_4.pre_info.player_name
		var_130_5.pre_avatar = var_130_4.pre_info.avatar_id
		var_130_5.pre_avatar_frame = var_130_4.pre_info.avatar_frame_id
		var_130_5.pre_lev = var_130_4.pre_info.lev
		var_130_5.pre_damage = var_130_4.pre_info.hurt
		var_130_5.pre_rank = var_130_4.pre_info.pre_rank
	end

	var_0_12.WindowManager.get():openWindow("illusion_battle_result", var_130_5, function(arg_131_0)
		if arg_131_0 == nil then
			return
		end

		arg_130_0.battleEndWindow_ = arg_131_0

		cc.EventProxy.new(arg_130_0.battleEndWindow_, arg_130_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_132_0)
			arg_130_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.adventureIllusionCooperationResult(arg_134_0, arg_134_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_134_0 = {}
	local var_134_1 = {}
	local var_134_2 = {}
	local var_134_3 = {}

	for iter_134_0, iter_134_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_134_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_134_0, iter_134_1)
		elseif iter_134_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_134_2, iter_134_1)
		end
	end

	for iter_134_2, iter_134_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_134_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_134_1, iter_134_3)
		elseif iter_134_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_134_3, iter_134_3)
		end
	end

	arg_134_0:clearFormation(true)

	local var_134_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ADVENTURE_EVENT):getDamageResult()
	local var_134_5 = {
		damage = var_134_4,
		fighterA = var_134_0,
		fighterB = var_134_1,
		petA = var_134_2
	}

	var_0_12.WindowManager.get():openWindow("adventure_illusion_battle_result", var_134_5, function(arg_135_0)
		if arg_135_0 == nil then
			return
		end

		arg_134_0.battleEndWindow_ = arg_135_0

		cc.EventProxy.new(arg_134_0.battleEndWindow_, arg_134_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_136_0)
			arg_134_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.hunqiResult(arg_138_0, arg_138_1)
	local var_138_0

	if #arg_138_0.petsA ~= 0 and arg_138_0.petsA[1].petID_ ~= arg_138_0.rentPetID then
		var_138_0 = arg_138_0.petsA[1].petID_
	end

	local var_138_1 = {
		campaign_id = arg_138_0.campaignID,
		star = arg_138_0:getBattleStar() or 0,
		campaign_type = arg_138_0.campaignType,
		partner_ids = var_0_12.splitToNumber(arg_138_0.formation, "|"),
		pet_id = var_138_0
	}

	var_0_12.Backend.get():request(var_0_12.mid.HUNQI_FIGHT_RESULT, var_138_1, function(arg_139_0, arg_139_1)
		if arg_139_0 == var_0_12.error.OK or tonumber(arg_139_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			arg_138_0:runActionOnce(cc.CallFunc:create(function()
				local var_140_0 = {}

				if arg_139_1 and arg_139_1.items and next(arg_139_1.items) then
					for iter_140_0, iter_140_1 in ipairs(arg_139_1.items) do
						for iter_140_2 = 1, iter_140_1.item_num do
							local var_140_1 = var_0_8.new()

							var_140_1:populate({
								table_id = iter_140_1.item_id
							})
							table.insert(var_140_0, var_140_1)
						end
					end
				end

				arg_138_0:finishBattle(arg_139_1, {
					items = var_140_0
				})
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.allNightBossResult(arg_141_0, arg_141_1)
	local var_141_0

	if #arg_141_0.petsA ~= 0 then
		var_141_0 = arg_141_0.petsA[1].petID_
	end

	local var_141_1 = 0

	for iter_141_0, iter_141_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_141_1 = var_141_1 + iter_141_1.harms
	end

	local var_141_2 = 0
	local var_141_3 = false

	for iter_141_2, iter_141_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_141_3:isBoss() then
			if iter_141_3:getHp() < 1 then
				var_141_3 = true
			end

			var_141_2 = var_0_17(iter_141_3:getHpLimit() - iter_141_3:getHp())

			break
		end
	end

	local var_141_4 = {
		star = 0,
		damage = var_141_2 > 1 and var_141_2 or var_0_17(var_141_1),
		formation = arg_141_0.fightParams.formation
	}

	if var_141_3 then
		var_141_4.star = 1
	end

	if var_141_0 then
		var_141_4.pet_id = var_141_0
	end

	if arg_141_0.fightParams.rent_formation then
		var_141_4.rent_formation = arg_141_0.fightParams.rent_formation
		var_141_4.rent_player_id = arg_141_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.POLAR_NIGHT_BOSS_FIGHT_RESULT, var_141_4, function(arg_142_0, arg_142_1)
		if arg_142_0 == var_0_12.error.OK or tonumber(arg_142_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			arg_142_1.now_hurt = var_141_4.damage

			arg_141_0:runActionOnce(cc.CallFunc:create(function()
				arg_141_0:finishAllNightBoss(arg_142_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.ragnarokResult(arg_144_0, arg_144_1)
	local var_144_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.RAGNAROK)
	local var_144_1 = {}

	for iter_144_0, iter_144_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_144_1:getSummonType() == var_0_12.summonMonsterType.None then
			if iter_144_1:isDeath() then
				table.insert(var_144_1, 0)
			else
				table.insert(var_144_1, 1)
			end
		end
	end

	local var_144_2 = 0

	for iter_144_2, iter_144_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_144_3:getSummonType() == var_0_12.summonMonsterType.None then
			if iter_144_3:getHp() < 1 then
				var_144_2 = var_144_0:getEnemyHp()

				break
			end

			var_144_2 = var_0_17(var_144_0:getEnemyHp() - iter_144_3:getHp())

			break
		end
	end

	if arg_144_1 then
		for iter_144_4 = 1, #var_144_1 do
			var_144_1[iter_144_4] = 1
		end

		var_144_2 = 0
	end

	local var_144_3 = table.concat(var_144_1, "|")
	local var_144_4 = {
		damage = math.max(0, var_144_2),
		formation = arg_144_0.fightParams.formation,
		hero_status = var_144_3,
		pos = arg_144_0.fightParams.pos
	}

	if var_144_0:getType() == var_0_12.RagnarokType.SINGLE then
		var_0_12.Backend.get():request(var_0_12.mid.RAGNAROK_SINGLE_FIGHT_RESULT, var_144_4, function(arg_145_0, arg_145_1)
			if arg_145_0 == var_0_12.error.OK or tonumber(arg_145_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
				arg_144_0:runActionOnce(cc.CallFunc:create(function()
					arg_144_0:finishRagnarok(arg_145_1)
				end), false, nil, 2)
			else
				arg_144_0:runActionOnce(cc.CallFunc:create(function()
					arg_144_0:finishRagnarok()
				end), false, nil, 2)
			end
		end, nil, nil, true)
	elseif var_144_0:getType() == var_0_12.RagnarokType.TEAM then
		var_0_12.Backend.get():request(var_0_12.mid.RAGNAROK_TEAM_FIGHT_RESULT, var_144_4, function(arg_148_0, arg_148_1)
			if arg_148_0 == var_0_12.error.OK or tonumber(arg_148_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
				arg_144_0:runActionOnce(cc.CallFunc:create(function()
					arg_144_0:finishRagnarok(arg_148_1)
				end), false, nil, 2)
			else
				arg_144_0:runActionOnce(cc.CallFunc:create(function()
					arg_144_0:finishRagnarok()
				end), false, nil, 2)
			end
		end, nil, nil, true)
	end
end

function var_0_0.fifthAnniBossResult(arg_151_0, arg_151_1)
	local var_151_0

	if #arg_151_0.petsA ~= 0 then
		var_151_0 = arg_151_0.petsA[1].petID_
	end

	local var_151_1 = 0

	for iter_151_0, iter_151_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_151_1 = var_151_1 + iter_151_1.harms
	end

	local var_151_2 = 0
	local var_151_3 = false

	for iter_151_2, iter_151_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_151_3:isBoss() then
			if iter_151_3:getHp() < 1 then
				local var_151_4 = true
			end

			var_151_2 = var_0_17(iter_151_3:getHpLimit() - iter_151_3:getHp())

			break
		end
	end

	local var_151_5 = {
		damage = var_151_2 > 1 and var_151_2 or var_0_17(var_151_1),
		formation = arg_151_0.fightParams.formation
	}

	if var_151_0 then
		var_151_5.pet_id = var_151_0
	end

	if arg_151_0.fightParams.rent_pet_id then
		var_151_5.rent_pet_id = arg_151_0.fightParams.rent_pet_id
		var_151_5.rent_pet_player_id = arg_151_0.fightParams.rent_pet_player_id
	end

	if arg_151_0.fightParams.rent_formation then
		var_151_5.rent_formation = arg_151_0.fightParams.rent_formation
		var_151_5.rent_player_id = arg_151_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.FIFTH_ANNI_BOSS_FIGHT_RESULT, var_151_5, function(arg_152_0, arg_152_1)
		if arg_152_0 == var_0_12.error.OK or tonumber(arg_152_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			arg_152_1.now_hurt = var_151_5.damage

			arg_151_0:runActionOnce(cc.CallFunc:create(function()
				arg_151_0:finishFifthAnniBoss(arg_152_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.warCampResult(arg_154_0, arg_154_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_154_0 = {}
	local var_154_1 = {}
	local var_154_2 = {}
	local var_154_3 = {}

	for iter_154_0, iter_154_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_154_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_154_0, iter_154_1)
		elseif iter_154_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_154_2, iter_154_1)
		end
	end

	for iter_154_2, iter_154_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_154_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_154_1, iter_154_3)
		elseif iter_154_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_154_3, iter_154_3)
		end
	end

	arg_154_0:clearFormation(true)

	local var_154_4 = {
		fighterA = var_154_0,
		fighterB = var_154_1,
		petA = var_154_2
	}

	var_0_12.WindowManager.get():openWindow("war_camp_damage_wnd", var_154_4, function(arg_155_0)
		if arg_155_0 == nil then
			return
		end

		arg_154_0.battleEndWindow_ = arg_155_0

		cc.EventProxy.new(arg_154_0.battleEndWindow_, arg_154_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_156_0)
			arg_154_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.warCampEnemyResult(arg_158_0, arg_158_1)
	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		arg_158_0:runActionOnce(cc.CallFunc:create(function()
			arg_158_0:finishBattle({}, {})
		end), false, nil, 2)

		return
	end
end

function var_0_0.petResult(arg_160_0, arg_160_1)
	local var_160_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.PET_COMPAIGN)

	if arg_160_0.petFloorType == var_0_12.PetCampaignFloorType.SUPER then
		var_160_0.lastSuperMaxFloor = var_160_0.max_floor
	end

	if arg_160_1 then
		return
	end

	local var_160_1

	if #arg_160_0.petsA ~= 0 then
		var_160_1 = arg_160_0.petsA[1].petID_
	end

	local var_160_2 = {
		is_win = arg_160_0:getBattleStar() > 0,
		floor = arg_160_0.petFloor,
		floor_type = arg_160_0.petFloorType,
		pet_id = var_160_1
	}

	if var_160_2.floor_type == var_0_12.PetCampaignFloorType.SUPER and not var_160_2.is_win or arg_160_0.noResult then
		arg_160_0:finishBattle({}, {})

		return
	end

	var_160_0:battleResult(function(arg_161_0, arg_161_1)
		if not arg_160_1 then
			arg_160_0:runActionOnce(cc.CallFunc:create(function()
				local var_162_0 = {}

				if arg_161_1.awards and next(arg_161_1.awards) then
					local var_162_1 = {}

					for iter_162_0, iter_162_1 in ipairs(arg_161_1.awards) do
						for iter_162_2 = 1, iter_162_1.item_num do
							if iter_162_1.table_id ~= -1 then
								local var_162_2 = var_0_8.new()

								var_162_2:populate({
									table_id = iter_162_1.table_id
								})
								table.insert(var_162_1, var_162_2)
							else
								var_162_0.mana = iter_162_1.item_num
							end
						end
					end

					var_162_0.items = var_162_1
				end

				arg_160_0:finishBattle(arg_161_1, var_162_0)
			end), false, nil, 2)
			var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_PET_TWO)
			var_0_12.StoryData.get():persist()
		end
	end, var_160_2)
end

function var_0_0.sakuraResult(arg_163_0, arg_163_1)
	local function var_163_0(arg_164_0, arg_164_1)
		if arg_164_0 > 0 then
			arg_163_0:runActionOnce(cc.CallFunc:create(function()
				arg_163_0:finishBattle(arg_164_1)
			end), false, nil, arg_164_0)
		else
			arg_163_0:finishBattle(arg_164_1)
		end
	end

	var_0_12.Backend.get():request(var_0_12.mid.SAKURA_FIGHT_RESULT, {
		star = arg_163_0:getBattleStar()
	}, function(arg_166_0, arg_166_1)
		if arg_166_0 == var_0_12.error.OK or tonumber(arg_166_1.error_code or 0) == var_0_12.battleConst.errorIdFightExist then
			if arg_166_1 and arg_166_1.items and next(arg_166_1.items) then
				var_163_0(1, arg_166_1)
			elseif not arg_163_1 then
				var_163_0(1, arg_166_1)
			else
				var_163_0(1, arg_166_1)
			end
		end
	end, nil, nil, true)
end

function var_0_0.studentOverResult(arg_167_0, arg_167_1)
	local function var_167_0(arg_168_0, arg_168_1)
		if arg_168_0 > 0 then
			arg_167_0:runActionOnce(cc.CallFunc:create(function()
				arg_167_0:finishBattle(arg_168_1)
			end), false, nil, arg_168_0)
		else
			arg_167_0:finishBattle(arg_168_1)
		end
	end

	local var_167_1 = {}

	if arg_167_0:getBattleStar() > 0 then
		var_167_1.is_win = 1
	else
		var_167_0(1, response)

		return
	end

	var_167_1.formation = arg_167_0.formation

	local var_167_2

	if arg_167_0.petsA and arg_167_0.petsA[1] then
		var_167_2 = arg_167_0.petsA[1].petID_
	end

	var_167_1.pet_id = var_167_2

	var_0_12.Backend.get():request(var_0_12.mid.STUDENT_OVER_FIGHT_RESULT, var_167_1, function(arg_170_0, arg_170_1)
		if arg_170_0 == var_0_12.error.OK or tonumber(arg_170_1.error_code or 0) == var_0_12.battleConst.errorIdFightExist then
			if arg_170_1 and arg_170_1.items and next(arg_170_1.items) then
				local var_170_0 = {}

				for iter_170_0, iter_170_1 in ipairs(arg_170_1.items) do
					for iter_170_2 = 1, iter_170_1.item_num do
						local var_170_1 = var_0_8.new()

						var_170_1:populate({
							table_id = iter_170_1.item_id
						})
						table.insert(var_170_0, var_170_1)
					end

					arg_167_0.selfPlayer:getBackpack():addItemsByID(iter_170_1.item_id, iter_170_1.item_num)
				end

				var_167_0(1, arg_170_1)
			elseif not arg_167_1 then
				var_167_0(1, arg_170_1)
			else
				var_167_0(1, arg_170_1)
			end
		end
	end, nil, nil, true)
end

function var_0_0.nianBossResult(arg_171_0, arg_171_1)
	local var_171_0 = 0

	for iter_171_0, iter_171_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_171_0 = var_171_0 + iter_171_1.harms
	end

	local var_171_1 = 0

	for iter_171_2, iter_171_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_171_3:isBoss() then
			var_171_1 = var_0_17(iter_171_3:getHpLimit() - iter_171_3:getHp())

			break
		end
	end

	local var_171_2 = {
		campaign_id = arg_171_0.campaignID,
		total_damage = var_171_1 > 1 and var_171_1 or var_0_17(var_171_0),
		campaign_type = arg_171_0.campaignType,
		formation = arg_171_0.fightParams.formation
	}

	if arg_171_0.fightParams.rent_formation then
		var_171_2.rent_formation = arg_171_0.fightParams.rent_formation
		var_171_2.rent_player_id = arg_171_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.NIAN_BOSS_FIGHT_RESULT, var_171_2, function(arg_172_0, arg_172_1)
		if (arg_172_0 == var_0_12.error.OK or tonumber(arg_172_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_171_1 then
			arg_171_0:runActionOnce(cc.CallFunc:create(function()
				arg_171_0:finishNianBoss(arg_172_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.thirdAnniversaryBossResult(arg_174_0, arg_174_1)
	local var_174_0 = 0

	for iter_174_0, iter_174_1 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_174_1:isBoss() then
			var_174_0 = var_0_17(iter_174_1:getHpLimit() - iter_174_1:getHp())

			break
		end
	end

	local var_174_1 = {
		formation = arg_174_0.formation,
		damage = var_174_0 > 1 and var_174_0 or 0
	}

	if arg_174_0.fightParams.rent_pet_id then
		var_174_1.rent_pet_id = arg_174_0.fightParams.rent_pet_id
		var_174_1.rent_pet_player_id = arg_174_0.fightParams.rent_pet_player_id
	end

	if arg_174_0.fightParams.rent_formation then
		var_174_1.rent_formation = arg_174_0.fightParams.rent_formation
		var_174_1.rent_player_id = arg_174_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.THIRD_ANNIVERSARY_BOSS_FIGHT_RESULT, var_174_1, function(arg_175_0, arg_175_1)
		if arg_175_0 == var_0_12.error.OK or tonumber(arg_175_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			arg_174_0:runActionOnce(cc.CallFunc:create(function()
				arg_175_1.selfHarms = var_174_0

				arg_174_0:finishThirdAnniversaryBoss(arg_175_1)

				if arg_175_1.awards then
					arg_174_0.selfPlayer:handleRewards(arg_175_1.awards)
				end
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.zhugeNoteResult(arg_177_0, arg_177_1)
	local var_177_0 = arg_177_0:getBattleStar() > 0

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ZHUGE_FESTIVAL):completeTask(var_177_0, function(arg_178_0, arg_178_1)
		if arg_178_0 == var_0_12.error.OK then
			arg_177_0:runActionOnce(cc.CallFunc:create(function()
				local var_179_0 = {}

				if arg_178_1.awards and next(arg_178_1.awards) then
					local var_179_1 = {}

					for iter_179_0, iter_179_1 in ipairs(arg_178_1.awards) do
						for iter_179_2 = 1, iter_179_1.item_num do
							if iter_179_1.table_id ~= -1 then
								local var_179_2 = var_0_8.new()

								var_179_2:populate({
									table_id = iter_179_1.table_id
								})
								table.insert(var_179_1, var_179_2)
							else
								var_179_0.mana = iter_179_1.item_num
							end
						end
					end

					var_179_0.items = var_179_1
				end

				arg_177_0:finishBattle(arg_178_1, var_179_0)
			end), false, nil, 2)
		end
	end)
end

function var_0_0.singleDayResult(arg_180_0, arg_180_1)
	if arg_180_1 then
		return
	end

	local var_180_0 = 0

	for iter_180_0, iter_180_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_180_0 = var_180_0 + iter_180_1.harms
	end

	local var_180_1 = 0

	for iter_180_2, iter_180_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_180_3:isBoss() then
			var_180_1 = var_0_17(iter_180_3:getHpLimit() - iter_180_3:getHp())

			break
		end
	end

	local var_180_2 = {
		campaign_id = arg_180_0.campaignID,
		total_damage = var_180_1 > 1 and var_180_1 or var_0_17(var_180_0),
		campaign_type = arg_180_0.campaignType,
		formation = arg_180_0.fightParams.formation,
		mission_id = arg_180_0.missionID
	}

	if arg_180_0.fightParams.rent_formation then
		var_180_2.rent_formation = arg_180_0.fightParams.rent_formation
		var_180_2.rent_player_id = arg_180_0.fightParams.rent_player_id
	end

	if not arg_180_1 then
		arg_180_0:runActionOnce(cc.CallFunc:create(function()
			arg_180_0:finishSingleDayBattle(var_180_2)
		end), false, nil, 2)
	end
end

function var_0_0.occultResult(arg_182_0, arg_182_1)
	if arg_182_1 then
		return
	end

	local var_182_0

	if arg_182_0.petsA and arg_182_0.petsA[1] then
		var_182_0 = arg_182_0.petsA[1].petID_
	end

	local var_182_1 = {
		campaign_id = arg_182_0.campaignID,
		formation = arg_182_0.fightParams.formation,
		sub_id = arg_182_0.subId,
		star = arg_182_0:getBattleStar(),
		pet_id = var_182_0,
		hero_status = {}
	}

	for iter_182_0, iter_182_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_182_1.summonType_ == var_0_12.summonMonsterType.None then
			local var_182_2 = {
				hp = math.ceil(iter_182_1:getHp()),
				mp = math.ceil(iter_182_1:getEnergy()),
				is_reborn = iter_182_1:hasReborned() and 1 or 0
			}

			var_182_1.hero_status[tostring(iter_182_1.hero_:getHeroID())] = var_182_2
		end
	end

	var_182_1.monster_status = {}

	for iter_182_2, iter_182_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_182_3.summonType_ == var_0_12.summonMonsterType.None then
			local var_182_3 = {
				hp = math.ceil(iter_182_3:getHp()),
				mp = math.ceil(iter_182_3:getEnergy()),
				is_reborn = iter_182_3:hasReborned() and 1 or 0
			}

			var_182_1.monster_status[tostring(iter_182_3.hero_:getHeroID())] = var_182_3
		end
	end

	local var_182_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.OCCULT)

	var_182_4:singleFight(var_182_1, function(arg_183_0, arg_183_1)
		if arg_183_0 == var_0_12.error.OK then
			for iter_183_0, iter_183_1 in pairs(var_182_1.hero_status) do
				if var_182_4.dispatchInfo and var_182_4.dispatchInfo[iter_183_0] then
					var_182_4.dispatchInfo[iter_183_0].hp = iter_183_1.hp
					var_182_4.dispatchInfo[iter_183_0].mp = iter_183_1.mp
				end
			end

			var_182_4:handleResponse(arg_183_1)

			if not arg_182_1 then
				arg_182_0:runActionOnce(cc.CallFunc:create(function()
					arg_182_0:finishBattle()
				end), false, nil, 2)
			end
		else
			local var_183_0 = var_0_2:translation("NETWORK_ERROR")

			var_0_12.WindowManager.get():openWindow("toast", {
				delay = 600,
				message = var_183_0
			})
			arg_182_0:finishBattle()
		end
	end)
end

function var_0_0.tutorFightResult(arg_185_0, arg_185_1)
	if arg_185_1 then
		return
	end

	local var_185_0 = {
		campaign_id = arg_185_0.campaignID,
		star = arg_185_1 and 0 or arg_185_0:getBattleStar(),
		alive_num = arg_185_0:getAliveCount(var_0_13.ctx.battle.teamA),
		hero_ids = var_0_12.splitToNumber(arg_185_0:getOriginFormationStr(arg_185_0.herosA), "|"),
		hero_stars = var_0_12.splitToNumber(arg_185_0:getHeroStarStr(arg_185_0.herosA), "|")
	}

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.TUTOR):tutorEndCampaign(var_185_0, function(arg_186_0, arg_186_1)
		if arg_186_0 == var_0_12.error.OK then
			if arg_186_1 and arg_186_1.items and next(arg_186_1.items) and not arg_185_0.isReplay then
				for iter_186_0, iter_186_1 in ipairs(arg_186_1.items) do
					for iter_186_2 = 1, iter_186_1.item_num do
						local var_186_0 = var_0_8.new()

						var_186_0:populate({
							table_id = iter_186_1.item_id
						})
						table.insert(arg_185_0.dropItems, var_186_0)
					end
				end
			end

			local var_186_1 = {}

			if arg_186_1 and arg_186_1.awards and next(arg_186_1.awards) then
				var_186_1.tutorCoin = arg_186_1.awards[1].tutor_coin
			end

			arg_185_0:finishBattle(var_186_1)
		else
			local var_186_2 = var_0_2:translation("NETWORK_ERROR")

			var_0_12.WindowManager.get():openWindow("toast", {
				delay = 600,
				message = var_186_2
			})
			arg_185_0:finishBattle()
		end
	end)
end

function var_0_0.dreamWorldFightResult(arg_187_0, arg_187_1)
	if arg_187_1 then
		return
	end

	local var_187_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.DREAM_WORLD)
	local var_187_1

	if #arg_187_0.petsA ~= 0 then
		var_187_1 = arg_187_0.petsA[1]:getTableID()
	end

	local var_187_2
	local var_187_3

	var_187_3 = arg_187_0:getBattleStar() > 0 and 1 or 0

	local var_187_4 = var_187_0:getMapInfo()

	var_187_4.extra_data = {
		star = arg_187_0:getBattleStar(),
		pet_id = var_187_1,
		formation = var_0_12.splitToNumber(arg_187_0:getOriginFormationStr(arg_187_0.herosA), "|")
	}

	var_187_0:dealEvent(var_187_4, function(arg_188_0, arg_188_1)
		if arg_188_0 == var_0_12.error.OK then
			arg_187_0:finishBattle()

			if arg_188_1.awards then
				arg_187_0.selfPlayer:handleRewards(arg_188_1.awards)
			end
		else
			arg_187_0:finishBattle()
		end
	end)
end

function var_0_0.getOriginFormationStr(arg_189_0, arg_189_1)
	local var_189_0 = ""

	for iter_189_0, iter_189_1 in ipairs(arg_189_1) do
		var_189_0 = var_189_0 .. string.format("%d", iter_189_1:getFirstTableID())

		if iter_189_0 < #arg_189_1 then
			var_189_0 = var_189_0 .. "|"
		end
	end

	return var_189_0
end

function var_0_0.getHeroStarStr(arg_190_0, arg_190_1)
	local var_190_0 = ""

	for iter_190_0, iter_190_1 in ipairs(arg_190_1) do
		var_190_0 = var_190_0 .. string.format("%d", iter_190_1:getStar())

		if iter_190_0 < #arg_190_1 then
			var_190_0 = var_190_0 .. "|"
		end
	end

	return var_190_0
end

function var_0_0.chocolateFightResult(arg_191_0, arg_191_1)
	local var_191_0 = var_0_12.splitToNumber(arg_191_0.formation, "|")
	local var_191_1 = 0

	if arg_191_0.petsA and arg_191_0.petsA[1] then
		var_191_1 = tonumber(arg_191_0.petsA[1].petID_)
	end

	local var_191_2 = {
		campaign_id = arg_191_0.campaignID,
		star = arg_191_1 and 0 or arg_191_0:getBattleStar(),
		partner_ids = var_191_0,
		pet_id = var_191_1
	}

	for iter_191_0, iter_191_1 in ipairs(var_191_0) do
		local var_191_3 = arg_191_0.selfPlayer:getHero(iter_191_1)

		if var_191_3 and var_191_3.reinforceRatio then
			var_191_3.reinforceRatio = nil
			var_191_3.totalAttrs_ = nil
			var_191_3.isDouble = true
		end
	end

	local var_191_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.CHOCOLATE)

	var_191_4.mapNeedReload = false
	var_191_4.battleResult = var_191_2

	var_0_12.Backend.get():request(var_0_12.mid.CHOCOLATE_FIGHT_RESULT, var_191_2, function(arg_192_0, arg_192_1)
		if not arg_191_1 and arg_192_0 == var_0_12.error.OK then
			if arg_192_1 and arg_192_1.items and next(arg_192_1.items) and not arg_191_0.isReplay then
				for iter_192_0, iter_192_1 in ipairs(arg_192_1.items) do
					for iter_192_2 = 1, iter_192_1.item_num do
						local var_192_0 = var_0_8.new()

						var_192_0:populate({
							table_id = iter_192_1.item_id
						})
						table.insert(arg_191_0.dropItems, var_192_0)
					end
				end
			end

			arg_191_0:finishBattle()
		end
	end, nil, false, true)
end

function var_0_0.fourthAnniMapFightResult(arg_193_0, arg_193_1)
	local var_193_0 = var_0_12.splitToNumber(arg_193_0.formation, "|")
	local var_193_1 = 0

	if arg_193_0.petsA and arg_193_0.petsA[1] then
		var_193_1 = tonumber(arg_193_0.petsA[1].petID_)
	end

	local var_193_2 = {
		campaign_id = arg_193_0.campaignID,
		star = arg_193_1 and 0 or arg_193_0:getBattleStar(),
		formation = var_193_0,
		pet_id = var_193_1
	}

	arg_193_0.fourthAnniversary = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.FOURTH_ANNIVERSARY)

	if not arg_193_1 then
		arg_193_0.fourthAnniversary.onBattleEnd = true
	else
		arg_193_0.fourthAnniversary.onBattleEnd = false
	end

	for iter_193_0, iter_193_1 in ipairs(var_193_0) do
		local var_193_3 = arg_193_0.selfPlayer:getHero(iter_193_1)

		if var_193_3 and var_193_3.reinforceRatio then
			var_193_3.reinforceRatio = nil
			var_193_3.totalAttrs_ = nil
			var_193_3.isDouble = true
		end
	end

	local var_193_4 = arg_193_0.selfPlayer.exp

	var_0_12.Backend.get():request(var_0_12.mid.FOURTH_ANNI_MAP_BATTLE, var_193_2, function(arg_194_0, arg_194_1)
		if not arg_193_1 and arg_194_0 == var_0_12.error.OK then
			local var_194_0 = {}

			if arg_194_1.economy_ and arg_194_1.economy_.exp then
				var_194_0.collegeExp = arg_194_1.economy_.exp - var_193_4
			else
				var_194_0.collegeExp = 0
			end

			if arg_194_1 and arg_194_1.awards and next(arg_194_1.awards) and not arg_193_0.isReplay then
				for iter_194_0, iter_194_1 in ipairs(arg_194_1.awards) do
					if iter_194_1.table_id == -1 then
						if iter_194_1.type == "mana" then
							var_194_0.coin_award = iter_194_1.item_num
						elseif iter_194_1.type == "exp" then
							var_194_0.exps = {}

							for iter_194_2, iter_194_3 in ipairs(var_193_0) do
								local var_194_1 = arg_193_0.selfPlayer:getHero(iter_194_3)
								local var_194_2 = {
									partner_id = iter_194_3,
									exp = var_194_1.exp_ + iter_194_1.item_num
								}

								table.insert(var_194_0.exps, var_194_2)
							end
						end
					else
						for iter_194_4 = 1, iter_194_1.item_num do
							local var_194_3 = var_0_8.new()

							var_194_3:populate({
								table_id = iter_194_1.table_id
							})
							table.insert(arg_193_0.dropItems, var_194_3)
						end
					end
				end
			end

			arg_193_0:finishBattle(var_194_0)
		end
	end, nil, false, true)
end

function var_0_0.ragnarokMapFightResult(arg_195_0, arg_195_1)
	local var_195_0 = var_0_12.splitToNumber(arg_195_0.formation, "|")
	local var_195_1 = 0

	if arg_195_0.petsA and arg_195_0.petsA[1] then
		var_195_1 = tonumber(arg_195_0.petsA[1].petID_)
	end

	local var_195_2 = {
		campaign_id = arg_195_0.campaignID,
		star = arg_195_1 and 0 or arg_195_0:getBattleStar(),
		partner_ids = var_195_0,
		pet_id = var_195_1
	}

	for iter_195_0, iter_195_1 in ipairs(var_195_0) do
		local var_195_3 = arg_195_0.selfPlayer:getHero(iter_195_1)

		if var_195_3 and var_195_3.reinforceRatio then
			var_195_3.reinforceRatio = nil
			var_195_3.totalAttrs_ = nil
			var_195_3.isDouble = true
		end
	end

	local var_195_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.RAGNAROK)

	if not arg_195_1 then
		var_195_4.onBattleEnd = true
		var_195_4.battleEndId = arg_195_0.campaignID
	else
		var_195_4.onBattleEnd = false
		var_195_4.battleEndId = arg_195_0.campaignID
	end

	var_195_4.battleResult = var_195_2

	var_0_12.Backend.get():request(var_0_12.mid.RAGNAROK_FIGHT_RESULT, var_195_2, function(arg_196_0, arg_196_1)
		if not arg_195_1 and arg_196_0 == var_0_12.error.OK then
			if arg_196_1 and arg_196_1.items and next(arg_196_1.items) and not arg_195_0.isReplay then
				for iter_196_0, iter_196_1 in ipairs(arg_196_1.items) do
					for iter_196_2 = 1, iter_196_1.item_num do
						local var_196_0 = var_0_8.new()

						var_196_0:populate({
							table_id = iter_196_1.item_id
						})
						table.insert(arg_195_0.dropItems, var_196_0)
					end
				end
			end

			arg_195_0:finishBattle()
		end
	end, nil, false, true)
end

function var_0_0.allNightMapFightResult(arg_197_0, arg_197_1)
	local var_197_0 = var_0_12.splitToNumber(arg_197_0.formation, "|")
	local var_197_1 = 0

	if arg_197_0.petsA and arg_197_0.petsA[1] then
		var_197_1 = tonumber(arg_197_0.petsA[1].petID_)
	end

	local var_197_2 = {
		campaign_id = arg_197_0.campaignID,
		star = arg_197_1 and 0 or arg_197_0:getBattleStar(),
		partner_ids = var_197_0,
		pet_id = var_197_1
	}

	for iter_197_0, iter_197_1 in ipairs(var_197_0) do
		local var_197_3 = arg_197_0.selfPlayer:getHero(iter_197_1)

		if var_197_3 and var_197_3.reinforceRatio then
			var_197_3.reinforceRatio = nil
			var_197_3.totalAttrs_ = nil
			var_197_3.isDouble = true
		end
	end

	local var_197_4 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ALL_NIGHT)

	if not arg_197_1 then
		var_197_4.onBattleEnd = true
		var_197_4.battleEndId = arg_197_0.campaignID
	else
		var_197_4.onBattleEnd = false
		var_197_4.battleEndId = arg_197_0.campaignID
	end

	var_197_4.battleResult = var_197_2

	var_0_12.Backend.get():request(var_0_12.mid.POLAR_NIGHT_FIGHT_RESULT, var_197_2, function(arg_198_0, arg_198_1)
		if not arg_197_1 and arg_198_0 == var_0_12.error.OK then
			if arg_198_1 and arg_198_1.items and next(arg_198_1.items) and not arg_197_0.isReplay then
				for iter_198_0, iter_198_1 in ipairs(arg_198_1.items) do
					for iter_198_2 = 1, iter_198_1.item_num do
						local var_198_0 = var_0_8.new()

						var_198_0:populate({
							table_id = iter_198_1.item_id
						})
						table.insert(arg_197_0.dropItems, var_198_0)
					end
				end
			end

			arg_197_0:finishBattle()
		end
	end, nil, false, true)
end

function var_0_0.superRichChallengeResult(arg_199_0, arg_199_1)
	if arg_199_1 then
		return
	end

	local var_199_0 = arg_199_0:getBattleStar() > 0
	local var_199_1 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SUPER_RICH)
	local var_199_2 = {}

	if var_199_0 then
		var_199_1:monopolyFightWin(var_199_2, function(arg_200_0, arg_200_1)
			if arg_200_0 == var_0_12.error.OK then
				arg_199_0:finishBattle()
			end
		end)
	else
		arg_199_0:finishBattle()
	end
end

function var_0_0.zhugeEnemyResult(arg_201_0, arg_201_1)
	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		arg_201_0:runActionOnce(cc.CallFunc:create(function()
			arg_201_0:finishBattle({}, {})
		end), false, nil, 2)

		return
	end
end

function var_0_0.conquerSchoolResult(arg_203_0, arg_203_1)
	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		arg_203_0:runActionOnce(cc.CallFunc:create(function()
			arg_203_0:finishBattle({}, {})
		end), false, nil, 2)

		return
	end

	local var_203_0 = arg_203_0:getTotalHarms(var_0_13.ctx.battle.teamA)
	local var_203_1 = arg_203_0:getBattleStar() > 0

	arg_203_0:writeReport()

	local var_203_2 = var_0_6.encode(arg_203_0.report_)
	local var_203_3 = arg_203_0:getAliveCount(var_0_13.ctx.battle.teamA)
	local var_203_4

	if arg_203_0.petsA and arg_203_0.petsA[1] then
		var_203_4 = arg_203_0.petsA[1].petID_
	end

	local var_203_5 = {
		campaign_id = arg_203_0.campaignID,
		team_id = arg_203_0.conquerSchoolTeamID,
		is_win = var_203_1,
		formation = arg_203_0.formation,
		pet_id = var_203_4,
		report = var_203_2,
		report_invalid = arg_203_0:checkBattleReport(),
		total_damage = var_203_0,
		alive_num = var_203_3
	}

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.CONQUER_SCHOOL):fightResult(var_203_5, function(arg_205_0, arg_205_1)
		if arg_205_0 == var_0_12.error.OK then
			arg_203_0:runActionOnce(cc.CallFunc:create(function()
				arg_203_0:finishBattle(arg_205_1, {})
			end), false, nil, 2)
		end
	end)
end

function var_0_0.zhugeBossResult(arg_207_0, arg_207_1)
	local var_207_0 = 0

	for iter_207_0, iter_207_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_207_0 = var_207_0 + iter_207_1.harms
	end

	local var_207_1 = 0

	for iter_207_2, iter_207_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_207_3:isBoss() then
			var_207_1 = var_0_17(iter_207_3:getHpLimit() - iter_207_3:getHp())

			break
		end
	end

	var_207_0 = var_207_1 > 1 and var_207_1 or var_0_17(var_207_0)

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ZHUGE_FESTIVAL):fightBoss({
		damage = var_207_0
	}, function(arg_208_0, arg_208_1)
		if arg_208_0 == var_0_12.error.OK then
			arg_207_0:runActionOnce(cc.CallFunc:create(function()
				local var_209_0 = {
					damage = math.floor(var_207_0)
				}

				arg_207_0:finishZhugeBossBattle(var_209_0, {})
			end), false, nil, 2)
		end
	end)
end

function var_0_0.finishZhugeBossBattle(arg_210_0, arg_210_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
	arg_210_0:clearFormation(true)

	local var_210_0 = arg_210_1

	var_0_12.WindowManager.get():openWindow("zhuge_damage_wnd", var_210_0, function(arg_211_0)
		if arg_211_0 == nil then
			return
		end

		arg_210_0.battleEndWindow_ = arg_211_0

		cc.EventProxy.new(arg_210_0.battleEndWindow_, arg_210_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_212_0)
			arg_210_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.thiefBossResult(arg_214_0, arg_214_1)
	local var_214_0 = 0

	for iter_214_0, iter_214_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_214_0 = var_214_0 + iter_214_1.harms
	end

	local var_214_1 = 0

	for iter_214_2, iter_214_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_214_3:isBoss() then
			var_214_1 = var_0_17(iter_214_3:getHpLimit() - iter_214_3:getHp())

			break
		end
	end

	local var_214_2 = {
		campaign_id = arg_214_0.campaignID,
		total_damage = var_214_1 > 1 and var_214_1 or var_0_17(var_214_0),
		campaign_type = arg_214_0.campaignType,
		formation = arg_214_0.fightParams.formation
	}

	if arg_214_0.fightParams.rent_formation then
		var_214_2.rent_formation = arg_214_0.fightParams.rent_formation
		var_214_2.rent_player_id = arg_214_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.NIAN_BOSS_FIGHT_RESULT, var_214_2, function(arg_215_0, arg_215_1)
		if (arg_215_0 == var_0_12.error.OK or tonumber(arg_215_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist) and not arg_214_1 then
			arg_214_0:runActionOnce(cc.CallFunc:create(function()
				arg_214_0:finishThiefBoss(arg_215_1)
			end), false, nil, 2)
		end
	end, nil, nil, true)
end

function var_0_0.challengeResult(arg_217_0, arg_217_1)
	local function var_217_0(arg_218_0, arg_218_1)
		if arg_218_0 > 0 then
			arg_217_0:runActionOnce(cc.CallFunc:create(function()
				arg_217_0:finishBattle(arg_218_1)
			end), false, nil, arg_218_0)
		else
			arg_217_0:finishBattle(arg_218_1)
		end
	end

	local var_217_1 = {
		campaign_id = arg_217_0.campaignID,
		star = arg_217_0:getBattleStar(),
		campaign_type = arg_217_0.campaignType,
		formation = arg_217_0.formation
	}
	local var_217_2 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SELF_PLAYER)

	var_0_12.Backend.get():request(var_0_12.mid.FIGHT_RESULT, var_217_1, function(arg_220_0, arg_220_1)
		if arg_220_0 == var_0_12.error.OK or tonumber(arg_220_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			local var_220_0 = arg_220_1.chapter_info

			if var_220_0 ~= nil then
				var_217_2.normal_chapter_id = var_220_0.normal_chapter_id
				var_217_2.normal_campaign_id = var_220_0.normal_campaign_id
				var_217_2.super_chapter_id = var_220_0.super_chapter_id
				var_217_2.super_campaign_id = var_220_0.super_campaign_id
				var_217_2.super_stars = var_220_0.super_stars
				var_217_2.normal_stars = var_220_0.normal_stars
			end

			if arg_220_1.campaigns ~= nil then
				for iter_220_0, iter_220_1 in pairs(arg_220_1.campaigns) do
					local var_220_1 = tonumber(iter_220_1.campaign_id)

					if var_220_1 then
						var_217_2.worldMaps_[var_220_1] = {}
						var_217_2.worldMaps_[var_220_1].star = tonumber(iter_220_1.star)
						var_217_2.worldMaps_[var_220_1].dailyLimit = tonumber(iter_220_1.daily_limit)
						var_217_2.worldMaps_[var_220_1].resetCount = tonumber(iter_220_1.reset_count)
					end
				end
			end

			if arg_220_1.trial ~= nil then
				local var_220_2 = arg_220_1.trial
				local var_220_3 = tonumber(var_220_2.id)

				if var_220_3 then
					var_217_2.challengeInfos_[var_220_3] = {}
					var_217_2.challengeInfos_[var_220_3].id = tonumber(var_220_2.id)
					var_217_2.challengeInfos_[var_220_3].leftTimes = tonumber(var_220_2.left_times)
					var_217_2.challengeInfos_[var_220_3].isOpen = tonumber(var_220_2.is_open)
					var_217_2.challengeInfos_[var_220_3].maxTimes = tonumber(var_220_2.max_times)
					var_217_2.challengeInfos_[var_220_3].lastID = tonumber(var_220_2.last_id)
				end
			end

			if arg_220_1 and arg_220_1.items and next(arg_220_1.items) and not arg_217_0.isReplay then
				local var_220_4 = {}

				for iter_220_2, iter_220_3 in ipairs(arg_220_1.items) do
					for iter_220_4 = 1, iter_220_3.item_num do
						local var_220_5 = var_0_8.new()

						var_220_5:populate({
							table_id = iter_220_3.item_id
						})
						table.insert(var_220_4, var_220_5)
					end

					arg_217_0.selfPlayer:getBackpack():addItemsByID(iter_220_3.item_id, iter_220_3.item_num)
				end

				local var_220_6 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT1")
				local var_220_7 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT2")
				local var_220_8 = var_0_2:translation("BATTLE_AWARD_ITEMS_TEXT3")
				local var_220_9 = {
					var_220_6,
					var_220_7,
					var_220_8
				}
				local var_220_10 = var_0_12.WindowManager.get():openWindow("battle_award_items", {
					items = var_220_4,
					labels = var_220_9
				})

				cc.EventProxy.new(var_220_10, var_220_10):addEventListener(var_0_12.event.ALERT_AWARD_CLOSE, function()
					var_217_0(1, arg_220_1)
				end)
			elseif not arg_217_1 then
				var_217_0(2, arg_220_1)
			end
		end
	end, nil, nil, true)
end

function var_0_0.sakura2CompetitorResult(arg_222_0, arg_222_1)
	local var_222_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SAKURA)

	var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ACTIVITIES):getActivityReward2(var_0_12.Activities.Sakura, 2, arg_222_0:getBattleStar(), function(arg_223_0, arg_223_1)
		if arg_223_0 == var_0_12.error.OK then
			var_222_0.details.event_type = arg_223_1.event_type
			var_222_0.awards = arg_223_1.awards

			arg_222_0:finishBattle()
		end
	end)
end

function var_0_0.sakura2WarResult(arg_224_0, arg_224_1)
	local var_224_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SAKURA)

	if arg_224_0.campaignID ~= var_224_0.details.now_campaign_id then
		arg_224_0:finishBattle()

		return
	end

	local var_224_1

	if #arg_224_0.petsA ~= 0 then
		var_224_1 = arg_224_0.petsA[1].petID_
	end

	local var_224_2 = {
		campaign_id = arg_224_0.campaignID,
		star = arg_224_0:getBattleStar(),
		campaign_type = arg_224_0.campaignType,
		formation = arg_224_0.formation,
		pet_id = var_224_1
	}

	var_224_0:fightResult(var_224_2, function(arg_225_0, arg_225_1)
		if arg_225_0 == var_0_12.error.OK then
			var_224_0.battleAwards = arg_225_1.awards
			var_224_0.campaignID = arg_224_0.campaignID

			if arg_224_0:getBattleStar() > 0 then
				var_224_0.details.now_campaign_id = arg_225_1.now_campaign_id
				var_224_0.details.passed_campaign_id = arg_225_1.passed_campaign_id
			end

			arg_224_0:finishBattle()
		end
	end)
end

function var_0_0.summerFightBossResult(arg_226_0)
	arg_226_0.allParams = nil

	arg_226_0:finishBattle()
end

function var_0_0.chapterBossResult(arg_227_0, arg_227_1)
	if arg_227_1 then
		return
	end

	local var_227_0 = 0

	for iter_227_0, iter_227_1 in ipairs(var_0_13.ctx.battle.teamA) do
		var_227_0 = var_227_0 + iter_227_1.harms
	end

	local var_227_1

	if #arg_227_0.petsA ~= 0 then
		var_227_1 = arg_227_0.petsA[1].petID_
	end

	local var_227_2 = {
		formation = arg_227_0.formation,
		pet_id = var_227_1,
		total_damage = var_227_0,
		chapter_id = arg_227_0.chapterId
	}

	if arg_227_0.fightParams.rent_pet_id then
		var_227_2.rent_pet_id = arg_227_0.fightParams.rent_pet_id
		var_227_2.rent_pet_player_id = arg_227_0.fightParams.rent_pet_player_id
	end

	if arg_227_0.fightParams.rent_formation then
		var_227_2.rent_formation = arg_227_0.fightParams.rent_formation
		var_227_2.rent_player_id = arg_227_0.fightParams.rent_player_id
	end

	var_0_12.Backend.get():request(var_0_12.mid.FIGHT_CHAPTER_BOSS, var_227_2, function(arg_228_0, arg_228_1)
		if arg_228_0 == var_0_12.error.OK or tonumber(arg_228_1.error_code or 0) == var_0_13.ctx.battleConst.errorIdFightExist then
			if not arg_227_1 then
				arg_227_0:runActionOnce(cc.CallFunc:create(function()
					arg_227_0:finishBattle(arg_228_1)
				end), false, nil, 2)
			end

			var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.SELF_PLAYER):handleChapterEvent(arg_228_1)
		else
			arg_227_0:finishBattle()
		end
	end, nil, nil, true)
end

function var_0_0.memoriesOfSchoolResult(arg_230_0, arg_230_1)
	local var_230_0 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.MEMORIES_OF_SCHOOL)
	local var_230_1

	if #arg_230_0.petsA ~= 0 then
		var_230_1 = arg_230_0.petsA[1].petID_
	end

	local var_230_2
	local var_230_3 = arg_230_0:getBattleStar() > 0 and 1 or 0
	local var_230_4 = {
		formation = arg_230_0.formation,
		pet_id = var_230_1,
		is_win = var_230_3,
		grid_pos = var_230_0:getBattleGrid(),
		heroes_status = {}
	}

	for iter_230_0, iter_230_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_230_1:getSummonType() == var_0_12.summonMonsterType.None then
			local var_230_5 = {
				hero_id = iter_230_1.hero_:getHeroID(),
				hp = iter_230_1:getHp(),
				mp = iter_230_1:getEnergy(),
				is_reborn = iter_230_1:hasReborned() and 1 or 0
			}

			var_230_4.heroes_status[tostring(iter_230_1.hero_:getHeroID())] = var_230_5
		end
	end

	var_230_4.enemies_status = {}

	for iter_230_2, iter_230_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_230_3:getSummonType() == var_0_12.summonMonsterType.None then
			local var_230_6 = {
				hero_id = iter_230_3.hero_:getHeroID(),
				hp = iter_230_3:getHp(),
				mp = iter_230_3:getEnergy(),
				is_reborn = iter_230_3:hasReborned() and 1 or 0
			}

			var_230_4.enemies_status[tostring(iter_230_3.hero_:getTableID())] = var_230_6
		end
	end

	var_230_4.round = arg_230_0.group_

	if var_0_13.ctx.battle.walk2NextBattle_ then
		var_230_4.round = arg_230_0.group_ + 1
	end

	if not arg_230_0.pvp or arg_230_0.pvp ~= 1 then
		var_230_0:fightMonster(var_230_4, function(arg_231_0, arg_231_1)
			if arg_231_0 == var_0_12.error.OK then
				arg_230_0:finishBattle()

				if arg_231_1.awards then
					arg_230_0.selfPlayer:handleRewards(arg_231_1.awards)
				end
			else
				arg_230_0:finishBattle()
			end
		end)
	else
		arg_230_0:finishBattle()

		if arg_230_0.memories_awards then
			arg_230_0.selfPlayer:handleRewards(arg_230_0.memories_awards)

			arg_230_0.memories_awards = nil
			arg_230_0.allParams.memories_awards = nil
		end
	end
end

function var_0_0.twoYearsResult(arg_232_0, arg_232_1)
	arg_232_0:finishBattle()

	if arg_232_0.twoYearsAwards then
		arg_232_0.selfPlayer:handleRewards(arg_232_0.twoYearsAwards)

		arg_232_0.twoYearsAwards = nil
		arg_232_0.allParams.twoYearsAwards = nil
	end
end

function var_0_0.sendBattleResult(arg_233_0, arg_233_1)
	local function var_233_0(arg_234_0)
		if not arg_234_0 then
			return
		end

		var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
		var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd, function()
			cc.Director:getInstance():popToRootScene()
		end)
	end

	if arg_233_0.campaignType == var_0_12.CampaignType.SUPER_ARENA then
		arg_233_0:superArenaResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ARENA or arg_233_0.campaignType == var_0_12.CampaignType.ARENA_MODE then
		arg_233_0:arenaResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.LVBU_FESTIVAL then
		arg_233_0:arenaResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
		arg_233_0:arenaResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.REGION_ARENA then
		arg_233_0:regionArenaResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.MARCH then
		arg_233_0:marchResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.TREASURE then
		arg_233_0:treasureResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.GUILD then
		arg_233_0:guildResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ELEMENT then
		arg_233_0:elementResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.NIAN_BOSS then
		arg_233_0:nianBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.THIEF_BOSS then
		arg_233_0:thiefBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SAKURA_CAMPAIGN then
		arg_233_0:sakuraResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.PET then
		arg_233_0:petResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.CHALLENGE then
		arg_233_0:campaignResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_233_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD then
		arg_233_0:playoffsResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT then
		arg_233_0:friendResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.REGION_CASUAL then
		arg_233_0:RegionCasualResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ILLUSION then
		arg_233_0:illusionResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SINGLE_DAY then
		arg_233_0:singleDayResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.CONQUER_SCHOOL then
		arg_233_0:conquerSchoolResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SAKURA2_COMPETITOR then
		arg_233_0:sakura2CompetitorResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SAKURA2_WAR then
		arg_233_0:sakura2WarResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.STUDENT_OVER then
		arg_233_0:studentOverResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ZHUGE_NOTE then
		arg_233_0:zhugeNoteResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ZHUGE_ENEMY then
		arg_233_0:zhugeEnemyResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ZHUGE_BOSS then
		arg_233_0:zhugeBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.MEMORIES_OF_SCHOOL then
		arg_233_0:memoriesOfSchoolResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ILLUSION_COOPERATION then
		arg_233_0:illusionCooperationResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SUMMER_FIGHT_BOSS then
		arg_233_0:summerFightBossResult()
	elseif arg_233_0.campaignType == var_0_12.CampaignType.OCCULT then
		arg_233_0:occultResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.OCCULT_COOPERATION then
		arg_233_0:finishBattle()
	elseif arg_233_0.campaignType == var_0_12.CampaignType.TWO_YEARS then
		arg_233_0:twoYearsResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ADVENTURE_ILLUSION_SINGLE then
		arg_233_0:adventureIllusionSingleResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ADVENTURE_ILLUSION_COOPERATION then
		arg_233_0:adventureIllusionCooperationResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ADVENTURE_DEFENSE then
		arg_233_0:adventureDefenseResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.WAR_CAMP then
		arg_233_0:warCampResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.WAR_CAMP_ENEMY then
		arg_233_0:warCampEnemyResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.CHAPTER_BOSS then
		arg_233_0:chapterBossResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.THIRD_ANNIVERSARY_BOSS then
		arg_233_0:thirdAnniversaryBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.SUPER_RICH_CHALLENGE then
		arg_233_0:superRichChallengeResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.CHOCOLATE then
		arg_233_0:chocolateFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.TUTOR then
		arg_233_0:tutorFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.DREAM_WORLD then
		arg_233_0:dreamWorldFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.FOURTH_ANNI_MAP then
		arg_233_0:fourthAnniMapFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ALL_NIGHT_MAP then
		arg_233_0:allNightMapFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.ALL_NIGHT_BOSS then
		arg_233_0:allNightBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.RAGNAROK_MAP then
		arg_233_0:ragnarokMapFightResult(arg_233_1)
		var_233_0(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.RAGNAROK then
		arg_233_0:ragnarokResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.FIFTH_ANNIVERSARY_BOSS then
		arg_233_0:fifthAnniBossResult(arg_233_1)
	elseif arg_233_0.campaignType == var_0_12.CampaignType.HUNQI then
		arg_233_0:hunqiResult(arg_233_1)
	else
		arg_233_0:campaignResult(arg_233_1)
		var_233_0(arg_233_1)
	end
end

function var_0_0.sendStoryOperationLog(arg_236_0, arg_236_1)
	local var_236_0 = var_0_12.StoryData.get():getGuideID()

	if arg_236_1 == 1 then
		if var_236_0 == var_0_12.GuideStoryType.GUIDE_CAMPAIGN_RESULT then
			arg_236_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_DIALOG10)
		elseif var_236_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_3_END then
			arg_236_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_3_4)
		end
	elseif var_236_0 < var_0_12.GuideStoryType.GUIDE_CAMPAIGN_END then
		arg_236_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_DIALOG11)
	elseif var_236_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_3_END then
		arg_236_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_3_5)
	end
end

function var_0_0.playStory(arg_237_0)
	local var_237_0 = arg_237_0:getBattleStar()

	if var_237_0 <= 0 and arg_237_0.stories[2] and arg_237_0.stories[2] > 0 then
		local var_237_1 = var_0_12.WindowManager.get():openWindow("story", {
			story_state = 2,
			story_id = arg_237_0.stories[2],
			battle_id = arg_237_0.battleID,
			is_assist = arg_237_0.isAssist
		})

		cc.EventProxy.new(var_237_1, var_237_1):addEventListener(var_0_12.event.STORY_COMPLETE, function(arg_238_0)
			if arg_238_0.state >= 2 then
				arg_237_0:sendStoryOperationLog(2)
				arg_237_0:sendBattleResult()
			end
		end)
	elseif var_237_0 > 0 and arg_237_0.stories[3] and arg_237_0.stories[3] > 0 then
		local var_237_2 = var_0_12.WindowManager.get():openWindow("story", {
			story_state = 3,
			story_id = arg_237_0.stories[3],
			battle_id = arg_237_0.battleID,
			is_assist = arg_237_0.isAssist
		})

		cc.EventProxy.new(var_237_2, var_237_2):addEventListener(var_0_12.event.STORY_COMPLETE, function(arg_239_0)
			if arg_239_0.state >= 2 then
				arg_237_0:sendStoryOperationLog(3)
				arg_237_0:sendBattleResult()
			end
		end)
	elseif var_237_0 > 0 and arg_237_0.isPartnerdrop then
		local var_237_3 = var_0_3:specialVictory(arg_237_0.battleID)[1]
		local var_237_4 = var_0_12.WindowManager.get():openWindow("battle_special_story", {
			story_state = 3,
			story_id = var_237_3,
			campaign_id = arg_237_0.campaignID,
			campaign_type = arg_237_0.campaignType
		})

		cc.EventProxy.new(var_237_4, var_237_4):addEventListener(var_0_12.event.STORY_COMPLETE, function(arg_240_0)
			if arg_240_0.state == 3 then
				arg_237_0:sendStoryOperationLog(3)
				arg_237_0:sendBattleResult()
			end
		end)
	else
		arg_237_0:sendBattleResult()
	end
end

function var_0_0.showOnlyDialogGuide(arg_241_0, arg_241_1)
	if var_0_12.WindowManager.get():isWindowOpen("guide_only_dialog") then
		var_0_12.WindowManager.get():closeWindow("guide")
	end

	local var_241_0 = var_0_12.StoryData.get():getGuideID()
	local var_241_1 = {}

	if arg_241_1 then
		var_241_1.callback = arg_241_1
	else
		function var_241_1.callback()
			arg_241_0:playGuide()
		end
	end

	if var_241_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_2_FOUR then
		var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_FIGHT_2_FIVE)
		arg_241_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_2_4)
	elseif var_241_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_2_FIVE then
		var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_FIGHT_2_SIX)
		arg_241_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_2_5)
	end

	var_0_12.WindowManager.get():openWindow("guide_only_dialog", var_241_1)
end

function var_0_0.checkEscapeStory(arg_243_0)
	if not arg_243_0.escapeEnemyJudge then
		arg_243_0.escapeEnemyJudge = true

		local var_243_0 = var_0_3:escapeEnemy(arg_243_0.battleID)

		for iter_243_0, iter_243_1 in ipairs(var_0_13.ctx.battle.teamB) do
			if not iter_243_1:isDeath() and iter_243_1:getTableID() == var_243_0 then
				local var_243_1 = arg_243_0:newBuffs({
					40010721
				}, iter_243_1, iter_243_1, iter_243_1:getEnergySkillID())

				iter_243_1:addBuffs(var_243_1)
				iter_243_1:setMinHpValue(0.1)

				arg_243_0.escapeEnemy = iter_243_1

				break
			end
		end
	end

	if not arg_243_0.escapeEnemy or arg_243_0.escapeEnemy:isDeath() then
		return
	elseif arg_243_0.escapeEnemy:getHp() / arg_243_0.escapeEnemy:getHpLimit() > 0.5 then
		return
	end

	arg_243_0:playEscapeStory()
end

function var_0_0.newBuffs(arg_244_0, arg_244_1, arg_244_2, arg_244_3, arg_244_4)
	local var_244_0 = {}

	for iter_244_0, iter_244_1 in ipairs(arg_244_1) do
		local var_244_1 = var_0_9.new({
			tableID = iter_244_1,
			start = var_0_13.ctx.battle.count,
			level = arg_244_2:getSkillLevelByID(arg_244_4),
			skillID = arg_244_4,
			fighter = arg_244_2,
			target = arg_244_3
		})

		var_244_1:setIsHit(true)
		var_244_1:setDirection(arg_244_2:getFighterModel():getFlipX())
		table.insert(var_244_0, var_244_1)
	end

	return var_244_0
end

function var_0_0.playEscapeStory(arg_245_0)
	arg_245_0:pauseBattle()

	local var_245_0 = var_0_3:escapeStory(arg_245_0.battleID)
	local var_245_1 = var_0_12.WindowManager.get():openWindow("battle_special_story", {
		is_reopen = true,
		story_state = 1,
		story_id = var_245_0,
		campaign_id = arg_245_0.campaignID,
		campaign_type = arg_245_0.campaignType
	})

	cc.EventProxy.new(var_245_1, var_245_1):addEventListener(var_0_12.event.STORY_COMPLETE, function(arg_246_0)
		if arg_246_0.state == 1 then
			local var_246_0 = arg_245_0:newBuffs({
				40010720
			}, arg_245_0.escapeEnemy, arg_245_0.escapeEnemy, arg_245_0.escapeEnemy:getSkillLevelByColor(var_0_12.SKILL_INDEX.Energy))

			arg_245_0.escapeEnemy:addBuffs(var_246_0)

			arg_245_0.isEscapeEnemyMove = true
			arg_245_0.isEscapeStory = false

			arg_245_0:startBattle()
		end
	end)
end

function var_0_0.playEscapeMove(arg_247_0)
	if not arg_247_0.escapeEnemy or arg_247_0.escapeEnemy:isDeath() then
		return
	end

	local var_247_0 = arg_247_0.escapeEnemy:getX()

	if var_247_0 >= var_0_12.STAGE_WIDTH + 100 then
		arg_247_0.isEscapeEnemyMove = false

		arg_247_0.escapeEnemy:removeBuffByID(40010721)
		arg_247_0.escapeEnemy:setMinHpValue(0, true)
		arg_247_0.escapeEnemy:updateHp(0)
		arg_247_0.escapeEnemy:die()

		return
	end

	if not arg_247_0.isEscapeEnemyMoveJudge then
		arg_247_0.isEscapeEnemyMoveJudge = true

		arg_247_0.escapeEnemy:flipX(false)

		if not arg_247_0.escapeEnemy:isWalkAnimation() then
			arg_247_0.escapeEnemy:modelWalk()
		end

		arg_247_0.escapeEnemy:setEscapeEnemyMove(true)

		local var_247_1 = "skeletons/ui_effect/library/expression/bq_liuhan"
		local var_247_2 = var_247_1 .. ".json"
		local var_247_3 = var_247_1 .. ".atlas"

		arg_247_0.liuhanEffect = var_0_11.new(var_247_2, var_247_3, 1)

		arg_247_0.liuhanEffect:setScaleX(-1)
		arg_247_0.liuhanEffect:setAnchorPoint(cc.p(0.5, 0.5))

		local var_247_4 = arg_247_0.escapeEnemy:getFighterModel():getContentSize()

		arg_247_0.liuhanEffect:setPosition(cc.p(-70, var_247_4.height + 35))
		arg_247_0.liuhanEffect:addTo(arg_247_0.escapeEnemy:getFighterModel(), 100)
		arg_247_0.liuhanEffect:play(function()
			arg_247_0.liuhanEffect:hide()
		end, false)
	end

	arg_247_0.escapeEnemy:x(var_247_0 + 10)
end

function var_0_0.stopAllFighter(arg_249_0, arg_249_1)
	for iter_249_0, iter_249_1 in pairs(var_0_13.ctx.battle.teamA) do
		if not iter_249_1:isDeath() and arg_249_1 ~= iter_249_1 then
			iter_249_1:getFighterModel():pause()
		end
	end

	for iter_249_2, iter_249_3 in pairs(var_0_13.ctx.battle.teamB) do
		if not iter_249_3:isDeath() and arg_249_1 ~= iter_249_3 then
			iter_249_3:getFighterModel():pause()
		end
	end
end

function var_0_0.playGuide(arg_250_0)
	if var_0_13.ctx.battle.battleType == var_0_12.BattleType.ReplayReport or var_0_13.ctx.battle.battleType == var_0_12.BattleType.CreateReport then
		return
	end

	if var_0_12.WindowManager.get():isWindowOpen("guide") then
		var_0_12.WindowManager.get():closeWindow("guide")
	end

	local var_250_0 = var_0_12.StoryData.get():getGuideID()

	if var_250_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_2_FOUR then
		if arg_250_0.group_ ~= 3 then
			return
		end

		arg_250_0.notClickAvatar = true

		if arg_250_0.guideTimeCount then
			if arg_250_0.guideTimeCount < 30 then
				arg_250_0.guideTimeCount = arg_250_0.guideTimeCount + 1
			else
				for iter_250_0, iter_250_1 in ipairs(var_0_13.ctx.battle.teamB) do
					if iter_250_1:isDeath() and iter_250_1:getTableID() == arg_250_0.guideMonsterID then
						arg_250_0.guideTimeCount = 1

						return
					end
				end

				arg_250_0.guideTimeCount = nil

				arg_250_0:pauseBattle()
				var_0_13.ctx.battle.stopAllFighter()
				arg_250_0:showOnlyDialogGuide()
			end

			return
		end

		for iter_250_2, iter_250_3 in ipairs(var_0_13.ctx.battle.teamB) do
			if iter_250_3:getTableID() == arg_250_0.guideMonsterID and iter_250_3.unitSkills_ and iter_250_3.unitSkills_.rootID_ == iter_250_3:getEnergySkillID() then
				arg_250_0.guideTimeCount = 1

				break
			end
		end
	elseif var_250_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_2_FIVE then
		if arg_250_0.group_ ~= 3 then
			return
		end

		arg_250_0:showOnlyDialogGuide()
	elseif var_250_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_2_SIX then
		if arg_250_0.group_ ~= 3 then
			return
		end

		arg_250_0.notClickAvatar = false

		local var_250_1 = 10001001
		local var_250_2 = 0

		for iter_250_4, iter_250_5 in ipairs(var_0_13.ctx.battle.teamA) do
			if iter_250_5:getSummonType() == var_0_12.summonMonsterType.None then
				var_250_2 = var_250_2 + 1

				if iter_250_5:getTableID() == var_250_1 then
					iter_250_5:updateEnergyTo(var_0_12.ENERGY_DECIMAL_BASE)

					local var_250_3 = arg_250_0.battleBottomWindow:getButtonByIndex(var_250_2)

					if var_250_3 == nil then
						return
					end

					local var_250_4 = var_250_3:getContentSize()
					local var_250_5 = var_250_3:getPositionX()
					local var_250_6 = var_250_3:getPositionY()

					var_0_12.WindowManager.get():openWindow("guide")

					local var_250_7 = var_0_12.WindowManager.get():getWindow("guide")
					local var_250_8 = var_250_7:convertToNodeSpace(var_250_3:getParent():convertToWorldSpace(cc.p(var_250_5, var_250_6)))

					var_250_7:addNode()
					var_250_7:setStencil(var_250_4.width, var_250_4.height, var_250_8.x, var_250_8.y, 1)
					var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_FIGHT_2_SEVEN)
					arg_250_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_2_6)

					break
				end
			end
		end
	elseif var_250_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_3_THREE then
		if arg_250_0.guideTimeCount then
			if arg_250_0.guideTimeCount < 90 then
				arg_250_0.guideTimeCount = arg_250_0.guideTimeCount + 1
			else
				arg_250_0.battleBottomWindow:getAutoBtn():setTouchEnabled(true)

				arg_250_0.guideTimeCount = nil

				arg_250_0:pauseBattle()
				var_0_13.ctx.battle.stopAllFighter()
				var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_FIGHT_3_FOUR)
				arg_250_0:playGuide()
			end

			return
		end

		arg_250_0.guideTimeCount = 1

		arg_250_0.battleBottomWindow:getAutoBtn():setTouchEnabled(false)
	elseif var_250_0 == var_0_12.GuideStoryType.GUIDE_FIGHT_3_FOUR then
		local var_250_9 = arg_250_0.battleBottomWindow:getAutoBtn()
		local var_250_10 = var_250_9:getPositionX()
		local var_250_11 = var_250_9:getPositionY()

		var_0_12.WindowManager.get():openWindow("guide")

		local var_250_12 = var_0_12.WindowManager.get():getWindow("guide")
		local var_250_13 = var_250_12:convertToNodeSpace(var_250_9:getParent():convertToWorldSpace(cc.p(var_250_10, var_250_11)))

		var_250_12:addNode()
		var_250_12:setStencil(var_250_9:getContentSize().width, var_250_9:getContentSize().height, var_250_13.x, var_250_13.y, 0, {
			position = {
				850,
				250
			}
		})
		var_0_12.StoryData.get():setGuideID(var_0_12.GuideStoryType.GUIDE_FIGHT_3_END)
		var_0_12.StoryData.get():persist()
		arg_250_0.selfPlayer:sendOperationLog(var_0_12.StatID.ID_FIGHT_3_3_1)
	end
end

function var_0_0.playHeroShow(arg_251_0)
	if arg_251_0.campaignType ~= var_0_12.CampaignType.NORMAL or not next(arg_251_0.preBattleShow) or var_0_13.ctx.battle.count % 10 == 0 then
		return
	end

	if not arg_251_0:checkHeroNeedShow() then
		return
	end

	local var_251_0 = arg_251_0.needShowHero

	if var_251_0 and next(var_251_0) and not var_251_0:isDeath() then
		local var_251_1 = cc.p(var_251_0.fighterModel:getPosition())

		if var_0_12.STAGE_WIDTH - var_251_1.x >= 100 then
			arg_251_0:pauseBattle()
			var_0_13.ctx.battle.stopAllFighter()
			var_251_0:unsetMaskColor()
			var_0_13.ctx.battle.blackLayer:show()

			local var_251_2 = {
				table_id = var_251_0:getModelID(),
				position = cc.p(var_251_0.fighterModel:getParent():convertToWorldSpace(var_251_1)),
				callback = function()
					arg_251_0:clearPreBattleShow(var_251_0:getTableID())
					var_0_13.ctx.battle.resumeAllFighter()
					var_0_13.ctx.battle.blackLayer:hide()
					arg_251_0:startBattle()
					arg_251_0:playHeroShow()
				end
			}

			var_0_12.WindowManager.get():openWindow("hero_show", var_251_2)
		end
	end
end

function var_0_0.clearPreBattleShow(arg_253_0, arg_253_1)
	if not arg_253_0.preBattleShow or not next(arg_253_0.preBattleShow) then
		return false
	end

	if arg_253_1 then
		for iter_253_0 = #arg_253_0.preBattleShow, 1, -1 do
			if arg_253_0.preBattleShow[iter_253_0] == arg_253_1 then
				table.remove(arg_253_0.preBattleShow, iter_253_0)
			end
		end
	end

	arg_253_0.isHeroNeedShow = false
	arg_253_0.needShowHero = nil
end

function var_0_0.checkHeroNeedShow(arg_254_0)
	if not arg_254_0.preBattleShow or not next(arg_254_0.preBattleShow) then
		arg_254_0.isHeroNeedShow = false

		return false
	elseif arg_254_0.isHeroNeedShow and arg_254_0.needShowHero then
		return true
	elseif not arg_254_0.isHeroNeedShow and arg_254_0.needShowHero and not next(arg_254_0.needShowHero) then
		return false
	end

	for iter_254_0, iter_254_1 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_254_1:getSummonType() == var_0_12.summonMonsterType.None and not iter_254_1:isDeath() then
			local var_254_0 = iter_254_1.hero_:getTableID()
			local var_254_1 = iter_254_1.hero_:getModelID()

			if string.sub(tostring(var_254_1), 1, 1) == "1" then
				for iter_254_2 = 1, #arg_254_0.preBattleShow do
					if var_254_0 == arg_254_0.preBattleShow[iter_254_2] then
						arg_254_0.isHeroNeedShow = true
						arg_254_0.needShowHero = iter_254_1

						return true
					end
				end
			end
		end
	end

	arg_254_0.isHeroNeedShow = false
	arg_254_0.needShowHero = {}

	return false
end

function var_0_0.finishPlayoffs(arg_255_0, arg_255_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_255_0 = arg_255_0:getBattleStar()
	local var_255_1 = {}
	local var_255_2 = {}
	local var_255_3 = {}
	local var_255_4 = {}

	for iter_255_0, iter_255_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_255_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_255_1, iter_255_1)
		elseif iter_255_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_255_3, iter_255_1)
		end
	end

	for iter_255_2, iter_255_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_255_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_255_2, iter_255_3)
		elseif iter_255_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_255_4, iter_255_3)
		end
	end

	arg_255_0:clearFormation(true)

	var_0_13.ctx.battle.teamA = {}
	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.summonMonsters = {}

	if var_255_0 > 0 then
		local var_255_5
		local var_255_6

		if arg_255_0.playoffsModel.isSelfChallenger then
			var_255_6 = var_0_12.WindowName.battleWinWnd
			var_255_5 = {
				mana = 0,
				star = var_255_0,
				campaignID = arg_255_0.campaignID,
				campaignType = arg_255_0.campaignType,
				fighterA = var_255_1,
				fighterB = var_255_2,
				petA = var_255_3,
				petB = var_255_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_255_0.favorDegreeUp,
				allParams = arg_255_0.allParams
			}
		else
			var_255_6 = var_0_12.WindowName.battleLoseWnd
			var_255_5 = {
				mana = 0,
				star = var_255_0,
				campaignID = arg_255_0.campaignID,
				campaignType = arg_255_0.campaignType,
				fighterA = var_255_2,
				fighterB = var_255_1,
				petA = var_255_4,
				petB = var_255_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_255_0.favorDegreeUp,
				allParams = arg_255_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_255_6, var_255_5, function(arg_256_0)
			if arg_256_0 == nil then
				return
			end

			arg_255_0.battleEndWindow_ = arg_256_0

			cc.EventProxy.new(arg_255_0.battleEndWindow_, arg_255_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_257_0)
				arg_255_0:closeBattleEndWindow(function()
					if arg_255_1 then
						var_0_12.isArenaBattle = true

						arg_255_0.playoffsModel:setCurrentBattleRound(arg_255_0.playoffsModel:getCurrentBattleRound() + 1)
						arg_255_0.playoffsModel:getBattleReportFromBack(function(arg_259_0)
							local var_259_0 = arg_255_0.playoffsModel:setBattleParams(arg_259_0, arg_255_0.playoffsModel:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_259_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_260_0)
				arg_255_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_260_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		if arg_255_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
			arg_255_0.timeOut_ = false
		end

		local var_255_7
		local var_255_8

		if arg_255_0.playoffsModel.isSelfChallenger then
			var_255_8 = var_0_12.WindowName.battleLoseWnd
			var_255_7 = {
				mana = 0,
				star = var_255_0,
				campaignID = arg_255_0.campaignID,
				campaignType = arg_255_0.campaignType,
				fighterA = var_255_1,
				fighterB = var_255_2,
				petA = var_255_3,
				petB = var_255_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_255_0.favorDegreeUp,
				allParams = arg_255_0.allParams
			}
		else
			var_255_8 = var_0_12.WindowName.battleWinWnd
			var_255_7 = {
				mana = 0,
				star = var_255_0,
				campaignID = arg_255_0.campaignID,
				campaignType = arg_255_0.campaignType,
				fighterA = var_255_2,
				fighterB = var_255_1,
				petA = var_255_4,
				petB = var_255_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_255_0.favorDegreeUp,
				allParams = arg_255_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_255_8, var_255_7, function(arg_262_0)
			if arg_262_0 == nil then
				return
			end

			arg_255_0.battleEndWindow_ = arg_262_0

			cc.EventProxy.new(arg_255_0.battleEndWindow_, arg_255_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_263_0)
				arg_255_0:closeBattleEndWindow(function()
					if arg_255_1 then
						var_0_12.isArenaBattle = true

						arg_255_0.playoffsModel:setCurrentBattleRound(arg_255_0.playoffsModel:getCurrentBattleRound() + 1)
						arg_255_0.playoffsModel:getBattleReportFromBack(function(arg_265_0)
							local var_265_0 = arg_255_0.playoffsModel:setBattleParams(arg_265_0, arg_255_0.playoffsModel:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_265_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_266_0)
				arg_255_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_266_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end
end

function var_0_0.finishCasual(arg_268_0, arg_268_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_268_0 = arg_268_0:getBattleStar()
	local var_268_1 = {}
	local var_268_2 = {}
	local var_268_3 = {}
	local var_268_4 = {}

	for iter_268_0, iter_268_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_268_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_268_1, iter_268_1)
		elseif iter_268_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_268_3, iter_268_1)
		end
	end

	for iter_268_2, iter_268_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_268_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_268_2, iter_268_3)
		elseif iter_268_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_268_4, iter_268_3)
		end
	end

	arg_268_0:clearFormation(true)

	var_0_13.ctx.battle.teamA = {}
	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.summonMonsters = {}

	if var_268_0 > 0 then
		local var_268_5
		local var_268_6

		if arg_268_0.regionCasualArena.isSelfChallenger then
			var_268_6 = var_0_12.WindowName.battleWinWnd
			var_268_5 = {
				mana = 0,
				star = var_268_0,
				campaignID = arg_268_0.campaignID,
				campaignType = arg_268_0.campaignType,
				fighterA = var_268_1,
				fighterB = var_268_2,
				petA = var_268_3,
				petB = var_268_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_268_0.favorDegreeUp,
				allParams = arg_268_0.allParams
			}
		else
			var_268_6 = var_0_12.WindowName.battleLoseWnd
			var_268_5 = {
				mana = 0,
				star = var_268_0,
				campaignID = arg_268_0.campaignID,
				campaignType = arg_268_0.campaignType,
				fighterA = var_268_2,
				fighterB = var_268_1,
				petA = var_268_4,
				petB = var_268_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_268_0.favorDegreeUp,
				allParams = arg_268_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_268_6, var_268_5, function(arg_269_0)
			if arg_269_0 == nil then
				return
			end

			arg_268_0.battleEndWindow_ = arg_269_0

			cc.EventProxy.new(arg_268_0.battleEndWindow_, arg_268_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_270_0)
				arg_268_0:closeBattleEndWindow(function()
					if arg_268_1 then
						var_0_12.isArenaBattle = true

						arg_268_0.regionCasualArena:setCurrentBattleRound(arg_268_0.regionCasualArena:getCurrentBattleRound() + 1)
						arg_268_0.regionCasualArena:getBattleReportFromBack(function(arg_272_0)
							local var_272_0 = arg_268_0.regionCasualArena:setBattleParams(arg_272_0, arg_268_0.regionCasualArena:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_272_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_273_0)
				arg_268_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_273_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		if arg_268_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
			arg_268_0.timeOut_ = false
		end

		local var_268_7
		local var_268_8

		if arg_268_0.regionCasualArena.isSelfChallenger then
			var_268_8 = var_0_12.WindowName.battleLoseWnd
			var_268_7 = {
				mana = 0,
				star = var_268_0,
				campaignID = arg_268_0.campaignID,
				campaignType = arg_268_0.campaignType,
				fighterA = var_268_1,
				fighterB = var_268_2,
				petA = var_268_3,
				petB = var_268_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_268_0.favorDegreeUp,
				allParams = arg_268_0.allParams
			}
		else
			var_268_8 = var_0_12.WindowName.battleWinWnd
			var_268_7 = {
				mana = 0,
				star = var_268_0,
				campaignID = arg_268_0.campaignID,
				campaignType = arg_268_0.campaignType,
				fighterA = var_268_2,
				fighterB = var_268_1,
				petA = var_268_4,
				petB = var_268_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_268_0.favorDegreeUp,
				allParams = arg_268_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_268_8, var_268_7, function(arg_275_0)
			if arg_275_0 == nil then
				return
			end

			arg_268_0.battleEndWindow_ = arg_275_0

			cc.EventProxy.new(arg_268_0.battleEndWindow_, arg_268_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_276_0)
				arg_268_0:closeBattleEndWindow(function()
					if arg_268_1 then
						var_0_12.isArenaBattle = true

						arg_268_0.regionCasualArena:setCurrentBattleRound(arg_268_0.regionCasualArena:getCurrentBattleRound() + 1)
						arg_268_0.regionCasualArena:getBattleReportFromBack(function(arg_278_0)
							local var_278_0 = arg_268_0.regionCasualArena:setBattleParams(arg_278_0, arg_268_0.regionCasualArena:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_278_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_279_0)
				arg_268_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_279_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end
end

function var_0_0.finishFriend(arg_281_0, arg_281_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_281_0 = arg_281_0:getBattleStar()
	local var_281_1 = {}
	local var_281_2 = {}
	local var_281_3 = {}
	local var_281_4 = {}

	for iter_281_0, iter_281_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_281_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_281_1, iter_281_1)
		elseif iter_281_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_281_3, iter_281_1)
		end
	end

	for iter_281_2, iter_281_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_281_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_281_2, iter_281_3)
		elseif iter_281_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_281_4, iter_281_3)
		end
	end

	arg_281_0:clearFormation(true)

	var_0_13.ctx.battle.teamA = {}
	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.summonMonsters = {}

	if var_281_0 > 0 then
		local var_281_5
		local var_281_6

		if arg_281_0.socialSystem.isSelfChallenger then
			var_281_6 = var_0_12.WindowName.battleWinWnd
			var_281_5 = {
				mana = 0,
				star = var_281_0,
				campaignID = arg_281_0.campaignID,
				campaignType = arg_281_0.campaignType,
				fighterA = var_281_1,
				fighterB = var_281_2,
				petA = var_281_3,
				petB = var_281_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_281_0.favorDegreeUp,
				allParams = arg_281_0.allParams
			}
		else
			var_281_6 = var_0_12.WindowName.battleLoseWnd
			var_281_5 = {
				mana = 0,
				star = var_281_0,
				campaignID = arg_281_0.campaignID,
				campaignType = arg_281_0.campaignType,
				fighterA = var_281_2,
				fighterB = var_281_1,
				petA = var_281_4,
				petB = var_281_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_281_0.favorDegreeUp,
				allParams = arg_281_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_281_6, var_281_5, function(arg_282_0)
			if arg_282_0 == nil then
				return
			end

			arg_281_0.battleEndWindow_ = arg_282_0

			cc.EventProxy.new(arg_281_0.battleEndWindow_, arg_281_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_283_0)
				arg_281_0:closeBattleEndWindow(function()
					if arg_281_1 then
						var_0_12.isArenaBattle = true

						arg_281_0.socialSystem:setCurrentBattleRound(arg_281_0.socialSystem:getCurrentBattleRound() + 1)
						arg_281_0.socialSystem:getBattleReportFromBack(function(arg_285_0)
							local var_285_0 = arg_281_0.socialSystem:setBattleParams(arg_285_0, arg_281_0.socialSystem:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_285_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_286_0)
				arg_281_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_286_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		if arg_281_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
			arg_281_0.timeOut_ = false
		end

		local var_281_7
		local var_281_8

		if arg_281_0.socialSystem.isSelfChallenger then
			var_281_8 = var_0_12.WindowName.battleLoseWnd
			var_281_7 = {
				mana = 0,
				star = var_281_0,
				campaignID = arg_281_0.campaignID,
				campaignType = arg_281_0.campaignType,
				fighterA = var_281_1,
				fighterB = var_281_2,
				petA = var_281_3,
				petB = var_281_4,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_281_0.favorDegreeUp,
				allParams = arg_281_0.allParams
			}
		else
			var_281_8 = var_0_12.WindowName.battleWinWnd
			var_281_7 = {
				mana = 0,
				star = var_281_0,
				campaignID = arg_281_0.campaignID,
				campaignType = arg_281_0.campaignType,
				fighterA = var_281_2,
				fighterB = var_281_1,
				petA = var_281_4,
				petB = var_281_3,
				items = {},
				heroExp = {},
				favorDegreeUp = arg_281_0.favorDegreeUp,
				allParams = arg_281_0.allParams
			}
		end

		var_0_12.WindowManager.get():openWindow(var_281_8, var_281_7, function(arg_288_0)
			if arg_288_0 == nil then
				return
			end

			arg_281_0.battleEndWindow_ = arg_288_0

			cc.EventProxy.new(arg_281_0.battleEndWindow_, arg_281_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_289_0)
				arg_281_0:closeBattleEndWindow(function()
					if arg_281_1 then
						var_0_12.isArenaBattle = true

						arg_281_0.socialSystem:setCurrentBattleRound(arg_281_0.socialSystem:getCurrentBattleRound() + 1)
						arg_281_0.socialSystem:getBattleReportFromBack(function(arg_291_0)
							local var_291_0 = arg_281_0.socialSystem:setBattleParams(arg_291_0, arg_281_0.socialSystem:getCurrentBattleRound())

							cc.Director:getInstance():popScene()
							var_0_12.WindowManager.get():openWindow("region_arena_loading", var_291_0)
						end)
					else
						var_0_12.isArenaBattle = false

						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
						var_0_12.WindowManager.get():closeAllWindows()
					end
				end)
			end):addEventListener(var_0_12.event.BATTLE_END_WATCH_REGION_REPLAY, function(arg_292_0)
				arg_281_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_292_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end
end

function var_0_0.finishSuperArena(arg_294_0, arg_294_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_294_0 = arg_294_0:getBattleStar()
	local var_294_1 = {}
	local var_294_2 = {}
	local var_294_3 = {}
	local var_294_4 = {}

	for iter_294_0, iter_294_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_294_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_294_1, iter_294_1)
		elseif iter_294_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_294_3, iter_294_1)
		end
	end

	for iter_294_2, iter_294_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_294_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_294_2, iter_294_3)
		elseif iter_294_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_294_4, iter_294_3)
		end
	end

	arg_294_0:clearFormation(true)

	var_0_13.ctx.battle.teamA = {}
	var_0_13.ctx.battle.teamB = {}
	var_0_13.ctx.battle.summonMonsters = {}

	if var_294_0 > 0 then
		local var_294_5 = {
			mana = 0,
			star = var_294_0,
			campaignID = arg_294_0.campaignID,
			campaignType = arg_294_0.campaignType,
			fighterA = var_294_1,
			fighterB = var_294_2,
			petA = var_294_3,
			petB = var_294_4,
			items = {},
			heroExp = {},
			favorDegreeUp = arg_294_0.favorDegreeUp,
			allParams = arg_294_0.allParams
		}

		var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleWinWnd, var_294_5, function(arg_295_0)
			if arg_295_0 == nil then
				return
			end

			arg_294_0.battleEndWindow_ = arg_295_0

			cc.EventProxy.new(arg_294_0.battleEndWindow_, arg_294_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_296_0)
				arg_294_0:closeBattleEndWindow(function()
					if arg_294_1 then
						arg_294_0.peakArena:setCurrentBattleRound(arg_294_0.peakArena:getCurrentBattleRound() + 1)

						arg_294_0.herosA = arg_294_0.heroGroupA["team" .. arg_294_0.peakArena:getCurrentBattleRound()]
						arg_294_0.petsA = arg_294_0.heroGroupA["pet" .. arg_294_0.peakArena:getCurrentBattleRound()]
						arg_294_0.petsB = arg_294_0.heroGroupB["pet" .. arg_294_0.peakArena:getCurrentBattleRound()]

						arg_294_0:setupWindows()
						arg_294_0:setupButtons()
						arg_294_0:setupMusic()
						arg_294_0:init()
					else
						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
					end
				end)
			end)
		end)
	else
		if arg_294_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_294_0.campaignType == var_0_12.CampaignType.CHAPTER_BOSS then
			arg_294_0.timeOut_ = false
		end

		var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleLoseWnd, {
			star = var_294_0,
			campaignID = arg_294_0.campaignID,
			campaignType = arg_294_0.campaignType,
			petA = var_294_3,
			petB = var_294_4,
			fighterA = var_294_1,
			fighterB = var_294_2,
			is_timeout = arg_294_0.timeOut_,
			allParams = arg_294_0.allParams
		}, function(arg_298_0)
			if arg_298_0 == nil then
				return
			end

			arg_294_0.battleEndWindow_ = arg_298_0

			cc.EventProxy.new(arg_294_0.battleEndWindow_, arg_294_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_299_0)
				arg_294_0:closeBattleEndWindow(function()
					if arg_294_1 then
						arg_294_0.peakArena:setCurrentBattleRound(arg_294_0.peakArena:getCurrentBattleRound() + 1)

						arg_294_0.herosA = arg_294_0.heroGroupA["team" .. arg_294_0.peakArena:getCurrentBattleRound()]
						arg_294_0.petsA = arg_294_0.heroGroupA["pet" .. arg_294_0.peakArena:getCurrentBattleRound()]
						arg_294_0.petsB = arg_294_0.heroGroupB["pet" .. arg_294_0.peakArena:getCurrentBattleRound()]

						arg_294_0:setupWindows()
						arg_294_0:setupButtons()
						arg_294_0:setupMusic()
						arg_294_0:init()
					else
						var_0_12.WindowManager.get():closeAllWindows()
						var_0_13.ctx.battle.releaseCache()
						cc.Director:getInstance():popScene()
					end
				end)
			end)
		end)
	end
end

function var_0_0.finishBattle(arg_301_0, arg_301_1, arg_301_2)
	if arg_301_1 and arg_301_1.favor then
		if not arg_301_0.favorDegreeUp then
			arg_301_0.favorDegreeUp = {}
		end

		for iter_301_0, iter_301_1 in pairs(arg_301_1.favor) do
			if iter_301_1 > arg_301_0.selfPlayer:getHero(tonumber(iter_301_0)):getFavorDegree() then
				arg_301_0.favorDegreeUp[tonumber(iter_301_0)] = true

				arg_301_0.selfPlayer:getHero(tonumber(iter_301_0)):setFavorDegree(iter_301_1)
			end
		end
	end

	if arg_301_0.awards and #arg_301_0.awards ~= 0 then
		arg_301_0.selfPlayer:handleRewards(arg_301_0.awards)

		arg_301_0.awards = nil
		arg_301_0.allParams.awards = nil
	end

	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_301_0 = {}
	local var_301_1 = {}
	local var_301_2 = {}
	local var_301_3 = {}

	for iter_301_2, iter_301_3 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_301_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_301_0, iter_301_3)
		elseif iter_301_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_301_2, iter_301_3)
		end
	end

	for iter_301_4, iter_301_5 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_301_5:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_301_1, iter_301_5)
		elseif iter_301_5:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_301_3, iter_301_5)
		end
	end

	arg_301_0:clearFormation(true)

	if arg_301_0:getBattleStar() > 0 or arg_301_0.campaignType == var_0_12.CampaignType.GUILD then
		local var_301_4 = {
			star = arg_301_0:getBattleStar(),
			campaignID = arg_301_0.campaignID,
			campaignType = arg_301_0.campaignType,
			fighterA = var_301_0,
			fighterB = var_301_1,
			petA = var_301_2,
			petB = var_301_3,
			mana = var_0_13.ctx.battle.dropManaCount,
			items = arg_301_0.dropItems,
			heroExp = arg_301_1 and arg_301_1.exps or {},
			tutorCoin = arg_301_1 and arg_301_1.tutorCoin,
			data = arg_301_2,
			favorDegreeUp = arg_301_0.favorDegreeUp,
			allParams = arg_301_0.allParams,
			star_crystal = arg_301_1 and arg_301_1.star_crystal
		}

		if arg_301_0.campaignType == var_0_12.CampaignType.GUILD then
			var_301_4.mana = arg_301_1.coin_award
			var_301_4.items = arg_301_2.items
			var_301_4.guildItems = arg_301_2.guild_items
		end

		if arg_301_0.campaignType == var_0_12.CampaignType.PET then
			var_301_4.items = arg_301_2.items
			var_301_4.mana = arg_301_2.mana
		end

		if arg_301_0.campaignType == var_0_12.CampaignType.ZHUGE_NOTE then
			var_301_4.items = arg_301_2.items
		end

		if arg_301_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
			var_301_4.location = arg_301_0.location
		end

		if arg_301_0.campaignType == var_0_12.CampaignType.FOURTH_ANNI_MAP then
			var_301_4.mana = arg_301_1.coin_award
			var_301_4.addExp = arg_301_1.collegeExp
		end

		if arg_301_0.campaignType == var_0_12.CampaignType.HUNQI then
			var_301_4.items = arg_301_2.items
			var_301_4.spiritItems = arg_301_1.spirit_items
		end

		var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleWinWnd, var_301_4, function(arg_302_0)
			if arg_302_0 == nil then
				return
			end

			arg_301_0.battleEndWindow_ = arg_302_0

			cc.EventProxy.new(arg_301_0.battleEndWindow_, arg_301_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_303_0)
				arg_301_0:closeBattleEndWindow(function()
					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	else
		if arg_301_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_301_0.campaignType == var_0_12.CampaignType.CHAPTER_BOSS then
			arg_301_0.timeOut_ = false
		end

		var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleLoseWnd, {
			star = arg_301_0:getBattleStar(),
			campaignID = arg_301_0.campaignID,
			campaignType = arg_301_0.campaignType,
			fighterA = var_301_0,
			fighterB = var_301_1,
			petA = var_301_2,
			petB = var_301_3,
			is_timeout = arg_301_0.timeOut_,
			allParams = arg_301_0.allParams
		}, function(arg_305_0)
			if arg_305_0 == nil then
				return
			end

			arg_301_0.battleEndWindow_ = arg_305_0

			cc.EventProxy.new(arg_301_0.battleEndWindow_, arg_301_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_306_0)
				arg_301_0:closeBattleEndWindow(function()
					var_0_12.battleBackEnterWindow = arg_306_0.click_id

					var_0_12.WindowManager.get():closeAllWindows()
					var_0_13.ctx.battle.releaseCache()
					cc.Director:getInstance():popScene()
				end)
			end)
		end)
	end

	if arg_301_1 and arg_301_1.awards and arg_301_1.awards.awards then
		arg_301_0.selfPlayer:handleRewards(arg_301_1.awards.awards)
	end
end

function var_0_0.finishElement(arg_308_0, arg_308_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_308_0 = {}
	local var_308_1 = {}
	local var_308_2 = {}
	local var_308_3 = {}

	for iter_308_0, iter_308_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_308_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_308_0, iter_308_1)
		elseif iter_308_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_308_2, iter_308_1)
		end
	end

	for iter_308_2, iter_308_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_308_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_308_1, iter_308_3)
		elseif iter_308_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_308_3, iter_308_3)
		end
	end

	arg_308_0:clearFormation(true)

	local var_308_4

	if arg_308_1.pre_info then
		var_308_4 = {
			my_rank = arg_308_1.total_rank,
			hurt = arg_308_1.damage,
			total_hurt = arg_308_1.total_hurt,
			pre_name = arg_308_1.pre_info.player_name,
			pre_avatar = arg_308_1.pre_info.avatar_id,
			pre_avatar_frame = arg_308_1.pre_info.avatar_frame_id,
			pre_lev = arg_308_1.pre_info.lev,
			pre_hurt = arg_308_1.pre_info.hurt,
			pre_rank = arg_308_1.pre_info.pre_rank,
			damage_add = arg_308_1.incr_damage,
			fighterA = var_308_0,
			fighterB = var_308_1,
			petA = var_308_2,
			petB = var_308_3
		}
	else
		var_308_4 = {
			my_rank = arg_308_1.total_rank,
			hurt = arg_308_1.damage,
			total_hurt = arg_308_1.total_hurt,
			damage_add = arg_308_1.incr_damage,
			fighterA = var_308_0,
			fighterB = var_308_1,
			petA = var_308_2,
			petB = var_308_3
		}
	end

	var_0_12.WindowManager.get():openWindow("world_boss_battle_over", var_308_4, function(arg_309_0)
		if arg_309_0 == nil then
			return
		end

		arg_308_0.battleEndWindow_ = arg_309_0

		cc.EventProxy.new(arg_308_0.battleEndWindow_, arg_308_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_310_0)
			arg_308_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishAdventureIllusionSingle(arg_312_0, arg_312_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_312_0 = {}
	local var_312_1 = {}
	local var_312_2 = {}
	local var_312_3 = {}

	for iter_312_0, iter_312_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_312_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_312_0, iter_312_1)
		elseif iter_312_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_312_2, iter_312_1)
		end
	end

	for iter_312_2, iter_312_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_312_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_312_1, iter_312_3)
		elseif iter_312_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_312_3, iter_312_3)
		end
	end

	arg_312_0:clearFormation(true)
	arg_312_0.selfPlayer:handleRewards(arg_312_1.awards, function()
		var_0_12.WindowManager.get():closeAllWindows()
		var_0_13.ctx.battle.releaseCache()
		cc.Director:getInstance():popScene()
	end)
end

function var_0_0.finishIllusion(arg_314_0, arg_314_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_314_0 = {}
	local var_314_1 = {}
	local var_314_2 = {}
	local var_314_3 = {}

	for iter_314_0, iter_314_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_314_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_314_0, iter_314_1)
		elseif iter_314_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_314_2, iter_314_1)
		end
	end

	for iter_314_2, iter_314_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_314_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_314_1, iter_314_3)
		elseif iter_314_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_314_3, iter_314_3)
		end
	end

	arg_314_0:clearFormation(true)

	local var_314_4 = {
		rank = arg_314_1.rank,
		damage = arg_314_1.now_hurt,
		damageHighest = arg_314_1.highest_hurt,
		fighterA = var_314_0,
		fighterB = var_314_1,
		petA = var_314_2
	}

	if arg_314_1.pre_info then
		var_314_4.pre_name = arg_314_1.pre_info.player_name
		var_314_4.pre_avatar = arg_314_1.pre_info.avatar_id
		var_314_4.pre_avatar_frame = arg_314_1.pre_info.avatar_frame_id
		var_314_4.pre_lev = arg_314_1.pre_info.lev
		var_314_4.pre_damage = arg_314_1.pre_info.hurt
		var_314_4.pre_rank = arg_314_1.pre_info.pre_rank
		var_314_4.conquer_lev = arg_314_1.pre_info.conquer_lev or 0
		var_314_4.conquer_loop_id = arg_314_1.pre_info.conquer_loop_id
	end

	var_0_12.WindowManager.get():openWindow("illusion_battle_result", var_314_4, function(arg_315_0)
		if arg_315_0 == nil then
			return
		end

		arg_314_0.battleEndWindow_ = arg_315_0

		cc.EventProxy.new(arg_314_0.battleEndWindow_, arg_314_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_316_0)
			arg_314_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishAllNightBoss(arg_318_0, arg_318_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_318_0 = {}
	local var_318_1 = {}
	local var_318_2 = {}
	local var_318_3 = {}

	for iter_318_0, iter_318_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_318_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_318_0, iter_318_1)
		elseif iter_318_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_318_2, iter_318_1)
		end
	end

	for iter_318_2, iter_318_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_318_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_318_1, iter_318_3)
		elseif iter_318_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_318_3, iter_318_3)
		end
	end

	arg_318_0:clearFormation(true)

	local var_318_4 = {
		rank = arg_318_1.self_rank,
		damage = arg_318_1.now_hurt,
		totalDamage = arg_318_1.self_damage,
		fighterA = var_318_0,
		fighterB = var_318_1,
		petA = var_318_2
	}

	if arg_318_1.pre_np_info and arg_318_1.pre_np_info.rank > 0 then
		var_318_4.pre_player = arg_318_1.pre_np_info
	end

	if arg_318_1.awards then
		arg_318_0.selfPlayer:handleRewards(arg_318_1.awards)
	end

	var_0_12.WindowManager.get():openWindow("all_night_boss_result", var_318_4, function(arg_319_0)
		if arg_319_0 == nil then
			return
		end

		arg_318_0.battleEndWindow_ = arg_319_0

		cc.EventProxy.new(arg_318_0.battleEndWindow_, arg_318_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_320_0)
			arg_318_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)

	local var_318_5 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.ALL_NIGHT)

	var_318_5.bossInfo.rank = var_318_4.rank
	var_318_5.bossInfo.self_damage = var_318_4.damage
end

function var_0_0.finishRagnarok(arg_322_0, arg_322_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_322_0 = {}
	local var_322_1 = {}
	local var_322_2 = {}
	local var_322_3 = {}

	for iter_322_0, iter_322_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_322_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_322_0, iter_322_1)
		elseif iter_322_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_322_2, iter_322_1)
		end
	end

	for iter_322_2, iter_322_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_322_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_322_1, iter_322_3)
		elseif iter_322_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_322_3, iter_322_3)
		end
	end

	arg_322_0:clearFormation(true)

	local var_322_4 = {
		mana = 0,
		campaignID = arg_322_0.campaignID,
		campaignType = arg_322_0.campaignType,
		fighterA = var_322_0,
		fighterB = var_322_1,
		petA = var_322_2,
		petB = var_322_3,
		items = {},
		heroExp = {}
	}

	var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleWinWnd, var_322_4, function(arg_323_0)
		if arg_323_0 == nil then
			return
		end

		arg_322_0.battleEndWindow_ = arg_323_0

		cc.EventProxy.new(arg_322_0.battleEndWindow_, arg_322_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_324_0)
			arg_322_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)

	local var_322_5 = var_0_12.ModelManager.get():loadModel(var_0_12.ModelType.RAGNAROK)

	if arg_322_1 and var_322_5:getType() == var_0_12.RagnarokType.SINGLE then
		var_322_5.monster_status = arg_322_1.monster_status
		var_322_5.hero_status = arg_322_1.hero_status
		var_322_5.is_pass = arg_322_1.is_pass
		var_322_5.is_finish = arg_322_1.is_finish

		if arg_322_1.is_pass == 1 then
			var_322_5.win_params = arg_322_1
		end
	end
end

function var_0_0.finishFifthAnniBoss(arg_326_0, arg_326_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_326_0 = {}
	local var_326_1 = {}
	local var_326_2 = {}
	local var_326_3 = {}

	for iter_326_0, iter_326_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_326_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_326_0, iter_326_1)
		elseif iter_326_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_326_2, iter_326_1)
		end
	end

	for iter_326_2, iter_326_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_326_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_326_1, iter_326_3)
		elseif iter_326_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_326_3, iter_326_3)
		end
	end

	arg_326_0:clearFormation(true)

	local var_326_4 = {
		mana = 0,
		campaignID = arg_326_0.campaignID,
		campaignType = arg_326_0.campaignType,
		fighterA = var_326_0,
		fighterB = var_326_1,
		petA = var_326_2,
		petB = var_326_3,
		items = {},
		heroExp = {}
	}

	var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleWinWnd, var_326_4, function(arg_327_0)
		if arg_327_0 == nil then
			return
		end

		arg_326_0.battleEndWindow_ = arg_327_0

		cc.EventProxy.new(arg_326_0.battleEndWindow_, arg_326_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_328_0)
			arg_326_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)

		if arg_326_1.awards then
			arg_326_0.selfPlayer:handleRewards(arg_326_1.awards)
		end
	end)
end

function var_0_0.finishNianBoss(arg_330_0, arg_330_1)
	local var_330_0 = arg_330_1.boss_info

	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_330_1 = {}
	local var_330_2 = {}
	local var_330_3 = {}
	local var_330_4 = {}

	for iter_330_0, iter_330_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_330_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_330_1, iter_330_1)
		elseif iter_330_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_330_3, iter_330_1)
		end
	end

	for iter_330_2, iter_330_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_330_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_330_2, iter_330_3)
		elseif iter_330_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_330_4, iter_330_3)
		end
	end

	arg_330_0:clearFormation(true)

	local var_330_5

	if var_330_0.pre_info then
		var_330_5 = {
			my_rank = var_330_0.total_rank,
			hurt = var_330_0.damage,
			total_hurt = var_330_0.total_hurt,
			pre_name = var_330_0.pre_info.player_name,
			pre_avatar = var_330_0.pre_info.avatar_id,
			pre_avatar_frame = var_330_0.pre_info.avatar_frame_id,
			pre_lev = var_330_0.pre_info.lev,
			pre_hurt = var_330_0.pre_info.hurt,
			pre_rank = var_330_0.pre_info.pre_rank,
			damage_add = var_330_0.incr_damage,
			fighterA = var_330_1,
			fighterB = var_330_2,
			petA = var_330_3,
			petB = var_330_4
		}
	else
		var_330_5 = {
			my_rank = var_330_0.total_rank,
			hurt = var_330_0.damage,
			total_hurt = var_330_0.total_hurt,
			damage_add = var_330_0.incr_damage,
			fighterA = var_330_1,
			fighterB = var_330_2,
			petA = var_330_3,
			petB = var_330_4
		}
	end

	var_0_12.WindowManager.get():openWindow("nian_boss_battle_over", var_330_5, function(arg_331_0)
		if arg_331_0 == nil then
			return
		end

		arg_330_0.battleEndWindow_ = arg_331_0

		cc.EventProxy.new(arg_330_0.battleEndWindow_, arg_330_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_332_0)
			arg_330_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishThirdAnniversaryBoss(arg_334_0, arg_334_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_334_0 = {}
	local var_334_1 = {}
	local var_334_2 = {}
	local var_334_3 = {}

	for iter_334_0, iter_334_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_334_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_334_0, iter_334_1)
		elseif iter_334_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_334_2, iter_334_1)
		end
	end

	for iter_334_2, iter_334_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_334_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_334_1, iter_334_3)
		elseif iter_334_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_334_3, iter_334_3)
		end
	end

	arg_334_0:clearFormation(true)

	local var_334_4

	if arg_334_1.pre_np_info and arg_334_1.pre_np_info.rank > 0 then
		var_334_4 = {
			my_rank = arg_334_1.self_rank,
			self_damage = arg_334_1.selfHarms,
			total_damage = arg_334_1.self_damage,
			pre_name = arg_334_1.pre_np_info.player_name,
			pre_avatar = arg_334_1.pre_np_info.avatar_id,
			pre_avatar_frame = arg_334_1.pre_np_info.avatar_frame_id,
			pre_lev = arg_334_1.pre_np_info.lev,
			pre_rank = arg_334_1.pre_np_info.rank,
			pre_damage = arg_334_1.pre_np_info.damage,
			conquer_lev = arg_334_1.pre_np_info.conquer_lev,
			conquer_loop_id = arg_334_1.pre_np_info.conquer_loop_id,
			fighterA = var_334_0,
			fighterB = var_334_1,
			petA = var_334_2,
			petB = var_334_3
		}
	else
		var_334_4 = {
			my_rank = arg_334_1.self_rank,
			self_damage = arg_334_1.selfHarms,
			total_damage = arg_334_1.self_damage,
			fighterA = var_334_0,
			fighterB = var_334_1,
			petA = var_334_2,
			petB = var_334_3
		}
	end

	var_0_12.WindowManager.get():openWindow("third_anniversary_boss_over", var_334_4, function(arg_335_0)
		if arg_335_0 == nil then
			return
		end

		arg_334_0.battleEndWindow_ = arg_335_0

		cc.EventProxy.new(arg_334_0.battleEndWindow_, arg_334_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_336_0)
			arg_334_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishThiefBoss(arg_338_0, arg_338_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)

	local var_338_0 = {}
	local var_338_1 = {}
	local var_338_2 = {}
	local var_338_3 = {}

	for iter_338_0, iter_338_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if iter_338_1:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_338_0, iter_338_1)
		elseif iter_338_1:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_338_2, iter_338_1)
		end
	end

	for iter_338_2, iter_338_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if iter_338_3:getSummonType() == var_0_12.summonMonsterType.None then
			table.insert(var_338_1, iter_338_3)
		elseif iter_338_3:getSummonType() == var_0_12.summonMonsterType.Pet then
			table.insert(var_338_3, iter_338_3)
		end
	end

	arg_338_0:clearFormation(true)

	local var_338_4

	if arg_338_1.boss_info.pre_info then
		var_338_4 = {
			my_rank = arg_338_1.boss_info.total_rank,
			hurt = arg_338_1.boss_info.damage,
			total_hurt = arg_338_1.boss_info.total_hurt,
			pre_name = arg_338_1.boss_info.pre_info.player_name,
			pre_avatar = arg_338_1.boss_info.pre_info.avatar_id,
			pre_avatar_frame = arg_338_1.boss_info.pre_info.avatar_frame_id,
			pre_lev = arg_338_1.boss_info.pre_info.lev,
			pre_hurt = arg_338_1.boss_info.pre_info.hurt,
			pre_rank = arg_338_1.boss_info.pre_info.pre_rank,
			awards = arg_338_1.award.awards,
			damage_add = arg_338_1.boss_info.incr_damage,
			fighterA = var_338_0,
			fighterB = var_338_1,
			petA = var_338_2,
			petB = var_338_3
		}
	else
		var_338_4 = {
			my_rank = arg_338_1.boss_info.total_rank,
			hurt = arg_338_1.boss_info.damage,
			total_hurt = arg_338_1.boss_info.total_hurt,
			damage_add = arg_338_1.boss_info.incr_damage,
			awards = arg_338_1.award.awards,
			fighterA = var_338_0,
			fighterB = var_338_1,
			petA = var_338_2,
			petB = var_338_3
		}
	end

	var_0_12.WindowManager.get():openWindow("thief_boss_battle_over", var_338_4, function(arg_339_0)
		if arg_339_0 == nil then
			return
		end

		arg_338_0.battleEndWindow_ = arg_339_0

		cc.EventProxy.new(arg_338_0.battleEndWindow_, arg_338_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_340_0)
			arg_338_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishOccultBattle(arg_342_0, arg_342_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
	arg_342_0:clearFormation(true)

	local var_342_0 = arg_342_1

	var_0_12.WindowManager.get():openWindow("single_day_battle_result", var_342_0, function(arg_343_0)
		if arg_343_0 == nil then
			return
		end

		arg_342_0.battleEndWindow_ = arg_343_0

		cc.EventProxy.new(arg_342_0.battleEndWindow_, arg_342_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_344_0)
			arg_342_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.finishSingleDayBattle(arg_346_0, arg_346_1)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleTopWnd)
	var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleBottomWnd)
	arg_346_0:clearFormation(true)

	local var_346_0 = arg_346_1

	var_0_12.WindowManager.get():openWindow("single_day_battle_result", var_346_0, function(arg_347_0)
		if arg_347_0 == nil then
			return
		end

		arg_346_0.battleEndWindow_ = arg_347_0

		cc.EventProxy.new(arg_346_0.battleEndWindow_, arg_346_0.battleEndWindow_):addEventListener(var_0_12.event.BATTLE_END_BACK_TO_MAIN, function(arg_348_0)
			arg_346_0:closeBattleEndWindow(function()
				var_0_12.WindowManager.get():closeAllWindows()
				var_0_13.ctx.battle.releaseCache()
				cc.Director:getInstance():popScene()
			end)
		end)
	end)
end

function var_0_0.setupWindows(arg_350_0)
	local var_350_0 = {
		heros = arg_350_0.herosA,
		pets = arg_350_0.petsA
	}

	if arg_350_0.location and arg_350_0.location == 0 then
		var_350_0.heros = arg_350_0.herosB
		var_350_0.pets = arg_350_0.petsB
	end

	arg_350_0.battleBottomWindow = var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleBottomWnd, var_350_0)
	arg_350_0.battleTopWindow = var_0_12.WindowManager.get():openWindow(var_0_12.WindowName.battleTopWnd)

	if arg_350_0.battleBottomWindow and arg_350_0.campaignType == var_0_12.CampaignType.MARCH then
		arg_350_0.battleBottomWindow:getMedicine():show()
		arg_350_0.battleBottomWindow:getMedicineNum():setString(arg_350_0.medicineNum)
	end

	if arg_350_0.battleTopWindow ~= nil then
		arg_350_0.battleTopWindow:getAwakeDamage():hide()
		arg_350_0.battleTopWindow:getAwakeSelfKill():hide()

		if arg_350_0.isAwakeCampaign then
			if arg_350_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
				arg_350_0.battleTopWindow:getAwakeSelfKill():show()
				arg_350_0.battleTopWindow:getAwakeSelfKillHeroLabel():setString(arg_350_0.awakeHero:getName())
				arg_350_0.battleTopWindow:getAwakeSelfKillMonsterLabel():setString(var_0_12.tables.hero:name(var_0_12.tables.mission:challengeNums(arg_350_0.awakeMissionID)))
			elseif arg_350_0.awakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				arg_350_0.battleTopWindow:getAwakeDamage():show()
				arg_350_0.battleTopWindow:getAwakeDamageBar():setPercent(0)
				arg_350_0.battleTopWindow:getAwakeDamageLabel():setString(var_0_12.tables.mission:challengeNums(arg_350_0.awakeMissionID))
			end
		end

		if arg_350_0.isPetAwakeCampaign then
			if arg_350_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.SELF_KILL then
				arg_350_0.battleTopWindow:getAwakeSelfKill():show()
				arg_350_0.battleTopWindow:getAwakeSelfKillHeroLabel():setString(arg_350_0.awakePet:getName())
				arg_350_0.battleTopWindow:getAwakeSelfKillMonsterLabel():setString(var_0_12.tables.hero:name(var_0_12.tables.mission:challengeNums(arg_350_0.petAwakeMissionID)))
			elseif arg_350_0.petAwakeMissionGoalType == var_0_12.AwakeStage3MissionType.DAMAGE_ACHIEVE then
				arg_350_0.battleTopWindow:getAwakeDamage():show()
				arg_350_0.battleTopWindow:getAwakeDamageBar():setPercent(0)
				arg_350_0.battleTopWindow:getAwakeDamageLabel():setString(var_0_12.tables.mission:challengeNums(arg_350_0.petAwakeMissionID))
				arg_350_0.battleTopWindow:getAwakeDamageLabel():setColor(cc.c3b(0, 0, 0))
			end
		end

		if arg_350_0:isPausable() then
			cc.EventProxy.new(arg_350_0.battleTopWindow, arg_350_0.battleTopWindow):addEventListener(var_0_12.event.EXIT_BATTLE, function(arg_351_0)
				var_0_13.ctx.battle.isEnd = true

				arg_350_0:pauseBattle()
				arg_350_0:sendBattleResult(true)
			end):addEventListener(var_0_12.event.BATTLE_PAUSED, function()
				arg_350_0:pauseBattle()
			end):addEventListener(var_0_12.event.BATTLE_RESUMED, function()
				if arg_350_0.handler == nil and arg_350_0.isBattleEnded_ ~= true then
					arg_350_0:startBattle()
				end
			end)
		end

		if arg_350_0:isShowPauseBtn() then
			arg_350_0.battleTopWindow:showPauseButton()
		else
			arg_350_0.battleTopWindow:hidePauseButton()
		end
	end

	if arg_350_0.battleBottomWindow then
		local var_350_1 = arg_350_0.battleBottomWindow:nextBattleBtn()

		var_350_1:setTouchEnabled(true)
		var_350_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_354_0)
			if arg_354_0.name == "ended" then
				arg_350_0:clickNextBattle()
			end

			return true
		end)
	end
end

function var_0_0.autoBtnClick(arg_355_0)
	if var_0_13.ctx.battle.autoA then
		arg_355_0.autoBtn_:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_355_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	end

	var_0_13.ctx.battle.autoA = not var_0_13.ctx.battle.autoA

	if var_0_12.StoryData.get():getGuideID() == var_0_12.GuideStoryType.GUIDE_FIGHT_3_END then
		if var_0_12.WindowManager.get():isWindowOpen("guide") then
			var_0_12.WindowManager.get():closeWindow("guide")
		end

		var_0_13.ctx.battle.resumeAllFighter()
		arg_355_0:startBattle()
	end
end

function var_0_0.setupButtons(arg_356_0)
	arg_356_0.autoBtn_ = arg_356_0.battleBottomWindow:getAutoBtn()

	if arg_356_0.battleType == var_0_12.BattleType.ReplayReport then
		arg_356_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
		arg_356_0.autoBtn_:addTouchEventListener(function(arg_357_0, arg_357_1)
			if arg_357_1 == ccui.TouchEventType.ended then
				arg_356_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)

				local var_357_0 = var_0_2:translation("AUTO_BATTLE_TIP3")

				var_0_12.WindowManager.get():openWindow("toast", {
					message = var_357_0
				})
			end
		end)
	elseif arg_356_0.campaignType == var_0_12.CampaignType.ARENA or arg_356_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_356_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_356_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_356_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_356_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD or arg_356_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT then
		arg_356_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
		arg_356_0.autoBtn_:addTouchEventListener(function(arg_358_0, arg_358_1)
			if arg_358_1 == ccui.TouchEventType.ended then
				arg_356_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)

				local var_358_0 = var_0_2:translation("AUTO_BATTLE_TIP2")

				var_0_12.WindowManager.get():openWindow("toast", {
					message = var_358_0
				})
			end
		end)
	elseif arg_356_0.campaignType == var_0_12.CampaignType.NORMAL and arg_356_0.campaignID < var_0_12.tables.misc.autoBattleOpenCampaign then
		arg_356_0.autoBtn_:setBright(false)
		arg_356_0.autoBtn_:addTouchEventListener(function(arg_359_0, arg_359_1)
			if arg_359_1 == ccui.TouchEventType.ended then
				local var_359_0 = var_0_2:translation("AUTO_BATTLE_TIP1")

				var_0_12.WindowManager.get():openWindow("toast", {
					message = var_359_0
				})
			end
		end)
	else
		arg_356_0.battleBottomWindow:getLockIcon():hide()
		arg_356_0.autoBtn_:addTouchEventListener(function(arg_360_0, arg_360_1)
			if arg_360_1 == ccui.TouchEventType.ended then
				arg_356_0:autoBtnClick()
			end
		end)
	end

	if var_0_13.ctx.battle.autoA then
		arg_356_0.autoBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	end

	arg_356_0.speedBtn_ = arg_356_0.battleBottomWindow:getSpeedBtn()

	arg_356_0.speedBtn_:addTouchEventListener(function(arg_361_0, arg_361_1)
		if arg_361_1 == ccui.TouchEventType.ended then
			if var_0_13.ctx.battle.timeScale == 1 then
				var_0_13.ctx.battle.timeScale = 1.5

				arg_356_0.speedBtn_:setBrightStyle(ccui.BrightStyle.highlight)
			else
				var_0_13.ctx.battle.timeScale = 1

				arg_356_0.speedBtn_:setBrightStyle(ccui.BrightStyle.normal)
			end

			arg_356_0:setAnimationInterval()
			arg_356_0:setTimeScale(var_0_13.ctx.battle.timeScale)
		end
	end)

	if var_0_13.ctx.battle.timeScale == 1 then
		arg_356_0.speedBtn_:setBrightStyle(ccui.BrightStyle.normal)
	else
		arg_356_0.speedBtn_:setBrightStyle(ccui.BrightStyle.highlight)
	end

	if arg_356_0.selfPlayer.lev < tonumber(var_0_12.tables.misc:getValue("speed_up_open_level")) or arg_356_0.campaignType == var_0_12.CampaignType.SUMMER_FIGHT_BOSS then
		arg_356_0.speedBtn_:setVisible(false)
	end
end

function var_0_0.closeBattleEndWindow(arg_362_0, arg_362_1)
	arg_362_0.battleEndWindow_ = nil

	if var_0_12.WindowManager.get():isWindowOpen(var_0_12.WindowName.battleLoseWnd) then
		var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleLoseWnd, arg_362_1)
	else
		var_0_12.WindowManager.get():closeWindow(var_0_12.WindowName.battleWinWnd, arg_362_1)
	end

	var_0_12.EventDispatcher.get():dispatchEvent({
		name = var_0_12.event.UPDATE_STONE_EQUIP_CAMPAIGN,
		params = {}
	})
end

function var_0_0.isPausable(arg_363_0)
	if arg_363_0.campaignType == var_0_12.CampaignType.PLAYOFFS then
		return false
	end

	if arg_363_0.battleType == var_0_12.BattleType.ReplayReport then
		return true
	end

	if arg_363_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_363_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_363_0.campaignType == var_0_12.CampaignType.TREASURE or arg_363_0.campaignType == var_0_12.CampaignType.GUILD or arg_363_0.campaignType == var_0_12.CampaignType.ELEMENT or arg_363_0.campaignType == var_0_12.CampaignType.NIAN_BOSS or arg_363_0.campaignType == var_0_12.CampaignType.THIEF_BOSS or arg_363_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_363_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_363_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT then
		return false
	end

	return true
end

function var_0_0.isShowPauseBtn(arg_364_0)
	if arg_364_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_364_0.campaignType == var_0_12.CampaignType.OCCULT or arg_364_0.campaignType == var_0_12.CampaignType.OCCULT_COOPERATION then
		return false
	end

	if var_0_12.StoryData.get():getGuideID() <= var_0_12.GuideStoryType.END_NORMAL_FIGHT_ID then
		return false
	end

	if arg_364_0.campaignType == var_0_12.CampaignType.SUMMER_FIGHT_BOSS and not arg_364_0.isWatchReplay then
		return false
	end

	if arg_364_0.battleType == var_0_12.BattleType.ReplayReport and (arg_364_0.campaignType ~= var_0_12.CampaignType.REGION_ARENA or arg_364_0.isWatchReplay or var_0_13.ctx.battle.count >= 900) then
		return true
	end

	if arg_364_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_364_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_364_0.campaignType == var_0_12.CampaignType.TREASURE or arg_364_0.campaignType == var_0_12.CampaignType.GUILD or arg_364_0.campaignType == var_0_12.CampaignType.ELEMENT or arg_364_0.campaignType == var_0_12.CampaignType.NIAN_BOSS or arg_364_0.campaignType == var_0_12.CampaignType.THIEF_BOSS or arg_364_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_364_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_364_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT or arg_364_0.campaignType == var_0_12.CampaignType.ILLUSION or arg_364_0.campaignType == var_0_12.CampaignType.ZHUGE_ENEMY or arg_364_0.campaignType == var_0_12.CampaignType.ADVENTURE_ILLUSION_SINGLE or arg_364_0.campaignType == var_0_12.CampaignType.ADVENTURE_DEFENSE then
		return false
	end

	return true
end

function var_0_0.checkWindowState(arg_365_0)
	if var_0_13.ctx.battle.count == 900 then
		if arg_365_0:isShowPauseBtn() then
			arg_365_0.battleTopWindow:showPauseButton()
		else
			arg_365_0.battleTopWindow:hidePauseButton()
		end
	end
end

function var_0_0.isArena(arg_366_0)
	return arg_366_0.campaignType == var_0_12.CampaignType.ARENA or arg_366_0.campaignType == var_0_12.CampaignType.ARENA_MODE or arg_366_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_366_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_366_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_366_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_366_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD or arg_366_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT
end

function var_0_0.isAutoA(arg_367_0)
	if arg_367_0.battleType == var_0_12.BattleType.ReplayReport or arg_367_0.battleType == var_0_12.BattleType.CreateReport then
		return true
	end

	if arg_367_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_367_0.campaignType == var_0_12.CampaignType.ARENA or arg_367_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_367_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_367_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_367_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD or arg_367_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT then
		return true
	end

	if var_0_12.db.campaignAutoStatus:getCampaignAutoStatus(arg_367_0.campaignType) then
		return true
	end

	return false
end

function var_0_0.recordAutoStatus(arg_368_0)
	if arg_368_0.battleType == var_0_12.BattleType.ReplayReport or arg_368_0.battleType == var_0_12.BattleType.CreateReport then
		return
	end

	if arg_368_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_368_0.campaignType == var_0_12.CampaignType.ARENA or arg_368_0.campaignType == var_0_12.CampaignType.REGION_ARENA or arg_368_0.campaignType == var_0_12.CampaignType.GUILD_ARENA or arg_368_0.campaignType == var_0_12.CampaignType.PLAYOFFS or arg_368_0.campaignType == var_0_12.CampaignType.PLAYOFFS_RECORD or arg_368_0.campaignType == var_0_12.CampaignType.FRIEND_FIGHT then
		return
	end

	var_0_12.db.campaignAutoStatus:setCampaignAutoStatus(arg_368_0.campaignType, var_0_13.ctx.battle.autoA)
end

function var_0_0.setupMusic(arg_369_0)
	if arg_369_0.canceleMusic_ then
		arg_369_0.canceleMusic_ = nil

		return
	end

	audio.stopMusic()
	audio.stopAllSounds()

	local var_369_0
	local var_369_1 = var_0_12.tables.battle:sounds(arg_369_0.battleID)

	var_369_1 = (not var_369_1 or var_369_1 ~= "") and var_369_1 or var_0_12.tables.sound:getSound("battle_bg_music_1")

	audio.playMusic(var_369_1, true)
end

function var_0_0.setupBackground_(arg_370_0)
	local var_370_0 = "images/maps/map_images/"

	if var_0_13.ctx.battle.background and tolua.isnull(var_0_13.ctx.battle.background) ~= true then
		var_0_13.ctx.battle.background:removeSelf()

		var_0_13.ctx.battle.background = nil
	end

	local var_370_1

	if type(arg_370_0.mapID_) == "number" then
		var_370_1 = var_370_0 .. tostring(arg_370_0.mapID_) .. ".png"
	elseif type(arg_370_0.mapID_) == "string" then
		var_370_1 = arg_370_0.mapID_
	elseif next(arg_370_0.mapID_) and arg_370_0.group_ <= #arg_370_0.mapID_ then
		var_370_1 = var_370_0 .. tostring(arg_370_0.mapID_[arg_370_0.group_]) .. ".png"
	elseif next(arg_370_0.mapID_) then
		var_370_1 = var_370_0 .. tostring(arg_370_0.mapID_[#arg_370_0.mapID_]) .. ".png"
	end

	var_0_13.ctx.battle.background = var_0_12.ColoredSprite.new(var_370_1):align(display.LEFT_BOTTOM, 0, 0):addTo(arg_370_0, -1)

	var_0_13.ctx.battle.background:setOpacity(255)
	var_0_13.ctx.battle.background:setScaleX(arg_370_0:getWidth() / var_0_13.ctx.battle.background:getWidth())
	var_0_13.ctx.battle.background:setScaleY(arg_370_0:getHeight() / var_0_13.ctx.battle.background:getHeight())
end

function var_0_0.buttonHandler(arg_371_0, arg_371_1, arg_371_2, arg_371_3)
	if arg_371_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_371_2)
		arg_371_2:setScale(1)
		var_0_12.playButtonSound()

		if arg_371_1 then
			arg_371_1(arg_371_2, arg_371_3)
		end
	elseif arg_371_3 == ccui.TouchEventType.began then
		local var_371_0 = transition.sequence({
			cc.ScaleTo:create(0.3, 1.5),
			cc.ScaleTo:create(0.3, 1)
		})
		local var_371_1 = cc.RepeatForever:create(var_371_0)

		arg_371_2:runAction(var_371_1)

		return true
	elseif arg_371_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_371_2)
		arg_371_2:setScale(1)
	end
end

function var_0_0.setTotalHurt(arg_372_0)
	for iter_372_0, iter_372_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if not iter_372_1:isDeath() and iter_372_1:getSummonType() == var_0_12.summonMonsterType.None then
			var_0_13.ctx.battle.allFighterHurt = var_0_13.ctx.battle.allFighterHurt + iter_372_1:getHurtHp()

			if not iter_372_1:getParalysis() then
				iter_372_1:setHurtHp(0)
			end
		end
	end

	for iter_372_2, iter_372_3 in ipairs(var_0_13.ctx.battle.teamB) do
		if not iter_372_3:isDeath() and iter_372_3:getSummonType() == var_0_12.summonMonsterType.None then
			var_0_13.ctx.battle.allFighterHurt = var_0_13.ctx.battle.allFighterHurt + iter_372_3:getHurtHp()

			if not iter_372_3:getParalysis() then
				iter_372_3:setHurtHp(0)
			end
		end
	end
end

function var_0_0.mainLoopOfChallenge(arg_373_0)
	if var_0_13.ctx.battle.isSpecialSkill then
		return
	end

	if tolua.isnull(arg_373_0) then
		arg_373_0:pauseBattle()

		return
	end

	if arg_373_0:checkEnds() then
		if arg_373_0.challengeType == var_0_12.ChallengeType.KillSteal then
			arg_373_0.battleTopWindow:nodeByName("text_challenge_kill"):setString(string.format("(%d/%d)", arg_373_0.killTheft_:getKillCount(), var_0_3:killingNumber(arg_373_0.battleID)))
		end

		arg_373_0:processAfterBattleEnd()
		arg_373_0:battleEnd()

		return
	end

	var_0_13.ctx.battle.count = var_0_13.ctx.battle.count + 1

	if var_0_13.ctx.battle.nightCount > 0 and not arg_373_0.stopTimeCount_ then
		var_0_13.ctx.battle.nightCount = math.max(var_0_13.ctx.battle.nightCount - 1, 0)
	end

	if not arg_373_0.stopTimeCount_ then
		var_0_13.ctx.battle.timeCount = var_0_13.ctx.battle.timeCount + 1
	end

	arg_373_0:processChallengePerFrame()
	arg_373_0:checkBlackLayerState()
	arg_373_0:adjustYs()

	for iter_373_0, iter_373_1 in ipairs(var_0_13.ctx.battle.teamA) do
		iter_373_1:singleLoop()
	end

	for iter_373_2, iter_373_3 in ipairs(var_0_13.ctx.battle.teamB) do
		iter_373_3:singleLoop()
	end

	if var_0_13.ctx.battle.isCountHurtNum then
		arg_373_0:setTotalHurt()
	end

	arg_373_0:updateInfoListener()
	arg_373_0:updateWalk2Next()
	var_0_13.ctx.battle.popSoundQueue()

	if not arg_373_0.stopTimeCount_ and var_0_13.ctx.battle.timeCount % 30 == 0 then
		local var_373_0 = var_0_13.ctx.battleConst.seconds - var_0_13.ctx.battle.timeCount
		local var_373_1 = var_0_17(var_373_0 / 1800)
		local var_373_2 = var_0_17(var_373_0 % 1800 / 30)
		local var_373_3 = string.format("%02d:%02d", var_373_1, var_373_2)

		arg_373_0.battleTopWindow:getTimeLabel():setString(var_373_3)
	end
end

function var_0_0.processChallengePerFrame(arg_374_0)
	if arg_374_0.teamBJoinCount_[1] and var_0_13.ctx.battle.count >= arg_374_0.teamBJoinCount_[1] then
		table.remove(arg_374_0.teamBJoinCount_, 1)

		local var_374_0 = table.remove(arg_374_0.secondTeamB_, 1)

		arg_374_0.secondTeamIndex_ = (arg_374_0.secondTeamIndex_ or 0) + 1

		local var_374_1 = arg_374_0.secondTeamIndex_ % 2 > 0 and var_0_12.Direction.Left or var_0_12.Direction.Right

		var_374_1 = arg_374_0.challengeType == var_0_12.ChallengeType.BackwardSecondTeam and var_374_1

		local var_374_2 = 0

		for iter_374_0 = 1, #var_374_0 do
			local var_374_3 = var_374_0[iter_374_0]

			var_374_3.fighterModel:show()

			var_374_3.fighterIndex = "B|" .. #var_0_13.ctx.battle.teamB + 1
			var_374_2 = var_374_3:setFormation(iter_374_0, var_374_2, 10 - iter_374_0, var_374_1)

			var_374_3:setFormationDelay(var_0_12.tables.battleConfig.skillDelayQueue[iter_374_0], var_0_12.tables.battleConfig.formationWalkQueue[iter_374_0])
			var_374_3:getFighterModel():setFlipX(not var_374_1)
			table.insert(var_0_13.ctx.battle.yOrder, var_374_3)
			table.insert(var_0_13.ctx.battle.teamB, var_374_3)
		end
	end

	if arg_374_0.challengeType == var_0_12.ChallengeType.LimitTime and next(arg_374_0:getInfoByKey("death_info")) then
		local var_374_4 = var_0_3:timeLimit(arg_374_0.battleID)[arg_374_0.group_] or var_0_3:timeLimit(arg_374_0.battleID)[1]

		if var_374_4 < var_0_13.ctx.battleConst.seconds - var_0_13.ctx.battle.timeCount then
			for iter_374_1, iter_374_2 in ipairs(arg_374_0:getInfoByKey("death_info")) do
				if iter_374_2:getTeamType() == var_0_12.TeamType.B and iter_374_2:getSummonType() == var_0_12.summonMonsterType.None then
					var_0_13.ctx.battle.timeCount = var_0_13.ctx.battleConst.seconds - var_374_4
				end
			end
		end
	end

	if arg_374_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst and next(arg_374_0:getInfoByKey("death_info")) then
		for iter_374_3, iter_374_4 in ipairs(arg_374_0:getInfoByKey("death_info")) do
			if iter_374_4:getTeamType() == var_0_12.TeamType.B and iter_374_4:getSummonType() == var_0_12.summonMonsterType.None and iter_374_4.isLeader_ then
				for iter_374_5, iter_374_6 in ipairs(var_0_13.ctx.battle.teamB) do
					if not iter_374_6:isDeath() then
						iter_374_6.isImmortal_ = nil
					end
				end

				break
			end
		end
	end

	if arg_374_0.challengeType == var_0_12.ChallengeType.OneHeroKillAll and var_0_13.ctx.battle.timeCount % 15 < 1 then
		for iter_374_7, iter_374_8 in ipairs(var_0_13.ctx.battle.teamA) do
			if not iter_374_8:isDeath() and iter_374_8:getSummonType() == var_0_12.summonMonsterType.None then
				iter_374_8:updateEnergyBy(var_0_12.tables.battleConfig.challengeRemp, 0.5)
			end
		end
	end

	if arg_374_0.challengeType == var_0_12.ChallengeType.KillSteal and next(arg_374_0:getInfoByKey("death_info")) then
		for iter_374_9, iter_374_10 in ipairs(arg_374_0:getInfoByKey("death_info")) do
			if iter_374_10:getTeamType() == var_0_12.TeamType.B and iter_374_10:getSummonType() == var_0_12.summonMonsterType.None then
				arg_374_0.battleTopWindow:nodeByName("text_challenge_kill"):setString(string.format("(%d/%d)", arg_374_0.killTheft_:getKillCount(), var_0_3:killingNumber(arg_374_0.battleID)))
			end
		end
	end
end

function var_0_0.getSuperArenaBattleStar(arg_375_0)
	if not arg_375_0.timeOut_ then
		return arg_375_0:getDefaultBattleStar()
	end

	if arg_375_0:getAliveCount(var_0_13.ctx.battle.teamA) > arg_375_0:getAliveCount(var_0_13.ctx.battle.teamB) then
		arg_375_0.battleStar_ = 1

		return 1
	elseif arg_375_0:getAliveCount(var_0_13.ctx.battle.teamA) < arg_375_0:getAliveCount(var_0_13.ctx.battle.teamB) then
		arg_375_0.battleStar_ = 0

		return 0
	else
		arg_375_0.battleStar_ = arg_375_0:getTotalHarms(var_0_13.ctx.battle.teamA) >= arg_375_0:getTotalHarms(var_0_13.ctx.battle.teamB) and 1 or 0

		return arg_375_0.battleStar_
	end
end

function var_0_0.getMarchBattleStar(arg_376_0)
	if arg_376_0.timeOut_ then
		arg_376_0.battleStar_ = 1

		return 1
	end

	return arg_376_0:getDefaultBattleStar()
end

function var_0_0.getChallengeBattleStar(arg_377_0)
	if arg_377_0.challengeType == var_0_12.ChallengeType.Protect then
		for iter_377_0, iter_377_1 in ipairs(var_0_13.ctx.battle.teamA) do
			if iter_377_1.isChallengeProtected_ and iter_377_1:isDeath() then
				arg_377_0.battleStar_ = 0

				return 0
			end
		end
	elseif arg_377_0.challengeType == var_0_12.ChallengeType.KillSteal then
		for iter_377_2, iter_377_3 in ipairs(var_0_13.ctx.battle.teamA) do
			if iter_377_3.isChallengeKillSteal_ and iter_377_3:getKillCount() < var_0_3:killingNumber(arg_377_0.battleID) then
				arg_377_0.battleStar_ = 0

				return 0
			end
		end
	elseif arg_377_0.challengeType == var_0_12.ChallengeType.LimitTime then
		-- block empty
	elseif arg_377_0.challengeType == var_0_12.ChallengeType.SecondTeam then
		-- block empty
	elseif arg_377_0.challengeType == var_0_12.ChallengeType.OneHeroKillAll then
		-- block empty
	elseif arg_377_0.challengeType == var_0_12.ChallengeType.KillLeaderFirst then
		-- block empty
	end

	return arg_377_0:getDefaultBattleStar()
end

function var_0_0.getDefaultBattleStar(arg_378_0)
	if not arg_378_0.isBattleEnded_ or arg_378_0.timeOut_ then
		arg_378_0.battleStar_ = 0

		return 0
	end

	if arg_378_0.isAssist then
		arg_378_0.battleStar_ = 3

		return 3
	end

	local var_378_0 = 0

	for iter_378_0, iter_378_1 in pairs(var_0_13.ctx.battle.teamA) do
		if iter_378_1:isDeath() and iter_378_1.summonType_ == var_0_12.summonMonsterType.None then
			var_378_0 = var_378_0 + 1
		end
	end

	if var_378_0 == 0 then
		if arg_378_0.rentFlag_ then
			arg_378_0.battleStar_ = 2

			return 2
		else
			arg_378_0.battleStar_ = 3

			return 3
		end
	elseif var_378_0 == 1 and var_378_0 < #arg_378_0.herosA then
		arg_378_0.battleStar_ = 2

		return 2
	elseif var_378_0 >= 2 and var_378_0 < #arg_378_0.herosA then
		arg_378_0.battleStar_ = 1

		return 1
	else
		arg_378_0.battleStar_ = 0

		return 0
	end
end

function var_0_0.getTotalHarms(arg_379_0, arg_379_1)
	local var_379_0 = 0

	for iter_379_0, iter_379_1 in ipairs(arg_379_1) do
		if iter_379_1:getSummonType() == var_0_12.summonMonsterType.None then
			var_379_0 = var_379_0 + iter_379_1.harms
		end
	end

	return var_379_0
end

function var_0_0.getAliveCount(arg_380_0, arg_380_1)
	local var_380_0 = 0

	for iter_380_0, iter_380_1 in ipairs(arg_380_1) do
		if iter_380_1:getSummonType() == var_0_12.summonMonsterType.None and (not iter_380_1:isDeath() or iter_380_1:canReborn()) then
			var_380_0 = var_380_0 + 1
		end
	end

	return var_380_0
end

function var_0_0.getBattleStar(arg_381_0)
	if var_0_12.BattleType.ReplayReport == var_0_13.ctx.battle.battleType then
		return arg_381_0.reportStar_
	end

	if arg_381_0.battleStar_ and arg_381_0.battleStar_ >= 0 then
		return arg_381_0.battleStar_
	end

	if arg_381_0.campaignType == var_0_12.CampaignType.MARCH or arg_381_0.campaignType == var_0_12.CampaignType.TREASURE then
		return arg_381_0:getMarchBattleStar()
	elseif arg_381_0.campaignType == var_0_12.CampaignType.SUPER_ARENA or arg_381_0.campaignType == var_0_12.CampaignType.GUILD_ARENA then
		return arg_381_0:getSuperArenaBattleStar()
	elseif arg_381_0.campaignType == var_0_12.CampaignType.CHALLENGE then
		return arg_381_0:getChallengeBattleStar()
	end

	return arg_381_0:getDefaultBattleStar()
end

function var_0_0.listenInfo(arg_382_0, arg_382_1)
	var_0_13.ctx.battle.infoListener[arg_382_1] = var_0_13.ctx.battle.infoListener[arg_382_1] or {}
	var_0_13.ctx.battle.infoList[arg_382_1] = {}
end

function var_0_0.getInfoByKey(arg_383_0, arg_383_1)
	return var_0_13.ctx.battle.infoList[arg_383_1]
end

function var_0_0.getMaxHarmHero(arg_384_0)
	if not var_0_13.ctx.battle.teamA or not next(var_0_13.ctx.battle.teamA) then
		return nil
	end

	local var_384_0
	local var_384_1 = 0

	for iter_384_0, iter_384_1 in ipairs(var_0_13.ctx.battle.teamA) do
		if var_384_1 < iter_384_1.harms then
			var_384_1 = iter_384_1.harms
			var_384_0 = iter_384_1.hero_
		end
	end

	if not var_384_0 or var_384_1 <= 0 then
		return nil
	end

	return var_384_0
end

return var_0_0
