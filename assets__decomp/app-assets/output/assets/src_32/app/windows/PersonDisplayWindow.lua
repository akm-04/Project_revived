local var_0_0 = class("PersonDisplayWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("app.model.Hero")
local var_0_4 = import("app.model.Pet")
local var_0_5 = 2
local var_0_6 = 5
local var_0_7 = 5
local var_0_8 = {
	CAN_ADD = 1,
	IN_BLACK = 3,
	IN_FRIEND = 2,
	FULL_FRIEND = 4
}
local var_0_9 = var_0_1:translation("PERSON_DISPLAY")
local var_0_10 = {
	btn_main = var_0_1:translation("PERSON_DISPLAY_MAIN"),
	btn_history = var_0_1:translation("PERSON_DISPLAY_HISTORY"),
	btn_space = var_0_1:translation("PERSON_DISPLAY_SPACE"),
	btn_help = var_0_1:translation("PERSON_DISPLAY_HELP"),
	btn_system = var_0_1:translation("PERSON_DISPLAY_SYSTEM")
}
local var_0_11 = {
	var_0_1:translation("PERSON_HISTORY_TOP"),
	var_0_1:translation("PERSON_HISTORY_DOUNIU"),
	var_0_1:translation("PERSON_HISTORY_KUAFU")
}
local var_0_12 = var_0_1:translation("PERSON_HISTORY_ISSHOW")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.personDisplay = xyd.ModelManager.get():loadModel(xyd.ModelType.PERSON_DISPLAY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)

	if arg_1_2 then
		arg_1_0.leftBtnStyle = arg_1_2.leftBtnStyle or xyd.PlayerCardButtonStyle.MAIN
		arg_1_0.lastLeftBtnStyle = arg_1_2.leftBtnStyle or xyd.PlayerCardButtonStyle.MAIN
		arg_1_0.recordTabType = arg_1_2.recordTabType or xyd.PlayerCardHistory.ARENA
		arg_1_0.openFuctions = arg_1_2.open_fuctions
	else
		arg_1_0.leftBtnStyle = xyd.PlayerCardButtonStyle.MAIN
		arg_1_0.lastLeftBtnStyle = xyd.PlayerCardButtonStyle.MAIN
		arg_1_0.recordTabType = xyd.PlayerCardHistory.ARENA
	end

	arg_1_0.rightPanel = {}
	arg_1_0.leftBtn = {}
	arg_1_0.report = {}
	arg_1_0.heroShowCardTips = {}
	arg_1_0.displayAiHelp = arg_1_0:checkDisaplayAiHelp() or false
end

local function var_0_13(arg_2_0)
	local var_2_0, var_2_1, var_2_2 = arg_2_0:match("(%d+)%.(%d+)%.(%d+)")
	local var_2_3 = {
		main = tonumber(var_2_0 or 0),
		mid = tonumber(var_2_1 or 0),
		sub = tonumber(var_2_2 or 0)
	}

	setmetatable(var_2_3, {
		__tostring = function()
			return arg_2_0
		end
	})

	return var_2_3
end

local function var_0_14(arg_4_0, arg_4_1)
	if arg_4_0.main ~= arg_4_1.main then
		return arg_4_0.main - arg_4_1.main
	elseif arg_4_0.mid ~= arg_4_1.mid then
		return arg_4_0.mid - arg_4_1.mid
	else
		return arg_4_0.sub - arg_4_1.sub
	end
end

function var_0_0.checkDisaplayAiHelp(arg_5_0)
	local var_5_0 = false
	local var_5_1 = var_0_13(xyd.getVersionName() or "")
	local var_5_2 = var_0_13("1.790.0")

	if var_0_14(var_5_1, var_5_2) >= 0 then
		return true
	end

	return false
end

function var_0_0.willOpen(arg_6_0, arg_6_1)
	arg_6_0:nodeByName("container_right"):setLocalZOrder(1)
	arg_6_0:layout()
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	arg_7_0:playGuide()
	arg_7_0:addBlockLayer()
end

function var_0_0.checkPlayerIsYou(arg_8_0)
	if arg_8_0:getPlayerID() == arg_8_0.selfPlayer.playerID then
		return true
	end

	return false
end

function var_0_0.getPlayerID(arg_9_0)
	return (arg_9_0.personDisplay:getPlayerID())
end

function var_0_0.isDormShow(arg_10_0)
	if arg_10_0:checkPlayerIsYou() then
		return arg_10_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_DORM)
	else
		return arg_10_0.personDisplay:isFuncOpen(xyd.FunctionID.ID_DORM)
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:createRightPanel()
	arg_11_0:initLeftButtonEvent()
	arg_11_0:nodeByName("txt_name"):setString(var_0_9)
	arg_11_0:nodeByName("close"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = arg_11_0.personDisplay:getLastPlayerID()
			local var_12_1 = arg_11_0.personDisplay:checkNeedReturn()

			if var_12_0 and var_12_1 then
				local var_12_2, var_12_3 = arg_11_0.personDisplay:getLastPlayerLeftInfo()
				local var_12_4 = {
					leftBtnStyle = var_12_2,
					recordTabType = var_12_3
				}
				local var_12_5 = {
					to_player_id = var_12_0,
					sub_type = var_12_2
				}

				arg_11_0.personDisplay:getPlayerInfo(var_12_5, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						local var_13_0 = arg_11_0.personDisplay.oldPlayerInfos[arg_11_0.personDisplay:getTouchCount()]

						if var_13_0 and next(var_13_0) then
							arg_11_0.personDisplay:updateBasicInfo(var_13_0)
						end

						if xyd.WindowManager.get():isWindowOpen("person_display") then
							xyd.WindowManager.get():closeWindow("person_display")
						end

						xyd.WindowManager.get():openWindow("person_display", var_12_4)
					end
				end, true)
			else
				arg_11_0.personDisplay.lastPlayerID = nil

				xyd.WindowManager.get():closeWindow(arg_11_0)
			end
		end
	end)
end

function var_0_0.willClose(arg_14_0, arg_14_1)
	var_0_0.super:willClose(arg_14_1)
	arg_14_0.personDisplay:updateTouchCount(false)
end

function var_0_0.loadInfo(arg_15_0)
	local var_15_0 = {
		to_player_id = arg_15_0:getPlayerID(),
		sub_type = arg_15_0.leftBtnStyle
	}

	arg_15_0.personDisplay:getPlayerInfo(var_15_0, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:updateLeftBtnStatus()
			arg_15_0:updateRightPanel()
		end
	end)
end

function var_0_0.initLeftButtonEvent(arg_17_0)
	table.insert(arg_17_0.leftBtn, {
		btn_name = "btn_main",
		flag = xyd.PlayerCardButtonStyle.MAIN
	})
	table.insert(arg_17_0.leftBtn, {
		btn_name = "btn_history",
		flag = xyd.PlayerCardButtonStyle.HISTORY
	})
	table.insert(arg_17_0.leftBtn, {
		btn_name = "btn_space",
		flag = xyd.PlayerCardButtonStyle.SPACE
	})

	if arg_17_0.displayAiHelp then
		table.insert(arg_17_0.leftBtn, {
			btn_name = "btn_help",
			flag = xyd.PlayerCardButtonStyle.HELP
		})
	else
		arg_17_0:nodeByName("btn_help"):setVisible(false)
	end

	table.insert(arg_17_0.leftBtn, {
		btn_name = "btn_system",
		flag = xyd.PlayerCardButtonStyle.SYSTEM
	})

	for iter_17_0, iter_17_1 in pairs(arg_17_0.leftBtn) do
		if not arg_17_0:checkPlayerIsYou(iter_17_1.flag) and iter_17_1.flag == xyd.PlayerCardButtonStyle.SYSTEM then
			arg_17_0:nodeByName(iter_17_1.btn_name):setVisible(false)
			arg_17_0:nodeByName("btn_help"):setVisible(false)
		end

		arg_17_0:nodeByName("txt_" .. iter_17_1.btn_name):setString(var_0_10[iter_17_1.btn_name])
		arg_17_0:nodeByName(iter_17_1.btn_name):addTouchEventListener(function(arg_18_0, arg_18_1)
			if arg_18_1 == ccui.TouchEventType.ended and arg_17_0.leftBtnStyle ~= iter_17_1.flag then
				arg_17_0:nodeByName(iter_17_1.btn_name):setBrightStyle(ccui.BrightStyle.highlight)

				if arg_17_0.mainEditStatus then
					arg_17_0:updateEditStatus()
				end

				arg_17_0.leftBtnStyle = iter_17_1.flag

				arg_17_0.personDisplay:updatePlayerStatus(arg_17_0.leftBtnStyle, arg_17_0.recordTabType)

				if arg_17_0.leftBtnStyle == xyd.PlayerCardButtonStyle.SYSTEM or arg_17_0.personDisplay:checkIsRobot() then
					arg_17_0:updateLeftBtnStatus()
					arg_17_0:updateRightPanel()
				else
					arg_17_0:loadInfo()
				end

				arg_17_0:updateNewChange()
			end
		end)
	end

	arg_17_0:updateLeftBtnStatus()
	arg_17_0:changeLeftBtnPos()
end

