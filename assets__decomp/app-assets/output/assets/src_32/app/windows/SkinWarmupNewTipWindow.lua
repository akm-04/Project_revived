local var_0_0 = class("SkinWarmupNewTipWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.activitySkinWarmUpNewTable

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.skinItem = xyd.tables.misc:getValue("activity_skin_warmup_new_item_id")
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = var_0_2:discountPoint(arg_4_0.skinItem)

	arg_4_0:nodeByName("text_1"):setString(string.format(var_0_1:translation("SKIN_WARMUP_NEW_TXT"), var_0_2:recharge(arg_4_0.skinItem), var_4_0[#var_4_0] * 10, var_0_2:exDiscount(arg_4_0.skinItem), var_0_2:price(arg_4_0.skinItem)))

	local var_4_1 = import("app.common.ui.SplitLine")
	local var_4_2 = arg_4_0:nodeByName("line")

	var_4_1.new({
		size = var_4_2:getWidth()
	}):addTo(var_4_2)

	local var_4_3 = var_0_2:price(arg_4_0.skinItem)

	for iter_4_0 = 1, 5 do
		for iter_4_1 = 1, 4 do
			local var_4_4 = arg_4_0:nodeByName("text_" .. iter_4_0 .. "_" .. iter_4_1)

			if iter_4_0 == 1 then
				var_4_4:setString(var_0_1:translation("ACTIVITY_WARM_UP_NEW_TABLE_TEXT_" .. iter_4_1))
			elseif iter_4_1 == 1 then
				var_4_4:setString(string.format(var_0_1:translation("ACTIVITY_DACALL_DISCOUNT"), var_4_0[iter_4_0 - 1] * 10))
			elseif iter_4_1 == 2 then
				var_4_4:setString(math.floor(var_4_3 * var_4_0[iter_4_0 - 1]))
			elseif iter_4_1 == 3 then
				var_4_4:setString(math.floor(var_4_3 * var_4_0[iter_4_0 - 1] - var_0_2:exDiscount(arg_4_0.skinItem)))
			elseif iter_4_1 == 4 then
				local var_4_5 = math.floor(var_4_3 * var_4_0[iter_4_0 - 1] - var_0_2:exDiscount(arg_4_0.skinItem))

				var_4_4:setString(var_4_3 - var_4_5)
			end
		end
	end
end

return var_0_0
