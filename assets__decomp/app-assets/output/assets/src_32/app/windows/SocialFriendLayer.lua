local var_0_0 = class("SocialFriendLayer", function()
	return display.newLayer()
end)
local var_0_1 = import("app.common.ui.LayerMultiplex")
local var_0_2 = import(".FriendListLayer")
local var_0_3 = import(".FriendRequestLayer")
local var_0_4 = import(".AddFriendLayer")
local var_0_5 = 8
local var_0_6 = xyd.color.WHITE
local var_0_7 = xyd.color.FONT_G1

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.size_ = arg_2_1.size
	arg_2_0.viewConf_ = arg_2_1.viewConf

	if not arg_2_0.viewConf_ then
		arg_2_0.viewConf_ = {}
	end

	if not arg_2_0.viewConf_.friendDisplayOption then
		arg_2_0.viewConf_.friendDisplayOption = xyd.FriendDisplayOption.FRIEND_LIST
	end

	arg_2_0:initLayout()
	arg_2_0:refreshOption()
end

function var_0_0.initLayout(arg_3_0)
	local var_3_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/friend_layer.json")

	var_3_0:setPosition(cc.p(0, 0))
	arg_3_0:addChild(var_3_0)

	local var_3_1 = var_3_0:getChildByName("background")

	var_3_1:setContentSize(arg_3_0.size_)
	var_3_0:setContentSize(arg_3_0.size_)

	arg_3_0.menuLayer_ = var_3_1:getChildByName("menu_layer")
	arg_3_0.itemLayer_ = var_3_1:getChildByName("item_layer")

	local var_3_2 = arg_3_0.size_.width - arg_3_0.menuLayer_:getContentSize().width - var_0_5

	arg_3_0.itemLayer_:setContentSize(cc.size(var_3_2, arg_3_0.size_.height))

	local var_3_3 = xyd.tables.translation

	arg_3_0.menuLayer_:getChildByName("Label_friend_list"):setString(var_3_3:translation("FRIEND_LIST"))
	arg_3_0.menuLayer_:getChildByName("Label_friend_request"):setString(var_3_3:translation("FRIEND_REQUEST"))
	arg_3_0.menuLayer_:getChildByName("Label_add_friend"):setString(var_3_3:translation("ADD_FRIEND"))
	xyd.formatAllLabels(arg_3_0, function(arg_4_0)
		arg_4_0:enableShadow()
	end)
	arg_3_0:initOptions()
end

function var_0_0.initOptions(arg_5_0)
	arg_5_0.optionButtons_ = {}

	table.insert(arg_5_0.optionButtons_, arg_5_0.menuLayer_:getChildByName("Button_friend_list"))
	table.insert(arg_5_0.optionButtons_, arg_5_0.menuLayer_:getChildByName("Button_friend_request"))
	table.insert(arg_5_0.optionButtons_, arg_5_0.menuLayer_:getChildByName("Button_add_friend"))

	for iter_5_0 = 1, #arg_5_0.optionButtons_ do
		arg_5_0.optionButtons_[iter_5_0]:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.ended then
				xyd.playTabButtonSound()

				arg_5_0.viewConf_.friendDisplayOption = iter_5_0

				arg_5_0:refreshOption()
			end
		end)
	end

	arg_5_0.optionLabels_ = {}

	table.insert(arg_5_0.optionLabels_, arg_5_0.menuLayer_:getChildByName("Label_friend_list"))
	table.insert(arg_5_0.optionLabels_, arg_5_0.menuLayer_:getChildByName("Label_friend_request"))
	table.insert(arg_5_0.optionLabels_, arg_5_0.menuLayer_:getChildByName("Label_add_friend"))

	local var_5_0 = arg_5_0.itemLayer_:getContentSize()

	arg_5_0.itemLayers_ = {}

	local var_5_1 = var_0_2.new({
		size = var_5_0
	})

	table.insert(arg_5_0.itemLayers_, var_5_1)

	local var_5_2 = var_0_3.new({
		size = var_5_0
	})

	table.insert(arg_5_0.itemLayers_, var_5_2)

	local var_5_3 = var_0_4.new({
		size = var_5_0
	})

	table.insert(arg_5_0.itemLayers_, var_5_3)

	arg_5_0.friendLayers_ = var_0_1.new(arg_5_0.itemLayers_)

	arg_5_0.friendLayers_:setPosition(cc.p(0, 0))
	arg_5_0.friendLayers_:setContentSize(var_5_0)
	arg_5_0.itemLayer_:addChild(arg_5_0.friendLayers_)
end

function var_0_0.refreshOption(arg_7_0)
	for iter_7_0 = 1, #arg_7_0.optionButtons_ do
		if iter_7_0 == arg_7_0.viewConf_.friendDisplayOption then
			arg_7_0.optionButtons_[iter_7_0]:setBright(true)
			arg_7_0.optionLabels_[iter_7_0]:setTextColor(var_0_6)

			if arg_7_0.itemLayers_[iter_7_0].active then
				arg_7_0.itemLayers_[iter_7_0]:active()
			end
		else
			arg_7_0.optionButtons_[iter_7_0]:setBright(false)
			arg_7_0.optionLabels_[iter_7_0]:setTextColor(var_0_7)

			if arg_7_0.itemLayers_[iter_7_0].inactive then
				arg_7_0.itemLayers_[iter_7_0]:inactive()
			end
		end
	end

	arg_7_0.friendLayers_:switchTo(arg_7_0.viewConf_.friendDisplayOption)
end

return var_0_0