function var_0_0.updateNewChange(arg_19_0)
	if (arg_19_0.leftBtnStyle == xyd.PlayerCardButtonStyle.MAIN or arg_19_0.leftBtnStyle == xyd.PlayerCardButtonStyle.SPACE) and arg_19_0.praiseIsChange then
		local var_19_0 = arg_19_0.personDisplay:getIsHasPraise()

		if arg_19_0.mainPraiseBtn then
			if var_19_0 == 1 then
				arg_19_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(false)
				arg_19_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(true)
			else
				arg_19_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(true)
				arg_19_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(false)
			end
		end

		if arg_19_0.spacePraiseBtn then
			if var_19_0 == 1 then
				arg_19_0.spacePraiseBtn:getChildByName("icon_praise"):setVisible(false)
				arg_19_0.spacePraiseBtn:getChildByName("icon_prise_select"):setVisible(false)
				arg_19_0.spacePraiseBtn:getChildByName("icon_praise_done"):setVisible(true)
			else
				arg_19_0.spacePraiseBtn:getChildByName("icon_praise"):setVisible(true)
				arg_19_0.spacePraiseBtn:getChildByName("icon_prise_select"):setVisible(false)
				arg_19_0.spacePraiseBtn:getChildByName("icon_praise_done"):setVisible(false)
			end

			arg_19_0.spacePraiseBtn:setBrightStyle(var_19_0 == 1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
		end

		local var_19_1 = arg_19_0.personDisplay:getPraiseNum()

		if arg_19_0.spacePraiseNum then
			arg_19_0.spacePraiseNum:setString(var_19_1)
		end

		if arg_19_0.mainPraiseNum then
			arg_19_0.mainPraiseNum:setString(var_19_1)
		end

		arg_19_0.praiseIsChange = false
	end
end

function var_0_0.changeLeftBtnPos(arg_20_0)
	local var_20_0 = arg_20_0:nodeByName("btn_main"):getPositionY()

	for iter_20_0 = 1, #arg_20_0.leftBtn do
		local var_20_1 = arg_20_0.leftBtn[iter_20_0].btn_name

		if arg_20_0:nodeByName(var_20_1):isVisible() then
			arg_20_0:nodeByName(var_20_1):setPositionY(var_20_0)

			var_20_0 = var_20_0 - 72
		end
	end
end

function var_0_0.checkBtnIsHide(arg_21_0, arg_21_1)
	if arg_21_0:checkPlayerIsYou() then
		return false
	elseif not arg_21_0:checkPlayerIsYou() and arg_21_1 == xyd.PlayerCardButtonStyle.SYSTEM then
		return true
	elseif not arg_21_0:checkFunctionOpen(arg_21_1) then
		return true
	elseif arg_21_0.personDisplay:checkYouIsInBlackList() then
		return true
	elseif arg_21_0:checkCanAddFriend() == var_0_8.IN_BLACK then
		return true
	elseif arg_21_0.personDisplay:checkIsRobot() then
		return true
	end

	arg_21_0.hideTypes = arg_21_0.personDisplay:getHideTypes()

	for iter_21_0 = 1, #arg_21_0.hideTypes do
		if arg_21_0.hideTypes[iter_21_0] == arg_21_1 then
			return true
		end
	end

	return false
end

function var_0_0.checkFunctionOpen(arg_22_0, arg_22_1, arg_22_2)
	local var_22_0 = arg_22_2 or xyd.FunctionID.ID_ARENA

	if (arg_22_1 == xyd.PlayerCardButtonStyle.HISTORY or arg_22_1 == xyd.PlayerCardButtonStyle.BATTLE_RECORD) and not arg_22_0.selfPlayer:isFuncOpen(var_22_0) then
		return false
	end

	return true
end

function var_0_0.updateLeftBtnStatus(arg_23_0)
	for iter_23_0, iter_23_1 in pairs(arg_23_0.leftBtn) do
		if arg_23_0.leftBtnStyle == iter_23_1.flag then
			arg_23_0:nodeByName(iter_23_1.btn_name):setTouchEnabled(false)
			arg_23_0:nodeByName(iter_23_1.btn_name):setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_23_0:nodeByName(iter_23_1.btn_name):setTouchEnabled(true)
			arg_23_0:nodeByName(iter_23_1.btn_name):setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.updateRightPanel(arg_24_0)
	if arg_24_0.leftBtnStyle == xyd.PlayerCardButtonStyle.SPACE then
		arg_24_0:nodeByName("bg_large_pop_divide"):setLocalZOrder(2)
	else
		arg_24_0:nodeByName("bg_large_pop_divide"):setLocalZOrder(0)
	end

	if arg_24_0.rightPanel[arg_24_0.lastLeftBtnStyle] then
		arg_24_0.rightPanel[arg_24_0.lastLeftBtnStyle]:hide()
	end

	arg_24_0.lastLeftBtnStyle = arg_24_0.leftBtnStyle

	if arg_24_0.rightPanel[arg_24_0.leftBtnStyle] then
		arg_24_0.rightPanel[arg_24_0.leftBtnStyle]:show()

		return
	end

	arg_24_0:createRightPanel()
end

function var_0_0.createRightPanel(arg_25_0)
	if arg_25_0.leftBtnStyle == xyd.PlayerCardButtonStyle.MAIN then
		arg_25_0:createMain()
	elseif arg_25_0.leftBtnStyle == xyd.PlayerCardButtonStyle.HISTORY then
		arg_25_0:createHistory()
	elseif arg_25_0.leftBtnStyle == xyd.PlayerCardButtonStyle.SPACE then
		arg_25_0:createSpace()
	elseif arg_25_0.leftBtnStyle == xyd.PlayerCardButtonStyle.HELP then
		arg_25_0:createHelp()
	elseif arg_25_0.leftBtnStyle == xyd.PlayerCardButtonStyle.SYSTEM then
		arg_25_0:createSystem()
	end
end

function var_0_0.createMain(arg_26_0)
	local var_26_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/person_main.csb")

	var_26_0:addTo(arg_26_0:nodeByName("container_right"))

	local var_26_1 = var_26_0:getChildByName("container")

	arg_26_0.rightPanel[arg_26_0.leftBtnStyle] = var_26_0

	local var_26_2 = arg_26_0.personDisplay:getBasicInfo()
	local var_26_3 = var_26_2.player_info

	arg_26_0:createBasicMsg(var_26_1:getChildByName("container_message"), var_26_3)
	arg_26_0:initPlayerAvatar(var_26_1, var_26_3.avatar_id, var_26_3.avatar_frame_id)
	arg_26_0:initPlayerTitle(var_26_1, var_26_3.title_info)

	local var_26_4 = var_26_3.lev or var_26_3.level or var_26_3.player_lev

	var_26_1:getChildByName("txt_col_data"):setString("LV." .. var_26_4)
	var_26_1:getChildByName("txt_declar"):setVisible(false)
	var_26_1:getChildByName("frame_mid_1"):setVisible(false)
	var_26_1:getChildByName("frame_mid_2"):setVisible(false)
	var_26_1:getChildByName("frame_mid_3"):setVisible(false)
	var_26_1:getChildByName("frame_mid_4"):setVisible(false)
	var_26_1:getChildByName("frame_top"):setVisible(false)
	var_26_1:getChildByName("frame_bottom"):setVisible(false)
	var_26_1:getChildByName("txt_name"):setString(var_26_3.player_name or var_26_3.name)

	local var_26_5 = var_26_2.praise_num or 0

	var_26_1:getChildByName("btn_praise_num"):getChildByName("txt_praise_num"):setString(var_26_5)
	arg_26_0:createPlayerType(var_26_1:getChildByName("container_personality"))
	arg_26_0:createHeroShow(var_26_1:getChildByName("conatiner_show"))
	arg_26_0:createMainBtn(var_26_1)
end

function var_0_0.createBasicMsg(arg_27_0, arg_27_1, arg_27_2)
	local var_27_0 = arg_27_2.lev or arg_27_2.level or arg_27_2.player_lev
	local var_27_1 = xyd.tables.player:heroMaxLev(var_27_0)

	if not arg_27_0.personDisplay:checkIsRobot() then
		local var_27_2 = xyd.tables.player:totalExp(var_27_0)
		local var_27_3 = xyd.tables.player:totalExp(var_27_0 - 1)
		local var_27_4 = var_27_2 - var_27_3
		local var_27_5 = math.floor(arg_27_2.exp - var_27_3) .. "/" .. var_27_4

		if var_27_0 == arg_27_0.selfPlayer.maxTeamLev then
			var_27_5 = "0/0"
		end

		arg_27_1:getChildByName("txt_exp"):setString(var_0_1:translation("PLAYER_EXP"))
		arg_27_1:getChildByName("txt_id"):setString(var_0_1:translation("PLAYER_ID_2"))
		arg_27_1:getChildByName("txt_exp_num"):setString(var_27_5)
		arg_27_1:getChildByName("txt_id_num"):setString(arg_27_2.player_id)
	end

	arg_27_1:getChildByName("txt_lev"):setString(var_0_1:translation("HERO_MAX_LEV"))
	arg_27_1:getChildByName("txt_lev_num"):setString(var_27_1)
	arg_27_0:createGuildText(arg_27_1, arg_27_2)

	if arg_27_2.guild_id and arg_27_2.guild_id ~= 0 then
		arg_27_1:getChildByName("txt_society"):setString(var_0_1:translation("GUILD_ID_DESC"))
	else
		arg_27_1:getChildByName("txt_society"):setVisible(false)
		arg_27_1:getChildByName("txt_soc_data"):setPositionX(arg_27_1:getChildByName("txt_society"):getPositionX())
	end

	if arg_27_0.personDisplay:checkIsRobot() or not arg_27_0:checkPlayerIsYou() then
		arg_27_1:getChildByName("txt_exp"):setVisible(false)
		arg_27_1:getChildByName("txt_id"):setVisible(false)
		arg_27_1:getChildByName("txt_exp_num"):setVisible(false)
		arg_27_1:getChildByName("txt_id_num"):setVisible(false)

		local var_27_6 = arg_27_1:getChildByName("txt_society"):getPositionY()

		arg_27_1:getChildByName("txt_society"):setPositionY(var_27_6 + 53)
		arg_27_1:getChildByName("txt_soc_data"):setPositionY(var_27_6 + 53)
	end

	arg_27_1:getChildByName("guild_plus"):addTouchEventListener(function(arg_28_0, arg_28_1)
		if arg_28_1 == ccui.TouchEventType.began then
			arg_27_1:getChildByName("guild_plus"):setScale(0.9)

			return true
		elseif arg_28_1 == ccui.TouchEventType.ended then
			arg_27_1:getChildByName("guild_plus"):setScale(1)

			if arg_27_0.guild.member_nums >= xyd.tables.misc.teamPeopleLimit then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("INVITE_GUILD_NUM_MAX"), arg_27_0.guild.guild_name), function()
					arg_27_0.guild:loadTeam(function(arg_30_0)
						if arg_30_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("team_member_manage", {
								window_layer = 3
							})
						end
					end)
				end, nil, nil, arg_27_0.colorMode)
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("INVITE_GUILD_SAND"), arg_27_2.player_name, arg_27_0.guild.guild_name), function()
				local var_31_0 = {
					player_id = arg_27_0:getPlayerID()
				}

				arg_27_0.guild:inviteToGuild(var_31_0, function(arg_32_0, arg_32_1)
					if arg_32_0 == xyd.error.OK then
						xyd.GrayNode(arg_27_1:getChildByName("guild_plus"))
						arg_27_1:getChildByName("guild_plus"):setTouchEnabled(false)
						xyd.WindowManager.get():openWindow("toast", {
							message = var_0_1:translation("INVITE_GUILD_SAND_SUCCESS")
						})
					end
				end)
			end, nil, nil, arg_27_0.colorMode)
		end
	end)

	local var_27_7 = xyd.addPosition(cc.p(arg_27_1:getChildByName("txt_soc_data"):getPosition()), cc.p(arg_27_1:getChildByName("txt_soc_data"):getContentSize().width + 30, 0))

	arg_27_1:getChildByName("guild_plus"):setPosition(var_27_7)

	local var_27_8 = arg_27_0.personDisplay:getBasicInfo()

	if arg_27_0:getPlayerID() == arg_27_0.selfPlayer.playerID or xyd.getPlayerRegion(arg_27_0:getPlayerID()) ~= xyd.getPlayerRegion(arg_27_0.selfPlayer.playerID) or arg_27_2.guild_id and arg_27_2.guild_id ~= 0 or not arg_27_0.guild.job or arg_27_0.guild.job == 0 or arg_27_2.lev < arg_27_0.guild.min_lev then
		arg_27_1:getChildByName("guild_plus"):setVisible(false)
	elseif var_27_8.guild_invite_time and var_27_8.guild_invite_time > 0 then
		xyd.GrayNode(arg_27_1:getChildByName("guild_plus"))
		arg_27_1:getChildByName("guild_plus"):setTouchEnabled(false)
	end
end

function var_0_0.createGuildText(arg_33_0, arg_33_1, arg_33_2)
	if arg_33_2.guild_id and arg_33_2.guild_id ~= 0 then
		local var_33_0 = ""

		if arg_33_2.guild_job == 0 then
			local var_33_1 = var_0_1:translation("TEAM_MEMBER")
		elseif arg_33_2.guild_job == 1 then
			local var_33_2 = var_0_1:translation("TEAM_PRESIDENT")
		else
			local var_33_3 = var_0_1:translation("TEAM_VICE_PRESIDENT")
		end

		arg_33_1:getChildByName("txt_soc_data"):setString(arg_33_2.guild_name)

		local var_33_4 = arg_33_2.guild_job == xyd.GuildJobType.MEMBER and 3 or arg_33_2.guild_job

		for iter_33_0 = 1, 3 do
			local var_33_5 = false

			if var_33_4 == iter_33_0 then
				local var_33_6 = true
			end
		end

		local var_33_7 = cc.p(arg_33_1:getChildByName("txt_soc_data"):getPosition())
		local var_33_8 = arg_33_1:getChildByName("txt_soc_data"):getContentSize().width
	else
		arg_33_1:getChildByName("txt_soc_data"):setString(var_0_1:translation("PERSON_NO_GUILD"))
	end
end

function var_0_0.createTextLabel(arg_34_0, arg_34_1, arg_34_2, arg_34_3, arg_34_4, arg_34_5)
	local var_34_0 = {
		text = arg_34_1 or "",
		align = arg_34_2 or cc.ui.TEXT_ALIGN_CENTER,
		color = arg_34_3 or cc.c4b(255, 255, 255, 255),
		size = arg_34_4 or 24
	}
	local var_34_1 = xyd.AssetLoader.get():loadLabel(var_34_0)

	if arg_34_5 then
		var_34_1:setDimensions(arg_34_5, 0)
	end

	return var_34_1
end

function var_0_0.createPlayerType(arg_35_0, arg_35_1)
	arg_35_1:removeAllChildren()

	local var_35_0 = arg_35_0.personDisplay:getShowTypes()
	local var_35_1 = arg_35_1:getContentSize()
	local var_35_2 = 10
	local var_35_3 = var_35_1.height - 10
	local var_35_4 = 1

	arg_35_0.showtypesItems = {}
	arg_35_0.midEffect = {}

	for iter_35_0, iter_35_1 in pairs(var_35_0) do
		local var_35_5 = arg_35_0:createPlayerTypeCell(arg_35_1, iter_35_0, iter_35_1):getChildByName("container")
		local var_35_6 = var_35_5:getContentSize()

		var_35_5:setAnchorPoint(cc.p(0, 1))
		var_35_5:setPosition(cc.p(var_35_2, var_35_3))

		if var_35_4 == var_0_5 then
			var_35_2 = 10
			var_35_3 = var_35_3 - var_35_6.height - 10
		else
			var_35_2 = var_35_2 + var_35_6.width + 10
		end

		var_35_4 = var_35_4 + 1
	end

	for iter_35_2 = var_35_4, 4 do
		local var_35_7 = arg_35_0:createPlayerTypeCell(arg_35_1):getChildByName("container")
		local var_35_8 = var_35_7:getContentSize()

		var_35_7:setAnchorPoint(cc.p(0, 1))
		var_35_7:setPosition(cc.p(var_35_2, var_35_3))

		if var_35_4 == var_0_5 then
			var_35_2 = 10
			var_35_3 = var_35_3 - var_35_8.height - 10
		else
			var_35_2 = var_35_2 + var_35_8.width + 10
		end

		var_35_4 = var_35_4 + 1
	end
end

