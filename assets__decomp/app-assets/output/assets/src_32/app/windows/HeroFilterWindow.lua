local var_0_0 = class("HeroFilterWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = 0

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.showAwaken = arg_1_2
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.initData(arg_3_0)
	arg_3_0.herosPos = {
		0,
		0,
		0
	}
	arg_3_0.herosType = {
		0,
		0,
		0
	}
	arg_3_0.herosPower = {
		0,
		0,
		0,
		0
	}
	arg_3_0.herosAwaken = {
		0,
		0,
		0
	}

	if arg_3_0.selfPlayer.sortType > 0 then
		local var_3_0 = {}
		local var_3_1 = arg_3_0.selfPlayer.sortType
		local var_3_2 = 1

		while var_3_1 > 0 do
			var_3_0[var_3_2] = var_3_1 % 2
			var_3_2 = var_3_2 + 1
			var_3_1 = math.floor(var_3_1 / 2)
		end

		local var_3_3 = 1

		for iter_3_0 = 13, 1, -1 do
			if iter_3_0 <= 4 then
				if iter_3_0 == 4 then
					var_3_3 = 1
				end

				arg_3_0.herosPower[var_3_3] = var_3_0[iter_3_0]
			elseif iter_3_0 <= 7 then
				if iter_3_0 == 7 then
					var_3_3 = 1
				end

				arg_3_0.herosType[var_3_3] = var_3_0[iter_3_0]
			elseif iter_3_0 <= 10 then
				if iter_3_0 == 10 then
					var_3_3 = 1
				end

				if var_3_0[iter_3_0] then
					arg_3_0.herosPos[var_3_3] = var_3_0[iter_3_0]
				end
			elseif iter_3_0 <= 13 and var_3_0[iter_3_0] then
				arg_3_0.herosAwaken[var_3_3] = var_3_0[iter_3_0]
			end

			var_3_3 = var_3_3 + 1
		end
	else
		arg_3_0.herosPos = {
			1,
			1,
			1
		}
		arg_3_0.herosType = {
			1,
			1,
			1
		}
		arg_3_0.herosPower = {
			1,
			1,
			1,
			1
		}
		arg_3_0.herosAwaken = {
			1,
			1,
			1
		}
	end
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("title"):setString(var_0_1:translation("HERO_FILTER_TITLE"))

	if not arg_4_0.showAwaken then
		arg_4_0:nodeByName("awaken_des_words"):setVisible(false)
		arg_4_0:nodeByName("awaken"):setVisible(false)
		arg_4_0:nodeByName("top_des_words"):setPositionY(arg_4_0:nodeByName("top_des_words"):getPositionY() - 30)
		arg_4_0:nodeByName("mid_des_words"):setPositionY(arg_4_0:nodeByName("mid_des_words"):getPositionY() - 30)
		arg_4_0:nodeByName("bottom_des_words"):setPositionY(arg_4_0:nodeByName("bottom_des_words"):getPositionY() - 30)
		arg_4_0:nodeByName("top"):setPositionY(arg_4_0:nodeByName("top"):getPositionY() - 30)
		arg_4_0:nodeByName("middle"):setPositionY(arg_4_0:nodeByName("middle"):getPositionY() - 30)
		arg_4_0:nodeByName("bottom"):setPositionY(arg_4_0:nodeByName("bottom"):getPositionY() - 30)
	end

	arg_4_0:nodeByName("top_des_words"):setString(var_0_1:translation("HERO_FILTER_DES_1"))
	arg_4_0:nodeByName("mid_des_words"):setString(var_0_1:translation("HERO_FILTER_DES_2"))
	arg_4_0:nodeByName("bottom_des_words"):setString(var_0_1:translation("HERO_FILTER_DES_3"))
	arg_4_0:nodeByName("awaken_des_words"):setString(var_0_1:translation("HERO_FILTER_DES_4"))

	for iter_4_0, iter_4_1 in pairs(arg_4_0.herosPos) do
		arg_4_0:nodeByName("pos_words_" .. iter_4_0):setString(var_0_1:translation("HERO_FILTER_POS_" .. iter_4_0))
		arg_4_0:nodeByName("pos_kuang_" .. iter_4_0):setTouchEnabled(true)
		arg_4_0:nodeByName("pos_kuang_" .. iter_4_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
			if arg_5_0.name == "began" then
				return true
			elseif arg_5_0.name == "ended" then
				if arg_4_0.herosPos[iter_4_0] == var_0_2 then
					arg_4_0.herosPos[iter_4_0] = var_0_3

					arg_4_0:nodeByName("pos_selected_" .. iter_4_0):setVisible(false)
				else
					arg_4_0.herosPos[iter_4_0] = var_0_2

					arg_4_0:nodeByName("pos_selected_" .. iter_4_0):setVisible(true)
				end
			end
		end)
	end

	for iter_4_2, iter_4_3 in pairs(arg_4_0.herosType) do
		arg_4_0:nodeByName("type_words_" .. iter_4_2):setString(var_0_1:translation("HERO_FILTER_TYPE_" .. iter_4_2))
		arg_4_0:nodeByName("type_kuang_" .. iter_4_2):setTouchEnabled(true)
		arg_4_0:nodeByName("type_kuang_" .. iter_4_2):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				return true
			elseif arg_6_0.name == "ended" then
				if arg_4_0.herosType[iter_4_2] == var_0_2 then
					arg_4_0.herosType[iter_4_2] = var_0_3

					arg_4_0:nodeByName("type_selected_" .. iter_4_2):setVisible(false)
				else
					arg_4_0.herosType[iter_4_2] = var_0_2

					arg_4_0:nodeByName("type_selected_" .. iter_4_2):setVisible(true)
				end
			end
		end)
	end

	for iter_4_4, iter_4_5 in pairs(arg_4_0.herosPower) do
		arg_4_0:nodeByName("power_words_" .. iter_4_4):setString(var_0_1:translation("HERO_FILTER_POWER_" .. iter_4_4))
		arg_4_0:nodeByName("power_kuang_" .. iter_4_4):setTouchEnabled(true)
		arg_4_0:nodeByName("power_kuang_" .. iter_4_4):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" then
				if arg_4_0.herosPower[iter_4_4] == var_0_2 then
					arg_4_0.herosPower[iter_4_4] = var_0_3

					arg_4_0:nodeByName("power_selected_" .. iter_4_4):setVisible(false)
				else
					arg_4_0.herosPower[iter_4_4] = var_0_2

					arg_4_0:nodeByName("power_selected_" .. iter_4_4):setVisible(true)
				end
			end
		end)
	end

	for iter_4_6, iter_4_7 in pairs(arg_4_0.herosAwaken) do
		arg_4_0:nodeByName("awaken_words_" .. iter_4_6):setString(var_0_1:translation("HERO_FILTER_AWAKEN_" .. iter_4_6))
		arg_4_0:nodeByName("awaken_kuang_" .. iter_4_6):setTouchEnabled(true)
		arg_4_0:nodeByName("awaken_kuang_" .. iter_4_6):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
			if arg_8_0.name == "began" then
				return true
			elseif arg_8_0.name == "ended" then
				if arg_4_0.herosAwaken[iter_4_6] == var_0_2 then
					arg_4_0.herosAwaken[iter_4_6] = var_0_3

					arg_4_0:nodeByName("awaken_selected_" .. iter_4_6):setVisible(false)
				else
					arg_4_0.herosAwaken[iter_4_6] = var_0_2

					arg_4_0:nodeByName("awaken_selected_" .. iter_4_6):setVisible(true)
				end
			end
		end)
	end

	arg_4_0:nodeByName("ok_btn"):addTouchEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.TouchEventType.ended then
			xyd.playTabButtonSound()

			local var_9_0 = 0

			if arg_4_0.showAwaken then
				local var_9_1 = false

				for iter_9_0, iter_9_1 in pairs(arg_4_0.herosAwaken) do
					if iter_9_1 == var_0_2 then
						var_9_0 = var_9_0 + math.pow(2, #arg_4_0.herosAwaken - iter_9_0 + 10)
						var_9_1 = true
					end
				end

				if var_9_1 == false then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("HERO_FILTER_AWAKEN_TIP")
					})

					return true
				end
			end

			local var_9_2 = false

			for iter_9_2, iter_9_3 in pairs(arg_4_0.herosPos) do
				if iter_9_3 == var_0_2 then
					var_9_0 = var_9_0 + math.pow(2, #arg_4_0.herosPos - iter_9_2 + 7)
					var_9_2 = true
				end
			end

			if var_9_2 == false then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("HERO_FILTER_POS_TIP")
				})

				return true
			end

			local var_9_3 = false

			for iter_9_4, iter_9_5 in pairs(arg_4_0.herosType) do
				if iter_9_5 == var_0_2 then
					var_9_0 = var_9_0 + math.pow(2, #arg_4_0.herosType - iter_9_4 + 4)
					var_9_3 = true
				end
			end

			if var_9_3 == false then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("HERO_FILTER_TYPE_TIP")
				})

				return true
			end

			local var_9_4 = false

			for iter_9_6, iter_9_7 in pairs(arg_4_0.herosPower) do
				if iter_9_7 == var_0_2 then
					var_9_0 = var_9_0 + math.pow(2, #arg_4_0.herosPower - iter_9_6)
					var_9_4 = true
				end
			end

			if var_9_4 == false then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_1:translation("HERO_FILTER_POWER_TIP")
				})

				return true
			end

			arg_4_0.selfPlayer:saveHeroFilterType(var_9_0)
			xyd.WindowManager.get():closeWindow(arg_4_0)
		end
	end)
	arg_4_0:updateSelection()
