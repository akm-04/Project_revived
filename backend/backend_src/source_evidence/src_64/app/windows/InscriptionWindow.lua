local var_0_0 = class("InscriptionWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = "skeletons/ui_effect/inscription/flicker_effect"
local var_0_3 = "skeletons/ui_effect/inscription/magic_circle_effect"
local var_0_4 = "skeletons/ui_effect/huizhang/fuwenyuan"
local var_0_5 = "skeletons/ui_effect/huizhang/achievement_cup_silver"
local var_0_6 = import("framework.scheduler")
local var_0_7 = xyd.tables.translation
local var_0_8 = {
	Redo = 2,
	Make = 1
}
local var_0_9 = {
	Crystal = 1,
	Mana = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.workType = var_0_8.Make
	arg_1_0.redoPayType = var_0_9.Mana
	arg_1_0.rebuildItemID = nil
	arg_1_0.currentSelectReoItemID = nil
	arg_1_0.currentSelectInscription = nil
	arg_1_0.inscription = xyd.ModelManager.get():loadModel(xyd.ModelType.INSCRIPTION)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.ECONOMY_AFTER, function(arg_3_0)
		arg_2_0:updateAssetsShow()
	end)

	local var_2_0 = {
		isEcoBar = 0,
		show_rule = true,
		callback = function()
			arg_2_0:handleRebuildItem(handler(arg_2_0, arg_2_0.close))
		end
	}

	arg_2_0:addTopSidebar(var_2_0)
	arg_2_0:layout()
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("txt_make"):setString(var_0_7:translation("INSCRIPTION_TEXT_1"))
	arg_5_0:nodeByName("txt_redo"):setString(var_0_7:translation("INSCRIPTION_TEXT_2"))
	arg_5_0:nodeByName("txt_make_2"):setString(var_0_7:translation("INSCRIPTION_TEXT_1"))
	arg_5_0:nodeByName("txt_redo_2"):setString(var_0_7:translation("INSCRIPTION_TEXT_2"))
	arg_5_0:nodeByName("txt_redo_ten"):setString(var_0_7:translation("INSCRIPTION_TEXT_3"))
	arg_5_0:nodeByName("txt_save"):setString(var_0_7:translation("INSCRIPTION_TEXT_4"))
	arg_5_0:nodeByName("make_type_btn"):addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			if arg_5_0.workType ~= var_0_8.Make then
				arg_5_0:handleRebuildItem()

				arg_5_0.workType = var_0_8.Make
				arg_5_0.currentSelectInscription = nil

				arg_5_0:updateWorkState()
			else
				arg_5_0:nodeByName("make_type_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end
	end)
	arg_5_0:nodeByName("redo_type_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended and not arg_5_0.isOnMaking then
			if arg_5_0.workType ~= var_0_8.Redo then
				arg_5_0.workType = var_0_8.Redo
				arg_5_0.currentSelectInscription = nil
				arg_5_0.currentSelectReoItemID = nil

				arg_5_0:updateWorkState()
			else
				arg_5_0:nodeByName("redo_type_btn"):setBrightStyle(ccui.BrightStyle.highlight)
			end
		end
	end)
	arg_5_0:nodeByName("suit_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("inscription_suit")
		end
	end)
	xyd.nodeEventSample(arg_5_0:nodeByName("top_sidebar"):nodeByName("rule"), nil, function()
		local var_9_0 = {
			title_name = "INSCRIPTION_RULE_TITLE",
			rule = "INSCRIPTION_RULE_TXT",
			style = xyd.RuleStyle.GREEN
		}

		xyd.WindowManager.get():openWindow("new_text_rule", var_9_0)
	end)
	arg_5_0:nodeByName("make_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		xyd.buttonScaleAnim(arg_10_0, arg_10_1)

		if arg_10_1 == ccui.TouchEventType.ended and not arg_5_0.isOnMaking then
			local var_10_0 = xyd.tables.inscription:compoundMaterial(arg_5_0.currentSelectInscription)
			local var_10_1 = xyd.tables.inscription:compoundNum(arg_5_0.currentSelectInscription)
			local var_10_2 = arg_5_0.inscription:getMaterialNumByID(var_10_0)
			local var_10_3 = xyd.tables.inscription:compoundItem(arg_5_0.currentSelectInscription)
			local var_10_4 = xyd.tables.inscription:compoundItemNum(arg_5_0.currentSelectInscription)
			local var_10_5 = arg_5_0.selfPlayer:getBackpack():getItemNumByID(var_10_3)

			if var_10_2 < var_10_1 or var_10_5 < var_10_4 then
				local var_10_6 = var_0_7:translation("MAKE_INSCRIPTION_MATERIAL_NOT_ENOUGH")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_6
				})

				return
			end

			local var_10_7 = {
				inscript_id = arg_5_0.currentSelectInscription
			}

			var_10_7.make_num = 1
			arg_5_0.isOnMaking = true

			arg_5_0.inscription:make(var_10_7, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					if var_10_4 > 0 then
						local var_11_0 = {
							itemID = var_10_3,
							itemNum = var_10_4
						}

						arg_5_0.backpack:removeItem(var_11_0)
						arg_5_0:updateAssetsShow()
					end

					local var_11_1 = arg_5_0.effect2

					if xyd.tables.item:inscriptSuitId(arg_11_1.inscript_items[1]) > 0 then
						arg_5_0:createSuitEffect()

						var_11_1 = arg_5_0.effect3
					end

					var_11_1:play(function()
						local var_12_0 = clone(arg_11_1.inscript_items)

						arg_11_1.inscript_items = {}

						for iter_12_0 = 1, #var_12_0 do
							arg_11_1.inscript_items[iter_12_0] = {}
							arg_11_1.inscript_items[iter_12_0].table_id = var_12_0[iter_12_0]
							arg_11_1.inscript_items[iter_12_0].item_num = 1
						end

						if arg_11_1.inscript_items and arg_11_1.inscript_items[1] then
							arg_11_1.inscript_items[1].workType = var_0_8.Make
						end

						arg_5_0.selfPlayer:handleRewards(arg_11_1.inscript_items)
						var_0_6.performWithDelayGlobal(function()
							if arg_5_0 then
								arg_5_0.isOnMaking = false
							end
						end, 0.2)
					end, false)
				else
					arg_5_0.isOnMaking = false
				end
			end)
		end
	end)
	arg_5_0:nodeByName("redo_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		xyd.buttonScaleAnim(arg_14_0, arg_14_1)

		if arg_14_1 == ccui.TouchEventType.ended then
			if arg_5_0.isOnMaking then
				return
			end

			if xyd.tables.item:inscriptSuitId(arg_5_0.currentSelectReoItemID) > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_7:translation("INSCRIPTION_IS_SUIT")
				})

				return
			end

			local var_14_0 = xyd.tables.item:inscriptId(arg_5_0.currentSelectReoItemID)

			if arg_5_0.redoPayType == var_0_9.Mana and arg_5_0.selfPlayer.mana < xyd.tables.inscription:changeGold(var_14_0) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_7:translation("JINBI_ABSENCE"), function()
					local var_15_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_5_0.selfPlayer:isFuncOpen(var_15_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_15_1 = xyd.tables.functionOpen:level(var_15_0)
						local var_15_2 = string.format(var_0_7:translation("FUNCTION_OPEN_TIP_LEVEL"), var_15_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_15_2
						})
					end
				end, nil, nil, arg_5_0.colorMode)

				return
			elseif arg_5_0.redoPayType == var_0_9.Crystal and arg_5_0.selfPlayer.crystal < xyd.tables.inscription:changeCrystal(var_14_0) then
				local var_14_1 = var_0_7:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_14_1, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_5_0.colorMode)
			end

			local var_14_2 = {
				item_id = arg_5_0.currentSelectReoItemID
			}

			var_14_2.rebuild_num = 1
			var_14_2.cost_type = arg_5_0.redoPayType
			arg_5_0.isOnMaking = true

			arg_5_0.inscription:rebuild(var_14_2, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					local function var_17_0()
						arg_5_0.rebuildItemID = arg_17_1.inscript_items[1]

						arg_5_0:updateWorkState()
					end

					if xyd.tables.item:inscriptSuitId(arg_17_1.inscript_items[1]) > 0 then
						arg_5_0:createSuitEffect()
						arg_5_0.effect3:play(function()
							var_17_0()
							var_0_6.performWithDelayGlobal(function()
								if arg_5_0 then
									arg_5_0.isOnMaking = false

									arg_5_0.effect3:stop()
								end
							end, 0.2)
						end, false)
					else
						arg_5_0.isOnMaking = false

						var_17_0()
					end
				else
					arg_5_0.isOnMaking = false
				end
			end)
		end
	end)
	arg_5_0:nodeByName("redo_ten_btn"):addTouchEventListener(function(arg_21_0, arg_21_1)
		xyd.buttonScaleAnim(arg_21_0, arg_21_1)

		if arg_21_1 == ccui.TouchEventType.ended then
			if xyd.tables.item:inscriptSuitId(arg_5_0.currentSelectReoItemID) > 0 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_7:translation("INSCRIPTION_IS_SUIT")
				})

				return
			end

			local var_21_0 = xyd.tables.item:inscriptId(arg_5_0.currentSelectReoItemID)

			if arg_5_0.redoPayType == var_0_9.Mana and arg_5_0.selfPlayer.mana < 10 * xyd.tables.inscription:changeGold(var_21_0) then
				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_7:translation("JINBI_ABSENCE"), function()
					local var_22_0 = xyd.FunctionID.ID_GOLD_HAND

					if arg_5_0.selfPlayer:isFuncOpen(var_22_0) == true then
						xyd.WindowManager.get():openWindow(xyd.WindowName.goldenHand)
					else
						local var_22_1 = xyd.tables.functionOpen:level(var_22_0)
						local var_22_2 = string.format(var_0_7:translation("FUNCTION_OPEN_TIP_LEVEL"), var_22_1)

						xyd.WindowManager.get():openWindow("toast", {
							message = var_22_2
						})
					end
				end, nil, nil, arg_5_0.colorMode)

				return
			elseif arg_5_0.redoPayType == var_0_9.Crystal and arg_5_0.selfPlayer.crystal < 10 * xyd.tables.inscription:changeCrystal(var_21_0) then
				local var_21_1 = var_0_7:translation("ZUANSHI_ABSENCE")

				xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_21_1, function()
					xyd.WindowManager.get():openWindow("vip_recharge")
				end, nil, nil, arg_5_0.colorMode)
			end

			local var_21_2 = {
				item_id = arg_5_0.currentSelectReoItemID
			}

			var_21_2.rebuild_num = 10
			var_21_2.cost_type = arg_5_0.redoPayType

			arg_5_0.inscription:rebuild(var_21_2, function(arg_24_0, arg_24_1)
				if arg_24_0 == xyd.error.OK then
					local var_24_0 = {}

					xyd.WindowManager.get():openWindow("inscription_ten_times", {
						inscriptions = arg_24_1.inscript_items,
						itemToRedo = arg_5_0.currentSelectReoItemID or 0,
						callback = function(arg_25_0)
							if xyd.WindowManager.get():getWindow("inscription") then
								arg_5_0.rebuildItemID = arg_25_0[1].table_id
								arg_5_0.currentSelectReoItemID = arg_25_0[1].table_id

								arg_5_0:updateWorkState()

								arg_5_0.rebuildItemID = nil

								arg_5_0:updateWorkState()
							end
						end
					})
				end
			end)
		end
	end)
	arg_5_0:nodeByName("save_redo_btn"):addTouchEventListener(function(arg_26_0, arg_26_1)
		xyd.buttonScaleAnim(arg_26_0, arg_26_1)

		if arg_26_1 == ccui.TouchEventType.ended then
			arg_5_0:doSaveRebuildItem()
		end
	end)

	for iter_5_0, iter_5_1 in pairs(var_0_9) do
		arg_5_0:nodeByName("select_box" .. iter_5_1):setTouchEnabled(true)
		arg_5_0:nodeByName("select_box" .. iter_5_1):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_27_0)
			if arg_27_0.name == "began" then
				return true
			elseif arg_27_0.name == "ended" then
				arg_5_0.redoPayType = iter_5_1

				arg_5_0:updateRedoContainerShow()
			end
		end)
	end

	arg_5_0:nodeByName("make_cost_text1"):setString(var_0_7:translation("MAKE_COST"))
	arg_5_0:nodeByName("make_cost_text2"):setString(var_0_7:translation("MAKE_COST"))
	arg_5_0:updateAssetsShow()
	arg_5_0:updateWorkState()
	arg_5_0:addInscriptionIconTouchNode()
	arg_5_0:createMakeEffect()
	arg_5_0:createSuitEffect()
