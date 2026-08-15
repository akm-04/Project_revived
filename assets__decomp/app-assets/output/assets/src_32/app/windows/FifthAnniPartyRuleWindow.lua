local var_0_0 = class("FifthAnniPartyRuleWindow", import("app.windows.NewTextRuleWindow"))
local var_0_1 = xyd.tables.fifthAnniPartyRank
local var_0_2 = xyd.tables.gift

var_0_0.TITLE = "title_text"
var_0_0.DETAIL_CONTAINER = "detail_container"

local var_0_3 = xyd.tables.translation
local var_0_4 = xyd.tables.ruleStyle
local var_0_5 = 814
local var_0_6 = 547

function var_0_0.initRule(arg_1_0)
	local var_1_0

	if not arg_1_0.split then
		var_1_0 = xyd.split(var_0_3:translation(arg_1_0.rule), "\n")
	else
		var_1_0 = xyd.split(var_0_3:translation(arg_1_0.rule), arg_1_0.split)
	end

	for iter_1_0 = 1, #var_1_0 do
		local var_1_1 = display.newNode()
		local var_1_2 = arg_1_0.list:newItem()
		local var_1_3 = display.newNode()
		local var_1_4 = {
			size = 22,
			color = xyd.convertHex2RGB(var_0_4:textColor(arg_1_0.style)),
			dimensions = cc.size(708, 0),
			text = var_1_0[iter_1_0]
		}
		local var_1_5 = xyd.AssetLoader.get():loadLabel(var_1_4)

		var_1_5:addTo(var_1_3)
		var_1_5:setAnchorPoint(cc.p(0, 0))
		var_1_5:setPosition(cc.p(0, 0))

		local var_1_6 = var_1_5:getContentSize().height

		var_1_3:setContentSize(708, var_1_6)
		var_1_3:addTo(var_1_1)
		var_1_1:setContentSize(708, var_1_6 + 20)
		var_1_2:addContent(var_1_1)
		var_1_2:setItemSize(708, var_1_6 + 20)
		arg_1_0.list:addItem(var_1_2)
	end

	arg_1_0:addRewardItem()
	arg_1_0.list:reload()
end

