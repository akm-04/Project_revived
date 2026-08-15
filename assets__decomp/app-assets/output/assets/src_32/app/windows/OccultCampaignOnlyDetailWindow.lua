local var_0_0 = class("OccultCampaignOnlyDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.creatsCampaign
local var_0_3 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.campaignId = arg_1_2.campaign_id
	arg_1_0.subId = 1
	arg_1_0.fightIds = var_0_2:getFightIds(arg_1_0.campaignId)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("campaign_desc_text"):setString(var_0_1:translation("OCCULT_CAMPAIGN_DESC_TEXT"))
	arg_3_0:nodeByName("title_txt"):setString(var_0_1:translation(""))
	arg_3_0:nodeByName("campaign_desc_txt"):setString(var_0_1:translation(""))
	arg_3_0:setButtonClick()
	arg_3_0:updateCampaignStageShow()
	arg_3_0:updateMonsters()
end

function var_0_0.setButtonClick(arg_4_0)
	arg_4_0:nodeByName("right_arrow"):setTouchEnabled(true)
	arg_4_0:nodeByName("right_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			arg_4_0:nodeByName("right_arrow"):setScale(0.9)

			return true
		elseif arg_5_0.name == "ended" then
			xyd.playButtonSound()
			arg_4_0:nodeByName("right_arrow"):setScale(1)

			arg_4_0.subId = arg_4_0.subId + 1

			arg_4_0:updateCampaignStageShow()
		end
	end)
	arg_4_0:nodeByName("left_arrow"):setTouchEnabled(true)
	arg_4_0:nodeByName("left_arrow"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
		if arg_6_0.name == "began" then
			arg_4_0:nodeByName("left_arrow"):setScale(0.9)

			return true
		elseif arg_6_0.name == "ended" then
			xyd.playButtonSound()
			arg_4_0:nodeByName("left_arrow"):setScale(1)

			arg_4_0.subId = arg_4_0.subId - 1

			arg_4_0:updateCampaignStageShow()
		end
	end)
end

function var_0_0.updateCampaignStageShow(arg_7_0)
	if arg_7_0.subId <= 1 then
		arg_7_0:nodeByName("left_arrow"):setVisible(false)
	else
		arg_7_0:nodeByName("left_arrow"):setVisible(true)
	end

	if arg_7_0.subId >= #arg_7_0.fightIds then
		arg_7_0:nodeByName("right_arrow"):setVisible(false)
	else
		arg_7_0:nodeByName("right_arrow"):setVisible(true)
	end

	arg_7_0.fightId = arg_7_0.fightIds[arg_7_0.subId]
	arg_7_0.monsterIds = xyd.tables.battle:fight1(arg_7_0.fightId)

	arg_7_0:updateMonsters()
	arg_7_0:nodeByName("title_txt"):setString(var_0_2:campaignName(arg_7_0.campaignId) .. "(" .. arg_7_0.subId .. "/" .. #arg_7_0.fightIds .. ")")
	arg_7_0:nodeByName("campaign_desc_txt"):setString(var_0_2:campaignDes(arg_7_0.campaignId))
	arg_7_0:nodeByName("campaign_desc_txt2"):setString(var_0_2:eventDes(arg_7_0.campaignId))
end

function var_0_0.updateMonsters(arg_8_0)
	arg_8_0:nodeByName("scroll"):removeAllChildren()

	local var_8_0 = 100 * (2 - math.floor(#arg_8_0.monsterIds / 2)) + 20

	for iter_8_0 = 1, #arg_8_0.monsterIds do
		local var_8_1 = arg_8_0.monsterIds[iter_8_0]
		local var_8_2 = arg_8_0:createListContent(var_8_1)

		var_8_2:addTo(arg_8_0:nodeByName("scroll"))
		var_8_2:setPositionX(var_8_0 + 100 * (iter_8_0 - 1))
	end
end

function var_0_0.createListContent(arg_9_0, arg_9_1)
	local var_9_0 = display.newNode()

	var_9_0:setContentSize(90, 90)

	local var_9_1 = var_0_3.new()

	var_9_1:populateWithTableID(arg_9_1)
	xyd.setAvatarBorderNewUI(var_9_1, var_9_0)

	return var_9_0
end

return var_0_0
