local var_0_0 = class("GuildWarTopBuff", function()
	return cc.Node:create()
end)
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.guildBattleTable
local var_0_4 = 3

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_buff/top_buff.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.params = arg_4_1
	arg_4_0.step = arg_4_1.step
	arg_4_0.endTime = arg_4_1.end_time

	arg_4_0:layout()

	arg_4_0.isShowBuffWnd = true
end

function var_0_0.showBuffWnd(arg_5_0)
	transition.stopTarget(arg_5_0.contentView_:nodeByName("detail"))

	if not arg_5_0.isShowBuffWnd then
		arg_5_0.contentView_:nodeByName("img_show"):setVisible(false)
		arg_5_0.contentView_:nodeByName("img_hide"):setVisible(true)
		arg_5_0.contentView_:nodeByName("clip_container"):setVisible(true)
		transition.moveTo(arg_5_0.contentView_:nodeByName("detail"), {
			time = 0.3,
			x = 0,
			y = 0
		})
	else
		arg_5_0.contentView_:nodeByName("img_show"):setVisible(true)
		arg_5_0.contentView_:nodeByName("img_hide"):setVisible(false)

		local var_5_0 = arg_5_0.contentView_:nodeByName("detail"):getContentSize()

		transition.moveTo(arg_5_0.contentView_:nodeByName("detail"), {
			time = 0.3,
			y = 0,
			x = -var_5_0.width,
			onComplete = function()
				arg_5_0.contentView_:nodeByName("clip_container"):setVisible(false)
			end
		})
	end

	arg_5_0.isShowBuffWnd = not arg_5_0.isShowBuffWnd
end

function var_0_0.updateBtnType(arg_7_0)
	arg_7_0.step = var_0_3:step(arg_7_0.guild.warStep)

	if arg_7_0.step == xyd.GuildWarStep.PREPARE then
		arg_7_0.contentView_:nodeByName("img_show"):setVisible(false)
		arg_7_0.contentView_:nodeByName("img_hide"):setVisible(false)
		arg_7_0.contentView_:nodeByName("invest"):setVisible(true)
	else
		arg_7_0.contentView_:nodeByName("img_show"):setVisible(true)
		arg_7_0.contentView_:nodeByName("img_hide"):setVisible(false)
		arg_7_0.contentView_:nodeByName("invest"):setVisible(false)
	end
end

function var_0_0.layout(arg_8_0)
	arg_8_0:updateTimeCount()
	arg_8_0:updateBtnType()
	arg_8_0.contentView_:nodeByName("btn_input"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			if arg_8_0.step == xyd.GuildWarStep.PREPARE then
				xyd.WindowManager.get():openWindow("guild_war_buff")
			else
				arg_8_0:showBuffWnd()
			end
		end
	end)
	arg_8_0.contentView_:nodeByName("bar_duration_left"):setTouchEnabled(true)
	arg_8_0.contentView_:nodeByName("bar_duration_left"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_8_0.preX = arg_10_0.x
			arg_8_0.preY = arg_10_0.y
			arg_8_0.scrollMoved = false

			arg_8_0:showBuffInfo(true, 1)

			return true
		elseif arg_10_0.name == "moved" then
			if math.abs(arg_8_0.preX - arg_10_0.x) > 10 or math.abs(arg_8_0.preY - arg_10_0.y) > 10 then
				arg_8_0.scrollMoved = true

				arg_8_0:showBuffInfo(false)
			end
		elseif arg_10_0.name == "ended" and not arg_8_0.scrollMoved then
			arg_8_0:showBuffInfo(false)
		end
	end)
	arg_8_0.contentView_:nodeByName("bar_duration_right"):setTouchEnabled(true)
	arg_8_0.contentView_:nodeByName("bar_duration_right"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
		if arg_11_0.name == "began" then
			arg_8_0.preX = arg_11_0.x
			arg_8_0.preY = arg_11_0.y
			arg_8_0.scrollMoved = false

			arg_8_0:showBuffInfo(true, 2)

			return true
		elseif arg_11_0.name == "moved" then
			if math.abs(arg_8_0.preX - arg_11_0.x) > 10 or math.abs(arg_8_0.preY - arg_11_0.y) > 10 then
				arg_8_0.scrollMoved = true

				arg_8_0:showBuffInfo(false)
			end
		elseif arg_11_0.name == "ended" and not arg_8_0.scrollMoved then
			arg_8_0:showBuffInfo(false)
		end
	end)
end

function var_0_0.updateTimeCount(arg_12_0)
	if arg_12_0.step ~= xyd.GuildWarStep.PREPARE then
		arg_12_0.contentView_:nodeByName("text_time"):setString("00:00")

		return
	end

	if arg_12_0.handle_ then
		var_0_1.unscheduleGlobal(arg_12_0.handle_)
	end

	local var_12_0 = arg_12_0.endTime - xyd.ServerTime.get():getServerTime()

	arg_12_0.contentView_:nodeByName("text_time"):setString(xyd.secondsToString(var_12_0))

	arg_12_0.handle_ = var_0_1.scheduleGlobal(function()
		if arg_12_0.contentView_ and not tolua.isnull(arg_12_0.contentView_) then
			var_12_0 = var_12_0 - 1

			arg_12_0.contentView_:nodeByName("text_time"):setString(xyd.secondsToString(var_12_0))

			if var_12_0 == 0 then
				arg_12_0:updateBtnType()

				if arg_12_0.handle_ then
					var_0_1.unscheduleGlobal(arg_12_0.handle_)

					arg_12_0.handle_ = nil
				end
			end
		elseif arg_12_0.handle_ then
			var_0_1.unscheduleGlobal(arg_12_0.handle_)

			arg_12_0.handle_ = nil
		end
	end, 1)
