local var_0_0 = class("StarBonusTips", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	if arg_1_2.bonusID then
		arg_1_0.bonusID = arg_1_2.bonusID
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.bg = arg_2_0:nodeByName("backgroud")

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_4_0)
	local var_4_0, var_4_1 = arg_4_0:nodeByName("star_img"):getPosition()

	arg_4_0:nodeByName("reach_txt"):setString(var_0_1:translation("STAR_BONUS_DES_1"))
	arg_4_0:nodeByName("Text_1_Copy"):setString(var_0_1:translation("STAR_BONUS_DES_2"))
	arg_4_0:nodeByName("reward_txt"):setString(var_0_1:translation("STAR_BONUS_DES_3"))
	arg_4_0:nodeByName("reward_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	arg_4_0.starNum = xyd.tables.campaignBonus:starNum(arg_4_0.bonusID)
	arg_4_0.starLabel = xyd.AssetLoader.get():loadLabel(nil, "bonus")

	arg_4_0.starLabel:setString(tostring(arg_4_0.starNum))
	arg_4_0.starLabel:addTo(arg_4_0.bg)
	arg_4_0.starLabel:setPosition(215, var_4_1 + 5)
	arg_4_0.starLabel:setAnchorPoint(cc.p(0.5, 0.5))

	arg_4_0.allItems = {}
	arg_4_0.diamond = xyd.tables.campaignBonus:awardCrystal(arg_4_0.bonusID)

	if arg_4_0.diamond > 0 then
		table.insert(arg_4_0.allItems, {
			item = "-1",
			num = arg_4_0.diamond
		})
	end

	arg_4_0.coin = xyd.tables.campaignBonus:awardMana(arg_4_0.bonusID)

	if arg_4_0.coin > 0 then
		table.insert(arg_4_0.allItems, {
			item = "-2",
			num = arg_4_0.coin
		})
	end

	arg_4_0.awardItems = xyd.tables.campaignBonus:awardID(arg_4_0.bonusID)
	arg_4_0.awardNums = xyd.tables.campaignBonus:awardNum(arg_4_0.bonusID)

	for iter_4_0 = 1, #arg_4_0.awardItems do
		table.insert(arg_4_0.allItems, {
			item = arg_4_0.awardItems[iter_4_0],
			num = arg_4_0.awardNums[iter_4_0]
		})
	end

	local var_4_2 = math.ceil(#arg_4_0.allItems / 3)

	for iter_4_1 = 1, var_4_2 do
		for iter_4_2 = 1, 3 do
			local var_4_3 = (iter_4_1 - 1) * 3 + iter_4_2
			local var_4_4

			if var_4_3 <= #arg_4_0.allItems then
				local var_4_5 = xyd.AssetLoader.get():loadLabel({
					size = 28,
					color = cc.c3b(68, 69, 77)
				})

				if arg_4_0.allItems[var_4_3].item == "-1" then
					var_4_4 = xyd.AssetLoader.get():loadSprite("images/zuanshi.png")

					var_4_4:setScale(0.8)
					var_4_5:setString("X" .. arg_4_0.allItems[var_4_3].num)
				elseif arg_4_0.allItems[var_4_3].item == "-2" then
					var_4_4 = xyd.AssetLoader.get():loadSprite("images/jinbi.png")

					var_4_4:setScale(0.7)
					var_4_5:setString("X" .. arg_4_0.allItems[var_4_3].num)
				else
					var_4_4 = display.newNode()

					var_4_4:setContentSize(50, 50)
					xyd.setItemBorder(var_4_4, arg_4_0.allItems[var_4_3].item)
					var_4_5:setString("X" .. arg_4_0.allItems[var_4_3].num)
				end

				var_4_4:setContentSize(50, 50)
				var_4_4:addTo(arg_4_0.bg)
				var_4_4:setAnchorPoint(cc.p(0, 0.5))
				var_4_5:addTo(arg_4_0.bg)
				var_4_5:setAnchorPoint(cc.p(0, 0.5))

				if tonumber(arg_4_0.allItems[var_4_3].item) < 0 then
					var_4_4:setPosition(var_4_0 - 45 + (iter_4_2 - 1) * 125, var_4_1 - 68 + (iter_4_1 - 1) * -70)

					local var_4_6, var_4_7 = var_4_4:getPosition()

					var_4_5:setPosition(var_4_6 + 55, var_4_1 - 65 + (iter_4_1 - 1) * -70)
				else
					var_4_4:setPosition(var_4_0 - 39 + (iter_4_2 - 1) * 125, var_4_1 - 65 + (iter_4_1 - 1) * -70)

					local var_4_8, var_4_9 = var_4_4:getPosition()

					var_4_5:setPosition(var_4_8 + 54, var_4_9)
				end
			end
		end
	end

	local var_4_10 = arg_4_0:nodeByName("bg_img"):getHeight()

	arg_4_0:nodeByName("bg_img"):height(var_4_10 + (var_4_2 - 1) * 55)
end

return var_0_0