function var_0_0.createPlayerTypeCell(arg_36_0, arg_36_1, arg_36_2, arg_36_3)
	local var_36_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/show_type_item.csb")

	var_36_0:addTo(arg_36_1)

	local var_36_1 = var_36_0:getChildByName("container")
	local var_36_2 = var_36_1:getContentSize()

	if arg_36_2 and arg_36_3 then
		local var_36_3 = xyd.tables.personDisplayWords:personDisplayDesc(tonumber(arg_36_2))
		local var_36_4 = arg_36_0:createTextLabel(var_36_3, nil, cc.c4b(152, 83, 53, 255), 20)
		local var_36_5
		local var_36_6
		local var_36_7

		if tonumber(arg_36_2) == xyd.PlayerCardShowType.CREATE_TIME then
			var_36_5 = os.date("%Y/%m/%d", tonumber(arg_36_3))
			var_36_7 = 16
		else
			var_36_5 = arg_36_3
			var_36_7 = 20
		end

		local var_36_8 = arg_36_0:createTextLabel(var_36_5, nil, cc.c4b(93, 77, 70, 255), var_36_7)
		local var_36_9 = 0
		local var_36_10 = var_36_4:getContentSize()
		local var_36_11 = var_36_8:getContentSize()
		local var_36_12 = display.newNode()

		var_36_12:setAnchorPoint(cc.p(0.5, 0.5))
		var_36_4:addTo(var_36_12)
		var_36_4:setAnchorPoint(cc.p(0, 0))
		var_36_4:setPosition(cc.p(0, 0))

		local var_36_13 = var_36_10.width

		var_36_8:addTo(var_36_12)
		var_36_8:setAnchorPoint(cc.p(0, 0))
		var_36_8:setPosition(cc.p(var_36_13, 0))

		local var_36_14 = var_36_13 + var_36_11.width

		var_36_12:setContentSize(var_36_14, var_36_10.height)
		var_36_12:addTo(var_36_1)
		var_36_12:setPosition(cc.p(var_36_2.width / 2, var_36_2.height / 2))
	end

	table.insert(arg_36_0.showtypesItems, var_36_1)
	var_36_0:setTouchEnabled(true)
	var_36_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_37_0)
		if arg_37_0.name == "began" then
			return true
		elseif arg_37_0.name == "ended" and arg_36_0.mainEditStatus then
			local var_37_0 = {
				callback = function()
					arg_36_0:createPlayerType(arg_36_1)
					arg_36_0:playHideEffect(arg_36_0.mainEditStatus, arg_36_0.rightPanel[xyd.PlayerCardButtonStyle.MAIN]:getChildByName("container"))
				end
			}

			arg_36_0.personDisplay:getAllShowTypeInfos(function(arg_39_0, arg_39_1)
				var_37_0.all_show_types = arg_39_1

				if arg_39_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("select_show_type", var_37_0)
				end
			end)
		end
	end)

	return var_36_0
end

function var_0_0.createHeroShow(arg_40_0, arg_40_1)
	arg_40_0.heroShowCardTips = {}

	arg_40_1:removeAllChildren()

	local var_40_0 = arg_40_1:getContentSize()
	local var_40_1 = 160
	local var_40_2 = 0
	local var_40_3 = arg_40_0.personDisplay:getShowCase()

	for iter_40_0 = 1, var_0_6 do
		if var_40_3[iter_40_0] and next(var_40_3[iter_40_0]) then
			local var_40_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_main/hero_card.csb")

			var_40_4:addTo(arg_40_1)

			local var_40_5 = var_40_4:getChildByName("container")

			var_40_4:setPosition(cc.p(var_40_2 + 25, 15))

			local var_40_6

			if var_40_3[iter_40_0].pet_id and var_40_3[iter_40_0].pet_id > 0 then
				local var_40_7 = var_0_4.new()

				var_40_7:populate(var_40_3[iter_40_0])
				arg_40_0:setPetAvatarCard(var_40_7, var_40_5, true)
			else
				local var_40_8 = var_0_3.new()

				var_40_8:populate(var_40_3[iter_40_0])

				local var_40_9 = var_40_5:getWidth()
				local var_40_10 = arg_40_0:initHeroCell(var_40_8, var_40_9)

				var_40_10:addTo(arg_40_1)
				var_40_10:setAnchorPoint(cc.p(0, 0))
				var_40_10:setPosition(cc.p(var_40_2 + 25, 18))
			end

			var_40_2 = var_40_2 + var_40_1

			var_40_4:setTouchEnabled(true)
			var_40_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_41_0)
				if arg_41_0.name == "began" then
					return true
				elseif arg_41_0.name == "ended" then
					if arg_40_0.mainEditStatus then
						local var_41_0 = {
							index = iter_40_0,
							callback = function()
								arg_40_0:createHeroShow(arg_40_1)
							end
						}

						xyd.WindowManager.get():openWindow("select_hero_card", var_41_0)
					else
						local var_41_1 = {
							index = iter_40_0,
							playerID = arg_40_0:getPlayerID()
						}

						arg_40_0.personDisplay:getShowcaseDetail(var_41_1, function(arg_43_0, arg_43_1)
							if arg_43_0 == xyd.error.OK then
								local var_43_0

								if arg_43_1.pet_id and arg_43_1.pet_id > 0 then
									var_43_0 = var_0_4.new()
								else
									var_43_0 = var_0_3.new()
								end

								arg_43_1.player_id = arg_40_0:getPlayerID()

								var_43_0:populate(arg_43_1)

								local var_43_1 = arg_40_0.personDisplay:getBasicInfo().player_info

								var_43_0.player_name = var_43_1.player_name
								var_43_0.player_lev = var_43_1.lev
								var_43_0.player_avatar = var_43_1.avatar_id
								var_43_0.player_avatar_frame = var_43_1.avatar_frame_id

								if not var_43_0.isPet_ and var_43_1.conquer_lev and var_43_1.conquer_lev > 0 then
									var_43_0:setConquerSchoolLev(var_43_1.conquer_lev, var_43_1.conquer_loop_id)
								end

								if var_43_0.isPet_ then
									xyd.WindowManager.get():openWindow("pet_attribute", var_43_0)
								else
									xyd.WindowManager.get():openWindow(xyd.WindowName.heroattributeWnd, var_43_0)
								end
							end
						end)
					end
				end
			end)
		else
			local var_40_11 = xyd.AssetLoader:get():loadSprite("windows/person_display/person_main/bg_blank.png")

			var_40_11:setScaleY(1.02)
			var_40_11:setAnchorPoint(cc.p(0, 0))
			var_40_11:addTo(arg_40_1)
			var_40_11:setPosition(cc.p(var_40_2 + 25, 15))

			var_40_2 = var_40_2 + var_40_1

			var_40_11:setTouchEnabled(true)
			var_40_11:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
				if arg_44_0.name == "began" then
					return true
				elseif arg_44_0.name == "ended" and arg_40_0.mainEditStatus then
					local var_44_0 = {
						index = iter_40_0,
						callback = function()
							arg_40_0:createHeroShow(arg_40_1)
						end
					}

					xyd.WindowManager.get():openWindow("select_hero_card", var_44_0)
				end
			end)

			if arg_40_0:checkPlayerIsYou() then
				local var_40_12 = var_40_11:getContentSize()
				local var_40_13 = arg_40_0:createTextLabel(var_0_1:translation("PERSON_CLICK_EDIT"), nil, cc.c4b(255, 255, 255, 255), 22, var_40_12.width - 10)

				var_40_13:enableOutline(xyd.color.GRAY, 1)
				var_40_13:addTo(var_40_11)
				var_40_13:setAnchorPoint(cc.p(0.5, 0.5))
				var_40_13:setPosition(cc.p(var_40_12.width / 2, var_40_12.height / 2))
				var_40_13:setVisible(arg_40_0.mainEditStatus)
				table.insert(arg_40_0.heroShowCardTips, var_40_13)
			end
		end
	end
end

