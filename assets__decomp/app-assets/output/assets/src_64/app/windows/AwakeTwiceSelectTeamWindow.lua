local var_0_0 = class("AwakeTwiceSelectTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Hero")
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation
local var_0_4 = 30
local var_0_5 = 16
local var_0_6 = 5
local var_0_7 = 5
local var_0_8 = class("ScrollView", cc.ui.UIListView)

function var_0_8.ctor(arg_1_0, arg_1_1)
	var_0_8.super.ctor(arg_1_0, arg_1_1)
end

function var_0_8.removeItem(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0, var_2_1 = arg_2_1:getItemSize()

	arg_2_0.container:removeChild(arg_2_1)

	local var_2_2 = arg_2_0:getItemPos(arg_2_1)

	if var_2_2 then
		table.remove(arg_2_0.items_, var_2_2)
	end

	local var_2_3 = 0

	arg_2_0.size.width = arg_2_0.size.width - var_2_0
	arg_2_0.size.height = arg_2_0.size.height - var_2_3

	if table.nums(arg_2_0.items_) == 0 then
		return
	end

	if var_2_2 <= var_0_7 then
		arg_2_0:moveItems(var_2_2, table.nums(arg_2_0.items_), -var_2_0, -var_2_3, arg_2_2)
	else
		arg_2_0:moveItems(1, var_2_2 - 1, var_2_0, var_2_3, arg_2_2)
	end

	return arg_2_0
end

function var_0_0.ctor(arg_3_0, arg_3_1, arg_3_2)
	var_0_0.super.ctor(arg_3_0, arg_3_1, arg_3_2)

	arg_3_0.missionId = arg_3_2.missionId
	arg_3_0.heroId = arg_3_2.heroId
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_3_0.guardHero = arg_3_0.selfPlayer:getHeroByTableID(arg_3_0.heroId)
	arg_3_0.totalHero_ = {}
	arg_3_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_3_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_3_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_3_0.totalHero_[xyd.DistanceType.HOUPAI] = {}
	arg_3_0.teamCells_ = {}
	arg_3_0.heroCells_ = {}
	arg_3_0.bottomItems_ = {}
	arg_3_0.isAnimated_ = false
	arg_3_0.selectedHeroClass_ = xyd.DistanceType.ALL
end

function var_0_0.willOpen(arg_4_0, arg_4_1)
	arg_4_0:initHeros()
	arg_4_0:layout()
end

function var_0_0.initHeros(arg_5_0)
	local var_5_0 = arg_5_0.selfPlayer.heros_

	arg_5_0.totalHero_[xyd.DistanceType.ALL] = {}
	arg_5_0.totalHero_[xyd.DistanceType.QIANPAI] = {}
	arg_5_0.totalHero_[xyd.DistanceType.ZHONGPAI] = {}
	arg_5_0.totalHero_[xyd.DistanceType.HOUPAI] = {}

	for iter_5_0, iter_5_1 in pairs(var_5_0) do
		if arg_5_0:canHeroJoinBattle(iter_5_1) then
			if iter_5_1:getDistanceType() == xyd.DistanceType.QIANPAI then
				table.insert(arg_5_0.totalHero_[xyd.DistanceType.QIANPAI], iter_5_1)
			elseif iter_5_1:getDistanceType() == xyd.DistanceType.ZHONGPAI then
				table.insert(arg_5_0.totalHero_[xyd.DistanceType.ZHONGPAI], iter_5_1)
			elseif iter_5_1:getDistanceType() == xyd.DistanceType.HOUPAI then
				table.insert(arg_5_0.totalHero_[xyd.DistanceType.HOUPAI], iter_5_1)
			end

			table.insert(arg_5_0.totalHero_[xyd.DistanceType.ALL], iter_5_1)
		end
	end

	arg_5_0:sortTables(arg_5_0.totalHero_)

	arg_5_0.selectedHeroClass_ = xyd.DistanceType.ALL
end

function var_0_0.sortTables(arg_6_0, arg_6_1)
	for iter_6_0 = 1, #arg_6_1 do
		table.sort(arg_6_1[iter_6_0], function(arg_7_0, arg_7_1)
			if arg_7_0:getTableID() == arg_6_0.heroId then
				return true
			elseif arg_7_1:getTableID() == arg_6_0.heroId then
				return false
			end

			return xyd.heroNormalSort(arg_7_0, arg_7_1) or false
		end)
	end
end

function var_0_0.layout(arg_8_0)
	local var_8_0 = arg_8_0:nodeByName("list_layer")
	local var_8_1 = var_8_0:getContentSize()

	arg_8_0.heroList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_8_1.width, var_8_1.height),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_8_0)
	arg_8_0.heroCells_ = {}

	arg_8_0.heroList_:setDelegate(handler(arg_8_0, arg_8_0.heroDelegate))
	arg_8_0.heroList_:reload()

	local var_8_2 = arg_8_0:nodeByName("bottom_scroll")
	local var_8_3 = var_8_2:getContentSize()

	arg_8_0.bottomList_ = var_0_8.new({
		async = false,
		viewRect = cc.rect(0, 0, var_8_3.width, var_8_3.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_8_2):onScroll(handler(arg_8_0, arg_8_0.scrollListener))

	arg_8_0.bottomList_:setBounceable(true)
	arg_8_0:bottomListLayout()
	arg_8_0:setButtonClick()
	arg_8_0:updateSelectProgressShow()
	arg_8_0:addPartner(arg_8_0.guardHero)

	local var_8_4 = string.format(var_0_3:translation("BLOODLINE_INCUBUS_TIPS1"), arg_8_0.guardHero:getName())

	arg_8_0:nodeByName("select_tips_txt"):setString(var_8_4)
end

function var_0_0.bottomListLayout(arg_9_0)
	for iter_9_0 = 1, var_0_5 do
		arg_9_0:addNewBottomItem()
	end

	arg_9_0.bottomList_:reload()
end

function var_0_0.updateSelectProgressShow(arg_10_0)
	arg_10_0:nodeByName("select_num_txt"):setString(#arg_10_0.teamCells_ - 1 .. "/" .. var_0_5 - 1)
end

function var_0_0.setOrgPositonX(arg_11_0)
	arg_11_0.orgPositonX = arg_11_0.bottomList_:getScrollNode():getPositionX()
end

function var_0_0.scrollToOrgPositonX(arg_12_0, arg_12_1)
	if arg_12_0.orgPositonX and arg_12_0.orgPositonX <= 0 then
		if arg_12_1 and arg_12_0.orgPositonX + 152 <= 0 then
			arg_12_0.bottomList_:getScrollNode():setPositionX(arg_12_0.orgPositonX + 152)
		else
			arg_12_0.bottomList_:getScrollNode():setPositionX(arg_12_0.orgPositonX)
		end
	end

	arg_12_0.orgPositonX = nil
end

function var_0_0.scrollToIthItem(arg_13_0, arg_13_1)
	if arg_13_1 < 1 then
		arg_13_1 = 1
	elseif arg_13_1 >= var_0_5 - (var_0_7 - 1) then
		arg_13_1 = var_0_5 - (var_0_7 - 1)
	end

	arg_13_0.bottomList_:scrollTo(-(arg_13_1 - 1) * 152, 0)
end

function var_0_0.addNewBottomItem(arg_14_0)
	local var_14_0 = arg_14_0.bottomList_:dequeueItem()

	if not var_14_0 then
		var_14_0 = arg_14_0.bottomList_:newItem()
	else
		var_14_0:removeAllChildren(true)
	end

	local var_14_1 = arg_14_0:createBottomListContent()
	local var_14_2 = var_14_1:getWidth()
	local var_14_3 = var_14_1:getHeight()

	var_14_0:setItemSize(var_14_2, var_14_3)
	var_14_0:addContent(var_14_1)
	var_14_1:setName("content")
	table.insert(arg_14_0.bottomItems_, var_14_0)
	arg_14_0.bottomList_:addItem(var_14_0)
end

function var_0_0.createBottomListContent(arg_15_0)
	local var_15_0 = display.newNode()
	local var_15_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/awake_twice/select_team/bottom_item.csb")
	local var_15_2 = var_15_1:getChildByName("container")

	var_15_0:setAnchorPoint(cc.p(0, 0))
	var_15_0:setPosition(0, 0)
	var_15_1:addTo(var_15_0)
	var_15_1:setAnchorPoint(cc.p(0, 0))
	var_15_0:setContentSize(var_15_2:getContentSize())
	var_15_1:setName("source")

	return var_15_0
end

function var_0_0.heroDelegate(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = math.ceil(#arg_16_0.totalHero_[arg_16_0.selectedHeroClass_] / var_0_6)

	if cc.ui.UIListView.COUNT_TAG == arg_16_2 then
		return var_16_0
	elseif cc.ui.UIListView.CELL_TAG == arg_16_2 then
		local var_16_1
		local var_16_2 = arg_16_0.heroList_:dequeueItem()

		if not var_16_2 then
			var_16_2 = arg_16_0.heroList_:newItem()
		else
			var_16_2:removeAllChildren(true)
		end

		local var_16_3 = display.newNode()

		var_16_3:setTouchSwallowEnabled(false)

		for iter_16_0 = 1, var_0_6 do
			local var_16_4 = (arg_16_3 - 1) * var_0_6 + iter_16_0

			if var_16_4 > #arg_16_0.totalHero_[arg_16_0.selectedHeroClass_] then
				break
			end

			var_16_1 = arg_16_0:initHeroCell(var_16_4)

			local var_16_5 = var_16_1:getContentSize().width
			local var_16_6 = var_16_1:getContentSize().height
			local var_16_7 = (arg_16_0.heroList_.viewRect_.width - var_16_5 * var_0_6) / (var_0_6 + 1)

			var_16_1:pos(var_16_7 * iter_16_0 + (iter_16_0 - 1) * var_16_5 + var_16_5 / 2, var_0_4 + var_16_6 / 2 - 2)
			var_16_3:addChild(var_16_1)

			arg_16_0.heroCells_[var_16_4] = var_16_1
		end

		var_16_3:setContentSize(cc.size(arg_16_0.heroList_.viewRect_.width, var_16_1:getContentSize().height + var_0_4))
		var_16_2:setItemSize(arg_16_0.heroList_.viewRect_.width, var_16_1:getContentSize().height + var_0_4)
		var_16_2:addContent(var_16_3)

		return var_16_2
	end
end

function var_0_0.initHeroCell(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.totalHero_[arg_17_0.selectedHeroClass_][arg_17_1]
	local var_17_1 = arg_17_0:initTeamCell(var_17_0)

	var_17_1.hero = var_17_0

	for iter_17_0 = 1, #arg_17_0.teamCells_ do
		if arg_17_0.teamCells_[iter_17_0].hero:getTableID() == var_17_0:getTableID() then
			arg_17_0:setHeroCellSelectedState(var_17_1)

			break
		end
	end

	var_17_1:setTouchEnabled(true)
	var_17_1:setTouchSwallowEnabled(false)
	var_17_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_18_0)
		if arg_18_0.name == "began" then
			var_17_1:setScale(0.9)

			arg_17_0.startClick_ = true
			arg_17_0.prevX_ = arg_18_0.x
			arg_17_0.prevY_ = arg_18_0.y
		elseif arg_18_0.name == "moved" then
			if math.abs(arg_18_0.y - arg_17_0.prevY_) > 5 or math.abs(arg_18_0.x - arg_17_0.prevX_) > 5 then
				arg_17_0.startClick_ = false

				var_17_1:setScale(1)
			end
		elseif arg_18_0.name == "ended" and arg_17_0.startClick_ then
			var_17_1:setScale(1)
			arg_17_0:clickAvatar(var_17_1)
		end

		return true
	end)

	return var_17_1
end

function var_0_0.initTeamCell(arg_19_0, arg_19_1)
	local var_19_0 = display.newNode()
	local var_19_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/awake_twice/select_team/hero_avatar.csb")
	local var_19_2 = var_19_1:getChildByName("background"):getContentSize()

	var_19_1:setContentSize(var_19_2)
	var_19_0:setContentSize(var_19_2)
	xyd.setAvatarBorder(arg_19_1, var_19_1:getChildByName("avatar"))
	var_19_1:getChildByName("lv_txt"):setString(arg_19_1:getLevel())

	local var_19_3 = var_19_1:getChildByName("name_text")

	var_19_3:setString(arg_19_1:getName())
	var_19_3:enableOutline(cc.c4b(0, 0, 0, 105), 1)

	if xyd.Color2Level[arg_19_1:getColor()] ~= "" then
		local var_19_4 = {
			size = 20,
			align = cc.ui.TEXT_ALIGN_LEFT,
			valign = cc.ui.TEXT_VALIGN_BOTTOM,
			x = var_19_3:getX() + var_19_3:getWidth() / 2 - 10,
			y = var_19_3:getY(),
			color = xyd.color.HERO_QUALITY[arg_19_1:getColor()],
			text = xyd.Color2Level[arg_19_1:getColor()]
		}
		local var_19_5 = xyd.AssetLoader.get():loadLabel(var_19_4)

		var_19_5:addTo(var_19_1)
		var_19_5:align(display.CENTER_LEFT)
		var_19_5:enableOutline(cc.c4b(0, 0, 0, 255), 1)
		var_19_3:x(var_19_3:getX() - 15)
	end

	var_19_1:setName("layout")

	var_19_0.hero = arg_19_1

	var_19_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_0:addChild(var_19_1)
	arg_19_0:setHeroCellUnSelectedState(var_19_0)

	return var_19_0
end

function var_0_0.setHeroCellSelectedState(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_1:getChildByName("layout")
	local var_20_1 = var_20_0:getChildByName("avatar_mask")
	local var_20_2 = var_20_0:getChildByName("chosen")

	arg_20_1.isSelected = true

	var_20_1:setVisible(true)
	var_20_2:setVisible(true)
end

function var_0_0.setHeroCellUnSelectedState(arg_21_0, arg_21_1)
	local var_21_0 = arg_21_1:getChildByName("layout")
	local var_21_1 = var_21_0:getChildByName("avatar_mask")
	local var_21_2 = var_21_0:getChildByName("chosen")

	var_21_2:setLocalZOrder(100)
	var_21_1:setLocalZOrder(2)

	arg_21_1.isSelected = false

	var_21_1:setVisible(false)
	var_21_2:setVisible(false)
end

function var_0_0.setButtonClick(arg_22_0)
	arg_22_0:nodeByName("button_all"):addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended then
			arg_22_0.selectedHeroClass_ = xyd.DistanceType.ALL
			arg_22_0.heroCells_ = {}

			arg_22_0.heroList_:reload()
		end
	end)
	arg_22_0:nodeByName("button_qianpai"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended then
			arg_22_0.selectedHeroClass_ = xyd.DistanceType.QIANPAI
			arg_22_0.heroCells_ = {}

			arg_22_0.heroList_:reload()
		end
	end)
	arg_22_0:nodeByName("button_zhongpai"):addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.ended then
			arg_22_0.selectedHeroClass_ = xyd.DistanceType.ZHONGPAI
			arg_22_0.heroCells_ = {}

			arg_22_0.heroList_:reload()
		end
	end)
	arg_22_0:nodeByName("button_houpai"):addTouchEventListener(function(arg_26_0, arg_26_1)
		if arg_26_1 == ccui.TouchEventType.ended then
			arg_22_0.selectedHeroClass_ = xyd.DistanceType.HOUPAI
			arg_22_0.heroCells_ = {}

			arg_22_0.heroList_:reload()
		end
	end)
	arg_22_0:nodeByName("button_battle"):addTouchEventListener(function(arg_27_0, arg_27_1)
		if arg_27_1 == ccui.TouchEventType.ended then
			if #arg_22_0.teamCells_ < 2 then
				local var_27_0 = var_0_3:translation("BLOODLINE_INCUBUS_TIPS3")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_27_0
				})

				return
			end

			xyd.Backend.get():request(xyd.mid.UNLIMIT_START_FIGHT, {
				twice_awake_mission = arg_22_0.missionId,
				incubus_id = arg_22_0.missionId
			}, function(arg_28_0, arg_28_1)
				if arg_28_0 == xyd.error.OK then
					local var_28_0 = {
						isAwakeTwice = true,
						id = arg_22_0.missionId,
						herosA = arg_22_0:getHeroList(),
						partner = xyd.tables.incubusTable:partner(arg_22_0.missionId),
						guard = xyd.tables.incubusTable:guard(arg_22_0.missionId)
					}
					local var_28_1 = import("app.scenes.BattleUnlimit")
					local var_28_2 = {}
					local var_28_3 = {}

					for iter_28_0, iter_28_1 in ipairs(arg_22_0.teamCells_) do
						table.insert(var_28_2, iter_28_1.hero:getTableID())

						var_28_3[iter_28_1.hero:getTableID()] = 1
					end

					for iter_28_2 = 1, 20 do
						local var_28_4 = tonumber(string.format("%d%03d", var_28_0.id, iter_28_2))
						local var_28_5 = xyd.tables.incubusMonsterTable:leftMonster(var_28_4)

						for iter_28_3, iter_28_4 in ipairs(var_28_5) do
							if not var_28_3[iter_28_4] then
								table.insert(var_28_2, iter_28_4)

								var_28_3[iter_28_4] = 1
							end
						end

						local var_28_6 = xyd.tables.incubusMonsterTable:rightMonster(var_28_4)

						for iter_28_5, iter_28_6 in ipairs(var_28_6) do
							if not var_28_3[iter_28_6] then
								table.insert(var_28_2, iter_28_6)

								var_28_3[iter_28_6] = 1
							end
						end
					end

					if not var_28_3[var_28_0.partner] then
						table.insert(var_28_2, var_28_0.partner)

						var_28_3[var_28_0.partner] = 1
					end

					for iter_28_7, iter_28_8 in pairs(var_28_0.guard) do
						if not var_28_3[iter_28_8] then
							table.insert(var_28_2, iter_28_8)

							var_28_3[iter_28_8] = 1
						end
					end

					xyd.AssetDownload.get():preloadCharacters(var_28_2, function()
						cc.Director:getInstance():pushScene(var_28_1.new(var_28_0))
					end)
				end
			end, nil, nil, true)
		end
	end)
end

function var_0_0.getHeroList(arg_30_0)
	local var_30_0 = {}

	for iter_30_0, iter_30_1 in ipairs(arg_30_0.teamCells_) do
		if iter_30_0 ~= 1 then
			table.insert(var_30_0, iter_30_1.hero)
		end
	end

	return var_30_0
end

function var_0_0.clickAvatar(arg_31_0, arg_31_1)
	if arg_31_0.isAnimated_ == true then
		return
	end

	if arg_31_1.isSelected then
		arg_31_0.isAnimated_ = true

		arg_31_0:deletePartner(arg_31_1.hero)
	elseif not arg_31_1.isSelected and arg_31_0:checkHeroValid(arg_31_1.hero) then
		arg_31_0.isAnimated_ = true

		arg_31_0:addPartner(arg_31_1.hero)
	end
end

function var_0_0.deletePartner(arg_32_0, arg_32_1)
	if arg_32_1:getTableID() == arg_32_0.heroId then
		arg_32_0.isAnimated_ = false

		local var_32_0 = var_0_3:translation("BLOODLINE_INCUBUS_TIPS2")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_32_0
		})

		return
	end

	local var_32_1 = arg_32_0:getHeroCell(arg_32_1)
	local var_32_2, var_32_3 = arg_32_0:getTeamCell(arg_32_1)

	if not var_32_2 then
		return
	end

	var_32_2:retain()
	arg_32_0:removeItemFromTeamCells(arg_32_1)

	local var_32_4 = arg_32_0:getBottomItem(arg_32_1)

	if arg_32_0:scrollIfItemNotInviewRect(var_32_4, var_32_3) then
		arg_32_0:playRemoveBottomItem(var_32_2, var_32_4, var_32_1, var_32_3)
	else
		arg_32_0:playRemoveBottomItem(var_32_2, var_32_4, var_32_1, var_32_3)
	end
