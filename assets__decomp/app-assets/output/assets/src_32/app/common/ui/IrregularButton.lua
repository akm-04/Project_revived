require("cocos.init")

local var_0_0 = class("IrregularButton", cc.ui.UIPushButton)

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0:loadNormalTransparentInfo()
end

function var_0_0.extend(arg_2_0, arg_2_1)
	local var_2_0 = tolua.getpeer(arg_2_1)

	if not var_2_0 then
		var_2_0 = {}

		tolua.setpeer(arg_2_1, var_2_0)
	end

	setmetatable(var_2_0, var_0_0)

	return arg_2_1
end

function var_0_0.loadNormalTransparentInfo(arg_3_0)
	local var_3_0 = xyd.ImageData:new(arg_3_0.images_[cc.ui.UIPushButton.NORMAL])

	arg_3_0.normalImageWidth_ = var_3_0:getWidth()

	print(arg_3_0.normalImageWidth_)

	arg_3_0.normalImageHeight_ = var_3_0:getHeight()

	print(arg_3_0.normalImageHeight_)

	arg_3_0.normalTransparent_ = {}

	for iter_3_0 = 1, arg_3_0.normalImageHeight_ do
		arg_3_0.normalTransparent_[iter_3_0] = {}

		for iter_3_1 = 1, arg_3_0.normalImageWidth_ do
			if var_3_0:getAlpha(iter_3_1, arg_3_0.normalImageHeight_ - iter_3_0) == 0 then
				arg_3_0.normalTransparent_[iter_3_0][iter_3_1] = true
			else
				arg_3_0.normalTransparent_[iter_3_0][iter_3_1] = false
			end
		end
	end
end

function var_0_0.getIsTransparentAtPoint(arg_4_0, arg_4_1, arg_4_2)
	arg_4_1 = math.round(arg_4_1)

	if arg_4_1 < 1 then
		arg_4_1 = 1
	elseif arg_4_1 > arg_4_0.normalImageWidth_ then
		arg_4_1 = arg_4_0.normalImageWidth_
	end

	arg_4_2 = math.round(arg_4_2)

	if arg_4_2 < 1 then
		arg_4_2 = 1
	elseif arg_4_2 > arg_4_0.normalImageHeight_ then
		arg_4_2 = arg_4_0.normalImageHeight_
	end

	return arg_4_0.normalTransparent_[arg_4_2][arg_4_1]
end

function var_0_0.checkTouchInSprite_(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_0.sprite_[1]:convertToNodeSpace(cc.p(arg_5_1, arg_5_2))

	if arg_5_0.touchInSpriteOnly_ then
		return arg_5_0.sprite_[1] and arg_5_0.sprite_[1]:getCascadeBoundingBox():containsPoint(cc.p(arg_5_1, arg_5_2)) and not arg_5_0:getIsTransparentAtPoint(var_5_0.x, var_5_0.y)
	else
		return arg_5_0:getCascadeBoundingBox():containsPoint(cc.p(arg_5_1, arg_5_2)) and not arg_5_0:getIsTransparentAtPoint(var_5_0.x, var_5_0.y)
	end
end

return var_0_0
