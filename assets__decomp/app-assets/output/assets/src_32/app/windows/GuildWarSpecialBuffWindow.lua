local var_0_0 = class("GuildWarSpecialBuffWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
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
	arg_4_0:updateCostHuoYue()
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("GUILD_WAR_BUFF_TIPS4"))
	arg_4_0:nodeByName("text_huoyue"):setString(var_0_1:translation("GUILD_WAR_BUFF_TIPS6") .. arg_4_0.guild:getGuildHuoyue() or 0)
	arg_4_0:nodeByName("text_tips1"):setString(var_0_1:translation("GUILD_WAR_BUFF_EXCHANGE"))
end

function var_0_0.updateCostHuoYue(arg_5_0)
	local var_5_0 = 0

	for iter_5_0 = 1, #arg_5_0.selfAddBuff do
		var_5_0 = var_5_0 + arg_5_0.selfAddBuff[iter_5_0] * xyd.tables.misc.guildWarBuffExchange
	end

	arg_5_0:nodeByName("text_huoyue_cost"):setString(var_0_1:translation("GUILD_WAR_BUFF_TIPS7") .. var_5_0)
end

function var_0_0.willClose(arg_6_0)
	local var_6_0 = xyd.WindowManager.get():getWindow("guild_war_buff")

	if var_6_0 and not tolua.isnull(var_6_0) then
		var_6_0.buffInfos = arg_6_0.buffInfos

		var_6_0:initDetail()
	end
end

function var_0_0.setupButton(arg_7_0)
	arg_7_0:nodeByName("btn_confirm"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = 0

			for iter_8_0 = 1, #arg_7_0.selfAddBuff do
				var_8_0 = var_8_0 + arg_7_0.selfAddBuff[iter_8_0] * xyd.tables.misc.guildWarBuffExchange
			end

			if var_8_0 == 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_WAR_BUFF_CHOOSE")
				})

				return
			elseif var_8_0 > arg_7_0.guild:getGuildHuoyue() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("GUILD_WAR_BUFF_TIPS8")
				})

				return
			end

			local var_8_1 = string.format(var_0_1:translation("GUILD_WAR_BUFF_GUILD"), var_8_0)

			xyd.AlertWindow.open(xyd.AlertType.YES_NO, {
				var_8_1
			}, function(arg_9_0)
				if arg_9_0 then
					local var_9_0 = {
						add_nums = arg_7_0.selfAddBuff,
						cost_type = xyd.GuildWarBuffCostType.HUOYUE
					}

					arg_7_0.guild:addGuildBuff(var_9_0, function(arg_10_0, arg_10_1)
						if arg_10_0 == xyd.error.OK then
							arg_7_0.buffInfos = arg_10_1.buff_infos

							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_1:translation("GUILD_WAR_BUFF_TIPS10")
							})

							local var_10_0 = xyd.WindowManager.get():getWindow("guild_war")

							if var_10_0 and not tolua.isnull(var_10_0) then
								var_10_0:createBuffWnd()
							end

							arg_7_0.guild.huoyue = arg_7_0.guild.huoyue - var_8_0

							arg_7_0:initDetail()
							arg_7_0:nodeByName("text_huoyue"):setString(var_0_1:translation("GUILD_WAR_BUFF_TIPS6") .. arg_7_0.guild:getGuildHuoyue() or 0)
							arg_7_0:updateCostHuoYue()
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
end

function var_0_0.initDetail(arg_11_0)
	local var_11_0 = arg_11_0:nodeByName("detail")

	var_11_0:removeAllChildren()

	local var_11_1 = var_11_0:getContentSize()
	local var_11_2 = 15
	local var_11_3 = 0
	local var_11_4 = math.floor(var_11_1.width / var_0_2)

	for iter_11_0 = 1, #arg_11_0.buffInfos do
		local var_11_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_buff/special_item.csb")

		var_11_5:addTo(var_11_0)
		var_11_5:setPosition(cc.p(var_11_2, var_11_3))

		local var_11_6 = arg_11_0.buffInfos[iter_11_0]
		local var_11_7 = var_11_6.guild_add + var_11_6.player_add
		local var_11_8 = var_11_5:getChildByName("container")
		local var_11_9 = "windows/guild_war/guild_buff/buff_"

		xyd.setSpriteBorder(var_11_8:getChildByName("icon"), var_11_9 .. var_11_6.attr_id .. ".png", 1)
		var_11_8:getChildByName("text_desc"):setString(string.format(var_0_1:translation("GUILD_WAR_BUFF" .. var_11_6.attr_id), 1))

		arg_11_0.selfAddBuff[iter_11_0] = 0

		var_11_8:getChildByName("select_box"):setTouchEnabled(true)
		var_11_8:getChildByName("select_box"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "began" then
				return true
			elseif arg_12_0.name == "ended" then
				if var_11_7 == xyd.tables.misc.guildWarBuffMax then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("GUILD_WAR_BUFF_MAX")
					})

					return false
				end

				if arg_11_0.selfAddBuff[iter_11_0] == 1 then
					arg_11_0.selfAddBuff[iter_11_0] = 0

					var_11_8:getChildByName("select"):setVisible(false)
				else
					arg_11_0.selfAddBuff[iter_11_0] = 1

					var_11_8:getChildByName("select"):setVisible(true)
				end

				arg_11_0:updateCostHuoYue()
			end
		end)

		if var_11_6.guild_add > 0 then
			var_11_8:getChildByName("select"):setVisible(true)
			var_11_8:getChildByName("select"):setGrayScale(1)
			var_11_8:getChildByName("select_box"):setTouchEnabled(false)
		else
			var_11_8:getChildByName("select"):setVisible(false)
		end

		var_11_2 = var_11_2 + var_11_4
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
