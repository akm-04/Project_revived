local var_0_0 = class("SuperRichChallengeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.activityRichCampaign

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.superRich = xyd.ModelManager.get():loadModel(xyd.ModelType.SUPER_RICH)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignIds = xyd.tables.activityRichCampaign:campaignIds()
	arg_1_0.pos = arg_1_2.pos
	arg_1_0.gridInfo = arg_1_2.info
	arg_1_0.stationType = arg_1_2.grid_type
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll)

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:setTouchType(false)
	arg_3_0.scrollList:reload()
	arg_3_0:setButtonClick()
	arg_3_0:scrollToIthItem(arg_3_0.superRich.fightInfo.lev - 2)
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				giftId = xyd.tables.misc.activityRichBattleReward,
				text = var_0_1:translation("ACTIVITY_RICH_BATTLE_RULE_TEXT")
			}

			xyd.WindowManager.get():openWindow("super_rich_rule", var_5_0)
		end
	end)
	arg_4_0:nodeByName("backpack_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local function var_6_0()
				local var_7_0 = var_0_1:translation("SUPER_RICH_CHALLENGE_THOUGH_TIP")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_7_0, function()
					local var_8_0 = {
						grid_type = arg_4_0.stationType,
						pos = arg_4_0.pos,
						idx = arg_4_0.superRich.fightInfo.lev
					}

					arg_4_0.superRich:monopolyUseCard(var_8_0, function(arg_9_0, arg_9_1)
						if arg_9_0 == xyd.error.OK then
							xyd.WindowManager.get():closeWindow(arg_4_0)
						end
					end)
				end, nil, nil, arg_4_0.colorMode)
			end

			local var_6_1 = {
				callback = var_6_0,
				use_type = {
					0,
					1,
					0
				}
			}
			local var_6_2 = xyd.WindowManager.get():openWindow("super_rich_backpack", var_6_1)

			var_6_2:setPosition(cc.p(1160, 130))
			var_6_2:addBlockLayer(cc.c4b(0, 0, 0, 0))
		end
	end)
end

function var_0_0.scrollListDelegate(arg_10_0, arg_10_1, arg_10_2, arg_10_3)
	if cc.ui.UIListView.COUNT_TAG == arg_10_2 then
		return #arg_10_0.campaignIds
	elseif cc.ui.UIListView.CELL_TAG == arg_10_2 then
		local var_10_0
		local var_10_1 = arg_10_0.scrollList:dequeueItem()

		if not var_10_1 then
			var_10_1 = arg_10_0.scrollList:newItem()
		else
			var_10_1:removeAllChildren(true)
		end

		local var_10_2 = arg_10_0:createListContent(arg_10_3)
		local var_10_3 = var_10_2:getWidth()
		local var_10_4 = var_10_2:getHeight()

		var_10_1:setItemSize(var_10_3, var_10_4)
		var_10_1:addContent(var_10_2)

		return var_10_1
	end
end

function var_0_0.scrollToIthItem(arg_11_0, arg_11_1)
	if arg_11_1 > #arg_11_0.campaignIds - 3 then
		arg_11_1 = #arg_11_0.campaignIds - 3
	end

	if arg_11_1 < 1 then
		arg_11_1 = 1
	end

	arg_11_0.scrollList:scrollTo(-(arg_11_1 - 1) * 300, 0)
end

function var_0_0.createListContent(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_0.superRich.fightInfo.lev
	local var_12_1 = arg_12_0.campaignIds[arg_12_1]
	local var_12_2 = display.newNode()
	local var_12_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/zillionaire/challenge/challenge_item.csb")
	local var_12_4 = var_12_3:getChildByName("container")
	local var_12_5 = var_0_2.new()

	var_12_5:populateWithTableID(var_0_3:monsterDisplay(var_12_1))

	local var_12_6 = var_12_5:getHeroModel()

	var_12_6:addTo(var_12_4:getChildByName("model_pos"))
	var_12_4:getChildByName("model_pos"):setScale(0.7)

	local var_12_7 = display.newNode()

	var_12_7:setContentSize(var_12_6:getContentSize())
	var_12_7:setAnchorPoint(cc.p(0.5, 0))
	var_12_7:setTouchEnabled(true)
	var_12_7:addTo(var_12_6)
	var_12_7:setPosition(0, 0)
	var_12_7:setTouchSwallowEnabled(false)
	var_12_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" and var_12_0 == arg_12_1 and not arg_12_0.scrollViewMoved_ then
			local var_13_0 = {
				type = xyd.SelectTeamType.SUPER_RICH_CHALLENGE,
				campaignType = xyd.CampaignType.SUPER_RICH_CHALLENGE,
				campaignID = var_12_1
			}

			var_13_0.battleID = var_0_3:battleId(var_13_0.campaignID)

			local var_13_1 = xyd.tables.battle:monsters(var_13_0.battleID)

			var_13_0.enemyHeroes = {}
			var_13_0.enemyPets = {}

			for iter_13_0, iter_13_1 in ipairs(var_13_1[1]) do
				if iter_13_0 < 6 then
					local var_13_2 = var_0_2.new()

					var_13_2:populateWithTableID(iter_13_1)
					table.insert(var_13_0.enemyHeroes, var_13_2)
				else
					local var_13_3 = var_0_2.new()

					var_13_3:populateWithTableID(iter_13_1)

					var_13_0.enemyPets = var_13_3
				end
			end

			var_13_0.showEnemy = true

			xyd.WindowManager.get():openWindow("battle_select_team", var_13_0):addBlockLayer(cc.c4b(0, 0, 0, 155))
		end
	end)

	for iter_12_0 = 1, 3 do
		var_12_4:getChildByName("platform" .. iter_12_0):setVisible(false)
	end

	if arg_12_1 < var_12_0 then
		var_12_4:getChildByName("platform" .. 2):setVisible(true)
	elseif arg_12_1 == var_12_0 then
		var_12_4:getChildByName("platform" .. 3):setVisible(true)
	else
		var_12_4:getChildByName("platform" .. 1):setVisible(true)
	end

	var_12_3:addTo(var_12_2)
	var_12_3:setAnchorPoint(cc.p(0, 0))
	var_12_2:setContentSize(var_12_4:getContentSize())
	var_12_3:setName("source")

	return var_12_2
end

function var_0_0.scrollListener(arg_14_0, arg_14_1)
	if arg_14_1.name == "began" then
		arg_14_0.scrollViewMoved_ = false
		arg_14_0.prevX_ = arg_14_1.x
	elseif arg_14_1.name == "moved" and 5 <= math.abs(arg_14_1.x - arg_14_0.prevX_) then
		arg_14_0.scrollViewMoved_ = true
	end
end

return var_0_0
