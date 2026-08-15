local var_0_0 = class("PetStoneCampaignItem", function()
	return cc.Node:create()
end)

var_0_0.CHAPTER = "chapter_txt"
var_0_0.CAMPAIGN_TYPE = "campaign_type_txt"
var_0_0.LEFT_TIMES = "left_times"
var_0_0.CAMPAIGN_NAME = "campaign_name"
var_0_0.ICON = "icon_node"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.chapter = arg_3_1.chapter
	arg_3_0.campaignType = arg_3_1.campaignType
	arg_3_0.leftTimes = arg_3_1.leftTimes
	arg_3_0.campaignName = arg_3_1.campaignName
	arg_3_0.campaignID = arg_3_1.campaignID
	arg_3_0.onlyName = arg_3_1.onlyName
	arg_3_0.monsters = xyd.tables.campaign:monsterDisplay(arg_3_0.campaignID)
	arg_3_0.stars = xyd.tables.campaign:monsterStar(arg_3_0.campaignID)
	arg_3_0.qualitys = xyd.tables.campaign:monsterQuality(arg_3_0.campaignID)
	arg_3_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_3_0.selfPlayer:loadWorldMap(function()
		arg_3_0.campaigns = arg_3_0.selfPlayer.worldMaps_
		arg_3_0.icon = arg_3_1.icon

		arg_3_0:layout()
	end)
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_5_0)
	arg_5_0.contentView_:nodeByName(var_0_0.CAMPAIGN_NAME):setString(arg_5_0.campaignName)

	if arg_5_0.onlyName == nil then
		arg_5_0.contentView_:nodeByName(var_0_0.CHAPTER):setString(string.format(var_0_1:translation("TEAM_CHAPTER"), arg_5_0.chapter))
		arg_5_0.contentView_:nodeByName(var_0_0.CAMPAIGN_TYPE):setString(var_0_1:translation("SUPER"))

		if arg_5_0.campaigns[arg_5_0.campaignID] and arg_5_0.campaigns[arg_5_0.campaignID].dailyLimit then
			local var_5_0 = arg_5_0.campaigns[arg_5_0.campaignID].dailyLimit
			local var_5_1 = string.format("（%d/3）", var_5_0)

			arg_5_0.contentView_:nodeByName("left_times"):setString(var_5_1)
		else
			arg_5_0.contentView_:nodeByName("left_times"):setString("（3/3）")
		end
	else
		arg_5_0.contentView_:nodeByName("left_times"):setString("")
		arg_5_0.contentView_:nodeByName(var_0_0.CAMPAIGN_NAME):setPositionY(arg_5_0.contentView_:nodeByName(var_0_0.CAMPAIGN_NAME):getPositionY() + 15)
		arg_5_0.contentView_:nodeByName(var_0_0.CHAPTER):setString("")
		arg_5_0.contentView_:nodeByName(var_0_0.CAMPAIGN_TYPE):setString("")
	end

	if arg_5_0.monsters and next(arg_5_0.monsters) and arg_5_0.monsters[#arg_5_0.monsters] > 0 then
		arg_5_0.contentView_:nodeByName(var_0_0.ICON):setScale(0.9)

		local var_5_2 = #arg_5_0.monsters

		xyd.setAvatarBorder(arg_5_0.monsters[var_5_2], arg_5_0.contentView_:nodeByName(var_0_0.ICON), arg_5_0.qualitys[var_5_2], arg_5_0.stars[var_5_2])
	elseif arg_5_0.icon then
		local var_5_3 = xyd.AssetLoader.get():loadSprite(arg_5_0.icon)
		local var_5_4 = arg_5_0.contentView_:nodeByName(var_0_0.ICON):getHeight()
		local var_5_5 = arg_5_0.contentView_:nodeByName(var_0_0.ICON):getWidth()
		local var_5_6 = var_5_4 / var_5_3:getHeight()
		local var_5_7 = var_5_5 / var_5_3:getWidth()

		if var_5_7 < var_5_6 then
			var_5_6 = var_5_7
		end

		var_5_3:setScale(var_5_6)
		arg_5_0.contentView_:nodeByName(var_0_0.ICON):addChild(var_5_3)
		var_5_3:setPosition(var_5_5 / 2, var_5_4 / 2)
		var_5_3:setAnchorPoint(cc.p(0.5, 0.5))
	end
end

function var_0_0.contentView(arg_6_0)
	if arg_6_0.contentView_ == nil then
		arg_6_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_6_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/pet/petMainWindow/stone_campaign.csb"))
		arg_6_0.contentView_:addTo(arg_6_0)
		arg_6_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_6_0.contentView_
end

return var_0_0
