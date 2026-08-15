local var_0_0 = class("SelectGiftBagWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 3

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.id = arg_1_2.id
	arg_1_0.activityID = arg_1_2.activityID
	arg_1_0.currentIdx = 1
	arg_1_0.giftIDs = arg_1_2.giftIDs
	arg_1_0.modelIDs = arg_1_2.modelIDs
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.scrollListener(arg_3_0, arg_3_1)
	if arg_3_1.name == "began" then
		arg_3_0.startClick_ = true
		arg_3_0.prevX_ = arg_3_1.x
	elseif arg_3_1.name == "moved" and 20 <= math.abs(arg_3_1.x - arg_3_0.prevX_) then
		arg_3_0.startClick_ = false
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0.models = {}
	arg_4_0.btns = {}
	arg_4_0.petList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_4_0:nodeByName("list"):getWidth(), arg_4_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_4_0:nodeByName("list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	arg_4_0.petList:setTouchSwallowEnabled(false)
	arg_4_0.petList:setDelegate(handler(arg_4_0, arg_4_0.petDelegate))
	arg_4_0:nodeByName("title_txt"):setString(var_0_1:translation("PET_GIFT_SELECT_TITLE"))
	arg_4_0.petList:reload()
	arg_4_0:setButtonClick()
	arg_4_0:setWalkState()
	arg_4_0:setBtnState()
end

function var_0_0.initHeroCell(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1063/select_gift/gift_item.csb")
	local var_5_1 = var_5_0:getChildByName("container"):getContentSize()

	var_5_0:setContentSize(var_5_1.width, var_5_1.height)
	arg_5_1:setContentSize(var_5_1.width, var_5_1.height)
	var_5_0:setPosition(cc.p(0, 0))
	arg_5_1:addChild(var_5_0)
	var_5_0:setName("layout")

	local var_5_2 = var_5_0:getChildByName("container")
	local var_5_3

	if arg_5_3 then
		var_5_2:getChildByName("bagbtn"):setBrightStyle(ccui.BrightStyle.highlight)
	else
		var_5_2:getChildByName("bagbtn"):setBrightStyle(ccui.BrightStyle.normal)
	end

	var_5_2:getChildByName("pet_container"):setTouchEnabled(false)
	var_5_2:getChildByName("pet_container"):setTouchSwallowEnabled(false)

	arg_5_0.models[arg_5_2] = xyd.HeroAnimation.new(nil, arg_5_0.modelIDs[arg_5_2], 1, {})

	arg_5_0.models[arg_5_2]:setTouchSwallowEnabled(false)
	arg_5_0.models[arg_5_2]:setTouchEnabled(true)
	arg_5_0.models[arg_5_2]:addTo(var_5_2:getChildByName("pet_container"))
	arg_5_0.models[arg_5_2]:setPositionX(var_5_2:getChildByName("pet_container"):getContentSize().width / 2)

	arg_5_0.btns[arg_5_2] = var_5_2:getChildByName("bagbtn")

	local var_5_4 = xyd.tables.gift:items(arg_5_0.giftIDs[arg_5_2])[1]
	local var_5_5 = xyd.tables.gift:itemNum(arg_5_0.giftIDs[arg_5_2])[1]
	local var_5_6 = xyd.tables.item:name(var_5_4)

	var_5_2:getChildByName("bag_name"):setString(var_5_6 .. "X" .. var_5_5)
	var_5_2:getChildByName("bagbtn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.startClick_ == true then
			arg_5_0.currentIdx = arg_5_2

			arg_5_0:setWalkState()
			arg_5_0:setBtnState()
		end

		if arg_6_1 == ccui.TouchEventType.ended and arg_5_0.startClick_ == false and arg_5_0.currentIdx == arg_5_2 then
			var_5_2:getChildByName("bagbtn"):setBrightStyle(ccui.BrightStyle.highlight)
		end
	end)
end

function var_0_0.petDelegate(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = #arg_7_0.modelIDs

	if cc.ui.UIListView.COUNT_TAG == arg_7_2 then
		return var_7_0
	elseif cc.ui.UIListView.CELL_TAG == arg_7_2 then
		local var_7_1
		local var_7_2
		local var_7_3
		local var_7_4 = arg_7_0.petList:dequeueItem()

		if not var_7_4 then
			var_7_4 = arg_7_0.petList:newItem()
		else
			var_7_4:removeAllChildren()
		end

		local var_7_5 = display.newNode()
		local var_7_6 = arg_7_3
		local var_7_7 = display.newNode()

		if arg_7_3 == arg_7_0.currentIdx then
			arg_7_0:initHeroCell(var_7_7, var_7_6, true)
		else
			arg_7_0:initHeroCell(var_7_7, var_7_6, false)
		end

		var_7_7:setAnchorPoint(cc.p(0, 0))
		var_7_7:pos(0, 0)
		var_7_5:addChild(var_7_7)
		var_7_7:setName("cell")

		var_7_5.heroID = var_7_7.heroID

		var_7_5:size(var_7_7:getWidth(), var_7_7:getHeight())
		var_7_4:setItemSize(var_7_5:getWidth(), var_7_7:getHeight())
		var_7_5:align(display.CENTER, var_7_4:getWidth() / 2, var_7_4:getHeight() / 2)
		var_7_4:addContent(var_7_5)

		return var_7_4
	end
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0

			if arg_8_0.activityID == xyd.Activities.PetBagBigSell or arg_8_0.activityID == xyd.Activities.PetGrowUpSell then
				var_9_0 = arg_8_0.giftIDs[arg_8_0.currentIdx]
			elseif arg_8_0.activityID == xyd.Activities.PetAndGirls then
				var_9_0 = arg_8_0.currentIdx
			end

			arg_8_0.activitiesModel:getActivityReward2(arg_8_0.activityID, arg_8_0.id, var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					arg_8_0.selfPlayer:handleRewards(arg_10_1.awards)

					if arg_8_0.callback then
						arg_8_0.callback()
					end

					xyd.WindowManager.get():closeWindow(arg_8_0.name)
				end
			end)
		end
	end)
end

function var_0_0.setWalkState(arg_11_0)
	for iter_11_0 = 1, #arg_11_0.models do
		if arg_11_0.models[iter_11_0] and arg_11_0.currentIdx == iter_11_0 then
			arg_11_0.models[iter_11_0]:walk(true)
		else
			arg_11_0.models[iter_11_0]:walk(false)
			arg_11_0.models[iter_11_0]:idle()
		end
	end
end

function var_0_0.setBtnState(arg_12_0)
	for iter_12_0 = 1, #arg_12_0.btns do
		if tolua.isnull(arg_12_0) or tolua.isnull(arg_12_0.btns[iter_12_0]) then
			return
		end

		if iter_12_0 == arg_12_0.currentIdx then
			arg_12_0.btns[iter_12_0]:setBrightStyle(ccui.BrightStyle.highlight)
		else
			arg_12_0.btns[iter_12_0]:setBrightStyle(ccui.BrightStyle.normal)
		end
	end
end

function var_0_0.didOpen(arg_13_0, arg_13_1)
	var_0_0.super:didOpen(arg_13_1)
	arg_13_0:addBlockLayer(cc.c4b(0, 0, 0, 225), true)
end

return var_0_0
