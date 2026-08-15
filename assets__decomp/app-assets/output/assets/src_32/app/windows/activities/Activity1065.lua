local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.nianBoss = xyd.ModelManager.get():loadModel(xyd.ModelType.NIAN_BOSS)
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.startTime = arg_1_0.activity.start_time
	arg_1_0.endTime = arg_1_0.activity.end_time
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)
	arg_2_0.nianBoss:loadNianBoss(function(arg_3_0)
		if arg_3_0 ~= xyd.error.OK then
			print("nianboss info load faild.")
		else
			if not arg_2_0.res or arg_2_0.res == 0 then
				print("No res available.")

				return
			end

			local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

			var_3_0:addTo(arg_2_0.parent)
			var_3_0:setName("detail")
			var_3_0:setAnchorPoint(cc.p(0, 0))
			var_3_0:setPosition(0, 0)

			local var_3_1 = arg_2_0.parent:getChildByName("detail"):getChildByName("container")

			arg_2_0.first_name = var_3_1:getChildByName("flag"):getChildByName("first_name")
			arg_2_0.first_hurt = var_3_1:getChildByName("flag"):getChildByName("Text_10")

			if arg_2_0.nianBoss.top_info then
				arg_2_0.first_name:setString(arg_2_0.nianBoss.top_info.player_name)
				arg_2_0.first_hurt:setString(string.formatnumberthousands(arg_2_0.nianBoss.top_info.hurt))
			end

			arg_2_0:initThiefWindow()
		end
	end)
end

function var_0_0.initThiefWindow(arg_4_0)
	local var_4_0 = arg_4_0.parent:getChildByName("detail"):getChildByName("container")
	local var_4_1 = var_4_0:getChildByName("rule_button")
	local var_4_2 = var_4_0:getChildByName("battle_button")
	local var_4_3 = var_4_0:getChildByName("damage_button")
	local var_4_4 = var_4_0:getChildByName("model_container")
	local var_4_5 = var_4_0:getChildByName("rest_hp")
	local var_4_6 = var_4_0:getChildByName("progress_container"):getChildByName("hp_bar")
	local var_4_7 = xyd.tables.activities:title(arg_4_0.activity.table_id)
	local var_4_8 = xyd.AssetLoader.get():loadSprite(var_4_7)
	local var_4_9, var_4_10 = var_4_0:getChildByName("title_pos"):getPosition()

	var_4_0:getChildByName("a_text"):enableOutline(cc.c4b(0, 0, 0, 255), 2)
	var_4_0:getChildByName("a_text"):setVisible(false)
	var_4_0:getChildByName("a_text"):setString(var_0_1:translation("THIEF_DESC"))
	var_4_5:enableOutline(cc.c4b(0, 0, 0, 255), 2)
	var_4_8:addTo(var_4_0)
	var_4_8:setAnchorPoint(cc.p(0.5, 0.5))
	var_4_8:pos(var_4_9, var_4_10)
	var_4_1:addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("thief_rule_window")
		end
	end)
	var_4_2:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.ServerTime.get():getServerTime()

			if var_6_0 < arg_4_0.startTime then
				local var_6_1 = var_0_1:translation("ACTIVITY_NO_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_1
				})
			elseif var_6_0 > arg_4_0.endTime then
				local var_6_2 = var_0_1:translation("ACTIVITY_FINISHED")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_2
				})
			else
				if not arg_4_0:dealWrongTimeChallenge() then
					return
				end

				xyd.playButtonSound()
				xyd.WindowManager.get():openWindow("thief_boss_battle_pre")
			end
		end
	end)
	var_4_3:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("thief_rank_window")
		end
	end)

	local var_4_11 = var_4_4:getContentSize().width / 2
	local var_4_12 = (xyd.tables.nianBoss.need_brave[arg_4_0.nianBoss.boss_id] - arg_4_0.nianBoss.boss_brave) / xyd.tables.nianBoss.need_brave[arg_4_0.nianBoss.boss_id] * 100

	var_4_6:setPercent(var_4_12)

	if var_4_12 == 0 then
		var_4_0:getChildByName("money_bag"):setVisible(true)
		var_4_0:getChildByName("light_front"):setVisible(false)
		var_4_0:getChildByName("light_bg"):setVisible(false)
		var_4_2:setVisible(false)
		var_4_0:getChildByName("text_label1"):setVisible(true)
		var_4_0:getChildByName("text_label1"):setString(var_0_1:translation("THIEF_TEXT_LABEL1"))
		var_4_0:getChildByName("text_label2"):setVisible(true)
		var_4_5:setString(var_0_1:translation("THIEF_OVER"))
		arg_4_0:updateNextTime()
	else
		var_4_5:setString(string.format(var_0_1:translation("THIEF_PROCESS"), var_4_12))

		local var_4_13 = arg_4_0.nianBoss:getNianModel()

		var_4_13:setPosition(cc.p(var_4_11, 0))
		var_4_4:removeAllChildren()
		var_4_13:addTo(var_4_4)
		var_4_13:setTouchSwallowEnabled(true)
		var_4_13:setTouchEnabled(true)
		var_4_4:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				arg_4_0:openDialog()
			end
		end)
	end

	arg_4_0:updateThiefWindow()
end

function var_0_0.updateThiefWindow(arg_9_0)
	return
end

function var_0_0.openDialog(arg_10_0)
	local var_10_0 = arg_10_0.parent:getChildByName("detail"):getChildByName("container")

	if arg_10_0.dialogHandle then
		var_0_3.unscheduleGlobal(arg_10_0.dialogHandle)
	end

	var_10_0:getChildByName("dialog"):setVisible(true)
	var_10_0:getChildByName("dialog"):getChildByName("dialog_text"):setString(var_0_1:translation("THIEF_DIALOG"))

	arg_10_0.dialogHandle = var_0_3.performWithDelayGlobal(function()
		if not tolua.isnull(var_10_0) then
			var_10_0:getChildByName("dialog"):setVisible(false)
		end
	end, 3)
end

function var_0_0.updateNextTime(arg_12_0)
	local var_12_0 = arg_12_0.parent:getChildByName("detail"):getChildByName("container")

	if arg_12_0.handle1 then
		var_0_3.unscheduleGlobal(arg_12_0.handle1)

		arg_12_0.handle1 = nil
	end

	if not tolua.isnull(var_12_0) then
		var_12_0:getChildByName("text_label1"):setVisible(false)
		var_12_0:getChildByName("text_label2"):setString(var_0_1:translation("THIEF_ACTIVITY_OVER"))

		local var_12_1, var_12_2 = var_12_0:getChildByName("text_label2"):getPosition()

		var_12_0:getChildByName("text_label2"):setPosition(var_12_1, var_12_2 + 20)
	end

	if arg_12_0.handle1 then
		var_0_3.unscheduleGlobal(arg_12_0.handle1)

		arg_12_0.handle1 = nil
	end
end

function var_0_0.release(arg_13_0)
	if arg_13_0.handle1 then
		var_0_3.unscheduleGlobal(arg_13_0.handle1)
	end

	var_0_0.super:release()
end

function var_0_0.dealWrongTimeChallenge(arg_14_0)
	local var_14_0 = arg_14_0:checkTimeCanDo()

	if var_14_0 == true then
		return true
	elseif var_14_0 == false then
		local var_14_1 = var_0_1:translation("THIEF_NOT_OPEN")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_14_1
		})

		return false
	end

	return true
end

function var_0_0.checkTimeCanDo(arg_15_0)
	local var_15_0 = xyd.ServerTime.get():getSecondsOfDay()

	return true
end

return var_0_0
