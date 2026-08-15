local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = require("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	local var_2_1 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_2 = xyd.AssetLoader.get():loadSprite(var_2_1)
	local var_2_3, var_2_4 = var_2_0:getChildByName("title_pos"):getPosition()

	var_2_2:addTo(var_2_0)
	var_2_2:setPosition(var_2_3, var_2_4)

	arg_2_0.container = var_2_0:getChildByName("bg")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("go_btn")

	var_3_0:setTouchEnabled(true)
	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP):loadShopList({}, function()
				xyd.WindowManager.get():openWindow("shop", {
					shop_type = xyd.ShopType.NORMAL
				})
			end)
		end
	end)
end

return var_0_0
