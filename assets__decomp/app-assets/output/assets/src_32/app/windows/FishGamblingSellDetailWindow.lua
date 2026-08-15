local var_0_0 = class("FishGamblingSellDetailWindow", import("app.windows.SellDetailWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.misc
local var_0_3 = var_0_2:getValue("activity_fish_gambling_silver_coin")
local var_0_4 = var_0_2:getValue("activity_fish_gambling_crystal_to_coin")

var_0_0.ICON = "icon"
var_0_0.TXT_NAME = "txt_name"
var_0_0.TXT_HAS = "txt_has"
var_0_0.SELL_LABEL = "sell_label"
var_0_0.SELL_PRICE = "sell_price"
var_0_0.SELL_NUM_LABEL = "sell_num_label"
var_0_0.TXT_NUM = "txt_num"
var_0_0.TXT_MAX = "txt_max"
var_0_0.TOTAL_LABEL = "total_label"
var_0_0.TOTAL_PRICE = "total_price"
var_0_0.TXT_SELL = "txt_sell"
var_0_0.IMG_CURRENCY1 = "img_currency1"
var_0_0.IMG_CURRENCY2 = "img_currency2"
var_0_0.DECREASE_BUTTON = "decrease_button"
var_0_0.INCREASE_BUTTON = "increase_button"
var_0_0.MAX_BUTTON = "max_button"
var_0_0.SELL_BUTTON = "sell_button"

local var_0_5 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.player_:getBackpack()
	arg_1_0.itemID = arg_1_2.itemID
end

function var_0_0.didOpen(arg_2_0)
	var_0_0.super.didOpen(arg_2_0)
	arg_2_0:nodeByName(var_0_0.SELL_BUTTON):addTouchEventListener(function(arg_3_0, arg_3_1)
		xyd.buttonScaleAnim(arg_2_0:nodeByName(var_0_0.SELL_BUTTON), arg_3_1)

		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_3_0()
				if arg_2_0.itemID == var_0_3 then
					local var_4_0 = {
						num = arg_2_0.currentNum
					}

					xyd.Backend.get():request(xyd.mid.FISH_FIGHT_BUY, var_4_0, function(arg_5_0, arg_5_1)
						if arg_5_0 == xyd.error.OK then
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.ECONOMY_AFTER
							})
							arg_2_0.backpack:addItemsByID(arg_2_0.itemID, arg_2_0.currentNum)

							local var_5_0 = xyd.WindowManager.get():getWindow("fish_gambling_pledge")

							if var_5_0 then
								var_5_0:updateItemDetail(arg_2_0.itemID)
								var_5_0:refreshDisplayOptionAfterSell()
								var_5_0:updateEco()
							end

							local var_5_1 = xyd.WindowManager.get():getWindow("fish_gambling_main")

							if var_5_1 and xyd.WindowManager.get():isWindowOpen("fish_gambling_main") then
								var_5_1.hasNum = var_5_1.player_:getBackpack():getItemNumByID(arg_2_0.itemID)
								var_5_1.maxNum = var_5_1.hasNum

								var_5_1:updateEco()
								var_5_1:updateNum()
								var_5_1:reloadCardFish()
							end

							xyd.WindowManager.get():closeWindow(arg_2_0.name)
						end

						if callback then
							callback(arg_5_0, arg_5_1)
						end
					end)
				else
					local var_4_1 = {
						items = {}
					}

					var_4_1.items[1] = {}
					var_4_1.items[1].table_id = arg_2_0.itemID
					var_4_1.items[1].num = arg_2_0.currentNum

					xyd.Backend.get():request(xyd.mid.FISH_FIGHT_EXCHANGE, var_4_1, function(arg_6_0, arg_6_1)
						if arg_6_0 == xyd.error.OK then
							local var_6_0 = {
								itemID = arg_2_0.itemID,
								itemNum = arg_2_0.currentNum
							}

							arg_2_0.backpack:removeItem(var_6_0)

							local var_6_1 = xyd.error.OK
							local var_6_2 = {}
							local var_6_3 = arg_2_0.currentNum * arg_2_0.unitPrice

							arg_2_0.backpack:addItemsByID(var_0_3, var_6_3)

							local var_6_4 = xyd.WindowManager.get():getWindow("fish_gambling_pledge")

							if var_6_4 then
								var_6_4:updateItemDetail(arg_2_0.itemID)
								var_6_4:refreshDisplayOptionAfterSell()
								var_6_4:updateEco()
							end

							local var_6_5 = xyd.WindowManager.get():getWindow("fish_gambling_main")

							if var_6_5 and xyd.WindowManager.get():isWindowOpen("fish_gambling_main") then
								var_6_5.hasNum = var_6_5.player_:getBackpack():getItemNumByID(var_0_3)
								var_6_5.maxNum = var_6_5.hasNum

								var_6_5:updateEco()
								var_6_5:updateNum()
								var_6_5:reloadCardFish()
							end

							xyd.WindowManager.get():closeWindow(arg_2_0.name)
						end

						if callback then
							callback(arg_6_0, arg_6_1)
						end
					end)
				end
			end

			local var_3_1 = var_0_5:translation("SELL_CONFIRM_AGAIN")

			if arg_2_0.itemID == var_0_3 then
				var_3_1 = string.format(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_12"), arg_2_0.currentNum)
			end

			local var_3_2 = {
				rcallBefore = 0,
				title = var_0_5:translation("TIP"),
				txt = var_3_1,
				rcallback = var_3_0,
				align = xyd.ui_align.CENTER
			}

			xyd.WindowManager.get():openWindow("alert_green", var_3_2)
		end
	end)
end

function var_0_0.layout(arg_7_0)
	var_0_0.super.layout(arg_7_0)
	arg_7_0:nodeByName("sell"):setVisible(true)
	arg_7_0:nodeByName("sure_decompose_text"):setVisible(false)

	if arg_7_0.itemID == var_0_3 then
		arg_7_0:nodeByName("sell"):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_13"))
		arg_7_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_14"))
		arg_7_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_13"))
		arg_7_0:nodeByName(var_0_0.SELL_NUM_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_15"))

		arg_7_0.unitPrice = var_0_4

		arg_7_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_7_0.unitPrice)

		local var_7_0
		local var_7_1
		local var_7_2 = xyd.SpriteLoader.new("images/icon/eco/icon_crystal.png", nil, nil, xyd.DefaultImageType.CHARGE)
		local var_7_3 = xyd.SpriteLoader.new("images/icon/eco/icon_crystal.png", nil, nil, xyd.DefaultImageType.CHARGE)

		arg_7_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()
		arg_7_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()
		xyd.displaySpriteOnContainer(var_7_2, arg_7_0:nodeByName(var_0_0.IMG_CURRENCY1), true)
		xyd.displaySpriteOnContainer(var_7_3, arg_7_0:nodeByName(var_0_0.IMG_CURRENCY2), true)

		arg_7_0.totalNum = arg_7_0.player_:getEconomicItemNumByType(xyd.EconomicType.CRYSTAL)

		arg_7_0:updateNum()
	else
		arg_7_0:nodeByName("sell"):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_16"))
		arg_7_0:nodeByName(var_0_0.SELL_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_17"))
		arg_7_0:nodeByName(var_0_0.TOTAL_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_16"))
		arg_7_0:nodeByName(var_0_0.SELL_NUM_LABEL):setString(var_0_5:translation("ACTIVITY_FISH_GAMBLING_TEXT_18"))

		arg_7_0.unitPrice = xyd.tables.activityFishGamblingPledge:coinNumByItem(arg_7_0.itemID)

		arg_7_0:nodeByName(var_0_0.SELL_PRICE):setString(arg_7_0.unitPrice)

		local var_7_4
		local var_7_5
		local var_7_6 = xyd.SpriteLoader.new("windows/fish_gambling/fish_silver_coin.png", nil, nil, xyd.DefaultImageType.CHARGE)
		local var_7_7 = xyd.SpriteLoader.new("windows/fish_gambling/fish_silver_coin.png", nil, nil, xyd.DefaultImageType.CHARGE)

		arg_7_0:nodeByName(var_0_0.IMG_CURRENCY1):removeAllChildren()
		arg_7_0:nodeByName(var_0_0.IMG_CURRENCY2):removeAllChildren()
		xyd.displaySpriteOnContainer(var_7_6, arg_7_0:nodeByName(var_0_0.IMG_CURRENCY1), true)
		xyd.displaySpriteOnContainer(var_7_7, arg_7_0:nodeByName(var_0_0.IMG_CURRENCY2), true)
		arg_7_0:updateNum()
	end
end

return var_0_0