end

function var_0_0.createMakeEffect(arg_28_0)
	if arg_28_0.effect2 and not tolua.isnull(arg_28_0.effect2) then
		arg_28_0.effect2:removeFromParent()

		arg_28_0.effect2 = nil
	end

	local var_28_0 = var_0_3 .. ".json"
	local var_28_1 = var_0_3 .. ".atlas"

	arg_28_0.effect2 = var_0_1.new(var_28_0, var_28_1, 1)

	arg_28_0.effect2:setAnchorPoint(cc.p(0.5, 0.5))
	arg_28_0.effect2:addTo(arg_28_0:nodeByName("left_container"))
	arg_28_0.effect2:setPosition(arg_28_0:nodeByName("bg_circle"):getPositionX() - 2, arg_28_0:nodeByName("bg_circle"):getPositionY() + 7)
	arg_28_0.effect2:setName("effect2")
end

function var_0_0.createSuitEffect(arg_29_0)
	if arg_29_0.effect3 and not tolua.isnull(arg_29_0.effect3) then
		arg_29_0.effect3:removeFromParent()

		arg_29_0.effect3 = nil
	end

	local var_29_0 = var_0_4 .. ".json"
	local var_29_1 = var_0_4 .. ".atlas"

	arg_29_0.effect3 = var_0_1.new(var_29_0, var_29_1, 1)

	arg_29_0.effect3:setAnchorPoint(cc.p(0.5, 0.5))
	arg_29_0.effect3:addTo(arg_29_0:nodeByName("left_container"))
	arg_29_0.effect3:setPosition(arg_29_0:nodeByName("bg_circle"):getPositionX() - 2, arg_29_0:nodeByName("bg_circle"):getPositionY() + 6.5)
	arg_29_0.effect3:setName("effect3")