end

function var_0_0.addPartner(arg_33_0, arg_33_1)
	if #arg_33_0.teamCells_ >= var_0_5 then
		arg_33_0.isAnimated_ = false

		local var_33_0 = var_0_3:translation("BLOODLINE_INCUBUS_TIPS4")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_33_0
		})

		return
	end

	local var_33_1 = arg_33_0:getHeroCell(arg_33_1)

	if var_33_1 then
		arg_33_0:setHeroCellSelectedState(var_33_1)

		local var_33_2 = arg_33_0:initTeamCell(arg_33_1)

		table.insert(arg_33_0.teamCells_, var_33_2)
		arg_33_0:updateSelectProgressShow()

		local var_33_3 = arg_33_0.bottomItems_[#arg_33_0.teamCells_]

		arg_33_0:scrollToIthItem(#arg_33_0.teamCells_ - 3)
		arg_33_0:playAddTeamCellToBottomItem(var_33_2, var_33_3, var_33_1)
	end
end

function var_0_0.playAddTeamCellToBottomItem(arg_34_0, arg_34_1, arg_34_2, arg_34_3)
	local var_34_0 = arg_34_3:convertToWorldSpace(cc.p(0, 0))
	local var_34_1 = arg_34_2:convertToWorldSpace(cc.p(0, 0))

	var_34_1.x = var_34_1.x + arg_34_1:getContentSize().width / 2

	arg_34_1:pos(var_34_0.x, var_34_0.y)
	arg_34_1:setAnchorPoint(cc.p(0, 0))
	arg_34_1:addTo(arg_34_0)
	arg_34_1:setLocalZOrder(100)
	transition.stopTarget(arg_34_1)
	transition.moveTo(arg_34_1, {
		time = 0.19,
		x = var_34_1.x,
		y = var_34_1.y,
		onComplete = function()
			arg_34_1.isAnimated_ = false
			arg_34_3.isAnimated_ = false
			arg_34_0.isAnimated_ = false

			arg_34_1:retain()
			arg_34_1:removeFromParent()
			arg_34_1:addTo(arg_34_2)

			arg_34_2.hero = arg_34_1.hero

			arg_34_1:setPosition(cc.p(16, 1))
			arg_34_1:setTouchEnabled(true)
			arg_34_1:setTouchSwallowEnabled(false)
			arg_34_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_36_0)
				if arg_36_0.name == "began" then
					arg_34_0.scrollViewMoved_ = false
				elseif arg_36_0.name == "ended" and arg_34_0.scrollViewMoved_ ~= true then
					arg_34_0.isAnimated_ = true

					arg_34_0:deletePartner(arg_34_1.hero)
				end

				return true
			end)
		end
	})
