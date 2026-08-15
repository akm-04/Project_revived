local var_0_0 = class("GuildWarWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.guildBattleTable
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = false
local var_0_6 = 60

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.rankList = xyd.ModelManager.get():loadModel(xyd.ModelType.RANK_LIST)
	arg_1_0.freshLimit = -1
end

function var_0_0.checkUpdateForce(arg_2_0)
	if not arg_2_0.guild.hasUpdatedForce then
		local var_2_0 = {
			team_ids = {},
			forces = {}
		}

		for iter_2_0, iter_2_1 in pairs(arg_2_0.guild.troopInfo) do
			local var_2_1 = xyd.splitToNumber(iter_2_1.formation, "|")
			local var_2_2 = iter_2_1.petId
			local var_2_3 = 0

			for iter_2_2, iter_2_3 in pairs(var_2_1) do
				var_2_3 = var_2_3 + arg_2_0.selfPlayer:getHeroByID(iter_2_3):getZhandouli()
			end

			if var_2_2 and var_2_2 ~= 0 then
				var_2_3 = var_2_3 + arg_2_0.selfPlayer:getPetByID(var_2_2):getZhandouli()
			end

			if var_2_3 > 0 then
				table.insert(var_2_0.forces, var_2_3)
				table.insert(var_2_0.team_ids, iter_2_0)
			end
		end

		if #var_2_0.forces > 0 then
			arg_2_0.guild:guildWarUpdateForce(var_2_0, function(arg_3_0)
				if arg_3_0 == xyd.error.OK then
					-- block empty
				end
			end)
		else
			arg_2_0.guild.hasUpdatedForce = true
		end
	end
end

function var_0_0.updateTime(arg_4_0)
	local var_4_0 = xyd.ServerTime.get():getServerTime()
	local var_4_1 = os.date("%m", var_4_0)
	local var_4_2 = os.date("%d", var_4_0)
	local var_4_3 = os.date("%H", var_4_0)
	local var_4_4 = os.date("%M", var_4_0)

	arg_4_0:nodeByName("top_time_text1"):setString(string.format(var_0_2:translation("TEAM_DATA_DATE"), var_4_1, var_4_2) .. "  " .. var_4_3 .. ":" .. var_4_4)
	arg_4_0:nodeByName("top_time_text2"):setString("")

	local var_4_5
	local var_4_6 = var_0_3:step(arg_4_0.guild.warStep)

	arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("NOT_IN_ENROLL"))
	arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("TILL_ENROLL_TIME"))
	arg_4_0:nodeByName("blue_star1"):setVisible(false)
	arg_4_0:nodeByName("blue_star2"):setVisible(false)
	arg_4_0:nodeByName("red_star1"):setVisible(false)
	arg_4_0:nodeByName("red_star2"):setVisible(false)

	if var_0_5 == false then
		arg_4_0:nodeByName("team_btn"):setVisible(false)

		for iter_4_0 = 1, 3 do
			arg_4_0:nodeByName("blue_" .. iter_4_0):setVisible(false)
			arg_4_0:nodeByName("red_" .. iter_4_0):setVisible(false)
		end

		arg_4_0:nodeByName("top_point"):setVisible(false)
		arg_4_0:nodeByName("mid_point"):setVisible(false)
		arg_4_0:nodeByName("down_point"):setVisible(false)
	end

	local var_4_7 = false

	if arg_4_0.guild.isEnrollWar == 0 then
		if var_4_6 == xyd.GuildWarStep.ENROLL then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("IS_ENROLLING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("TILL_ENROLL_OVER"))

			var_4_5 = arg_4_0.guild.warEndTime
		else
			var_4_5 = arg_4_0.guild.warNextStartTime
		end

		if arg_4_0.guild.warEnemy and arg_4_0.guild.warEnemy.guildId == 0 then
			arg_4_0:nodeByName("team_btn"):setVisible(true)
			arg_4_0:nodeByName("team_words"):setVisible(false)

			for iter_4_1 = 1, 3 do
				arg_4_0:nodeByName("blue_" .. iter_4_1):setVisible(true)
				arg_4_0:nodeByName("red_" .. iter_4_1):setVisible(true)
			end

			arg_4_0:updateFlagPos(100, 93)
		elseif arg_4_0.guild.guildWarWin then
			if arg_4_0.guild.guildWarWin == -1 and arg_4_0.guild.warEnemy == nil then
				var_4_7 = true
			else
				arg_4_0:nodeByName("team_btn"):setVisible(true)
				arg_4_0:nodeByName("team_words"):setVisible(false)

				for iter_4_2 = 1, 3 do
					arg_4_0:nodeByName("blue_" .. iter_4_2):setVisible(true)
					arg_4_0:nodeByName("red_" .. iter_4_2):setVisible(true)
				end

				arg_4_0:updateFlagPos(100, 93)
			end
		else
			var_4_7 = true
		end
	else
		if var_4_6 == xyd.GuildWarStep.ENROLL then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("IS_ENROLLING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("TILL_ENROLL_OVER"))

			if arg_4_0.guild.warEnemy and arg_4_0.guild.warEnemy.guildId == 0 then
				arg_4_0:nodeByName("team_btn"):setVisible(true)
				arg_4_0:nodeByName("team_words"):setVisible(false)

				for iter_4_3 = 1, 3 do
					arg_4_0:nodeByName("blue_" .. iter_4_3):setVisible(true)
					arg_4_0:nodeByName("red_" .. iter_4_3):setVisible(true)
				end

				arg_4_0:updateFlagPos(100, 93)
			elseif arg_4_0.guild.guildWarWin then
				if arg_4_0.guild.guildWarWin == -1 and arg_4_0.guild.warEnemy == nil then
					var_4_7 = true
				else
					arg_4_0:nodeByName("team_btn"):setVisible(true)
					arg_4_0:nodeByName("team_words"):setVisible(false)

					for iter_4_4 = 1, 3 do
						arg_4_0:nodeByName("blue_" .. iter_4_4):setVisible(true)
						arg_4_0:nodeByName("red_" .. iter_4_4):setVisible(true)
					end

					arg_4_0:updateFlagPos(100, 93)
				end
			else
				var_4_7 = true
			end
		elseif var_4_6 == xyd.GuildWarStep.MATCH then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("STATE_MATCHING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("STATE_MATCH"))

			var_4_7 = true
		elseif var_4_6 == xyd.GuildWarStep.PREPARE then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("STATE_PREPARING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("STATE_PREPARE"))
			arg_4_0:nodeByName("team_btn"):setVisible(true)
			arg_4_0:nodeByName("self_state"):setVisible(false)

			for iter_4_5 = 1, 3 do
				arg_4_0:nodeByName("blue_" .. iter_4_5):setVisible(true)
				arg_4_0:nodeByName("red_" .. iter_4_5):setVisible(true)
			end
		elseif var_4_6 == xyd.GuildWarStep.WALK then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("STATE_WALKING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("STATE_WALK"))

			for iter_4_6 = 1, 3 do
				arg_4_0:nodeByName("blue_" .. iter_4_6):setVisible(true)
				arg_4_0:nodeByName("red_" .. iter_4_6):setVisible(true)
			end

			local var_4_8 = arg_4_0.guild.warEndTime - arg_4_0.guild.warStartTime
			local var_4_9 = var_4_0 - arg_4_0.guild.warStartTime

			arg_4_0:updateFlagPos(var_4_8, var_4_9)
		elseif var_4_6 == xyd.GuildWarStep.FIGHT then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("STATE_FIGHTING"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("STATE_FIGHT"))
			arg_4_0:nodeByName("team_btn"):setVisible(true)
			arg_4_0:nodeByName("team_words"):setVisible(false)
			arg_4_0:nodeByName("top_point"):setVisible(true)
			arg_4_0:nodeByName("mid_point"):setVisible(true)
			arg_4_0:nodeByName("down_point"):setVisible(true)

			for iter_4_7 = 1, 3 do
				arg_4_0:nodeByName("blue_" .. iter_4_7):setVisible(true)
				arg_4_0:nodeByName("red_" .. iter_4_7):setVisible(true)
			end

			arg_4_0:updateFlagPos(100, 93)
		elseif var_4_6 == xyd.GuildWarStep.ACCOUNT then
			arg_4_0:nodeByName("top_des_words1"):setString(var_0_2:translation("STATE_ACCOUNT"))
			arg_4_0:nodeByName("top_des_words2"):setString(var_0_2:translation("STATE_ACCOUNT"))
			arg_4_0:nodeByName("team_btn"):setVisible(true)
			arg_4_0:nodeByName("team_words"):setVisible(false)

			for iter_4_8 = 1, 3 do
				arg_4_0:nodeByName("blue_" .. iter_4_8):setVisible(true)
				arg_4_0:nodeByName("red_" .. iter_4_8):setVisible(true)
			end

			arg_4_0:updateFlagPos(100, 93)
		end

		var_4_5 = arg_4_0.guild.warEndTime
	end

	if var_4_5 then
		local var_4_10 = var_4_5 - xyd.ServerTime.get():getServerTime()
		local var_4_11 = math.floor((var_4_10 + 60) / xyd.OneDaySec)
		local var_4_12 = math.floor((var_4_10 + 60) % xyd.OneDaySec / 3600)
		local var_4_13 = math.floor((var_4_10 + 60) % 3600 / 60)

		if var_4_10 >= xyd.OneDaySec then
			arg_4_0:nodeByName("top_time_text2"):setString(string.format(var_0_2:translation("ACTIVITY_LEFT_TIME"), var_4_11, var_4_12, var_4_13))
		else
			arg_4_0:nodeByName("top_time_text2"):setString(string.format(var_0_2:translation("GUILD_WAR_LEFT_TIME"), var_4_12, var_4_13))
		end

		if var_4_10 + 6 < 0 then
			arg_4_0.guild:loadGuildWarInfo(function(arg_5_0)
				if arg_4_0.guild.warEndTime - xyd.ServerTime.get():getServerTime() < 0 then
					arg_4_0.freshLimit = 0
				else
					arg_4_0.freshLimit = -1
				end
			end)

			if arg_4_0.freshLimit == var_0_6 then
				arg_4_0.guild:loadGuildWarInfo(function(arg_6_0)
					if arg_4_0.guild.warEndTime - xyd.ServerTime.get():getServerTime() < 0 then
						arg_4_0.freshLimit = 0
					else
						arg_4_0.freshLimit = -1
					end
				end)
			elseif arg_4_0.freshLimit ~= -1 then
				arg_4_0.freshLimit = arg_4_0.freshLimit + 1
			end
		end
	end

	if var_4_7 then
		if var_0_5 == false then
			arg_4_0:nodeByName("red_container"):setVisible(false)
		end

		if arg_4_0.freshState == nil or arg_4_0.freshState ~= 1 then
			arg_4_0:nodeByName("blue_icon"):removeAllChildren()
			xyd.setTeamBorder(arg_4_0.guild.guild_icon, arg_4_0:nodeByName("blue_icon"))

			arg_4_0.freshState = 1
		end

		arg_4_0.side = "blue"
	else
		arg_4_0:nodeByName("red_container"):setVisible(true)

		if arg_4_0.guild.warSide then
			if arg_4_0.guild.warSide == 1 then
				arg_4_0.side = "blue"
			else
				arg_4_0.side = "red"
			end
		else
			arg_4_0.side = "blue"
		end

		if arg_4_0.freshState == nil or arg_4_0.freshState ~= 2 then
			if arg_4_0.side == "blue" then
				arg_4_0:nodeByName("red_icon"):removeAllChildren()

				if arg_4_0.guild.warEnemy then
					if arg_4_0.guild.warEnemy.icon then
						xyd.setTeamBorder(arg_4_0.guild.warEnemy.icon, arg_4_0:nodeByName("red_icon"))
					else
						xyd.setTeamBorder(xyd.tables.misc.teamIcons[1], arg_4_0:nodeByName("red_icon"))
					end
				end
			else
				arg_4_0:nodeByName("blue_icon"):removeAllChildren()

				if arg_4_0.guild.warEnemy then
					if arg_4_0.guild.warEnemy.icon then
						xyd.setTeamBorder(arg_4_0.guild.warEnemy.icon, arg_4_0:nodeByName("blue_icon"))
					else
						xyd.setTeamBorder(xyd.tables.misc.teamIcons[1], arg_4_0:nodeByName("blue_icon"))
					end
				end
			end

			arg_4_0:nodeByName(arg_4_0.side .. "_icon"):removeAllChildren()
			xyd.setTeamBorder(arg_4_0.guild.guild_icon, arg_4_0:nodeByName(arg_4_0.side .. "_icon"))

			arg_4_0.freshState = 2
		end
	end

	local var_4_14
	local var_4_15 = arg_4_0.side == "blue" and "red" or "blue"

	if arg_4_0.guild.guildWarStarEn and arg_4_0.guild.guildWarStarEn ~= 0 then
		arg_4_0:nodeByName(var_4_15 .. "_star1"):setVisible(true)

		if arg_4_0.guild.guildWarStarEn == 2 or arg_4_0.guild.guildWarStarEn == 3 then
			arg_4_0:nodeByName(var_4_15 .. "_star2"):setVisible(true)
		end
	end

	if arg_4_0.guild.guildWarStar and arg_4_0.guild.guildWarStar ~= 0 then
		arg_4_0:nodeByName(arg_4_0.side .. "_star1"):setVisible(true)

		if arg_4_0.guild.guildWarStar == 2 or arg_4_0.guild.guildWarStar == 3 then
			arg_4_0:nodeByName(arg_4_0.side .. "_star2"):setVisible(true)
		end
	end
end

function var_0_0.updateFlagPos(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = 0
	local var_7_1 = arg_7_0:nodeByName("blue_start_top")
	local var_7_2 = arg_7_0:nodeByName("blue_start_mid")
	local var_7_3 = arg_7_0:nodeByName("blue_start_down")
	local var_7_4 = arg_7_0:nodeByName("red_start_top")
	local var_7_5 = arg_7_0:nodeByName("red_start_mid")
	local var_7_6 = arg_7_0:nodeByName("red_start_down")
	local var_7_7 = arg_7_0:nodeByName("mid_point")
	local var_7_8 = arg_7_0:nodeByName("top_point")
	local var_7_9 = arg_7_0:nodeByName("down_point")
	local var_7_10 = arg_7_0:nodeByName("top_turn_point")
	local var_7_11 = arg_7_0:nodeByName("down_turn_point")
	local var_7_12 = arg_7_2 / arg_7_1
	local var_7_13 = 0
	local var_7_14 = 0
	local var_7_15 = 0
	local var_7_16 = ((var_7_10:getPositionX() - var_7_1:getPositionX())^2 + (var_7_10:getPositionY() - var_7_1:getPositionY())^2)^0.5
	local var_7_17 = ((var_7_8:getPositionX() - var_7_10:getPositionX())^2 + (var_7_8:getPositionY() - var_7_10:getPositionY())^2)^0.5
	local var_7_18 = var_7_16 + var_7_17

	if var_7_16 > var_7_18 * var_7_12 then
		local var_7_19 = var_7_18 * var_7_12 / var_7_16

		arg_7_0:nodeByName("blue_1"):setPositionX(var_7_1:getPositionX() + (var_7_10:getPositionX() - var_7_1:getPositionX()) * var_7_19)
		arg_7_0:nodeByName("blue_1"):setPositionY(var_7_1:getPositionY() + (var_7_10:getPositionY() - var_7_1:getPositionY()) * var_7_19)
	else
		local var_7_20 = (var_7_18 * var_7_12 - var_7_16) / var_7_17

		arg_7_0:nodeByName("blue_1"):setPositionX(var_7_10:getPositionX() + (var_7_8:getPositionX() - var_7_10:getPositionX()) * var_7_20)
		arg_7_0:nodeByName("blue_1"):setPositionY(var_7_10:getPositionY() + (var_7_8:getPositionY() - var_7_10:getPositionY()) * var_7_20)
	end

	arg_7_0:nodeByName("blue_2"):setPositionX(var_7_2:getPositionX() + (var_7_7:getPositionX() - var_7_2:getPositionX()) * var_7_12)
	arg_7_0:nodeByName("blue_2"):setPositionY(var_7_2:getPositionY() + (var_7_7:getPositionY() - var_7_2:getPositionY()) * var_7_12)
	arg_7_0:nodeByName("blue_3"):setPositionX(var_7_3:getPositionX() + (var_7_9:getPositionX() - var_7_3:getPositionX()) * var_7_12)
	arg_7_0:nodeByName("blue_3"):setPositionY(var_7_3:getPositionY() + (var_7_9:getPositionY() - var_7_3:getPositionY()) * var_7_12)
	arg_7_0:nodeByName("red_1"):setPositionX(var_7_8:getPositionX() + (var_7_4:getPositionX() - var_7_8:getPositionX()) * (1 - var_7_12))
	arg_7_0:nodeByName("red_1"):setPositionY(var_7_8:getPositionY() + (var_7_4:getPositionY() - var_7_8:getPositionY()) * (1 - var_7_12))
	arg_7_0:nodeByName("red_2"):setPositionX(var_7_7:getPositionX() + (var_7_5:getPositionX() - var_7_7:getPositionX()) * (1 - var_7_12))
	arg_7_0:nodeByName("red_2"):setPositionY(var_7_7:getPositionY() + (var_7_5:getPositionY() - var_7_7:getPositionY()) * (1 - var_7_12))

	local var_7_21 = ((var_7_6:getPositionX() - var_7_11:getPositionX())^2 + (var_7_6:getPositionY() - var_7_11:getPositionY())^2)^0.5
	local var_7_22 = ((var_7_11:getPositionX() - var_7_9:getPositionX())^2 + (var_7_11:getPositionY() - var_7_9:getPositionY())^2)^0.5
	local var_7_23 = var_7_21 + var_7_22

	if var_7_21 > var_7_23 * var_7_12 then
		local var_7_24 = var_7_23 * var_7_12 / var_7_21

		arg_7_0:nodeByName("red_3"):setPositionX(var_7_11:getPositionX() + (var_7_6:getPositionX() - var_7_11:getPositionX()) * (1 - var_7_24))
		arg_7_0:nodeByName("red_3"):setPositionY(var_7_11:getPositionY() + (var_7_6:getPositionY() - var_7_11:getPositionY()) * (1 - var_7_24))
	else
		local var_7_25 = (var_7_23 * var_7_12 - var_7_21) / var_7_22

		arg_7_0:nodeByName("red_3"):setPositionX(var_7_9:getPositionX() + (var_7_11:getPositionX() - var_7_9:getPositionX()) * (1 - var_7_25))
		arg_7_0:nodeByName("red_3"):setPositionY(var_7_9:getPositionY() + (var_7_11:getPositionY() - var_7_9:getPositionY()) * (1 - var_7_25))
	end

	local var_7_26 = var_0_3:step(arg_7_0.guild.warStep)

	if arg_7_0.guild.guildWarWin and var_7_26 ~= xyd.GuildWarStep.WALK then
		local var_7_27 = "blue"
		local var_7_28 = "red"

		if arg_7_0.guild.warSide then
			if arg_7_0.guild.warSide == 1 then
				var_7_27 = "blue"
				var_7_28 = "red"
			else
				var_7_27 = "red"
				var_7_28 = "blue"
			end
		end

		if arg_7_0.guild.guildWarWin == 1 then
			arg_7_0:nodeByName("top_point"):setVisible(false)
			arg_7_0:nodeByName("mid_point"):setVisible(false)
			arg_7_0:nodeByName("down_point"):setVisible(false)

			for iter_7_0 = 1, 3 do
				arg_7_0:nodeByName(var_7_27 .. "_" .. iter_7_0):setVisible(true)
				arg_7_0:nodeByName(var_7_28 .. "_" .. iter_7_0):setVisible(false)
			end

			arg_7_0:nodeByName(var_7_27 .. "_" .. "1"):setPosition(arg_7_0:nodeByName(var_7_28 .. "_start_top"):getPosition())
			arg_7_0:nodeByName(var_7_27 .. "_" .. "2"):setPosition(arg_7_0:nodeByName(var_7_28 .. "_start_mid"):getPosition())
			arg_7_0:nodeByName(var_7_27 .. "_" .. "3"):setPosition(arg_7_0:nodeByName(var_7_28 .. "_start_down"):getPosition())
		elseif arg_7_0.guild.guildWarWin == 0 then
			arg_7_0:nodeByName("top_point"):setVisible(false)
			arg_7_0:nodeByName("mid_point"):setVisible(false)
			arg_7_0:nodeByName("down_point"):setVisible(false)

			for iter_7_1 = 1, 3 do
				arg_7_0:nodeByName(var_7_27 .. "_" .. iter_7_1):setVisible(false)
				arg_7_0:nodeByName(var_7_28 .. "_" .. iter_7_1):setVisible(true)
			end

			arg_7_0:nodeByName(var_7_28 .. "_" .. "1"):setPosition(arg_7_0:nodeByName(var_7_27 .. "_start_top"):getPosition())
			arg_7_0:nodeByName(var_7_28 .. "_" .. "2"):setPosition(arg_7_0:nodeByName(var_7_27 .. "_start_mid"):getPosition())
			arg_7_0:nodeByName(var_7_28 .. "_" .. "3"):setPosition(arg_7_0:nodeByName(var_7_27 .. "_start_down"):getPosition())
		elseif arg_7_0.guild.guildWarWin == -1 then
			arg_7_0:nodeByName("top_point"):setVisible(false)
			arg_7_0:nodeByName("mid_point"):setVisible(false)
			arg_7_0:nodeByName("down_point"):setVisible(false)

			for iter_7_2 = 1, 3 do
				arg_7_0:nodeByName(var_7_27 .. "_" .. iter_7_2):setVisible(false)
				arg_7_0:nodeByName(var_7_28 .. "_" .. iter_7_2):setVisible(false)
			end
		end
	elseif var_7_26 == xyd.GuildWarStep.FIGHT then
		if not arg_7_0.fightFresh then
			arg_7_0.fightFresh = 0
		end

		arg_7_0.fightFresh = arg_7_0.fightFresh + 1

		if arg_7_0.fightFresh == var_0_6 then
			arg_7_0.guild:loadGuildWarInfo(function(arg_8_0)
				return
			end)

			arg_7_0.fightFresh = 0
		end
	end
end

function var_0_0.willOpen(arg_9_0, arg_9_1)
	arg_9_0:setTouchSwallowEnabled(true)
	arg_9_0:updateTime()

	arg_9_0.handle_ = var_0_1.scheduleGlobal(function()
		arg_9_0:updateTime()
	end, 1)

	arg_9_0:checkUpdateForce()
	arg_9_0:layout()
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
end

function var_0_0.layout(arg_12_0)
	arg_12_0:createBuffWnd()

	local var_12_0 = "skeletons/ui_effect/guild_battle/guild_battle1"
	local var_12_1 = var_12_0 .. ".json"
	local var_12_2 = var_12_0 .. ".atlas"
	local var_12_3 = var_0_4.new(var_12_1, var_12_2, 1)

	var_12_3:align(display.CENTER, arg_12_0:nodeByName("background"):getWidth() / 2, arg_12_0:nodeByName("background"):getHeight() / 2)
	var_12_3:addTo(arg_12_0:nodeByName("background"))
	var_12_3:play(nil, true)

	local var_12_4 = "skeletons/ui_effect/guild_battle/guild_battle2"
	local var_12_5 = var_12_4 .. ".json"
	local var_12_6 = var_12_4 .. ".atlas"
	local var_12_7 = var_0_4.new(var_12_5, var_12_6, 1)

	var_12_7:align(display.CENTER, arg_12_0:nodeByName("background"):getWidth() / 2, arg_12_0:nodeByName("background"):getHeight() / 2 - 40)
	var_12_7:addTo(arg_12_0:nodeByName("background"))
	var_12_7:play(nil, true)
	arg_12_0:nodeByName("exchange_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.HONOR,
					top_status = xyd.MainSceneTop.CLOSE
				})
			end)
		end
	end)
	arg_12_0:nodeByName("schedule_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_12_0.guild.isInWar == true then
				arg_12_0.guild:loadGuildWarInfo(function(arg_16_0)
					if arg_16_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("guild_war_schedule")
					end
				end)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("GUILD_WAR_IS_NONE")
				})
			end
		end
	end)
	arg_12_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_12_0.guild.isInWar == true then
				local var_17_0 = {}
				local var_17_1 = {
					rankData = arg_12_0.rankList:getRankData({
						12001,
						12002,
						13001,
						14001
					})
				}

				xyd.WindowManager.get():openWindow("new_rank_list", var_17_1)
			else
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("GUILD_WAR_IS_NONE")
				})
			end
		end
	end)

	if var_0_5 then
		arg_12_0:nodeByName("testing_enroll"):setTouchEnabled(true)
		arg_12_0:nodeByName("testing_enroll"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
			if arg_18_0.name == "began" then
				return true
			elseif arg_18_0.name == "ended" then
				xyd.playButtonSound()
				arg_12_0.guild:guildWarEnroll(function(arg_19_0)
					if arg_19_0 == xyd.error.OK then
						-- block empty
					end
				end)
			end
		end)
	else
		arg_12_0:nodeByName("testing_enroll"):setVisible(false)
	end

	arg_12_0:nodeByName("team_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_20_0 = var_0_3:step(arg_12_0.guild.warStep)

			if var_20_0 == xyd.GuildWarStep.PREPARE or var_0_5 == true then
				xyd.WindowManager.get():openWindow("guild_war_troop")
			elseif var_20_0 == xyd.GuildWarStep.FIGHT or var_20_0 == xyd.GuildWarStep.ACCOUNT or var_20_0 == xyd.GuildWarStep.ENROLL then
				local var_20_1 = {
					rank_type = 3
				}

				arg_12_0.guild:guildWarRank(var_20_1, function(arg_21_0)
					if arg_21_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("guild_war_personal_state")
					end
				end)
			end
		end
	end)
	arg_12_0:nodeByName("blue_container"):getChildByName("click_item"):setTouchEnabled(true)
	arg_12_0:nodeByName("red_container"):getChildByName("click_item"):setTouchEnabled(true)
	arg_12_0:nodeByName("blue_container"):getChildByName("click_item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_22_0)
		if arg_22_0.name == "began" then
			return true
		elseif arg_22_0.name == "ended" then
			xyd.playButtonSound()

			if arg_12_0.side == "blue" then
				xyd.WindowManager.get():openWindow("guild_war_self_msg")
			else
				local var_22_0

				if arg_12_0.guild.warEnemy then
					if arg_12_0.guild.warEnemy.guildId == 0 then
						var_22_0 = {
							member_nums = 1,
							guild_id = 911,
							guild_des = var_0_2:translation("TEAM_JOIN_ITEM_DEFAULT_DES"),
							guild_name = var_0_2:translation("GUILD_BATTLE_NAME"),
							guild_leader_name = var_0_2:translation("GUILD_BATTLE_NAME"),
							guild_icon = xyd.tables.misc.teamIcons[1]
						}
					else
						var_22_0 = {
							member_nums = arg_12_0.guild.warEnemy.memberNum,
							guild_id = arg_12_0.guild.warEnemy.guildId,
							guild_des = arg_12_0.guild.warEnemy.des,
							guild_name = arg_12_0.guild.warEnemy.name,
							guild_leader_name = arg_12_0.guild.warEnemy.leaderName,
							guild_icon = arg_12_0.guild.warEnemy.icon
						}
					end
				end

				xyd.WindowManager.get():openWindow("team_icon", var_22_0)
			end
		end
	end)
	arg_12_0:nodeByName("red_container"):getChildByName("click_item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_23_0)
		if arg_23_0.name == "began" then
			return true
		elseif arg_23_0.name == "ended" then
			xyd.playButtonSound()

			if arg_12_0.side == "red" then
				xyd.WindowManager.get():openWindow("guild_war_self_msg")
			else
				local var_23_0

				if arg_12_0.guild.warEnemy then
					if arg_12_0.guild.warEnemy.guildId == 0 then
						var_23_0 = {
							member_nums = 1,
							guild_id = 911,
							guild_des = var_0_2:translation("TEAM_JOIN_ITEM_DEFAULT_DES"),
							guild_name = var_0_2:translation("GUILD_BATTLE_NAME"),
							guild_leader_name = var_0_2:translation("GUILD_BATTLE_NAME"),
							guild_icon = xyd.tables.misc.teamIcons[1]
						}
					else
						var_23_0 = {
							member_nums = arg_12_0.guild.warEnemy.memberNum,
							guild_id = arg_12_0.guild.warEnemy.guildId,
							guild_des = arg_12_0.guild.warEnemy.des,
							guild_name = arg_12_0.guild.warEnemy.name,
							guild_leader_name = arg_12_0.guild.warEnemy.leaderName,
							guild_icon = arg_12_0.guild.warEnemy.icon
						}
					end

					xyd.WindowManager.get():openWindow("team_icon", var_23_0)
				end
			end
		end
	end)

	for iter_12_0 = 1, 3 do
		local var_12_8 = "skeletons/ui_effect/qizhi/qizi2_1"
		local var_12_9 = var_12_8 .. ".json"
		local var_12_10 = var_12_8 .. ".atlas"
		local var_12_11 = var_0_4.new(var_12_9, var_12_10, 1)

		var_12_11:align(display.CENTER, arg_12_0:nodeByName("red_" .. iter_12_0):getWidth() / 2, arg_12_0:nodeByName("red_" .. iter_12_0):getHeight() / 2)
		var_12_11:setFlipX(true)
		var_12_11:addTo(arg_12_0:nodeByName("red_" .. iter_12_0))
		var_12_11:play(nil, true)

		local var_12_12 = "skeletons/ui_effect/qizhi/qizi2_2"
		local var_12_13 = var_12_12 .. ".json"
		local var_12_14 = var_12_12 .. ".atlas"
		local var_12_15 = var_0_4.new(var_12_13, var_12_14, 1)

		var_12_15:align(display.CENTER, arg_12_0:nodeByName("blue_" .. iter_12_0):getWidth() / 2, arg_12_0:nodeByName("blue_" .. iter_12_0):getHeight() / 2)
		var_12_15:addTo(arg_12_0:nodeByName("blue_" .. iter_12_0))
		var_12_15:play(nil, true)
	end

	local var_12_16 = "skeletons/ui_effect/qizhi/battle"
	local var_12_17 = var_12_16 .. ".json"
	local var_12_18 = var_12_16 .. ".atlas"
	local var_12_19 = var_0_4.new(var_12_17, var_12_18, 1)
	local var_12_20 = var_0_4.new(var_12_17, var_12_18, 1)
	local var_12_21 = var_0_4.new(var_12_17, var_12_18, 1)

	var_12_19:align(display.CENTER, arg_12_0:nodeByName("top_point"):getWidth() / 3 * 2, arg_12_0:nodeByName("top_point"):getHeight() / 2)
	var_12_19:addTo(arg_12_0:nodeByName("top_point"))
	var_12_19:setScale(0.7, 0.7)
	var_12_19:play(nil, true)
	var_12_20:align(display.CENTER, arg_12_0:nodeByName("mid_point"):getWidth() / 3 * 2, arg_12_0:nodeByName("mid_point"):getHeight() / 2)
	var_12_20:addTo(arg_12_0:nodeByName("mid_point"))
	var_12_20:setScale(0.7, 0.7)
	var_12_20:play(nil, true)
	var_12_21:align(display.CENTER, arg_12_0:nodeByName("down_point"):getWidth() / 3 * 2, arg_12_0:nodeByName("down_point"):getHeight() / 2)
	var_12_21:addTo(arg_12_0:nodeByName("down_point"))
	var_12_21:setScale(0.7, 0.7)
	var_12_21:play(nil, true)

	for iter_12_1 = 1, 3 do
		arg_12_0:nodeByName("blue" .. "_" .. iter_12_1):getChildByName("click_item"):setTouchEnabled(true)
		arg_12_0:nodeByName("red" .. "_" .. iter_12_1):getChildByName("click_item"):setTouchEnabled(true)
		arg_12_0:nodeByName(arg_12_0.side .. "_" .. iter_12_1):getChildByName("click_item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
			if arg_24_0.name == "began" then
				arg_12_0.isLoadingSelfList = true

				return true
			elseif arg_24_0.name == "ended" then
				local var_24_0 = var_0_3:step(arg_12_0.guild.warStep)

				if var_24_0 == xyd.GuildWarStep.WALK or var_0_5 == true then
					xyd.playButtonSound()

					local var_24_1 = {
						path = iter_12_1
					}

					arg_12_0.guild:guildWarLoadPath(var_24_1, function(arg_25_0, arg_25_1)
						if arg_25_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("guild_war_path", {
								isWalking = true,
								path = iter_12_1
							})
						end
					end)
				elseif var_24_0 == xyd.GuildWarStep.PREPARE or var_0_5 == true then
					xyd.playButtonSound()

					local var_24_2 = {
						path = iter_12_1
					}

					arg_12_0.guild:guildWarLoadPath(var_24_2, function(arg_26_0, arg_26_1)
						if arg_26_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("guild_war_path", {
								path = iter_12_1
							})
						end
					end)
				elseif var_0_5 == true or var_24_0 == xyd.GuildWarStep.FIGHT or var_24_0 == xyd.GuildWarStep.ACCOUNT or var_24_0 == xyd.GuildWarStep.ENROLL then
					local var_24_3 = {
						path = iter_12_1
					}

					if not isLoadingList then
						arg_12_0.guild:guildWarFightListUpdate(var_24_3, function(arg_27_0, arg_27_1)
							if arg_27_0 == xyd.error.OK then
								xyd.playButtonSound()
								xyd.WindowManager.get():openWindow("guild_war_path_state", {
									path = iter_12_1
								})

								arg_12_0.isLoadingSelfList = false
							end
						end)
					end
				end
			end
		end)
	end

	for iter_12_2 = 1, 3 do
		local var_12_22
		local var_12_23 = arg_12_0.side == "blue" and "red" or "blue"

		arg_12_0:nodeByName(var_12_23 .. "_" .. iter_12_2):getChildByName("click_item"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_28_0)
			if arg_28_0.name == "began" then
				arg_12_0.isLoadingList = true

				return true
			elseif arg_28_0.name == "ended" then
				local var_28_0 = var_0_3:step(arg_12_0.guild.warStep)

				if var_0_5 == true or var_28_0 == xyd.GuildWarStep.FIGHT or var_28_0 == xyd.GuildWarStep.ACCOUNT or var_28_0 == xyd.GuildWarStep.ENROLL then
					local var_28_1 = {
						path = iter_12_2
					}

					if not arg_12_0.isLoadingSelfList then
						arg_12_0.guild:guildWarFightListUpdate(var_28_1, function(arg_29_0, arg_29_1)
							if arg_29_0 == xyd.error.OK then
								xyd.playButtonSound()
								xyd.WindowManager.get():openWindow("guild_war_path_state", {
									path = iter_12_2
								})

								arg_12_0.isLoadingList = false
							end
						end)
					end
				end
			end
		end)
	end

	if var_0_5 == true then
		arg_12_0:nodeByName("top_point"):getChildByName("click"):setTouchEnabled(true)
		arg_12_0:nodeByName("mid_point"):getChildByName("click"):setTouchEnabled(true)
		arg_12_0:nodeByName("down_point"):getChildByName("click"):setTouchEnabled(true)
	end

	arg_12_0:nodeByName("top_point"):getChildByName("click"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			return true
		elseif arg_30_0.name == "ended" then
			local var_30_0 = var_0_3:step(arg_12_0.guild.warStep)

			if var_0_5 == true then
				local var_30_1 = {
					path = xyd.GuildWarPath.TOP
				}

				arg_12_0.guild:guildWarFightListUpdate(var_30_1, function(arg_31_0, arg_31_1)
					if arg_31_0 == xyd.error.OK then
						xyd.playButtonSound()
						xyd.WindowManager.get():openWindow("guild_war_path_state", {
							path = xyd.GuildWarPath.TOP
						})
					end
				end)
			end
		end
	end)
	arg_12_0:nodeByName("mid_point"):getChildByName("click"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		if arg_32_0.name == "began" then
			return true
		elseif arg_32_0.name == "ended" then
			local var_32_0 = var_0_3:step(arg_12_0.guild.warStep)

			if var_0_5 == true then
				local var_32_1 = {
					path = xyd.GuildWarPath.MID
				}

				arg_12_0.guild:guildWarFightListUpdate(var_32_1, function(arg_33_0, arg_33_1)
					if arg_33_0 == xyd.error.OK then
						xyd.playButtonSound()
						xyd.WindowManager.get():openWindow("guild_war_path_state", {
							path = xyd.GuildWarPath.MID
						})
					end
				end)
			end
		end
	end)
	arg_12_0:nodeByName("down_point"):getChildByName("click"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_34_0)
		if arg_34_0.name == "began" then
			return true
		elseif arg_34_0.name == "ended" then
			local var_34_0 = var_0_3:step(arg_12_0.guild.warStep)

			if var_0_5 == true then
				local var_34_1 = {
					path = xyd.GuildWarPath.BOTTOM
				}

				arg_12_0.guild:guildWarFightListUpdate(var_34_1, function(arg_35_0, arg_35_1)
					if arg_35_0 == xyd.error.OK then
						xyd.playButtonSound()
						xyd.WindowManager.get():openWindow("guild_war_path_state", {
							path = xyd.GuildWarPath.BOTTOM
						})
					end
				end)
			end
		end
	end)
