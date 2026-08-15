local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activityFusionReward
local var_0_3 = xyd.tables.activityFusion
local var_0_4 = xyd.tables.activityFusionMaterial
local var_0_5 = import("app.common.ui.SpineEffect")
local var_0_6 = "skeletons/ui_effect/star_treasure_effect/yun"
local var_0_7 = import("framework.scheduler")
local var_0_8 = 80
local var_0_9 = 60
local var_0_10 = 30
local var_0_11 = 1
local var_0_12 = 3
local var_0_13 = {
	OPEN = 1,
	HAVE_OVER = -2,
	NOT_OPEN = -1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.maxLev = #var_0_2:ids()
	arg_1_0.giftIsAnimation = nil
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.parent:removeAllChildren()

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(-10, -10)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("mission_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0):onScroll(handler(arg_3_0, arg_3_0.scrollListener)):setTouchType(true)

	arg_3_0.list:setTouchSwallowEnabled(true)
	arg_3_0.list:setBounceable(false)
	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))

	arg_3_0.light = xyd.AssetLoader.get():loadSprite("windows/activities/1076/bg_light.png")

	arg_3_0.light:addTo(arg_3_0.container, -1)
	arg_3_0.light:setVisible(false)
	arg_3_0:initProgress()
	arg_3_0:updateLoadingbar()
	arg_3_0:updateJinduShow()
	arg_3_0:updateItemShow()
	arg_3_0.list:reload()
	arg_3_0.container:getChildByName("btn_rule"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			local var_4_0 = {
				title_name = "ACTIVITY_FUSION_RULE_TITLE",
				rule = "ACTIVITY_FUSION_RULE_TEXT"
			}

			xyd.WindowManager.get():openWindow("new_text_rule", var_4_0)
		end
	end)
	arg_3_0.container:getChildByName("btn_server_award"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_3_0.container:getChildByName("btn_server_award"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0.container:getChildByName("btn_server_award"):setScale(1)

			local var_5_0 = {
				activity_id = xyd.Activities.FUSION
			}

			xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES):loadSingleActivity(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("halloween_award", arg_6_1)
				end
			end)
		end
	end)
	arg_3_0.container:getChildByName("dialog_txt"):setString(var_0_1:translation("ACTIVITY_FUSION_AWARD_TIP"))
end

function var_0_0.initProgress(arg_7_0)
	local function var_7_0(arg_8_0, arg_8_1)
		local var_8_0 = xyd.tables.gift:items(arg_8_1)
		local var_8_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary4th/story_map/map/gift_tips.csb")

		var_8_1:getChildByName("container"):setContentSize(160, 60 * #var_8_0 + 70)

		for iter_8_0, iter_8_1 in ipairs(var_8_0) do
			local var_8_2 = display.newNode()

			var_8_2:setContentSize(cc.size(60, 60))
			var_8_2:setAnchorPoint(cc.p(0, 0))
			xyd.setItemBorder(var_8_2, iter_8_1)
			var_8_2:addTo(var_8_1:getChildByName("container"))
			var_8_2:setPosition(cc.p(40, 70 * iter_8_0 - 40))

			local var_8_3 = {
				size = 20,
				color = cc.c3b(255, 255, 255)
			}
			local var_8_4 = xyd.AssetLoader.get():loadLabel(var_8_3)

			var_8_4:setMaxLineWidth(70)
			var_8_4:setLineHeight(49)
			var_8_4:setString("x " .. xyd.tables.gift:itemNum(arg_8_1)[iter_8_0])
			var_8_4:addTo(var_8_1:getChildByName("container"))
			var_8_4:setPosition(cc.p(110, 70 * iter_8_0 - 25))
		end

		return var_8_1
	end

	local var_7_1 = arg_7_0.activity.details.award_count

	arg_7_0.nodeTips = {}

	for iter_7_0 = 1, arg_7_0.maxLev do
		local var_7_2 = var_0_2:gift(iter_7_0)

		arg_7_0.nodeTips[iter_7_0] = display.newNode()

		arg_7_0.nodeTips[iter_7_0]:setContentSize(74, 63)
		arg_7_0.nodeTips[iter_7_0]:setAnchorPoint(cc.p(0.5, 0.5))

		local var_7_3, var_7_4 = arg_7_0.container:getChildByName("btn_" .. iter_7_0):getPosition()

		arg_7_0.nodeTips[iter_7_0]:setPosition(cc.p(var_7_3, var_7_4))
		arg_7_0.nodeTips[iter_7_0]:addTo(arg_7_0.container)

		local var_7_5 = var_7_0(arg_7_0.nodeTips[iter_7_0], var_7_2)

		var_7_5:addTo(arg_7_0.container)
		var_7_5:setPosition(cc.p(var_7_3 - 80, var_7_4 + 20))
		var_7_5:setVisible(false)
		arg_7_0.nodeTips[iter_7_0]:setTouchEnabled(true)
		arg_7_0.nodeTips[iter_7_0]:setTouchSwallowEnabled(false)
		arg_7_0.nodeTips[iter_7_0]:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
			if arg_9_0.name == "began" then
				var_7_5:setVisible(true)

				return true
			elseif arg_9_0.name == "ended" then
				var_7_5:setVisible(false)
				var_7_5:setTouchSwallowEnabled(true)
			end
		end)

		if iter_7_0 <= var_7_1 then
			arg_7_0.container:getChildByName("btn_" .. iter_7_0):setBright(false)
		end

		arg_7_0.nodeTips[iter_7_0]:setVisible(false)

		if iter_7_0 >= var_7_1 + 1 and iter_7_0 ~= arg_7_0.maxLev then
			arg_7_0.nodeTips[iter_7_0]:setVisible(true)
		end
	end