end

function var_0_0.updateRedoContainerShow(arg_30_0)
	local var_30_0 = xyd.tables.item:inscriptId(arg_30_0.currentSelectReoItemID)

	arg_30_0:nodeByName("cost_mana_num_txt"):setString(xyd.tables.inscription:changeGold(var_30_0))
	arg_30_0:nodeByName("cost_crystal_num_txt"):setString(xyd.tables.inscription:changeCrystal(var_30_0))

	for iter_30_0, iter_30_1 in pairs(var_0_9) do
		if iter_30_1 == arg_30_0.redoPayType then
			arg_30_0:nodeByName("select" .. iter_30_1):setVisible(true)
		else
			arg_30_0:nodeByName("select" .. iter_30_1):setVisible(false)
		end
	end
end

function var_0_0.addInscriptionIconTouchNode(arg_31_0)
	local var_31_0 = display.newNode()

	var_31_0:setTouchEnabled(true)
	var_31_0:setAnchorPoint(cc.p(0.5, 0.5))
	var_31_0:setContentSize(arg_31_0:nodeByName("inscription_icon"):getContentSize())
	var_31_0:addTo(arg_31_0:nodeByName("left_container"))
	var_31_0:setPosition(arg_31_0:nodeByName("inscription_icon"):getPosition())
	var_31_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_32_0)
		if arg_32_0.name == "began" and not arg_31_0.isOnMaking then
			arg_31_0.scrollViewMoved_ = false
			arg_31_0.prevX_ = arg_32_0.x
			arg_31_0.prevY_ = arg_32_0.y

			return true
		elseif arg_32_0.name == "moved" then
			local var_32_0 = 5

			if var_32_0 <= math.abs(arg_32_0.y - arg_31_0.prevY_) or var_32_0 <= math.abs(arg_32_0.x - arg_31_0.prevX_) then
				arg_31_0.scrollViewMoved_ = true
			end
		elseif arg_32_0.name == "ended" and not arg_31_0.scrollViewMoved_ then
			local function var_32_1()
				arg_31_0:handleTouchNode()
			end

			arg_31_0:handleRebuildItem(var_32_1)
		end
	end)
