local var_0_0 = class("OccultCampaignDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.creatsCampaign
local var_0_3 = ngx.ctx.battle.getRequire("FighterModel")
local var_0_4 = import("app.model.Hero")
local var_0_5 = 752
local var_0_6 = 222

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignId = arg_1_2.campaign_id
	arg_1_0.campaignInfo = arg_1_0.occult.openCampaigns[tostring(arg_1_0.campaignId)]
	arg_1_0.monsterInfos = arg_1_2.monster_infos

	arg_1_0:sortMonsters()

	arg_1_0.subId = arg_1_0:getInitialSubId()
	arg_1_0.occultCampaignType = arg_1_0.occult:getRoomCampaignType()
end

function var_0_0.getInitialSubId(arg_2_0)
	local var_2_0 = arg_2_0.occult.openCampaigns[tostring(arg_2_0.campaignId)]

	for iter_2_0 = 1, #arg_2_0.monsterInfos do
		if var_2_0.is_win[iter_2_0] == 0 and var_2_0.in_battle[iter_2_0] == 0 then
			return iter_2_0
		end
	end

	return 1
end

function var_0_0.sortMonsters(arg_3_0)
	for iter_3_0 = 1, #arg_3_0.monsterInfos do
		table.sort(arg_3_0.monsterInfos[iter_3_0], function(arg_4_0, arg_4_1)
			return arg_4_0.partner_id < arg_4_1.partner_id
		end)
	end
end

function var_0_0.willOpen(arg_5_0, arg_5_1)
	var_0_0.super.willOpen(arg_5_0, arg_5_1)
	arg_5_0:layout()
	arg_5_0:addBlockLayer()
	arg_5_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_6_0)
	arg_6_0:nodeByName("enemy_defeated_text"):setString(var_0_1:translation("OCCLUT_TEXT_3"))
	arg_6_0:nodeByName("in_fighting_text"):setString(var_0_1:translation("OCCLUT_TEXT_4"))
	arg_6_0:nodeByName("text_single"):setString(var_0_1:translation("OCCLUT_TEXT_5"))
	arg_6_0:nodeByName("text_cooperate"):setString(var_0_1:translation("OCCLUT_TEXT_6"))
	arg_6_0:nodeByName("campaign_desc_text"):setString(var_0_1:translation("OCCULT_CAMPAIGN_DESC_TEXT"))
	arg_6_0:setButtonClick()

	local var_6_0 = xyd.AssetLoader:get():loadSprite("windows/occult/sub_map/mask.png")

	arg_6_0.clippingNode = cc.ClippingNode:create()

	arg_6_0.clippingNode:setStencil(var_6_0)
	arg_6_0.clippingNode:setInverted(true)
	arg_6_0.clippingNode:setAlphaThreshold(0)
	arg_6_0.clippingNode:addTo(arg_6_0:nodeByName("centre_container"))
	var_6_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_6_0:setPosition(arg_6_0:nodeByName("centre_container"):getWidth() / 2 - 1, arg_6_0:nodeByName("centre_container"):getHeight() / 2 + 4)
	arg_6_0:updateCampaignStageShow()

	if arg_6_0.occultCampaignType == xyd.OccultRoomType.SINGLE_PLAYER then
		arg_6_0:nodeByName("cooperate_btn"):setVisible(false)
		arg_6_0:nodeByName("single_btn"):setPositionX(arg_6_0:nodeByName("container"):getContentSize().width / 2)
	end
end

