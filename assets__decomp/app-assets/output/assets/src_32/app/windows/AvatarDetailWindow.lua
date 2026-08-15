local var_0_0 = class("AvatarDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = 28
local var_0_4 = {
	10,
	30,
	80
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.avatarID = arg_1_2.ID
	arg_1_0.avatarName = xyd.tables.avatar.name_[arg_1_0.avatarID]
	arg_1_0.des = xyd.tables.avatar.description_[arg_1_0.avatarID]
	arg_1_0.icon = xyd.tables.avatar.icon_[arg_1_0.avatarID]
	arg_1_0.frameColor = arg_1_2.color
	arg_1_0.isFrame = arg_1_2.isFrame
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.panelAttr_ = arg_2_0:nodeByName("panel_attr")

	arg_2_0:nodeByName("has_txt"):setString(var_0_1:translation("TREASURE_UNLOCK"))
	arg_2_0:nodeByName("price_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_2_0:nodeByName("name_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_2_0:nodeByName("desc1_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_2_0:nodeByName("price_txt_1"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.backpack_ = arg_2_0.player_:getBackpack()
	arg_2_0.changeAvatar_ = xyd.ModelManager.get():loadModel(xyd.ModelType.CHANGE_AVATAR)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.avatarName
	local var_3_1 = arg_3_0.des

	arg_3_0:nodeByName("name_txt"):setString(var_3_0)
	arg_3_0:nodeByName("desc1_txt"):setString(var_3_1)
	arg_3_0:nodeByName("price_label"):setString(var_0_1:translation("PRESENT_PRICE"))
	arg_3_0:nodeByName("price_label_1"):setString(var_0_1:translation("ORIGINAL_PRICE"))

	local var_3_2 = xyd.currencyType.CRYSTAL
	local var_3_3 = xyd.tables.avatar.value2_[arg_3_0.avatarID]

	if var_3_3 == 0 then
		arg_3_0:nodeByName("txt_sure"):setVisible(true)
		arg_3_0:nodeByName("txt_buy"):setVisible(false)
		arg_3_0:nodeByName("price_container"):setVisible(false)
	else
		arg_3_0:nodeByName("txt_sure"):setVisible(false)
		arg_3_0:nodeByName("txt_buy"):setVisible(true)
	end

	arg_3_0:nodeByName("price_txt_1"):setString(xyd.tables.avatar.value1_[arg_3_0.avatarID])
	arg_3_0:nodeByName("price_txt"):setString(var_3_3)

	local var_3_4
	local var_3_5

	if var_3_2 == xyd.currencyType.CRYSTAL then
		var_3_4 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
		var_3_5 = xyd.AssetLoader:get():loadSprite("images/zuanshi.png")
	end

	arg_3_0:nodeByName("img_currency"):removeAllChildren()
	xyd.displaySpriteOnContainer(var_3_4, arg_3_0:nodeByName("img_currency"), false)
	xyd.displaySpriteOnContainer(var_3_5, arg_3_0:nodeByName("img_currency_1"), false)

	arg_3_0.iconImg = arg_3_0:nodeByName("img_icon")

	arg_3_0.iconImg:removeAllChildren()
	arg_3_0:setIcon(arg_3_0.icon, arg_3_0.iconImg, arg_3_0.frameColor)
	arg_3_0.panelAttr_:removeAllChildren()
end

function var_0_0.setIcon(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = "images/avatars/" .. arg_4_1 .. ".png"

	if arg_4_0.isFrame and arg_4_0.isFrame == true then
		var_4_0 = "images/avatar_frames/" .. arg_4_1 .. ".png"
	end

	local var_4_1 = arg_4_3
	local var_4_2
	local var_4_3 = xyd.AssetLoader.get():loadSprite(var_4_0)
	local var_4_4 = arg_4_2:getContentSize()

	var_4_3 = var_4_3 or xyd.AssetLoader.get():loadSprite("windows/common/common_avatar.png")

	if var_4_1 then
		local var_4_5 = xyd.AssetLoader:get():loadSprite("windows/common/avatar_mask.png")
		local var_4_6 = cc.ClippingNode:create()

		var_4_6:setStencil(var_4_5)
		var_4_6:setInverted(false)
		var_4_6:setAlphaThreshold(0)
		var_4_6:addChild(var_4_3)
		var_4_3:align(display.CENTER, var_4_4.width / 2, var_4_4.height / 2)
		var_4_3:scale(var_4_4.width / var_4_3:getWidth())
		var_4_5:addTo(arg_4_2, -1)
		var_4_5:align(display.CENTER, var_4_4.width / 2, var_4_4.height / 2)
		var_4_5:scale((var_4_4.width - 3) / var_4_5:getWidth())
		arg_4_2:addChild(var_4_6)
	else
		var_4_3:align(display.CENTER, var_4_4.width / 2, var_4_4.height / 2)
		var_4_3:scale(var_4_4.width / var_4_3:getWidth())
		arg_4_2:addChild(var_4_3)
	end

	if var_4_1 then
		if var_4_1 < 0 then
			local var_4_7 = xyd.getAvatarBorder(xyd.EquipQuality.ORANGE)
			local var_4_8 = clone(var_4_7:getContentSize())

			xyd.displaySpriteOnContainer(var_4_7, arg_4_2, true)
			var_4_7:setName("border")

			if var_4_1 == -1 then
				local var_4_9 = xyd.getAvatarBorder(0)

				xyd.displaySpriteOnContainer(var_4_9, arg_4_2, true)
				var_4_9:scale(var_4_4.width / var_4_9:getWidth() + 0.04)
			end
		else
			local var_4_10 = xyd.getAvatarBorder(var_4_1)
			local var_4_11 = clone(var_4_10:getContentSize())

			xyd.displaySpriteOnContainer(var_4_10, arg_4_2, true)
			var_4_10:setName("border")
		end
	end
end

function var_0_0.buy(arg_5_0)
	local var_5_0 = {
		id = arg_5_0.avatarID
	}

	arg_5_0.changeAvatar_:buyAvatar(var_5_0, function(arg_6_0)
		if arg_6_0 == xyd.error.OK then
			arg_5_0.player_:getBackpack():addItemsByID(arg_5_0.avatarID, 1)
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.UPDATE_AVATAR_LIST
			})
			xyd.WindowManager.get():closeWindow(arg_5_0)
		end
	end)
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0:nodeByName("buy_button"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
			local var_8_1 = xyd.tables.avatar.value2_[arg_7_0.avatarID]

			if var_8_1 ~= 0 then
				if var_8_1 > var_8_0.crystal then
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_1:translation("ZUANSHI_ABSENCE"), function()
						local var_9_0 = {}

						var_9_0.windowState = true

						xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
					end, nil, nil, arg_7_0.colorMode)
				else
					arg_7_0:buy()
				end
			else
				xyd.WindowManager.get():closeWindow(arg_7_0)
			end
		end
	end)
	arg_7_0:addBlockLayer()
end

return var_0_0
