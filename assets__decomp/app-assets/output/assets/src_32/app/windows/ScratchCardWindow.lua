local var_0_0 = class("ScratchCardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.cardID = arg_1_2.card_id
	arg_1_0.award = arg_1_2.awards or {}
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layout()
	arg_3_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.didClose(arg_4_0, arg_4_1)
	var_0_0.super:didClose(arg_4_1)

	if arg_4_0.callback then
		arg_4_0.callback()
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("desc"):setString(var_0_1:translation("SCRATCH_DESC"))

	local var_5_0 = cc.Director:getInstance():getWinSize()
	local var_5_1 = arg_5_0:nodeByName("container"):convertToWorldSpace(cc.p(arg_5_0:nodeByName("card_container"):getPosition()))
	local var_5_2 = arg_5_0:nodeByName("card_container")

	arg_5_0:setCardInObverseSide(var_5_2, arg_5_0.cardID)

	local var_5_3 = 30

	erase = cc.DrawNode:create()

	erase:drawDot(cc.p(0, 0), var_5_3, cc.c4f(0, 0, 0, 0))
	erase:retain()

	renderTex = cc.RenderTexture:create(var_5_0.width, var_5_0.height)

	renderTex:addTo(arg_5_0:nodeByName("container"), 1000)
	renderTex:setAnchorPoint(cc.p(0.5, 0.5))
	renderTex:setPosition(arg_5_0:nodeByName("card_container"):getPosition())
	renderTex:retain()
	renderTex:setTouchSwallowEnabled(false)

	local var_5_4 = xyd.AssetLoader.get():loadSprite("windows/activities/1055/scratch_card_wnd/coating_bg.png")

	var_5_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_5_4:setScale(2.4)
	var_5_4:setPosition(var_5_0.width / 2, var_5_0.height / 2)
	renderTex:begin()
	var_5_4:visit()
	renderTex:endToLua()

	local var_5_5 = display.newColorLayer(cc.c4b(0, 0, 0, 0))
	local var_5_6 = arg_5_0:nodeByName("container"):convertToNodeSpace(cc.p(0, 0))

	var_5_5:setContentSize(var_5_0.width, var_5_0.height)
	var_5_5:setTouchEnabled(true)
	var_5_5:addTo(arg_5_0:nodeByName("container"))
	var_5_5:setPosition(var_5_6)
	var_5_5:setLocalZOrder(100)

	local var_5_7 = var_5_1.x - var_5_4:getContentSize().width * 2.4 / 2
	local var_5_8 = var_5_1.x + var_5_4:getContentSize().width * 2.4 / 2
	local var_5_9 = var_5_1.y + var_5_4:getContentSize().height * 2.4 / 2
	local var_5_10 = var_5_1.y - var_5_4:getContentSize().height * 2.4 / 2
	local var_5_11 = var_5_4:getContentSize().width * 2.4 * var_5_4:getContentSize().height * 2.4
	local var_5_12 = var_5_0.width
	local var_5_13 = 0
	local var_5_14 = var_5_0.height
	local var_5_15 = 0
	local var_5_16 = 0

	var_5_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			return true
		elseif arg_6_0.name == "moved" then
			local var_6_0 = arg_6_0.x
			local var_6_1 = arg_6_0.y

			erase:setPosition(arg_6_0.x, arg_6_0.y)
			erase:setBlendFunc(gl.ONE, gl.ZERO)
			renderTex:begin()
			erase:visit()
			renderTex:endToLua()

			if var_6_0 >= var_5_7 and var_6_0 <= var_5_8 and var_6_1 >= var_5_10 and var_6_1 <= var_5_9 then
				if var_6_0 > var_5_13 then
					var_5_13 = var_6_0
				end

				if var_6_0 < var_5_12 then
					var_5_12 = var_6_0
				end

				if var_6_1 > var_5_15 then
					var_5_15 = var_6_1
				end

				if var_6_1 < var_5_14 then
					var_5_14 = var_6_1
				end
			end

			if var_5_15 > 0 and var_5_14 > 0 and var_5_13 > 0 and var_5_12 > 0 and var_5_15 > var_5_14 and var_5_13 > var_5_12 then
				var_5_16 = (var_5_15 - var_5_14) * (var_5_13 - var_5_12)

				if var_5_16 / var_5_11 > 0.5 then
					if xyd.tables.activityScratchCard:isMultiplierCard(arg_5_0.cardID) then
						local var_6_2 = xyd.tables.activityScratchCard:getMultiplier(arg_5_0.cardID)
						local var_6_3 = {
							message = string.format(var_0_1:translation("MORE_CARD_TIPS"), var_6_2)
						}

						var_6_3.delay = 0.95
						var_6_3.textSize = 24

						xyd.WindowManager.get():openWindow("toast", var_6_3)
					else
						arg_5_0:showAwards()
					end

					renderTex:setVisible(false)
					renderTex:removeSelf()

					if arg_5_0.layerListener then
						local function var_6_4(arg_7_0, arg_7_1)
							local var_7_0 = xyd.tables.sound:getSound("ui_close_window")

							audio.playSound(var_7_0, false)
							xyd.WindowManager.get():closeWindow(arg_5_0.name)

							return true
						end

						arg_5_0.layerListener:registerScriptHandler(var_6_4, cc.Handler.EVENT_TOUCH_BEGAN)
					end

					arg_5_0.canClose = true

					var_5_5:setTouchEnabled(false)
					var_5_5:setTouchSwallowEnabled(false)
					var_5_5:removeSelf()
				end
			end
		end
	end)
