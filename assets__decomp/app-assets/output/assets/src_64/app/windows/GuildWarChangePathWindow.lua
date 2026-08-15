local var_0_0 = class("GuildWarChangePathWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.guildBattleTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.path = arg_1_2.path
	arg_1_0.teamId = arg_1_2.teamId
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 1))

	if arg_3_0.path == xyd.GuildWarPath.TOP then
		arg_3_0:nodeByName("top_1"):setVisible(false)
		arg_3_0:nodeByName("bottom_1"):setVisible(false)
	elseif arg_3_0.path == xyd.GuildWarPath.MID then
		arg_3_0:nodeByName("top_2"):setVisible(false)
		arg_3_0:nodeByName("bottom_1"):setVisible(false)
	else
		arg_3_0:nodeByName("top_2"):setVisible(false)
		arg_3_0:nodeByName("bottom_2"):setVisible(false)
	end

	arg_3_0:nodeByName("top_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_4_0 = {
				team_ids = {}
			}

			table.insert(var_4_0.team_ids, arg_3_0.teamId)

			if arg_3_0.path == xyd.GuildWarPath.TOP then
				var_4_0.path = xyd.GuildWarPath.MID
			else
				var_4_0.path = xyd.GuildWarPath.TOP
			end

			arg_3_0.guild:guildWarChangePath(var_4_0, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					local var_5_0 = xyd.WindowManager.get():getWindow("guild_war_path")

					if var_5_0 then
						var_5_0:updateLeftList()
						var_5_0.leftListView:reload()
					end

					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
		end
	end)
	arg_3_0:nodeByName("bottom_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_6_0 = {
				team_ids = {}
			}

			table.insert(var_6_0.team_ids, arg_3_0.teamId)

			if arg_3_0.path == xyd.GuildWarPath.BOTTOM then
				var_6_0.path = xyd.GuildWarPath.MID
			else
				var_6_0.path = xyd.GuildWarPath.BOTTOM
			end

			arg_3_0.guild:guildWarChangePath(var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					local var_7_0 = xyd.WindowManager.get():getWindow("guild_war_path")

					if var_7_0 then
						var_7_0:updateLeftList()
						var_7_0.leftListView:reload()
					end

					xyd.WindowManager.get():closeWindow(arg_3_0)
				end
			end)
		end
	end)
end

return var_0_0