end

function var_0_0.updateSelection(arg_10_0)
	for iter_10_0, iter_10_1 in pairs(arg_10_0.herosPos) do
		if iter_10_1 == var_0_2 then
			arg_10_0:nodeByName("pos_selected_" .. iter_10_0):setVisible(true)
		else
			arg_10_0:nodeByName("pos_selected_" .. iter_10_0):setVisible(false)
		end
	end

	for iter_10_2, iter_10_3 in pairs(arg_10_0.herosType) do
		if iter_10_3 == var_0_2 then
			arg_10_0:nodeByName("type_selected_" .. iter_10_2):setVisible(true)
		else
			arg_10_0:nodeByName("type_selected_" .. iter_10_2):setVisible(false)
		end
	end

	for iter_10_4, iter_10_5 in pairs(arg_10_0.herosPower) do
		if iter_10_5 == var_0_2 then
			arg_10_0:nodeByName("power_selected_" .. iter_10_4):setVisible(true)
		else
			arg_10_0:nodeByName("power_selected_" .. iter_10_4):setVisible(false)
		end
	end

	for iter_10_6, iter_10_7 in pairs(arg_10_0.herosAwaken) do
		if iter_10_7 == var_0_2 then
			arg_10_0:nodeByName("awaken_selected_" .. iter_10_6):setVisible(true)
		else
			arg_10_0:nodeByName("awaken_selected_" .. iter_10_6):setVisible(false)
		end
	end
end

function var_0_0.didOpen(arg_11_0, arg_11_1)
	var_0_0.super:didOpen(arg_11_1)
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super:willClose(arg_12_1)
end

return var_0_0
