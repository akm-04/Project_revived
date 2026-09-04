local var_0_0 = class("InscriptionTenTimesWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = "skeletons/ui_effect/huizhang/achievement_cup_silver"
local var_0_3 = import("framework.scheduler")
local var_0_4 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2, arg_1_3)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.inscriptions = arg_1_2.inscriptions
	arg_1_0.itemToRedo = arg_1_2.itemToRedo
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.itemToSave = 0
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayerWithNoTouchEvent()
	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_4:translation("INSCRIPTION_TEXT_8"))
	arg_4_0:nodeByName("txt_save"):setString(var_0_4:translation("INSCRIPTION_TEXT_4"))
	arg_4_0:addSelectEffect(1)
	arg_4_0:nodeByName("text_label"):setString(var_0_4:translation("PLEASE_SELECT_ONE"))

	arg_4_0.itemToSave = arg_4_0.inscriptions[1]

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.inscriptions) do
		arg_4_0:nodeByName("item_container_" .. iter_4_0):setVisible(true)
		xyd.setItemBorder(arg_4_0:nodeByName("item_container_" .. iter_4_0), iter_4_1)
		arg_4_0:nodeByName("item_container_" .. iter_4_0):addTouchEventListener(function(arg_5_0, arg_5_1)
			if arg_5_1 == ccui.TouchEventType.ended then
				arg_4_0:addSelectEffect(iter_4_0)

				arg_4_0.itemToSave = iter_4_1
			end
		end)
		arg_4_0:nodeByName("text_" .. iter_4_0):setVisible(true)

		local var_4_0, var_4_1, var_4_2 = arg_4_0.inscription:getInscriptionAttrLabelText(iter_4_1)

		arg_4_0:nodeByName("text_" .. iter_4_0):setString(var_4_0 .. "+" .. var_4_1 .. var_4_2)

		if xyd.tables.item:inscriptSuitId(arg_4_0.inscriptions[iter_4_0]) > 0 then
			arg_4_0:createEffect(iter_4_0)
			arg_4_0:addSelectEffect(iter_4_0)

			arg_4_0.itemToSave = iter_4_1
		end
	end

	arg_4_0:nodeByName("save_button"):addTouchEventListener(function(arg_6_0, arg_6_1)
		xyd.buttonScaleAnim(arg_6_0, arg_6_1)

		if arg_6_1 == ccui.TouchEventType.ended then
			local var_6_0 = {
				item_id = arg_4_0.itemToSave
			}

			arg_4_0.inscription:saveRedo(var_6_0, function(arg_7_0, arg_7_1)
				arg_4_0.callbackParams = arg_7_1

				local var_7_0 = {}

				var_7_0.itemNum = 1
				var_7_0.itemID = arg_4_0.itemToRedo

				arg_4_0.selfPlayer:getBackpack():removeItem(var_7_0)
				arg_4_0.selfPlayer:handleRewards(arg_7_1.rebuild_items)
				xyd.WindowManager.get():closeWindow("inscription_ten_times")
			end)
		end
	end)
end

function var_0_0.createEffect(arg_8_0, arg_8_1)
	if arg_8_0.effect and not tolua.isnull(arg_8_0.effect) then
		arg_8_0.effect:removeFromParent()

		arg_8_0.effect = nil
	end

	local var_8_0 = var_0_2 .. ".json"
	local var_8_1 = var_0_2 .. ".atlas"

	arg_8_0.effect = var_0_1.new(var_8_0, var_8_1, 1)

	arg_8_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_8_0.effect:addTo(arg_8_0:nodeByName("item_container_" .. arg_8_1))
	arg_8_0.effect:setPosition(cc.p(arg_8_0:nodeByName("item_container_" .. arg_8_1):getContentSize().width / 2, arg_8_0:nodeByName("item_container_" .. arg_8_1):getContentSize().height / 2 + 10))
	arg_8_0.effect:setName("effect")
	arg_8_0.effect:play(nil, true)
end

function var_0_0.addSelectEffect(arg_9_0, arg_9_1)
	if arg_9_0.selectEffect then
		arg_9_0.selectEffect:removeFromParent(false)
	else
		arg_9_0.selectEffect = xyd.AssetLoader.get():loadSprite("windows/inscription/ten_times/select_kuang.png")

		local var_9_0 = cc.ScaleBy:create(0.3, 1.04)
		local var_9_1 = transition.sequence({
			var_9_0,
			var_9_0:reverse()
		})
		local var_9_2 = cc.RepeatForever:create(var_9_1)

		arg_9_0.selectEffect:runAction(var_9_2)
		arg_9_0.selectEffect:setNormalizedPosition(cc.p(0.5, 0.5))
		arg_9_0.selectEffect:setLocalZOrder(1)
	end

	arg_9_0:nodeByName("item_container_" .. arg_9_1):addChild(arg_9_0.selectEffect)
end

function var_0_0.willClose(arg_10_0, arg_10_1)
	var_0_0.super:willClose(arg_10_1)

	if arg_10_0.callback and arg_10_0.callbackParams then
		arg_10_0.callback(arg_10_0.callbackParams.rebuild_items or {})
	end
end

return var_0_0