end

function var_0_0.showBuffInfo(arg_14_0, arg_14_1, arg_14_2)
	if not arg_14_1 then
		if arg_14_0.buffInfoWnd and not tolua.isnull(arg_14_0.buffInfoWnd) then
			arg_14_0.buffInfoWnd:setVisible(false)
		end

		return
	end

	if not arg_14_0.buffInfoWnd or tolua.isnull(arg_14_0.buffInfoWnd) then
		local var_14_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/guild_war/guild_buff/show_buff_info.csb")

		var_14_0:addTo(arg_14_0.contentView_:nodeByName("container"))
		var_14_0:setVisible(false)

		arg_14_0.buffInfoWnd = var_14_0
	end

	if not arg_14_0.buffsInfo then
		return
	end

	local var_14_1 = arg_14_0.buffsInfo.self_buff_info or {}
	local var_14_2 = arg_14_0.buffsInfo.enemy_buff_info or {}
	local var_14_3 = {}
	local var_14_4 = {}

	if arg_14_0.selfSide and arg_14_0.selfSide == 0 then
		var_14_3 = var_14_2
		var_14_4 = var_14_1
	else
		var_14_3 = var_14_1
		var_14_4 = var_14_2
	end

	local var_14_5 = arg_14_2 == 1 and var_14_3 or var_14_4
	local var_14_6 = arg_14_0.buffInfoWnd:getChildByName("container")

	for iter_14_0 = 1, var_0_4 do
		local var_14_7 = iter_14_0 + 3
		local var_14_8 = 0

		if var_14_5[iter_14_0] and next(var_14_5[iter_14_0]) then
			var_14_8 = var_14_5[iter_14_0].guild_add + var_14_5[iter_14_0].player_add

			if var_14_8 == xyd.tables.misc.guildWarBuffMax then
				var_14_8 = 11
			end

			var_14_7 = var_14_5[iter_14_0].attr_id
		end

		var_14_6:getChildByName("text_" .. iter_14_0):setString(string.format(var_0_2:translation("GUILD_WAR_DESC_BUFF" .. var_14_7), var_14_8))
	end

	arg_14_0.buffInfoWnd:setVisible(true)

	if arg_14_2 == 1 then
		arg_14_0.buffInfoWnd:setPosition(cc.p(50, -220))
	else
		arg_14_0.buffInfoWnd:setPosition(cc.p(200, -220))
	end
end

function var_0_0.getEnemyGuildName(arg_15_0)
	local var_15_0 = ""

	if arg_15_0.guild.warEnemy and arg_15_0.guild.warEnemy.guildId ~= 0 then
		var_15_0 = arg_15_0.guild.warEnemy.name
	else
		var_15_0 = var_0_2:translation("GUILD_BATTLE_NAME")
	end

	return var_15_0
end

function var_0_0.update(arg_16_0, arg_16_1, arg_16_2)
	arg_16_0.buffsInfo = arg_16_1

	local var_16_0 = arg_16_1.self_buff_info or {}
	local var_16_1 = arg_16_1.enemy_buff_info or {}
	local var_16_2 = {}
	local var_16_3 = {}
	local var_16_4 = ""
	local var_16_5 = ""

	arg_16_0.selfSide = arg_16_2

	if arg_16_0.selfSide and arg_16_0.selfSide == 0 then
		var_16_2 = var_16_1
		var_16_4 = arg_16_0:getEnemyGuildName()
		var_16_3 = var_16_0
		var_16_5 = arg_16_0.guild.guild_name
	else
		var_16_2 = var_16_0
		var_16_4 = arg_16_0.guild.guild_name
		var_16_3 = var_16_1
		var_16_5 = arg_16_0:getEnemyGuildName()
	end

	for iter_16_0 = 1, var_0_4 do
		if var_16_2[iter_16_0] and next(var_16_2[iter_16_0]) then
			local var_16_6 = var_16_2[iter_16_0].guild_add + var_16_2[iter_16_0].player_add

			arg_16_0.contentView_:nodeByName("bar_left_" .. iter_16_0):setPercent(var_16_6 * 10)
		else
			arg_16_0.contentView_:nodeByName("bar_left_" .. iter_16_0):setPercent(0)
		end
	end

	arg_16_0.contentView_:nodeByName("text_left_name"):setString(var_16_4)
	arg_16_0.contentView_:nodeByName("text_right_name"):setString(var_16_5)

	for iter_16_1 = 1, var_0_4 do
		if var_16_3[iter_16_1] and next(var_16_3[iter_16_1]) then
			local var_16_7 = var_16_3[iter_16_1].guild_add + var_16_3[iter_16_1].player_add

			arg_16_0.contentView_:nodeByName("bar_right_" .. iter_16_1):setPercent(var_16_7 * 10)
		else
			arg_16_0.contentView_:nodeByName("bar_right_" .. iter_16_1):setPercent(0)
		end
	end
end

return var_0_0
