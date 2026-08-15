local var_0_0 = class("PlayoffsDeclarationWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = xyd.tables.misc.guildBulletinMaxCharNum
local var_0_6 = xyd.tables.misc.guildBulletinMinCharNum

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.PlayoffsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.PLAYOFFS)
	arg_1_0.regionArena = xyd.ModelManager.get():loadModel(xyd.ModelType.REGION_ARENA)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	return
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	if arg_4_0.teamDes == nil then
		arg_4_0.teamDes = var_0_4:translation("PLAYOFFS_DEFAULT_DECLARATION")
	end

	local var_4_0 = "windows/login/transparent.png"

	xyd.AssetLoader.get():loadSprite(var_4_0, cc.rect(28, 28, 1, 1))

	arg_4_0.sidEditbox_ = ccui.EditBox:create(cc.size(arg_4_0:nodeByName("text_container"):getWidth(), arg_4_0:nodeByName("text_container"):getHeight()), var_4_0):align(display.LEFT_BOTTOM, arg_4_0:nodeByName("text_container"):getX(), arg_4_0:nodeByName("text_container"):getY()):addTo(arg_4_0:nodeByName("background"))

	arg_4_0.sidEditbox_:setFontSize(24)
	arg_4_0.sidEditbox_:registerScriptEditBoxHandler(handler(arg_4_0, arg_4_0.inputboxEventHandler))
	arg_4_0.sidEditbox_:setInputFlag(3)

	arg_4_0.editY = arg_4_0:nodeByName("text_container"):getY()

	local var_4_1 = xyd.tables.regionArenaLevel:getPlayerArenaLevel(arg_4_0.regionArena:getStar())
	local var_4_2

	arg_4_0.season = arg_4_0.regionArena:getSeasonCount()

	if arg_4_0.season <= 10 then
		var_4_2 = var_0_1:translation("NUM_" .. arg_4_0.season)
	else
		var_4_2 = tostring(arg_4_0.season)
	end

	arg_4_0:nodeByName("text_"):setString(string.format(var_0_1:translation("PLAYOFFS_DECLARATION_SEASON"), var_4_2))
	arg_4_0:nodeByName("dec"):setString(arg_4_0.teamDes)
	arg_4_0:nodeByName("confirm_button"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if var_0_6 > 0 and xyd.getTextLen(arg_4_0.teamDes) < var_0_6 then
				local var_5_0 = string.format(var_0_4:translation("TEAM_NOTICE_LIMMIT_MIN_ALERT"), var_0_6)

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_5_0, nil, nil, nil, arg_4_0.colorMode)
			else
				local var_5_1 = {
					dec = arg_4_0.teamDes
				}

				arg_4_0.PlayoffsModel:setDeclaration(var_5_1, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						if xyd.WindowManager.get():getWindow("playoffs_player_info") then
							xyd.WindowManager.get():getWindow("playoffs_player_info"):updateDeclaration(arg_6_1.dec)
						end

						return true
					end
				end)
				xyd.WindowManager.get():closeWindow(arg_4_0)
			end
		end
	end)
end

function var_0_0.inputboxEventHandler(arg_7_0, arg_7_1)
	if arg_7_1 == "began" then
		arg_7_0.sidEditbox_:setText(arg_7_0:nodeByName("dec"):getString())
		arg_7_0:nodeByName("dec"):setString("")
	end

	if arg_7_1 == "return" then
		local var_7_0 = arg_7_0.sidEditbox_:getText()

		if xyd.getTextLen(var_7_0) <= var_0_5 then
			local var_7_1 = arg_7_0.sidEditbox_:getText()

			arg_7_0:nodeByName("dec"):setString(var_7_1)

			arg_7_0.teamDes = var_7_1
		else
			local var_7_2 = string.format(var_0_4:translation("TEAM_NOTICE_LIMMIT_ALERT"), var_0_5)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.ONE_BTN, var_7_2, nil, nil, nil, arg_7_0.colorMode)
		end

		arg_7_0.sidEditbox_:setText("")
		arg_7_0.sidEditbox_:setVisible(true)
		arg_7_0.sidEditbox_:setPositionY(arg_7_0.editY)
	end
end

return var_0_0
