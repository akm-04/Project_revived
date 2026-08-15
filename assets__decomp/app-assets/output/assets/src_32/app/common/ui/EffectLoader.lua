local var_0_0 = 1
local var_0_1 = 2
local var_0_2 = 3
local var_0_3 = 4
local var_0_4 = 5
local var_0_5 = 6
local var_0_6 = {
	{
		width = 435,
		height = 665
	},
	{
		width = 172,
		height = 252
	},
	{
		width = 1000,
		height = 720
	},
	{
		width = 140,
		height = 255
	}
}
local var_0_7 = class("EffectLoader", function(arg_1_0, arg_1_1, arg_1_2, arg_1_3, arg_1_4)
	local var_1_0 = ""

	if arg_1_1 == var_0_2 then
		var_1_0 = "images/common/home_card_common.png"
	elseif arg_1_1 == var_0_1 then
		var_1_0 = "images/common/s_card_common.png"
	elseif arg_1_1 == var_0_0 then
		var_1_0 = "images/common/hero_card_common.png"
	elseif arg_1_1 == var_0_3 then
		var_1_0 = "images/common/old_small_card_common.png"
	elseif arg_1_1 == var_0_4 then
		var_1_0 = "images/common/home_card_common.png"
	elseif arg_1_1 == var_0_5 then
		var_1_0 = "images/title_system/unknown.png"
	end

	local var_1_1 = display.newNode()
	local var_1_2 = display.newSprite(var_1_0, 0, 0, params)

	var_1_1:setContentSize(var_1_2:getContentSize())
	var_1_2:setAnchorPoint(0, 0)
	var_1_2:setPosition(0, 0)

	return var_1_1
end)

function var_0_7.ctor(arg_2_0, arg_2_1, arg_2_2, arg_2_3, arg_2_4, arg_2_5)
	local var_2_0 = {
		size = 28,
		color = cc.c3b(255, 255, 255)
	}
	local var_2_1 = arg_2_5 or false

	arg_2_0.label = xyd.AssetLoader.get():loadLabel(var_2_0)

	arg_2_0.label:setMaxLineWidth(50)
	arg_2_0.label:addTo(arg_2_0)
	arg_2_0.label:setName("progress")
	arg_2_0.label:setAnchorPoint(0.5, 0.5)
	arg_2_0.label:setPosition(arg_2_0:getContentSize().width / 2, arg_2_0:getContentSize().height / 2)
	arg_2_0.label:setString("")
	arg_2_0.label:enableOutline(cc.c4b(136, 15, 0, 255), 1)
	xyd.AssetDownload.get():downloadEffectByPath(arg_2_0, arg_2_1, function()
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:removeAllChildren()

			arg_2_3 = arg_2_3 or 1

			if not arg_2_4 then
				arg_2_4 = {}
				arg_2_4.x = 0
				arg_2_4.y = 0
			end

			local var_3_0 = xyd.createEffect(arg_2_1)

			var_3_0:setFlipX(var_2_1)
			var_3_0:setScale(arg_2_3)
			var_3_0:setPosition(arg_2_4.x, arg_2_4.y)

			if arg_2_2 == var_0_4 then
				var_3_0:play(nil, true, nil, "texiao03")
				var_3_0:addTo(arg_2_0)
			elseif arg_2_2 == var_0_2 then
				var_3_0:play(nil, true, nil, "texiao02")
				var_3_0:addTo(arg_2_0)
			elseif arg_2_2 == var_0_5 then
				var_3_0:play(nil, true)
				var_3_0:addTo(arg_2_0)
			else
				var_3_0:play(nil, true, nil, "texiao01")

				local var_3_1

				if arg_2_2 == var_0_0 then
					var_3_1 = xyd.AssetLoader:get():loadSprite("images/dynamic_card.png")
				elseif arg_2_2 == var_0_1 then
					var_3_1 = xyd.AssetLoader:get():loadSprite("images/dynamic_card_small.png")
				else
					var_3_1 = xyd.AssetLoader:get():loadSprite("images/dynamic_card_small_old.png")
				end

				local var_3_2 = var_0_6[arg_2_2]

				var_3_1:setAnchorPoint(0.5, 0.5)
				var_3_1:setPosition(var_3_2.width / 2, var_3_2.height / 2)

				local var_3_3 = cc.ClippingNode:create()

				var_3_3:setStencil(var_3_1)
				var_3_3:setInverted(true)
				var_3_3:setAlphaThreshold(0)
				var_3_3:addTo(arg_2_0)
				var_3_3:addChild(var_3_0)
			end
		end
	end)
end

function var_0_7.setPercent(arg_4_0, arg_4_1)
	if arg_4_0.label and not tolua.isnull(arg_4_0.label) and arg_4_1 then
		arg_4_0.label:setVisible(true)
		arg_4_0.label:setString(arg_4_1 .. "%")
	end
end

return var_0_7
