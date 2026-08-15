local var_0_0 = class("LuckybagOpenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation
local var_0_3 = 10

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.thirdAnni = xyd.ModelManager.get():loadModel(xyd.ModelType.THIRD_ANNIVERSARY)
	arg_1_0.signUseNum = 0
	arg_1_0.bagType = arg_1_2.type
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	var_0_0.super:didOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = xyd.tables.AnniLuckybagTable:key(arg_3_0.bagType)

	arg_3_0:nodeByName("num"):setString(arg_3_0.signUseNum)
	arg_3_0:nodeByName("tic_coler"):setString(var_0_2:translation("LUCKYBAG_COLOR_" .. tostring(arg_3_0.bagType)))
	arg_3_0:nodeByName("bag_size"):setString(var_0_2:translation("LUCKYBAG_" .. tostring(arg_3_0.bagType)))
	arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("LUCKYBAG_TXT_9"))
	arg_3_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 2)

	local var_3_1 = xyd.AssetLoader.get():loadSprite("windows/anniversary3rd/lucky_bag/sign_" .. tostring(arg_3_0.bagType) .. ".png")

	arg_3_0:nodeByName("sign_node"):addChild(var_3_1)

	local var_3_2 = arg_3_0:nodeByName("line"):getContentSize()
	local var_3_3 = var_0_1.new({
		size = var_3_2.width
	})

	var_3_3:addTo(arg_3_0:nodeByName("line"))
	var_3_3:setAnchorPoint(0.5, 0.5)
	var_3_3:setPosition(cc.p(var_3_2.width / 2, 2))

	for iter_3_0 = 1, 4 do
		arg_3_0:nodeByName("txt_" .. iter_3_0):setString(var_0_2:translation("LUCKYBAG_TEXT" .. iter_3_0))
	end

	arg_3_0:nodeByName("btn_add"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_add"):setScale(0.9)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_add"):setScale(1)

			local var_4_0 = arg_3_0.signUseNum + 1

			if var_4_0 > var_0_3 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LUCKYBAG_USE_MAX")
				})

				return
			end

			if var_4_0 > arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_0) then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LUCKYBAG_USE_LIMIT")
				})

				return
			end

			arg_3_0.signUseNum = var_4_0

			arg_3_0:nodeByName("num"):setString(arg_3_0.signUseNum)
		end
	end)
	arg_3_0:nodeByName("btn_sub"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("btn_sub"):setScale(0.9)
		elseif arg_5_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("btn_sub"):setScale(1)

			local var_5_0 = arg_3_0.signUseNum - 1

			if var_5_0 < 0 then
				return
			end

			arg_3_0.signUseNum = var_5_0

			arg_3_0:nodeByName("num"):setString(arg_3_0.signUseNum)
		end
	end)
	arg_3_0:nodeByName("open"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			arg_3_0:nodeByName("open"):setScale(0.9)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("open"):setScale(1)

			if not arg_3_0.signUseNum or arg_3_0.signUseNum <= 0 then
				return
			end

			local var_6_0 = {
				idx = arg_3_0.bagType,
				num = arg_3_0.signUseNum
			}

			arg_3_0.thirdAnni:getLuckybagAward(var_6_0, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					local var_7_0 = arg_3_0.selfPlayer:getBackpack()
					local var_7_1 = {
						itemID = var_3_0,
						itemNum = arg_3_0.signUseNum
					}

					var_7_0:removeItem(var_7_1)

					if arg_7_1 and arg_7_1.awards then
						local var_7_2 = {}

						arg_3_0.selfPlayer:handleRewardsWithoutShow(arg_7_1.awards)

						for iter_7_0, iter_7_1 in pairs(arg_7_1.awards) do
							if tonumber(iter_7_0) then
								table.insert(var_7_2, iter_7_1)
							end
						end

						local var_7_3 = {
							bagType = arg_3_0.bagType,
							useNum = arg_3_0.signUseNum,
							items = var_7_2
						}

						var_7_3.lastType = 100
						var_7_3.extraAward = arg_7_1.items

						for iter_7_2, iter_7_3 in pairs(var_7_2) do
							arg_3_0.selfPlayer:heroUpdateEvent_({
								name = xyd.event.HERO_UPDATE,
								params = iter_7_3
							}, true)
						end

						xyd.WindowManager.get():openWindow("luckybag_summon_result", var_7_3)
					end
				else
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_2:translation("ANNIVERSARY_OPENNING_FALSE")
					})
				end

				local var_7_4 = arg_3_0.selfPlayer:getBackpack():getItemNumByID(var_3_0)

				if var_7_4 < arg_3_0.signUseNum then
					arg_3_0.signUseNum = var_7_4
				end

				arg_3_0:nodeByName("num"):setString(arg_3_0.signUseNum)

				local var_7_5 = xyd.WindowManager.get():getWindow("luckybag_wnd")

				if var_7_5 and var_7_5.updateItemTxt then
					var_7_5:updateItemTxt()
				end
			end)
		end
	end)
	arg_3_0:initEditBox()