end

function var_0_0.playRemoveBottomItem(arg_37_0, arg_37_1, arg_37_2, arg_37_3, arg_37_4)
	local var_37_0 = arg_37_2:convertToWorldSpace(cc.p(0, 0))

	var_37_0.x = var_37_0.x + arg_37_1:getContentSize().width / 2

	if var_37_0.x < 165 then
		var_37_0.x = 165
	elseif var_37_0.x > 1100 then
		var_37_0.x = 1100
	end

	local var_37_1 = arg_37_0:nodeByName("list_layer")
	local var_37_2 = cc.p(var_37_1:getPosition())

	arg_37_1:removeFromParent()
	arg_37_1:pos(var_37_0.x, var_37_0.y)
	arg_37_1:setAnchorPoint(cc.p(0, 0))
	arg_37_1:addTo(arg_37_0)
	arg_37_1:setLocalZOrder(100)
	transition.stopTarget(arg_37_1)

	if not tolua.isnull(arg_37_3) then
		var_37_2 = arg_37_3:convertToWorldSpace(cc.p(0, 0))
		layout = arg_37_3:getChildByName("layout")

		local var_37_3 = layout:getChildByName("avatar_mask")
		local var_37_4 = layout:getChildByName("chosen")

		var_37_3:setVisible(false)
		var_37_4:setVisible(false)

		arg_37_3.isSelected = false
	end

	arg_37_0:removeItem(arg_37_2, arg_37_4)
	arg_37_0:moveFadeOutAction(var_37_2.x, var_37_2.y, arg_37_1, function()
		arg_37_0:removeItemFromTeamCells(arg_37_1.hero)

		arg_37_0.isAnimated_ = false
	end)
