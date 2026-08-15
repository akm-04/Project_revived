local var_0_0 = class("TuJianCellHero", function()
	return cc.Node:create()
end)

var_0_0.IMG_ICON = "img_icon"
var_0_0.NAME_TXT = "name"

local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_2_0)
	arg_2_0.player_ = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/tujian/tujianitem_.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.params = arg_4_1
	arg_4_0.iconImg = arg_4_0:contentView():nodeByName(var_0_0.IMG_ICON)

	arg_4_0.iconImg:removeAllChildren()
	xyd.setAvatarBorder(arg_4_0.params.hero, arg_4_0.iconImg, null, null, null, not arg_4_0.params.hero:isCollected())

	local var_4_0 = arg_4_0.params.hero:getName()

	arg_4_0:contentView():nodeByName(var_0_0.NAME_TXT):setString(var_4_0)
end

function var_0_0.onClick(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.hero
	local var_5_1 = xyd.tables.hero:stoneID(var_5_0:getTableID())

	xyd.WindowManager.get():openWindow("pet_stone", {
		hero = var_5_0,
		itemComposeID = var_5_1
	})
end

return var_0_0
