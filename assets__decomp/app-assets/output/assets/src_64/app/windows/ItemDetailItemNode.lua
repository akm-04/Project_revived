local var_0_0 = class("ItemDetailItemNode", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation

var_0_0.BACKGROUD = "background"
var_0_0.ICON = "icon"
var_0_0.ICONBODY = "icon_body"
var_0_0.NAME = "name"
var_0_0.CHAPTER = "chapter"
var_0_0.CHAPTERSUPER = "chapter_super"
var_0_0.CONSTRACT = "constract"
var_0_0.BACKGROUDITEM = "background_item"

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.background = arg_2_0.contentView_:nodeByName(var_0_0.BACKGROUD)
	arg_2_0.iconBody = arg_2_0.contentView_:nodeByName(var_0_0.ICONBODY)
	arg_2_0.icon = arg_2_0.contentView_:nodeByName(var_0_0.ICON)
	arg_2_0.getWayTable = xyd.tables.heroGetWayTable

	arg_2_0.icon:removeAllChildren()
	arg_2_0.iconBody:removeAllChildren()

	arg_2_0.nameTxt = arg_2_0.contentView_:nodeByName(var_0_0.NAME)
	arg_2_0.chapterTxt = arg_2_0.contentView_:nodeByName(var_0_0.CHAPTER)
	arg_2_0.chapterSuperTxt = arg_2_0.contentView_:nodeByName(var_0_0.CHAPTERSUPER)
	arg_2_0.constractTxt = arg_2_0.contentView_:nodeByName(var_0_0.CONSTRACT)
	arg_2_0.scrollViewMoved_ = false
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.itemID = arg_3_1.itemID
	arg_3_0.heroID = arg_3_1.heroID
	arg_3_0.quality = arg_3_1.quality
	arg_3_0.chapter = arg_3_1.chapter
	arg_3_0.campaignName = arg_3_1.campaignName
	arg_3_0.campaignIcon = arg_3_1.campaignIcon
	arg_3_0.isInscription = arg_3_1.isInscription
	arg_3_0.petFloor = arg_3_1.petFloor
	arg_3_0.getWayID = arg_3_1.getWayID
	arg_3_0.campaignType = arg_3_1.campaignType

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUD):setVisible(false)
	arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUDITEM):setVisible(true)

	local var_4_0 = arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUD):getHeight()
	local var_4_1 = arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUD):getWidth()

	if arg_4_0.itemID ~= nil and arg_4_0.itemID > 0 then
		xyd.setItemBorder(arg_4_0.iconBody, arg_4_0.itemID)
		arg_4_0.background:height(var_4_0 - 20)
		arg_4_0.nameTxt:setString(xyd.tables.item:name(arg_4_0.itemID))
	elseif arg_4_0.heroID ~= nil and arg_4_0.heroID > 0 then
		xyd.setAvatarBorder(arg_4_0.heroID, arg_4_0.iconBody, arg_4_0.quality, 0)
		arg_4_0.background:height(var_4_0 - 20)
		arg_4_0.nameTxt:setString(xyd.tables.hero:name(arg_4_0.heroID))
	elseif arg_4_0.chapter ~= nil and arg_4_0.chapter > 0 or arg_4_0.petFloor or arg_4_0.isInscription then
		arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUD):setVisible(true)
		arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUDITEM):setVisible(false)

		if arg_4_0.petFloor then
			arg_4_0.chapterTxt:setString(string.format(var_0_1:translation("SKYCITY_LEVEL_BAG"), arg_4_0.petFloor))
		elseif arg_4_0.isInscription then
			arg_4_0.chapterTxt:setString(var_0_1:translation("INSCRIPTION_CENTRE"))
		else
			arg_4_0.chapterTxt:setString(string.format(var_0_1:translation("TEAM_CHAPTER"), arg_4_0.chapter))

			if arg_4_0.campaignType - 1 == xyd.CampaignType.SUPER then
				arg_4_0.chapterSuperTxt:setString(var_0_1:translation("SUPER"))
			elseif arg_4_0.campaignType - 1 == xyd.CampaignType.CHALLENGE then
				arg_4_0.chapterSuperTxt:setString(var_0_1:translation("CHALLENGE"))
			end

			arg_4_0.constractTxt:setString(arg_4_0.campaignName)
		end

		local var_4_2 = xyd.AssetLoader.get():loadSprite(arg_4_0.campaignIcon)
		local var_4_3 = arg_4_0.contentView_:nodeByName(var_0_0.ICON):getHeight()
		local var_4_4 = arg_4_0.contentView_:nodeByName(var_0_0.ICON):getWidth()
		local var_4_5 = var_4_3 / var_4_2:getHeight()
		local var_4_6 = var_4_4 / var_4_2:getWidth()

		if var_4_6 < var_4_5 then
			var_4_5 = var_4_6
		end

		var_4_2:setScale(var_4_5)
		arg_4_0.icon:addChild(var_4_2)
		var_4_2:setPosition(var_4_4 / 2, var_4_3 / 2)
		var_4_2:setAnchorPoint(cc.p(0.5, 0.5))
		arg_4_0.background:width(var_4_1)
	elseif arg_4_0.getWayID ~= nil then
		arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUD):setVisible(true)
		arg_4_0.contentView_:nodeByName(var_0_0.BACKGROUDITEM):setVisible(false)

		local var_4_7 = arg_4_0.getWayTable:getIcon(arg_4_0.getWayID)
		local var_4_8 = xyd.AssetLoader:get():loadSprite(var_4_7)
		local var_4_9 = arg_4_0.contentView_:nodeByName(var_0_0.ICON):getHeight()
		local var_4_10 = arg_4_0.contentView_:nodeByName(var_0_0.ICON):getWidth()
		local var_4_11 = var_4_9 / var_4_8:getHeight()
		local var_4_12 = var_4_10 / var_4_8:getWidth()

		if var_4_12 < var_4_11 then
			var_4_11 = var_4_12
		end

		var_4_8:setScale(var_4_11)
		var_4_8:setAnchorPoint(cc.p(0.5, 0.5))

		local var_4_13 = arg_4_0.icon:getContentSize().width / 2

		var_4_8:addTo(arg_4_0.icon)
		var_4_8:setPosition(cc.p(var_4_13, var_4_13))
		arg_4_0.chapterTxt:setString(arg_4_0.getWayTable:getName(arg_4_0.getWayID))
		arg_4_0.constractTxt:setString(arg_4_0.getWayTable:getDesc(arg_4_0.getWayID))
		arg_4_0.background:width(var_4_1)
		arg_4_0.background:setVisible(true)
	end
end

function var_0_0.contentView(arg_5_0)
	if arg_5_0.contentView_ == nil then
		arg_5_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_5_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/backpack_window/item_detail_item_node.csb"))
		arg_5_0.contentView_:addTo(arg_5_0)
		arg_5_0.contentView_:setTouchSwallowEnabled(false)
		arg_5_0.contentView_:setAnchorPoint(cc.p(0.5, 0.5))
	end

	return arg_5_0.contentView_
end

return var_0_0
