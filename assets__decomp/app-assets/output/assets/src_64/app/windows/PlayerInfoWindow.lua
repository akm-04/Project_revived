local var_0_0 = class("PlayerInfoWindow", import("app.common.ui.BaseWindow"))

var_0_0.CHANGE_HEAD = "change_head_icon_btn"
var_0_0.CHANGE_HEAD_BORDER = "change_head_border_btn"
var_0_0.SYSCONFIG_BTN = "sysconfig_btn"
var_0_0.ACHIEVEMENT_BTN = "achievement_btn"
var_0_0.QUIT_TEAM = "quit_team_btn"
var_0_0.CHANGE_NICKNAME = "change_nickname_btn"
var_0_0.CHANGE_NICKNAME_TXT = "change_nickname_txt"
var_0_0.PLAYER_LEV = "play_lev_txt"
var_0_0.PLAYER_EXP = "player_exp_txt"
var_0_0.HERO_LEV_MAX = "hero_lev_max_txt"
var_0_0.PLAYER_ID = "playerid_txt"
var_0_0.TEAM_NAME = "team_name_txt"
var_0_0.TEAM_ID = "teamid_txt"
var_0_0.NICK_NAME = "player_nickname_txt"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.playerLev = arg_1_0.selfPlayer.lev
	arg_1_0.exp = arg_1_0.selfPlayer.exp
	arg_1_0.heroMaxLev = xyd.tables.player:heroMaxLev(arg_1_0.playerLev)
	arg_1_0.playerId = arg_1_0.selfPlayer.playerID
	arg_1_0.playerName = arg_1_0.selfPlayer.playerName
	arg_1_0.stringLocalizer = xyd.tables.translation
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.avatar = display.newNode()

	arg_2_0.avatar:setContentSize(110, 110)
	arg_2_0.avatar:setPosition(72, 456)
	arg_2_0:nodeByName("backgroud"):addChild(arg_2_0.avatar)

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	if arg_2_0.guild.guild_id then
		arg_2_0.guildId = arg_2_0.guild.guild_id
	else
		arg_2_0.guildId = 0
	end

	if arg_2_0.guildId == 0 or arg_2_0.guildId == nil then
		arg_2_0:nodeByName("team_name_txt"):setVisible(false)
		arg_2_0:nodeByName("teamid_txt"):setVisible(false)
		arg_2_0:nodeByName("job_txt"):setVisible(false)
		arg_2_0:nodeByName("quit_team_btn"):setVisible(false)
		arg_2_0:nodeByName("quit_gonghui_txt"):setVisible(false)
		arg_2_0:nodeByName("check_team_btn"):setVisible(false)
		arg_2_0:nodeByName("search_words"):setVisible(false)
		arg_2_0:nodeByName("bg_2"):setVisible(false)
		arg_2_0:nodeByName("high_bg"):setVisible(false)
		arg_2_0:init()
	else
		arg_2_0:init()
		arg_2_0:nodeByName("bg_1"):setVisible(false)
		arg_2_0:nodeByName("sysconfig_btn"):setPosition(arg_2_0:nodeByName("sysconfig_btn"):getX(), arg_2_0:nodeByName("sysconfig_btn"):getY() - 100)
		arg_2_0:nodeByName("achievement_btn"):setPositionY(arg_2_0:nodeByName("achievement_btn"):getY() - 100)
		arg_2_0:nodeByName("backgroud"):setPosition(arg_2_0:nodeByName("backgroud"):getX(), arg_2_0:nodeByName("backgroud"):getY() + 20)
	end
end

function var_0_0.init(arg_3_0)
	arg_3_0:updateRedPointShow()

	local var_3_0 = xyd.tables.player:totalExp(arg_3_0.playerLev)
	local var_3_1 = xyd.tables.player:totalExp(arg_3_0.playerLev - 1)
	local var_3_2 = var_3_0 - var_3_1
	local var_3_3 = arg_3_0.playerId
	local var_3_4 = arg_3_0.exp - var_3_1 .. "/" .. var_3_2

	if arg_3_0.playerLev == arg_3_0.selfPlayer.maxTeamLev then
		var_3_4 = "0/0"
	end

	arg_3_0:nodeByName(var_0_0.PLAYER_LEV):setString(string.format(arg_3_0.stringLocalizer:translation("TEAM_LEV"), arg_3_0.playerLev))
	arg_3_0:nodeByName(var_0_0.PLAYER_EXP):setString(string.format(arg_3_0.stringLocalizer:translation("TEAM_EXP"), var_3_4))
	arg_3_0:nodeByName(var_0_0.HERO_LEV_MAX):setString(string.format(arg_3_0.stringLocalizer:translation("HERO_LEV_MAX"), arg_3_0.heroMaxLev))
	arg_3_0:nodeByName(var_0_0.PLAYER_ID):setString(string.format(arg_3_0.stringLocalizer:translation("PLAYER_ID"), var_3_3))

	if arg_3_0.guildId ~= 0 and arg_3_0.guildId ~= nil then
		arg_3_0:nodeByName("team_name_txt"):setString(string.format(arg_3_0.stringLocalizer:translation("PLAYER_INFO_TEAM_NAME"), arg_3_0.guild.guild_name))
		arg_3_0:nodeByName("teamid_txt"):setString(string.format(arg_3_0.stringLocalizer:translation("PLAYER_INFO_TEAM_ID"), arg_3_0.guild.guild_id))

		local var_3_5 = ""

		if arg_3_0.guild.job == 0 then
			var_3_5 = arg_3_0.stringLocalizer:translation("TEAM_MEMBER")
		elseif arg_3_0.guild.job == 1 then
			var_3_5 = arg_3_0.stringLocalizer:translation("TEAM_PRESIDENT")
		else
			var_3_5 = arg_3_0.stringLocalizer:translation("TEAM_VICE_PRESIDENT")
		end

		arg_3_0:nodeByName("job_txt"):setString(string.format(arg_3_0.stringLocalizer:translation("PLAYER_INFO_JOB"), var_3_5))
	end

	if not arg_3_0.playerName or arg_3_0.playerName == "" then
		arg_3_0:nodeByName("config_name_img"):setVisible(true)
		arg_3_0:nodeByName("change_name_img"):setVisible(false)
	else
		arg_3_0:nodeByName("config_name_img"):setVisible(false)
		arg_3_0:nodeByName("change_name_img"):setVisible(true)
	end

	arg_3_0:nodeByName(var_0_0.NICK_NAME):setString(arg_3_0.playerName)
	arg_3_0:updateAvatar()
