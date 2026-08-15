local var_0_0 = class("UIScrollView", function(arg_1_0)
	if arg_1_0.clippingType == xyd.ScrollViewClippingType.STENCIL then
		return cc.ClippingNode:create()
	else
		return cc.ClippingRegionNode:create()
	end
end)

var_0_0.BG_ZORDER = -100
var_0_0.TOUCH_ZORDER = -99
var_0_0.DIRECTION_BOTH = 0
var_0_0.DIRECTION_VERTICAL = 1
var_0_0.DIRECTION_HORIZONTAL = 2

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.clippingType = arg_2_1.clippingType or xyd.ScrollViewClippingType.REGION
	arg_2_0.bBounce = true
	arg_2_0.bTopBounce = true
	arg_2_0.nShakeVal = 5
	arg_2_0.direction = var_0_0.DIRECTION_BOTH
	arg_2_0.layoutPadding = {
		top = 0,
		bottom = 0,
		left = 0,
		right = 0
	}
	arg_2_0.speed = {
		x = 0,
		y = 0
	}

	if not arg_2_1 then
		return
	end

	if arg_2_1.viewRect then
		arg_2_0:setViewRect(arg_2_1.viewRect)
	end

	if arg_2_1.direction then
		arg_2_0:setDirection(arg_2_1.direction)
	end

	if arg_2_1.scrollbarImgH then
		arg_2_0.sbH = display.newScale9Sprite(arg_2_1.scrollbarImgH, 100):addTo(arg_2_0)
	end

	if arg_2_1.scrollbarImgV then
		arg_2_0.sbV = display.newScale9Sprite(arg_2_1.scrollbarImgV, 100):addTo(arg_2_0)
	end

	arg_2_0:setTouchType(arg_2_1.touchOnContent or true)
	arg_2_0:addBgColorIf(arg_2_1)
	arg_2_0:addBgGradientColorIf(arg_2_1)
	arg_2_0:addBgIf(arg_2_1)
	arg_2_0:addNodeEventListener(cc.NODE_ENTER_FRAME_EVENT, function(...)
		arg_2_0:update_(...)
	end)
	arg_2_0:scheduleUpdate()
end

function scheduleUpdate()
	print(self:getScrollNode():getPosition())
end

function var_0_0.addBgColorIf(arg_5_0, arg_5_1)
	if not arg_5_1.bgColor then
		return
	end

	cc.LayerColor:create(arg_5_1.bgColor):size(arg_5_1.viewRect.width, arg_5_1.viewRect.height):pos(arg_5_1.viewRect.x, arg_5_1.viewRect.y):addTo(arg_5_0, var_0_0.BG_ZORDER):setTouchEnabled(false)
end

function var_0_0.addBgGradientColorIf(arg_6_0, arg_6_1)
	if not arg_6_1.bgStartColor or not arg_6_1.bgEndColor then
		return
	end

	cc.LayerGradient:create(arg_6_1.bgStartColor, arg_6_1.bgEndColor):size(arg_6_1.viewRect.width, arg_6_1.viewRect.height):pos(arg_6_1.viewRect.x, arg_6_1.viewRect.y):addTo(arg_6_0, var_0_0.BG_ZORDER):setTouchEnabled(false):setVector(arg_6_1.bgVector)
end

function var_0_0.addBgIf(arg_7_0, arg_7_1)
	if not arg_7_1.bg then
		return
	end

	local var_7_0

	if arg_7_1.bgScale9 then
		var_7_0 = display.newScale9Sprite(arg_7_1.bg, nil, nil, nil, arg_7_1.capInsets)
	else
		var_7_0 = display.newSprite(arg_7_1.bg)
	end

	var_7_0:size(arg_7_1.viewRect.width, arg_7_1.viewRect.height):pos(arg_7_1.viewRect.x + arg_7_1.viewRect.width / 2, arg_7_1.viewRect.y + arg_7_1.viewRect.height / 2):addTo(arg_7_0, var_0_0.BG_ZORDER):setTouchEnabled(false)
end