function var_0_0.createMainBtn(arg_46_0, arg_46_1)
	arg_46_0.dormBtn = arg_46_1:getChildByName("btn_dorm")
	arg_46_0.mainPraiseBtn = arg_46_1:getChildByName("btn_praise_num")
	arg_46_0.mainPraiseNum = arg_46_1:getChildByName("btn_praise_num"):getChildByName("txt_praise_num")

	arg_46_0.mainPraiseBtn:setTouchEnabled(true)
	arg_46_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(true)
	arg_46_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(false)

	if arg_46_0:checkPlayerIsYou() then
		arg_46_0.mainPraiseBtn:setVisible(false)
		arg_46_1:getChildByName("btn_praise_num"):setVisible(false)
		arg_46_1:getChildByName("btn_blacklist"):setVisible(false)
		arg_46_1:getChildByName("btn_add_friend"):setVisible(false)
	elseif arg_46_0:checkBtnIsHide() then
		arg_46_0.mainPraiseBtn:setTouchEnabled(false)
		arg_46_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(false)
		arg_46_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(true)
		xyd.GrayNode(arg_46_0.mainPraiseBtn)
	elseif arg_46_0.personDisplay:getIsHasPraise() == 1 then
		arg_46_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(false)
		arg_46_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(true)
	end

	if not arg_46_0:checkPlayerIsYou() then
		arg_46_1:getChildByName("btn_achieve"):setVisible(false)
		arg_46_1:getChildByName("btn_hide"):setVisible(false)
		arg_46_1:getChildByName("btn_edit"):setVisible(false)

		if arg_46_0:checkCanAddFriend() == var_0_8.IN_BLACK then
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_after_black"):setVisible(true)
		else
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_after_black"):setVisible(false)
		end
	end

	arg_46_0.mainPraiseBtn:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_47_0)
		if arg_47_0.name == "began" then
			arg_46_0.mainPraiseBtn:setScale(0.9)

			return true
		elseif arg_47_0.name == "ended" then
			arg_46_0.mainPraiseBtn:setScale(1)

			local var_47_0 = arg_46_0:getPlayerID()

			arg_46_0.personDisplay:addPraise(var_47_0, function(arg_48_0, arg_48_1)
				if arg_48_0 == xyd.error.OK then
					local var_48_0 = arg_48_1.is_has_praise == 1

					arg_46_0.mainPraiseBtn:getChildByName("img_praise"):setVisible(not var_48_0)
					arg_46_0.mainPraiseBtn:getChildByName("img_praise_done"):setVisible(var_48_0)

					arg_46_0.praiseIsChange = true

					arg_46_0.mainPraiseNum:setString(arg_46_0.personDisplay:getPraiseNum())
				end
			end)
		end
	end)

	if arg_46_0:checkCanAddFriend() ~= var_0_8.CAN_ADD then
		arg_46_1:getChildByName("btn_add_friend"):setVisible(false)
	end

	arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add_select"):setVisible(false)
	arg_46_1:getChildByName("btn_add_friend"):addTouchEventListener(function(arg_49_0, arg_49_1)
		if arg_49_1 == ccui.TouchEventType.began then
			arg_46_1:getChildByName("btn_add_friend"):setScale(0.9)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add_select"):setVisible(true)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add"):setVisible(false)
		end

		if arg_49_1 == ccui.TouchEventType.ended then
			arg_46_1:getChildByName("btn_add_friend"):setScale(1)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add_select"):setVisible(false)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add"):setVisible(true)

			local var_49_0 = arg_46_0:checkCanAddFriend()

			if var_49_0 == var_0_8.CAN_ADD then
				local var_49_1 = {
					player_id = arg_46_0:getPlayerID()
				}
				local var_49_2 = {
					data = var_49_1
				}

				xyd.WindowManager.get():openWindow("input_authentic_msg", var_49_2)
			else
				local var_49_3
				local var_49_4 = arg_46_0.personDisplay:getPlayerName()

				if var_49_0 == var_0_8.IN_FRIEND then
					var_49_3 = string.format(var_0_1:translation("SOMEONE_IN_FRIEND"), var_49_4)
				elseif var_49_0 == var_0_8.IN_BLACK then
					var_49_3 = string.format(var_0_1:translation("SOMEONE_IN_BLACK"), var_49_4)
				elseif var_49_0 == var_0_8.FULL_FRIEND then
					var_49_3 = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_49_3
				})
			end
		end

		if arg_49_1 == ccui.TouchEventType.moved then
			arg_46_1:getChildByName("btn_add_friend"):setScale(1)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add_select"):setVisible(false)
			arg_46_1:getChildByName("btn_add_friend"):getChildByName("img_add"):setVisible(true)
		end
	end)

	if arg_46_0.personDisplay:checkIsRobot() then
		arg_46_1:getChildByName("btn_blacklist"):setVisible(false)
	end

	if not arg_46_0:isDormShow() then
		arg_46_0.dormBtn:setVisible(false)
	end

	arg_46_0.dormBtn:getChildByName("img_dorm_select"):setVisible(false)
	arg_46_0.dormBtn:addTouchEventListener(function(arg_50_0, arg_50_1)
		if arg_50_1 == ccui.TouchEventType.began then
			arg_46_0.dormBtn:setScale(0.9)
			arg_46_0.dormBtn:getChildByName("img_dorm"):setVisible(false)
			arg_46_0.dormBtn:getChildByName("img_dorm_select"):setVisible(true)
		elseif arg_50_1 == ccui.TouchEventType.ended then
			arg_46_0.dormBtn:setScale(1)
			arg_46_0.dormBtn:getChildByName("img_dorm"):setVisible(true)
			arg_46_0.dormBtn:getChildByName("img_dorm_select"):setVisible(false)

			local var_50_0 = {}

			if not arg_46_0:checkPlayerIsYou() then
				var_50_0.host_id = arg_46_0:getPlayerID()
				var_50_0.host_info = arg_46_0.personDisplay.playerInfo
			end

			arg_46_0.dorm:getHouseList(var_50_0, function(arg_51_0, arg_51_1)
				if arg_51_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("dorm")
					xyd.WindowManager.get():closeWindow(arg_46_0)

					local var_51_0 = xyd.WindowManager.get():getWindow("new_rank_list")
					local var_51_1 = xyd.WindowManager.get():getWindow("person_display")
					local var_51_2 = xyd.WindowManager.get():getWindow("chat")

					if var_51_0 and not tolua.isnull(var_51_0) then
						xyd.WindowManager.get():closeWindow("new_rank_list")
					end

					if var_51_1 and not tolua.isnull(var_51_1) then
						xyd.WindowManager.get():closeWindow("person_display")
					end

					if var_51_2 and not tolua.isnull(var_51_2) then
						xyd.WindowManager.get():closeWindow("chat")
					end
				end
			end)
		end

		if arg_50_1 == ccui.TouchEventType.moved then
			arg_46_0.dormBtn:setScale(1)
			arg_46_0.dormBtn:getChildByName("img_dorm"):setVisible(true)
			arg_46_0.dormBtn:getChildByName("img_dorm_select"):setVisible(false)
		end
	end)

	if arg_46_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_ACHIEVE) then
		arg_46_0:updateRedPointShow(arg_46_1:getChildByName("btn_achieve"))
		arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve_select"):setVisible(false)
		arg_46_1:getChildByName("btn_achieve"):addTouchEventListener(function(arg_52_0, arg_52_1)
			if arg_52_1 == ccui.TouchEventType.began then
				arg_46_1:getChildByName("btn_achieve"):setScale(0.9)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve"):setVisible(false)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve_select"):setVisible(true)
			end

			if arg_52_1 == ccui.TouchEventType.ended then
				arg_46_1:getChildByName("btn_achieve"):setScale(1)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve"):setVisible(true)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve_select"):setVisible(false)
				arg_46_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.ACHIEVEMENT)
				xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT):loadAchievementInfo({}, function(arg_53_0, arg_53_1)
					if arg_53_0 == xyd.error.OK then
						local var_53_0 = {
							callback = function()
								if arg_46_0 and not tolua.isnull(arg_46_0) then
									arg_46_0:updateRedPointShow(arg_52_0)
								end
							end
						}

						xyd.WindowManager.get():openWindow("achievement", var_53_0)

						local var_53_1 = xyd.WindowManager.get():getWindow("main_scene_top")

						if var_53_1 then
							var_53_1:updateAchievementRedMark()
						end
					end
				end)
			end

			if arg_52_1 == ccui.TouchEventType.moved then
				arg_46_1:getChildByName("btn_achieve"):setScale(1)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve"):setVisible(true)
				arg_46_1:getChildByName("btn_achieve"):getChildByName("img_achieve_select"):setVisible(false)
			end
		end)
	else
		arg_46_1:getChildByName("btn_achieve"):setVisible(false)
	end

	arg_46_0.mainEditStatus = false
	arg_46_0.mainBtnEdit = arg_46_1:getChildByName("btn_edit")

	arg_46_0.mainBtnEdit:getChildByName("img_edit_select"):setVisible(false)
	arg_46_1:getChildByName("btn_edit"):addTouchEventListener(function(arg_55_0, arg_55_1)
		if arg_55_1 == ccui.TouchEventType.began then
			arg_46_0.mainBtnEdit:setScale(0.9)
			arg_46_0.mainBtnEdit:setBrightStyle(ccui.BrightStyle.highlight)
			arg_46_0.mainBtnEdit:getChildByName("img_edit"):setVisible(false)
			arg_46_0.mainBtnEdit:getChildByName("img_edit_select"):setVisible(true)
		elseif arg_55_1 == ccui.TouchEventType.ended then
			arg_46_0.mainBtnEdit:setScale(1)
			arg_46_0.mainBtnEdit:getChildByName("img_edit"):setVisible(true)
			arg_46_0.mainBtnEdit:getChildByName("img_edit_select"):setVisible(false)
			arg_46_0:updateEditStatus()
		end

		if arg_55_1 == ccui.TouchEventType.moved then
			arg_46_0.mainBtnEdit:setScale(1)
			arg_46_0.mainBtnEdit:getChildByName("img_edit"):setVisible(true)
			arg_46_0.mainBtnEdit:getChildByName("img_edit_select"):setVisible(false)
		end
	end)

	local var_46_0 = display.newNode()

	var_46_0:setContentSize(arg_46_1:getChildByName("bg_name"):getContentSize())
	var_46_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_46_0:setPosition(arg_46_1:getChildByName("bg_name"):getPosition())
	var_46_0:addTo(arg_46_1)
	var_46_0:setTouchEnabled(true)
	var_46_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_56_0)
		if arg_56_0.name == "began" then
			return true
		elseif arg_56_0.name == "ended" and arg_46_0.mainEditStatus then
			local var_56_0 = {
				callback = function(arg_57_0)
					local var_57_0 = {
						player_name = arg_46_0.selfPlayer.playerName
					}

					arg_46_0.personDisplay:updatePlayerInfo(var_57_0)
					arg_46_1:getChildByName("txt_name"):setString(arg_46_0.selfPlayer.playerName)
				end
			}

			xyd.WindowManager.get():openWindow("edit_player_name", var_56_0)
		end
	end)
	arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide_select"):setVisible(false)
	arg_46_1:getChildByName("btn_hide"):addTouchEventListener(function(arg_58_0, arg_58_1)
		if arg_58_1 == ccui.TouchEventType.began then
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide"):setVisible(false)
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide_select"):setVisible(true)
			arg_46_1:getChildByName("btn_hide"):setScale(0.9)
		elseif arg_58_1 == ccui.TouchEventType.ended then
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide"):setVisible(true)
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide_select"):setVisible(false)
			arg_46_1:getChildByName("btn_hide"):setScale(1)
			xyd.WindowManager.get():openWindow("select_person_hide")
		end

		if arg_58_1 == ccui.TouchEventType.moved then
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide"):setVisible(true)
			arg_46_1:getChildByName("btn_hide"):getChildByName("img_hide_select"):setVisible(false)
			arg_46_1:getChildByName("btn_hide"):setScale(1)
		end
	end)
	arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist_select"):setVisible(false)
	arg_46_1:getChildByName("btn_blacklist"):addTouchEventListener(function(arg_59_0, arg_59_1)
		if arg_59_1 == ccui.TouchEventType.began then
			arg_46_1:getChildByName("btn_blacklist"):setScale(0.9)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist"):setVisible(false)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist_select"):setVisible(true)

			return true
		elseif arg_59_1 == ccui.TouchEventType.ended then
			arg_46_1:getChildByName("btn_blacklist"):setScale(1)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist"):setVisible(true)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist_select"):setVisible(false)

			local var_59_0
			local var_59_1 = arg_46_0:checkCanAddFriend() ~= var_0_8.IN_BLACK and true or false
			local var_59_2

			if var_59_1 then
				var_59_2 = string.format(var_0_1:translation("PERSON_SHIELDING_ONE_MAN"), arg_46_0.personDisplay:getPlayerName())
			else
				var_59_2 = string.format(var_0_1:translation("REMOVE_ONE_MAN_IN_BLACK"), arg_46_0.personDisplay:getPlayerName())
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_59_2, function()
				local var_60_0 = {
					player_id = arg_46_0:getPlayerID()
				}
				local var_60_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)

				if var_59_1 then
					var_60_1:addBlackList(var_60_0, function(arg_61_0, arg_61_1)
						if arg_61_0 == xyd.error.OK then
							arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_after_black"):setVisible(true)
							arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist"):setVisible(false)

							if var_60_1.blacklist then
								table.insert(var_60_1.blacklist, arg_61_1.player_info)
							end
						end
					end)
				else
					var_60_1:removeBlackList(var_60_0, function(arg_62_0, arg_62_1)
						if arg_62_0 == xyd.error.OK then
							var_60_1:removeOnefromBlack(arg_46_0:getPlayerID())
							arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist"):setVisible(true)
							arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_after_black"):setVisible(false)
						end
					end)
				end
			end, nil, nil, arg_46_0.colorMode)
		end

		if arg_59_1 == ccui.TouchEventType.moved then
			arg_46_1:getChildByName("btn_blacklist"):setScale(1)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist"):setVisible(true)
			arg_46_1:getChildByName("btn_blacklist"):getChildByName("img_blacklist_select"):setVisible(false)
		end
	end)
end

function var_0_0.updateRedPointShow(arg_63_0, arg_63_1)
	local var_63_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.ACHIEVEMENT)

	if var_63_0:getCanAwardLev() > 0 or var_63_0.isHasNewNotice then
		var_63_0.isHasNewNotice = false

		arg_63_1:getChildByName("red_point"):setVisible(true)
	else
		arg_63_1:getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.updateEditStatus(arg_64_0)
	local var_64_0 = arg_64_0.rightPanel[xyd.PlayerCardButtonStyle.MAIN]

	if var_64_0 and not tolua.isnull(var_64_0) then
		arg_64_0.mainEditStatus = not arg_64_0.mainEditStatus

		if arg_64_0.mainBtnEdit and not tolua.isnull(arg_64_0.mainBtnEdit) then
			arg_64_0.mainBtnEdit:setBrightStyle(arg_64_0.mainEditStatus and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
		end

		arg_64_0:playHideEffect(arg_64_0.mainEditStatus, var_64_0:getChildByName("container"))

		for iter_64_0 = 1, #arg_64_0.heroShowCardTips do
			arg_64_0.heroShowCardTips[iter_64_0]:setVisible(arg_64_0.mainEditStatus)
		end

		if arg_64_0.firstGuideHand then
			arg_64_0.firstGuideHand:removeSelf()
			arg_64_0.personDisplay:updateFirstTime(0)

			arg_64_0.firstGuideHand = nil
		end
	end
end

function var_0_0.createHistory(arg_65_0)
	local var_65_0 = arg_65_0:nodeByName("container_right")
	local var_65_1 = var_65_0:getContentSize()

	arg_65_0.historyList_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 20, var_65_1.width, var_65_1.height - 50),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_65_0):onScroll(handler(arg_65_0, arg_65_0.scrollListener)):setTouchType(true):setBounceable(true):pos(0, 0)
	arg_65_0.rightPanel[arg_65_0.leftBtnStyle] = arg_65_0.historyList_

	for iter_65_0, iter_65_1 in pairs(xyd.PlayerCardHistory) do
		local var_65_2 = arg_65_0.historyList_:newItem()
		local var_65_3 = display.newNode()
		local var_65_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_history/hero_report_item.csb")

		arg_65_0:createBasicHistory(var_65_4, iter_65_1)
		var_65_3:setContentSize(cc.size(878, 220))
		var_65_4:addTo(var_65_3)
		var_65_4:setTouchEnabled(true)
		var_65_4:setTouchSwallowEnabled(false)
		var_65_2:addContent(var_65_3)
		var_65_2:setPosition(cc.p(0, 220 * (iter_65_1 - 1)))
		var_65_2:setItemSize(878, 220)
		arg_65_0.historyList_:addItem(var_65_2)
	end

	arg_65_0.historyList_:reload()
end

function var_0_0.scrollListener(arg_66_0, arg_66_1)
	if arg_66_1.name == "began" then
		arg_66_0.scrollViewMoved_ = false
		arg_66_0.prevY_ = arg_66_1.y
	elseif arg_66_1.name == "moved" and 10 <= math.abs(arg_66_1.y - arg_66_0.prevY_) then
		arg_66_0.scrollViewMoved_ = true
	end
end

