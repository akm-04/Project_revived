local var_0_0 = class("PetFilterWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = 0
local var_0_4 = {
	xyd.HeroAwakeType.AWAKE,
	xyd.HeroAwakeType.NO_AWAKE
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
	arg_3_0:initData()
	arg_3_0:layout()
end

function var_0_0.initData(arg_4_0)
	arg_4_0.petsHolyAttr = {
		0,
		0,
		0
	}
	arg_4_0.petsAwaken = {
		0,
		0
	}

	if arg_4_0.selfPlayer.petSortType then
		local var_4_0 = {}
		local var_4_1 = arg_4_0.selfPlayer.petSortType
		local var_4_2 = 1

		while var_4_1 > 0 do
			var_4_0[var_4_2] = var_4_1 % 2
			var_4_2 = var_4_2 + 1
			var_4_1 = math.floor(var_4_1 / 2)
		end

		local var_4_3 = 1

		for iter_4_0 = 5, 1, -1 do
			if iter_4_0 <= 3 then
				if iter_4_0 == 3 then
					var_4_3 = 1
				end

				arg_4_0.petsHolyAttr[var_4_3] = var_4_0[iter_4_0]
			elseif iter_4_0 <= 5 and var_4_0[iter_4_0] then
				arg_4_0.petsAwaken[var_4_3] = var_4_0[iter_4_0]
			end

			var_4_3 = var_4_3 + 1
		end
	else
		arg_4_0.petsHolyAttr = {
			1,
			1,
			1
		}
		arg_4_0.petsAwaken = {
			1,
			1
		}
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_title"):setString(var_0_1:translation("HERO_FILTER_TITLE"))
	arg_5_0:initButtons()
	arg_5_0:nodeByName("txt_attr"):setString(var_0_1:translation("PET_FILTER_DES_1"))
	arg_5_0:nodeByName("txt_awake"):setString(var_0_1:translation("PET_FILTER_DES_2"))

	for iter_5_0, iter_5_1 in pairs(arg_5_0.petsHolyAttr) do
		arg_5_0:nodeByName("check_attr_" .. iter_5_0):setTouchEnabled(true)
		arg_5_0:nodeByName("check_attr_" .. iter_5_0):addEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.CheckBoxEventType.selected then
				xyd.playButtonSound()

				arg_5_0.petsHolyAttr[iter_5_0] = var_0_2
			elseif arg_6_1 == ccui.CheckBoxEventType.unselected then
				xyd.playButtonSound()

				arg_5_0.petsHolyAttr[iter_5_0] = var_0_3
			end
		end)
	end

	for iter_5_2, iter_5_3 in pairs(arg_5_0.petsAwaken) do
		arg_5_0:nodeByName("txt_awake_" .. iter_5_2):setString(var_0_1:translation("PET_FILTER_TXT_AWAKE_" .. iter_5_2))
		arg_5_0:nodeByName("check_awake_" .. iter_5_2):setTouchEnabled(true)
		arg_5_0:nodeByName("check_awake_" .. iter_5_2):addEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.CheckBoxEventType.selected then
				xyd.playButtonSound()

				arg_5_0.petsAwaken[iter_5_2] = var_0_2
			elseif arg_7_1 == ccui.CheckBoxEventType.unselected then
				xyd.playButtonSound()

				arg_5_0.petsAwaken[iter_5_2] = var_0_3
			end
		end)
	end

	arg_5_0:updateSelection()
end

function var_0_0.initButtons(arg_8_0)
	arg_8_0:nodeByName("btn_close"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("btn_close"), arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended and not arg_8_0.isSummon then
			xyd.playButtonSound()
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
	arg_8_0:nodeByName("btn_ok"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_8_0:nodeByName("btn_ok"), arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended and not arg_8_0.isSummon then
			xyd.playButtonSound()

			local var_10_0 = 0
			local var_10_1 = false

			for iter_10_0, iter_10_1 in pairs(arg_8_0.petsHolyAttr) do
				if iter_10_1 == var_0_2 then
					var_10_0 = var_10_0 + math.pow(2, #arg_8_0.petsHolyAttr - iter_10_0)

					local var_10_2 = true
				end
			end

			local var_10_3 = ""

			for iter_10_2, iter_10_3 in pairs(arg_8_0.petsAwaken) do
				if iter_10_3 == var_0_2 then
					var_10_0 = var_10_0 + math.pow(2, #arg_8_0.petsAwaken - iter_10_2 + 3)

					local var_10_4
					local var_10_5 = var_0_4[iter_10_2]

					var_10_3 = var_10_3 .. var_10_5 .. "|"
				end
			end

			arg_8_0.selfPlayer.petSortType = var_10_0

			local var_10_6 = {
				attrFilter = arg_8_0.petsHolyAttr,
				awakeFilter = var_10_3
			}

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.PET_FILTER,
				filterParams = var_10_6
			})
			xyd.WindowManager.get():closeWindow(arg_8_0)
		end
	end)
end

function var_0_0.updateSelection(arg_11_0)
	for iter_11_0, iter_11_1 in pairs(arg_11_0.petsHolyAttr) do
		if iter_11_1 == var_0_2 then
			arg_11_0:nodeByName("check_attr_" .. iter_11_0):setSelected(true)
		else
			arg_11_0:nodeByName("check_attr_" .. iter_11_0):setSelected(false)
		end
	end

	for iter_11_2, iter_11_3 in pairs(arg_11_0.petsAwaken) do
		if iter_11_3 == var_0_2 then
			arg_11_0:nodeByName("check_awake_" .. iter_11_2):setSelected(true)
		else
			arg_11_0:nodeByName("check_awake_" .. iter_11_2):setSelected(false)
		end
	end
end

function var_0_0.willClose(arg_12_0, arg_12_1)
	var_0_0.super:willClose(arg_12_1)
end

return var_0_0