end

function var_0_0.handleRewards(arg_8_0, arg_8_1)
	local var_8_0 = ""

	for iter_8_0, iter_8_1 in pairs(arg_8_1) do
		if iter_8_1.mana then
			local var_8_1 = var_0_1:translation("COIN") .. "X" .. iter_8_1.item_num

			if var_8_0 ~= "" then
				var_8_0 = var_8_0 .. "," .. var_8_1
			else
				var_8_0 = var_8_0 .. var_8_1
			end
		elseif iter_8_1.crystal then
			local var_8_2 = var_0_1:translation("CRYSTAL") .. "X" .. iter_8_1.item_num

			if var_8_0 ~= "" then
				var_8_0 = var_8_0 .. "," .. var_8_2
			else
				var_8_0 = var_8_0 .. var_8_2
			end
		elseif iter_8_1.lucky_coin then
			local var_8_3 = var_0_1:translation("LUCKY_COIN") .. "X" .. iter_8_1.item_num

			if var_8_0 ~= "" then
				var_8_0 = var_8_0 .. "," .. var_8_3
			else
				var_8_0 = var_8_0 .. var_8_3
			end
		else
			local var_8_4 = xyd.tables.item:name(tonumber(iter_8_1.table_id)) .. "X" .. iter_8_1.item_num

			if var_8_0 ~= "" then
				var_8_0 = var_8_0 .. "," .. var_8_4
			else
				var_8_0 = var_8_0 .. var_8_4
			end

			arg_8_0.selfPlayer:getBackpack():addItemsByID(tonumber(iter_8_1.table_id), tonumber(iter_8_1.item_num))
		end
	end

	local var_8_5 = {
		message = var_8_0
	}

	var_8_5.delay = 0.95
	var_8_5.textSize = 24

	xyd.WindowManager.get():openWindow("toast", var_8_5)
end

function var_0_0.showAwards(arg_9_0)
	local var_9_0

	for iter_9_0, iter_9_1 in ipairs(arg_9_0.award) do
		if iter_9_1.is_partner == true then
			var_9_0 = iter_9_1
			iter_9_1.item_num = 1
		elseif iter_9_1.to_stone == true then
			var_9_0 = iter_9_1
		end
	end

	if var_9_0 then
		local var_9_1 = {}

		if var_9_0.is_partner then
			local var_9_2 = var_0_3.new()

			var_9_2:populate(var_9_0)
			arg_9_0.selfPlayer:addHero(var_9_2)

			local var_9_3 = {
				toStone = false,
				partnerID = var_9_0.table_id
			}
			local var_9_4 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_9_3)

			cc.EventProxy.new(var_9_4, var_9_4):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				arg_9_0:handleRewards(arg_9_0.award)
			end)
		elseif var_9_0.to_stone then
			local var_9_5 = {
				partnerID = xyd.tables.item:heroID(var_9_0.table_id),
				toStone = tonumber(var_9_0.item_num)
			}
			local var_9_6 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_9_5)

			cc.EventProxy.new(var_9_6, var_9_6):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
				arg_9_0:handleRewards(arg_9_0.award)
			end)
		end
	else
		arg_9_0:handleRewards(arg_9_0.award)
	end
end

function var_0_0.setCardInObverseSide(arg_12_0, arg_12_1, arg_12_2)
	local var_12_0 = display.newNode()

	var_12_0:setContentSize(arg_12_1:getHeight(), arg_12_1:getHeight())

	local var_12_1 = xyd.tables.activityScratchCard:getGiftID(arg_12_2)

	if xyd.tables.activityScratchCard:isMultiplierCard(arg_12_2) then
		local var_12_2 = xyd.tables.activityScratchCard:getIcon(arg_12_2)

		xyd.setSpriteBorder(var_12_0, var_12_2, 1)
	elseif xyd.tables.gift:crystal(var_12_1) and xyd.tables.gift:crystal(var_12_1) > 0 then
		xyd.setItemBorder(var_12_0, -1, false, false, xyd.tables.gift:crystal(var_12_1))
	elseif xyd.tables.gift:mana(var_12_1) and xyd.tables.gift:mana(var_12_1) > 0 then
		xyd.setItemBorder(var_12_0, -2, false, false, xyd.tables.gift:mana(var_12_1))
	elseif xyd.tables.gift:luckyCoin(var_12_1) and xyd.tables.gift:luckyCoin(var_12_1) > 0 then
		xyd.setItemBorder(var_12_0, -5, false, false, xyd.tables.gift:luckyCoin(var_12_1))
	else
		local var_12_3 = xyd.tables.gift:items(var_12_1)[1]
		local var_12_4 = xyd.tables.gift:itemNum(var_12_1)[1]

		xyd.setItemBorder(var_12_0, var_12_3, false, false, var_12_4)
	end

	var_12_0:addTo(arg_12_1)
	var_12_0:setName("scratchCard")
	var_12_0:setPosition(0, 0)
	var_12_0:setAnchorPoint(cc.p(0, 0))
	arg_12_1:setScale(2.4)
end

return var_0_0
