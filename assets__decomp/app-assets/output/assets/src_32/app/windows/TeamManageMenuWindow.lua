local var_0_0 = class("TeamManageMenuWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.parent = arg_1_2.parent

	arg_1_0:setTouchSwallowEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:nodeByName("red_point"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.GUILD_APPLY_NOTICE, handler(arg_3_0, arg_3_0.updateGuildNotice_))
	arg_3_0:updateGuildNotice_()
	arg_3_0:nodeByName("apply_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("apply_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.guild:loadSelfGuild(function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0.guild:loadAllApply(function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							xyd.WindowManager.get():openWindow("team_apply_member")
						end
					end)
				end
			end)
		end
	end)
	arg_3_0:nodeByName("manage_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("manage_btn"), arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.guild:loadTeam(function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("team_member_manage", {
						parent = arg_3_0
					})
				end
			end)
		end
	end)
	arg_3_0:nodeByName("gonggao_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("gonggao_btn"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.guild:loadSelfGuild(function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("team_data_setting")
				end
			end)
		end
	end)
	arg_3_0:nodeByName("setting_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("setting_btn"), arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_3_0.guild:loadSelfGuild(function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("team_setting")
				end
			end)
		end
	end)
	arg_3_0:nodeByName("message_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("message_btn"), arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.guild.job == 1 then
				xyd.WindowManager.get():openWindow("team_message")
			else
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
					var_0_2:translation("TEAM_MESSAGE_JOB_LIMMIT_ALERT")
				}, nil, nil, nil, xyd.ColorMode.YELLOW)
			end
		end
	end)
	arg_3_0:nodeByName("over_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("over_btn"), arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
				var_0_2:translation("TEAM_DISSOLUTION_ALERT")
			}, function(arg_15_0)
				if arg_3_0.guild.job == 1 then
					if arg_3_0.guild.member_nums <= 1 then
						arg_3_0.guild:dissolutionTeam(function(arg_16_0)
							if arg_16_0 == xyd.error.OK then
								xyd.WindowManager.get():closeWindow("team")
								xyd.WindowManager.get():closeWindow(arg_3_0.parent)
								xyd.WindowManager.get():closeWindow(arg_3_0)

								return true
							end
						end)
					else
						xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
							var_0_2:translation("TEAM_DISSOLUTION_NUM_ALERT")
						}, nil, nil, 0, xyd.ColorMode.YELLOW)
					end
				else
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
						var_0_2:translation("TEAM_DISSOLUTION_JOB_ALERT")
					}, nil, nil, 0, xyd.ColorMode.YELLOW)
				end
			end, nil, 0, xyd.ColorMode.YELLOW)
		end
	end)
	arg_3_0:nodeByName("quit_btn"):addTouchEventListener(function(arg_17_0, arg_17_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("quit_btn"), arg_17_1)

		if arg_17_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_3_0.guild.job == 0 or arg_3_0.guild.job == 2 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					xyd.tables.translation:translation("PLAYER_INFO_QUIT_ALERT")
				}, function(arg_18_0)
					arg_3_0.guild:quitTeam(function(arg_19_0)
						if arg_19_0 == xyd.error.OK then
							xyd.WindowManager.get():closeWindow("team")
							xyd.WindowManager.get():closeWindow(arg_3_0.parent)
							xyd.WindowManager.get():closeWindow(arg_3_0)

							return true
						end
					end)
				end, nil, nil, xyd.ColorMode.YELLOW)
			elseif arg_3_0.guild.job == 1 then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, {
					xyd.tables.translation:translation("PLAYER_INFO_CANT_QUIT_ALERT")
				}, nil, nil, nil, xyd.ColorMode.YELLOW)
			end
		end
	end)
	arg_3_0:nodeByName("search_btn"):addTouchEventListener(function(arg_20_0, arg_20_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("search_btn"), arg_20_1)

		if arg_20_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("read_guild")
		end
	end)
	arg_3_0:nodeByName("apply_words_little"):setString(var_0_2:translation("SHE_TUAN_TEXT_3"))
	arg_3_0:nodeByName("manage_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_4"))
	arg_3_0:nodeByName("gonggao_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_5"))
	arg_3_0:nodeByName("setting_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_6"))
	arg_3_0:nodeByName("message_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_7"))
	arg_3_0:nodeByName("over_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_10"))
	arg_3_0:nodeByName("search_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_8"))
	arg_3_0:nodeByName("quit_text"):setString(var_0_2:translation("SHE_TUAN_TEXT_9"))
end

function var_0_0.updateGuildNotice_(arg_21_0, arg_21_1)
	arg_21_0.guild:loadAllApply(function(arg_22_0, arg_22_1)
		if arg_22_1 ~= nil and #arg_22_1 ~= 0 then
			arg_21_0:nodeByName("red_point"):setVisible(true)
		else
			arg_21_0:nodeByName("red_point"):setVisible(false)
		end
	end)
end

function var_0_0.willClose(arg_23_0, arg_23_1)
	var_0_0.super:willClose(arg_23_1)
end

return var_0_0