function var_0_0.createSpace(arg_67_0)
	local var_67_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_space/person_space.csb")

	var_67_0:addTo(arg_67_0:nodeByName("container_right"))

	local var_67_1 = var_67_0:getChildByName("container")

	arg_67_0.rightPanel[arg_67_0.leftBtnStyle] = var_67_0

	local var_67_2 = arg_67_0.personDisplay:getPraiseNum()

	var_67_1:getChildByName("bg_to_praise"):getChildByName("txt_praise_num"):setString(var_67_2)

	local var_67_3 = {
		size = 535,
		offset = 5,
		align = xyd.SplitLineAlign.CENTER
	}
	local var_67_4 = import("app.common.ui.SplitLine").new(var_67_3)

	var_67_4:addTo(var_67_1)
	var_67_4:setPosition(var_67_1:getChildByName("split_line"):getPosition())
	var_67_4:setRotation(90)

	arg_67_0.textSendContent = var_67_1:getChildByName("txt_send_content")

	arg_67_0.textSendContent:setString(var_0_1:translation("PERSON_ZONE_TIP_COMMENT"))

	arg_67_0.myIntroduce = arg_67_0.personDisplay:getIntroduce()

	local var_67_5 = "windows/login/transparent.png"

	if arg_67_0:checkPlayerIsYou() then
		local var_67_6 = var_67_1:getChildByName("txt_my_intro")

		var_67_6:setString(arg_67_0.myIntroduce == "" and var_0_1:translation("PERSON_ZONE_TIP_EDIT") or arg_67_0.myIntroduce)

		arg_67_0.editbox_ = ccui.EditBox:create(cc.size(180, 115), var_67_5)

		arg_67_0.editbox_:addTo(var_67_1)
		arg_67_0.editbox_:setAnchorPoint(cc.p(0.5, 0.5))
		arg_67_0.editbox_:setPosition(var_67_6:getPosition())
		arg_67_0.editbox_:setFontSize(24)
		arg_67_0.editbox_:setInputFlag(3)
		arg_67_0.editbox_:setFontColor(cc.c3b(143, 136, 126))
		arg_67_0.editbox_:registerScriptEditBoxHandler(function(arg_68_0)
			if arg_68_0 == "began" then
				arg_67_0.editbox_:setText(var_67_6:getString())
			end

			if arg_68_0 == "return" then
				local var_68_0 = arg_67_0.editbox_:getText()

				if xyd.utf8len(var_68_0) > 40 then
					var_68_0 = xyd.getTextstr(var_68_0, 1, 40)
				end

				if var_68_0 ~= arg_67_0.myIntroduce then
					arg_67_0.personDisplay:modifyIntro(var_68_0, function(arg_69_0, arg_69_1)
						if arg_69_0 == xyd.error.OK then
							arg_67_0.myIntroduce = arg_67_0.personDisplay:getIntroduce()

							var_67_6:setString(arg_67_0.myIntroduce)
						end
					end)
				end

				arg_67_0.editbox_:setText("")
				arg_67_0.editbox_:setVisible(true)
			end
		end)
		var_67_1:getChildByName("bg_edit_bottom"):setVisible(false)
		var_67_1:getChildByName("bg_edit"):setVisible(false)
		var_67_1:getChildByName("box_edit"):setVisible(false)
		var_67_1:getChildByName("txt_send_content"):setVisible(false)
		var_67_1:getChildByName("btn_send"):setVisible(false)
		var_67_1:getChildByName("btn_to_add"):setVisible(false)
		var_67_1:getChildByName("btn_to_black"):setVisible(false)
		var_67_1:getChildByName("btn_to_prise"):setPosition(cc.p(778, 195))
		var_67_1:getChildByName("bg_to_praise"):setPosition(cc.p(776, 125))
	else
		arg_67_0.sendContentText = ""

		var_67_1:getChildByName("txt_my_intro"):setVisible(true)
		var_67_1:getChildByName("txt_my_intro"):setString(arg_67_0.myIntroduce == "" and var_0_1:translation("PERSON_ZONE_TIP_NOT_EDIT") or arg_67_0.myIntroduce)

		local var_67_7 = var_67_1:getChildByName("box_edit"):getContentSize()

		arg_67_0.sendContent = ccui.EditBox:create(var_67_7, var_67_5)

		var_67_1:getChildByName("box_edit"):addChild(arg_67_0.sendContent)
		arg_67_0.sendContent:setAnchorPoint(cc.p(0, 0))
		arg_67_0.sendContent:setPosition(0, 0)
		arg_67_0.sendContent:registerScriptEditBoxHandler(handler(arg_67_0, arg_67_0.sendContentbox))
		arg_67_0.sendContent:setInputFlag(3)
	end

	arg_67_0.spaceCommentPage = 1
	arg_67_0.spaceInfos = arg_67_0.personDisplay:getCommentInfos(arg_67_0.spaceCommentPage)

	arg_67_0:createSpaceList(var_67_1:getChildByName("list"))
	arg_67_0:createSpaceBtn(var_67_1)
end

function var_0_0.createHelp(arg_70_0)
	local var_70_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_help/person_help.csb")

	var_70_0:addTo(arg_70_0:nodeByName("container_right"))

	local var_70_1 = var_70_0:getChildByName("container")

	var_70_1:getChildByName("bg_help_title"):getChildByName("txt_help_title"):setString(var_0_1:translation("PERSON_DISPLAY_HELP"))

	local var_70_2 = var_70_1:getChildByName("btn_ai")
	local var_70_3 = var_70_1:getChildByName("btn_question")
	local var_70_4 = var_70_1:getChildByName("btn_questionnaire")

	var_70_2:getChildByName("txt_btn_ai"):setString(var_0_1:translation("PERSON_HELP_AI_TEXT"))
	var_70_2:addTouchEventListener(function(arg_71_0, arg_71_1)
		xyd.buttonScaleAnim(arg_71_0, arg_71_1)

		if arg_71_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.showAiHelp()
		end
	end)
	var_70_3:getChildByName("txt_btn_question"):setString(var_0_1:translation("PERSON_HELP_FAQ_TEXT"))
	var_70_3:addTouchEventListener(function(arg_72_0, arg_72_1)
		xyd.buttonScaleAnim(arg_72_0, arg_72_1)

		if arg_72_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.showAiHelpFAQ()
		end
	end)
	var_70_4:getChildByName("txt_btn_questionnaire"):setString(var_0_1:translation("PERSON_HELP_QUERY_TEXT"))
	var_70_4:addTouchEventListener(function(arg_73_0, arg_73_1)
		xyd.buttonScaleAnim(arg_73_0, arg_73_1)

		if arg_73_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_73_0 = xyd.tables.misc:getValue("person_display_help_query")

			cc.Application:getInstance():openURL(var_73_0)
		end
	end)

	arg_70_0.rightPanel[arg_70_0.leftBtnStyle] = var_70_0
end

function var_0_0.createSystem(arg_74_0)
	local var_74_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/sysconfig/sysconfig.csb")

	var_74_0:addTo(arg_74_0:nodeByName("container_right"))

	local var_74_1 = var_74_0:getChildByName("container")

	arg_74_0.rightPanel[arg_74_0.leftBtnStyle] = var_74_0

	arg_74_0:createBasicSystem(var_74_1)
end

function var_0_0.initPlayerAvatar(arg_75_0, arg_75_1, arg_75_2, arg_75_3)
	arg_75_1:getChildByName("avatar"):removeAllChildren()

	local var_75_0 = {
		avatar_id = tonumber(arg_75_2),
		avatar_frame_id = arg_75_3,
		callback = function(arg_76_0)
			if arg_76_0.name == "began" then
				return true
			elseif arg_76_0.name == "ended" and arg_75_0.mainEditStatus then
				local var_76_0 = {
					callback = function(arg_77_0)
						local var_77_0 = {
							avatar_id = arg_77_0.avatar_id,
							avatar_frame_id = arg_77_0.avatar_frame_id
						}

						arg_75_0.personDisplay:updatePlayerInfo(var_77_0)
						arg_75_0:initPlayerAvatar(arg_75_1, arg_77_0.avatar_id, arg_77_0.avatar_frame_id)
						arg_75_0:initPlayerTitle(arg_75_1, arg_77_0.title_info)
					end
				}

				xyd.WindowManager.get():openWindow("new_change_avatar", var_76_0)
			end
		end
	}

	xyd.setPlayerAvatar(arg_75_1:getChildByName("avatar"), var_75_0)
end

function var_0_0.initPlayerTitle(arg_78_0, arg_78_1, arg_78_2)
	local var_78_0 = arg_78_1:getChildByName("container_chenhao")
	local var_78_1 = arg_78_1:getChildByName("txt_chenhao")

	if not arg_78_2 or not arg_78_2.title_id or arg_78_2.title_id == 0 then
		var_78_1:setString(var_0_1:translation("PERSON_NO_TITLE"))
		var_78_1:setVisible(true)
		var_78_0:setVisible(false)
	else
		var_78_1:setVisible(false)
		var_78_0:setVisible(true)
		var_78_0:removeAllChildren()
		xyd.setPlayerTitle(var_78_0, arg_78_2)
		var_78_0:getChildByName("node"):setTouchSwallowEnabled(true)
		var_78_0:getChildByName("node"):setTouchEnabled(true)
		var_78_0:getChildByName("node"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_79_0)
			if arg_79_0.name == "began" then
				return true
			elseif arg_79_0.name == "ended" and arg_78_0.mainEditStatus then
				xyd.Backend.get():request(xyd.mid.GET_TITLE_INFO, nil, function(arg_80_0, arg_80_1)
					if arg_80_0 == xyd.error.OK then
						local var_80_0 = {
							menuType = 3,
							callback = function(arg_81_0)
								local var_81_0 = {
									avatar_id = arg_81_0.avatar_id,
									avatar_frame_id = arg_81_0.avatar_frame_id
								}

								arg_78_0.personDisplay:updatePlayerInfo(var_81_0)
								arg_78_0:initPlayerAvatar(arg_78_1, arg_81_0.avatar_id, arg_81_0.avatar_frame_id)
								arg_78_0:initPlayerTitle(arg_78_1, arg_81_0.title_info)
							end,
							titleInfo = arg_80_1.title_list
						}

						xyd.WindowManager.get():openWindow("new_change_avatar", var_80_0)
					end
				end)
			end
		end)
	end
end

function var_0_0.createBasicSystem(arg_82_0, arg_82_1)
	arg_82_0.systemListView_ = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 750, 540),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_82_1:getChildByName("list"))

	arg_82_0.systemListView_:setAnchorPoint(cc.p(0, 1))

	arg_82_0.blackList = {}
	arg_82_0.soundSwitch = xyd.db.settings:getSoundEffect()
	arg_82_0.musicSwitch = xyd.db.settings:getBackgroudMusicOn()
	arg_82_0.dialogSwitch = xyd.db.settings:getAutoDialog()
	arg_82_0.standbySwitch = xyd.db.settings:getAutoStandby()
	arg_82_0.live2dSwitch = xyd.db.settings:getLive2dOn()
	arg_82_0.isReviewServer = false

	if xyd.Backend.get().GMURL_ ~= nil then
		arg_82_0.isReviewServer = true
	end

	arg_82_0:systemLayout(arg_82_1)
end

function var_0_0.systemLayout(arg_83_0, arg_83_1)
	local var_83_0 = arg_83_0.systemListView_:newItem()
	local var_83_1 = display.newNode()
	local var_83_2 = import("app.windows.SwitchItem"):new()
	local var_83_3 = {
		voiceSwitch = arg_83_0.soundSwitch,
		musicSwitch = arg_83_0.musicSwitch,
		dialogSwitch = arg_83_0.dialogSwitch,
		standbySwitch = arg_83_0.standbySwitch,
		live2dSwitch = arg_83_0.live2dSwitch
	}

	var_83_2:setParams(var_83_3)
	var_83_2:setCodeVisible(not arg_83_0.isReviewServer)
	var_83_1:addChild(var_83_2)
	var_83_2:pos(0, 510)
	var_83_2:setAnchorPoint(cc.p(0, 1))
	var_83_2:ignoreAnchorPointForPosition(false)

	local var_83_4 = import("app.windows.MessagePushItem").new()

	var_83_1:addChild(var_83_4)
	var_83_4:pos(0, 40)
	var_83_1:setContentSize(750, 890)
	var_83_0:addContent(var_83_1)
	var_83_0:setItemSize(750, 890)
	arg_83_0.systemListView_:addItem(var_83_0)
	arg_83_0.systemListView_:reload()
end

function var_0_0.createBasicHistory(arg_84_0, arg_84_1, arg_84_2)
	local var_84_0 = arg_84_1:getChildByName("container")
	local var_84_1 = arg_84_0.personDisplay:getHistoryInfo(arg_84_2)
	local var_84_2 = var_84_1.arena_info or {}

	arg_84_0.historyPartners = var_84_1.partners_info or var_84_1.partner_info

	local var_84_3 = var_84_2.win_fight or var_84_2.win_times

	if arg_84_0:checkBtnIsHide(xyd.PlayerCardButtonStyle.HISTORY) or arg_84_0.personDisplay:checkIsRobot() then
		var_84_2 = {}
		arg_84_0.historyPartners = {}
		var_84_3 = nil
	end

	var_84_0:getChildByName("txt_name"):setString(var_0_11[arg_84_2])
	var_84_0:getChildByName("txt_show"):setString(var_0_12)

	local var_84_4

	if arg_84_2 == xyd.PlayerCardHistory.REGION_ARENA then
		var_84_4 = var_0_1:translation("PERSON_HISTORY_TIPS_8")
	else
		var_84_4 = var_0_1:translation("PERSON_HISTORY_TIPS_2")
	end

	local var_84_5 = var_84_2.rank or var_84_2.king_coin
	local var_84_6 = var_0_1:translation("PERSON_HISTORY_TIPS_3")
	local var_84_7 = var_84_2.total_fight
	local var_84_8 = var_0_1:translation("PERSON_HISTORY_TIPS_4")
	local var_84_9 = var_84_3

	arg_84_0:createHistoryLabel(var_84_0, "txt_rank", var_84_4, var_84_5)
	arg_84_0:createHistoryLabel(var_84_0, "txt_challenge", var_84_6, var_84_7)
	arg_84_0:createHistoryLabel(var_84_0, "txt_win", var_84_8, var_84_9)
	var_84_0:getChildByName("txt_best_hero"):setString(var_0_1:translation("PERSON_HISTORY_TIPS_7"))
	arg_84_0:initHistoryIsShow(var_84_0, arg_84_2)
	arg_84_0:sortHerosInfo(arg_84_0.historyPartners)
	arg_84_0:createHistoryUseHeros(var_84_0:getChildByName("container_use_hero"), arg_84_0.historyPartners, arg_84_2)

	local var_84_10 = clone(arg_84_0.historyPartners)

	arg_84_0:sortBestHeros(var_84_10)
	var_84_0:getChildByName("container_hero"):removeAllChildren()

	if var_84_10 and next(var_84_10) then
		local var_84_11 = var_0_3.new()

		var_84_11:populate(var_84_10[1])

		if arg_84_2 == xyd.PlayerCardHistory.REGION_ARENA then
			xyd.formatRegionArenaHeros({
				var_84_11
			})
		end

		xyd.setAvatarBorder(var_84_11, var_84_0:getChildByName("container_hero"))
	end
