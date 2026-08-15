local var_0_0 = class("FifthAnniPartyBackpackWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item
local var_0_4 = xyd.tables.fifthAnniPartyGift
local var_0_5 = xyd.tables.misc
local var_0_6 = xyd.tables.gift
local var_0_7 = 4
local var_0_8 = 108

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.FIFTH_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.collectionStatus = arg_1_2.collect_status
	arg_1_0.isAward = arg_1_2.is_award
	arg_1_0.items = {}

	for iter_1_0 = 1, var_0_4:all() do
		table.insert(arg_1_0.items, {
			item_id = var_0_4:itemId(iter_1_0)
		})
	end
end

function var_0_0.willOpen(arg_2_0)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_tips"):setString(var_0_2:translation("FIFTH_ANNI_PARTY_TEXT_35"))
	arg_3_0:nodeByName("txt_progress"):setString(var_0_2:translation("FIFTH_ANNI_PARTY_TEXT_36"))
	arg_3_0:nodeByName("txt_get"):setString(var_0_2:translation("FIFTH_ANNI_PARTY_TEXT_37"))
	arg_3_0:nodeByName("txt_count"):enableOutline(cc.c4b(94, 54, 29, 255), 3)
	arg_3_0:nodeByName("txt_get"):enableOutline(cc.c4b(130, 73, 36, 255), 2)
	arg_3_0:nodeByName("txt_tips"):getVirtualRenderer():setLineHeight(30)

	local var_3_0 = arg_3_0:nodeByName("list"):getContentSize()
	local var_3_1 = 0
	local var_3_2 = var_3_0.height

	for iter_3_0 = 1, math.ceil(#arg_3_0.items / var_0_7) do
		for iter_3_1 = 1, var_0_7 do
			local var_3_3 = (iter_3_0 - 1) * var_0_7 + iter_3_1

			if not arg_3_0.items[var_3_3] then
				return
			end

			local var_3_4 = display.newNode()
			local var_3_5 = arg_3_0.backpack:getItemNumByID(arg_3_0.items[var_3_3].item_id)

			var_3_4:setContentSize(var_0_8, var_0_8)
			var_3_4:setAnchorPoint(0, 1)
			var_3_4:setPosition(var_3_1, var_3_2)

			if arg_3_0.collectionStatus[var_3_3] == 0 then
				xyd.setItemBorder(var_3_4, arg_3_0.items[var_3_3].item_id)
				xyd.GrayNode(var_3_4)
			else
				xyd.setItemBorder(var_3_4, arg_3_0.items[var_3_3].item_id, nil, nil, var_3_5)
			end

			arg_3_0:nodeByName("list"):addChild(var_3_4)

			local var_3_6 = xyd.createLabel(22, cc.c3b(109, 73, 61))

			var_3_6:setAnchorPoint(0.5, 1)
			var_3_6:setPosition(var_3_1 + var_0_8 / 2, var_3_2 - var_0_8 - 16)
			var_3_6:setString(var_0_3:name(arg_3_0.items[var_3_3].item_id))
			arg_3_0:nodeByName("list"):addChild(var_3_6)
			var_3_4:setTouchEnabled(true)
			var_3_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
				if arg_4_0.name == "began" then
					return true
				elseif arg_4_0.name == "ended" then
					arg_3_0:nodeByName("txt_tips"):setString(var_0_3:desc1(arg_3_0.items[var_3_3].item_id))
				end
			end)

			var_3_1 = var_3_1 + var_0_8 + 45
		end

		var_3_1 = 0
		var_3_2 = var_3_2 - 178
	end

	local var_3_7 = 0

	for iter_3_2, iter_3_3 in ipairs(arg_3_0.collectionStatus) do
		if iter_3_3 ~= 0 then
			var_3_7 = var_3_7 + 1
		end
	end

	arg_3_0:nodeByName("txt_count"):setString(var_3_7 .. "/" .. #arg_3_0.items)
	arg_3_0:nodeByName("bar"):setPercent(100 * var_3_7 / #arg_3_0.items)

	local var_3_8 = var_0_5:getValue("fifth_anni_party_collection_reward")
	local var_3_9 = var_0_6:items(var_3_8)[1]

	xyd.setItemAndAddTips(arg_3_0:nodeByName("item"), var_3_9)

	if var_3_7 >= #arg_3_0.items and arg_3_0.isAward == 0 then
		arg_3_0:nodeByName("red_point"):setVisible(true)
		arg_3_0:nodeByName("item"):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_3_0.model:partyGetCollectionAward(nil, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_3_0.selfPlayer:handleRewards(arg_6_1.awards)
						arg_3_0:nodeByName("red_point"):setVisible(false)
						arg_3_0:nodeByName("item"):setTouchEnabled(false)
					end
				end)
			end
		end)
	end
end

function var_0_0.addTopSidebar(arg_7_0)
	local var_7_0 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(arg_7_0.colorMode)
	})

	var_7_0:addTo(arg_7_0:nodeByName("bg_top"))
	var_7_0:setAnchorPoint(0.5, 0.5)
	var_7_0:setPosition(arg_7_0:nodeByName("pos_btn_return"):getPosition())
	var_7_0:addTouchEvent(function(arg_8_0)
		if arg_8_0.name == "ended" then
			xyd.playCloseSound()
			arg_7_0:close()
		end
	end)
	arg_7_0:nodeByName("txt_title"):setString(xyd.tables.window:title(arg_7_0.name))
end

return var_0_0
