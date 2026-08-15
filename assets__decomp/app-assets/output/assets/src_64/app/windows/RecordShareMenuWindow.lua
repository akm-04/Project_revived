local var_0_0 = class("RecordShareMenuWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.message = arg_1_2.message
	arg_1_0.type_ = arg_1_2.type_ or 1
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("txt_friend"):setString(var_0_2:translation("TOP_SHARE_TEXT1"))
	arg_2_0:nodeByName("txt_world"):setString(var_0_2:translation("TOP_SHARE_TEXT2"))
	arg_2_0:nodeByName("txt_server"):setString(var_0_2:translation("TOP_SHARE_TEXT4"))
	arg_2_0:nodeByName("txt_guild"):setString(var_0_2:translation("TOP_SHARE_TEXT3"))
	arg_2_0:nodeByName("world_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_3_0, arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			local var_3_0 = {
				channel = 0,
				message = arg_2_0.message,
				type = arg_2_0.type_
			}

			xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_3_0)
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("ARENA_REPORT_SHARED")
			})
		end
	end)
	arg_2_0:nodeByName("guild_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_4_0, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_GUILD) == false then
				xyd.WindowManager.get():openWindow("toast", {
					message = xyd.tables.translation:translation("HAS_NOT_JOIN_GUILD")
				})
			else
				var_4_0:loadSelfGuild(function()
					if var_4_0.guild_id ~= nil and var_4_0.guild_id ~= 0 then
						local var_5_0 = {
							channel = 2,
							message = arg_2_0.message,
							type = arg_2_0.type_
						}

						xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_5_0)
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.translation:translation("ARENA_REPORT_SHARED_GUILD")
						})
					else
						xyd.WindowManager.get():openWindow("toast", {
							message = xyd.tables.translation:translation("HAS_NOT_JOIN_GUILD")
						})
					end
				end)
			end
		end
	end)
	arg_2_0:nodeByName("server_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				channel = 4,
				message = arg_2_0.message,
				type = arg_2_0.type_
			}

			xyd.Backend.get():request(xyd.mid.SEND_CHAT_MESSAGE, var_6_0)
			xyd.WindowManager.get():openWindow("toast", {
				message = xyd.tables.translation:translation("ARENA_REPORT_SHARED_SERVER")
			})
		end
	end)
	arg_2_0:nodeByName("friend_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				message = arg_2_0.message
			}

			xyd.WindowManager.get():openWindow("friend_share_wnd", var_7_0)
			xyd.WindowManager.get():closeWindow(arg_2_0)
		end
	end)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