end

function var_0_0.removeItemFromTeamCells(arg_39_0, arg_39_1)
	for iter_39_0 = 1, #arg_39_0.teamCells_ do
		local var_39_0 = arg_39_0.teamCells_[iter_39_0]

		if tolua.isnull(var_39_0) or var_39_0.hero:getTableID() == arg_39_1:getTableID() then
			table.remove(arg_39_0.teamCells_, iter_39_0)
		end
	end

	arg_39_0:updateSelectProgressShow()
end

function var_0_0.getHeroCell(arg_40_0, arg_40_1)
	for iter_40_0 = 1, #arg_40_0.heroCells_ do
		local var_40_0 = arg_40_0.heroCells_[iter_40_0]

		if not tolua.isnull(var_40_0) and var_40_0.hero:getTableID() == arg_40_1:getTableID() and not tolua.isnull(var_40_0) then
			return var_40_0
		end
	end

	return nil
end

function var_0_0.getTeamCell(arg_41_0, arg_41_1)
	for iter_41_0 = 1, #arg_41_0.teamCells_ do
		local var_41_0 = arg_41_0.teamCells_[iter_41_0]

		if var_41_0.hero:getTableID() == arg_41_1:getTableID() and not tolua.isnull(var_41_0) then
			return var_41_0, iter_41_0
		end
	end

	return nil
