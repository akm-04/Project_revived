local var_0_0 = class("TeamSettingNameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 500

var_0_0.EIDT_NAME_NODE = "edit_name_node"
var_0_0.OK = "ok_btn"
var_0_0.CLOSE = "close"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.editName = xyd.ModelManager.get():loadModel(xyd.ModelType.EDIT_PLAYER_NAME)
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
	arg_1_0.teamName = arg_1_2.name
	arg_1_0.parent = arg_1_2.parent
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.inputboxEventHandler(arg_3_0, arg_3_1)
	if arg_3_1 == "began" then
		local var_3_0 = arg_3_0:nodeByName("name_txt"):getString()

		arg_3_0:nodeByName("name_txt"):setString("")
		arg_3_0.nameEditbox_:setText(var_3_0)
	end

	if arg_3_1 == "return" then
		local var_3_1 = arg_3_0.nameEditbox_:getText()
		local var_3_2 = false

		if var_3_1 then
			_, var_3_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD):warningStrGsub(var_3_1)
		end

		local var_3_3 = xyd.getTextLen(var_3_1)

		if var_3_1 == "" then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("TEAM_INPUT_NAME_EMPTY"), nil, nil, nil, arg_3_0.colorMode)
		elseif var_3_2 then
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_0_1:translation("INPUT_WITH_BAD_WORDS"), nil, nil, nil, arg_3_0.colorMode)
		elseif var_3_1 ~= nil and var_3_3 <= xyd.tables.misc.guildNameMaxCharNum then
			arg_3_0.teamName = var_3_1

			arg_3_0:nodeByName("name_txt"):setString(arg_3_0.teamName)
		else
			local var_3_4 = string.format(var_0_1:translation("TEAM_INPUT_NAME_LIMMIT_ALERT"), tonumber(xyd.tables.misc.guildNameMaxCharNum))

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_3_4, nil, nil, nil, arg_3_0.colorMode)
		end

		arg_3_0.nameEditbox_:setText("")
	end
end

function var_0_0.init(arg_4_0)
	arg_4_0:nodeByName("name_txt"):setString("")
	arg_4_0:nodeByName("Label_tittle"):setString(xyd.tables.translation:translation("TEAM_CHANGE_NAME_TITLE"))

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.nameEditbox_ = ccui.EditBox:create(cc.size(280, 40), var_4_0)

	arg_4_0:nodeByName(var_0_0.EIDT_NAME_NODE):addChild(arg_4_0.nameEditbox_)
	arg_4_0.nameEditbox_:setAnchorPoint(cc.p(0, 0))
	arg_4_0.nameEditbox_:setPosition(0, 0)
	arg_4_0.nameEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.nameEditbox_:setInputFlag(3)
	arg_4_0:nodeByName("name_txt"):setString(arg_4_0.teamName)
end

function var_0_0.didOpen(arg_5_0, arg_5_1)
	var_0_0.super:didOpen(arg_5_1)
	arg_5_0:closeButton():addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_6_0, false)
			xyd.WindowManager.get():closeWindow(arg_5_0.name)
		end
	end)

	local var_5_0 = var_0_2

	arg_5_0:nodeByName(var_0_0.OK):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_1:translation("TEAM_CHANGE_NAME_ALERT"), var_0_2), function()
				if var_5_0 > arg_5_0.selfPlayer.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_9_0 = {}

						var_9_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					end, nil, nil, arg_5_0.colorMode)
				else
					arg_5_0.parent:updateTeamName(arg_5_0.teamName)
					xyd.WindowManager.get():closeWindow(arg_5_0.name)
				end
			end, nil, 0, arg_5_0.colorMode)
		end
	end)
	arg_5_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
