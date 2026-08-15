local var_0_0 = class("TrialTips", import("app.common.ui.BaseWindow"))

var_0_0.TITLE = "title_node"
var_0_0.DESC_BG = "tanchudi"
var_0_0.AWARD_TXT = "award_txt"
var_0_0.ITEM_NODE = "item_node"
var_0_0.OPEN_TXT = "open_guide_txt"
var_0_0.DESC_NODE = "desc_node"

local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.trialType = arg_1_2.trialType

	local var_1_0 = var_0_1:translation("NUM_7")

	arg_1_0.openDesc = string.gsub(arg_1_2.openStr, var_1_0, var_0_1:translation("DAY"))
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	local var_2_0 = xyd.tables.sound:getSound("ui_tips")

	audio.playSound(var_2_0, false)
	arg_2_0:layout()
	arg_2_0:addBlockLayer(cc.c4b(0, 0, 0, 0))
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = "images/text/trial_" .. arg_3_0.trialType .. ".png"
	local var_3_1 = xyd.AssetLoader.get():loadSprite(var_3_0)

	var_3_1:addTo(arg_3_0:nodeByName(var_0_0.TITLE))
	var_3_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_1:setPosition(20, 15)
	arg_3_0:nodeByName(var_0_0.OPEN_TXT):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_3_0:nodeByName(var_0_0.OPEN_TXT):setString(arg_3_0.openDesc)
	arg_3_0:nodeByName(var_0_0.AWARD_TXT):setString(var_0_1:translation("REWARD") .. var_0_1:translation("COLON"))

	local var_3_2 = {
		size = 20,
		color = cc.c3b(250, 230, 92)
	}
	local var_3_3 = xyd.AssetLoader.get():loadLabel(var_3_2)

	var_3_3:enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	var_3_3:setMaxLineWidth(380)
	var_3_3:y(30)
	var_3_3:setString(xyd.tables.trialConfig:desc(arg_3_0.trialType))
	var_3_3:addTo(arg_3_0:nodeByName(var_0_0.DESC_NODE))
	var_3_3:setAnchorPoint(cc.p(0, 1))
	arg_3_0:nodeByName(var_0_0.DESC_BG):height(var_3_3:getContentSize().height + 10)

	local var_3_4, var_3_5 = arg_3_0:nodeByName(var_0_0.OPEN_TXT):getPosition()

	arg_3_0:nodeByName(var_0_0.AWARD_TXT):setString(xyd.tables.translation:translation("MISSION_TEXT"))
	arg_3_0:nodeByName(var_0_0.AWARD_TXT):setPosition(var_3_4, var_3_5 - var_3_3:getContentSize().height - 50)

	local var_3_6, var_3_7 = arg_3_0:nodeByName(var_0_0.AWARD_TXT):getPosition()

	arg_3_0:nodeByName(var_0_0.ITEM_NODE):setPosition(var_3_6, var_3_7 - 40)

	local var_3_8 = xyd.tables.trialConfig:showItems(arg_3_0.trialType)
	local var_3_9 = math.ceil(#var_3_8 / 7)

	arg_3_0.listView = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 410, 60 * var_3_9),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	})

	arg_3_0.listView:addTo(arg_3_0:nodeByName(var_0_0.ITEM_NODE))
	arg_3_0.listView:setAnchorPoint(cc.p(0, 1))

	for iter_3_0 = 1, var_3_9 do
		local var_3_10 = arg_3_0.listView:newItem()
		local var_3_11 = display.newNode()

		for iter_3_1 = 1, 7 do
			local var_3_12 = (iter_3_0 - 1) * 7 + iter_3_1

			if var_3_12 <= #var_3_8 then
				local var_3_13 = display.newNode()

				var_3_13:setContentSize(55, 55)
				xyd.setItemBorder(var_3_13, var_3_8[var_3_12])
				var_3_11:addChild(var_3_13)
				var_3_13:setPosition((iter_3_1 - 1) * 58, 0)
				var_3_13:setAnchorPoint(cc.p(0, 0))
				var_3_13:ignoreAnchorPointForPosition(false)

				local var_3_14 = {
					id = var_3_8[var_3_12]
				}

				arg_3_0:addTips(var_3_13, var_3_14)
			end
		end

		var_3_11:setContentSize(320, 55)
		var_3_11:setAnchorPoint(cc.p(0.5, 0.5))
		var_3_10:addContent(var_3_11)
		var_3_10:setItemSize(320, 55)
		arg_3_0.listView:addItem(var_3_10)
	end

	arg_3_0.listView:reload()
	arg_3_0.listView.scrollNode:setPosition(-42, 0)
end

return var_0_0
