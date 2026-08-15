local var_0_0 = class("SelectHeroGiftBagWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = 3
local var_0_4 = 260
local var_0_5 = 392
local var_0_6 = 1

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.id = arg_1_2.id
	arg_1_0.activityID = arg_1_2.activityID
	arg_1_0.currentIdx = 0
	arg_1_0.giftIDs = arg_1_2.giftIDs
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.heros = {}
	arg_1_0.heroItem = {}
	arg_1_0.heroCard = {}
	arg_1_0.isAnimation = false
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("text_mid"):setString(var_0_1:translation("CLICK_HERO_CARD"))

	for iter_3_0 = 1, var_0_3 do
		local var_3_0 = xyd.tables.gift:items(arg_3_0.giftIDs[iter_3_0])[1]
		local var_3_1 = xyd.tables.gift:itemNum(arg_3_0.giftIDs[iter_3_0])[1]
		local var_3_2 = xyd.tables.item:name(var_3_0)
		local var_3_3 = var_0_2.new()

		var_3_3:initUnCollected(var_3_0)
		table.insert(arg_3_0.heros, var_3_3)

		local var_3_4 = cc.p(arg_3_0:nodeByName("node_" .. iter_3_0):getPosition())
		local var_3_5 = display.newNode()

		var_3_5:setContentSize(var_0_4, var_0_5)
		var_3_5:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_5:addTo(arg_3_0:nodeByName("container"))
		var_3_5:setPosition(cc.p(var_3_4))

		local var_3_6 = xyd.getHeroCard(var_3_3)
		local var_3_7 = var_3_6:getContentSize()

		var_3_6:setScale(var_0_5 / var_3_7.height)
		var_3_6:addTo(var_3_5)
		var_3_6:setPosition(var_0_4 / 2, var_0_5 / 2)
		var_3_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_5:setTouchEnabled(true)

		arg_3_0.heroCard[iter_3_0] = var_3_5

		var_3_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				return true
			elseif arg_4_0.name == "ended" and not arg_3_0.isAnimation then
				arg_3_0:initHeroModel(var_3_3, var_3_4, iter_3_0)

				local var_4_0 = arg_3_0.currentIdx

				arg_3_0.currentIdx = iter_3_0

				arg_3_0:initAnimation(iter_3_0, var_4_0)
			end
		end)
		arg_3_0:nodeByName("btn_select_" .. iter_3_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_3_0.activitiesModel:getActivityReward2(arg_3_0.activityID, arg_3_0.id, iter_3_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						arg_3_0.selfPlayer:handleRewards(arg_6_1.awards)

						if arg_3_0.callback then
							arg_3_0.callback()
						end

						xyd.WindowManager.get():closeWindow(arg_3_0.name)
					end
				end)
			end
		end)
	end
end

function var_0_0.initHeroModel(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	if not arg_7_0.heroItem[arg_7_3] then
		local var_7_0 = arg_7_1:getName()
		local var_7_1 = arg_7_1:getDes()
		local var_7_2 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1071/hero_item.csb")

		var_7_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_2:setPosition(cc.p(arg_7_2.x - var_0_4 / 2, arg_7_2.y - var_0_5 / 2))
		var_7_2:addTo(arg_7_0:nodeByName("container"))

		local var_7_3 = var_7_2:getChildByName("container")
		local var_7_4 = cc.p(var_7_3:getChildByName("text_pos"):getPosition())
		local var_7_5 = {
			size = 22,
			color = cc.c3b(0, 0, 0),
			text = var_7_1,
			dimensions = cc.size(215, 0),
			x = var_7_4.x,
			y = var_7_4.y,
			align = cc.ui.TEXT_ALIGN_CENTER
		}
		local var_7_6 = xyd.AssetLoader.get():loadLabel(var_7_5)

		var_7_6:addTo(var_7_3)
		var_7_6:setAnchorPoint(cc.p(0.5, 0.5))
		var_7_3:getChildByName("text_name"):setString(var_7_0)

		local var_7_7 = var_7_3:getChildByName("hero_container")
		local var_7_8 = arg_7_1:getHeroModel()

		var_7_8:setScale(0.8)
		var_7_7:addChild(var_7_8)
		var_7_8:setPositionX(var_7_7:getContentSize().width / 2)

		arg_7_0.heroItem[arg_7_3] = var_7_3

		var_7_3:setVisible(false)

		local var_7_9 = cc.p(var_7_3:getPosition())
		local var_7_10 = display.newNode()

		var_7_10:setContentSize(var_7_3:getContentSize().width, var_7_3:getContentSize().height)
		var_7_10:setAnchorPoint(cc.p(0, 0))
		var_7_10:addTo(var_7_3)
		var_7_10:setPosition(0, 0)
		var_7_10:setTouchEnabled(true)
		var_7_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				return true
			elseif arg_8_0.name == "ended" and not arg_7_0.isAnimation then
				local var_8_0 = arg_7_0.currentIdx

				arg_7_0.currentIdx = 0

				arg_7_0:initAnimation(arg_7_3, var_8_0)
			end
		end)
	end
end

function var_0_0.initAnimation(arg_9_0, arg_9_1, arg_9_2)
	arg_9_0.isAnimation = true

	local function var_9_0()
		if arg_9_2 ~= 0 then
			arg_9_0.heroItem[arg_9_2]:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
				arg_9_0.heroItem[arg_9_2]:setVisible(false)
				arg_9_0.heroCard[arg_9_2]:setVisible(true)
				arg_9_0.heroCard[arg_9_2]:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
					arg_9_0.isAnimation = false
				end)))
			end)))
		end
	end

	local function var_9_1()
		arg_9_0.heroCard[arg_9_1]:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 0, 1), cc.CallFunc:create(function()
			arg_9_0.heroItem[arg_9_1]:setVisible(true)
			arg_9_0.heroItem[arg_9_1]:setScale(0, 1)
			arg_9_0.heroCard[arg_9_1]:setVisible(false)
			arg_9_0.heroItem[arg_9_1]:runAction(cc.Sequence:create(cc.ScaleTo:create(0.5, 1, 1), cc.CallFunc:create(function()
				if arg_9_2 == 0 then
					arg_9_0.isAnimation = false
				end
			end)))
		end)))
	end

	local var_9_2

	if arg_9_2 == arg_9_1 then
		var_9_2 = cc.Spawn:create({
			cc.CallFunc:create(var_9_0)
		})
	else
		var_9_2 = cc.Spawn:create({
			cc.CallFunc:create(var_9_1),
			cc.CallFunc:create(var_9_0)
		})
	end

	arg_9_0:runAction(var_9_2)
end

function var_0_0.didOpen(arg_16_0, arg_16_1)
	var_0_0.super:didOpen(arg_16_1)
	arg_16_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

return var_0_0