end

function var_0_0.updateLoadingbar(arg_10_0)
	local var_10_0 = var_0_2:ids()
	local var_10_1 = var_0_2:elementReq(#var_10_0)
	local var_10_2 = arg_10_0.activity.details.element_num
	local var_10_3 = math.min(math.floor(100 * var_10_2 / var_10_1), 100)

	arg_10_0.container:getChildByName("loading_bar"):setPercent(var_10_3)
	arg_10_0:checkAwardIsGet()
end

function var_0_0.getActivityReward2(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0.activitiesModel:getActivityReward2(arg_11_0.activity.table_id, arg_11_1 + 1, 1, function(arg_12_0, arg_12_1)
		if arg_12_0 == xyd.error.OK then
			arg_11_0.activity.details.award_count = arg_11_1 + 1

			arg_11_0.player:handleRewards(arg_12_1.awards, arg_11_2)
		end
	end)
end

function var_0_0.checkAwardIsGet(arg_13_0)
	if arg_13_0:checkActivityIsOpen() ~= var_0_13.OPEN then
		return
	end

	local var_13_0 = arg_13_0.activity.details.award_count

	if arg_13_0:checkAwardCanGet() then
		if var_13_0 + 1 >= arg_13_0.maxLev then
			arg_13_0.container:getChildByName("btn_6"):setTouchEnabled(true)
			arg_13_0.container:getChildByName("btn_6"):setBright(true)
			arg_13_0:initGiftIconAnimation(arg_13_0.container:getChildByName("btn_6"))
			arg_13_0.container:getChildByName("btn_6"):addTouchEventListener(function(arg_14_0, arg_14_1)
				if arg_14_1 == ccui.TouchEventType.ended then
					arg_13_0.container:getChildByName("btn_6"):setTouchEnabled(false)
					arg_13_0:getActivityReward2(var_13_0, function()
						arg_13_0.container:getChildByName("btn_6"):setTouchEnabled(false)
						arg_13_0.container:getChildByName("btn_6"):setBright(false)
						arg_13_0.light:setVisible(false)
						arg_13_0.container:getChildByName("btn_6"):stopAllActions()
						arg_13_0.container:getChildByName("btn_6"):setRotation(0)

						arg_13_0.giftIsAnimation = false

						arg_13_0:updateJinduShow()
						arg_13_0:checkAwardIsGet()
					end)
				end
			end)
		else
			local var_13_1 = var_13_0 + 1
			local var_13_2 = arg_13_0.container:getChildByName("btn_" .. var_13_1)

			var_13_2:setTouchEnabled(true)
			arg_13_0.nodeTips[var_13_1]:setVisible(false)
			arg_13_0:initGiftIconAnimation(var_13_2)
			var_13_2:addTouchEventListener(function(arg_16_0, arg_16_1)
				if arg_16_1 == ccui.TouchEventType.ended then
					var_13_2:setTouchEnabled(false)
					arg_13_0:getActivityReward2(var_13_0, function()
						var_13_2:setTouchEnabled(false)
						var_13_2:setBright(false)
						arg_13_0.light:setVisible(false)

						arg_13_0.giftIsAnimation = false

						var_13_2:stopAllActions()
						var_13_2:setRotation(0)
						arg_13_0:updateJinduShow()
						arg_13_0:checkAwardIsGet()
					end)
				end
			end)
		end
	end
end

function var_0_0.checkAwardCanGet(arg_18_0)
	local var_18_0 = arg_18_0.activity.details.award_count
	local var_18_1 = arg_18_0.activity.details.element_lev

	if var_18_0 < var_18_1 then
		return true
	end

	if var_18_1 == arg_18_0.maxLev and arg_18_0.activity.details.element_num >= var_0_2:elementReq(arg_18_0.maxLev) + (var_18_0 - arg_18_0.maxLev + 1) * xyd.tables.misc.activityFusionMax then
		return true
	end

	return false
end

function var_0_0.initGiftIconAnimation(arg_19_0, arg_19_1)
	if arg_19_0.giftIsAnimation then
		return
	end

	local var_19_0 = 0.2
	local var_19_1 = cc.Spawn:create({
		cc.Sequence:create({
			cc.MoveBy:create(var_19_0, cc.p(5, 0)),
			cc.MoveBy:create(var_19_0, cc.p(-10, 0)),
			cc.MoveBy:create(var_19_0, cc.p(5, 0)),
			cc.DelayTime:create(var_19_0 * 3)
		}),
		cc.Sequence:create({
			cc.RotateBy:create(var_19_0, 15),
			cc.RotateBy:create(var_19_0, -30),
			cc.RotateBy:create(var_19_0, 15),
			cc.DelayTime:create(var_19_0 * 3)
		}),
		cc.CallFunc:create(function()
			local var_20_0, var_20_1 = arg_19_1:getPosition()

			arg_19_0.light:setPosition(var_20_0, var_20_1)
			arg_19_0.light:setVisible(true)
		end)
	})

	arg_19_1:runAction(cc.RepeatForever:create(var_19_1))

	arg_19_0.giftIsAnimation = true
end

function var_0_0.initMakeAnimation(arg_21_0, arg_21_1, arg_21_2)
	local var_21_0 = var_0_3:icon(arg_21_2)

	if not arg_21_1 or tolua.isnull(arg_21_1) then
		return
	end

	local var_21_1 = arg_21_1:convertToWorldSpace(cc.p(arg_21_1:getChildByName("container"):getPosition()))
	local var_21_2 = arg_21_0.container:convertToNodeSpace(cc.p(var_21_1))
	local var_21_3 = cc.p(arg_21_0.container:getChildByName("btn_5"):getPosition())
	local var_21_4 = xyd.AssetLoader.get():loadSprite(var_21_0)

	var_21_4:addTo(arg_21_0.container)
	var_21_4:setAnchorPoint(cc.p(0.5, 0.5))
	var_21_4:setPosition(cc.p(var_21_2))
	arg_21_1:setVisible(false)

	local var_21_5 = var_0_6 .. ".json"
	local var_21_6 = var_0_6 .. ".atlas"
	local var_21_7 = var_0_5.new(var_21_5, var_21_6, 1)

	var_21_7:addTo(arg_21_0.container)
	var_21_7:setPosition(cc.p(var_21_2))
	var_21_7:play(function()
		local var_22_0 = cc.MoveTo:create(var_0_11, cc.p(var_21_3))
		local var_22_1 = cc.FadeOut:create(var_0_11)
		local var_22_2 = cc.Spawn:create({
			var_22_0,
			var_22_1
		})
		local var_22_3 = cc.CallFunc:create(function()
			arg_21_0.animation = false

			arg_21_0:updateLoadingbar()
			arg_21_0:updateJinduShow()
			arg_21_0:updateItemShow()
			arg_21_0.list:refreshList()
		end)

		var_21_4:runAction(transition.sequence({
			var_22_2,
			var_22_3
		}))
	end, false)
end

function var_0_0.updateJinduShow(arg_24_0)
	local var_24_0 = var_0_2:ids()
	local var_24_1 = arg_24_0.activity.details.element_lev
	local var_24_2
	local var_24_3
	local var_24_4 = arg_24_0.activity.details.element_num

	for iter_24_0 = 1, #var_24_0 - 1 do
		local var_24_5 = var_0_2:elementReq(iter_24_0)
		local var_24_6 = math.min(var_24_4, var_24_5)

		arg_24_0.container:getChildByName("btn_" .. iter_24_0):getChildByName("txt_" .. iter_24_0):setString(var_24_6 .. "/" .. var_24_5)
	end

	if var_24_1 == #var_24_0 then
		local var_24_7 = var_0_2:elementReq(arg_24_0.maxLev)

		var_24_2 = var_24_4 + xyd.tables.misc.activityFusionMax - (var_24_4 - var_24_7) % xyd.tables.misc.activityFusionMax
	else
		var_24_2 = var_0_2:elementReq(arg_24_0.maxLev)
	end

	arg_24_0.container:getChildByName("btn_6"):getChildByName("txt_6"):setString(var_24_4 .. "/" .. var_24_2)
end

function var_0_0.showLevAward(arg_25_0)
	local var_25_0 = {}
	local var_25_1 = ""

	if arg_25_0.activity.details.element_lev == arg_25_0.maxLev then
		arg_25_0.showLev = arg_25_0.maxLev
	else
		arg_25_0.showLev = arg_25_0.activity.details.element_lev + 1
	end

	local var_25_2 = var_0_2:drops(arg_25_0.showLev)

	if var_25_2 and var_25_2[1] ~= 0 then
		for iter_25_0, iter_25_1 in pairs(var_25_2) do
			table.insert(var_25_0, {
				itemNum = 1,
				itemID = iter_25_1
			})
		end

		var_25_1 = var_0_1:translation("ACTIVITY_FUSION_SPECIAL_AWARD")
	else
		local var_25_3 = var_0_2:gift(arg_25_0.showLev)
		local var_25_4 = xyd.tables.gift:items(var_25_3)
		local var_25_5 = xyd.tables.gift:itemNum(var_25_3)
		local var_25_6 = xyd.tables.gift:mana(var_25_3)
		local var_25_7 = xyd.tables.gift:crystal(var_25_3)

		for iter_25_2, iter_25_3 in pairs(var_25_4) do
			if iter_25_3 ~= 0 then
				table.insert(var_25_0, {
					itemID = iter_25_3,
					itemNum = var_25_5[iter_25_2]
				})
			end
		end

		if var_25_6 > 0 then
			table.insert(var_25_0, {
				itemID = -2,
				itemNum = var_25_6
			})
		end

		if var_25_7 > 0 then
			table.insert(var_25_0, {
				itemID = -1,
				itemNum = var_25_7
			})
		end

		var_25_1 = var_0_1:translation("ACTIVITY_FUSION_AWARD")
	end

	local var_25_8 = arg_25_0.container:getChildByName("jindu_" .. arg_25_0.showLev):getParent():convertToWorldSpace(cc.p(arg_25_0.container:getChildByName("jindu_" .. arg_25_0.showLev):getPosition()))
	local var_25_9 = xyd.addPosition(var_25_8, cc.p(-100, 20))

	arg_25_0:showAwardsWnd(var_25_0, var_25_1, var_25_9)
end

function var_0_0.showAwardsWnd(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	arg_26_0.awardsWnd = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1076/level_award.csb")

	arg_26_0.awardsWnd:addTo(arg_26_0.parent)
	arg_26_0.awardsWnd:setLocalZOrder(20)
	arg_26_0.awardsWnd:setTouchSwallowEnabled(true)
	arg_26_0.awardsWnd:setTouchEnabled(true)

	local var_26_0 = arg_26_0.awardsWnd:getChildByName("container")

	arg_26_0.awardsWnd:setPosition(cc.p(arg_26_3.x, arg_26_3.y - var_26_0:getContentSize().width / 2))

	local var_26_1 = var_26_0:getChildByName("detail_container")
	local var_26_2 = var_26_1:getContentSize()
	local var_26_3 = math.ceil(#arg_26_1 / var_0_12)

	var_26_0:getChildByName("text_title"):setString(arg_26_2)

	if var_26_3 > 1 then
		local var_26_4 = var_26_3 - 1

		var_26_0:setContentSize(var_26_0:getContentSize().width, var_26_0:getContentSize().height + var_0_8 * var_26_4)

		local var_26_5 = var_26_0:getChildByName("bg"):getContentSize()

		var_26_0:getChildByName("bg"):setContentSize(var_26_5.width, var_26_5.height + var_0_8 * var_26_4)
		var_26_0:getChildByName("text_title"):setPositionY(var_26_0:getChildByName("text_title"):getPositionY() + var_0_8 * var_26_4)
		var_26_1:setContentSize(var_26_2.width, var_26_2.height + var_0_8 * var_26_4)

		var_26_2 = var_26_1:getContentSize()

		arg_26_0.awardsWnd:setPosition(cc.p(arg_26_3.x, arg_26_3.y - var_26_0:getContentSize().width / 2 - 50))
	end

	local var_26_6 = var_26_2.height - var_0_8

	for iter_26_0 = 1, var_26_3 do
		local var_26_7 = 0

		for iter_26_1 = 1, var_0_12 do
			local var_26_8 = arg_26_1[(iter_26_0 - 1) * var_0_12 + iter_26_1]

			if not var_26_8 then
				return
			end

			local var_26_9 = display.newNode()

			var_26_9:setContentSize(var_0_8, var_0_8)
			xyd.setItemBorder(var_26_9, var_26_8.itemID, false, false, var_26_8.itemNum)
			var_26_9:addTo(var_26_1)
			var_26_9:setAnchorPoint(cc.p(0, 0))
			var_26_9:setPosition(var_26_7, var_26_6)

			var_26_7 = var_26_7 + var_0_8 + 10

			local var_26_10 = {
				id = var_26_8.itemID,
				lev = xyd.tables.item:level(var_26_8.itemID),
				desc2 = xyd.tables.item:desc2(var_26_8.itemID),
				name = xyd.tables.item:name(var_26_8.itemID),
				hasNum = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_26_8.itemID)
			}

			if xyd.tables.item:type(var_26_8.itemID) == -1 then
				var_26_10.tipsType = 0
				var_26_10.desc1 = xyd.tables.hero:getDes(var_26_8.itemID)
			else
				var_26_10.tipsType = 1
			end

			arg_26_0:addTips(var_26_9, var_26_10)
		end

		var_26_6 = var_26_6 - var_0_8
	end
end

function var_0_0.updateItemShow(arg_27_0)
	local var_27_0 = arg_27_0.container:getChildByName("item_container")
	local var_27_1 = var_0_4:ids()

	for iter_27_0, iter_27_1 in pairs(var_27_1) do
		local var_27_2 = var_0_4:item(iter_27_1)
		local var_27_3 = arg_27_0.player:getBackpack():getItemNumByID(var_27_2)

		var_27_0:getChildByName("item_num_" .. iter_27_0):setString("x " .. var_27_3)
	end
end

function var_0_0.delegate(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = xyd.splitToNumber(arg_28_0.activity.details.fusion_ids, "|")

	if cc.ui.UIListView.COUNT_TAG == arg_28_2 then
		return #var_28_0 or 0
	elseif cc.ui.UIListView.CELL_TAG == arg_28_2 then
		local var_28_1
		local var_28_2 = arg_28_0.list:dequeueItem()

		if not var_28_2 then
			var_28_2 = arg_28_0.list:newItem()
		else
			var_28_2:removeAllChildren(true)
		end

		local var_28_3 = arg_28_0:createMissionContent(var_28_0, arg_28_3)

		var_28_2:setItemSize(453, 157)
		var_28_2:addContent(var_28_3)

		return var_28_2
	end
end

function var_0_0.createMissionContent(arg_29_0, arg_29_1, arg_29_2)
	local var_29_0 = arg_29_1[arg_29_2]
	local var_29_1 = var_0_3:name(var_29_0)
	local var_29_2 = var_0_3:icon(var_29_0)
	local var_29_3 = var_0_3:materialIDs(var_29_0)
	local var_29_4 = var_0_3:materialNums(var_29_0)
	local var_29_5 = var_0_3:elementNum(var_29_0)
	local var_29_6 = true
	local var_29_7 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1076/mission_item.csb")
	local var_29_8 = var_29_7:getChildByName("container")

	var_29_8:getChildByName("text_name"):setString(var_29_1)
	var_29_8:getChildByName("text_name"):enableOutline(cc.c4b(94, 27, 43, 255), 2)

	local var_29_9 = xyd.AssetLoader.get():loadSprite(var_29_2)

	if var_29_9 then
		var_29_9:setScale(0.5)
		var_29_9:addTo(var_29_8)
		var_29_9:setPosition(cc.p(cc.p(var_29_8:getChildByName("item_pos"):getPosition())))
	end

	local var_29_10 = var_29_8:getChildByName("detail_container")
	local var_29_11 = 0

	for iter_29_0, iter_29_1 in pairs(var_29_3) do
		local var_29_12 = display.newNode()

		var_29_12:setContentSize(var_0_9, var_0_9)
		var_29_12:addTo(var_29_10)
		var_29_12:setPosition(cc.p(var_29_11, 0))
		var_29_12:setAnchorPoint(cc.p(0, 0))
		xyd.setItemBorder(var_29_12, iter_29_1)

		local var_29_13 = var_29_4[iter_29_0]

		if var_29_13 > arg_29_0.player:getBackpack():getItemNumByID(iter_29_1) then
			var_29_6 = false
		end

		local var_29_14 = {
			size = 26,
			color = cc.c3b(129, 54, 28),
			text = "x " .. var_29_13
		}
		local var_29_15 = xyd.AssetLoader.get():loadLabel(var_29_14)

		var_29_10:addChild(var_29_15)
		var_29_15:setPosition(cc.p(var_29_11 + 20, -15))
		var_29_15:setAnchorPoint(cc.p(0, 0.5))

		if iter_29_0 ~= 1 then
			local var_29_16 = "windows/activities/1076/bg_add.png"
			local var_29_17 = xyd.AssetLoader.get():loadSprite(var_29_16)

			var_29_17:setScale(0.6)
			var_29_17:addTo(var_29_10)
			var_29_17:setPosition(cc.p(var_29_11 - 15, var_0_9 / 2))
			var_29_17:setAnchorPoint(cc.p(0.5, 0.5))
		end

		var_29_11 = var_29_11 + var_0_9 + 30
	end

	if var_29_6 == true then
		var_29_8:getChildByName("img_make"):setVisible(true)
		var_29_8:getChildByName("img_make"):setLocalZOrder(10)
	else
		var_29_8:getChildByName("img_make"):setVisible(false)
	end

	var_29_7:setCascadeOpacityEnabled(true)
	var_29_7:setTouchEnabled(true)
	var_29_7:setTouchSwallowEnabled(false)
	var_29_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_30_0)
		if arg_30_0.name == "began" then
			var_29_7:getChildByName("container"):setScale(0.9)

			return true
		elseif arg_30_0.name == "ended" then
			var_29_7:getChildByName("container"):setScale(1)

			if not arg_29_0.scrollViewMoved_ then
				local var_30_0 = arg_29_0:checkActivityIsOpen()

				if var_30_0 == var_0_13.OPEN then
					if var_29_6 == false then
						arg_29_0.animation = false

						local var_30_1 = var_0_1:translation("MATERIAL_NOT_ENOUGH")

						xyd.WindowManager.get():openWindow("toast", {
							message = var_30_1
						})

						return true
					elseif not arg_29_0.animation then
						arg_29_0.animation = true

						local var_30_2 = string.format(var_0_1:translation("ACTIVITY_FUSION_MAKE_ITEM"), var_29_1)

						xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_30_2, function()
							arg_29_0:exchangeFusionItem(var_29_7, var_29_0)
						end, {
							lcallback = function()
								arg_29_0.animation = false
							end
						}, nil, xyd.ColorMode.ACTIVITY)
					end
				elseif var_30_0 == var_0_13.NOT_OPEN then
					arg_29_0.animation = false

					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_FUSION_NOT_OPEN")
					})
				elseif var_30_0 == var_0_13.HAVE_OVER then
					arg_29_0.animation = false

					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("ACTIVITY_FUSION_HAVE_OVER")
					})
				end
			end
		end
	end)

	return var_29_7
