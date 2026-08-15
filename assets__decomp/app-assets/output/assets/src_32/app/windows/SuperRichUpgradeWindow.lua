local var_0_0 = class("SuperRichUpgradeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.misc.activityRichBoutiqueCost
local var_0_3 = xyd.tables.misc.activityRichBoutiqueGain
local var_0_4 = xyd.tables.activityRichMap

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.info = arg_1_2.info
	arg_1_0.stationType = arg_1_2.grid_type
	arg_1_0.lev = arg_1_0.info.lev or 0
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text3"):setString(var_0_1:translation("SUPER_RICH_SELECT_UPGRADE_TEXT3"))
	arg_3_0:nodeByName("text2"):setString(string.format(var_0_1:translation("SUPER_RICH_SELECT_UPGRADE_TEXT2"), var_0_4:name(arg_3_0.pos)))
	arg_3_0:nodeByName("text1"):setString(var_0_1:translation("SUPER_RICH_SELECT_UPGRADE_TEXT1"))

	if arg_3_0.stationType ~= 5 then
		arg_3_0:nodeByName("cost_txt"):setString(var_0_2[arg_3_0.lev + 1])
		arg_3_0:nodeByName("text4"):setString(var_0_3[arg_3_0.lev] or 0)
		arg_3_0:nodeByName("text5"):setString(var_0_3[arg_3_0.lev + 1])
	else
		arg_3_0:nodeByName("cost_txt"):setString(xyd.tables.misc.activityRichBankCost)

		local var_3_0 = xyd.AssetLoader.get():loadSprite("images/icon/eco/yuanbao.png")

		arg_3_0:nodeByName("mana1"):setSpriteFrame(var_3_0:getSpriteFrame())
		arg_3_0:nodeByName("mana2"):setSpriteFrame(var_3_0:getSpriteFrame())
		arg_3_0:nodeByName("jinbi"):setSpriteFrame(var_3_0:getSpriteFrame())
		arg_3_0:nodeByName("text4"):setString(0)
		arg_3_0:nodeByName("text5"):setString(xyd.tables.misc.activityRichBankGain)
	end

	arg_3_0:setButtonClick()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				pos = arg_4_0.pos,
				grid_type = arg_4_0.stationType
			}

			if arg_4_0.stationType ~= 5 and arg_4_0.selfPlayer.mana < var_0_2[arg_4_0.lev + 1] then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("JINBI_ABSENCE"), function()
					local var_6_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_4_0.selfPlayer:isFuncOpen(var_6_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_6_1 = xyd.tables.functionOpen:level(var_6_0)
						local var_6_2 = string.format(var_0_1:translation("FUNCTION_OPEN_TIP_LEVEL"), var_6_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_6_2
						})
					end
				end, nil, nil, arg_4_0.colorMode)

				return
			elseif arg_4_0.stationType == 5 and arg_4_0.selfPlayer.crystal < xyd.tables.misc.activityRichBankCost then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
					xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge)
				end, nil, nil, arg_4_0.colorMode)

				return
			end

			arg_4_0.superRich:monoplyOperate(var_5_0, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					local var_8_0 = arg_8_1.grid_info

					arg_4_0.info.lev = var_8_0.lev
					arg_4_0.info.move = var_8_0.move

					xyd.WindowManager.get():closeWindow(arg_4_0)
				end
			end)
		end
	end)
end

function var_0_0.willClose(arg_9_0, arg_9_1)
	var_0_0.super.willClose(arg_9_0, arg_9_1)

	if arg_9_0.callback then
		arg_9_0.callback()
	end
end

return var_0_0
