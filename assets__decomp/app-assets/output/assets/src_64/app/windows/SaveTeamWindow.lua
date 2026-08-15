local var_0_0 = class("SaveTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.formation = arg_1_2.formation
	arg_1_0.pet_id = tostring(arg_1_2.pet_id)
	arg_1_0.presetHeroType = arg_1_2.presetHeroType
	arg_1_0.presetHeroIndex = arg_1_2.presetHeroIndex
	arg_1_0.teamName = ""
	arg_1_0.teamDefaultName = ""
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initSaveTeamName()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.initSaveTeamName(arg_4_0)
	if arg_4_0.presetHeroType == xyd.PresetHeroType.NEW_TEAM then
		arg_4_0.teamDefaultName = string.format(var_0_1:translation("PRESET_TEAM_NAME"), arg_4_0.presetHeroIndex + 1)
	elseif arg_4_0.presetHeroType == xyd.PresetHeroType.ADJUST_TEAM then
		local var_4_0, var_4_1 = arg_4_0.player:getSaveTeamStr()

		arg_4_0.teamDefaultName = string.split(var_4_1, "|||")[arg_4_0.presetHeroIndex]
	end

	arg_4_0.teamName = arg_4_0.teamDefaultName
end

function var_0_0.layout(arg_5_0)
	arg_5_0:initEditBox()
	arg_5_0:nodeByName("text_ok"):setString(var_0_1:translation("OK"))
	arg_5_0:nodeByName("text_cancel"):setString(var_0_1:translation("CANCEL"))
	arg_5_0:nodeByName("text_desc"):setString(var_0_1:translation("PRESET_TEAM_MAKE_NAME"))
	arg_5_0:nodeByName("btn_cancel"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
	arg_5_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_7_0, arg_7_1)
		xyd.buttonScaleAnim(arg_7_0, arg_7_1)

		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_5_0:checkTeamNameValid() then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("PRESET_TEAM_NAME_INVALID")
				})

				return
			end

			if not arg_5_0.teamName or arg_5_0.teamName == "" then
				arg_5_0.teamName = arg_5_0.teamDefaultName
			end

			local var_7_0, var_7_1, var_7_2 = arg_5_0:getSaveTeamStr()
			local var_7_3 = {
				team_str = var_7_0,
				team_name_str = var_7_1,
				pet_str = var_7_2
			}

			arg_5_0.player:heroPreset(var_7_3, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.HERO_PRESET_REFRESH
					})

					if arg_5_0.callback then
						arg_5_0.callback(arg_8_0, arg_8_1)
					end

					xyd.WindowManager.get():closeWindow(arg_5_0)
				end
			end)
		end
	end)
end

function var_0_0.checkTeamNameValid(arg_9_0)
	local var_9_0 = arg_9_0.teamName

	if string.find(var_9_0, " ") or string.find(var_9_0, "|") then
		return false
	end

	return true
end

function var_0_0.getSaveTeamStr(arg_10_0)
	local var_10_0 = ""
	local var_10_1 = ""
	local var_10_2 = ""
	local var_10_3, var_10_4, var_10_5 = arg_10_0.player:getSaveTeamStr()

	if arg_10_0.presetHeroType == xyd.PresetHeroType.NEW_TEAM then
		if not var_10_3 or var_10_3 == "" then
			var_10_0 = arg_10_0.formation
			var_10_1 = arg_10_0.teamName
			var_10_2 = arg_10_0.pet_id
		else
			var_10_0 = var_10_3 .. ":" .. arg_10_0.formation
			var_10_1 = var_10_4 .. "|||" .. arg_10_0.teamName
			var_10_2 = var_10_5 .. "|" .. arg_10_0.pet_id
		end
	elseif arg_10_0.presetHeroType == xyd.PresetHeroType.ADJUST_TEAM then
		local var_10_6 = xyd.split(var_10_3, ":")

		var_10_6[arg_10_0.presetHeroIndex] = arg_10_0.formation
		var_10_0 = arg_10_0:tableToString(var_10_6, ":")

		local var_10_7 = string.split(var_10_4, "|||")

		var_10_7[arg_10_0.presetHeroIndex] = arg_10_0.teamName
		var_10_1 = arg_10_0:tableToString(var_10_7, "|||")

		local var_10_8 = string.split(var_10_5, "|")

		var_10_8[arg_10_0.presetHeroIndex] = arg_10_0.pet_id
		var_10_2 = arg_10_0:tableToString(var_10_8, "|")
	end

	return var_10_0, var_10_1, var_10_2
end

function var_0_0.tableToString(arg_11_0, arg_11_1, arg_11_2)
	local var_11_0 = arg_11_1[1] or ""

	for iter_11_0 = 2, #arg_11_1 do
		var_11_0 = var_11_0 .. arg_11_2 .. arg_11_1[iter_11_0]
	end

	return var_11_0
end

function var_0_0.initEditBox(arg_12_0)
	arg_12_0:nodeByName("text_name"):setString("")

	local var_12_0 = "windows/login/transparent.png"
	local var_12_1 = arg_12_0:nodeByName("edit_container")

	arg_12_0.editbox_ = ccui.EditBox:create(var_12_1:getContentSize(), var_12_0)

	arg_12_0:nodeByName("edit_container"):addChild(arg_12_0.editbox_)
	arg_12_0.editbox_:setAnchorPoint(cc.p(0, 0))
	arg_12_0.editbox_:setPosition(0, 0)
	arg_12_0.editbox_:registerScriptEditBoxHandler(handler(arg_12_0, arg_12_0.inputboxEventHandler))
	arg_12_0.editbox_:setInputFlag(3)

	if not arg_12_0.teamName or arg_12_0.teamName == "" then
		arg_12_0.teamName = arg_12_0.teamDefaultName

		arg_12_0:nodeByName("text_name"):setString(arg_12_0.teamDefaultName)
		arg_12_0:nodeByName("text_name"):setColor(cc.c3b(122, 162, 207))
	else
		arg_12_0:nodeByName("text_name"):setString(arg_12_0.teamName)
		arg_12_0:nodeByName("text_name"):setColor(cc.c3b(122, 162, 207))
	end
end

function var_0_0.inputboxEventHandler(arg_13_0, arg_13_1)
	if arg_13_1 == "began" then
		if not arg_13_0.teamName or arg_13_0.teamName == "" then
			arg_13_0:nodeByName("text_name"):setString("")
		else
			arg_13_0.editbox_:setText(arg_13_0:nodeByName("text_name"):getString())
			arg_13_0:nodeByName("text_name"):setString("")
		end
	end

	if arg_13_1 == "return" then
		local var_13_0 = arg_13_0.editbox_:getText()

		if var_13_0 == "" then
			arg_13_0.teamName = arg_13_0.teamDefaultName

			arg_13_0:nodeByName("text_name"):setString(arg_13_0.teamDefaultName)
			arg_13_0:nodeByName("text_name"):setColor(cc.c3b(122, 162, 207))
		else
			if xyd.utf8len(var_13_0) > 10 then
				var_13_0 = xyd.getTextstr(var_13_0, 1, 10)
			end

			arg_13_0.teamName = var_13_0

			arg_13_0:nodeByName("text_name"):setString(var_13_0)
			arg_13_0:nodeByName("text_name"):setColor(cc.c3b(122, 162, 207))
		end

		arg_13_0.editbox_:setText("")
	end
end

function var_0_0.willClose(arg_14_0, arg_14_1)
	var_0_0.super.willClose(arg_14_1)
end

return var_0_0