end

function var_0_0.initHistoryIsShow(arg_85_0, arg_85_1, arg_85_2)
	arg_85_1:getChildByName("txt_show"):setVisible(false)
	arg_85_1:getChildByName("bg_show"):setVisible(false)
	arg_85_1:getChildByName("bg_close"):setVisible(false)
end

function var_0_0.createHistoryLabel(arg_86_0, arg_86_1, arg_86_2, arg_86_3, arg_86_4)
	local var_86_0 = {
		size = 22,
		text = arg_86_3,
		color = cc.c3b(152, 83, 53),
		align = cc.ui.TEXT_ALIGN_LEFT
	}

	arg_86_0.textLabelA = xyd.AssetLoader.get():loadLabel(var_86_0)

	arg_86_0.textLabelA:setPosition(arg_86_1:getChildByName(arg_86_2):getPosition())
	arg_86_0.textLabelA:setAnchorPoint(cc.p(0, 0.5))
	arg_86_0.textLabelA:addTo(arg_86_1)

	if arg_86_4 then
		local var_86_1 = {
			size = 22,
			text = arg_86_4,
			color = cc.c3b(0, 0, 0),
			align = cc.ui.TEXT_ALIGN_LEFT
		}

		arg_86_0.textLabelB = xyd.AssetLoader.get():loadLabel(var_86_1)

		arg_86_0.textLabelB:setPosition(cc.p(arg_86_0.textLabelA:getPositionX() + arg_86_0.textLabelA:getContentSize().width, arg_86_0.textLabelA:getPositionY()))
		arg_86_0.textLabelB:setAnchorPoint(cc.p(0, 0.5))
		arg_86_0.textLabelB:addTo(arg_86_1)
	end
end

function var_0_0.createHistoryUseHeros(arg_87_0, arg_87_1, arg_87_2, arg_87_3)
	arg_87_1:removeAllChildren()

	local var_87_0 = 0
	local var_87_1 = arg_87_1:getContentSize().height
	local var_87_2 = #arg_87_2 < var_0_7 and #arg_87_2 or var_0_7

	for iter_87_0 = 1, var_87_2 do
		local var_87_3 = arg_87_2[iter_87_0]
		local var_87_4 = display.newNode()

		var_87_4:setContentSize(var_87_1, var_87_1)

		local var_87_5 = var_0_3.new()

		var_87_5:populate(var_87_3)

		if arg_87_3 == xyd.PlayerCardHistory.REGION_ARENA then
			xyd.formatRegionArenaHeros({
				var_87_5
			})
		end

		xyd.setAvatarBorder(var_87_5, var_87_4)
		var_87_4:addTo(arg_87_1)
		var_87_4:setPosition(var_87_0, 0)

		var_87_0 = var_87_0 + var_87_1 + 5
	end
end

function var_0_0.sortHerosInfo(arg_88_0, arg_88_1)
	table.sort(arg_88_1, function(arg_89_0, arg_89_1)
		if arg_89_0.total_fight ~= arg_89_1.total_fight then
			return arg_89_0.total_fight > arg_89_1.total_fight
		end
	end)
end

function var_0_0.sortBestHeros(arg_90_0, arg_90_1)
	for iter_90_0, iter_90_1 in pairs(arg_90_1) do
		local var_90_0

		if iter_90_1.total_fight > 0 then
			var_90_0 = iter_90_1.win_fight / iter_90_1.total_fight
			iter_90_1.perKill = iter_90_1.total_kill / iter_90_1.total_fight
			iter_90_1.perDamage = iter_90_1.total_damage / iter_90_1.total_fight
		else
			var_90_0 = 0
			iter_90_1.perKill = 0
			iter_90_1.perDamage = 0
		end

		iter_90_1.best = var_90_0 * iter_90_1.total_fight
	end

	table.sort(arg_90_1, function(arg_91_0, arg_91_1)
		if arg_91_0.best ~= arg_91_1.best then
			return arg_91_0.best > arg_91_1.best
		elseif arg_91_0.total_fight ~= arg_91_1.total_fight then
			return arg_91_0.total_fight > arg_91_1.total_fight
		elseif arg_91_0.perKill ~= arg_91_1.perKill then
			return arg_91_0.perKill > arg_91_1.perKill
		elseif arg_91_0.perDamage ~= arg_91_1.perDamage then
			return arg_91_0.perDamage > arg_91_1.perDamage
		end
	end)
end

function var_0_0.sendContentbox(arg_92_0, arg_92_1)
	if arg_92_1 == "began" then
		arg_92_0.sendContent:setText(arg_92_0.sendContentText)
		arg_92_0.textSendContent:setString("")
	elseif arg_92_1 == "return" then
		local var_92_0 = arg_92_0.filterWord:warningStrGsub(arg_92_0.sendContent:getText())

		if xyd.utf8len(var_92_0) > 30 then
			var_92_0 = xyd.getTextstr(var_92_0, 1, 30)
		end

		arg_92_0.sendContentText = var_92_0

		arg_92_0.textSendContent:setString(var_92_0)
		arg_92_0.sendContent:setText("")
		arg_92_0.sendContent:setVisible(true)
	end
end

function var_0_0.createSpaceList(arg_93_0, arg_93_1)
	if not arg_93_0.spaceList then
		local var_93_0 = arg_93_1:getContentSize()
		local var_93_1 = var_93_0.height
		local var_93_2 = 0

		if not arg_93_0:checkPlayerIsYou() then
			var_93_2 = 70
			var_93_1 = var_93_1 - var_93_2
		end

		arg_93_0.spaceList = cc.ui.UIListView.new({
			async = true,
			viewRect = cc.rect(0, 0, var_93_0.width, var_93_1),
			direction = cc.ui.UIListView.DIRECTION_VERTICAL,
			alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
		}):addTo(arg_93_1):pos(0, var_93_2)

		arg_93_0.spaceList:setDelegate(handler(arg_93_0, arg_93_0.spaceDelegate))
	end

	arg_93_0.spaceList:removeAllItems()

	if arg_93_0.spaceInfos or next(arg_93_0.spaceInfos) then
		if arg_93_0:checkBtnIsHide(xyd.PlayerCardButtonStyle.SPACE) then
			arg_93_0.spaceInfos = {}
		end

		arg_93_0.spaceList:reload()
	end
end

function var_0_0.spaceDelegate(arg_94_0, arg_94_1, arg_94_2, arg_94_3)
	local var_94_0 = #arg_94_0.spaceInfos

	if cc.ui.UIListView.COUNT_TAG == arg_94_2 then
		return var_94_0
	elseif cc.ui.UIListView.CELL_TAG == arg_94_2 then
		if arg_94_3 > #arg_94_0.spaceInfos then
			return
		end

		local var_94_1
		local var_94_2
		local var_94_3
		local var_94_4 = arg_94_0.spaceList:dequeueItem()

		if not var_94_4 then
			var_94_4 = arg_94_0.spaceList:newItem()
		else
			var_94_4:removeAllChildren()
		end

		local var_94_5 = display.newNode()

		var_94_5:setTouchSwallowEnabled(false)

		local var_94_6 = display.newNode()

		arg_94_0:initSpaceCell(var_94_6, arg_94_3)
		var_94_5:addChild(var_94_6)
		var_94_5:setContentSize(cc.size(arg_94_0.spaceList.viewRect_.width, var_94_6:getContentSize().height + 10))
		var_94_4:setItemSize(arg_94_0.spaceList.viewRect_.width, var_94_6:getContentSize().height + 10)
		var_94_4:addContent(var_94_5)

		return var_94_4
	end
end

function var_0_0.initSpaceCell(arg_95_0, arg_95_1, arg_95_2)
	if arg_95_2 > #arg_95_0.spaceInfos then
		return
	end

	local var_95_0 = arg_95_0.spaceInfos[arg_95_2]
	local var_95_1 = var_95_0.from_player_info
	local var_95_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/person_display/person_space/comment_item.csb")
	local var_95_3 = var_95_2:getChildByName("container")
	local var_95_4 = var_95_3:getContentSize()

	arg_95_1:setContentSize(var_95_4.width + 10, var_95_4.height)
	var_95_2:addTo(arg_95_1)
	var_95_2:setPosition(cc.p(0, 0))

	local var_95_5 = {
		avatar_id = tonumber(var_95_1.avatar_id),
		avatar_frame_id = var_95_1.avatar_frame_id,
		playerInfo = var_95_1
	}

	xyd.setPlayerAvatar(var_95_3:getChildByName("avatar"), var_95_5)

	if var_95_1.conquer_lev and var_95_1.conquer_lev > 0 then
		xyd.setConquerLev(var_95_1.conquer_lev, var_95_3:getChildByName("txt_level"), var_95_3:getChildByName("bg_level_circle"), nil, nil, nil, nil, var_95_1.conquer_loop_id)
	else
		var_95_3:getChildByName("txt_level"):setString(var_95_1.lev)
	end

	var_95_3:getChildByName("txt_name"):setString(var_95_1.player_name)
	var_95_3:getChildByName("txt_content"):setString(var_95_0.content)

	if var_95_0.isBest then
		var_95_3:getChildByName("best"):setVisible(true)
	else
		var_95_3:getChildByName("best"):setVisible(false)
	end

	local var_95_6 = var_95_3:getChildByName("btn_del")

	if arg_95_0:checkPlayerIsYou() then
		var_95_6:getChildByName("icon_del"):setVisible(true)
		var_95_6:getChildByName("icon_prise"):setVisible(false)
	else
		var_95_6:getChildByName("icon_del"):setVisible(false)
		var_95_6:getChildByName("icon_prise"):setVisible(true)
	end

	if var_95_0.is_has_praise == 1 then
		var_95_6:setBrightStyle(ccui.BrightStyle.highlight)
	end

	var_95_6:addTouchEventListener(function(arg_96_0, arg_96_1)
		if arg_96_1 == ccui.TouchEventType.began then
			var_95_6:setScale(0.9)
		end

		if arg_96_1 == ccui.TouchEventType.ended then
			var_95_6:setBrightStyle(ccui.BrightStyle.highlight)
			var_95_6:setScale(1)

			local var_96_0 = var_95_0.comment_id

			if arg_95_0:checkPlayerIsYou() then
				local var_96_1 = var_0_1:translation("PERSON_DEL_COMMENT")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_96_1, function()
					local var_97_0 = {
						commentID = var_96_0,
						pageNum = arg_95_0.spaceCommentPage
					}

					if arg_95_0.personDisplay then
						arg_95_0.personDisplay:delComment(var_97_0, function(arg_98_0, arg_98_1)
							if arg_98_0 == xyd.error.OK then
								arg_95_0.spaceInfos = arg_95_0.personDisplay:getCommentInfos(arg_95_0.spaceCommentPage)

								if arg_95_0.spaceCommentPage > 1 and #arg_95_0.spaceInfos == 0 then
									arg_95_0.spaceInfos = arg_95_0.personDisplay:getCommentInfos(arg_95_0.spaceCommentPage - 1)
									arg_95_0.spaceCommentPage = arg_95_0.spaceCommentPage - 1
								end

								arg_95_0.spaceList:refreshList()
								arg_95_0:updateCommentBtn()
							end
						end)
					end
				end, nil, nil, arg_95_0.colorMode)
			else
				local var_96_2 = {
					comment_id = var_95_0.comment_id,
					to_player_id = var_95_0.player_id
				}

				arg_95_0.personDisplay:addCommentPraise(var_96_2, function(arg_99_0, arg_99_1)
					if arg_99_0 == xyd.error.OK then
						arg_95_0.spaceInfos = arg_95_0.personDisplay:getCommentInfos(arg_95_0.spaceCommentPage)

						arg_95_0.spaceList:refreshList()
					end
				end)
			end
		end

		if arg_96_1 == ccui.TouchEventType.moved then
			var_95_6:setScale(1)
		end
	end)
