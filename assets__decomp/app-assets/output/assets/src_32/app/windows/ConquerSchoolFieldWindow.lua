local var_0_0 = class("ConquerSchoolFieldWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.conquerSchoolCampaign
local var_0_3 = xyd.tables.conquerSchool
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.conquerSchool = xyd.ModelManager.get():loadModel(xyd.ModelType.CONQUER_SCHOOL)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.currentID = arg_1_0.conquerSchool:getCurrentID()
	arg_1_0.currentRegion = arg_1_0.selfPlayer.conquerRegion
	arg_1_0.mapList = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initData()
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.initData(arg_4_0)
	for iter_4_0 = 1, var_0_4 do
		if iter_4_0 < arg_4_0.currentRegion then
			arg_4_0:nodeByName("map_" .. iter_4_0):setVisible(false)
			arg_4_0:nodeByName("map_light_" .. iter_4_0):setVisible(true)
		elseif iter_4_0 == arg_4_0.currentRegion then
			arg_4_0:nodeByName("map_" .. iter_4_0):setVisible(false)
			arg_4_0:nodeByName("map_light_" .. iter_4_0):setVisible(true)
		else
			arg_4_0:nodeByName("map_" .. iter_4_0):setVisible(true)
			arg_4_0:nodeByName("map_light_" .. iter_4_0):setVisible(false)
		end

		arg_4_0.mapList[iter_4_0] = arg_4_0:nodeByName("map_click_" .. iter_4_0)
	end
end

function var_0_0.layout(arg_5_0)
	for iter_5_0 = 1, #arg_5_0.mapList do
		local var_5_0 = display.newNode()
		local var_5_1 = arg_5_0.mapList[iter_5_0]:getContentSize()

		var_5_0:setContentSize(var_5_1)
		var_5_0:addTo(arg_5_0.mapList[iter_5_0])
		var_5_0:setTouchEnabled(true)
		var_5_0:setTouchSwallowEnabled(true)
		var_5_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_6_0)
			if arg_6_0.name == "began" then
				return true
			elseif arg_6_0.name == "ended" then
				if not arg_5_0:checkCanTouch(iter_5_0) then
					xyd.WindowManager.get():openWindow("toast", {
						message = var_0_1:translation("CONQUER_FIELD_NOT_OPEN")
					})

					return
				end

				arg_5_0:updateShowInfo(iter_5_0)
			end
		end)
	end

	arg_5_0:updateShowInfo(arg_5_0.currentRegion)
	arg_5_0:nodeByName("text_title"):setString(var_0_1:translation("CONQUER_SCHOOL_TXT"))
	arg_5_0:nodeByName("text_award"):setString(var_0_1:translation("CONQUER_SCHOOL_TEXT_6"))
end

function var_0_0.checkCanTouch(arg_7_0, arg_7_1)
	if arg_7_1 <= var_0_2:region(arg_7_0.conquerSchool:getCurrentID()) then
		return true
	else
		return false
	end
end

function var_0_0.checkChangeColor(arg_8_0, arg_8_1)
	if arg_8_1 <= arg_8_0.selfPlayer.conquerRegion then
		return true
	else
		return false
	end
end

function var_0_0.updateShowInfo(arg_9_0, arg_9_1)
	arg_9_0:nodeByName("awards"):removeAllChildren()

	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/conquer_school/school_field/reward_item.csb")

	var_9_0:addTo(arg_9_0:nodeByName("awards"))

	local var_9_1 = var_9_0:getChildByName("container")
	local var_9_2 = var_0_3:translation(arg_9_1)

	var_9_1:getChildByName("reward_des_words"):setString(var_9_2[1])
	var_9_1:getChildByName("need_value_words"):setString(var_9_2[2])

	if arg_9_0:checkChangeColor(arg_9_1) then
		var_9_1:getChildByName("reward_des_words"):setColor(cc.c3b(35, 179, 177))
		var_9_1:getChildByName("need_value_words"):setColor(cc.c3b(35, 179, 177))
	else
		var_9_1:getChildByName("reward_des_words"):setColor(cc.c3b(68, 69, 77))
		var_9_1:getChildByName("need_value_words"):setColor(cc.c3b(68, 69, 77))
	end
end

return var_0_0