end

function var_0_0.initEditBox(arg_8_0)
	local var_8_0 = xyd.AssetLoader.get()
	local var_8_1 = arg_8_0:nodeByName("addcut")
	local var_8_2 = var_8_1:getContentSize()
	local var_8_3 = 24
	local var_8_4 = "windows/login/transparent.png"

	arg_8_0.editBox_ = ccui.EditBox:create(cc.size(var_8_2.width - 16, var_8_2.height - 8), var_8_4)

	arg_8_0.editBox_:setAnchorPoint(0.5, 0.5)
	arg_8_0.editBox_:setNormalizedPosition(cc.p(0.5, 0.5))
	arg_8_0.editBox_:addTo(var_8_1)
	arg_8_0.editBox_:setFont(var_8_0.FONT_NAME, var_8_3)
	arg_8_0.editBox_:setFontColor(cc.c3b(0, 0, 0))
	arg_8_0.editBox_:registerScriptEditBoxHandler(handler(arg_8_0, arg_8_0.inputboxEventHandler))
	arg_8_0.editBox_:setInputFlag(3)
end

function var_0_0.inputboxEventHandler(arg_9_0, arg_9_1)
	if arg_9_1 == "began" then
		arg_9_0.editBox_:setText("")
		arg_9_0:nodeByName("num"):setVisible(false)
	elseif arg_9_1 == "return" then
		local var_9_0 = arg_9_0.editBox_:getText()
		local var_9_1 = tonumber(var_9_0)

		arg_9_0.editBox_:setText("")
		arg_9_0:nodeByName("num"):setVisible(true)

		if var_9_0 ~= "" then
			if var_9_1 then
				local var_9_2 = xyd.tables.AnniLuckybagTable:key(arg_9_0.bagType)
				local var_9_3 = arg_9_0.selfPlayer:getBackpack():getItemNumByID(var_9_2)
				local var_9_4 = math.floor(var_9_1)

				if var_9_4 < 0 then
					local var_9_5 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_5
					})

					return
				elseif var_9_4 > var_0_3 then
					local var_9_6 = string.format(xyd.tables.translation:translation("LUCKYBAG_USE_MAX"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_6
					})

					return
				elseif var_9_3 < var_9_4 then
					local var_9_7 = string.format(xyd.tables.translation:translation("LUCKYBAG_USE_LIMIT"))

					xyd.WindowManager.get():openWindow("toast", {
						message = var_9_7
					})

					return
				else
					arg_9_0.signUseNum = var_9_4

					arg_9_0:nodeByName("num"):setString(arg_9_0.signUseNum)
				end

				return
			else
				local var_9_8 = string.format(xyd.tables.translation:translation("BAG_IMPORT_TIP"))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_9_8
				})

				return
			end
		end
	end
end

return var_0_0