end

function var_0_0.checkActivityIsOpen(arg_33_0)
	local var_33_0 = xyd.ServerTime.get():getServerTime()

	if var_33_0 < arg_33_0.activity.start_time then
		return var_0_13.NOT_OPEN
	elseif var_33_0 > arg_33_0.activity.end_time then
		return var_0_13.HAVE_OVER
	else
		return var_0_13.OPEN
	end
end

function var_0_0.exchangeFusionItem(arg_34_0, arg_34_1, arg_34_2)
	local var_34_0 = {
		fusion_id = arg_34_2
	}

	xyd.Backend.get():request(xyd.mid.EXCHANGE_FUSION_ITEM, var_34_0, function(arg_35_0, arg_35_1)
		if arg_35_0 == xyd.error.OK then
			arg_34_0.activity.details = arg_35_1.details

			arg_34_0:updateExchangeLaterInfo(arg_34_1, arg_34_2)
		else
			arg_34_0.animation = false
		end
	end)
end

function var_0_0.updateExchangeLaterInfo(arg_36_0, arg_36_1, arg_36_2)
	local var_36_0 = var_0_3:materialIDs(arg_36_2)
	local var_36_1 = var_0_3:materialNums(arg_36_2)

	for iter_36_0, iter_36_1 in pairs(var_36_0) do
		local var_36_2 = var_36_1[iter_36_0]
		local var_36_3 = arg_36_0.player:getBackpack():getItemNumByID(iter_36_1)

		arg_36_0.player:getBackpack():setItemNumByID(iter_36_1, var_36_3 - var_36_2)
	end

	arg_36_0:initMakeAnimation(arg_36_1, arg_36_2)
