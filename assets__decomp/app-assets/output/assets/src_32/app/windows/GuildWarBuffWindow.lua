local var_0_0 = class("GuildWarBuffWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.selfAddBuff = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.buffInfos = arg_2_0.guild:getBuffsInfo().self_buff_info or {}

	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setupButton()
	arg_4_0:initDetail()
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("GUILD_WAR_BUFF_TIPS4"))
end

function var_0_0.setupButton(arg_5_0)
	arg_5_0:nodeByName("btn_confirm"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = 0

			for iter_6_0 = 1, #arg_5_0.selfAddBuff do
				var_6_0 = var_6_0 + arg_5_0.selfAddBuff[iter_6_0] * xyd.tables.misc.guildWarBuffPrice
			end

			if var_6_0 == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_WAR_BUFF_CHOOSE")
				})

				return
			elseif var_6_0 > arg_5_0.selfPlayer.crystal then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_WAR_BUFF_TIPS9")
				})

				return
			end

			local var_6_1 = string.format(var_0_1:translation("GUILD_WAR_BUFF_BUY"), var_6_0)

			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				var_6_1
			}, function(arg_7_0)
				if arg_7_0 then
					local var_7_0 = {
						add_nums = arg_5_0.selfAddBuff,
						cost_type = xyd.GuildWarBuffCostType.CRYSTAL
					}

					arg_5_0.guild:addGuildBuff(var_7_0, function(arg_8_0, arg_8_1)
						if arg_8_0 == xyd.error.OK then
							arg_5_0.buffInfos = arg_8_1.buff_infos

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("GUILD_WAR_BUFF_TIPS10")
							})

							local var_8_0 = xyd.WindowManager.get():getWindow("guild_war")

							if var_8_0 and not tolua.isnull(var_8_0) then
								var_8_0:createBuffWnd()
							end

							arg_5_0:initDetail()
						else
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("GUILD_WAR_BUFF_TIPS11")
							})
						end
					end)
				end
			end)
		end
	end)

	if arg_5_0.guild:getSelfJob() == xyd.GuildJobType.MEMBER then
		arg_5_0:nodeByName("btn_change"):setVisible(false)
	end

	arg_5_0:nodeByName("btn_change"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("guild_war_special_buff")
		end
	end)
end

function var_0_0.initDetail(arg_10_0)
	local var_10_0 = arg_10_0:nodeByName("detail")

	var_10_0:removeAllChildren()

	local var_10_1 = var_10_0:getContentSize()
	local var_10_2 = 15
	local var_10_3 = 0
	local var_10_4 = math.floor(var_10_1.width / var_0_2)

	for iter_10_0 = 1, #arg_10_0.buffInfos do
		local var_10_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_buff/buff_item.csb")

		var_10_5:addTo(var_10_0)
		var_10_5:setPosition(cc.p(var_10_2, var_10_3))

		local var_10_6 = arg_10_0.buffInfos[iter_10_0]
		local var_10_7 = var_10_6.guild_add + var_10_6.player_add
		local var_10_8 = var_10_5:getChildByName("container")
		local var_10_9 = "windows/guild_war/guild_buff/buff_"

		xyd.setSpriteBorder(var_10_8:getChildByName("icon"), var_10_9 .. var_10_6.attr_id .. ".png", 1)
		var_10_8:getChildByName("text_desc"):setString(string.format(var_0_1:translation("GUILD_WAR_BUFF" .. var_10_6.attr_id), 0))
		var_10_8:getChildByName("text_progress"):setString(string.format(var_0_1:translation("GUILD_WAR_BUFF_TIPS5"), var_10_7))
		var_10_8:getChildByName("text_cost_num"):setString(0)

		arg_10_0.selfAddBuff[iter_10_0] = 0

		var_10_8:getChildByName("btn_add"):addTouchEventListener(function(arg_11_0, arg_11_1)
			if arg_11_1 == ccui.TouchEventType.ended then
				if arg_10_0:checkCanAdd(iter_10_0) then
					arg_10_0.selfAddBuff[iter_10_0] = arg_10_0.selfAddBuff[iter_10_0] + 1

					var_10_8:getChildByName("text_desc"):setString(string.format(var_0_1:translation("GUILD_WAR_BUFF" .. var_10_6.attr_id), arg_10_0.selfAddBuff[iter_10_0]))
					var_10_8:getChildByName("text_cost_num"):setString(xyd.tables.misc.guildWarBuffPrice * arg_10_0.selfAddBuff[iter_10_0])
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GUILD_WAR_BUFF_MAX")
					})
				end
			end
		end)
		var_10_8:getChildByName("btn_delete"):addTouchEventListener(function(arg_12_0, arg_12_1)
			if arg_12_1 == ccui.TouchEventType.ended then
				if arg_10_0:checkCanDelete(iter_10_0) then
					arg_10_0.selfAddBuff[iter_10_0] = arg_10_0.selfAddBuff[iter_10_0] - 1

					var_10_8:getChildByName("text_desc"):setString(string.format(var_0_1:translation("GUILD_WAR_BUFF" .. var_10_6.attr_id), arg_10_0.selfAddBuff[iter_10_0]))
					var_10_8:getChildByName("text_cost_num"):setString(xyd.tables.misc.guildWarBuffPrice * arg_10_0.selfAddBuff[iter_10_0])
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GUILD_WAR_BUFF_TIPS2")
					})
				end
			end
		end)

		var_10_2 = var_10_2 + var_10_4
	end
end

function var_0_0.checkCanAdd(arg_13_0, arg_13_1)
	local var_13_0 = arg_13_0.buffInfos[arg_13_1]

	if var_13_0 and next(var_13_0) and var_13_0.guild_add + var_13_0.player_add + arg_13_0.selfAddBuff[arg_13_1] < xyd.tables.misc.guildWarBuffMax then
		return true
	end

	return false
end

function var_0_0.checkCanDelete(arg_14_0, arg_14_1)
	if arg_14_0.selfAddBuff[arg_14_1] > 0 then
		return true
	end

	return false
end

return var_0_0