function var_0_0.setViewRect(arg_8_0, arg_8_1)
	if arg_8_0.clippingType == xyd.ScrollViewClippingType.STENCIL then
		local var_8_0 = display.newScale9Sprite("images/line_mask.png", 0, 0, cc.size(arg_8_1.width, arg_8_1.height))

		var_8_0:setAnchorPoint(0, 0)
		arg_8_0:setStencil(var_8_0)
	else
		arg_8_0:setClippingRegion(arg_8_1)
	end

	arg_8_0.viewRect_ = arg_8_1
	arg_8_0.viewRectIsNodeSpace = false

	return arg_8_0
end

function var_0_0.getViewRect(arg_9_0)
	return arg_9_0.viewRect_
end

function var_0_0.setLayoutPadding(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
	if not arg_10_0.layoutPadding then
		arg_10_0.layoutPadding = {}
	end

	arg_10_0.layoutPadding.top = arg_10_1
	arg_10_0.layoutPadding.right = arg_10_2
	arg_10_0.layoutPadding.bottom = arg_10_3
	arg_10_0.layoutPadding.left = arg_10_4

	return arg_10_0
end

function var_0_0.setActualRect(arg_11_0, arg_11_1)
	arg_11_0.actualRect_ = arg_11_1
end

function var_0_0.setDirection(arg_12_0, arg_12_1)
	arg_12_0.direction = arg_12_1

	return arg_12_0
end

function var_0_0.getDirection(arg_13_0)
	return arg_13_0.direction
end

function var_0_0.setBounceable(arg_14_0, arg_14_1)
	arg_14_0.bBounce = arg_14_1

	return arg_14_0
end

function var_0_0.setTopBounceable(arg_15_0, arg_15_1)
	arg_15_0.bTopBounce = arg_15_1

	return arg_15_0
end

function var_0_0.setTouchType(arg_16_0, arg_16_1)
	arg_16_0.touchOnContent = arg_16_1

	return arg_16_0
end

function var_0_0.resetPosition(arg_17_0)
	if var_0_0.DIRECTION_VERTICAL ~= arg_17_0.direction then
		return
	end

	local var_17_0, var_17_1 = arg_17_0.scrollNode:getPosition()
	local var_17_2 = arg_17_0.scrollNode:getCascadeBoundingBox()
	local var_17_3 = var_17_1 + (arg_17_0.viewRect_.y + arg_17_0.viewRect_.height - var_17_2.y - var_17_2.height)

	arg_17_0.scrollNode:setPosition(var_17_0, var_17_3)
end

function var_0_0.isItemInViewRect(arg_18_0, arg_18_1)
	if type(arg_18_1) ~= "userdata" then
		arg_18_1 = nil
	end

	if not arg_18_1 then
		print("UIScrollView - isItemInViewRect item is not right")

		return
	end

	local var_18_0 = arg_18_1:getCascadeBoundingBox()

	return cc.rectIntersectsRect(arg_18_0:getViewRectInWorldSpace(), var_18_0)
end

function var_0_0.setTouchEnabled(arg_19_0, arg_19_1)
	if not arg_19_0.scrollNode then
		return
	end

	arg_19_0.scrollNode:setTouchEnabled(arg_19_1)

	return arg_19_0
end

function var_0_0.addScrollNode(arg_20_0, arg_20_1)
	arg_20_0:addChild(arg_20_1)

	arg_20_0.scrollNode = arg_20_1

	if not arg_20_0.viewRect_ then
		arg_20_0.viewRect_ = arg_20_0.scrollNode:getCascadeBoundingBox()

		arg_20_0:setViewRect(arg_20_0.viewRect_)
	end

	arg_20_1:setTouchSwallowEnabled(false)
	arg_20_1:setTouchEnabled(true)
	arg_20_1:addNodeEventListener(cc.NODE_TOUCH_CAPTURE_EVENT, function(arg_21_0)
		return arg_20_0:onTouchCapture_(arg_21_0)
	end)
	arg_20_0:addTouchNode()

	return arg_20_0
end

function var_0_0.getScrollNode(arg_22_0)
	return arg_22_0.scrollNode
end

function var_0_0.onScroll(arg_23_0, arg_23_1)
	arg_23_0.scrollListener_ = arg_23_1

	return arg_23_0
end

function var_0_0.calcLayoutPadding(arg_24_0)
	local var_24_0 = arg_24_0.scrollNode:getCascadeBoundingBox()

	arg_24_0.layoutPadding.left = var_24_0.x - arg_24_0.actualRect_.x
	arg_24_0.layoutPadding.right = arg_24_0.actualRect_.x + arg_24_0.actualRect_.width - var_24_0.x - var_24_0.width
	arg_24_0.layoutPadding.top = var_24_0.y - arg_24_0.actualRect_.y
	arg_24_0.layoutPadding.bottom = arg_24_0.actualRect_.y + arg_24_0.actualRect_.height - var_24_0.y - var_24_0.height
end

function var_0_0.update_(arg_25_0, arg_25_1)
	arg_25_0:drawScrollBar()
end

function var_0_0.onTouchCapture_(arg_26_0, arg_26_1)
	if (arg_26_1.name == "began" or arg_26_1.name == "moved" or arg_26_1.name == "ended") and arg_26_0:isTouchInViewRect(arg_26_1) then
		return true
	else
		return false
	end
end

function var_0_0.setViewCanNotScroll(arg_27_0, arg_27_1)
	arg_27_0.listViewCanNotScroll = arg_27_1
end

function var_0_0.onTouch_(arg_28_0, arg_28_1)
	if arg_28_0.listViewCanNotScroll then
		return false
	end

	if arg_28_1.name == "began" and not arg_28_0:isTouchInViewRect(arg_28_1) then
		printInfo("UIScrollView - touch didn't in viewRect")

		return false
	end

	if arg_28_1.name == "began" and arg_28_0.touchOnContent then
		local var_28_0 = arg_28_0.scrollNode:getCascadeBoundingBox()

		if not cc.rectContainsPoint(var_28_0, cc.p(arg_28_1.x, arg_28_1.y)) then
			return false
		end
	end

	if arg_28_1.name == "began" then
		arg_28_0.prevX_ = arg_28_1.x
		arg_28_0.prevY_ = arg_28_1.y
		arg_28_0.bDrag_ = false

		local var_28_1, var_28_2 = arg_28_0.scrollNode:getPosition()

		arg_28_0.position_ = {
			x = var_28_1,
			y = var_28_2
		}

		transition.stopTarget(arg_28_0.scrollNode)
		arg_28_0:callListener_({
			name = "began",
			x = arg_28_1.x,
			y = arg_28_1.y
		})
		arg_28_0:enableScrollBar()

		arg_28_0.scaleToWorldSpace_ = arg_28_0:scaleToParent_()

		return true
	elseif arg_28_1.name == "moved" then
		if arg_28_0:isShake(arg_28_1) then
			return
		end

		arg_28_0.bDrag_ = true
		arg_28_0.speed.x = arg_28_1.x - arg_28_1.prevX
		arg_28_0.speed.y = arg_28_1.y - arg_28_1.prevY

		if arg_28_0.direction == var_0_0.DIRECTION_VERTICAL then
			arg_28_0.speed.x = 0
		elseif arg_28_0.direction == var_0_0.DIRECTION_HORIZONTAL then
			arg_28_0.speed.y = 0
		end

		arg_28_0:scrollBy(arg_28_0.speed.x, arg_28_0.speed.y)
		arg_28_0:callListener_({
			name = "moved",
			x = arg_28_1.x,
			y = arg_28_1.y
		})
	elseif arg_28_1.name == "ended" then
		if arg_28_0.bDrag_ then
			arg_28_0.bDrag_ = false

			arg_28_0:scrollAuto()
			arg_28_0:callListener_({
				name = "ended",
				x = arg_28_1.x,
				y = arg_28_1.y
			})
			arg_28_0:disableScrollBar()
		else
			arg_28_0:callListener_({
				name = "clicked",
				x = arg_28_1.x,
				y = arg_28_1.y
			})
		end
	elseif arg_28_1.name == "cancelled" then
		if arg_28_0.bDrag_ then
			arg_28_0.bDrag_ = false

			arg_28_0:scrollAuto()
			arg_28_0:callListener_({
				name = "cancelled",
				x = arg_28_1.x,
				y = arg_28_1.y
			})
			arg_28_0:disableScrollBar()
		else
			arg_28_0:callListener_({
				name = "clicked",
				x = arg_28_1.x,
				y = arg_28_1.y
			})
		end
	end
end

function var_0_0.isTouchInViewRect(arg_29_0, arg_29_1)
	local var_29_0 = arg_29_0:convertToWorldSpace(cc.p(arg_29_0.viewRect_.x, arg_29_0.viewRect_.y))

	var_29_0.width = arg_29_0.viewRect_.width
	var_29_0.height = arg_29_0.viewRect_.height

	return cc.rectContainsPoint(var_29_0, cc.p(arg_29_1.x, arg_29_1.y))
end

function var_0_0.isTouchInScrollNode(arg_30_0, arg_30_1)
	local var_30_0 = arg_30_0:getScrollNodeRect()

	return cc.rectContainsPoint(var_30_0, cc.p(arg_30_1.x, arg_30_1.y))
end

function var_0_0.scrollTo(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0
	local var_31_1

	if type(arg_31_1) == "table" then
		var_31_0 = arg_31_1.x or 0
		var_31_1 = arg_31_1.y or 0
	else
		var_31_0 = arg_31_1
		var_31_1 = arg_31_2
	end

	arg_31_0.position_ = cc.p(var_31_0, var_31_1)

	arg_31_0.scrollNode:setPosition(arg_31_0.position_)
end

function var_0_0.moveXY(arg_32_0, arg_32_1, arg_32_2, arg_32_3, arg_32_4)
	if arg_32_0.bBounce and arg_32_0.bTopBounce then
		return arg_32_1 + arg_32_3, arg_32_2 + arg_32_4
	end

	local var_32_0 = arg_32_0:getScrollNodeRect()
	local var_32_1 = arg_32_0:getViewRectInWorldSpace()
	local var_32_2 = arg_32_1
	local var_32_3 = arg_32_2
	local var_32_4
	local var_32_5

	if arg_32_3 > 0 then
		if var_32_0.x < var_32_1.x then
			local var_32_6 = (var_32_1.x - var_32_0.x) / arg_32_0.scaleToWorldSpace_.x

			var_32_2 = arg_32_1 + math.min(var_32_6, arg_32_3)
		end
	elseif var_32_0.x + var_32_0.width > var_32_1.x + var_32_1.width then
		local var_32_7 = (var_32_1.x + var_32_1.width - var_32_0.x - var_32_0.width) / arg_32_0.scaleToWorldSpace_.x

		var_32_2 = arg_32_1 + math.max(var_32_7, arg_32_3)
	end

	if arg_32_4 > 0 then
		if arg_32_0.bBounce and not arg_32_0.bTopBounce then
			var_32_3 = arg_32_2 + arg_32_4
		elseif var_32_0.y < var_32_1.y then
			local var_32_8 = (var_32_1.y - var_32_0.y) / arg_32_0.scaleToWorldSpace_.y

			var_32_3 = arg_32_2 + math.min(var_32_8, arg_32_4)
		end
	elseif var_32_0.y + var_32_0.height > var_32_1.y + var_32_1.height then
		local var_32_9 = (var_32_1.y + var_32_1.height - var_32_0.y - var_32_0.height) / arg_32_0.scaleToWorldSpace_.y

		var_32_3 = arg_32_2 + math.max(var_32_9, arg_32_4)
	end

	return var_32_2, var_32_3
end

function var_0_0.scrollBy(arg_33_0, arg_33_1, arg_33_2)
	arg_33_0.position_.x, arg_33_0.position_.y = arg_33_0:moveXY(arg_33_0.position_.x, arg_33_0.position_.y, arg_33_1, arg_33_2)

	arg_33_0.scrollNode:setPosition(arg_33_0.position_)

	if arg_33_0.actualRect_ then
		arg_33_0.actualRect_.x = arg_33_0.actualRect_.x + arg_33_1
		arg_33_0.actualRect_.y = arg_33_0.actualRect_.y + arg_33_2
	end
end

function var_0_0.disableScrollAuto(arg_34_0, arg_34_1)
	arg_34_0.disScrollAuto = arg_34_1
end

function var_0_0.scrollAuto(arg_35_0)
	if arg_35_0.disScrollAuto then
		return
	end

	if arg_35_0:twiningScroll() then
		return
	end

	arg_35_0:elasticScroll()
end

function var_0_0.twiningScroll(arg_36_0)
	if arg_36_0:isSideShow() then
		return false
	end

	if math.abs(arg_36_0.speed.x) < 10 and math.abs(arg_36_0.speed.y) < 10 then
		return false
	end

	local var_36_0 = 210

	if arg_36_0.speed.x > 0 and var_36_0 < arg_36_0.speed.x then
		arg_36_0.speed.x = var_36_0
	elseif arg_36_0.speed.x < 0 and arg_36_0.speed.x < -var_36_0 then
		arg_36_0.speed.x = -var_36_0
	end

	if arg_36_0.speed.y > 0 and var_36_0 < arg_36_0.speed.y then
		arg_36_0.speed.y = var_36_0
	elseif arg_36_0.speed.y < 0 and arg_36_0.speed.y < -var_36_0 then
		arg_36_0.speed.y = -var_36_0
	end

	local var_36_1, var_36_2 = arg_36_0:moveXY(0, 0, arg_36_0.speed.x * 12, arg_36_0.speed.y * 12)
	local var_36_3 = math.abs(math.abs(arg_36_0.speed.x) < 10 and arg_36_0.speed.y or arg_36_0.speed.x) / 70

	transition.moveBy(arg_36_0.scrollNode, {
		easing = "sineOut",
		x = var_36_1,
		y = var_36_2,
		time = var_36_3,
		onComplete = function()
			if arg_36_0:isSideShow() then
				arg_36_0:elasticScroll()
			end

			arg_36_0.speed.x = 0
			arg_36_0.speed.y = 0
		end
	})

	return true
end

function var_0_0.elasticScroll(arg_38_0)
	local var_38_0 = arg_38_0:getScrollNodeRect()
	local var_38_1 = 0
	local var_38_2 = 0
	local var_38_3 = arg_38_0:getViewRectInWorldSpace()

	if var_38_0.width < var_38_3.width then
		var_38_1 = var_38_3.x - var_38_0.x
	elseif var_38_0.x > var_38_3.x then
		var_38_1 = var_38_3.x - var_38_0.x
	elseif var_38_0.x + var_38_0.width < var_38_3.x + var_38_3.width then
		var_38_1 = var_38_3.x + var_38_3.width - var_38_0.x - var_38_0.width
	end

	if var_38_0.height < var_38_3.height then
		var_38_2 = var_38_3.y + var_38_3.height - var_38_0.y - var_38_0.height
	elseif var_38_0.y > var_38_3.y then
		var_38_2 = var_38_3.y - var_38_0.y
	elseif var_38_0.y + var_38_0.height < var_38_3.y + var_38_3.height then
		var_38_2 = var_38_3.y + var_38_3.height - var_38_0.y - var_38_0.height
	end

	if var_38_1 == 0 and var_38_2 == 0 then
		return
	end

	transition.moveBy(arg_38_0.scrollNode, {
		easing = "backout",
		time = 0.3,
		x = var_38_1,
		y = var_38_2,
		onComplete = function()
			arg_38_0:callListener_({
				name = "scrollEnd"
			})
		end
	})
end

function var_0_0.getScrollNodeRect(arg_40_0)
	return (arg_40_0.scrollNode:getCascadeBoundingBox())
end

function var_0_0.getViewRectInWorldSpace(arg_41_0)
	local var_41_0 = arg_41_0:convertToWorldSpace(cc.p(arg_41_0.viewRect_.x, arg_41_0.viewRect_.y))

	var_41_0.width = arg_41_0.viewRect_.width
	var_41_0.height = arg_41_0.viewRect_.height

	return var_41_0
end

function var_0_0.isSideShow(arg_42_0)
	local var_42_0 = arg_42_0.scrollNode:getCascadeBoundingBox()
	local var_42_1 = arg_42_0:convertToNodeSpace(cc.p(var_42_0.x, var_42_0.y))
	local var_42_2 = var_42_1.y > arg_42_0.viewRect_.y or var_42_1.y + var_42_0.height < arg_42_0.viewRect_.y + arg_42_0.viewRect_.height
	local var_42_3 = var_42_1.x > arg_42_0.viewRect_.x or var_42_1.x + var_42_0.width < arg_42_0.viewRect_.x + arg_42_0.viewRect_.width

	if var_0_0.DIRECTION_VERTICAL == arg_42_0.direction then
		return var_42_2
	elseif var_0_0.DIRECTION_HORIZONTAL == arg_42_0.direction then
		return var_42_3
	else
		return var_42_2 or var_42_3
	end
end

function var_0_0.callListener_(arg_43_0, arg_43_1)
	if not arg_43_0.scrollListener_ then
		return
	end

	arg_43_1.scrollView = arg_43_0

	arg_43_0.scrollListener_(arg_43_1)
end

function var_0_0.enableScrollBar(arg_44_0)
	local var_44_0 = arg_44_0.scrollNode:getCascadeBoundingBox()

	if arg_44_0.sbV then
		arg_44_0.sbV:setVisible(false)
		transition.stopTarget(arg_44_0.sbV)
		arg_44_0.sbV:setOpacity(128)

		local var_44_1 = arg_44_0.sbV:getContentSize()

		if arg_44_0.viewRect_.height < var_44_0.height then
			local var_44_2 = arg_44_0.viewRect_.height * arg_44_0.viewRect_.height / var_44_0.height

			if var_44_2 < var_44_1.width then
				var_44_2 = var_44_1.width
			end

			arg_44_0.sbV:setContentSize(var_44_1.width, var_44_2)
			arg_44_0.sbV:setPosition(arg_44_0.viewRect_.x + arg_44_0.viewRect_.width - var_44_1.width / 2, arg_44_0.viewRect_.y + var_44_2 / 2)
		end
	end

	if arg_44_0.sbH then
		arg_44_0.sbH:setVisible(false)
		transition.stopTarget(arg_44_0.sbH)
		arg_44_0.sbH:setOpacity(128)

		local var_44_3 = arg_44_0.sbH:getContentSize()

		if arg_44_0.viewRect_.width < var_44_0.width then
			local var_44_4 = arg_44_0.viewRect_.width * arg_44_0.viewRect_.width / var_44_0.width

			if var_44_4 < var_44_3.height then
				var_44_4 = var_44_3.height
			end

			arg_44_0.sbH:setContentSize(var_44_4, var_44_3.height)
			arg_44_0.sbH:setPosition(arg_44_0.viewRect_.x + var_44_4 / 2, arg_44_0.viewRect_.y + var_44_3.height / 2)
		end
	end
end

function var_0_0.disableScrollBar(arg_45_0)
	if arg_45_0.sbV then
		transition.fadeOut(arg_45_0.sbV, {
			time = 0.3,
			onComplete = function()
				arg_45_0.sbV:setOpacity(128)
				arg_45_0.sbV:setVisible(false)
			end
		})
	end

	if arg_45_0.sbH then
		transition.fadeOut(arg_45_0.sbH, {
			time = 1.5,
			onComplete = function()
				arg_45_0.sbH:setOpacity(128)
				arg_45_0.sbH:setVisible(false)
			end
		})
	end
end

function var_0_0.drawScrollBar(arg_48_0)
	if not arg_48_0.bDrag_ then
		return
	end

	if not arg_48_0.sbV and not arg_48_0.sbH then
		return
	end

	local var_48_0 = arg_48_0.scrollNode:getCascadeBoundingBox()

	if arg_48_0.sbV then
		arg_48_0.sbV:setVisible(true)

		local var_48_1 = arg_48_0.sbV:getContentSize()
		local var_48_2 = (arg_48_0.viewRect_.y - var_48_0.y) * (arg_48_0.viewRect_.height - var_48_1.height) / (var_48_0.height - arg_48_0.viewRect_.height) + arg_48_0.viewRect_.y + var_48_1.height / 2
		local var_48_3, var_48_4 = arg_48_0.sbV:getPosition()

		arg_48_0.sbV:setPosition(var_48_3, var_48_2)
	end

	if arg_48_0.sbH then
		arg_48_0.sbH:setVisible(true)

		local var_48_5 = arg_48_0.sbH:getContentSize()
		local var_48_6 = (arg_48_0.viewRect_.x - var_48_0.x) * (arg_48_0.viewRect_.width - var_48_5.width) / (var_48_0.width - arg_48_0.viewRect_.width) + arg_48_0.viewRect_.x + var_48_5.width / 2
		local var_48_7, var_48_8 = arg_48_0.sbH:getPosition()

		arg_48_0.sbH:setPosition(var_48_6, var_48_8)
	end
end

function var_0_0.addScrollBarIf(arg_49_0)
	if not arg_49_0.sb then
		arg_49_0.sb = cc.DrawNode:create():addTo(arg_49_0)
	end

	drawNode = cc.DrawNode:create()

	drawNode:drawSegment(points[1], points[2], radius, borderColor)
end

function var_0_0.changeViewRectToNodeSpaceIf(arg_50_0)
	if arg_50_0.viewRectIsNodeSpace then
		return
	end

	local var_50_0, var_50_1 = arg_50_0:getPosition()
	local var_50_2 = arg_50_0:convertToWorldSpace(cc.p(var_50_0, var_50_1))

	arg_50_0.viewRect_.x = arg_50_0.viewRect_.x + var_50_2.x
	arg_50_0.viewRect_.y = arg_50_0.viewRect_.y + var_50_2.y
	arg_50_0.viewRectIsNodeSpace = true
end

function var_0_0.isShake(arg_51_0, arg_51_1)
	if math.abs(arg_51_1.x - arg_51_0.prevX_) < arg_51_0.nShakeVal and math.abs(arg_51_1.y - arg_51_0.prevY_) < arg_51_0.nShakeVal then
		return true
	end
end

function var_0_0.scaleToParent_(arg_52_0)
	local var_52_0
	local var_52_1 = arg_52_0
	local var_52_2 = {
		x = 1,
		y = 1
	}

	while true do
		var_52_2.x = var_52_2.x * var_52_1:getScaleX()
		var_52_2.y = var_52_2.y * var_52_1:getScaleY()

		local var_52_3 = var_52_1:getParent()

		if not var_52_3 then
			break
		end

		var_52_1 = var_52_3
	end

	return var_52_2
end

function var_0_0.addTouchNode(arg_53_0)
	local var_53_0

	if arg_53_0.touchNode_ then
		var_53_0 = arg_53_0.touchNode_
	else
		var_53_0 = display.newNode()
		arg_53_0.touchNode_ = var_53_0

		var_53_0:setLocalZOrder(var_0_0.TOUCH_ZORDER)
		var_53_0:setTouchSwallowEnabled(true)
		var_53_0:setTouchEnabled(true)
		var_53_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_54_0)
			return arg_53_0:onTouch_(arg_54_0)
		end)
		arg_53_0:addChild(var_53_0)
	end

	var_53_0:setContentSize(arg_53_0.viewRect_.width, arg_53_0.viewRect_.height)
	var_53_0:setPosition(arg_53_0.viewRect_.x, arg_53_0.viewRect_.y)

	return arg_53_0
