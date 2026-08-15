local var_0_0 = class("SakuraEnjoyWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "skeletons/ui_effect/activity_sakura2/yinghuaparticle_texture"
local var_0_2 = import("framework.scheduler")
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.sakura = xyd.ModelManager.get():loadModel(xyd.ModelType.SAKURA)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.materials = arg_1_0.sakura.details.used_items
	arg_1_0.selectItemID = nil
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("tip_txt"):enableOutline(arg_4_0.sakura.outlineColor, arg_4_0.sakura.outlineSize)
	arg_4_0:nodeByName("sure_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_5_0 = {
				item_id = arg_4_0.selectItemID
			}

			arg_4_0.sakura:openEvent(var_5_0, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0:updateOwnMaterials()

					arg_4_0.sakura.details.event_type = arg_6_1.event_type
					arg_4_0.sakura.details.competitor_info = arg_6_1.competitor_info

					arg_4_0:handleEvent()
				end
			end)
		end
	end)

	arg_4_0.clippingNode = display.newClippingRegionNode()

	arg_4_0.clippingNode:setClippingRegion(cc.rect(0, 0, 1038, 358))
	arg_4_0.clippingNode:setAnchorPoint(cc.p(0, 0))
	arg_4_0.clippingNode:addTo(arg_4_0:nodeByName("material_container"))
	arg_4_0:addPartice(var_0_1)
	arg_4_0:addCentreModels()
	arg_4_0:updateOwnMaterials()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_4_0):addEventListener(xyd.event.WINDOW_DID_OPEN, function(arg_7_0)
		if arg_7_0.windowName == "sakura_enjoy" and arg_4_0 then
			arg_4_0:handleEvent()
		end
	end)
end

function var_0_0.addCentreModels(arg_8_0)
	local var_8_0 = 120
	local var_8_1 = arg_8_0:nodeByName("material_container"):getContentSize().width
	local var_8_2 = xyd.tables.misc.activitySakura2SitModel[1]

	arg_8_0.heroModelLeft = xyd.HeroAnimation.new(nil, var_8_2, 0.5, {})

	arg_8_0.heroModelLeft:addTo(arg_8_0.clippingNode)
	arg_8_0.heroModelLeft:setPosition(cc.p(var_8_1 * 0.38, var_8_0))
	arg_8_0.heroModelLeft:idle()

	local var_8_3 = xyd.tables.misc.activitySakura2SitModel[2]

	arg_8_0.heroModelRight = xyd.HeroAnimation.new(nil, var_8_3, 0.5, {})

	arg_8_0.heroModelRight:addTo(arg_8_0.clippingNode)
	arg_8_0.heroModelRight:setPosition(cc.p(var_8_1 * 0.65, var_8_0 + 20))
	arg_8_0.heroModelRight:idle()
	arg_8_0.heroModelRight:setFlipX(true)
end

function var_0_0.updateOwnMaterials(arg_9_0)
	arg_9_0:nodeByName("item_pos"):setLocalZOrder(20)

	if arg_9_0.backpack:getItemNumByID(arg_9_0.selectItemID) <= 0 then
		arg_9_0.selectItemID = nil
	end

	if arg_9_0.selectItemID then
		local var_9_0 = string.format(var_0_3:translation("SAKURA_ENJOY_TIP1"), xyd.tables.item:name(arg_9_0.selectItemID))

		arg_9_0:nodeByName("tip_txt"):setString(var_9_0)
		arg_9_0:nodeByName("sure_btn"):setBright(true)
		arg_9_0:nodeByName("sure_btn"):setTouchEnabled(true)
		arg_9_0:nodeByName("sure_text"):setVisible(true)
		arg_9_0:nodeByName("sure_gray_text"):setVisible(false)
	else
		if #arg_9_0.materials > 0 then
			arg_9_0:nodeByName("tip_txt"):setString(var_0_3:translation("SAKURA_ENJOY_TIP2"))
		else
			arg_9_0:nodeByName("tip_txt"):setString(var_0_3:translation("SAKURA_ENJOY_TIP3"))
		end

		arg_9_0:nodeByName("sure_btn"):setBright(false)
		arg_9_0:nodeByName("sure_btn"):setTouchEnabled(false)
		arg_9_0:nodeByName("sure_text"):setVisible(false)
		arg_9_0:nodeByName("sure_gray_text"):setVisible(true)
	end

	arg_9_0:nodeByName("item_pos"):removeAllChildren()

	local var_9_1 = 200
	local var_9_2 = 180
	local var_9_3 = (arg_9_0:nodeByName("material_container"):getContentSize().width - var_9_2 * (#arg_9_0.materials - 1)) / 2

	for iter_9_0 = 1, #arg_9_0.materials do
		local var_9_4 = arg_9_0.sakura:createMaterialsItemContent(arg_9_0.materials[iter_9_0])

		var_9_4:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_4:addTo(arg_9_0:nodeByName("item_pos"))
		var_9_4:setPosition(cc.p(var_9_3, var_9_1))

		var_9_3 = var_9_3 + var_9_2

		local var_9_5 = var_9_4:getChildByName("source"):getChildByName("container"):getChildByName("select")

		var_9_5:setVisible(false)
		var_9_4:setTouchEnabled(true)

		if arg_9_0.selectItemID == arg_9_0.materials[iter_9_0] then
			var_9_5:setVisible(true)
		end

		var_9_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				return true
			elseif arg_10_0.name == "ended" and arg_9_0.backpack:getItemNumByID(arg_9_0.materials[iter_9_0]) > 0 then
				arg_9_0.selectItemID = arg_9_0.materials[iter_9_0]

				arg_9_0:updateOwnMaterials()
			end
		end)
	end
end

function var_0_0.handleEvent(arg_11_0)
	if arg_11_0.sakura.details.event_type ~= 0 then
		local var_11_0 = {
			event_type = arg_11_0.sakura.details.event_type
		}

		xyd.WindowManager.get():openWindow("sakura_enjoy_playing", var_11_0)
	end
end

function var_0_0.addPartice(arg_12_0, arg_12_1)
	local var_12_0 = cc.ParticleSystemQuad:create(arg_12_1 .. ".plist")

	var_12_0:addTo(arg_12_0.clippingNode)

	local var_12_1 = arg_12_0:nodeByName("material_container"):getContentSize().width

	var_12_0:setPosition(cc.p(var_12_1 / 2, 358))
end

return var_0_0
