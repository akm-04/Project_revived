local var_0_0 = class("EditPlayerNameWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = 100

var_0_0.EIDT_NAME_NODE = "edit_name_node"
var_0_0.CHANGE_NAME_BTN = "change_btn"
var_0_0.OK = "ok_btn"
var_0_0.CLOSE = "close"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.editName = xyd.ModelManager.get():loadModel(xyd.ModelType.EDIT_PLAYER_NAME)
	arg_1_0.filterWord = xyd.ModelManager.get():loadModel(xyd.ModelType.FILTER_WORD)
	arg_1_0.playerName = arg_1_0.selfPlayer.playerName
	arg_1_0.nameList = {}

	if arg_1_2 then
		arg_1_0.callback = arg_1_2.callback
		arg_1_0.noClose_ = arg_1_2.notClose
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:init()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willOpen(arg_3_1)

	if arg_3_0.callback then
		arg_3_0.callback()
	end
end

function var_0_0.inputboxEventHandler(arg_4_0, arg_4_1)
	if arg_4_1 == "began" then
		arg_4_0.nameEditbox_:setText(arg_4_0:nodeByName("name_txt"):getString())
		arg_4_0:nodeByName("name_txt"):setString("")
	end

	if arg_4_1 == "return" then
		local var_4_0 = arg_4_0.nameEditbox_:getText()

		arg_4_0:nodeByName("name_txt"):setString(var_4_0)
		arg_4_0.nameEditbox_:setText("")
		arg_4_0.nameEditbox_:setVisible(true)
	end
end

function var_0_0.init(arg_5_0)
	arg_5_0:nodeByName("name_txt"):setString("")
	arg_5_0:nodeByName("label_tittle"):setString(xyd.tables.translation:translation("EDIT_PLAY_NAME_TITLE"))
	arg_5_0:nodeByName("txt_ok"):setString(var_0_1:translation("OK"))
	arg_5_0:nodeByName("txt_cancel"):setString(var_0_1:translation("CANCEL"))

	local var_5_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_5_0, cc.rect(28, 28, 1, 1))

	arg_5_0.nameEditbox_ = ccui.EditBox:create(cc.size(210, 32), var_5_0)

	arg_5_0:nodeByName(var_0_0.EIDT_NAME_NODE):addChild(arg_5_0.nameEditbox_)
	arg_5_0.nameEditbox_:setAnchorPoint(cc.p(0, 0))
	arg_5_0.nameEditbox_:setPosition(0, 0)
	arg_5_0.nameEditbox_:registerScriptEditBoxHandler(handler(arg_5_0, arg_5_0.inputboxEventHandler))
	arg_5_0.nameEditbox_:setInputFlag(3)
	arg_5_0.nameEditbox_:setFontColor(cc.c3b(122, 162, 207))

	if not arg_5_0.playerName or arg_5_0.playerName == "" then
		if not next(arg_5_0.nameList) then
			arg_5_0.editName:getGenerateName(function(arg_6_0)
				if not arg_5_0 or tolua.isnull(arg_5_0) then
					return
				end

				if arg_6_0 == xyd.error.OK then
					arg_5_0.nameList = arg_5_0.editName.nameList

					arg_5_0:nodeByName("name_txt"):setString(arg_5_0.nameList[1])
					table.remove(arg_5_0.nameList, 1)
				end
			end)
		else
			arg_5_0:nodeByName("name_txt"):setString(arg_5_0.nameList[1])
			table.remove(arg_5_0.nameList, 1)
		end
	else
		arg_5_0:nodeByName("name_txt"):setString(arg_5_0.playerName)
	end
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	xyd.nodeEventSample(arg_7_0:nodeByName("cancel"), nil, function(arg_8_0)
		local var_8_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_8_0, false)

		if arg_7_0.noClose_ then
			local var_8_1 = xyd.tables.translation:translation("CANNOT_CLOSE_EDIT_PLAYERNAME")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_8_1
			})
		else
			if xyd.WindowManager.get():getWindow("arena") then
				xyd.WindowManager.get():closeWindow("arena")
			end

			if xyd.WindowManager.get():getWindow("chat") then
				xyd.WindowManager.get():closeWindow("chat")
			end

			if xyd.WindowManager.get():getWindow("invite_friends") then
				xyd.WindowManager.get():closeWindow("invite_friends")
			end

			xyd.WindowManager.get():closeWindow(arg_7_0.name)
		end
	end)

	if arg_7_0.noClose_ and arg_7_0:closeButton() ~= nil then
		-- block empty
	end

	xyd.nodeEventSample(arg_7_0:nodeByName(var_0_0.CHANGE_NAME_BTN), nil, function(arg_9_0)
		if not next(arg_7_0.nameList) then
			arg_7_0.editName:getGenerateName(function(arg_10_0)
				if arg_10_0 == xyd.error.OK then
					arg_7_0.nameList = arg_7_0.editName.nameList

					arg_7_0:nodeByName("name_txt"):setString(arg_7_0.nameList[1])
					table.remove(arg_7_0.nameList, 1)
				end
			end)
		else
			arg_7_0:nodeByName("name_txt"):setString(arg_7_0.nameList[1])
			table.remove(arg_7_0.nameList, 1)
		end
	end)
	xyd.nodeEventSample(arg_7_0:nodeByName(var_0_0.OK), nil, function(arg_11_0)
		local var_11_0 = arg_7_0:nodeByName("name_txt"):getString()
		local var_11_1 = string.format(var_0_1:translation("NAME_LEN_MAX"), xyd.tables.misc.playerNameMaxLength)
		local var_11_2 = string.format(var_0_1:translation("NAME_LEN_LEAST"), xyd.tables.misc.playerNameMinLength)

		if xyd.utf8len(var_11_0) > xyd.tables.misc.playerNameMaxLength then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_11_1
			})

			return
		elseif xyd.utf8len(var_11_0) < xyd.tables.misc.playerNameMinLength then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_11_2
			})

			return
		end

		local var_11_3, var_11_4 = arg_7_0.filterWord:warningStrGsub(var_11_0)

		if var_11_4 then
			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_1:translation("INPUT_WITH_BAD_WORDS")
			})

			return
		end

		if arg_7_0.playerName and arg_7_0.playerName ~= "" then
			local var_11_5 = string.format(var_0_1:translation("RENAME_COST"), xyd.tables.misc.editNameCost)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_11_5, function()
				local var_12_0 = {
					player_name = var_11_0
				}

				arg_7_0.editName:editPlayerName(var_12_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						arg_7_0.selfPlayer.playerName = var_11_0

						arg_7_0:dispatchEvent({
							name = xyd.event.EDIT_NAME_FINISHED
						})
						var_0_2.performWithDelayGlobal(function()
							local var_14_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

							xyd.Backend.get():enterChatRoom(var_14_0.region)
							xyd.Backend.get():enterServiceChatRoom(99999)

							if var_14_0.guildID and var_14_0.guildID ~= 0 then
								xyd.Backend.get():enterLeagueRoom(var_14_0.guildID)
							end
						end, 1)
						xyd.WindowManager.get():closeWindow("edit_player_name")
						xyd.EventDispatcher.get():dispatchEvent({
							name = xyd.event.EDIT_NAME_FINISHED
						})
					end
				end)
			end, nil, nil, arg_7_0.colorMode)
		else
			local var_11_6 = {
				player_name = var_11_0
			}

			arg_7_0.editName:editPlayerName(var_11_6, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					arg_7_0.selfPlayer.playerName = var_11_0

					arg_7_0:dispatchEvent({
						name = xyd.event.EDIT_NAME_FINISHED
					})
					xyd.Backend.get():enterChatRoom(arg_7_0.selfPlayer.region)
					xyd.Backend.get():enterServiceChatRoom(99999)

					if arg_7_0.selfPlayer.guildID and arg_7_0.selfPlayer.guildID ~= 0 then
						xyd.Backend.get():enterLeagueRoom(arg_7_0.selfPlayer.guildID)
					end

					xyd.WindowManager.get():closeWindow("edit_player_name")
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.EDIT_NAME_FINISHED
					})
				else
					local var_15_0 = arg_15_1.error_code
					local var_15_1 = xyd.tables.message:getContent(var_15_0)

					xyd.WindowManager.get():openWindow("toast", {
						message = var_15_1
					})

					return
				end
			end)
		end
	end)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.buttonHandler(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	if arg_16_3 == ccui.TouchEventType.ended then
		transition.stopTarget(arg_16_2)
		arg_16_2:setScale(1)
		audio.getSoundsVolume(1)
		audio.playSound("sound/button.ogg", false)

		if arg_16_1 then
			arg_16_1(arg_16_2, arg_16_3)
		end
	elseif arg_16_3 == ccui.TouchEventType.began then
		return true
	elseif arg_16_3 == ccui.TouchEventType.canceled then
		transition.stopTarget(arg_16_2)
		arg_16_2:setScale(1)
	end
end

return var_0_0