end

function var_0_0.getBottomItem(arg_42_0, arg_42_1)
	for iter_42_0 = 1, #arg_42_0.bottomItems_ do
		local var_42_0 = arg_42_0.bottomItems_[iter_42_0]

		if var_42_0.hero and var_42_0.hero:getTableID() == arg_42_1:getTableID() and not tolua.isnull(var_42_0) then
			return var_42_0
		end
	end

	return nil
end

function var_0_0.removeItem(arg_43_0, arg_43_1, arg_43_2)
	arg_43_1.hero = nil

	arg_43_0.bottomList_:removeItem(arg_43_1, true)
	arg_43_0:setOrgPositonX()
	var_0_2.performWithDelayGlobal(function()
		if not arg_43_0 or tolua.isnull(arg_43_0) then
			return
		end

		for iter_44_0 = 1, #arg_43_0.bottomItems_ do
			if arg_43_0.bottomItems_[iter_44_0] == arg_43_1 then
				table.remove(arg_43_0.bottomItems_, iter_44_0)

				break
			end
		end

		arg_43_0:addNewBottomItem()
		arg_43_0.bottomList_:reload()

		if arg_43_2 >= var_0_7 then
			arg_43_0:scrollToOrgPositonX(true)
		else
			arg_43_0:scrollToOrgPositonX()
		end
	end, 0.19)
