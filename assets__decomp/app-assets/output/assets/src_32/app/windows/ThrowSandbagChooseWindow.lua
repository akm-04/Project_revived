local var_0_0 = class("ThrowSandbagChooseWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpriteNodeButton")
local var_0_3 = xyd.tables.hero
local var_0_4 = xyd.tables.throwSandbag

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.throwSandbag = xyd.ModelManager.get():loadModel(xyd.ModelType.THROW_SANDBAG)
	arg_1_0.ticket = arg_1_0.selfPlayer:getBackpack():getItemNumByID(xyd.tables.misc:getValue("dodge_ticket"))
	arg_1_0.gameInfos = arg_1_2
	arg_1_0.ids = arg_1_0.gameInfos.select_monsters
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setTexts()
	arg_3_0:setBtns()
	arg_3_0:initModel()
end

function var_0_0.setTexts(arg_4_0)
	arg_4_0:nodeByName("text_title"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_1"))
	arg_4_0:nodeByName("text_start"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_3"))
	arg_4_0:nodeByName("text_tip"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_4"))
	arg_4_0:nodeByName("text_guide"):setString(var_0_1:translation("THROW_SANDBAG_TEXT_14"))
	arg_4_0:nodeByName("text_top_num"):setString(arg_4_0.ticket)
end

function var_0_0.setBtns(arg_5_0)
	local var_5_0 = var_0_2.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_5_0:addTo(arg_5_0)
	var_5_0:setAnchorPoint(0.5, 0.5)
	var_5_0:setPosition(46, 694)
	var_5_0:setName("return_btn")

	arg_5_0.returnBtn = var_5_0

	arg_5_0.returnBtn:addTouchEvent(function(arg_6_0)
		if arg_6_0.name == "ended" then
			xyd.playCloseSound()

			local var_6_0 = xyd.tables.translation:translation("THROW_SANDBAG_TEXT_15")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_6_0, function()
				xyd.WindowManager.get():closeWindow(arg_5_0)
			end)
		end
	end)
	arg_5_0:nodeByName("btn_rule"):addTouchEventListener(function(arg_8_0, arg_8_1)
		xyd.buttonScaleAnim(arg_8_0, arg_8_1)

		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = {}

			var_8_0.title_name = "THROW_SANDBAG_TEXT_1"
			var_8_0.rule = "THROW_SANDBAG_INFO"
			var_8_0.style = xyd.RuleStyle.BLUE

			xyd.WindowManager.get():openWindow("new_text_rule", var_8_0)
		end
	end)
	arg_5_0:nodeByName("btn_start"):addTouchEventListener(function(arg_9_0, arg_9_1)
		xyd.buttonScaleAnim(arg_9_0, arg_9_1)

		if arg_9_1 == ccui.TouchEventType.ended then
			local var_9_0 = {
				chooseID = arg_5_0.ids[arg_5_0.chooseID],
				gameInfos = arg_5_0.gameInfos
			}

			arg_5_0.throwSandbag:startGame({
				select_id = var_9_0.chooseID
			}, function(arg_10_0, arg_10_1)
				var_9_0.selfRds = arg_10_1.self_rd
				var_9_0.friendRds = arg_10_1.friend_rd

				xyd.WindowManager.get():openWindow("throw_sandbag", var_9_0)
				arg_5_0:close()
			end)
		end
	end)
	arg_5_0:nodeByName("btn_guide"):addTouchEventListener(function(arg_11_0, arg_11_1)
		xyd.buttonScaleAnim(arg_11_0, arg_11_1)

		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.sendGudieBtnClick("btn_guide")
			xyd.WindowManager.get():openWindow("throw_sandbag_guide")
		end
	end)
end

function var_0_0.initModel(arg_12_0)
	for iter_12_0 = 1, 3 do
		local var_12_0 = arg_12_0:nodeByName("node_" .. iter_12_0)
		local var_12_1 = arg_12_0.ids[iter_12_0]
		local var_12_2 = var_0_4:partnerID(var_12_1)
		local var_12_3

		if var_12_2 then
			var_12_3 = var_0_3:modelID(var_12_2)
		else
			var_12_3 = var_0_4:model(var_12_1)
		end

		local var_12_4 = xyd.HeroAnimation.new(var_12_3, var_12_3, xyd.tables.model:uiScale(var_12_3), {})

		var_12_4:addTo(var_12_0)
		var_12_4:idle()
		var_12_4:setScale(0.7)
		var_12_0:getChildByName("text_name"):setString(var_0_4:name(var_12_1))
		var_12_0:getChildByName("choose_light"):setVisible(false)
		var_12_0:getChildByName("choose"):setVisible(false)

		local var_12_5 = display.newNode()

		var_12_5:setAnchorPoint(cc.p(0.5, 0))
		var_12_5:setContentSize(200, 300)
		var_12_5:addTo(var_12_0)
		var_12_5:setTouchEnabled(true)
		var_12_5:setTouchSwallowEnabled(true)
		var_12_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
			if arg_13_0.name == "ended" then
				arg_12_0:updateChoose(iter_12_0)
			end

			return true
		end)
	end

	arg_12_0:updateChoose(1)
end

function var_0_0.updateChoose(arg_14_0, arg_14_1)
	if arg_14_0.chooseID ~= arg_14_1 then
		if arg_14_0.chooseID then
			local var_14_0 = arg_14_0:nodeByName("node_" .. arg_14_0.chooseID)

			var_14_0:getChildByName("choose_light"):setVisible(false)
			var_14_0:getChildByName("choose"):setVisible(false)
		end

		local var_14_1 = arg_14_0:nodeByName("node_" .. arg_14_1)

		var_14_1:getChildByName("choose_light"):setVisible(true)
		var_14_1:getChildByName("choose"):setVisible(true)

		arg_14_0.chooseID = arg_14_1
	end
end

return var_0_0
