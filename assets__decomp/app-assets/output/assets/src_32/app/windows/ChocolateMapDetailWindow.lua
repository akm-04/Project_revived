local var_0_0 = class("ChocolateMapDetailWindow", import("app.windows.ActivityBaseMapDetailWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.campaignID = arg_1_2.campaignID
	arg_1_0.mapCampaignType = xyd.CampaignType.CHOCOLATE
	arg_1_0.star = arg_1_2.star
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:updateModelContainer()
	arg_2_0:updateEquipPanel()
	arg_2_0:updateEnemyPanel()
	arg_2_0:updateSweepPanel()
	arg_2_0:updateStarContainer()
	arg_2_0:updateCostContainer()
	arg_2_0:updateStartBtn()
	arg_2_0:updateTitleAndDesc()
	arg_2_0:layout()
end

function var_0_0.baseDefine(arg_3_0)
	arg_3_0.super.baseDefine(arg_3_0)

	arg_3_0.campaignTable = xyd.tables.chocolateCampaignTable
	arg_3_0.PANEL_EQUIP = "panel_equip"
	arg_3_0.PANEL_ENEMY = "panel_enemy"
	arg_3_0.PANEL_SWEEP = "panel_sweep"
	arg_3_0.PANEL_COST = "energy_container"
	arg_3_0.MODEL_CONTAINER = "model_container"
	arg_3_0.STAR_CONTAINER = "star_container"
	arg_3_0.START_BUTTON = "start"
	arg_3_0.TITLE = "title_pos"
	arg_3_0.DESC = "txt_desc"
	arg_3_0.TIPS = "tip"
	arg_3_0.EQUIP_TXT = "txt_equip"
	arg_3_0.ENEMY_TXT = "txt_enemy"
	arg_3_0.sweepItemID = xyd.tables.misc.activityChocolateCampaignSweepItem
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("sweep_num_txt"):setString(string.format(var_0_1:translation("MAP_SWEEP_NUM"), "10"))
	arg_4_0:nodeByName("sweep_num_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("sweep_num_txt"):getVirtualRenderer():setAdditionalKerning(-2)
	arg_4_0:nodeByName("sweep_txt"):setString(var_0_1:translation("MAP_SWEEP"))
	arg_4_0:nodeByName("sweep_txt"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	arg_4_0:nodeByName("sweep_txt"):getVirtualRenderer():setAdditionalKerning(-2)
	arg_4_0:setTouchSwallowEnabled(true)
	arg_4_0:addBlockLayerWithNoTouchEvent()
end

function var_0_0.updateSweepItemNum(arg_5_0)
	local var_5_0 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(arg_5_0.sweepItemID)
	local var_5_1 = var_0_1:translation("CHOCOLATE_MAP_SWEEP_TIP") .. tostring(var_5_0)

	arg_5_0:nodeByName(arg_5_0.PANEL_SWEEP):getChildByName("sweep_item_num"):setString(var_5_1)
end

return var_0_0