end

function var_0_0.createSpaceBtn(arg_100_0, arg_100_1)
	arg_100_0.spacePraiseBtn = arg_100_1:getChildByName("btn_to_prise")
	arg_100_0.spacePraiseNum = arg_100_1:getChildByName("bg_to_praise"):getChildByName("txt_praise_num")

	arg_100_1:getChildByName("btn_to_prise"):addTouchEventListener(function(arg_101_0, arg_101_1)
		if arg_101_1 == ccui.TouchEventType.began then
			arg_100_0.spacePraiseBtn:setScale(0.9)
			arg_100_0.spacePraiseBtn:getChildByName("icon_praise"):setVisible(false)
			arg_100_0.spacePraiseBtn:getChildByName("icon_prise_select"):setVisible(true)
		end

		if arg_101_1 == ccui.TouchEventType.ended then
			arg_100_0.spacePraiseBtn:setBrightStyle(ccui.BrightStyle.highlight)
			arg_100_0.spacePraiseBtn:setScale(1)
			arg_100_0.spacePraiseBtn:getChildByName("icon_praise"):setVisible(true)
			arg_100_0.spacePraiseBtn:getChildByName("icon_prise_select"):setVisible(false)

			if arg_100_0:checkPlayerIsYou() then
				arg_100_0.spacePraiseBtn:setBrightStyle(ccui.BrightStyle.normal)
				arg_100_0.personDisplay:getPraiseList(true, function(arg_102_0, arg_102_1)
					if arg_102_0 == xyd.error.OK then
						xyd.WindowManager.get():openWindow("person_praise")
					end
				end)
			else
				local var_101_0 = arg_100_0:getPlayerID()

				arg_100_0.personDisplay:addPraise(var_101_0, function(arg_103_0, arg_103_1)
					if arg_103_0 == xyd.error.OK then
						local var_103_0 = arg_100_0.personDisplay:getPraiseNum()

						arg_100_0.spacePraiseNum:setString(var_103_0)

						local var_103_1 = arg_100_0.personDisplay:getIsHasPraise()

						arg_101_0:setBrightStyle(var_103_1 == 1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)

						arg_100_0.praiseIsChange = true
					end
				end)
			end
		end

		if arg_101_1 == ccui.TouchEventType.moved then
			arg_100_0.spacePraiseBtn:setScale(1)
			arg_100_0.spacePraiseBtn:getChildByName("icon_praise"):setVisible(true)
			arg_100_0.spacePraiseBtn:getChildByName("icon_prise_select"):setVisible(false)

			local var_101_1 = arg_100_0.personDisplay:getIsHasPraise()

			arg_101_0:setBrightStyle(var_101_1 == 1 and ccui.BrightStyle.highlight or ccui.BrightStyle.normal)
		end
	end)
	arg_100_1:getChildByName("btn_send"):addTouchEventListener(function(arg_104_0, arg_104_1)
		if arg_104_1 == ccui.TouchEventType.began then
			arg_100_1:getChildByName("btn_send"):setScale(0.9)
		end

		if arg_104_1 == ccui.TouchEventType.ended then
			arg_100_1:getChildByName("btn_send"):setScale(1)

			if arg_100_0:checkPlayerIsYou() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NOT_SEND_MSG_FOR_SELF")
				})

				return
			elseif arg_100_0:checkBtnIsHide(xyd.PlayerCardButtonStyle.SPACE) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("CAN_NOT_SEND_MSG_TO_MAN")
				})

				return
			elseif not arg_100_0.sendContentText or arg_100_0.sendContentText == "" then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("NOT_SEND_NULL_MSG")
				})

				return
			end

			local var_104_0 = arg_100_0.sendContentText

			if not var_104_0 or var_104_0 == "" then
				return false
			end

			local var_104_1 = {
				to_player_id = arg_100_0:getPlayerID(),
				content = var_104_0
			}

			arg_100_0.personDisplay:addComment(var_104_1, function(arg_105_0, arg_105_1)
				if arg_105_0 == xyd.error.OK then
					arg_100_0.textSendContent:setString(var_0_1:translation("PERSON_ZONE_TIP_COMMENT"))

					arg_100_0.sendContentText = ""
					arg_100_0.spaceCommentPage = 1
					arg_100_0.spaceInfos = arg_100_0.personDisplay:getCommentInfos(arg_100_0.spaceCommentPage)

					arg_100_0.spaceList:reload()
					arg_100_0:updateCommentBtn()
				end
			end)
		end

		if arg_104_1 == ccui.TouchEventType.moved then
			arg_100_1:getChildByName("btn_send"):setScale(1)
		end
	end)

	if arg_100_0:checkCanAddFriend() ~= var_0_8.CAN_ADD then
		arg_100_1:getChildByName("btn_to_add"):setVisible(false)
	end

	arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(false)
	arg_100_1:getChildByName("btn_to_add"):addTouchEventListener(function(arg_106_0, arg_106_1)
		if arg_106_1 == ccui.TouchEventType.began then
			arg_100_1:getChildByName("btn_to_add"):setScale(0.9)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend"):setVisible(false)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(true)
		end

		if arg_106_1 == ccui.TouchEventType.ended then
			arg_100_1:getChildByName("btn_to_add"):setScale(1)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend"):setVisible(true)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(false)

			local var_106_0 = arg_100_0:checkCanAddFriend()

			if var_106_0 == var_0_8.CAN_ADD then
				local var_106_1 = {
					player_id = arg_100_0:getPlayerID()
				}
				local var_106_2 = {
					data = var_106_1
				}

				xyd.WindowManager.get():openWindow("input_authentic_msg", var_106_2)
			else
				local var_106_3
				local var_106_4 = arg_100_0.personDisplay:getPlayerName()

				if var_106_0 == var_0_8.IN_FRIEND then
					var_106_3 = string.format(var_0_1:translation("SOMEONE_IN_FRIEND"), var_106_4)
				elseif var_106_0 == var_0_8.IN_BLACK then
					var_106_3 = string.format(var_0_1:translation("SOMEONE_IN_BLACK"), var_106_4)
				elseif var_106_0 == var_0_8.FULL_FRIEND then
					var_106_3 = var_0_1:translation("FRIEND_NUM_LIMIT_TIPS")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_106_3
				})
			end
		end

		if arg_106_1 == ccui.TouchEventType.moved then
			arg_100_1:getChildByName("btn_to_add"):setScale(1)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend"):setVisible(true)
			arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(false)
		end
	end)

	if arg_100_0:checkCanAddFriend() == var_0_8.IN_BLACK then
		arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_afterblack"):setVisible(true)
	else
		arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_afterblack"):setVisible(false)
	end

	arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black_select"):setVisible(false)
	arg_100_1:getChildByName("btn_to_black"):addTouchEventListener(function(arg_107_0, arg_107_1)
		if arg_107_1 == ccui.TouchEventType.began then
			arg_100_1:getChildByName("btn_to_black"):setScale(0.9)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black"):setVisible(false)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black_select"):setVisible(true)

			return true
		elseif arg_107_1 == ccui.TouchEventType.ended then
			arg_100_1:getChildByName("btn_to_black"):setScale(1)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black"):setVisible(true)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black_select"):setVisible(false)

			local var_107_0
			local var_107_1 = arg_100_0:checkCanAddFriend() ~= var_0_8.IN_BLACK and true or false
			local var_107_2

			if var_107_1 then
				var_107_2 = string.format(var_0_1:translation("PERSON_SHIELDING_ONE_MAN"), arg_100_0.personDisplay:getPlayerName())
			else
				var_107_2 = string.format(var_0_1:translation("REMOVE_ONE_MAN_IN_BLACK"), arg_100_0.personDisplay:getPlayerName())
			end

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_107_2, function()
				local var_108_0 = {
					player_id = arg_100_0:getPlayerID()
				}
				local var_108_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)

				if var_107_1 then
					var_108_1:addBlackList(var_108_0, function(arg_109_0, arg_109_1)
						if arg_109_0 == xyd.error.OK then
							arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_afterblack"):setVisible(true)
							arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black"):setVisible(false)

							if var_108_1.blacklist then
								table.insert(var_108_1.blacklist, arg_109_1.player_info)
							end
						end
					end)
				else
					var_108_1:removeBlackList(var_108_0, function(arg_110_0, arg_110_1)
						if arg_110_0 == xyd.error.OK then
							var_108_1:removeOnefromBlack(arg_100_0:getPlayerID())
							arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black"):setVisible(true)
							arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_afterblack"):setVisible(false)
						end
					end)
				end
			end, nil, nil, arg_100_0.colorMode)
		end

		if arg_107_1 == ccui.TouchEventType.moved then
			arg_100_1:getChildByName("btn_to_black"):setScale(1)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black"):setVisible(true)
			arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black_select"):setVisible(false)
		end
	end)
	arg_100_1:getChildByName("btn_last"):addTouchEventListener(function(arg_111_0, arg_111_1)
		if arg_111_1 == ccui.TouchEventType.began then
			arg_111_0:setScale(0.9)

			return true
		elseif arg_111_1 == ccui.TouchEventType.ended then
			arg_111_0:setScale(1)

			if arg_100_0.spaceCommentPage == 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PERSON_MSG_START")
				})

				return false
			end

			arg_100_0.spaceCommentPage = arg_100_0.spaceCommentPage - 1
			arg_100_0.spaceInfos = arg_100_0.personDisplay:getCommentInfos(arg_100_0.spaceCommentPage)

			arg_100_0.spaceList:reload()
			arg_100_0:updateCommentBtn()
		end
	end)
	arg_100_1:getChildByName("btn_next"):addTouchEventListener(function(arg_112_0, arg_112_1)
		if arg_112_1 == ccui.TouchEventType.began then
			arg_112_0:setScale(0.9)

			return true
		elseif arg_112_1 == ccui.TouchEventType.ended then
			arg_112_0:setScale(1)

			if arg_100_0.spaceCommentPage == xyd.tables.misc.personCommentPage then
				return false
			end

			local var_112_0 = {
				playerID = arg_100_0:getPlayerID(),
				pageNum = arg_100_0.spaceCommentPage + 1
			}

			arg_100_0.personDisplay:getCommentList(var_112_0, function(arg_113_0, arg_113_1)
				if arg_113_0 == xyd.error.OK then
					local var_113_0 = arg_100_0.personDisplay:getCommentInfos(arg_100_0.spaceCommentPage + 1)

					if #var_113_0 > 0 then
						arg_100_0.spaceCommentPage = arg_100_0.spaceCommentPage + 1
						arg_100_0.spaceInfos = var_113_0

						arg_100_0.spaceList:reload()
						arg_100_0:updateCommentBtn()

						return
					end
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PERSON_MSG_OVER")
				})
			end)
		end
	end)
	arg_100_0:updateCommentBtn()
	arg_100_1:getChildByName("btn_to_prise"):getChildByName("icon_prise_select"):setVisible(false)
	arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(false)
	arg_100_1:getChildByName("btn_to_black"):getChildByName("icon_black_select"):setVisible(false)

	if arg_100_0:checkPlayerIsYou() then
		arg_100_1:getChildByName("btn_to_add"):setVisible(false)
	elseif arg_100_0:checkBtnIsHide(xyd.PlayerCardButtonStyle.SPACE) then
		arg_100_1:getChildByName("btn_to_prise"):getChildByName("icon_praise"):setVisible(false)
		arg_100_1:getChildByName("btn_to_prise"):getChildByName("icon_praise_done"):setVisible(true)
		arg_100_1:getChildByName("btn_to_prise"):setTouchEnabled(false)
		arg_100_1:getChildByName("btn_to_prise"):setVisible(false)
		arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend_select"):setVisible(true)
		arg_100_1:getChildByName("btn_to_add"):getChildByName("icon_addfriend"):setVisible(false)
		arg_100_1:getChildByName("btn_to_add"):setTouchEnabled(false)
		arg_100_1:getChildByName("btn_to_add"):setVisible(false)
	elseif arg_100_0.personDisplay:getIsHasPraise() == 1 then
		arg_100_1:getChildByName("btn_to_prise"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		arg_100_1:getChildByName("btn_to_prise"):setBrightStyle(ccui.BrightStyle.normal)
	end
end

function var_0_0.updateCommentBtn(arg_114_0)
	local var_114_0 = arg_114_0.rightPanel[xyd.PlayerCardButtonStyle.SPACE]

	if not var_114_0 then
		return
	end

	local var_114_1 = var_114_0:getChildByName("container")

	var_114_1:getChildByName("btn_last"):setVisible(true)
	var_114_1:getChildByName("btn_next"):setVisible(true)

	if arg_114_0:checkBtnIsHide(xyd.PlayerCardButtonStyle.SPACE) then
		var_114_1:getChildByName("btn_last"):setVisible(false)
		var_114_1:getChildByName("btn_next"):setVisible(false)

		return
	end

	if arg_114_0.spaceCommentPage == 1 then
		var_114_1:getChildByName("btn_last"):setVisible(false)
	end

	if arg_114_0.spaceCommentPage == arg_114_0.personDisplay:getMaxCommentPage() then
		var_114_1:getChildByName("btn_next"):setVisible(false)
	end
end

function var_0_0.checkCanAddFriend(arg_115_0)
	local var_115_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)

	if var_115_0:isInFriendList(arg_115_0:getPlayerID()) then
		return var_0_8.IN_FRIEND
	elseif var_115_0:isInBlackList(arg_115_0:getPlayerID()) then
		return var_0_8.IN_BLACK
	elseif #var_115_0.friendlist >= xyd.tables.misc.maxFriendNum then
		return var_0_8.FULL_FRIEND
	else
		return var_0_8.CAN_ADD
	end
