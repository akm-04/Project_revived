local var_0_0 = require("lib.battle.framework.cocos")
local var_0_1 = ngx
local var_0_2 = var_0_0.getXinyoudi(var_0_1)
local var_0_3 = var_0_0.class("BattleBaseNode")
local var_0_4 = 10

function var_0_3.ctor(arg_1_0)
	arg_1_0.x_ = 0
	arg_1_0.y_ = 0
	arg_1_0.w_ = 0
	arg_1_0.h_ = 0
	arg_1_0.scale_ = 1
	arg_1_0.flipX_ = false
end

function var_0_3.getX(arg_2_0)
	return arg_2_0.x_
end

function var_0_3.getY(arg_3_0)
	return arg_3_0.y_
end

function var_0_3.getPosition(arg_4_0)
	return arg_4_0.x_, arg_4_0.y_
end

function var_0_3.getPos(arg_5_0)
	return arg_5_0.x_, arg_5_0.y_
end

function var_0_3.x(arg_6_0, arg_6_1)
	arg_6_0.x_ = arg_6_1 or arg_6_0.x_

	return arg_6_0
end

function var_0_3.y(arg_7_0, arg_7_1)
	arg_7_0.y_ = arg_7_1 or arg_7_0.y_

	return arg_7_0
end

function var_0_3.moveByX(arg_8_0, arg_8_1)
	arg_8_0.x_ = arg_8_0.x_ + (arg_8_1 or 0)
end

function var_0_3.moveByY(arg_9_0, arg_9_1)
	arg_9_0.y_ = arg_9_0.y_ + (arg_9_1 or 0)
end

function var_0_3.moveBy(arg_10_0, arg_10_1, arg_10_2)
	arg_10_0.x_ = arg_10_0.x_ + (arg_10_1 or 0)
	arg_10_0.y_ = arg_10_0.y_ + (arg_10_2 or 0)
end

function var_0_3.pos(arg_11_0, arg_11_1, arg_11_2)
	arg_11_0.x_ = arg_11_1
	arg_11_0.y_ = arg_11_2

	return arg_11_0
end

function var_0_3.addTo(arg_12_0, arg_12_1)
	return arg_12_0
end

function var_0_3.addChild(arg_13_0, arg_13_1)
	if arg_13_1 and var_0_0.iskindof(arg_13_1, arg_13_0.__cname) then
		arg_13_1:addTo(arg_13_0)
	end
end

function var_0_3.reset(arg_14_0)
	arg_14_0.x_ = 0
	arg_14_0.y_ = 0
end

function var_0_3.getSizeX(arg_15_0)
	return arg_15_0.w_
end

function var_0_3.rotation(arg_16_0)
	return
end

function var_0_3.rotate(arg_17_0)
	return
end

function var_0_3.getRotationSkewX(arg_18_0)
	return
end

function var_0_3.playRepeat(arg_19_0)
	return
end

function var_0_3.play(arg_20_0, arg_20_1)
	return
end

function var_0_3.playOnce(arg_21_0, arg_21_1)
	return
end

function var_0_3.stop(arg_22_0)
	return
end

function var_0_3.flipX(arg_23_0, arg_23_1)
	arg_23_0:setFlipX(arg_23_1)
end

function var_0_3.setFlipX(arg_24_0, arg_24_1)
	arg_24_0.flipX_ = arg_24_1
end

function var_0_3.getFlipX(arg_25_0)
	return arg_25_0.flipX_
end

function var_0_3.setContentSize(arg_26_0, arg_26_1, arg_26_2)
	arg_26_0:size(arg_26_1, arg_26_2)
end

function var_0_3.getContentSize(arg_27_0)
	return arg_27_0.w_, arg_27_0.h_
end

function var_0_3.size(arg_28_0, arg_28_1, arg_28_2)
	arg_28_0.w_ = arg_28_1
	arg_28_0.h_ = arg_28_2
end

function var_0_3.getWidth(arg_29_0)
	return arg_29_0.w_
end

function var_0_3.getHeight(arg_30_0)
	return arg_30_0.h_
end

function var_0_3.setScale(arg_31_0, arg_31_1)
	arg_31_0.scale_ = arg_31_1
end

function var_0_3.setScaleX(arg_32_0, arg_32_1)
	arg_32_0.scale_ = arg_32_1
end

function var_0_3.setScaleY(arg_33_0, arg_33_1)
	arg_33_0.scale_ = arg_33_1
end

function var_0_3.scale(arg_34_0, arg_34_1)
	arg_34_0.scale_ = arg_34_1
end

function var_0_3.scaleX(arg_35_0, arg_35_1)
	arg_35_0.scale_ = arg_35_1
end

function var_0_3.scaleY(arg_36_0, arg_36_1)
	arg_36_0.scale_ = arg_36_1
end

function var_0_3.getScale(arg_37_0)
	return arg_37_0.scale_
end

function var_0_3.getScaleX(arg_38_0)
	return arg_38_0.scale_
end

function var_0_3.getScaleY(arg_39_0)
	return arg_39_0.scale_
end

function var_0_3.show(arg_40_0)
	return
end

function var_0_3.hide(arg_41_0)
	return
end

function var_0_3.setVisible(arg_42_0)
	return
end

function var_0_3.retain(arg_43_0)
	return
end

function var_0_3.release(arg_44_0)
	return
end

function var_0_3.setLocalZOrder(arg_45_0)
	return
end

function var_0_3.setRotation(arg_46_0)
	return
end

function var_0_3.removeSelf(arg_47_0)
	return
end

function var_0_3.getChildren(arg_48_0)
	return {}
end

function var_0_3.removeAllChildren(arg_49_0)
	return
end

function var_0_3.getChildByName(arg_50_0)
	return
end

function var_0_3.setMaskColor(arg_51_0, arg_51_1)
	return
end

function var_0_3.unsetMaskColor(arg_52_0)
	return
end

function var_0_3.setGrayScale(arg_53_0, arg_53_1)
	return
end

function var_0_3.unsetGrayScale(arg_54_0)
	return
end

return var_0_3
