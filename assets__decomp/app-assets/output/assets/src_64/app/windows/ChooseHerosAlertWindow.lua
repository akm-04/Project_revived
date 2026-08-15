local var_0_0 = class("ChooseHerosAlertWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	RENT_HERO = 1,
	RENT_PET = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:setTouchSwallowEnabled(false)

	local var_1_0 = arg_1_2.hero
	local var_1_1 = arg_1_2.pet

	if var_1_1 then
		arg_1_0.rentType = var_0_2.RENT_PET
		arg_1_0.rent = var_1_1
	else
		arg_1_0.rentType = var_0_2.RENT_HERO
		arg_1_0.rent = var_1_0
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = var_0_1:translation("LEND_HERO_ALERT")

	arg_3_0:colorWords(arg_3_0:nodeByName("text_1"), var_3_0, {
		arg_3_0.rent:getName() .. xyd.Color2Level[arg_3_0.rent:getColor()]
	})
	arg_3_0:nodeByName("text_1"):setString("")
	arg_3_0:nodeByName("right_btn"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_4_0, false)

			local var_4_1 = xyd.WindowManager.get():getWindow("choose_heros")

			if var_4_1 then
				if arg_3_0.rentType == var_0_2.RENT_HERO then
					var_4_1:rentHeroOK(arg_3_0.rent:getHeroID())
				else
					var_4_1:rentPetOK(arg_3_0.rent:getPetID())
				end
			end

			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
	arg_3_0:nodeByName("cancel_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_5_0, false)
			xyd.WindowManager.get():closeWindow(arg_3_0)
		end
	end)
end

function var_0_0.colorWords(arg_6_0, arg_6_1, arg_6_2, arg_6_3)
	local var_6_0 = display.newNode()
	local var_6_1 = arg_6_2
	local var_6_2 = 0
	local var_6_3 = 1
	local var_6_4 = false

	while true do
		local var_6_5 = string.find(var_6_1, "{")
		local var_6_6 = string.find(var_6_1, "}")

		if var_6_5 and var_6_6 then
			local var_6_7 = string.sub(var_6_1, 1, var_6_5 - 1)
			local var_6_8 = arg_6_3[var_6_3]

			var_6_3 = var_6_3 + 1
			var_6_1 = string.sub(var_6_1, var_6_6 + 1, #var_6_1)

			if var_6_5 < var_6_6 then
				local var_6_9 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 25,
					text = var_6_7,
					color = xyd.color.BLACK,
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_6_0:addChild(var_6_9)
				var_6_9:setPosition(var_6_2, 3)
				var_6_9:setAnchorPoint(cc.p(0, 0))

				var_6_2 = var_6_2 + var_6_9:getContentSize().width + 3

				local var_6_10 = display.newTTFLabel({
					font = "fonts/main_font.ttf",
					size = 25,
					text = var_6_8,
					color = xyd.isSuperHero(arg_6_0.rent) and xyd.color.SUPER_HERO or xyd.color.HERO_QUALITY[arg_6_0.rent:getColor()],
					align = cc.TEXT_ALIGNMENT_LEFT
				})

				var_6_10:enableShadow(cc.c4b(1, 1, 1, 200), cc.size(1, -1), 1)
				var_6_0:addChild(var_6_10)
				var_6_10:setPosition(var_6_2, 3)
				var_6_10:setAnchorPoint(cc.p(0, 0))

				var_6_2 = var_6_2 + var_6_10:getContentSize().width + 3

				if var_6_8 == nil then
					arg_6_0.is_wrong_item = true

					break
				else
					arg_6_0.is_wrong_item = false
				end
			else
				print("wrong data.")

				break
			end
		elseif var_6_5 or var_6_6 then
			print("Wrong data.")

			break
		else
			local var_6_11 = display.newTTFLabel({
				font = "fonts/main_font.ttf",
				size = 25,
				text = var_6_1,
				color = xyd.color.BLACK,
				align = cc.TEXT_ALIGNMENT_LEFT
			})

			var_6_0:addChild(var_6_11)
			var_6_11:setPosition(var_6_2, 3)
			var_6_11:setAnchorPoint(cc.p(0, 0))

			break
		end
	end

	arg_6_1:addChild(var_6_0)
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	var_0_0.super:willClose(arg_7_1)
end

function var_0_0.didOpen(arg_8_0, arg_8_1)
	var_0_0.super:didOpen(arg_8_1)
	arg_8_0:addBlockLayer()
end

return var_0_0