end

function var_0_0.playHideEffect(arg_116_0, arg_116_1, arg_116_2)
	if arg_116_1 then
		arg_116_2:getChildByName("frame_mid_1"):setVisible(true)
		arg_116_2:getChildByName("frame_mid_2"):setVisible(true)
		arg_116_2:getChildByName("frame_mid_3"):setVisible(true)
		arg_116_2:getChildByName("frame_mid_4"):setVisible(true)
		arg_116_2:getChildByName("frame_top"):setVisible(true)
		arg_116_2:getChildByName("frame_bottom"):setVisible(true)
		arg_116_2:getChildByName("frame_mid_1"):setTouchSwallowEnabled(true)
		arg_116_2:getChildByName("frame_mid_2"):setTouchSwallowEnabled(true)
		arg_116_2:getChildByName("frame_mid_3"):setTouchSwallowEnabled(true)
		arg_116_2:getChildByName("frame_mid_4"):setTouchSwallowEnabled(true)
		arg_116_2:getChildByName("frame_top"):setTouchSwallowEnabled(true)
		arg_116_2:getChildByName("frame_bottom"):setTouchSwallowEnabled(true)
	else
		arg_116_2:getChildByName("frame_mid_1"):setVisible(false)
		arg_116_2:getChildByName("frame_mid_2"):setVisible(false)
		arg_116_2:getChildByName("frame_mid_3"):setVisible(false)
		arg_116_2:getChildByName("frame_mid_4"):setVisible(false)
		arg_116_2:getChildByName("frame_top"):setVisible(false)
		arg_116_2:getChildByName("frame_bottom"):setVisible(false)
	end
end

function var_0_0.playGuide(arg_117_0)
	if arg_117_0.personDisplay:checkIsFirstTime() and arg_117_0:checkPlayerIsYou() then
		local var_117_0 = arg_117_0.mainBtnEdit

		if not var_117_0 then
			return
		end

		local var_117_1 = var_117_0:getPositionX()
		local var_117_2 = var_117_0:getPositionY()
		local var_117_3 = var_117_0:getContentSize().width
		local var_117_4 = var_117_0:getContentSize().height
		local var_117_5 = display.newNode()

		var_117_5:setPosition(var_117_1, var_117_2)

		local var_117_6 = import("app.windows.GuideHand").new()

		var_117_5:addChild(var_117_6)
		var_117_6:setPosition(0, 0)

		local var_117_7 = var_0_1:translation("PERSON_FIRST_CLICK_EDIT")

		var_117_6:setText(var_117_7, cc.p(60, 0))
		var_117_5:addTo(arg_117_0.rightPanel[xyd.PlayerCardButtonStyle.MAIN]:getChildByName("container"))

		arg_117_0.firstGuideHand = var_117_5
	end
end

function var_0_0.createSpaceImageLoder(arg_118_0, arg_118_1)
	arg_118_1:getChildByName("avatar_bg"):setTouchEnabled(true)
	arg_118_1:getChildByName("avatar_bg"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_119_0)
		if arg_119_0.name == "began" then
			return true
		elseif arg_119_0.name == "ended" and arg_118_0:checkPlayerIsYou() and device.platform == "android" then
			local var_119_0 = {
				callback = function(arg_120_0, arg_120_1)
					if arg_120_0 then
						local var_120_0 = "avatar_" .. arg_118_0.selfPlayer.region .. "_" .. arg_118_0:getPlayerID() .. ".png"
						local var_120_1 = "avatar|" .. var_120_0
						local var_120_2 = {
							form_name = var_120_1,
							file_path = arg_120_1,
							file_name = var_120_0
						}

						arg_118_0.personDisplay:uploadAvatar(var_120_2, function(arg_121_0, arg_121_1)
							if arg_121_0 == xyd.error.OK then
								arg_118_0:loadAvatarImage(arg_118_1)
							else
								local var_121_0 = var_0_1:translation("UPLOAD_IMAGE_FAILED")

								xyd.WindowManager.get():openWindow("toast", {
									message = var_121_0
								})
							end
						end)
					else
						local var_120_3 = var_0_1:translation("UPLOAD_IMAGE_FAILED")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_120_3
						})
					end
				end
			}

			xyd.WindowManager.get():openWindow("image_picker", var_119_0)
		end
	end)
	arg_118_0:loadAvatarImage(arg_118_1)
end

function var_0_0.loadAvatarImage(arg_122_0, arg_122_1)
	local var_122_0 = arg_122_0.personDisplay:getBasicInfo()
	local var_122_1 = var_122_0.avatar_file_path
	local var_122_2 = var_122_0.avatar_md5_code

	if not var_122_1 or not var_122_2 then
		arg_122_0:createDefaultImage(arg_122_1)

		return
	end

	local var_122_3 = var_122_1

	if not var_122_3 or var_122_3 == "" then
		arg_122_0:createDefaultImage(arg_122_1)

		return
	end

	local var_122_4 = {
		md5_code = var_122_2,
		file_name = "avatar_" .. arg_122_0.selfPlayer.region .. "_" .. arg_122_0:getPlayerID() .. ".png",
		file_path = cc.FileUtils:getInstance():getWritablePath()
	}
	local var_122_5 = arg_122_1:getChildByName("avatar_bg"):getContentSize()
	local var_122_6 = import("app.common.ui.OnlineImageSprite").new("windows/person_display/person_space/summer_icon.png", var_122_3, var_122_5.width / 2, var_122_5.height / 2, var_122_4)

	arg_122_1:getChildByName("avatar_bg"):removeAllChildren()
	var_122_6:addTo(arg_122_1:getChildByName("avatar_bg"))
	arg_122_1:getChildByName("summer_icon"):setVisible(false)
end

function var_0_0.createDefaultImage(arg_123_0, arg_123_1)
	if device.platform == "android" and arg_123_0:checkPlayerIsYou() then
		local var_123_0 = arg_123_1:getChildByName("avatar_bg"):getContentSize()
		local var_123_1 = var_0_1:translation("UPLOAD_IMAGE_TIPS_1")
		local var_123_2 = arg_123_0:createTextLabel(var_123_1, nil, cc.c4b(0, 0, 0, 255), 30, var_123_0.width - 5)

		var_123_2:addTo(arg_123_1:getChildByName("avatar_bg"))
		var_123_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_123_2:setPosition(cc.p(var_123_0.width / 2, var_123_0.height / 2))
		arg_123_1:getChildByName("summer_icon"):setVisible(false)
	end
end

function var_0_0.initHeroCell(arg_124_0, arg_124_1, arg_124_2)
	if not arg_124_1 or not next(arg_124_1) then
		return
	end

	local var_124_0 = import("app.windows.HeroListCell").new({
		hero = arg_124_1,
		type = xyd.HeroListDisplayType.ONLYSHOW
	})

	var_124_0:layout()

	if arg_124_2 and arg_124_2 > 0 then
		local var_124_1 = arg_124_2 / var_124_0:getWidth()

		var_124_0:setScale(var_124_1)
	end

	return var_124_0
end

function var_0_0.setPetAvatarCard(arg_125_0, arg_125_1, arg_125_2, arg_125_3)
	arg_125_2:setScale(0.98)

	local function var_125_0()
		local var_126_0 = "windows/common/hero_common/icon_hero_star.png"

		return xyd.AssetLoader.get():loadSprite(var_126_0)
	end

	local var_125_1 = arg_125_1:getAvatar(2)
	local var_125_2 = arg_125_1:getColor()
	local var_125_3 = arg_125_1:getStar()
	local var_125_4 = xyd.AssetLoader.get():loadNodeFromJson("windows/battle/select_team/pet_avatar.csb")

	var_125_4:getChildByName("avatar_mask"):hide()
	var_125_4:getChildByName("chosen"):hide()
	var_125_4:getChildByName("name"):setVisible(false)
	var_125_4:getChildByName("name_label_bg"):setVisible(false)
	var_125_4:getChildByName("pet_avatar_back"):setVisible(false)

	local var_125_5 = var_125_4:getChildByName("background"):getWidth()

	var_125_4:size(var_125_5, var_125_5)
	var_125_4:setName("layout")
	var_125_4:align(display.CENTER, arg_125_2:getWidth() / 2, arg_125_2:getHeight() / 2 + 5)
	var_125_4:setScale(0.85, 0.85)

	local var_125_6 = var_125_4:getChildByName("avatar")
	local var_125_7 = xyd.AssetLoader.get():loadSprite(var_125_1)

	var_125_6:addChild(var_125_7)
	var_125_7:align(display.CENTER_BOTTOM, 50, 0)

	local var_125_8 = arg_125_2:getChildByName("card")
	local var_125_9

	if arg_125_3 then
		var_125_9 = xyd.AssetLoader:get():loadSprite("windows/person_display/person_main/bg_pet.png")
	else
		var_125_9 = xyd.AssetLoader:get():loadSprite("windows/person_display/person_main/bg_pet.png")

		var_125_9:setScale(0.94, 0.94)
	end

	var_125_9:setAnchorPoint(cc.p(0, 0))
	var_125_9:setPosition(7, 13)
	var_125_9:setLocalZOrder(-1)
	var_125_8:addChild(var_125_9)
	var_125_8:addChild(var_125_4)

	local var_125_10 = var_125_8:getContentSize()
	local var_125_11 = arg_125_2:getContentSize().height
	local var_125_12 = arg_125_2:getContentSize().width
	local var_125_13

	if arg_125_3 then
		var_125_13 = xyd.AssetLoader:get():loadSprite("images/card_mask.png")
	else
		var_125_13 = xyd.AssetLoader:get():loadSprite("images/small_card_mask.png")
	end

	var_125_13:setPosition(var_125_12 / 2, var_125_11 / 2)
	var_125_13:setAnchorPoint(cc.p(0.5, 0.5))
	var_125_13:setScale(var_125_11 / var_125_13:getHeight())

	local var_125_14 = cc.ClippingNode:create()

	var_125_14:setStencil(var_125_13)
	var_125_14:setInverted(true)
	var_125_14:setAlphaThreshold(0)
	arg_125_2:addChild(var_125_14)
	var_125_14:setLocalZOrder(-1)

	local var_125_15 = xyd.getSmallCardBorder(arg_125_1)

	xyd.displaySpriteOnContainer(var_125_15, arg_125_2, true)

	local var_125_16

	if arg_125_1:isAwaken() then
		var_125_16 = xyd.AssetLoader.get():loadSprite("windows/common/hero_common/border_awake.png")
	end

	if var_125_16 then
		var_125_16:setAnchorPoint(1, 1)
		var_125_16:setScale(0.75)
		var_125_16:setPosition(arg_125_2:getWidth() + 7, arg_125_2:getHeight() + 7)
		var_125_16:addTo(arg_125_2)
		var_125_16:setName("extra_border")
	end

	local var_125_17 = arg_125_1:getColor()
	local var_125_18 = "windows/common/hero_common/quality_mini_"
	local var_125_19 = xyd.AssetLoader.get():loadSprite(var_125_18 .. var_125_17 .. ".png")

	var_125_19:addTo(arg_125_2)
	var_125_19:setPosition(30, arg_125_2:getHeight() - 20)
	var_125_19:setScale(0.8)

	local var_125_20 = display.newNode()
	local var_125_21 = var_125_0()
	local var_125_22 = var_125_21:getWidth()
	local var_125_23 = var_125_22 + (var_125_3 - 1) * 20
	local var_125_24 = var_125_21:getHeight()

	var_125_20:setContentSize(var_125_23, var_125_24)
	var_125_20:setAnchorPoint(0.5, 0.5)
	var_125_20:setPosition(cc.p(0.5 * var_125_10.width, var_125_24 / 2))
	var_125_21:addTo(var_125_20, 10)
	var_125_21:setAnchorPoint(0.5, 0.5)
	var_125_21:setPosition(var_125_22 / 2, var_125_24 / 2 + 2)

	for iter_125_0 = 1, var_125_3 - 1 do
		local var_125_25 = var_125_0()

		var_125_25:addTo(var_125_20, 10 - iter_125_0)
		var_125_25:setAnchorPoint(0.5, 0.5)
		var_125_25:setPosition(var_125_22 / 2 + iter_125_0 * 20, var_125_24 / 2 + 2)
	end

	var_125_20:setScale(0.75)
	arg_125_2:addChild(var_125_20)
end

return var_0_0
