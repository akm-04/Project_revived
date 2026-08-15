local var_0_0 = class("EquipItem", function()
	return cc.Node:create()
end)
local var_0_1 = import("app.model.Item")

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/fumo_window/fumo_equip.csb"))
		arg_3_0.contentView_:addTo(arg_3_0):setAnchorPoint(0.5, 0.5)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.item_ = var_0_1.new()

	arg_4_0.item_:populate(arg_4_1:toParams())

	if arg_4_1:isCollected() then
		local var_4_0 = arg_4_1:getMaxFumoStar()
		local var_4_1 = arg_4_1:getFumoLev()

		if var_4_0 <= 0 then
			arg_4_0:contentView():nodeByName("stars"):setVisible(false)
		else
			for iter_4_0 = 1, var_4_0 do
				if iter_4_0 <= var_4_1 then
					arg_4_0:contentView():nodeByName("light_star" .. iter_4_0):setVisible(true)
					arg_4_0:contentView():nodeByName("gray_star" .. iter_4_0):setVisible(false)
				else
					arg_4_0:contentView():nodeByName("light_star" .. iter_4_0):setVisible(false)
					arg_4_0:contentView():nodeByName("gray_star" .. iter_4_0):setVisible(true)
				end
			end

			for iter_4_1 = var_4_0 + 1, 5 do
				arg_4_0:contentView():nodeByName("light_star" .. iter_4_1):setVisible(false)
				arg_4_0:contentView():nodeByName("gray_star" .. iter_4_1):setVisible(false)
			end
		end

		xyd.setItemBorder(arg_4_0:contentView():nodeByName("equip"), arg_4_1:getTableID(), false)
	else
		arg_4_0:contentView():nodeByName("stars"):setVisible(false)
	end
end

function var_0_0.addItem(arg_5_0, arg_5_1)
	local var_5_0 = xyd.tables.item:moneng(arg_5_1.itemID)

	arg_5_0.item_.moneng_ = arg_5_0.item_.moneng_ + var_5_0
end

function var_0_0.removeItem(arg_6_0, arg_6_1)
	local var_6_0 = xyd.tables.item:moneng(arg_6_1.itemID)

	arg_6_0.item_.moneng_ = arg_6_0.item_.moneng_ - var_6_0
end

function var_0_0.getEquipItem(arg_7_0)
	return arg_7_0.item_
end

return var_0_0
