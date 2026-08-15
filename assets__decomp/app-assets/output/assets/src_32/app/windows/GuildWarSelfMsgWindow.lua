local var_0_0 = class("GuildWarSelfMsgWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = var_0_2:translation("GUILD_WAR_NOTICE")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.arena = xyd.ModelManager.get():loadModel(xyd.ModelType.ARENA)

	arg_1_0:setTouchSwallowEnabled(true)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.REFRESH_GUILD_WAR_DES, function(arg_4_0)
		local var_4_0 = arg_4_0.params

		if var_4_0 then
			arg_3_0.message = arg_3_0.guild.guildWarNotice

			arg_3_0:nodeByName("msg_text"):setString(var_4_0)
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.isOnce = false

	if arg_5_0.guild.guildWarNotice then
		arg_5_0.message = arg_5_0.guild.guildWarNotice
	else
		arg_5_0.message = ""
	end

	arg_5_0:nodeByName("change_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {
				notice = arg_5_0.message
			}

			xyd.WindowManager.get():openWindow("guild_war_setting_des", var_6_0)
		end
	end)
	arg_5_0:nodeByName("close"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)

	if arg_5_0.guild.job ~= 0 then
		arg_5_0:nodeByName("change_btn"):setVisible(true)
	else
		arg_5_0:nodeByName("change_btn"):setVisible(false)
	end

	local var_5_0 = var_0_3

	if arg_5_0.guild.guildWarNotice and arg_5_0.guild.guildWarNotice ~= "" then
		var_5_0 = arg_5_0.guild.guildWarNotice
	end

	arg_5_0:nodeByName("msg_text"):setString(var_5_0)
	xyd.setTeamBorder(arg_5_0.guild.guild_icon, arg_5_0:nodeByName("icon_container"))
	arg_5_0:nodeByName("name_text"):setString(arg_5_0.guild.guild_name)
	arg_5_0:nodeByName("id_text"):setString("ID:" .. arg_5_0.guild.guild_id)
	arg_5_0:nodeByName("mi_words"):setString(var_0_2:translation("MI"))
	arg_5_0:nodeByName("zhanshu_words"):setString(var_0_2:translation("ZHANSHU"))
end

function var_0_0.willClose(arg_8_0, arg_8_1)
	var_0_0.super:willClose(arg_8_1)
end

return var_0_0
