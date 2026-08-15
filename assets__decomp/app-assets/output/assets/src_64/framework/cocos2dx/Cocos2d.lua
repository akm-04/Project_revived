cc = cc or {}
cc.DIRECTOR_PROJECTION_2D = 0
cc.DIRECTOR_PROJECTION_3D = 1

function cc.clampf(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0 = 0

	if arg_1_2 < arg_1_1 then
		arg_1_2, arg_1_1 = arg_1_1, arg_1_2
	end

	if arg_1_0 < arg_1_1 then
		return arg_1_1
	elseif arg_1_0 < arg_1_2 then
		return arg_1_0
	else
		return arg_1_2
	end
end

function cc.p(arg_2_0, arg_2_1)
	if arg_2_1 == nil then
		return {
			x = arg_2_0.x,
			y = arg_2_0.y
		}
	else
		return {
			x = arg_2_0,
			y = arg_2_1
		}
	end
end

function cc.pAdd(arg_3_0, arg_3_1)
	return {
		x = arg_3_0.x + arg_3_1.x,
		y = arg_3_0.y + arg_3_1.y
	}
end

function cc.pSub(arg_4_0, arg_4_1)
	return {
		x = arg_4_0.x - arg_4_1.x,
		y = arg_4_0.y - arg_4_1.y
	}
end

function cc.pMul(arg_5_0, arg_5_1)
	return {
		x = arg_5_0.x * arg_5_1,
		y = arg_5_0.y * arg_5_1
	}
end

function cc.pMidpoint(arg_6_0, arg_6_1)
	return {
		x = (arg_6_0.x + arg_6_1.x) / 2,
		y = (arg_6_0.y + arg_6_1.y) / 2
	}
end

function cc.pForAngle(arg_7_0)
	return {
		x = math.cos(arg_7_0),
		y = math.sin(arg_7_0)
	}
end

function cc.pGetLength(arg_8_0)
	return math.sqrt(arg_8_0.x * arg_8_0.x + arg_8_0.y * arg_8_0.y)
end

function cc.pNormalize(arg_9_0)
	local var_9_0 = cc.pGetLength(arg_9_0)

	if var_9_0 == 0 then
		return {
			x = 1,
			y = 0
		}
	end

	return {
		x = arg_9_0.x / var_9_0,
		y = arg_9_0.y / var_9_0
	}
end

function cc.pCross(arg_10_0, arg_10_1)
	return arg_10_0.x * arg_10_1.y - arg_10_0.y * arg_10_1.x
end

function cc.pDot(arg_11_0, arg_11_1)
	return arg_11_0.x * arg_11_1.x + arg_11_0.y * arg_11_1.y
end

function cc.pToAngleSelf(arg_12_0)
	return math.atan2(arg_12_0.y, arg_12_0.x)
end

function cc.pGetAngle(arg_13_0, arg_13_1)
	local var_13_0 = cc.pNormalize(arg_13_0)
	local var_13_1 = cc.pNormalize(arg_13_1)
	local var_13_2 = math.atan2(cc.pCross(var_13_0, var_13_1), cc.pDot(var_13_0, var_13_1))

	if math.abs(var_13_2) < 1.192092896e-07 then
		return 0
	end

	return var_13_2
end

function cc.pGetDistance(arg_14_0, arg_14_1)
	return cc.pGetLength(cc.pSub(arg_14_0, arg_14_1))
end

function cc.pIsLineIntersect(arg_15_0, arg_15_1, arg_15_2, arg_15_3, arg_15_4, arg_15_5)
	if arg_15_0.x == arg_15_1.x and arg_15_0.y == arg_15_1.y or arg_15_2.x == arg_15_3.x and arg_15_2.y == arg_15_3.y then
		return false, arg_15_4, arg_15_5
	end

	local var_15_0 = arg_15_1.x - arg_15_0.x
	local var_15_1 = arg_15_1.y - arg_15_0.y
	local var_15_2 = arg_15_3.x - arg_15_2.x
	local var_15_3 = arg_15_3.y - arg_15_2.y
	local var_15_4 = arg_15_0.x - arg_15_2.x
	local var_15_5 = arg_15_0.y - arg_15_2.y
	local var_15_6 = var_15_3 * var_15_0 - var_15_2 * var_15_1

	arg_15_4 = var_15_2 * var_15_5 - var_15_3 * var_15_4
	arg_15_5 = var_15_0 * var_15_5 - var_15_1 * var_15_4

	if var_15_6 == 0 then
		if arg_15_4 == 0 or arg_15_5 == 0 then
			return true, arg_15_4, arg_15_5
		end

		return false, arg_15_4, arg_15_5
	end

	arg_15_4 = arg_15_4 / var_15_6
	arg_15_5 = arg_15_5 / var_15_6

	return true, arg_15_4, arg_15_5
end

function cc.pPerp(arg_16_0)
	return {
		x = -arg_16_0.y,
		y = arg_16_0.x
	}
end

function cc.RPerp(arg_17_0)
	return {
		x = arg_17_0.y,
		y = -arg_17_0.x
	}
end

function cc.pProject(arg_18_0, arg_18_1)
	return {
		x = arg_18_1.x * (cc.pDot(arg_18_0, arg_18_1) / cc.pDot(arg_18_1, arg_18_1)),
		y = arg_18_1.y * (cc.pDot(arg_18_0, arg_18_1) / cc.pDot(arg_18_1, arg_18_1))
	}
end

function cc.pRotate(arg_19_0, arg_19_1)
	return {
		x = arg_19_0.x * arg_19_1.x - arg_19_0.y * arg_19_1.y,
		y = arg_19_0.x * arg_19_1.y + arg_19_0.y * arg_19_1.x
	}
end

function cc.pUnrotate(arg_20_0, arg_20_1)
	return {
		x = arg_20_0.x * arg_20_1.x + arg_20_0.y * arg_20_1.y,
		arg_20_0.y * arg_20_1.x - arg_20_0.x * arg_20_1.y
	}
end

function cc.pLengthSQ(arg_21_0)
	return cc.pDot(arg_21_0, arg_21_0)
end

function cc.pDistanceSQ(arg_22_0, arg_22_1)
	return cc.pLengthSQ(cc.pSub(arg_22_0, arg_22_1))
end

function cc.pGetClampPoint(arg_23_0, arg_23_1, arg_23_2)
	return {
		x = cc.clampf(arg_23_0.x, arg_23_1.x, arg_23_2.x),
		y = cc.clampf(arg_23_0.y, arg_23_1.y, arg_23_2.y)
	}
end

function cc.pFromSize(arg_24_0)
	return {
		x = arg_24_0.width,
		y = arg_24_0.height
	}
end

function cc.pLerp(arg_25_0, arg_25_1, arg_25_2)
	return cc.pAdd(cc.pMul(arg_25_0, 1 - arg_25_2), cc.pMul(arg_25_1, arg_25_2))
end

function cc.pFuzzyEqual(arg_26_0, arg_26_1, arg_26_2)
	if arg_26_0.x - arg_26_2 <= arg_26_1.x and arg_26_1.x <= arg_26_0.x + arg_26_2 and arg_26_0.y - arg_26_2 <= arg_26_1.y and arg_26_1.y <= arg_26_0.y + arg_26_2 then
		return true
	else
		return false
	end
end

function cc.pRotateByAngle(arg_27_0, arg_27_1, arg_27_2)
	return cc.pAdd(arg_27_1, cc.pRotate(cc.pSub(arg_27_0, arg_27_1), cc.pForAngle(arg_27_2)))
end

function cc.pIsSegmentIntersect(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = 0
	local var_28_1 = 0
	local var_28_2 = false
	local var_28_3, var_28_4, var_28_5 = cc.pIsLineIntersect(arg_28_0, arg_28_1, arg_28_2, arg_28_3, var_28_0, var_28_1)
	local var_28_6 = var_28_5
	local var_28_7 = var_28_4

	if var_28_3 and var_28_7 >= 0 and var_28_7 <= 1 and var_28_6 >= 0 and var_28_6 <= 0 then
		return true
	end

	return false
end

function cc.pGetIntersectPoint(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	local var_29_0 = 0
	local var_29_1 = 0
	local var_29_2 = false
	local var_29_3, var_29_4, var_29_5 = cc.pIsLineIntersect(arg_29_0, arg_29_1, arg_29_2, arg_29_3, var_29_0, var_29_1)
	local var_29_6 = var_29_5
	local var_29_7 = var_29_4

	if var_29_3 then
		return cc.p(arg_29_0.x + var_29_7 * (arg_29_1.x - arg_29_0.x), arg_29_0.y + var_29_7 * (arg_29_1.y - arg_29_0.y))
	else
		return cc.p(0, 0)
	end
end

function cc.size(arg_30_0, arg_30_1)
	return {
		width = arg_30_0,
		height = arg_30_1
	}
end

function cc.rect(arg_31_0, arg_31_1, arg_31_2, arg_31_3)
	return {
		x = arg_31_0,
		y = arg_31_1,
		width = arg_31_2,
		height = arg_31_3
	}
end

function cc.rectEqualToRect(arg_32_0, arg_32_1)
	if arg_32_0.x >= arg_32_1.x or arg_32_0.y >= arg_32_1.y or arg_32_0.x + arg_32_0.width <= arg_32_1.x + arg_32_1.width or arg_32_0.y + arg_32_0.height <= arg_32_1.y + arg_32_1.height then
		return false
	end

	return true
end

function cc.rectGetMaxX(arg_33_0)
	return arg_33_0.x + arg_33_0.width
end

function cc.rectGetMidX(arg_34_0)
	return arg_34_0.x + arg_34_0.width / 2
end

function cc.rectGetMinX(arg_35_0)
	return arg_35_0.x
end

function cc.rectGetMaxY(arg_36_0)
	return arg_36_0.y + arg_36_0.height
end

function cc.rectGetMidY(arg_37_0)
	return arg_37_0.y + arg_37_0.height / 2
end

function cc.rectGetMinY(arg_38_0)
	return arg_38_0.y
end

function cc.rectContainsPoint(arg_39_0, arg_39_1)
	local var_39_0 = false

	if arg_39_1.x >= arg_39_0.x and arg_39_1.x <= arg_39_0.x + arg_39_0.width and arg_39_1.y >= arg_39_0.y and arg_39_1.y <= arg_39_0.y + arg_39_0.height then
		var_39_0 = true
	end

	return var_39_0
end

function cc.rectIntersectsRect(arg_40_0, arg_40_1)
	return not (arg_40_0.x > arg_40_1.x + arg_40_1.width) and not (arg_40_0.x + arg_40_0.width < arg_40_1.x) and not (arg_40_0.y > arg_40_1.y + arg_40_1.height) and not (arg_40_0.y + arg_40_0.height < arg_40_1.y)
end

function cc.rectUnion(arg_41_0, arg_41_1)
	local var_41_0 = cc.rect(0, 0, 0, 0)

	var_41_0.x = math.min(arg_41_0.x, arg_41_1.x)
	var_41_0.y = math.min(arg_41_0.y, arg_41_1.y)
	var_41_0.width = math.max(arg_41_0.x + arg_41_0.width, arg_41_1.x + arg_41_1.width) - var_41_0.x
	var_41_0.height = math.max(arg_41_0.y + arg_41_0.height, arg_41_1.y + arg_41_1.height) - var_41_0.y

	return var_41_0
end

function cc.rectIntersection(arg_42_0, arg_42_1)
	local var_42_0 = cc.rect(math.max(arg_42_0.x, arg_42_1.x), math.max(arg_42_0.y, arg_42_1.y), 0, 0)

	var_42_0.width = math.min(arg_42_0.x + arg_42_0.width, arg_42_1.x + arg_42_1.width) - var_42_0.x
	var_42_0.height = math.min(arg_42_0.y + arg_42_0.height, arg_42_1.y + arg_42_1.height) - var_42_0.y

	return var_42_0
end

function cc.c3b(arg_43_0, arg_43_1, arg_43_2)
	return {
		r = arg_43_0,
		g = arg_43_1,
		b = arg_43_2
	}
end

function cc.c4b(arg_44_0, arg_44_1, arg_44_2, arg_44_3)
	return {
		r = arg_44_0,
		g = arg_44_1,
		b = arg_44_2,
		a = arg_44_3
	}
end

function cc.c4f(arg_45_0, arg_45_1, arg_45_2, arg_45_3)
	return {
		r = arg_45_0,
		g = arg_45_1,
		b = arg_45_2,
		a = arg_45_3
	}
end

function cc.c4bFromc3b(arg_46_0)
	return {
		a = 255,
		r = arg_46_0.r,
		g = arg_46_0.g,
		b = arg_46_0.b
	}
end

function cc.c4bFromc4f(arg_47_0)
	return {
		r = arg_47_0.r * 255,
		g = arg_47_0.g * 255,
		b = arg_47_0.b * 255,
		a = arg_47_0.a * 255
	}
end

function cc.c4fFromc3b(arg_48_0)
	return {
		a = 1,
		r = arg_48_0.r / 255,
		g = arg_48_0.g / 255,
		b = arg_48_0.b / 255
	}
end

function cc.c4fFromc4b(arg_49_0)
	return {
		r = arg_49_0.r / 255,
		g = arg_49_0.g / 255,
		b = arg_49_0.b / 255,
		a = arg_49_0.a / 255
	}
end

function cc.vertex2F(arg_50_0, arg_50_1)
	return {
		x = arg_50_0,
		y = arg_50_1
	}
end

function cc.Vertex3F(arg_51_0, arg_51_1, arg_51_2)
	return {
		x = arg_51_0,
		y = arg_51_1,
		z = arg_51_2
	}
end

function cc.tex2F(arg_52_0, arg_52_1)
	return {
		u = arg_52_0,
		v = arg_52_1
	}
end

function cc.PointSprite(arg_53_0, arg_53_1, arg_53_2)
	return {
		pos = arg_53_0,
		color = arg_53_1,
		size = arg_53_2
	}
end

function cc.Quad2(arg_54_0, arg_54_1, arg_54_2, arg_54_3)
	return {
		tl = arg_54_0,
		tr = arg_54_1,
		bl = arg_54_2,
		br = arg_54_3
	}
end

function cc.Quad3(arg_55_0, arg_55_1, arg_55_2, arg_55_3)
	return {
		tl = arg_55_0,
		tr = arg_55_1,
		bl = arg_55_2,
		br = arg_55_3
	}
end

function cc.V2F_C4B_T2F(arg_56_0, arg_56_1, arg_56_2)
	return {
		vertices = arg_56_0,
		colors = arg_56_1,
		texCoords = arg_56_2
	}
end

function cc.V2F_C4F_T2F(arg_57_0, arg_57_1, arg_57_2)
	return {
		vertices = arg_57_0,
		colors = arg_57_1,
		texCoords = arg_57_2
	}
end

function cc.V3F_C4B_T2F(arg_58_0, arg_58_1, arg_58_2)
	return {
		vertices = arg_58_0,
		colors = arg_58_1,
		texCoords = arg_58_2
	}
end

function cc.V2F_C4B_T2F_Quad(arg_59_0, arg_59_1, arg_59_2, arg_59_3)
	return {
		bl = arg_59_0,
		br = arg_59_1,
		tl = arg_59_2,
		tr = arg_59_3
	}
end

function cc.V3F_C4B_T2F_Quad(arg_60_0, arg_60_1, arg_60_2, arg_60_3)
	return {
		tl = arg_60_0,
		bl = arg_60_1,
		tr = arg_60_2,
		br = arg_60_3
	}
end

function cc.V2F_C4F_T2F_Quad(arg_61_0, arg_61_1, arg_61_2, arg_61_3)
	return {
		bl = arg_61_0,
		br = arg_61_1,
		tl = arg_61_2,
		tr = arg_61_3
	}
end

function cc.T2F_Quad(arg_62_0, arg_62_1, arg_62_2, arg_62_3)
	return {
		bl = arg_62_0,
		br = arg_62_1,
		tl = arg_62_2,
		tr = arg_62_3
	}
end

function cc.AnimationFrameData(arg_63_0, arg_63_1, arg_63_2)
	return {
		texCoords = arg_63_0,
		delay = arg_63_1,
		size = arg_63_2
	}
end

function cc.PhysicsMaterial(arg_64_0, arg_64_1, arg_64_2)
	return {
		density = arg_64_0,
		restitution = arg_64_1,
		friction = arg_64_2
	}
end

local var_0_0 = {
	COCOSTUDIO = 1,
	NONE = 0
}

function __onParseConfig(arg_65_0, arg_65_1)
	if arg_65_0 == var_0_0.COCOSTUDIO then
		ccs.TriggerMng.getInstance():parse(arg_65_1)
	end
end