end

function var_0_0.scrollIfItemNotInviewRect(arg_45_0, arg_45_1, arg_45_2)
	if not arg_45_0.bottomList_:isItemInViewRect(arg_45_1) then
		if arg_45_2 > math.ceil(math.abs(arg_45_0.bottomList_:getScrollNode():getPositionX()) / 152) then
			arg_45_0:scrollToIthItem(arg_45_2 - 4)
		else
			arg_45_0:scrollToIthItem(arg_45_2)
		end

		return true
	elseif #arg_45_0.teamCells_ < var_0_7 then
		arg_45_0:scrollToIthItem(1)
	end

	return false
end

function var_0_0.getHeroCells(arg_46_0, arg_46_1)
	for iter_46_0 = 1, #arg_46_0.heroCells_ do
		if arg_46_0.heroCells_[iter_46_0].hero:getTableID() == arg_46_1:getTableID() and not tolua.isnull(arg_46_0.heroCells_[iter_46_0]) then
			return arg_46_0.heroCells_[iter_46_0]
		end
	end

	return nil
end

function var_0_0.moveFadeOutAction(arg_47_0, arg_47_1, arg_47_2, arg_47_3, arg_47_4)
	arg_47_0:widgetSet(arg_47_3)
	arg_47_3:setCascadeOpacityEnabled(true)

	local var_47_0 = cc.Spawn:create(cc.FadeOut:create(0.2), cc.MoveTo:create(0.3, cc.p(arg_47_1, arg_47_2)))

	arg_47_3:runActionOnce(var_47_0, true, arg_47_4)