end

function var_0_0.fill(arg_55_0, arg_55_1, arg_55_2)
	local var_55_0 = (function(arg_56_0, arg_56_1)
		if not arg_56_1 then
			return arg_56_0
		end

		for iter_56_0, iter_56_1 in pairs(arg_56_1) do
			arg_56_0[iter_56_0] = arg_56_1[iter_56_0]
		end

		return arg_56_0
	end)({
		cellCount = 3,
		rowCount = 3,
		heightGap = 0,
		autoTable = true,
		widthGap = 0,
		autoGap = true,
		itemSize = cc.size(50, 50)
	}, arg_55_2)

	if #arg_55_1 == 0 then
		return nil
	end

	local function var_55_1(arg_57_0)
		return arg_57_0:getContentSize()
	end

	local function var_55_2(arg_58_0)
		return arg_58_0:getContentSize().width
	end

	local function var_55_3(arg_59_0)
		return arg_59_0:getContentSize().height
	end

	local function var_55_4(arg_60_0, arg_60_1, arg_60_2)
		return arg_60_0:setContentSize(cc.size(arg_60_1, arg_60_2))
	end

	local function var_55_5(arg_61_0, arg_61_1, arg_61_2)
		arg_61_0:setPosition(arg_61_1, arg_61_2)
	end

	local function var_55_6(arg_62_0)
		return arg_62_0:getAnchorPoint().x
	end

	local function var_55_7(arg_63_0)
		return arg_63_0:getAnchorPoint().y
	end

	local var_55_8 = display.newNode()

	var_55_4(var_55_8, arg_55_0:getViewRect().width, arg_55_0:getViewRect().height)
	arg_55_0:addScrollNode(var_55_8)
	var_55_5(var_55_8, arg_55_0.viewRect_.x, arg_55_0.viewRect_.y)

	if arg_55_0.direction == cc.ui.UIScrollView.DIRECTION_VERTICAL then
		if var_55_0.autoTable then
			var_55_0.cellCount = math.floor(arg_55_0.viewRect_.width / var_55_0.itemSize.width)
		end

		if var_55_0.autoGap then
			var_55_0.widthGap = (arg_55_0.viewRect_.width - var_55_0.cellCount * var_55_0.itemSize.width) / (var_55_0.cellCount + 1)
			var_55_0.heightGap = var_55_0.widthGap
		end

		var_55_0.rowCount = math.ceil(#arg_55_1 / var_55_0.cellCount)

		local var_55_9 = (var_55_0.itemSize.height + var_55_0.heightGap) * var_55_0.rowCount + var_55_0.heightGap

		if var_55_9 < arg_55_0.viewRect_.height then
			var_55_9 = arg_55_0.viewRect_.height
		end

		var_55_4(var_55_8, arg_55_0.viewRect_.width, var_55_9)

		for iter_55_0 = 1, #arg_55_1 do
			local var_55_10 = arg_55_1[iter_55_0]
			local var_55_11 = 0
			local var_55_12 = 0
			local var_55_13 = var_55_0.widthGap + math.floor((iter_55_0 - 1) % var_55_0.cellCount) * (var_55_0.widthGap + var_55_0.itemSize.width)
			local var_55_14 = var_55_3(var_55_8) - (math.floor((iter_55_0 - 1) / var_55_0.cellCount) + 1) * (var_55_0.heightGap + var_55_0.itemSize.height)
			local var_55_15 = var_55_13 + var_55_2(var_55_10) * var_55_6(var_55_10)
			local var_55_16 = var_55_14 + var_55_3(var_55_10) * var_55_7(var_55_10)

			var_55_5(var_55_10, var_55_15, var_55_16)
			var_55_10:addTo(var_55_8)
		end
	else
		if var_55_0.autoTable then
			var_55_0.rowCount = math.floor(arg_55_0.viewRect_.height / var_55_0.itemSize.height)
		end

		if var_55_0.autoGap then
			var_55_0.heightGap = (arg_55_0.viewRect_.height - var_55_0.rowCount * var_55_0.itemSize.height) / (var_55_0.rowCount + 1)
			var_55_0.widthGap = var_55_0.heightGap
		end

		var_55_0.cellCount = math.ceil(#arg_55_1 / var_55_0.rowCount)

		local var_55_17 = (var_55_0.itemSize.width + var_55_0.widthGap) * var_55_0.cellCount + var_55_0.widthGap

		if var_55_17 < arg_55_0.viewRect_.width then
			v_h = arg_55_0.viewRect_.width
		end

		var_55_4(var_55_8, var_55_17, arg_55_0.viewRect_.height)

		for iter_55_1 = 1, #arg_55_1 do
			local var_55_18 = arg_55_1[iter_55_1]
			local var_55_19 = 0
			local var_55_20 = 0
			local var_55_21 = var_55_0.widthGap + math.floor((iter_55_1 - 1) / var_55_0.rowCount) * (var_55_0.widthGap + var_55_0.itemSize.width)
			local var_55_22 = var_55_3(var_55_8) - (math.floor((iter_55_1 - 1) % var_55_0.rowCount) + 1) * (var_55_0.heightGap + var_55_0.itemSize.height)
			local var_55_23 = var_55_21 + var_55_2(var_55_18) * var_55_6(var_55_18)
			local var_55_24 = var_55_22 + var_55_3(var_55_18) * var_55_7(var_55_18)

			var_55_5(var_55_18, var_55_23, var_55_24)
			var_55_18:addTo(var_55_8)
		end
	end
end

return var_0_0
