local var_0_0 = class("ExtraAwardWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SplitLine")
local var_0_2 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.chooseAwards = arg_1_2.chooseAwards
	arg_1_0.choosenAward = nil
	arg_1_0.items = {}
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:layOut()
end

function var_0_0.layOut(arg_3_0)
	arg_3_0:nodeByName("desc"):setString(var_0_2:translation("LATERN_TIP_8"))
	arg_3_0:nodeByName("title"):setString(var_0_2:translation("ACTIVITY_1041_TEXT_1"))
	arg_3_0:nodeByName("text_cancel"):setString(var_0_2:translation("ACTIVITY_1041_TEXT_2"))
	arg_3_0:nodeByName("text_sure"):setString(var_0_2:translation("ACTIVITY_1041_TEXT_3"))

	local var_3_0 = var_0_1.new({
		size = 485
	})

	var_3_0:addTo(arg_3_0:nodeByName("background"))
	var_3_0:setAnchorPoint(0, 0.5)
	var_3_0:setPosition(arg_3_0:nodeByName("line"):getPosition())

	for iter_3_0, iter_3_1 in pairs(arg_3_0.chooseAwards) do
		local var_3_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1041/avatar_item.csb")
		local var_3_2 = var_3_1:getChildByName("container")
		local var_3_3 = display.newNode()

		var_3_3:setContentSize(104, 104)
		var_3_3:addTo(var_3_2)
		var_3_3:setLocalZOrder(-1)

		local var_3_4 = var_3_2:getChildByName("zhezhao")
		local var_3_5 = var_3_2:getChildByName("gou")

		var_3_4:setVisible(false)
		var_3_5:setVisible(false)
		xyd.setItemBorder(var_3_3, iter_3_1.table_id, nil, nil, iter_3_1.item_num)
		table.insert(arg_3_0.items, var_3_2)
		var_3_3:setTouchEnabled(true)

		local var_3_6, var_3_7 = var_3_3:getPosition()
		local var_3_8 = {
			id = iter_3_1.table_id,
			hasNum = arg_3_0.player:getBackpack():getItemNumByID(iter_3_1.table_id),
			showNum = iter_3_1.item_num
		}

		var_3_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
			if arg_4_0.name == "began" then
				local var_4_0 = xyd.WindowManager.get():getWindow("new_item_tips")
				local var_4_1 = arg_3_0:convertToWorldSpace(cc.p(0, 0))

				if not var_4_0 then
					local var_4_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_3_8)

					xyd.adaptToWorldPosition(var_3_3, var_4_2)
				end

				return true
			elseif arg_4_0.name == "ended" then
				wnd = xyd.WindowManager.get():closeWindow("new_item_tips")

				var_3_4:setVisible(true)
				var_3_5:setVisible(true)

				arg_3_0.choosenAward = iter_3_0

				for iter_4_0 = 1, #arg_3_0.items do
					if iter_4_0 ~= iter_3_0 then
						arg_3_0.items[iter_4_0]:getChildByName("zhezhao"):setVisible(false)
						arg_3_0.items[iter_4_0]:getChildByName("gou"):setVisible(false)
					end
				end
			end

			return true
		end)
		var_3_1:addTo(arg_3_0:nodeByName("container"))
		var_3_1:setPosition((iter_3_0 - 1) * 145, 0)
	end

	arg_3_0:nodeByName("ok"):addTouchEventListener(function(arg_5_0, arg_5_1)
		xyd.buttonScaleAnim(arg_3_0:nodeByName("ok"), arg_5_1)

		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if not arg_3_0.choosenAward then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("LATERN_TIP_10")
				})

				return
			end

			local var_5_0 = {
				index = arg_3_0.choosenAward
			}

			arg_3_0.activitiesModel:selectExternalAward(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_3_0.player:handleRewards({
						arg_6_1
					})
					xyd.WindowManager.get():closeWindow(arg_3_0.name)
				end
			end)
		end
	end)
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0:addBlockLayerWithNoTouchEvent()
end

return var_0_0
