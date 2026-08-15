local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = require("lib.battle.requireServer")
local var_0_2 = require("lib.battle.requireClient")

return {
	new = function(arg_1_0)
		local var_1_0 = var_0_0.getXinyoudi(ngx)

		if not ngx then
			ngx = {
				ctx = {}
			}
		end

		local var_1_1 = ngx

		var_1_1.ctx.battle = var_1_1.ctx.battle or {}
		var_1_1.ctx.battle.teamA = var_1_1.ctx.battle.teamA or {}
		var_1_1.ctx.battle.teamB = var_1_1.ctx.battle.teamB or {}
		var_1_1.ctx.battle.subTeam = var_1_1.ctx.battle.subTeam or {}
		var_1_1.ctx.battle.schoolSceneFighter = nil
		var_1_1.ctx.battle.summonMonsters = {}
		var_1_1.ctx.battle.summonMonsterNum = {}
		var_1_1.ctx.battle.globalBuffsA = {}
		var_1_1.ctx.battle.globalBuffsB = {}
		var_1_1.ctx.battle.globalBuffs = {}
		var_1_1.ctx.battle.yOrder = {}
		var_1_1.ctx.battle.applyUnits = {}
		var_1_1.ctx.battle.moveUnits = {}
		var_1_1.ctx.battle.moveAttackUnits = {}
		var_1_1.ctx.battle.count = 0
		var_1_1.ctx.battle.isSpecialSkill = false
		var_1_1.ctx.battle.timeCount = 0
		var_1_1.ctx.battle.soundQueue = var_1_1.ctx.battle.soundQueue or {}
		var_1_1.ctx.battle.isEnergySkilling = false
		var_1_1.ctx.battle.playerLayer = nil
		var_1_1.ctx.battle.unitLayer = nil
		var_1_1.ctx.battle.blackLayer = nil
		var_1_1.ctx.battle.unitBottomLayer = nil
		var_1_1.ctx.battle.battleType = 0
		var_1_1.ctx.battle.autoA = true
		var_1_1.ctx.battle.autoB = true
		var_1_1.ctx.battle.walk2NextBattle_ = false
		var_1_1.ctx.battle.dropAwardCount = 0
		var_1_1.ctx.battle.dropManaCount = 0
		var_1_1.ctx.battle.isEnd = true
		var_1_1.ctx.battle.reportData = nil
		var_1_1.ctx.battle.guildNormalDrop = {}
		var_1_1.ctx.battle.campaignType = nil
		var_1_1.ctx.battle.spineCache = {}
		var_1_1.ctx.battle.spinePlayCache = {}
		var_1_1.ctx.battle.allFighterHurt = 0
		var_1_1.ctx.battle.chapter = nil
		var_1_1.ctx.battle.isCountHurtNum = false
		var_1_1.ctx.battle.background = nil
		var_1_1.ctx.battle.infoListener = {}
		var_1_1.ctx.battle.infoList = {}
		var_1_1.ctx.battle.teamAEnd = false
		var_1_1.ctx.battle.teamBEnd = false
		var_1_1.ctx.battle.isUnlimitBattle = false
		var_1_1.ctx.battle.nightCount = 0
		var_1_1.ctx.battle.timeScale = 1
		var_1_1.ctx.battleConst = var_1_1.ctx.battleConst or {}
		var_1_1.ctx.battleConst.PreWalk = 4
		var_1_1.ctx.battleConst.BehindWalk = 6
		var_1_1.ctx.battleConst.seconds = 2700
		var_1_1.ctx.battleConst.unlimiteSeconds = 14400
		var_1_1.ctx.battleConst.guideCampaignId = 10002
		var_1_1.ctx.battleConst.errorIdFightExist = 30005
		var_1_1.ctx.battleConst.errorIdTimeEnd = 30021
		var_1_1.ctx.battleConst.frames = 30
		var_1_1.ctx.battleConst.secondsPerFrame = 0.03333333333333333
		var_1_1.ctx.battleConst.loopsPerFrame = 100

		function var_1_1.ctx.battle.pushSoundQueue(arg_2_0)
			if not arg_2_0 and arg_2_0 == "" then
				return
			end

			for iter_2_0, iter_2_1 in ipairs(var_1_1.ctx.battle.soundQueue) do
				if iter_2_1 == arg_2_0 then
					return
				end
			end

			table.insert(var_1_1.ctx.battle.soundQueue, arg_2_0)
		end

		function var_1_1.ctx.battle.popSoundQueue()
			while next(var_1_1.ctx.battle.soundQueue) do
				if var_1_0.BattleType.CreateReport ~= var_1_1.ctx.battle.battleType then
					audio.playSound(var_1_1.ctx.battle.soundQueue[1], false)
				end

				table.remove(var_1_1.ctx.battle.soundQueue, 1)
			end
		end

		function var_1_1.ctx.battle.updateZorder()
			if next(var_1_1.ctx.battle.yOrder) == nil then
				return
			end

			table.sort(var_1_1.ctx.battle.yOrder, function(arg_5_0, arg_5_1)
				return arg_5_0:getY() > arg_5_1:getY()
			end)

			for iter_4_0 = 1, #var_1_1.ctx.battle.yOrder do
				var_1_1.ctx.battle.yOrder[iter_4_0].fighterModel:setLocalZOrder(iter_4_0)
			end
		end

		function var_1_1.ctx.battle.stopAllFighter()
			for iter_6_0, iter_6_1 in pairs(var_1_1.ctx.battle.teamA) do
				if not iter_6_1.acttionInBlack_ and not iter_6_1:isDeath() and iter_6_1:canBeStop() then
					iter_6_1:setMaskColor()
					iter_6_1:pause()
				end
			end

			for iter_6_2, iter_6_3 in pairs(var_1_1.ctx.battle.teamB) do
				if not iter_6_3.acttionInBlack_ and not iter_6_3:isDeath() and iter_6_3:canBeStop() then
					iter_6_3:setMaskColor()
					iter_6_3:pause()
				end
			end

			local var_6_0 = var_1_1.ctx.battle.unitLayer:getChildren()

			for iter_6_4, iter_6_5 in ipairs(var_6_0) do
				iter_6_5:pause()
				iter_6_5:setMaskColor()
			end

			local var_6_1 = var_1_1.ctx.battle.unitBottomLayer:getChildren()

			for iter_6_6, iter_6_7 in ipairs(var_6_1) do
				iter_6_7:pause()
				iter_6_7:setMaskColor()
			end
		end

		function var_1_1.ctx.battle.pauseAndDuskAllEffectAllRole(arg_7_0)
			local var_7_0 = arg_7_0 or {}

			for iter_7_0, iter_7_1 in pairs(var_1_1.ctx.battle.teamA) do
				if not iter_7_1:isDeath() and not var_0_0.table.keyof(var_7_0, iter_7_1) then
					iter_7_1:setMaskColor()
					iter_7_1:pause()
				end
			end

			for iter_7_2, iter_7_3 in pairs(var_1_1.ctx.battle.teamB) do
				if not iter_7_3:isDeath() and not var_0_0.table.keyof(var_7_0, iter_7_3) then
					iter_7_3:setMaskColor()
					iter_7_3:pause()
				end
			end

			local var_7_1 = var_1_1.ctx.battle.unitLayer:getChildren()

			for iter_7_4, iter_7_5 in ipairs(var_7_1) do
				iter_7_5:setMaskColor()
				iter_7_5:pause()
			end

			local var_7_2 = var_1_1.ctx.battle.unitBottomLayer:getChildren()

			for iter_7_6, iter_7_7 in ipairs(var_7_2) do
				iter_7_7:setMaskColor()
				iter_7_7:pause()
			end
		end

		function var_1_1.ctx.battle.resumeAllFighter()
			for iter_8_0, iter_8_1 in pairs(var_1_1.ctx.battle.teamA) do
				if not iter_8_1:isDeath() then
					if iter_8_1:isPause() then
						iter_8_1:getFighterModel():setGrayScale(0.7)
						iter_8_1.fighterModel:unsetBackMaskColor()
						iter_8_1:resume({
							no_model = true
						})
					elseif iter_8_1.fighterModel.filterBuff_ then
						iter_8_1:getFighterModel():setMaskColor(iter_8_1.fighterModel.filterBuff_:getFilter().color)
						iter_8_1.fighterModel:unsetBackMaskColor()
						iter_8_1:resume()
					else
						iter_8_1:unsetMaskColor()
						iter_8_1:resume()
					end

					iter_8_1.acttionInBlack_ = nil
				end
			end

			for iter_8_2, iter_8_3 in pairs(var_1_1.ctx.battle.teamB) do
				if not iter_8_3:isDeath() then
					if iter_8_3:isPause() then
						iter_8_3:getFighterModel():setGrayScale(0.7)
						iter_8_3.fighterModel:unsetBackMaskColor()
						iter_8_3:resume({
							no_model = true
						})
					elseif iter_8_3.fighterModel.filterBuff_ then
						iter_8_3:getFighterModel():setMaskColor(iter_8_3.fighterModel.filterBuff_:getFilter().color)
						iter_8_3.fighterModel:unsetBackMaskColor()
						iter_8_3:resume()
					else
						iter_8_3:unsetMaskColor()
						iter_8_3:resume()
					end

					iter_8_3.acttionInBlack_ = nil
				end
			end

			local var_8_0 = var_1_1.ctx.battle.unitLayer:getChildren()

			for iter_8_4, iter_8_5 in ipairs(var_8_0) do
				iter_8_5:resume()
				iter_8_5:unsetMaskColor()
			end

			local var_8_1 = var_1_1.ctx.battle.unitBottomLayer:getChildren()

			for iter_8_6, iter_8_7 in ipairs(var_8_1) do
				iter_8_7:resume()
				iter_8_7:unsetMaskColor()
			end
		end

		function var_1_1.ctx.battle.getFighter(arg_9_0)
			if var_1_0.BattleType.ReplayReport == var_1_1.ctx.battle.battleType and var_1_1.ctx.battle.summonMonsters[arg_9_0] then
				return var_1_1.ctx.battle.summonMonsters[arg_9_0]
			end

			local var_9_0 = string.sub(arg_9_0, 1, 1)
			local var_9_1 = tonumber(string.sub(arg_9_0, 3))
			local var_9_2

			if var_9_0 == "A" then
				return var_1_1.ctx.battle.teamA[var_9_1]
			end

			return var_1_1.ctx.battle.teamB[var_9_1]
		end

		function var_1_1.ctx.battle.getFighters(arg_10_0)
			local var_10_0 = {}

			for iter_10_0, iter_10_1 in ipairs(arg_10_0 or {}) do
				table.insert(var_10_0, var_1_1.ctx.battle.getFighter(iter_10_1))
			end

			return var_10_0
		end

		function var_1_1.ctx.battle.distributeGuildIteams(arg_11_0)
			if arg_11_0:getTeamType() == var_1_0.TeamType.A or arg_11_0:getSummonType() ~= var_1_0.summonMonsterType.None or not var_1_1.ctx.battle.guildNormalDrop[1] then
				return
			end

			return table.remove(var_1_1.ctx.battle.guildNormalDrop, 1)
		end

		function var_1_1.ctx.battle.adjustX(arg_12_0, arg_12_1)
			arg_12_0 = math.max(arg_12_1:getFighterModel():getWidth() / 2, arg_12_0)

			if not var_1_1.ctx.battle.isUnlimitBattle then
				arg_12_0 = math.min(var_1_0.STAGE_WIDTH - arg_12_1:getFighterModel():getWidth() / 2, arg_12_0)
			else
				arg_12_0 = math.min(var_1_0.UNLIMIT_STAGE_WIDTH - arg_12_1:getFighterModel():getWidth() / 2, arg_12_0)
			end

			return arg_12_0
		end

		function var_1_1.ctx.battle.getSpine(arg_13_0, arg_13_1, arg_13_2)
			local var_13_0
			local var_13_1

			if arg_13_1 == "self" then
				local var_13_2

				var_13_0, var_13_2 = var_1_0.tables.skill:selfResource(arg_13_0)
			elseif arg_13_1 == "area" then
				local var_13_3

				var_13_0, var_13_3 = var_1_0.tables.skill:areaResource(arg_13_0)
			elseif arg_13_1 == "unit" then
				local var_13_4

				var_13_0, var_13_4 = var_1_0.tables.skill:unitResource(arg_13_0)
			elseif arg_13_1 == "hurt" then
				local var_13_5

				var_13_0, var_13_5 = var_1_0.tables.skill:hurtResource(arg_13_0)
			end

			if var_1_1.ctx.battle.battleType == var_1_0.BattleType.CreateReport then
				return var_1_1.ctx.battle.getRequire("BattleBaseNode").new()
			end

			local var_13_6 = var_13_0

			if not var_1_1.ctx.battle.spineCache[var_13_6] then
				var_1_1.ctx.battle.spineCache[var_13_6] = {}
			end

			for iter_13_0 = #var_1_1.ctx.battle.spineCache[var_13_6], 1, -1 do
				if tolua.isnull(var_1_1.ctx.battle.spineCache[var_13_6][iter_13_0]) then
					table.remove(var_1_1.ctx.battle.spineCache[var_13_6], iter_13_0)
				end
			end

			if next(var_1_1.ctx.battle.spineCache[var_13_6]) ~= nil then
				var_1_1.ctx.battle.spineCache[var_13_6][1]:setScale(arg_13_2)

				return table.remove(var_1_1.ctx.battle.spineCache[var_13_6], 1)
			end

			local var_13_7 = var_1_1.ctx.battle.getRequire("SkillEffect").new(arg_13_0, arg_13_1, 1)

			var_13_7:setScale(arg_13_2)

			var_1_1.ctx.battle.spinePlayCache[var_13_6] = var_1_1.ctx.battle.spinePlayCache[var_13_6] or {}

			table.insert(var_1_1.ctx.battle.spinePlayCache[var_13_6], var_13_7)

			return var_13_7
		end

		function var_1_1.ctx.battle.preloadSpine(arg_14_0)
			if var_1_1.ctx.battle.battleType == var_1_0.BattleType.CreateReport then
				return var_1_1.ctx.battle.getRequire("BattleBaseNode").new()
			end

			if not var_1_1.ctx.battle.spineCache[arg_14_0] then
				var_1_1.ctx.battle.spineCache[arg_14_0] = {}
			end

			for iter_14_0 = #var_1_1.ctx.battle.spineCache[arg_14_0], 1, -1 do
				if tolua.isnull(var_1_1.ctx.battle.spineCache[arg_14_0][iter_14_0]) then
					table.remove(var_1_1.ctx.battle.spineCache[arg_14_0], iter_14_0)
				end
			end

			if next(var_1_1.ctx.battle.spineCache[arg_14_0]) ~= nil then
				return
			end

			arg_14_0 = var_1_0.split(arg_14_0, "%.")[1]

			if arg_14_0:match("web") then
				arg_14_0 = string.sub(arg_14_0, 9)
			else
				arg_14_0 = string.sub(arg_14_0, 5)
			end

			local var_14_0 = var_1_0.split(arg_14_0, "/")

			if var_14_0[#var_14_0] == var_14_0[#var_14_0 - 1] or string.match(var_14_0[#var_14_0], var_14_0[#var_14_0 - 1] .. "pifu" .. "%d*$") then
				return
			end

			local var_14_1 = var_1_1.ctx.battle.getRequire("SkillEffectByPath").new(arg_14_0)

			var_1_1.ctx.battle.cacheSpine(var_14_1)
		end

		function var_1_1.ctx.battle.cacheSpine(arg_15_0)
			if var_1_1.ctx.battle.battleType == var_1_0.BattleType.CreateReport then
				return
			end

			if not arg_15_0 or tolua.isnull(arg_15_0) then
				return
			end

			local var_15_0 = arg_15_0.key

			arg_15_0:removeSelf()
			arg_15_0:unsetMaskColor()

			var_1_1.ctx.battle.spinePlayCache[var_15_0] = var_1_1.ctx.battle.spinePlayCache[var_15_0] or {}

			var_0_0.table.removebyvalue(var_1_1.ctx.battle.spinePlayCache[var_15_0], arg_15_0)

			var_1_1.ctx.battle.spineCache[var_15_0] = var_1_1.ctx.battle.spineCache[var_15_0] or {}

			if not var_0_0.table.keyof(var_1_1.ctx.battle.spineCache[var_15_0], arg_15_0) then
				table.insert(var_1_1.ctx.battle.spineCache[var_15_0], arg_15_0)
			end
		end

		function var_1_1.ctx.battle.releaseCache()
			if var_1_1.ctx.battle.battleType == var_1_0.BattleType.CreateReport then
				return
			end

			for iter_16_0, iter_16_1 in pairs(var_1_1.ctx.battle.spineCache) do
				for iter_16_2, iter_16_3 in ipairs(var_1_1.ctx.battle.spineCache[iter_16_0]) do
					if not tolua.isnull(var_1_1.ctx.battle.spineCache[iter_16_0][iter_16_2]) then
						var_1_1.ctx.battle.spineCache[iter_16_0][iter_16_2]:release()
					end
				end
			end

			var_1_1.ctx.battle.spineCache = {}

			for iter_16_4, iter_16_5 in pairs(var_1_1.ctx.battle.spinePlayCache) do
				for iter_16_6, iter_16_7 in ipairs(var_1_1.ctx.battle.spinePlayCache[iter_16_4]) do
					if not tolua.isnull(var_1_1.ctx.battle.spinePlayCache[iter_16_4][iter_16_6]) then
						var_1_1.ctx.battle.spinePlayCache[iter_16_4][iter_16_6]:release()
					end
				end
			end

			var_1_1.ctx.battle.spinePlayCache = {}
		end

		function var_1_1.ctx.battle.isReleased(arg_17_0)
			if var_1_0.BattleType.CreateReport == var_1_1.ctx.battle.battleType then
				return false
			end

			if not arg_17_0 then
				return false
			end

			return tolua.isnull(arg_17_0)
		end

		function var_1_1.ctx.battle.getRequire(arg_18_0)
			if var_1_0.BattleType.CreateReport == var_1_1.ctx.battle.battleType then
				return var_0_0.import(var_1_1.ctx.battle.requireServer[arg_18_0])
			end

			return var_0_0.import(var_1_1.ctx.battle.requireClient[arg_18_0])
		end

		function var_1_1.ctx.battle.requireFighter(arg_19_0)
			if var_1_0.BattleType.CreateReport == var_1_1.ctx.battle.battleType then
				return var_0_0.import(var_1_1.ctx.battle.serverPath .. arg_19_0)
			end

			return var_0_0.import(var_1_1.ctx.battle.clientPath .. arg_19_0)
		end

		function var_1_1.ctx.battle.setupBackground(arg_20_0, arg_20_1)
			if var_1_1.ctx.battle.battleType == var_1_0.BattleType.CreateReport then
				return
			end

			local var_20_0 = var_1_1.ctx.battle.background

			local function var_20_1()
				if var_20_0 and var_1_1.ctx.battle.isReleased(var_20_0) ~= true then
					var_20_0:removeSelf()
				end
			end

			var_1_1.ctx.battle.background = nil

			local var_20_2 = "images/maps/map_images/" .. arg_20_0
			local var_20_3 = display.getRunningScene()

			var_1_1.ctx.battle.background = var_1_0.ColoredSprite.new(var_20_2):align(display.LEFT_BOTTOM, 0, 0):addTo(var_20_3, -1)

			var_1_1.ctx.battle.background:setOpacity(255)
			var_1_1.ctx.battle.background:setScaleX(var_20_3:getWidth() / var_1_1.ctx.battle.background:getWidth())
			var_1_1.ctx.battle.background:setScaleY(var_20_3:getHeight() / var_1_1.ctx.battle.background:getHeight())

			if arg_20_1 then
				var_1_1.ctx.battle.background:runActionOnce(arg_20_1, false, var_20_1)
			else
				var_20_1()
			end
		end

		function var_1_1.ctx.battle.clearAttrCache(arg_22_0, arg_22_1)
			if type(arg_22_0) ~= "table" then
				return
			end

			if arg_22_0[1] and arg_22_0[1].__cname then
				for iter_22_0, iter_22_1 in ipairs(arg_22_0) do
					if arg_22_1 > 0 then
						iter_22_1.___attrCache[arg_22_1] = nil

						if arg_22_1 == var_1_0.AttributeType.ACK_SPEED then
							iter_22_1.___ackSpeed = nil
						end
					end
				end
			elseif arg_22_0.__cname and arg_22_1 > 0 then
				arg_22_0.___attrCache[arg_22_1] = nil

				if arg_22_1 == var_1_0.AttributeType.ACK_SPEED then
					arg_22_0.___ackSpeed = nil
				end
			end
		end

		var_0_1:new()
		var_0_2:new()
	end
}