end

function var_0_0.setMainByState(arg_36_0)
	arg_36_0:nodeByName("top_time_text2"):setString(var_0_2:translation("ACTIVITY_LEFT_TIME"))
end

function var_0_0.willClose(arg_37_0, arg_37_1)
	var_0_0.super:willClose(arg_37_1)

	if arg_37_0.handle_ then
		var_0_1.unscheduleGlobal(arg_37_0.handle_)
	end
end

function var_0_0.createBuffWnd(arg_38_0)
	local var_38_0 = arg_38_0.guild:getBuffsInfo()

	if not var_38_0 or not next(var_38_0) then
		return
	end

	if not arg_38_0.isInitBuffWnd or not arg_38_0.topBuffWnd or tolua.isnull(topBuffWnd) then
		local var_38_1 = import("app.windows.GuildWarTopBuff").new()
		local var_38_2 = {
			step = var_0_3:step(arg_38_0.guild.warStep),
			end_time = arg_38_0.guild.warEndTime
		}

		var_38_1:setParams(var_38_2)
		var_38_1:addTo(arg_38_0:nodeByName("background"))
		var_38_1:setPosition(cc.p(124, 517))
		var_38_1:setName("top_buff_wnd")

		arg_38_0.isInitBuffWnd = true
		arg_38_0.topBuffWnd = var_38_1
	end

	arg_38_0.topBuffWnd:update(var_38_0, arg_38_0.guild.warSide)
end

return var_0_0
