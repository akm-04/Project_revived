local var_0_0 = class("FragmentMake", import("app.common.ui.BaseWindow"))

var_0_0.NAME_TXT = "name_txt"
var_0_0.IMG_FROM = "img_from"
var_0_0.IMG_TO = "img_to"
var_0_0.TXT_FROM = "txt_from"
var_0_0.TXT_TO = "txt_to"
var_0_0.MAKE_TXT = "make_txt"
var_0_0.PRICE_LABLE = "price_label"
var_0_0.PRICE_NUM = "price_num"
var_0_0.MAKE_BUTTON = "make_button"
var_0_0.SUB_BUTTON = "sub_button"
var_0_0.ADD_BUTTON = "add_button"
var_0_0.MAX_BUTTON = "max_button"
var_0_0.TXT_NUM = "txt_num"
var_0_0.MAX_TXT = "max_txt"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.fromID = arg_1_2.itemID
	arg_1_0.toID = xyd.tables.item:composeItem(arg_1_0.fromID)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.fromImg = arg_2_0:nodeByName(var_0_0.IMG_FROM)

	arg_2_0.fromImg:removeAllChildren()

	arg_2_0.toImg = arg_2_0:nodeByName(var_0_0.IMG_TO)

	arg_2_0.toImg:removeAllChildren()

	arg_2_0.item_num = 1
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.item:name(arg_3_0.toID)
	local var_3_1 = xyd.tables.item:composeMana(arg_3_0.toID)

	arg_3_0:nodeByName(var_0_0.NAME_TXT):setString(var_0_1:translation("FRAGMENT_COMPOSE") .. var_3_0)
	arg_3_0:nodeByName(var_0_0.PRICE_LABLE):setString(var_0_1:translation("FRAGMENT_MAKE_COST"))
	arg_3_0:nodeByName(var_0_0.PRICE_NUM):setString(var_3_1)

	if var_3_1 > arg_3_0.player_.mana then
		arg_3_0:nodeByName(var_0_0.PRICE_NUM):setColor(cc.c4b(255, 0, 0, 150))
	else
		arg_3_0:nodeByName(var_0_0.PRICE_NUM):setColor(cc.c4b(254, 113, 54, 150))
	end

	if xyd.tables.item:type(arg_3_0.fromID) == xyd.ItemType.BOOK_FRAGMENT then
		arg_3_0:nodeByName("adjust_panel"):setVisible(false)
	end

	arg_3_0:nodeByName(var_0_0.TXT_FROM):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName(var_0_0.NAME_TXT):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName(var_0_0.TXT_TO):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName(var_0_0.PRICE_LABLE):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName(var_0_0.PRICE_NUM):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)

	local var_3_2 = arg_3_0.player_:getBackpack():getItemNumByID(arg_3_0.fromID)
	local var_3_3 = var_3_2
	local var_3_4 = xyd.tables.item:itemNum(arg_3_0.fromID)
	local var_3_5 = var_3_4
	local var_3_6 = arg_3_0:nodeByName(var_0_0.TXT_NUM)
	local var_3_7 = arg_3_0:nodeByName(var_0_0.SUB_BUTTON)
	local var_3_8 = arg_3_0:nodeByName(var_0_0.ADD_BUTTON)
	local var_3_9 = arg_3_0:nodeByName(var_0_0.MAX_BUTTON)
	local var_3_10 = arg_3_0:nodeByName(var_0_0.MAX_TXT)

	var_3_8:addTouchEventListener(function(arg_4_0, arg_4_1)
		xyd.buttonScaleAnim(var_3_8, arg_4_1)

		if arg_4_1 == ccui.TouchEventType.ended and var_3_2 >= var_3_5 and var_3_4 + var_3_5 <= var_3_3 then
			var_3_2 = var_3_2 - var_3_5
			var_3_4 = var_3_4 + var_3_5
			arg_3_0.item_num = arg_3_0.item_num + 1

			arg_3_0:nodeByName(var_0_0.TXT_FROM):setString(var_3_3 .. "/" .. var_3_4)
			var_3_6:setString(arg_3_0.item_num .. "/" .. math.floor(var_3_3 / var_3_5))
			arg_3_0:nodeByName(var_0_0.PRICE_NUM):setString(var_3_1 * arg_3_0.item_num)
		end
	end)
	var_3_7:addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(var_3_7, arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended and var_3_2 <= var_3_3 and var_3_4 > var_3_5 then
			var_3_2 = var_3_2 + var_3_5
			var_3_4 = var_3_4 - var_3_5
			arg_3_0.item_num = arg_3_0.item_num - 1

			arg_3_0:nodeByName(var_0_0.TXT_FROM):setString(var_3_3 .. "/" .. var_3_4)
			var_3_6:setString(arg_3_0.item_num .. "/" .. math.floor(var_3_3 / var_3_5))
			arg_3_0:nodeByName(var_0_0.PRICE_NUM):setString(var_3_1 * arg_3_0.item_num)
		end
	end)
	var_3_9:addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(var_3_9, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended and var_3_2 >= var_3_5 and var_3_4 + var_3_5 <= var_3_3 then
			local var_6_0 = math.floor(var_3_2 / var_3_5) - 1

			var_3_2 = var_3_2 - var_6_0 * var_3_5
			var_3_4 = var_3_4 + var_6_0 * var_3_5
			arg_3_0.item_num = arg_3_0.item_num + var_6_0

			arg_3_0:nodeByName(var_0_0.TXT_FROM):setString(var_3_3 .. "/" .. var_3_4)
			var_3_6:setString(arg_3_0.item_num .. "/" .. math.floor(var_3_3 / var_3_5))
			arg_3_0:nodeByName(var_0_0.PRICE_NUM):setString(var_3_1 * arg_3_0.item_num)
		end
	end)
	arg_3_0:nodeByName(var_0_0.TXT_FROM):setString(var_3_3 .. "/" .. var_3_4)
	var_3_6:setString(arg_3_0.item_num .. "/" .. math.floor(var_3_3 / var_3_5))
	arg_3_0:nodeByName(var_0_0.TXT_TO):setString(var_3_0)
	var_3_10:setString(var_0_1:translation("MAX"))
	xyd.setItemBorder(arg_3_0.fromImg, arg_3_0.fromID)
	xyd.setItemBorder(arg_3_0.toImg, arg_3_0.toID)
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0:addBlockLayer()
	arg_7_0:nodeByName(var_0_0.MAKE_BUTTON):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_7_0:nodeByName(var_0_0.MAKE_BUTTON), arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = xyd.tables.sound:getSound("hero_combine_equip")

			audio.playSound(var_8_0, false)

			if arg_7_0.player_:getBackpack():getItemNumByID(arg_7_0.fromID) < xyd.tables.item:itemNum(arg_7_0.fromID) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ITEM_COMPOSE_NOT_ENOUGH")
				})
			elseif xyd.tables.item:type(arg_7_0.fromID) == xyd.ItemType.BOOK_FRAGMENT and arg_7_0.player_:getBackpack():getItemNumByID(arg_7_0.toID) > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("ITEM_COMPOSE_BOOK_HAD")
				})
			else
				arg_7_0.player_:makeItem({
					item_id = arg_7_0.toID,
					item_num = math.floor(arg_7_0.item_num)
				}, function(arg_9_0)
					if arg_9_0 == xyd.error.OK then
						local var_9_0 = xyd.WindowManager.get():getWindow("backpack")

						if var_9_0 ~= nil then
							var_9_0:updateItemDetail(arg_7_0.fromID)
							var_9_0:refreshDisplayOptionAfterSell()
						end

						local var_9_1 = xyd.WindowManager.get():getWindow("junk_chest")
						local var_9_2 = xyd.ModelManager.get():loadModel(xyd.ModelType.EVENTCENTRE)

						if var_9_1 ~= nil then
							var_9_2:sortBook()
							var_9_1:updateLeftContainer(2)
						end

						if xyd.WindowManager.get():getWindow("board_task_info_window") then
							xyd.WindowManager.get():getWindow("board_task_info_window"):updateMagicStoneInfos()
						end

						xyd.WindowManager.get():closeWindow(arg_7_0.name)
					end
				end)
			end
		end
	end)
end

return var_0_0
