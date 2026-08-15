local var_0_0 = class("HunqiDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = {
	EQUIP = 1,
	UNEQUIP = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()

	arg_1_0:setParams(arg_1_2)
end

function var_0_0.setParams(arg_2_0, arg_2_1)
	arg_2_0.item1 = arg_2_1.item1
	arg_2_0.itemParams1 = arg_2_1.itemParams1 or {}
	arg_2_0.item2 = arg_2_1.item2
	arg_2_0.itemParams2 = arg_2_1.itemParams2 or {}
	arg_2_0.hero = arg_2_1.hero
	arg_2_0.equips = arg_2_1.equips
	arg_2_0.hideLockBtn = arg_2_1.hideLockBtn
end

function var_0_0.willOpen(arg_3_0)
	arg_3_0:layout()
end

function var_0_0.didOpen(arg_4_0)
	arg_4_0:addNoTouchLayer()
end

function var_0_0.layout(arg_5_0)
	arg_5_0.tipWidth = 0
	arg_5_0.tipHeight = 0

	arg_5_0:initItem(arg_5_0.item1, arg_5_0.itemParams1, 1)

	if arg_5_0.item2 then
		arg_5_0:initItem(arg_5_0.item2, arg_5_0.itemParams2, 2)
	end
end

function var_0_0.getTipHeight(arg_6_0)
	return arg_6_0.tipHeight
end

function var_0_0.getTipWidth(arg_7_0)
	return arg_7_0.tipHeight
end

function var_0_0.initItem(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	local var_8_0
	local var_8_1
	local var_8_2

	if arg_8_2.isSuit then
		var_8_1 = arg_8_2.suitID
	else
		local var_8_3 = arg_8_1.table_id

		var_8_1 = xyd.tables.spiritEquip:from(var_8_3)
		var_8_2 = xyd.tables.spiritEquip:modelId(var_8_3)
	end

	local var_8_4 = display.newNode()
	local var_8_5 = 320
	local var_8_6 = 25

	if arg_8_1 then
		local var_8_7 = {
			size = 17,
			align = cc.ui.TEXT_ALIGN_CENTER,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(168, 202, 222)
		}
		local var_8_8 = xyd.AssetLoader.get():loadLabel(var_8_7)

		var_8_8:setString("No." .. arg_8_1.spirit_id)
		var_8_8:setAnchorPoint(cc.p(0, 0))
		var_8_8:addTo(var_8_4)
		var_8_8:setPosition(27, 18)

		var_8_6 = var_8_6 + 17 + 4
	end

	if arg_8_2.showStrenthen and arg_8_1.lev < xyd.HunqiMaxLev then
		local var_8_9 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/btn.png")

		var_8_9:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_9:addTo(var_8_4)
		var_8_9:setPosition(86, var_8_6 + 23)

		local var_8_10 = {
			size = 24,
			align = cc.ui.TEXT_ALIGN_CENTER,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(55, 72, 77)
		}
		local var_8_11 = xyd.AssetLoader.get():loadLabel(var_8_10)

		var_8_11:setString("Enhance")
		var_8_11:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_11:addTo(var_8_9)
		var_8_11:setPosition(61, 29)
		xyd.nodeEventSample(var_8_9, nil, function()
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("hunqi_strengthen", {
				targetItem = arg_8_1
			})
			arg_8_0:close()
		end)
	end

	if arg_8_2.rightBtnType then
		local var_8_12

		if arg_8_0.equips then
			var_8_12 = arg_8_0.equips
		else
			var_8_12 = arg_8_0.hero:getSpiritEquips()
		end

		local var_8_13 = xyd.tables.spirit:pos(var_8_2)
		local var_8_14 = arg_8_0.backpack:getSpiritItemBySpiritID(var_8_12[var_8_13])
		local var_8_15 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/btn.png")

		var_8_15:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_15:addTo(var_8_4)
		var_8_15:setPosition(234, var_8_6 + 23)

		local var_8_16 = {
			size = 24,
			align = cc.ui.TEXT_ALIGN_CENTER,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(55, 72, 77)
		}
		local var_8_17 = xyd.AssetLoader.get():loadLabel(var_8_16)

		var_8_17:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_17:addTo(var_8_15)
		var_8_17:setPosition(61, 29)

		if arg_8_2.rightBtnType == var_0_2.EQUIP then
			if not var_8_14 then
				var_8_17:setString("Equip")
			else
				var_8_17:setString("Replace")
			end
		elseif arg_8_2.rightBtnType == var_0_2.UNEQUIP then
			var_8_17:setString("Remove")
		end

		xyd.nodeEventSample(var_8_15, nil, function()
			xyd.playButtonSound()

			if arg_8_0.equips then
				local var_10_0 = xyd.WindowManager.get():getWindow("hunqi_comb_editor")

				if var_10_0 and not tolua.isnull(var_10_0) then
					local var_10_1 = arg_8_1.spirit_id

					if arg_8_2.rightBtnType == var_0_2.UNEQUIP then
						var_10_1 = 0
					end

					var_10_0:onSelectSpirit(var_8_13, var_10_1)
				end

				arg_8_0:close()
			else
				local var_10_2 = {
					partner_id = arg_8_0.hero:getHeroID(),
					spirit_id = arg_8_1.spirit_id,
					pos = var_8_13
				}

				if arg_8_2.rightBtnType == var_0_2.UNEQUIP then
					var_10_2.spirit_id = 0
				end

				xyd.Backend.get():request(xyd.mid.HUNQI_EQUIP, var_10_2, function(arg_11_0, arg_11_1)
					if arg_11_0 == xyd.error.OK then
						if not arg_8_0 or tolua.isnull(arg_8_0) then
							return
						end

						if arg_8_2.rightBtnType ~= var_0_2.EQUIP or not not var_8_14 then
							var_8_14.is_equip = 0

							arg_8_0.backpack:setSpiritItem(var_8_14.spirit_id, {
								is_equip = 0
							})
						end

						if arg_8_2.rightBtnType == var_0_2.EQUIP then
							arg_8_0.backpack:setSpiritItem(arg_8_1.spirit_id, {
								is_equip = var_10_2.partner_id
							})
						end

						arg_8_0.hero:setSpiritEquips(arg_11_1.spirit_equip)

						local var_11_0 = xyd.WindowManager.get():getWindow("hero_main")

						if var_11_0 and not tolua.isnull(var_11_0) then
							var_11_0:updateAttrScore()
							var_11_0:updateAttrLabels()
						end

						local var_11_1 = xyd.WindowManager.get():getWindow("hunqi")

						if var_11_1 then
							var_11_1:updateAllItems()
						end

						arg_8_0:close()
					end
				end)
			end
		end)
	end

	if arg_8_2.showStrenthen or arg_8_2.rightBtnType then
		var_8_6 = var_8_6 + 56 + 25
	end

	if arg_8_2.isSuit then
		local var_8_18 = xyd.tables.spiritSuit:campainDesc(var_8_1)
		local var_8_19 = ""

		for iter_8_0 = 1, #var_8_18 do
			var_8_19 = var_8_19 .. var_8_18[iter_8_0] .. "\n"
		end

		local var_8_20 = cc.c3b(255, 255, 255)
		local var_8_21 = {
			size = 18,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = var_8_20,
			dimensions = cc.size(var_8_5 - 64, 0)
		}
		local var_8_22 = xyd.AssetLoader.get():loadLabel(var_8_21)

		var_8_22:setString(var_8_19)
		var_8_22:setAnchorPoint(cc.p(0, 0))
		var_8_22:addTo(var_8_4)
		var_8_22:setPosition(32, var_8_6 - 10)
		var_8_22:setLineHeight(27)

		var_8_6 = var_8_6 + var_8_22:getContentSize().height

		local var_8_23 = cc.c3b(255, 239, 148)
		local var_8_24 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = var_8_23,
			dimensions = cc.size(var_8_5 - 64, 0)
		}
		local var_8_25 = xyd.AssetLoader.get():loadLabel(var_8_24)

		var_8_25:setString(var_0_1:translation("HUNQI_TEXT_24"))
		var_8_25:setAnchorPoint(cc.p(0, 0))
		var_8_25:addTo(var_8_4)
		var_8_25:setPosition(32, var_8_6)

		var_8_6 = var_8_6 + var_8_25:getContentSize().height + 9

		local var_8_26 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/devide.png")

		var_8_26:addTo(var_8_4)
		var_8_26:setPosition(var_8_5 / 2, var_8_6 + var_8_26:getHeight() / 2)

		var_8_6 = var_8_6 + var_8_26:getHeight() + 11
	end

	local var_8_27 = arg_8_2.showActive and arg_8_0:isActive4(var_8_1) and cc.c3b(126, 245, 179) or cc.c3b(168, 202, 222)
	local var_8_28 = {
		size = 18,
		align = cc.ui.TEXT_ALIGN_LEFT,
		font = xyd.AssetLoader.FONT_NAME,
		color = var_8_27,
		dimensions = cc.size(var_8_5 - 64, 0)
	}
	local var_8_29 = var_0_1:translation("HUNQI_TEXT_26") .. xyd.tables.spiritSuit:attr4Desc(var_8_1)
	local var_8_30 = xyd.AssetLoader.get():loadLabel(var_8_28)

	var_8_30:setString(var_8_29)
	var_8_30:setAnchorPoint(cc.p(0, 0))
	var_8_30:addTo(var_8_4)
	var_8_30:setPosition(32, var_8_6 - 9)
	var_8_30:setLineHeight(27)

	local var_8_31 = var_8_6 + var_8_30:getContentSize().height
	local var_8_32 = arg_8_2.showActive and arg_8_0:isActive2(var_8_1) and cc.c3b(126, 245, 179) or cc.c3b(168, 202, 222)
	local var_8_33 = {
		size = 18,
		align = cc.ui.TEXT_ALIGN_LEFT,
		font = xyd.AssetLoader.FONT_NAME,
		color = var_8_32,
		dimensions = cc.size(var_8_5 - 64, 0)
	}
	local var_8_34 = (var_0_1:translation("HUNQI_TEXT_25") .. "\n") .. xyd.tables.attr:name(xyd.tables.spiritSuit:attr2(var_8_1))
	local var_8_35, var_8_36 = xyd.tables.spiritSuit:attr2Value(var_8_1)

	if var_8_36 then
		var_8_34 = var_8_34 .. " + " .. var_8_35 / 100
		var_8_34 = var_8_34 .. "%"
	else
		var_8_34 = var_8_34 .. " + " .. var_8_35
	end

	local var_8_37 = xyd.AssetLoader.get():loadLabel(var_8_33)

	var_8_37:setString(var_8_34)
	var_8_37:setAnchorPoint(cc.p(0, 0))
	var_8_37:addTo(var_8_4)
	var_8_37:setPosition(32, var_8_31 - 9)
	var_8_37:setLineHeight(27)

	local var_8_38 = var_8_31 + var_8_37:getContentSize().height
	local var_8_39 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/devide.png")

	var_8_39:addTo(var_8_4)
	var_8_39:setPosition(var_8_5 / 2, var_8_38 + var_8_39:getHeight() / 2)

	local var_8_40 = var_8_38 + var_8_39:getHeight() + 11

	if not arg_8_2.isSuit then
		if arg_8_1.sub then
			for iter_8_1 = #arg_8_1.sub, 1, -1 do
				local var_8_41 = arg_8_1.sub[iter_8_1]
				local var_8_42 = {
					size = 20,
					align = cc.ui.TEXT_ALIGN_LEFT,
					font = xyd.AssetLoader.FONT_NAME,
					color = cc.c3b(255, 255, 255)
				}
				local var_8_43 = xyd.AssetLoader.get():loadLabel(var_8_42)

				var_8_43:setString((xyd.tables.attr:name(xyd.tables.spirit:sub(var_8_2, var_8_41))))
				var_8_43:setAnchorPoint(cc.p(0, 0))
				var_8_43:addTo(var_8_4)
				var_8_43:setPosition(32, var_8_40)

				local var_8_44 = "+"

				if xyd.tables.spirit:subIsP(var_8_2, var_8_41) ~= 0 then
					local var_8_45 = arg_8_1.sub_attr_value[iter_8_1] / xyd.DECIMAL_BASE * 100

					var_8_44 = var_8_44 .. var_8_45 .. "%"
				else
					var_8_44 = var_8_44 .. arg_8_1.sub_attr_value[iter_8_1]
				end

				local var_8_46 = {
					size = 20,
					align = cc.ui.TEXT_ALIGN_LEFT,
					font = xyd.AssetLoader.FONT_NAME,
					color = cc.c3b(255, 255, 255)
				}
				local var_8_47 = xyd.AssetLoader.get():loadLabel(var_8_46)

				var_8_47:setString(var_8_44)
				var_8_47:setAnchorPoint(cc.p(1, 0))
				var_8_47:addTo(var_8_4)
				var_8_47:setPosition(var_8_5 - 30, var_8_40)

				var_8_40 = var_8_40 + 31
			end

			local var_8_48 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/devide.png")

			var_8_48:addTo(var_8_4)
			var_8_48:setPosition(var_8_5 / 2, var_8_40 + var_8_48:getHeight() / 2)

			var_8_40 = var_8_40 + var_8_48:getHeight() + 11
		end

		if arg_8_1.is_equip ~= 0 then
			local var_8_49 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/equiped.png")

			var_8_49:addTo(var_8_4, 1)
			var_8_49:setPosition(var_8_5 / 2, var_8_40)
			var_8_49:setOpacity(180)
		end

		local var_8_50 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(255, 239, 148)
		}
		local var_8_51 = xyd.AssetLoader.get():loadLabel(var_8_50)

		var_8_51:setString(xyd.tables.attr:name(xyd.tables.spirit:main(var_8_2, arg_8_1.main)))
		var_8_51:setAnchorPoint(cc.p(0, 0))
		var_8_51:addTo(var_8_4)
		var_8_51:setPosition(32, var_8_40)

		local var_8_52 = "+"

		if xyd.tables.spirit:mainIsP(var_8_2, arg_8_1.main) ~= 0 then
			local var_8_53 = arg_8_1.main_attr_value / xyd.DECIMAL_BASE * 100

			var_8_52 = var_8_52 .. var_8_53 .. "%"
		else
			var_8_52 = var_8_52 .. arg_8_1.main_attr_value
		end

		local var_8_54 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(255, 239, 148)
		}
		local var_8_55 = xyd.AssetLoader.get():loadLabel(var_8_54)

		var_8_55:setString(var_8_52)
		var_8_55:setAnchorPoint(cc.p(1, 0))
		var_8_55:addTo(var_8_4)
		var_8_55:setPosition(var_8_5 - 30, var_8_40)

		var_8_40 = var_8_40 + 31

		local var_8_56 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/devide.png")

		var_8_56:addTo(var_8_4)
		var_8_56:setPosition(var_8_5 / 2, var_8_40 + var_8_56:getHeight() / 2)

		var_8_40 = var_8_40 + var_8_56:getHeight() + 4
	end

	local var_8_57 = 133
	local var_8_58 = display.newNode()

	var_8_58:setContentSize(var_8_57, var_8_57)
	var_8_58:setAnchorPoint(cc.p(0.5, 0.5))
	var_8_58:addTo(var_8_4)
	var_8_58:setPosition(61, var_8_40 + 47)

	if arg_8_2.isSuit then
		local var_8_59 = xyd.SpriteLoader.new("images/hunqi/icon/" .. var_8_1 .. ".png", nil, nil, xyd.DefaultImageType.QUESTION_MARK2)

		var_8_58:setContentSize(100, 100)
		xyd.displaySpriteOnContainer(var_8_59, var_8_58)
	else
		local var_8_60 = {
			noBorder = true,
			noLev = true,
			container = var_8_58,
			item = arg_8_1
		}

		xyd.setHunqiBorder(var_8_60)
	end

	local var_8_61 = xyd.tables.spiritSuit:name(var_8_1)

	if not arg_8_2.isSuit and arg_8_1.lev ~= 0 then
		var_8_61 = var_8_61 .. "+" .. arg_8_1.lev
	end

	local var_8_62 = {
		size = 22,
		align = cc.ui.TEXT_ALIGN_LEFT,
		font = xyd.AssetLoader.FONT_NAME,
		color = cc.c3b(100, 255, 253)
	}
	local var_8_63 = xyd.AssetLoader.get():loadLabel(var_8_62)

	var_8_63:setString(var_8_61)
	var_8_63:setAnchorPoint(cc.p(0, 0))
	var_8_63:addTo(var_8_4)
	var_8_63:setPosition(122, var_8_40 + 51)

	if not arg_8_2.isSuit and not arg_8_0.hideLockBtn then
		local var_8_64 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/unlock.png")

		var_8_64:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_64:addTo(var_8_4)
		var_8_64:setPosition(273, var_8_40 + 23)

		local var_8_65 = xyd.AssetLoader.get():loadSprite("windows/hunqi/detail/lock.png")

		var_8_65:setAnchorPoint(cc.p(0.5, 0.5))
		var_8_65:addTo(var_8_4)
		var_8_65:setPosition(273, var_8_40 + 23)
		var_8_64:setTouchEnabled(true)
		var_8_64:setTouchSwallowEnabled(true)
		var_8_64:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
			if arg_12_0.name == "ended" then
				xyd.playButtonSound()

				local var_12_0 = {
					spirit_id = arg_8_1.spirit_id
				}

				xyd.Backend.get():request(xyd.mid.HUNQI_LOCK, var_12_0, function(arg_13_0, arg_13_1)
					if arg_13_0 == xyd.error.OK then
						if not arg_8_0 or tolua.isnull(arg_8_0) then
							return
						end

						arg_8_0.backpack:setSpiritItem(arg_8_1.spirit_id, {
							is_lock = 1
						})

						if arg_8_2.relateIcon and not tolua.isnull(arg_8_2.relateIcon) then
							local var_13_0 = {
								container = arg_8_2.relateIcon,
								item = arg_8_0.backpack:getSpiritItemBySpiritID(arg_8_1.spirit_id)
							}

							xyd.setHunqiBorder(var_13_0)
						end

						var_8_64:setVisible(false)
						var_8_65:setVisible(true)
					end
				end)
			end

			return true
		end)
		var_8_65:setTouchEnabled(true)
		var_8_65:setTouchSwallowEnabled(true)
		var_8_65:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
			if arg_14_0.name == "ended" then
				xyd.playButtonSound()

				local var_14_0 = {
					spirit_id = arg_8_1.spirit_id
				}

				xyd.Backend.get():request(xyd.mid.HUNQI_UNLOCK, var_14_0, function(arg_15_0, arg_15_1)
					if arg_15_0 == xyd.error.OK then
						if not arg_8_0 or tolua.isnull(arg_8_0) then
							return
						end

						arg_8_0.backpack:setSpiritItem(arg_8_1.spirit_id, {
							is_lock = 0
						})

						if arg_8_2.relateIcon then
							local var_15_0 = {
								container = arg_8_2.relateIcon,
								item = arg_8_0.backpack:getSpiritItemBySpiritID(arg_8_1.spirit_id)
							}

							xyd.setHunqiBorder(var_15_0)
						end

						var_8_64:setVisible(true)
						var_8_65:setVisible(false)
					end
				end)
			end

			return true
		end)
		var_8_64:setVisible(arg_8_1.is_lock == 0)
		var_8_65:setVisible(arg_8_1.is_lock ~= 0)
	end

	local var_8_66 = var_8_40 + 102
	local var_8_67 = "windows/hunqi/detail/bg_pop.png"
	local var_8_68 = display.newScale9Sprite(var_8_67, 0, 0, cc.size(var_8_5, var_8_66), cc.rect(20, 20, 20, 20))

	var_8_68:setAnchorPoint(cc.p(0, 0))
	var_8_68:addTo(var_8_4, -1)
	var_8_68:setTouchEnabled(true)
	var_8_68:setTouchSwallowEnabled(true)
	var_8_4:addTo(arg_8_0.contentView_)
	var_8_4:setName("node_" .. arg_8_3)

	if arg_8_3 == 1 then
		arg_8_0:nodeByName("container_1"):setContentSize(var_8_5, var_8_66)

		arg_8_0.tipWidth = var_8_5
		arg_8_0.tipHeight = var_8_66
	else
		arg_8_0:nodeByName("container_2"):setContentSize(var_8_5, var_8_66)
		var_8_4:setPositionX(var_8_5 + 8)
		arg_8_0:nodeByName("container_2"):setPosition(var_8_5 + 8, 0)

		arg_8_0.tipWidth = arg_8_0.tipWidth + var_8_5 + 8

		if var_8_66 > arg_8_0.tipHeight then
			arg_8_0:nodeByName("container_1"):setPositionY(var_8_66 - arg_8_0.tipHeight)
			arg_8_0.contentView_:getChildByName("node_1"):setPositionY(var_8_66 - arg_8_0.tipHeight)

			arg_8_0.tipHeight = var_8_66
		else
			var_8_4:setPositionY(arg_8_0.tipHeight - var_8_66)
			arg_8_0:nodeByName("container_2"):setPositionY(arg_8_0.tipHeight - var_8_66)
		end
	end