function var_0_0.updateCampaignStageShow(arg_7_0)
	arg_7_0.campaignInfo = arg_7_0.occult.openCampaigns[tostring(arg_7_0.campaignId)]

	if arg_7_0.subId <= 1 then
		arg_7_0:nodeByName("left_arrow"):setVisible(false)
	else
		arg_7_0:nodeByName("left_arrow"):setVisible(true)
	end

	if arg_7_0.subId >= #arg_7_0.monsterInfos then
		arg_7_0:nodeByName("right_arrow"):setVisible(false)
	else
		arg_7_0:nodeByName("right_arrow"):setVisible(true)
	end

	local var_7_0 = var_0_2:getFightId(arg_7_0.campaignId, arg_7_0.subId)

	arg_7_0.clippingNode:removeAllChildren()

	local var_7_1 = xyd.tables.creatsChapterSelect:campaignMap(arg_7_0.occult.baseInfo.chapter_id)
	local var_7_2 = xyd.AssetLoader.get():loadSprite(var_7_1)

	var_7_2:setPosition(cc.p(var_0_5 / 2, var_0_6 / 2))
	var_7_2:addTo(arg_7_0.clippingNode)

	if arg_7_0.campaignInfo.is_win[arg_7_0.subId] == 1 then
		arg_7_0:nodeByName("enemy_defeated_text"):setVisible(true)
	else
		arg_7_0:nodeByName("enemy_defeated_text"):setVisible(false)
	end

	if arg_7_0.campaignInfo.in_battle[arg_7_0.subId] > 0 then
		arg_7_0:nodeByName("in_fighting_text"):setVisible(true)
	else
		arg_7_0:nodeByName("in_fighting_text"):setVisible(false)
	end

	local var_7_3 = arg_7_0.monsterInfos[arg_7_0.subId]
	local var_7_4 = 120 * (3 - math.floor(#table.keys(var_7_3) / 2))
	local var_7_5 = {}

	for iter_7_0, iter_7_1 in pairs(var_7_3) do
		table.insert(var_7_5, iter_7_1.monster_id)
	end

	for iter_7_2, iter_7_3 in pairs(var_7_3) do
		local var_7_6 = var_0_4.new()

		var_7_6:populateWithTableID(iter_7_3.monster_id)

		local var_7_7 = xyd.tables.hero:modelID(iter_7_3.monster_id)
		local var_7_8 = xyd.tables.model:creatsUiScale(var_7_7) * 0.7
		local var_7_9 = var_0_3.new(var_7_6, var_7_8)

		var_7_9:addTo(arg_7_0.clippingNode)
		var_7_9:setPosition(cc.p(var_7_4 + 120 * (iter_7_2 - 1), 15))
		var_7_9:getHeroAnimation():idle(true)
		var_7_9:initHeaderView()
		var_7_9:setHPProgress(iter_7_3.hp / iter_7_3.total_hp)
		var_7_9:hideHeaderView(true)
		var_7_9.headerView_:setHPProgressVisible(true)
	end

	if arg_7_0.campaignInfo.is_win[arg_7_0.subId] == 1 or arg_7_0.campaignInfo.in_battle[arg_7_0.subId] > 0 then
		local var_7_10 = "windows/occult/sub_map/bg_mask.png"
		local var_7_11 = xyd.AssetLoader.get():loadSprite(var_7_10)

		var_7_11:addTo(arg_7_0.clippingNode)
		var_7_11:setPosition(var_0_5 / 2, var_0_6 / 2)
	end

	arg_7_0:nodeByName("title_txt"):setString(var_0_2:campaignName(arg_7_0.campaignId) .. "(" .. arg_7_0.subId .. "/" .. #arg_7_0.monsterInfos .. ")")
	arg_7_0:nodeByName("campaign_desc_txt"):setString(var_0_2:campaignDes(arg_7_0.campaignId))
	arg_7_0:nodeByName("campaign_desc_txt2"):setString(var_0_2:eventDes(arg_7_0.campaignId))
end

function var_0_0.setButtonClick(arg_8_0)
	arg_8_0:nodeByName("left_arrow"):setTouchEnabled(true)
	arg_8_0:nodeByName("left_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_0:nodeByName("left_arrow"):setScale(0.9)

			return true
		elseif arg_9_0.name == "ended" then
			xyd.playButtonSound()
			arg_8_0:nodeByName("left_arrow"):setScale(1)

			arg_8_0.subId = arg_8_0.subId - 1

			arg_8_0:updateCampaignStageShow()
		end
	end)
	arg_8_0:nodeByName("right_arrow"):setTouchEnabled(true)
	arg_8_0:nodeByName("right_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			arg_8_0:nodeByName("right_arrow"):setScale(0.9)

			return true
		elseif arg_10_0.name == "ended" then
			xyd.playButtonSound()
			arg_8_0:nodeByName("right_arrow"):setScale(1)

			arg_8_0.subId = arg_8_0.subId + 1

			arg_8_0:updateCampaignStageShow()
		end
	end)
	arg_8_0:nodeByName("cooperate_btn"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.campaignInfo.is_win[arg_8_0.subId] == 1 then
				local var_11_0 = var_0_1:translation("OCCULT_ENERY_DEFEATED_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_11_0
				})

				return
			end

			local var_11_1 = {
				campaign_id = arg_8_0.campaignId,
				sub_id = arg_8_0.subId
			}

			arg_8_0.occult:teamFightInvite(var_11_1, function(arg_12_0, arg_12_1)
				if arg_12_0 == xyd.error.OK then
					if arg_12_1.is_auto_pass then
						xyd.WindowManager.get():closeWindow(arg_8_0)

						return
					end

					var_11_1.monster_infos = arg_8_0.monsterInfos[arg_8_0.subId]

					xyd.WindowManager.get():openWindow("occult_cooperate_waiting", var_11_1)
				end
			end)
		end
	end)
	arg_8_0:nodeByName("single_btn"):addTouchEventListener(function(arg_13_0, arg_13_1)
		xyd.buttonScaleAnim(arg_13_0, arg_13_1)

		if arg_13_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.campaignInfo.is_win[arg_8_0.subId] == 1 then
				local var_13_0 = var_0_1:translation("OCCULT_ENERY_DEFEATED_TIP")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})

				return
			end

			local var_13_1 = {
				campaign_id = arg_8_0.campaignId,
				sub_id = arg_8_0.subId
			}

			arg_8_0.occult:prepareSingleFight(var_13_1, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK then
					if arg_14_1.is_auto_pass then
						xyd.WindowManager.get():closeWindow(arg_8_0)

						return
					end

					var_13_1.monsters_info = arg_8_0.monsterInfos[var_13_1.sub_id]

					xyd.WindowManager.get():openWindow("occult_select_team", var_13_1)
				end
			end)
		end
	end)
end

return var_0_0
