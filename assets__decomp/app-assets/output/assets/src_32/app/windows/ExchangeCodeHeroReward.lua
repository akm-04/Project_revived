local var_0_0 = class("ExchageCodeHeroReward", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.itemID = arg_1_2.itemID
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer(cc.c4b(0, 0, 0, 225))
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = xyd.tables.item:gifts(arg_4_0.itemID)
	local var_4_1 = arg_4_0:nodeByName("container")
	local var_4_2 = var_4_1:getHeight()
	local var_4_3

	for iter_4_0 = 1, #var_4_0 do
		local var_4_4 = var_4_0[iter_4_0]
		local var_4_5 = xyd.tables.gift:items(var_4_4)[1]
		local var_4_6 = var_0_2.new()

		var_4_6:populateWithTableID(var_4_5)

		local var_4_7 = xyd.getHeroCard(var_4_6)
		local var_4_8 = var_4_2 / var_4_7:getHeight()

		var_4_7:setScale(var_4_8)
		var_4_7:addTo(var_4_1)
		var_4_7:setAnchorPoint(cc.p(0, 0))
		var_4_7:setPosition((iter_4_0 - 1) * (var_4_7:getWidth() * var_4_8 + 40), 0)
		arg_4_0:nodeByName("choose_" .. iter_4_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			xyd.buttonScaleAnim(arg_4_0:nodeByName("choose_" .. iter_4_0), arg_5_1)

			if arg_5_1 == ccui.TouchEventType.ended then
				xyd.playButtonSound()

				local var_5_0 = {
					item_id = arg_4_0.itemID,
					gift_id = var_4_4
				}

				xyd.Backend.get():request(xyd.mid.EXCHAGE_CODE_HERO, var_5_0, function(arg_6_0, arg_6_1)
					if arg_6_0 == xyd.error.OK then
						local var_6_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
						local var_6_1 = {
							itemNum = 1,
							itemID = var_5_0.item_id
						}

						var_6_0:getBackpack():removeItem(var_6_1)
						var_6_0:handleRewards(arg_6_1.awards)
						xyd.WindowManager.get():closeWindow(arg_4_0.name)

						local var_6_2 = xyd.WindowManager.get():getWindow("backpack")

						if var_6_2 then
							var_6_2:updateItemDetail(var_5_0.item_id)
							var_6_2:refreshDisplayOption()
						end
					end
				end)
			end
		end)
	end
end

function var_0_0.willClose(arg_7_0, arg_7_1)
	var_0_0.super:willClose(arg_7_1)
end

return var_0_0
