local var_0_0 = class("SkinSkillSelectWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.datas = arg_1_2.items
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.select = 1
	arg_1_0.listContainer = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:nodeByName("txt_title"):setString(var_0_1:translation("AVARTAR_POSE_EQUIP_SKILL"))
	arg_4_0:nodeByName("txt_title"):enableOutline(cc.c4b(255, 255, 255, 255), 3)

	local var_4_0 = arg_4_0:nodeByName("skill_list"):getContentSize()

	arg_4_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_4_0.width, var_4_0.height),
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_4_0:nodeByName("skill_list")):onScroll(handler(arg_4_0, arg_4_0.scrollListener))

	for iter_4_0 = 1, math.ceil(#arg_4_0.datas / 2) do
		local var_4_1 = arg_4_0.list:newItem()
		local var_4_2 = display.newNode()

		var_4_2:setContentSize(334, 160)

		for iter_4_1 = 1, 2 do
			local var_4_3 = (iter_4_0 - 1) * 2 + iter_4_1
			local var_4_4 = arg_4_0.datas[var_4_3]

			if not var_4_4 then
				break
			end

			local var_4_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero/skin_skill_select_item.csb")
			local var_4_6 = var_4_5:getChildByName("container")
			local var_4_7 = var_4_6:getChildByName("skill_icon")

			table.insert(arg_4_0.listContainer, var_4_6)

			if var_4_4.is_equip then
				local var_4_8 = var_4_6:getChildByName("bg_skin_skill_equip")

				var_4_8:setVisible(true)
				var_4_8:getChildByName("txt_equip"):setString(var_0_1:translation("AVARTAR_POSE_EUIPED"))
				var_4_8:getChildByName("txt_equip"):enableOutline(cc.c4b(145, 42, 70, 255), 2)
			end

			var_4_6:getChildByName("bg"):setVisible(var_4_3 ~= arg_4_0.select)
			var_4_6:getChildByName("bg2"):setVisible(var_4_3 == arg_4_0.select)
			var_4_6:getChildByName("txt_name"):setString(var_0_2:name(var_4_4.item_id))
			xyd.setItemBorder(var_4_7, var_4_4.item_id)
			var_4_7:setSwallowTouches(false)
			var_4_7:addTouchEventListener(function(arg_5_0, arg_5_1)
				if arg_5_1 == ccui.TouchEventType.ended then
					if arg_4_0.scrollViewMoved_ then
						return
					end

					local var_5_0 = {
						isSpecialSkill = false,
						id = var_4_4.skill_id,
						partnerID = arg_4_0.hero:getHeroID(),
						hero = arg_4_0.hero
					}
					local var_5_1 = xyd.WindowManager.get():getWindow("skill_tips")

					if not var_5_1 or tolua.isnull(var_5_1) then
						local var_5_2 = xyd.WindowManager.get():openWindow("skill_tips", var_5_0)
						local var_5_3 = arg_5_0:convertToWorldSpace(cc.p(86, 43))

						var_5_2:setPosition(var_5_3.x + 20, var_5_3.y - 140)
					end
				end
			end)
			var_4_6:addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					if arg_4_0.scrollViewMoved_ then
						return
					end

					arg_4_0:updateSelect(var_4_3)
					arg_4_0:updateBtnShow()
				end
			end)
			var_4_5:addTo(var_4_2)
			var_4_5:setPositionX((iter_4_1 - 1) * 178)
		end

		var_4_1:addContent(var_4_2)
		var_4_1:setItemSize(334, 175)
		arg_4_0.list:addItem(var_4_1)
	end

	arg_4_0.list:reload()
	arg_4_0:updateBtnShow()
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_close"), nil, function()
		arg_4_0:close()
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn"), nil, function()
		local var_8_0 = {}

		if arg_4_0.datas[arg_4_0.select].is_equip then
			var_8_0.partner_id = arg_4_0.hero:getHeroID()

			xyd.Backend.get():request(xyd.mid.SKIN_CANCEL, {
				partner_id = arg_4_0.hero:getHeroID()
			}, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					arg_4_0.hero:setSkinInfo(0)
					arg_4_0.callback(0)

					local var_9_0 = xyd.WindowManager.get():getWindow("hero_main")

					if var_9_0 and not tolua.isnull(var_9_0) then
						var_9_0:setSkillContainer()
					end

					arg_4_0:close()
				end
			end)
		else
			var_8_0.partner_id = arg_4_0.hero:getHeroID()

			if arg_4_0.datas[arg_4_0.select].isHasTemp then
				var_8_0.item_id = arg_4_0.hero:getTempSkinItemId(arg_4_0.datas[arg_4_0.select].item_id)
			else
				var_8_0.item_id = arg_4_0.datas[arg_4_0.select].item_id
			end

			xyd.Backend.get():request(xyd.mid.SKIN_ON, var_8_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					arg_4_0.hero:setSkinInfo(arg_10_1.current_skin_id, arg_10_1.skin_ids)
					arg_4_0.callback(arg_4_0.datas[arg_4_0.select].idx)

					local var_10_0 = xyd.WindowManager.get():getWindow("hero_main")

					if var_10_0 and not tolua.isnull(var_10_0) then
						var_10_0:setSkillContainer()
					end

					arg_4_0:close()
				end
			end)
		end
	end)
end

function var_0_0.updateBtnShow(arg_11_0)
	if arg_11_0.datas[arg_11_0.select].is_equip then
		arg_11_0:nodeByName("txt_btn"):setString(var_0_1:translation("AVARTAR_POSE_TAKEOFF"))
	elseif arg_11_0.hero.isSkinOn_ == 1 then
		arg_11_0:nodeByName("txt_btn"):setString(var_0_1:translation("AVARTAR_POSE_CHANGE_EQUIP"))
	else
		arg_11_0:nodeByName("txt_btn"):setString(var_0_1:translation("AVARTAR_POSE_EQUIP"))
	end
end

function var_0_0.updateSelect(arg_12_0, arg_12_1)
	if arg_12_1 == arg_12_0.select then
		return
	end

	local var_12_0 = arg_12_0.listContainer[arg_12_0.select]
	local var_12_1 = arg_12_0.listContainer[arg_12_1]

	arg_12_0.select = arg_12_1

	var_12_0:getChildByName("bg"):setVisible(true)
	var_12_0:getChildByName("bg2"):setVisible(false)
	var_12_1:getChildByName("bg"):setVisible(false)
	var_12_1:getChildByName("bg2"):setVisible(true)
end

function var_0_0.scrollListener(arg_13_0, arg_13_1)
	if arg_13_1.name == "began" then
		arg_13_0.scrollViewMoved_ = false
		arg_13_0.preY_ = arg_13_1.y
	elseif arg_13_1.name == "ended" and 10 < math.abs(arg_13_0.preY_ - arg_13_1.y) then
		arg_13_0.scrollViewMoved_ = true
	end
end

return var_0_0
