local var_0_0 = class("ConfirmRentWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.window = arg_1_2.window
	arg_1_0.type = arg_1_2.type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("ok_btn"), arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0

			if arg_3_0.window then
				var_4_0 = xyd.WindowManager.get():getWindow(arg_3_0.window)
			else
				var_4_0 = xyd.WindowManager.get():getWindow("select_team_old")

				if not var_4_0 or tolua.isnull(var_4_0) then
					var_4_0 = xyd.WindowManager.get():getWindow("battle_select_team")
				end
			end

			if var_4_0 and not var_4_0.battleBegan then
				var_4_0.battleBegan = true

				var_4_0:startBattle()
			end

			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end
	end)
	arg_3_0:nodeByName("close"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("close"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():closeWindow(arg_3_0.name)
		end
	end)
	arg_3_0:nodeByName("word_player"):setString(var_0_2:translation("CONFRIM_RENT_TEXT1"))
	arg_3_0:nodeByName("word_mana"):setString(var_0_2:translation("CONFRIM_RENT_TEXT2"))
	arg_3_0:nodeByName("text_cancel"):setString(var_0_2:translation("CONFRIM_RENT_TEXT3"))
	arg_3_0:nodeByName("text_sure"):setString(var_0_2:translation("CONFRIM_RENT_TEXT4"))
	arg_3_0:nodeByName("text_player"):setString(arg_3_0.hero.player_name)
	arg_3_0:nodeByName("text_hero"):setString(xyd.tables.hero:name(arg_3_0.hero:getTableID()))

	local var_3_0 = var_0_1.new({
		size = 500
	})

	var_3_0:addTo(arg_3_0:nodeByName("line"))
	var_3_0:setAnchorPoint(0, 0.5)

	if arg_3_0.type == xyd.ConfirmRent.HERO then
		arg_3_0:nodeByName("word_hero"):setString(var_0_2:translation("CONFRIM_RENT_TEXT5"))

		local var_3_1 = string.format(var_0_2:translation("CONFRIM_RENT_TEXT7"), arg_3_0.hero.player_name)
		local var_3_2 = xyd.createMultiColorTxt(var_3_1, cc.c4b(54, 54, 54, 255), 20, true)

		var_3_2:setAnchorPoint(0.5, 0.5)
		arg_3_0:nodeByName("text_tips"):addChild(var_3_2)
	elseif arg_3_0.type == xyd.ConfirmRent.TUTOR then
		arg_3_0:nodeByName("text_player"):setString(var_0_2:translation("TUTOR_RENT_TITLE_TEXT"))
		arg_3_0:nodeByName("word_hero"):setString(var_0_2:translation("CONFRIM_RENT_TEXT5"))
		arg_3_0:nodeByName("text_tips"):setVisible(false)
	else
		arg_3_0:nodeByName("word_hero"):setString(var_0_2:translation("CONFRIM_RENT_TEXT6"))

		local var_3_3 = string.format(var_0_2:translation("CONFRIM_RENT_TEXT8"), arg_3_0.hero.player_name)
		local var_3_4 = xyd.createMultiColorTxt(var_3_3, cc.c4b(54, 54, 54, 255), 20, true)

		var_3_4:setAnchorPoint(0.5, 0.5)
		arg_3_0:nodeByName("text_tips"):addChild(var_3_4)
	end

	arg_3_0:nodeByName("title"):setString(var_0_2:translation("CONFIRM_TO_BORROW"))
	arg_3_0:nodeByName("cost"):setString(arg_3_0.hero.rent_need_mana)
end

function var_0_0.didOpen(arg_6_0, arg_6_1)
	var_0_0.super:didOpen(arg_6_1)
	arg_6_0:addBlockLayer()
end

return var_0_0
