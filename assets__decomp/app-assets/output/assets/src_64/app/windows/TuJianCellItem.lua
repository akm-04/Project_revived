local var_0_0 = class("TuJianItem", function()
	return cc.Node:create()
end)

var_0_0.IMG_ICON = "img_icon"
var_0_0.NAME_TXT = "name"

local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Item")

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

	if arg_4_0.params.isHide == true then
		arg_4_0.iconImg = arg_4_0:contentView():nodeByName(var_0_0.IMG_ICON)

		arg_4_0.iconImg:removeAllChildren()

		local var_4_0 = xyd.AssetLoader.get():loadSprite("images/icon/black_bg.png")

		if var_4_0 then
			var_4_0:setAnchorPoint(cc.p(0.5, 0.5))

			local var_4_1 = arg_4_0.iconImg:getContentSize()

			var_4_0:setPosition(cc.p(var_4_1.width / 2, var_4_1.height / 2))
			arg_4_0.iconImg:addChild(var_4_0)
		end

		local var_4_2 = xyd.tables.item:level_visible(arg_4_0.params.itemID)

		arg_4_0:contentView():nodeByName(var_0_0.NAME_TXT):setString(string.format(var_0_1:translation("ITEM_OPEN"), var_4_2))
		arg_4_0:contentView():nodeByName(var_0_0.NAME_TXT):setColor(cc.c4b(151, 118, 78, 0))
	elseif arg_4_0.params.isHide == false then
		arg_4_0.iconImg = arg_4_0:contentView():nodeByName(var_0_0.IMG_ICON)

		arg_4_0.iconImg:removeAllChildren()
		xyd.setItemBorder(arg_4_0.iconImg, arg_4_0.params.itemID)

		local var_4_3 = xyd.tables.item:name(arg_4_0.params.itemID)

		arg_4_0:contentView():nodeByName(var_0_0.NAME_TXT):setString(var_4_3)
	end
end

function var_0_0.onClick(arg_5_0, arg_5_1, arg_5_2)
	arg_5_0.itemID = arg_5_1

	if arg_5_0.itemID ~= nil then
		local var_5_0 = var_0_2.new()

		var_5_0:populate({
			table_id = arg_5_0.itemID
		})

		if arg_5_0.params.isHide == true then
			local var_5_1 = var_0_1:translation("DID_NOT_OPEN_TIPS")
			local var_5_2 = cc.Director:getInstance():getWinSize()

			params = {
				message = var_5_1,
				pos = cc.p(var_5_2.width / 2 + 29, var_5_2.height / 2 + 10)
			}

			xyd.WindowManager.get():openWindow("toast", params)
		else
			xyd.WindowManager.get():openWindow("tujian_itemdetail", {
				item = var_5_0
			})
		end
	end
end

return var_0_0