end

function var_0_0.updateAvatar(arg_4_0)
	xyd.setAvatarClip(arg_4_0.avatar, arg_4_0.selfPlayer:getMyCurrentAvatarID(), 1)
	arg_4_0:nodeByName("touxiang_kuang"):removeAllChildren()

	local var_4_0 = xyd.AssetLoader.get():loadSprite("images/avatar_frames/" .. xyd.tables.avatar.icon_[arg_4_0.selfPlayer.avatarFrame] .. ".png")

	var_4_0:setPosition(arg_4_0:nodeByName("touxiang_kuang"):getWidth() / 2, arg_4_0:nodeByName("touxiang_kuang"):getHeight() / 2 + 5)
	arg_4_0:nodeByName("touxiang_kuang"):addChild(var_4_0)
	arg_4_0:nodeByName("touxiang_kuang"):setLocalZOrder(1)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:nodeByName(var_0_0.SYSCONFIG_BTN):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("sysconfig_window")
		end
	end)
	arg_5_0:nodeByName(var_0_0.ACHIEVEMENT_BTN):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT):loadAchievementInfo({}, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					arg_5_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.ACHIEVEMENT)
					xyd.WindowManager.get():openWindow("achievement", arg_5_1)
					xyd.WindowManager.get():closeWindow(arg_5_0)

					local var_8_0 = xyd.WindowManager.get():getWindow("main_scene_top")

					if var_8_0 then
						var_8_0:updateAchievementRedMark()
					end
				end
			end)
		end
	end)
	arg_5_0:nodeByName(var_0_0.CHANGE_NICKNAME):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("edit_player_name")
		end
	end)
	arg_5_0:nodeByName(var_0_0.CHANGE_HEAD):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("change_avatar")
		end
	end)
	arg_5_0:nodeByName("change_head_border_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("change_avatar_frame")
		end
	end)

	if arg_5_0.guildId ~= 0 and arg_5_0.guildId ~= nil then
		arg_5_0:nodeByName("quit_team_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				if arg_5_0.guild.job == 0 or arg_5_0.guild.job == 2 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, xyd.tables.translation:translation("PLAYER_INFO_QUIT_ALERT"), function()
						arg_5_0.guild:quitTeam(function(arg_14_0)
							if arg_14_0 == xyd.error.OK then
								xyd.WindowManager.get():closeWindow(arg_5_0)

								return true
							end
						end)
					end, nil, nil, arg_5_0.colorMode)
				elseif arg_5_0.guild.job == 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, xyd.tables.translation:translation("PLAYER_INFO_CANT_QUIT_ALERT"), nil, nil, nil, arg_5_0.colorMode)
				end
			end
		end)
		arg_5_0:nodeByName("check_team_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
			if arg_15_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("read_guild")
			end
		end)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.EDIT_NAME_FINISHED, function(arg_16_0)
		arg_5_0:nodeByName(var_0_0.NICK_NAME):setString(arg_5_0.selfPlayer.playerName)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_5_0):addEventListener(xyd.event.REFRESH_AVATAR, function(arg_17_0)
		arg_5_0:updateAvatar()
	end)
	arg_5_0:addBlockLayer()
end

function var_0_0.updateRedPointShow(arg_18_0)
	local var_18_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)

	if var_18_0:getCanAwardLev() > 0 or var_18_0.isHasNewNotice then
		var_18_0.isHasNewNotice = false

		arg_18_0:nodeByName("achievement_btn"):getChildByName("red_point"):setVisible(true)
	else
		arg_18_0:nodeByName("achievement_btn"):getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.getVipGiftIndex(arg_19_0)
	local var_19_0 = arg_19_0.selfPlayer.vip

	while var_19_0 > 0 do
		if arg_19_0.selfPlayer.vipAwards[var_19_0] and arg_19_0.selfPlayer.vipAwards[var_19_0] == 0 then
			return var_19_0
		end

		var_19_0 = var_19_0 - 1
	end

	return var_19_0
end

function var_0_0.buttonHandler(arg_20_0, arg_20_1, arg_20_2, arg_20_3)
	if arg_20_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_20_2)
		arg_20_2:setScale(1)
		xyd.playButtonSound()

		if arg_20_1 then
			arg_20_1(arg_20_2, arg_20_3)
		end
	elseif arg_20_3 == ccui.TouchEventType.began then
		return true
	elseif arg_20_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_20_2)
		arg_20_2:setScale(1)
	end
end

return var_0_0