end

function var_0_0.handleTouchNode(arg_34_0)
	local function var_34_0(arg_35_0)
		if arg_34_0.workType == var_0_8.Make then
			arg_34_0.currentSelectInscription = arg_35_0
		else
			arg_34_0.currentSelectReoItemID = arg_35_0
		end

		arg_34_0:updateWorkState()
	end

	local var_34_1 = {
		callback = var_34_0
	}

	if arg_34_0.workType == var_0_8.Make then
		xyd.WindowManager.get():openWindow("inscription_make", var_34_1)
	else
		xyd.WindowManager.get():openWindow("inscription_redo", var_34_1)
	end
end

function var_0_0.updateAssetsShow(arg_36_0)
	arg_36_0:nodeByName("hot_num_txt"):setString(arg_36_0.selfPlayer.degreeCer)
	arg_36_0:nodeByName("moon_num_txt"):setString(arg_36_0.selfPlayer.graduateCer)
	arg_36_0:nodeByName("star_num_txt"):setString(arg_36_0.selfPlayer.patentCer)
	arg_36_0:nodeByName("solid_num_txt"):setString(arg_36_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc.speacialItemID))
end

function var_0_0.updateWorkState(arg_37_0)
	arg_37_0:nodeByName("green_plus"):setVisible(false)
	arg_37_0:nodeByName("make_container"):setVisible(false)
	arg_37_0:nodeByName("redo_container"):setVisible(false)
	arg_37_0:nodeByName("not_select_container"):setVisible(false)
	arg_37_0:nodeByName("inscription_icon"):removeAllChildren(true)
	arg_37_0:nodeByName("make_desc_txt"):setVisible(false)
	arg_37_0:nodeByName("redo_desc_txt1"):setVisible(false)
	arg_37_0:nodeByName("redo_desc_txt2"):setVisible(false)

	if arg_37_0.workType == var_0_8.Make then
		arg_37_0:nodeByName("make_desc_txt"):setVisible(true)
		arg_37_0:nodeByName("redo_type_btn"):setBrightStyle(ccui.BrightStyle.normal)
		arg_37_0:nodeByName("make_type_btn"):setBrightStyle(ccui.BrightStyle.highlight)

		if arg_37_0.currentSelectInscription == nil then
			arg_37_0:nodeByName("green_plus"):setVisible(true)
			arg_37_0:nodeByName("not_select_container"):setVisible(true)
			arg_37_0:nodeByName("make_desc_txt"):setString(var_0_7:translation("SELECT_INSCRIPTION_TO_MAKE"))
			arg_37_0:nodeByName("tips_text1"):setString(var_0_7:translation("MAKE_INSCRIPTION_COST_TIP1"))
			arg_37_0:nodeByName("tips_text2"):setString(var_0_7:translation("MAKE_INSCRIPTION_COST_TIP2"))
		else
			arg_37_0:nodeByName("make_container"):setVisible(true)
			arg_37_0.inscription:setTransparentBorder(arg_37_0:nodeByName("inscription_icon"), xyd.tables.inscription:itemID(arg_37_0.currentSelectInscription)[1])
			arg_37_0:nodeByName("make_desc_txt"):setString(string.format(var_0_7:translation("MAKE_INSCRIPTION_TXT"), xyd.tables.inscription:level(arg_37_0.currentSelectInscription), xyd.tables.inscription:name(arg_37_0.currentSelectInscription)))

			local var_37_0 = xyd.tables.inscription:compoundMaterial(arg_37_0.currentSelectInscription)
			local var_37_1 = xyd.tables.inscription:compoundNum(arg_37_0.currentSelectInscription)
			local var_37_2 = arg_37_0.inscription:getMaterialNumByID(var_37_0)
			local var_37_3 = arg_37_0.inscription:getMaterialIcon(var_37_0)

			arg_37_0:nodeByName("make_coin_pos1"):removeAllChildren(true)
			var_37_3:setScale(0.7)
			var_37_3:addTo(arg_37_0:nodeByName("make_coin_pos1"))
			arg_37_0:nodeByName("make_cost_num_txt1"):setString(var_37_1)

			if var_37_2 < var_37_1 then
				arg_37_0:nodeByName("make_cost_num_txt1"):setColor(xyd.color.RED)
			else
				arg_37_0:nodeByName("make_cost_num_txt1"):setColor(xyd.color.WHITE)
			end

			local var_37_4 = xyd.tables.inscription:compoundItem(arg_37_0.currentSelectInscription)
			local var_37_5 = xyd.tables.inscription:compoundItemNum(arg_37_0.currentSelectInscription)

			if var_37_4 > 0 then
				arg_37_0:nodeByName("make_cost_bg2"):setVisible(true)

				local var_37_6 = arg_37_0.inscription:getMaterialIcon(var_37_4)

				arg_37_0:nodeByName("make_coin_pos2"):removeAllChildren(true)
				var_37_6:setScale(0.7)
				var_37_6:addTo(arg_37_0:nodeByName("make_coin_pos2"))
				arg_37_0:nodeByName("make_cost_num_txt2"):setString(var_37_5)

				if var_37_5 > arg_37_0.selfPlayer:getBackpack():getItemNumByID(var_37_4) then
					arg_37_0:nodeByName("make_cost_num_txt2"):setColor(xyd.color.RED)
				else
					arg_37_0:nodeByName("make_cost_num_txt2"):setColor(xyd.color.WHITE)
				end
			else
				arg_37_0:nodeByName("make_cost_bg2"):setVisible(false)
			end
		end
	else
		arg_37_0:nodeByName("redo_type_btn"):setBrightStyle(ccui.BrightStyle.highlight)
		arg_37_0:nodeByName("make_type_btn"):setBrightStyle(ccui.BrightStyle.normal)

		if arg_37_0.rebuildItemID then
			arg_37_0:nodeByName("save_redo_btn"):setTouchEnabled(true)
			arg_37_0:nodeByName("save_redo_btn"):setBright(true)
		else
			arg_37_0:nodeByName("save_redo_btn"):setTouchEnabled(false)
			arg_37_0:nodeByName("save_redo_btn"):setBright(false)
		end

		if arg_37_0.currentSelectReoItemID == nil then
			arg_37_0:nodeByName("green_plus"):setVisible(true)
			arg_37_0:nodeByName("not_select_container"):setVisible(true)
			arg_37_0:nodeByName("make_desc_txt"):setVisible(true)
			arg_37_0:nodeByName("make_desc_txt"):setString(var_0_7:translation("SELECT_INSCRIPTION_TO_REDO"))
		else
			arg_37_0:nodeByName("redo_desc_txt1"):setVisible(true)
			arg_37_0:nodeByName("redo_desc_txt2"):setVisible(true)

			local var_37_7 = arg_37_0.currentSelectReoItemID

			if arg_37_0.rebuildItemID then
				var_37_7 = arg_37_0.rebuildItemID
			end

			arg_37_0:nodeByName("redo_container"):setVisible(true)
			arg_37_0:updateRedoContainerShow()
			arg_37_0.inscription:setTransparentBorder(arg_37_0:nodeByName("inscription_icon"), var_37_7)

			local var_37_8 = xyd.tables.item:inscriptId(var_37_7)
			local var_37_9, var_37_10, var_37_11 = arg_37_0.inscription:getInscriptionAttrLabelText(var_37_7)

			arg_37_0:nodeByName("redo_desc_txt1"):setString("Lv." .. xyd.tables.inscription:level(var_37_8) .. " " .. xyd.tables.inscription:name(var_37_8))

			if xyd.tables.item:inscriptSuitId(var_37_7) > 0 then
				arg_37_0:nodeByName("redo_desc_txt1"):setString("Lv." .. xyd.tables.inscription:level(var_37_8) .. " " .. xyd.tables.item:name(var_37_7))
			end

			arg_37_0:nodeByName("redo_desc_txt2"):setString(var_37_9 .. "+" .. var_37_10 .. var_37_11)
			arg_37_0:nodeByName("cost_mana_num_txt"):setString(xyd.tables.inscription:changeGold(var_37_8))
			arg_37_0:nodeByName("cost_crystal_num_txt"):setString(xyd.tables.inscription:changeCrystal(var_37_8))
		end
	end