end

function var_0_0.addBlockLayerClickClose(arg_37_0, arg_37_1)
	arg_37_1 = arg_37_1 or -1
	arg_37_0.blockLayer_ = display.newLayer()

	local var_37_0 = arg_37_0.parent:convertToWorldSpace(cc.p(0, 0))

	arg_37_0.blockLayer_:pos(-var_37_0.x, -var_37_0.y):addTo(arg_37_0.parent, arg_37_1)
	arg_37_0.blockLayer_:setContentSize(xyd.STAGE_WIDTH, xyd.STAGE_HEIGHT)
	arg_37_0.blockLayer_:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_38_0)
		if arg_38_0.name == "began" then
			return true
		elseif arg_38_0.name == "ended" then
			arg_37_0.awardsWnd:removeSelf()
			arg_37_0.blockLayer_:removeSelf()
		end
	end)
end

function var_0_0.scrollListener(arg_39_0, arg_39_1)
	if arg_39_1.name == "began" then
		arg_39_0.scrollViewMoved_ = false
		arg_39_0.prevY_ = arg_39_1.y
	elseif arg_39_1.name == "moved" and 3 <= math.abs(arg_39_1.y - arg_39_0.prevY_) then
		arg_39_0.scrollViewMoved_ = true
	end
end

function var_0_0.release(arg_40_0)
	if arg_40_0.handler then
		var_0_7.unscheduleGlobal(arg_40_0.handler)

		arg_40_0.handler = nil
	end

	arg_40_0.animation = false
	arg_40_0.giftIsAnimation = false
	arg_40_0.giftIcon = false
end

return var_0_0
