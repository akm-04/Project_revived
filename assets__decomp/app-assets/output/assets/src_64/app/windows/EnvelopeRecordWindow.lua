local var_0_0 = class("EnvelopeRecordWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.grabPlayers = arg_1_2.players
	arg_1_0.envelopeID = arg_1_2.id
	arg_1_0.num = arg_1_2.num
	arg_1_0.redEnvelope = xyd.ModelManager.get():loadModel(xyd.ModelType.RED_ENVELOPE)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)

	arg_2_0.list = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, 435, 400),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(arg_2_0:nodeByName("list"))
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:layoutDesc()
	arg_3_0:updateRecordList()
	arg_3_0:addBlockLayer()
end

function var_0_0.layoutDesc(arg_4_0)
	local var_4_0 = xyd.tables.redEnvelope:pacMoney(arg_4_0.envelopeID) * arg_4_0.num
	local var_4_1 = xyd.tables.redEnvelope:pacAmount(arg_4_0.envelopeID) * arg_4_0.num
	local var_4_2 = display.newNode()

	var_4_2:setAnchorPoint(cc.p(0, 0))
	var_4_2:addTo(arg_4_0:nodeByName("bg"))

	local var_4_3 = {
		arg_4_0:createLabel(cc.c3b(102, 22, 6), 24),
		arg_4_0:createLabel(cc.c3b(48, 228, 227), 24),
		arg_4_0:createLabel(cc.c3b(102, 22, 6), 24),
		arg_4_0:createLabel(cc.c3b(48, 228, 227), 24),
		(arg_4_0:createLabel(cc.c3b(102, 22, 6), 24))
	}

	var_4_3[1]:setString(var_0_1:translation("TOTAL_WORD"))
	var_4_3[2]:setString(var_4_0)
	var_4_3[3]:setString(var_0_1:translation("HAVE_RECIEVE"))
	var_4_3[4]:setString(#arg_4_0.grabPlayers .. "/" .. var_4_1)
	var_4_3[5]:setString(var_0_1:translation("GE"))
	var_4_3[2]:enableShadow(cc.c4b(0, 0, 0, 255), cc.size(1, -1), 2)
	var_4_3[4]:enableShadow(cc.c4b(0, 0, 0, 255), cc.size(1, -1), 2)

	local var_4_4 = 0

	for iter_4_0 = 1, #var_4_3 do
		var_4_3[iter_4_0]:addTo(var_4_2)

		var_4_4 = var_4_4 + var_4_3[iter_4_0]:getContentSize().width + 2

		if iter_4_0 == 1 then
			var_4_3[iter_4_0]:setPosition(0, 0)
		else
			local var_4_5 = var_4_3[iter_4_0 - 1]:getContentSize().width

			var_4_3[iter_4_0]:setPosition(var_4_3[iter_4_0 - 1]:getPositionX() + var_4_5 + 2, 0)
		end
	end

	var_4_2:setContentSize(var_4_4, var_4_3[1]:getHeight())
	var_4_2:setPosition(arg_4_0:nodeByName("desc_pos"):getPositionX() - 0.5 * var_4_4, arg_4_0:nodeByName("desc_pos"):getPositionY())
end

function var_0_0.createLabel(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = {
		color = arg_5_1,
		size = arg_5_2
	}
	local var_5_1 = xyd.AssetLoader.get():loadLabel(var_5_0)

	if arg_5_3 then
		var_5_1:setMaxLineWidth(arg_5_3)
	end

	return var_5_1
end

function var_0_0.updateRecordList(arg_6_0)
	for iter_6_0 = 1, #arg_6_0.grabPlayers do
		local var_6_0 = arg_6_0.grabPlayers[iter_6_0]
		local var_6_1 = display.newNode()
		local var_6_2 = arg_6_0.list:newItem()
		local var_6_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/red_envelope/grab_record_item.csb")
		local var_6_4 = var_6_3:getChildByName("container")

		var_6_4:getChildByName("get_desc_txt"):setString(var_0_1:translation("ENVELOPE_RECORD_TIP"))
		var_6_4:getChildByName("reward_num_txt"):setString(var_6_0.grab_money)
		var_6_4:getChildByName("name_txt"):setString(var_6_0.player_name)
		var_6_4:getChildByName("region_txt"):setString("S" .. tostring(xyd.getPlayerRegion(var_6_0.player_id)))

		local var_6_5, var_6_6 = var_6_4:getChildByName("avatar_pos"):getPosition()
		local var_6_7 = display.newNode()

		var_6_4:getChildByName("avatar_kuang"):setVisible(false)
		var_6_7:setContentSize(90, 90)
		var_6_7:setPosition(var_6_5, var_6_6)
		var_6_7:setAnchorPoint(cc.p(0.5, 0.5))
		var_6_7:addTo(var_6_4)

		local var_6_8 = var_6_0

		var_6_8.playerInfo = var_6_0

		xyd.setPlayerAvatar(var_6_7, var_6_8)
		var_6_3:addTo(var_6_1)
		var_6_3:setAnchorPoint(cc.p(0, 0))
		var_6_1:setContentSize(var_6_4:getContentSize())
		var_6_2:addContent(var_6_1)
		var_6_2:setItemSize(var_6_4:getWidth(), var_6_4:getHeight() + 10)
		arg_6_0.list:addItem(var_6_2)
	end

	arg_6_0.list:reload()
end

return var_0_0
