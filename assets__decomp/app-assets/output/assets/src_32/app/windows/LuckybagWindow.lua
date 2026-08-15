local var_0_0 = class("LuckybagWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.AnniLuckybagTable
local var_0_3 = {
	open = var_0_1:translation("LUCKYBAG_TXT_1"),
	get_way = {
		var_0_1:translation("LUCKYBAG_TXT_2"),
		var_0_1:translation("LUCKYBAG_TXT_3"),
		var_0_1:translation("LUCKYBAG_TXT_4")
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.model = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	local function var_4_0(arg_5_0, arg_5_1)
		local var_5_0 = arg_5_1:getChildByName("container")

		var_5_0:getChildByName("txt_type"):setString(var_0_1:translation("LUCKYBAG_" .. arg_5_0))

		local var_5_1 = var_5_0:getChildByName("btn_open")
		local var_5_2 = "windows/anniversary3rd/lucky_bag/fudai_" .. arg_5_0 .. ".png"
		local var_5_3 = "windows/anniversary3rd/lucky_bag/fudai_" .. arg_5_0 .. ".png"

		var_5_1:loadTextures(var_5_2, var_5_3, nil, 0)
		var_5_1:addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.began then
				var_5_1:setScale(0.9)
			elseif arg_6_1 == ccui.TouchEventType.ended then
				var_5_1:setScale(1)
				xyd.WindowManager.get():openWindow("luckybag_present", {
					type = arg_5_0
				})
			end
		end)

		local var_5_4 = "windows/anniversary3rd/lucky_bag/sign_" .. arg_5_0 .. ".png"

		var_5_0:getChildByName("Ima_sign"):loadTexture(var_5_4)

		local var_5_5 = var_0_2:key(arg_5_0)
		local var_5_6 = arg_4_0.backpack:getItemNumByID(var_5_5)

		var_5_0:getChildByName("txt_sign_num"):setString(var_5_6 or 0)
		var_5_0:setName("container" .. arg_5_0)

		arg_4_0.children_[var_5_0:getName()] = var_5_0

		local var_5_7 = var_5_0:getChildByName("btn_pres")

		var_5_7:getChildByName("txt_pres"):setString(var_0_3.open)
		var_5_7:addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.began then
				var_5_7:setScale(0.9)
			elseif arg_7_1 == ccui.TouchEventType.ended then
				var_5_7:setScale(1)
				xyd.WindowManager.get():openWindow("luckybag_open", {
					type = arg_5_0
				})
			end
		end)

		local var_5_8 = var_5_0:getChildByName("get_way_btn")

		var_5_8:getChildByName("txt_get_way"):setString(var_0_3.get_way[arg_5_0])
		var_5_8:addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.began then
				var_5_8:setScale(0.9)
			elseif arg_8_1 == ccui.TouchEventType.ended then
				var_5_8:setScale(1)

				if arg_5_0 == 1 then
					xyd.WindowManager.get():openWindow("third_diglett_shop")
					xyd.WindowManager.get():closeWindow(arg_4_0)

					return
				end

				local function var_8_0(arg_9_0)
					if arg_9_0 then
						xyd.WindowManager.get():openWindow("luckybag_open", {
							type = arg_5_0 - 1
						})
					else
						if arg_5_0 == 2 then
							arg_4_0.model:loadInfo(function(arg_10_0, arg_10_1)
								if arg_10_0 == xyd.error.OK then
									local var_10_0 = {
										isCanGetBag = arg_10_1.wish_info.is_awards,
										wishTimes = arg_10_1.wish_info.wish_times,
										energy = arg_10_1.wish_info.energy,
										energyLev = arg_10_1.wish_info.energy_lev
									}

									xyd.WindowManager.get():openWindow("wishing_wnd", var_10_0)
								end
							end)
						elseif arg_5_0 == 3 then
							local var_9_0 = {}

							var_9_0.windowState = true

							xyd.WindowManager.get():openWindow("vip_recharge", var_9_0)
						end

						xyd.WindowManager.get():closeWindow(arg_4_0)
					end
				end

				local var_8_1 = {
					fudai_id = arg_5_0,
					callback = var_8_0
				}

				xyd.WindowManager.get():openWindow("luckybag_get_way", var_8_1)
			end
		end)

		return arg_5_1
	end

	local var_4_1 = arg_4_0:nodeByName("container")
	local var_4_2 = var_0_2:getAllIds()

	for iter_4_0, iter_4_1 in ipairs(var_4_2) do
		local var_4_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/anniversary3rd/lucky_bag/fudai_item.csb")

		if var_4_3 then
			local var_4_4 = var_4_0(iter_4_1, var_4_3)

			var_4_1:addChild(var_4_4)
			var_4_4:setPosition((iter_4_1 - 1) * 313, 0)
		end
	end
end

function var_0_0.updateItemTxt(arg_11_0)
	for iter_11_0, iter_11_1 in ipairs(var_0_2:getAllIds()) do
		local var_11_0 = arg_11_0:nodeByName("container" .. iter_11_1)

		if var_11_0 then
			local var_11_1 = var_0_2:key(iter_11_1)
			local var_11_2 = arg_11_0.backpack:getItemNumByID(var_11_1) or 0

			var_11_0:getChildByName("txt_sign_num"):setString(var_11_2)

			local var_11_3 = transition.sequence({
				cc.ScaleTo:create(0.3, 1.5),
				cc.ScaleTo:create(0.3, 1)
			})
			local var_11_4 = cc.Spawn:create(var_11_3)

			var_11_0:getChildByName("txt_sign_num"):runAction(var_11_4)
		end
	end
end

return var_0_0