end

function var_0_0.handleRebuildItem(arg_38_0, arg_38_1)
	if not arg_38_0.rebuildItemID then
		if arg_38_1 then
			arg_38_1()
		end

		return
	end

	local var_38_0 = var_0_7:translation("SURE_SAVE_CURRENT_REDO_ITEM")

	xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_38_0, function()
		arg_38_0:doSaveRebuildItem(arg_38_1)
	end, {
		lcallback = function()
			arg_38_0:doAbandonRedoItem(arg_38_1)
		end
	}, nil, arg_38_0.colorMode)
end

function var_0_0.doSaveRebuildItem(arg_41_0, arg_41_1)
	arg_41_0.inscription:saveRedo({
		item_id = arg_41_0.rebuildItemID
	}, function(arg_42_0, arg_42_1)
		if arg_42_0 == xyd.error.OK then
			arg_41_0:saveRedoItem(arg_42_1)

			if arg_41_1 then
				arg_41_1()
			end
		end
	end)
end

function var_0_0.saveRedoItem(arg_43_0, arg_43_1)
	local var_43_0 = {}

	var_43_0.itemNum = 1
	var_43_0.itemID = arg_43_0.currentSelectReoItemID

	arg_43_0.selfPlayer:getBackpack():removeItem(var_43_0)

	if arg_43_1.rebuild_items and arg_43_1.rebuild_items[1] then
		arg_43_1.rebuild_items[1].workType = var_0_8.Redo
	end

	arg_43_0.selfPlayer:handleRewards(arg_43_1.rebuild_items)

	arg_43_0.currentSelectReoItemID = arg_43_0.rebuildItemID
	arg_43_0.rebuildItemID = nil

	arg_43_0:updateWorkState()
end

function var_0_0.doAbandonRedoItem(arg_44_0, arg_44_1)
	arg_44_0.inscription:abandonRedo({}, function(arg_45_0, arg_45_1)
		if arg_45_0 == xyd.error.OK then
			arg_44_0.rebuildItemID = nil

			arg_44_0:updateWorkState()

			if arg_44_1 then
				arg_44_1()
			end
		end
	end)
end

return var_0_0
