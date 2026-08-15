local var_0_0 = class("FunctionOpenWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.openIDs = arg_1_2.open_ids
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	if #arg_2_0.openIDs > 0 then
		arg_2_0.index = 1
		arg_2_0.grayLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150)):addTo(arg_2_0:nodeByName("background"))

		arg_2_0:layout()
	end
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super.didOpen(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("touch_layer"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			arg_3_0:nodeByName("touch_layer"):setTouchEnabled(false)
			arg_3_0:moveIcon()
		end
	end)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("touch_layer"):setTouchEnabled(true)

	arg_5_0.nameLabel = arg_5_0:nodeByName("name")
	arg_5_0.descLabel = arg_5_0:nodeByName("desc")
	arg_5_0.container = arg_5_0:nodeByName("icon_container")
	arg_5_0.effectContainer = arg_5_0:nodeByName("effect_container")

	arg_5_0.descLabel:ignoreContentAdaptWithSize(false)

	arg_5_0.bg = arg_5_0:nodeByName("bg")

	arg_5_0.container:setVisible(true)
	arg_5_0.bg:setVisible(true)
	arg_5_0.bg:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 + 70))
	arg_5_0.container:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.container:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 + 70))
	arg_5_0.effectContainer:setAnchorPoint(cc.p(0.5, 0.5))
	arg_5_0.effectContainer:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 + 70))

	local var_5_0 = xyd.AssetLoader.get():loadAnimation("zhanduo01fla.swf/")

	if arg_5_0.effectSprite == nil then
		arg_5_0.effectSprite = display.newSprite()

		arg_5_0.effectSprite:addTo(arg_5_0)
		arg_5_0.effectSprite:playAnimationForever(var_5_0)
		arg_5_0.effectSprite:setLocalZOrder(-1)
	end

	arg_5_0.effectSprite:setScale(1, 1)
	arg_5_0.effectSprite:pos(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2 + 70)

	local var_5_1 = arg_5_0.openIDs[arg_5_0.index]
	local var_5_2

	if xyd.tables.building:isBuildingID(var_5_1) then
		arg_5_0.descLabel:setString(xyd.tables.building:desc(var_5_1))
		arg_5_0.nameLabel:setString(xyd.tables.building:name(var_5_1))

		local var_5_3 = xyd.tables.building:funcOpenIcon(var_5_1)

		var_5_2 = xyd.AssetLoader.get():loadSprite(var_5_3)
	else
		arg_5_0.descLabel:setString(xyd.tables.functionOpen:desc(var_5_1))
		arg_5_0.nameLabel:setString(xyd.tables.functionOpen:name(var_5_1))

		local var_5_4 = xyd.tables.functionOpen:icon(var_5_1)

		var_5_2 = xyd.AssetLoader.get():loadSprite(var_5_4)
	end

	if var_5_2 then
		arg_5_0.container:removeAllChildren()
		xyd.displaySpriteOnContainer(var_5_2, arg_5_0.container, true)
	end
end

function var_0_0.moveIcon(arg_6_0)
	local var_6_0 = arg_6_0.openIDs[arg_6_0.index]

	arg_6_0.bg:setVisible(false)
	arg_6_0.container:setVisible(false)
	arg_6_0.effectSprite:setScale(0.5, 0.5)

	local var_6_1 = xyd.WindowManager.get():getWindow("main_scene_bottom")
	local var_6_2 = xyd.WindowManager.get():getWindow("main_scene_right")

	if var_6_0 == xyd.FunctionID.MISSION then
		if var_6_1 then
			local var_6_3 = var_6_1:nodeByName(var_6_1.TASK_BUTTON)

			arg_6_0.resPos = arg_6_0:convertToNodeSpace(var_6_3:getParent():convertToWorldSpace(cc.p(var_6_3:getPosition())))
		end
	elseif var_6_0 == xyd.FunctionID.FRIEND then
		-- block empty
	elseif var_6_0 == xyd.FunctionID.SUMMON then
		-- block empty
	elseif var_6_0 == xyd.FunctionID.EVOLVE then
		if var_6_2 then
			local var_6_4 = var_6_2.evolveButton_

			var_6_4:setTouchEnabled(false)

			arg_6_0.resPos = arg_6_0:convertToNodeSpace(var_6_4:getParent():convertToWorldSpace(cc.p(var_6_4:getPosition())))
		end
	elseif var_6_0 == xyd.FunctionID.MARKET then
		-- block empty
	elseif var_6_0 == xyd.FunctionID.SHOP then
		if var_6_2 then
			local var_6_5 = var_6_2.shopButton_

			arg_6_0.resPos = arg_6_0:convertToNodeSpace(var_6_5:getParent():convertToWorldSpace(cc.p(var_6_5:getPosition())))
		end
	elseif var_6_0 == xyd.FunctionID.ARENA then
		if var_6_1 then
			local var_6_6 = var_6_1:nodeByName(var_6_1.ARENA_BUTTON)

			arg_6_0.resPos = arg_6_0:convertToNodeSpace(var_6_6:getParent():convertToWorldSpace(cc.p(var_6_6:getPosition())))
		end
	elseif var_6_0 == xyd.FunctionID.FUBEN then
		-- block empty
	elseif var_6_0 == xyd.FunctionID.DUNGON then
		if var_6_2 then
			local var_6_7 = var_6_2.worldMapButton_

			arg_6_0.resPos = arg_6_0:convertToNodeSpace(var_6_7:getParent():convertToWorldSpace(cc.p(var_6_7:getPosition())))
		end
	elseif var_6_0 == xyd.FunctionID.GONGHU then
		-- block empty
	elseif var_6_0 == xyd.FunctionID.WAREHOUSE then
		-- block empty
	elseif var_6_1 then
		local var_6_8 = var_6_1:nodeByName(var_6_1.BUILDING_BUTTON)

		arg_6_0.resPos = var_6_1:convertToNodeSpace(var_6_8:getParent():convertToWorldSpace(cc.p(var_6_8:getPosition())))
	end

	transition.moveTo(arg_6_0.effectSprite, {
		time = 0.5,
		x = arg_6_0.resPos.x,
		y = arg_6_0.resPos.y
	})
	var_0_1.performWithDelayGlobal(function(arg_7_0)
		if arg_6_0.index >= #arg_6_0.openIDs then
			xyd.WindowManager.get():closeWindow("function_open")
		else
			arg_6_0.index = arg_6_0.index + 1

			arg_6_0:layout()
		end
	end, 0.5)
end

function var_0_0.didClose(arg_8_0)
	var_0_0.super.didOpen()

	local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	for iter_8_0, iter_8_1 in pairs(arg_8_0.openIDs) do
		local var_8_1 = true

		for iter_8_2, iter_8_3 in pairs(var_8_0.funcIDs) do
			if tostring(iter_8_1) == iter_8_3 then
				var_8_1 = false

				break
			end
		end

		if var_8_1 then
			table.insert(var_8_0.funcIDs, tostring(iter_8_1))
		end
	end

	xyd.StoryData.get():persist()

	if arg_8_0.callback then
		arg_8_0.callback()
	end
end

return var_0_0
