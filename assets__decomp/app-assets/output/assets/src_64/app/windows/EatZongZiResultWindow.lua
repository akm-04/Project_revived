local var_0_0 = class("EatZongZiResultWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = "skeletons/ui_effect/effect_redpacket/effect_redpacket1"
local var_0_4 = 5

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.award = arg_1_2.awards[1]
	arg_1_0.zongziId = arg_1_2.zongzi_id
	arg_1_0.zongziType = xyd.tables.zongZiTable:type(arg_1_0.zongziId)

	arg_1_0:initialReWard()
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:addBlockLayer()
end

function var_0_0.initialReWard(arg_4_0)
	arg_4_0.itemNum = arg_4_0.award.item_num

	if arg_4_0.award.crystal then
		arg_4_0.itemId = -1
	elseif arg_4_0.award.mana then
		arg_4_0.itemId = -2
	elseif arg_4_0.award.table_id > 0 then
		arg_4_0.itemId = arg_4_0.award.table_id

		arg_4_0.selfPlayer:getBackpack():addItemsByID(tonumber(arg_4_0.itemId), tonumber(arg_4_0.itemNum))
	end
end

function var_0_0.layout(arg_5_0)
	arg_5_0:setAllZongZiInvisible()
	arg_5_0:nodeByName("zongzi_" .. arg_5_0.zongziType):setVisible(true)
	arg_5_0:nodeByName("jinbi"):setVisible(false)
	arg_5_0:nodeByName("zhuansi"):setVisible(false)

	if arg_5_0.itemId then
		if arg_5_0.itemId == -2 then
			arg_5_0:nodeByName("jinbi"):setVisible(true)
		elseif arg_5_0.itemId == -1 then
			arg_5_0:nodeByName("zhuansi"):setVisible(true)
		else
			xyd.setItemBorder(arg_5_0:nodeByName("item_container"), arg_5_0.itemId)
		end
	end

	arg_5_0:nodeByName("reward_num_txt"):setString(arg_5_0.itemNum)
	arg_5_0:nodeByName("get_reward_txt"):setString(var_0_1:translation("ZONGZI_REWARD"))

	local var_5_0 = xyd.split(var_0_1:translation("ZONGZI_TYPE_NAME"), ",")
	local var_5_1 = string.format(var_0_1:translation("GET_ZONGZI_DESC"), var_5_0[arg_5_0.zongziType])

	arg_5_0:nodeByName("get_zongzi_tip"):setString(var_5_1)
	arg_5_0:playEffect()
end

function var_0_0.playEffect(arg_6_0)
	local var_6_0 = var_0_3 .. ".json"
	local var_6_1 = var_0_3 .. ".atlas"

	arg_6_0.redEnvelopeEffect = var_0_2.new(var_6_0, var_6_1, 1)

	arg_6_0.redEnvelopeEffect:addTo(arg_6_0:nodeByName("zongzi_" .. arg_6_0.zongziType):getParent(), -1)
	arg_6_0.redEnvelopeEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_6_0.redEnvelopeEffect:setPosition(arg_6_0:nodeByName("zongzi_pos"):getPosition())
	arg_6_0.redEnvelopeEffect:play(function()
		arg_6_0.redEnvelopeEffect:setVisible(false)
	end, true)
end

function var_0_0.setAllZongZiInvisible(arg_8_0)
	for iter_8_0 = 1, var_0_4 do
		arg_8_0:nodeByName("zongzi_" .. iter_8_0):setVisible(false)
	end
end

return var_0_0