function var_0_0.addRewardItem(arg_2_0)
	local var_2_0 = arg_2_0.awardTable or var_0_1
	local var_2_1 = arg_2_0.list:newItem()
	local var_2_2 = {
		size = 24,
		color = cc.c3b(210, 84, 16)
	}
	local var_2_3 = xyd.AssetLoader.get():loadLabel(var_2_2)

	var_2_3:setMaxLineWidth(708)
	var_2_3:setLineHeight(49)
	var_2_3:setString(var_0_3:translation("RANK_AWARD"))
	var_2_1:addContent(var_2_3)
	var_2_1:setItemSize(708, var_2_3:getContentSize().height + 20)
	arg_2_0.list:addItem(var_2_1)

	local var_2_4 = var_2_0:all()

	for iter_2_0 = 1, var_2_4 do
		local var_2_5 = arg_2_0.list:newItem()
		local var_2_6 = display.newNode()

		var_2_6:setContentSize(714, 80)

		local var_2_7 = 0
		local var_2_8 = var_2_0:range(iter_2_0)
		local var_2_9 = {
			size = 24,
			color = cc.c3b(54, 52, 55)
		}
		local var_2_10 = xyd.AssetLoader.get():loadLabel(var_2_9)

		if var_2_8[1] == var_2_8[2] then
			local var_2_11 = string.format(var_0_3:translation("ARENA_RULE_ITEM_TITLE_1"), var_2_8[1])

			var_2_10:setString(var_2_11)
		else
			local var_2_12 = string.format(var_0_3:translation("ARENA_RULE_ITEM_TITLE_2"), var_2_8[1], var_2_8[2])

			var_2_10:setString(var_2_12)
		end

		var_2_10:addTo(var_2_6)
		var_2_10:setAnchorPoint(cc.p(0, 0.5))
		var_2_10:setPosition(var_2_7, 40)

		local var_2_13 = var_2_7 + 220
		local var_2_14 = var_2_0:gift(iter_2_0)
		local var_2_15 = var_0_2:crystal(var_2_14)

		if var_2_15 > 0 then
			local var_2_16 = "images/icon/eco/icon_crystal.png"
			local var_2_17 = xyd.AssetLoader.get():loadSprite(var_2_16)

			var_2_17:setScale(0.8)
			var_2_17:addTo(var_2_6)
			var_2_17:setAnchorPoint(cc.p(0.5, 0.5))
			var_2_17:setPosition(var_2_13, 40)

			local var_2_18 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_2_19 = xyd.AssetLoader.get():loadLabel(var_2_18)

			var_2_19:setString("x" .. var_2_15)
			var_2_19:addTo(var_2_6)
			var_2_19:setAnchorPoint(cc.p(0, 0.5))
			var_2_19:setPosition(var_2_13 + 20, 40)

			var_2_13 = var_2_13 + 150
		end

		local var_2_20 = var_0_2:items(var_2_14)
		local var_2_21 = var_0_2:itemNum(var_2_14)

		for iter_2_1 = 1, #var_2_20 do
			local var_2_22 = display.newNode()

			var_2_22:setContentSize(60, 60)
			xyd.setItemAndAddTips(var_2_22, var_2_20[iter_2_1])
			var_2_22:addTo(var_2_6)
			var_2_22:setAnchorPoint(cc.p(0.5, 0.5))
			var_2_22:setPosition(var_2_13, 40)

			var_2_13 = var_2_13 + 40

			local var_2_23 = {
				size = 24,
				color = cc.c3b(54, 52, 55)
			}
			local var_2_24 = xyd.AssetLoader.get():loadLabel(var_2_23)

			var_2_24:setString("x" .. var_2_21[iter_2_1])
			var_2_24:addTo(var_2_6)
			var_2_24:setAnchorPoint(cc.p(0, 0.5))
			var_2_24:setPosition(var_2_13, 40)

			var_2_13 = var_2_13 + 90
		end

		local var_2_25 = var_2_0:titleId(iter_2_0)

		if var_2_25 > 0 then
			local var_2_26 = display.newNode()

			var_2_26:setContentSize(60, 60)
			xyd.setPlayerTitle(var_2_26, {
				unique_id = 0,
				title_id = var_2_25
			})
			var_2_26:addTo(var_2_6)
			var_2_26:setAnchorPoint(cc.p(0.5, 0.5))
			var_2_26:setPosition(var_2_13, 40)
		end

		if var_2_0.bubbleId then
			local var_2_27 = var_2_0:bubbleId(iter_2_0)

			if var_2_27 > 0 then
				local var_2_28 = display.newNode()
				local var_2_29 = xyd.tables.chatBubble:capInsets(var_2_27)
				local var_2_30 = {
					41,
					-37
				}
				local var_2_31 = {
					37,
					25,
					37,
					24
				}
				local var_2_32 = cc.size(200 + var_2_31[1] + var_2_31[3], 60 + var_2_31[2] + var_2_31[4])
				local var_2_33 = xyd.SpriteLoader.new("images/bubble/arrow/" .. var_2_27 .. ".png", nil, nil, xyd.DefaultImageType.BUBBLE_ARROW)
				local var_2_34 = xyd.SpriteLoader.new("images/bubble/bg/" .. var_2_27 .. ".png", cc.rect(var_2_29[1], var_2_29[2], var_2_29[3], var_2_29[4]), {
					size = var_2_32
				}, xyd.DefaultImageType.BUBBLE_BG)

				var_2_34:setAnchorPoint(0, 0)
				var_2_34:setPosition(-var_2_31[1], -var_2_31[2])
				var_2_33:setAnchorPoint(1, 1)
				var_2_33:setPosition(var_2_30[1] - var_2_31[1], 60 + var_2_31[4] + var_2_30[2])
				var_2_28:addChild(var_2_34)
				var_2_28:addChild(var_2_33)
				var_2_28:addTo(var_2_6)
				var_2_28:setAnchorPoint(cc.p(0.5, 0.5))
				var_2_28:setPosition(var_2_13, 10)

				local var_2_35 = {
					y = 30,
					size = 22,
					x = 100,
					color = cc.c3b(96, 99, 131),
					text = var_0_3:translation("CHAT_BUBBLE_TEXT_4")
				}
				local var_2_36 = xyd.AssetLoader.get():loadLabel(var_2_35)

				var_2_36:setAnchorPoint(0.5, 0.5)
				var_2_28:addChild(var_2_36)
			end
		end

		var_2_5:addContent(var_2_6)
		var_2_5:setItemSize(714, 80)
		arg_2_0.list:addItem(var_2_5)
	end
end

return var_0_0
