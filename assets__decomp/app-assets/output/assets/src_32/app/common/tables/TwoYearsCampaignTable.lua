local var_0_0 = class("TwoYearsCampaignTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.campaign_id_ = {}
	arg_1_0.campaign_type_ = {}
	arg_1_0.battle_id_ = {}
	arg_1_0.last_campaign_id_ = {}
	arg_1_0.next_campaign_id_ = {}
	arg_1_0.node_pos_x_ = {}
	arg_1_0.node_pos_y_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("activity_anni2_campaign.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.campaign_id)

		table.insert(arg_1_0.campaign_id_, var_2_0)

		arg_1_0.campaign_type_[var_2_0] = tonumber(arg_2_0.campaign_type)
		arg_1_0.battle_id_[var_2_0] = tonumber(arg_2_0.battle_id)
		arg_1_0.last_campaign_id_[var_2_0] = tonumber(arg_2_0.last_campaign_id)
		arg_1_0.next_campaign_id_[var_2_0] = tonumber(arg_2_0.next_campaign_id)
		arg_1_0.node_pos_x_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.node_pos_y_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.campaignIds(arg_3_0)
	return arg_3_0.campaign_id_
end

function var_0_0.campaignType(arg_4_0, arg_4_1)
	return arg_4_0.campaign_type_[arg_4_1]
end

function var_0_0.battleId(arg_5_0, arg_5_1)
	return arg_5_0.battle_id_[arg_5_1]
end

function var_0_0.lastCampaignId(arg_6_0, arg_6_1)
	return arg_6_0.last_campaign_id_[arg_6_1]
end

function var_0_0.nextCampaignId(arg_7_0, arg_7_1)
	return arg_7_0.next_campaign_id_[arg_7_1]
end

function var_0_0.posx(arg_8_0, arg_8_1)
	return arg_8_0.node_pos_x_[arg_8_1]
end

function var_0_0.posy(arg_9_0, arg_9_1)
	return arg_9_0.node_pos_y_[arg_9_1]
end

function var_0_0.icon(arg_10_0, arg_10_1)
	return arg_10_0.icon_[arg_10_1]
end

return var_0_0
