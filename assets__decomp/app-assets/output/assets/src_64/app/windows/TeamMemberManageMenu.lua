local var_0_0 = class("TeamMemberManageMenu", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.job = arg_1_2.job
	arg_1_0.parent = arg_1_2.parent
	arg_1_0.memberId = arg_1_2.memberId
	arg_1_0.memberJob = arg_1_2.memberJob
	arg_1_0.theName = arg_1_2.selfName
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	if arg_3_0.job == 1 then
		if arg_3_0.memberJob == 2 then
			arg_3_0:nodeByName("renming"):setVisible(false)
			arg_3_0:nodeByName("jiechu"):setVisible(true)
		else
			arg_3_0:nodeByName("renming"):setVisible(true)
			arg_3_0:nodeByName("jiechu"):setVisible(false)
		end

		arg_3_0:nodeByName("fu_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
			xyd.buttonScaleAnim(arg_3_0:nodeByName("fu_btn"), arg_4_1)

			if arg_4_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_4_0 = {}
				local var_4_1 = ""
				local var_4_2 = ""

				if arg_3_0.memberJob == 2 then
					var_4_0 = {
						job = 0,
						member_id = arg_3_0.memberId
					}
					var_4_1 = string.format(var_0_2:translation("GUILD_REMOVE_JOB_ALERT"), arg_3_0.theName)
					var_4_2 = string.format(var_0_2:translation("GUILD_REMOVE_JOB_OK"), arg_3_0.theName)
				elseif arg_3_0.memberJob == 0 then
					var_4_0 = {
						job = 2,
						member_id = arg_3_0.memberId
					}
					var_4_1 = string.format(var_0_2:translation("GUILD_APPOINT_JOB_ALERT"), arg_3_0.theName)
					var_4_2 = string.format(var_0_2:translation("GUILD_APPOINT_JOB_OK"), arg_3_0.theName)
				end

				if arg_3_0.memberJob ~= 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						var_4_1
					}, function(arg_5_0)
						arg_3_0.guild:setJob(var_4_0, function(arg_6_0, arg_6_1)
							if arg_6_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_4_2
								})

								if arg_6_1 == nil then
									arg_6_1 = 0
								end

								arg_3_0.parent:init(arg_6_1)
								xyd.WindowManager.get():closeWindow(arg_3_0)

								return true
							end
						end)
					end)
				end
			end
		end)
		arg_3_0:nodeByName("zhuan_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
			xyd.buttonScaleAnim(arg_3_0:nodeByName("zhuan_btn"), arg_7_1)

			if arg_7_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
					var_0_2:translation("TEAM_PRESIDENT_TRANSFER")
				}, function(arg_8_0)
					params_ = {
						job = 1,
						member_id = arg_3_0.memberId
					}

					if arg_3_0.memberJob ~= 1 then
						arg_3_0.guild:setJob(params_, function(arg_9_0, arg_9_1)
							if arg_9_0 == xyd.error.OK then
								local var_9_0 = var_0_2:translation("GUILD_CHANGE_PRESIDENT_OK")

								xyd.WindowManager.get():openWindow("toast", {
									message = var_9_0
								})
								xyd.WindowManager.get():closeWindow(arg_3_0.parent.parent)
								xyd.WindowManager.get():closeWindow(arg_3_0.parent)
								xyd.WindowManager.get():closeWindow(arg_3_0)

								return true
							end
						end)
					end
				end)
			end
		end)
		arg_3_0:nodeByName("ti_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			xyd.buttonScaleAnim(arg_3_0:nodeByName("ti_btn"), arg_10_1)

			if arg_10_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				params_ = {
					member_id = arg_3_0.memberId
				}

				if arg_3_0.memberJob ~= 1 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_2:translation("GUILD_KICK_OUT_ALERT"), arg_3_0.theName)
					}, function(arg_11_0)
						arg_3_0.guild:kickTeam(params_, function(arg_12_0, arg_12_1)
							if arg_12_0 == xyd.error.OK then
								local var_12_0 = string.format(var_0_2:translation("GUILD_KICK_OUT_OK"), arg_3_0.theName)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_12_0
								})
								arg_3_0.parent:init(arg_12_1)
								xyd.WindowManager.get():closeWindow(arg_3_0)

								return true
							end
						end)
					end)
				end
			end
		end)
	elseif arg_3_0.job == 2 then
		arg_3_0:nodeByName("zhuan_btn"):setVisible(false)
		arg_3_0:nodeByName("fu_btn"):setVisible(false)
		arg_3_0:nodeByName("container"):height(120)
		arg_3_0:nodeByName("ti_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
			xyd.buttonScaleAnim(arg_3_0:nodeByName("ti_btn"), arg_13_1)

			if arg_13_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				params_ = {
					member_id = arg_3_0.memberId
				}

				if arg_3_0.memberJob == 0 then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
						string.format(var_0_2:translation("GUILD_KICK_OUT_ALERT"), arg_3_0.theName)
					}, function(arg_14_0)
						arg_3_0.guild:kickTeam(params_, function(arg_15_0, arg_15_1)
							if arg_15_0 == xyd.error.OK then
								local var_15_0 = string.format(var_0_2:translation("GUILD_KICK_OUT_OK"), arg_3_0.theName)

								xyd.WindowManager.get():openWindow("toast", {
									message = var_15_0
								})
								arg_3_0.parent:init(arg_15_1)
								xyd.WindowManager.get():closeWindow(arg_3_0)

								return true
							end
						end)
					end)
				end
			end
		end)
	end
end

function var_0_0.didOpen(arg_16_0, arg_16_1)
	var_0_0.super:didOpen(arg_16_1)
	arg_16_0:addBlockLayer()
end

return var_0_0