end

function var_0_0.widgetSet(arg_48_0, arg_48_1)
	for iter_48_0, iter_48_1 in ipairs(arg_48_1:getChildren()) do
		if iter_48_1 ~= nil then
			iter_48_1:setCascadeOpacityEnabled(true)
			arg_48_0:widgetSet(iter_48_1)
		end
	end
end

function var_0_0.checkHeroValid(arg_49_0, arg_49_1)
	for iter_49_0, iter_49_1 in pairs(arg_49_0.teamCells_) do
		if arg_49_1:getTableID() == iter_49_1.hero:getTableID() or xyd.tables.hero:beforeAwaken(arg_49_1:getTableID()) == iter_49_1.hero:getTableID() or xyd.tables.hero:afterAwaken(arg_49_1:getTableID()) == iter_49_1.hero:getTableID() then
			return false
		end
	end

	return true
end

function var_0_0.canHeroJoinBattle(arg_50_0, arg_50_1)
	return true
end

function var_0_0.scrollListener(arg_51_0, arg_51_1)
	if arg_51_1.name == "began" then
		arg_51_0.scrollViewMoved_ = false
		arg_51_0.prevX_ = arg_51_1.x
	elseif arg_51_1.name == "moved" and 5 <= math.abs(arg_51_1.x - arg_51_0.prevX_) then
		arg_51_0.scrollViewMoved_ = true
	end
end

return var_0_0