end

function var_0_0.addNoTouchLayer(arg_16_0)
	local function var_16_0(arg_17_0, arg_17_1)
		if arg_17_1 == ccui.TouchEventType.ended and not noClose then
			local var_17_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_17_0, false)
			xyd.WindowManager.get():closeWindow(arg_16_0.name)
		end

		return true
	end

	local function var_16_1(arg_18_0, arg_18_1)
		if callback then
			callback()
		end

		if not noClose then
			local var_18_0 = xyd.tables.sound:getSound("ui_close_window")

			audio.playSound(var_18_0, false)
			xyd.WindowManager.get():closeWindow(arg_16_0.name)
		end
	end

	if not touchFalse then
		arg_16_0.layerListener = cc.EventListenerTouchOneByOne:create()

		arg_16_0.layerListener:registerScriptHandler(var_16_0, cc.Handler.EVENT_TOUCH_BEGAN)
		arg_16_0.layerListener:registerScriptHandler(var_16_1, cc.Handler.EVENT_TOUCH_ENDED)
		arg_16_0:getEventDispatcher():addEventListenerWithSceneGraphPriority(arg_16_0.layerListener, arg_16_0.contentView_)
	end
end

function var_0_0.isActive2(arg_19_0, arg_19_1)
	if arg_19_0.hero then
		local var_19_0, var_19_1 = arg_19_0.hero:getSpiritSuitID()

		for iter_19_0, iter_19_1 in ipairs(var_19_0) do
			if iter_19_1 == arg_19_1 then
				return true
			end
		end
	end

	return false
end

function var_0_0.isActive4(arg_20_0, arg_20_1)
	if arg_20_0.hero then
		local var_20_0, var_20_1 = arg_20_0.hero:getSpiritSuitID()

		if var_20_1 == arg_20_1 then
			return true
		end
	end

	return false
end

return var_0_0
