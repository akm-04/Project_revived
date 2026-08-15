local var_0_0 = class("DormRoomItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.dormFurnitureItem
local var_0_2 = xyd.DormUnit.xunit
local var_0_3 = xyd.DormUnit.yunit
local var_0_4 = "skeletons/ui_effect/dorm/dorm_sleep"
local var_0_5 = "skeletons/ui_effect/dorm/dorm_dresser"
local var_0_6 = "skeletons/ui_effect/dorm/dorm_exp"
local var_0_7 = "skeletons/ui_effect/common_effect_hero3/common_effect_hero3"
local var_0_8 = import("app.common.ui.SpineEffect")
local var_0_9 = xyd.DormPanelType
local var_0_10 = {
	OnFloor = 1,
	OnWar = 2
}
local var_0_11 = xyd.DormItemState

function var_0_0.ctor(arg_2_0, arg_2_1)
	arg_2_0.dorm = xyd.ModelManager.get():loadModel(xyd.ModelType.DORM)
	arg_2_0.hero = arg_2_1.hero

	arg_2_0:setKey(arg_2_1.key)
	arg_2_0:setCascadeOpacityEnabled(true)
	arg_2_0:contentView()
end

function var_0_0.setKey(arg_3_0, arg_3_1, arg_3_2)
	arg_3_0.key = arg_3_1

	local var_3_0 = arg_3_0.dorm:resolveKey(arg_3_0.key)

	arg_3_0.tableId = tonumber(var_3_0.item_id)
	arg_3_0.isFlipped = tonumber(var_3_0.is_flipped) or 0
	arg_3_0.parent = var_3_0.parent_key
	arg_3_0.coordX = var_3_0.coordX
	arg_3_0.coordY = var_3_0.coordY

	if arg_3_0.parent then
		local var_3_1 = arg_3_0.dorm:resolveKey(arg_3_0.parent)

		arg_3_0.baseH = var_0_1:coverHeight(var_3_1.item_id)
	end

	arg_3_0:init()
	arg_3_0:setCoordinate(arg_3_0.coordX, arg_3_0.coordY, arg_3_2)
	arg_3_0:contentView()
end

function var_0_0.isHeroItem(arg_4_0)
	if arg_4_0.tableId == xyd.DormRoomGirlItemID then
		return true
	end
end

function var_0_0.addSleepEffect(arg_5_0)
	if not arg_5_0.sleepEffect then
		arg_5_0.sleepEffect = xyd.createEffect(var_0_4)

		arg_5_0.sleepEffect:addTo(arg_5_0.addPoint)
		arg_5_0.sleepEffect:setPosition(cc.p(0, 0))
		arg_5_0.sleepEffect:play(nil, true)
		arg_5_0.sleepEffect:setLocalZOrder(100000)

		local var_5_0 = var_0_1:sleepIcon(arg_5_0.tableId)
		local var_5_1 = xyd.AssetLoader.get():loadSprite(var_5_0)

		arg_5_0.contentView_:setSpriteFrame(var_5_1:getSpriteFrame())
	end
end

function var_0_0.removeSleepEffect(arg_6_0)
	if arg_6_0.sleepEffect then
		arg_6_0.sleepEffect:removeFromParent()

		arg_6_0.sleepEffect = nil

		local var_6_0 = var_0_1:icon(arg_6_0.tableId)
		local var_6_1 = xyd.AssetLoader.get():loadSprite(var_6_0)

		arg_6_0.contentView_:setSpriteFrame(var_6_1:getSpriteFrame())
	end
end

function var_0_0.addDresserEffect(arg_7_0)
	if not arg_7_0.dresserEffect then
		arg_7_0.dresserEffect = xyd.createEffect(var_0_5)

		arg_7_0.dresserEffect:addTo(arg_7_0.addPoint)
		arg_7_0.dresserEffect:play(nil, true)
		arg_7_0.dresserEffect:setVisible(false)
		arg_7_0:updateDresserEffect()
	end
end

function var_0_0.setDresserEffectVisible(arg_8_0, arg_8_1)
	if not arg_8_0.dresserEffect then
		arg_8_0:addDresserEffect()
	end

	arg_8_0.dresserEffect:setVisible(arg_8_1)
end

function var_0_0.updateDresserEffect(arg_9_0)
	if arg_9_0.dresserEffect then
		if arg_9_0.flipped then
			arg_9_0.dresserEffect:setRotation(-90)
			arg_9_0.dresserEffect:setPosition(cc.p(-10, 20))
		else
			arg_9_0.dresserEffect:setRotation(0)
			arg_9_0.dresserEffect:setPosition(cc.p(20, 20))
		end
	end
end

function var_0_0.removeDresserEffect(arg_10_0)
	if arg_10_0.dresserEffect then
		arg_10_0.dresserEffect:removeFromParent()

		arg_10_0.dresserEffect = nil
	end
end

function var_0_0.playExpEffect(arg_11_0, arg_11_1)
	if not arg_11_0.expLabel then
		local var_11_0 = {
			size = 30,
			align = cc.ui.TEXT_ALIGN_CENTER,
			font = xyd.AssetLoader.FONT_NAME,
			color = cc.c3b(247, 217, 54)
		}
		local var_11_1 = xyd.AssetLoader.get():loadLabel(var_11_0)

		var_11_1:setAnchorPoint(cc.p(0.5, 0.5))
		var_11_1:enableOutline(cc.c4b(0, 0, 0, 155), 1)
		var_11_1:addTo(arg_11_0.contentView_)

		arg_11_0.expLabel = var_11_1

		arg_11_0.expLabel:setScale(1.5)
	end

	arg_11_0.expLabel:setString("+" .. tostring(arg_11_1))

	local var_11_2 = arg_11_0.contentView_:getContentSize()

	arg_11_0.expLabel:setPositionY(var_11_2.height / 2 + 50)
	arg_11_0.expLabel:runActionOnce(cc.MoveTo:create(1, cc.p(0, var_11_2.height / 2 + 150)), false, function()
		if arg_11_0 and arg_11_0.expLabel and not tolua.isnull(arg_11_0.expLabel) then
			arg_11_0.expLabel:setVisible(false)
		end
	end)
end

function var_0_0.playLevelUpEffect(arg_13_0)
	if not arg_13_0.levelUpEffect then
		arg_13_0.levelUpEffect = xyd.createEffect(var_0_7)
	end

	arg_13_0.levelUpEffect:addTo(arg_13_0.contentView_)
	arg_13_0.levelUpEffect:play(nil, false)

	local var_13_0 = arg_13_0.contentView_:getContentSize()

	if arg_13_0.levelUpSprite == nil then
		arg_13_0.levelUpSprite = xyd.AssetLoader.get():loadSprite("images/text/txt_levelup.png")

		arg_13_0.levelUpSprite:setAnchorPoint(cc.p(0.5, 0.5))
		arg_13_0.levelUpSprite:setPositionY(var_13_0.height / 2)
		arg_13_0.levelUpSprite:addTo(arg_13_0.contentView_)
		arg_13_0.levelUpSprite:setScale(1.5)
	end

	arg_13_0.levelUpSprite:setPositionY(var_13_0.height / 2)
	arg_13_0.levelUpSprite:setVisible(true)
	arg_13_0.levelUpSprite:runActionOnce(cc.MoveTo:create(1.2, cc.p(0, var_13_0.height / 2 + 150)), false, function()
		if arg_13_0 and arg_13_0.levelUpSprite and not tolua.isnull(arg_13_0.levelUpSprite) then
			arg_13_0.levelUpSprite:setVisible(false)
		end
	end)
end

function var_0_0.updateParent(arg_15_0, arg_15_1)
	arg_15_0.parent = arg_15_1

	if arg_15_0.parent then
		local var_15_0 = arg_15_0.dorm:resolveKey(arg_15_0.parent)

		arg_15_0.baseH = var_0_1:coverHeight(var_15_0.item_id)
	end

	arg_15_0:initPanelParams()
	arg_15_0:setCoordinate(arg_15_0.coordX, arg_15_0.coordY)
end

function var_0_0.init(arg_16_0)
	local var_16_0 = var_0_1:getItemSize(arg_16_0.tableId, arg_16_0.isFlipped)

	arg_16_0.l = var_16_0.long
	arg_16_0.w = var_16_0.width
	arg_16_0.h = var_16_0.height
	arg_16_0.canFlip = var_0_1:canFlip(arg_16_0.tableId)
	arg_16_0.flipped = arg_16_0.isFlipped == 1
	arg_16_0.panelType = arg_16_0.dorm:getPanelTypeByKey(arg_16_0.key)
	arg_16_0.specialType = var_0_1:specialType(arg_16_0.tableId)

	if arg_16_0.specialType == xyd.DormSpecialType.AutoFull then
		arg_16_0.l, arg_16_0.w = arg_16_0.dorm:getPanelSize(arg_16_0.panelType)
	end

	arg_16_0:initPanelParams()
end

function var_0_0.initPanelParams(arg_17_0)
	arg_17_0.maxL, arg_17_0.maxW = arg_17_0.dorm:getPanelSize(arg_17_0.panelType)
	arg_17_0.basePosition = arg_17_0.dorm:getPanelBasePosition(arg_17_0.panelType)

	if arg_17_0.parent then
		arg_17_0.basePosition = cc.p(0, arg_17_0.baseH * var_0_3)
	elseif arg_17_0.panelType ~= var_0_9.Floor and arg_17_0.specialType ~= xyd.DormSpecialType.AutoFull then
		arg_17_0.basePosition = xyd.addPosition(arg_17_0.basePosition, arg_17_0.dorm:getWallCorrectPositon())
	end
end

function var_0_0.contentView(arg_18_0)
	local var_18_0 = arg_18_0:calculateAnchorPoint()

	if arg_18_0.contentView_ == nil and arg_18_0.specialType == xyd.DormSpecialType.AutoFull then
		arg_18_0.contentView_ = arg_18_0.dorm:getPanelItem(arg_18_0.tableId, arg_18_0.l, arg_18_0.w)

		arg_18_0.contentView_:addTo(arg_18_0):setAnchorPoint(var_18_0)
		arg_18_0.contentView_:setPosition(cc.p(0, 0))
	elseif arg_18_0.contentView_ == nil and not arg_18_0:isHeroItem() then
		local var_18_1 = var_0_1:icon(arg_18_0.tableId)

		arg_18_0.contentView_ = xyd.AssetLoader.get():loadSprite(var_18_1)

		arg_18_0.contentView_:setFlippedX(arg_18_0.flipped)
		arg_18_0.contentView_:addTo(arg_18_0):setAnchorPoint(var_18_0)
		arg_18_0.contentView_:setTouchEnabled(true)
		arg_18_0.contentView_:setTouchSwallowEnabled(true)

		arg_18_0.addPoint = display.newNode()

		arg_18_0.addPoint:addTo(arg_18_0)
		arg_18_0.addPoint:setCascadeOpacityEnabled(false)
		arg_18_0.addPoint:setLocalZOrder(200000)

		if var_0_1:actType(arg_18_0.tableId) == xyd.DormInteractionType.Dress then
			arg_18_0:addDresserEffect()
		end
	elseif arg_18_0.contentView_ == nil and arg_18_0:isHeroItem() then
		arg_18_0.contentView_ = arg_18_0.hero:getHeroModel()

		arg_18_0.contentView_:flipX(arg_18_0.flipped)
		arg_18_0.contentView_:addTo(arg_18_0):setAnchorPoint(cc.p(0, 0))
		arg_18_0.contentView_:setScale(0.5)
		arg_18_0.contentView_:walk(true)
		arg_18_0.contentView_:setTimeScale(xyd.tables.misc.dormGirlsSpeed)

		local var_18_2 = arg_18_0.contentView_:getContentSize()
		local var_18_3 = display.newNode()

		var_18_3:setContentSize(var_18_2)
		var_18_3:setAnchorPoint(cc.p(0.5, 0))
		var_18_3:setTouchEnabled(true)
		var_18_3:addTo(arg_18_0.contentView_)
		var_18_3:setPosition(0, 0)
		var_18_3:setTouchSwallowEnabled(true)

		arg_18_0.touchNode = var_18_3
	elseif arg_18_0.specialType ~= xyd.DormSpecialType.AutoFull and not arg_18_0:isHeroItem() then
		arg_18_0.contentView_:setFlippedX(arg_18_0.flipped)
		arg_18_0.contentView_:setAnchorPoint(var_18_0)
	elseif arg_18_0.specialType ~= xyd.DormSpecialType.AutoFull then
		arg_18_0.contentView_:flipX(arg_18_0.flipped)
	end

	arg_18_0:updateDresserEffect()
	arg_18_0:correctPosition()

	return arg_18_0.contentView_
end

function var_0_0.playExpression(arg_19_0)
	local var_19_0 = xyd.tables.misc.dormitoryExpression
	local var_19_1 = xyd.randomlySelectElement(var_19_0)
	local var_19_2 = xyd.tables.expression:expression(var_19_1)
	local var_19_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/dorm/expression/expression_item.csb")

	arg_19_0.contentView_:removeChildByName("expression")

	local var_19_4 = arg_19_0.contentView_:getContentSize().height
	local var_19_5 = math.max(var_19_4, 250)

	var_19_3:addTo(arg_19_0.contentView_)
	var_19_3:setPositionY(var_19_5)
	var_19_3:setName("expression")

	local var_19_6 = var_19_3:getChildByName("container")
	local var_19_7 = var_19_2 .. ".json"
	local var_19_8 = var_19_2 .. ".atlas"
	local var_19_9 = var_0_8.new(var_19_7, var_19_8, 1)

	var_19_9:setAnchorPoint(cc.p(0.5, 0.5))
	var_19_9:addTo(var_19_6)
	var_19_9:setPosition(cc.p(var_19_6:getContentSize().width / 2, var_19_6:getContentSize().height / 2))

	local var_19_10 = true

	var_19_9:play(function()
		var_19_3:setVisible(false)
	end, false)
end

function var_0_0.correctPosition(arg_21_0)
	local var_21_0 = var_0_1:correctPos(arg_21_0.tableId)
	local var_21_1 = cc.p(var_21_0[1] or 0, var_21_0[2] or 0)

	if arg_21_0:isHeroItem() then
		var_21_1 = cc.p(0, var_0_3 / 2)
	elseif arg_21_0.flipped then
		var_21_1 = cc.p(-(var_21_0[1] or 0), var_21_0[2] or 0)
	end

	arg_21_0.contentView_:setPosition(var_21_1)

	if arg_21_0.addPoint then
		arg_21_0.addPoint:setPosition(xyd.addPosition(arg_21_0:getContentCentrePositon(), var_21_1))
	end
end

function var_0_0.setHeroState(arg_22_0, arg_22_1, arg_22_2, arg_22_3)
	arg_22_0.state = arg_22_1
	arg_22_0.time = arg_22_2
	arg_22_0.bedKey = arg_22_3

	arg_22_0.contentView_:setVisible(true)
	arg_22_0:updateModelState()
end

function var_0_0.updateModelState(arg_23_0)
	if arg_23_0.state == xyd.DormGirlState.Rest then
		arg_23_0.contentView_:idle()
	elseif arg_23_0.state == xyd.DormGirlState.Walk then
		arg_23_0.contentView_:walk(true)
	elseif arg_23_0.state == xyd.DormGirlState.OnBed then
		arg_23_0.contentView_:attacked()
		arg_23_0.contentView_:setVisible(false)
	elseif arg_23_0.state == xyd.DormGirlState.Attack then
		arg_23_0.contentView_:attacked()
	end
end

function var_0_0.flippingItem(arg_24_0)
	arg_24_0:flipCoordinate()
	arg_24_0:swapLW()
	arg_24_0:setCoordinate(arg_24_0.coordX, arg_24_0.coordY)

	arg_24_0.flipped = not arg_24_0.flipped

	arg_24_0:contentView_()
end

function var_0_0.swapLW(arg_25_0)
	arg_25_0.l, arg_25_0.w = arg_25_0.w, arg_25_0.l
end

function var_0_0.swapCoordinate(arg_26_0)
	arg_26_0.coordX, arg_26_0.coordY = arg_26_0.coordY, arg_26_0.coordX
end

function var_0_0.flipCoordinate(arg_27_0)
	local var_27_0 = arg_27_0.l - arg_27_0.w

	arg_27_0.coordX = arg_27_0.coordX + var_27_0
	arg_27_0.coordY = arg_27_0.coordY - var_27_0

	arg_27_0:setCoordinate(arg_27_0.coordX, arg_27_0.coordY)
end

function var_0_0.moveCoordinate(arg_28_0, arg_28_1, arg_28_2)
	local var_28_0 = arg_28_0.coordX + arg_28_1
	local var_28_1 = arg_28_0.coordY + arg_28_2

	arg_28_0:setCoordinate(var_28_0, var_28_1)
end

function var_0_0.setCoordinate(arg_29_0, arg_29_1, arg_29_2, arg_29_3)
	arg_29_0.coordX = arg_29_1
	arg_29_0.coordY = arg_29_2

	if arg_29_0.pieceRect then
		arg_29_0:setLocalZOrder(200000)
	else
		arg_29_0:setLocalZOrder(arg_29_0:calculateZOrder())
	end

	local var_29_0 = arg_29_0:calculatePosition(arg_29_0.coordX, arg_29_0.coordY)

	if not arg_29_3 then
		arg_29_0:setPosition(var_29_0)

		if arg_29_0.moveAction then
			transition.removeAction(arg_29_0.moveAction)

			arg_29_0.moveAction = nil
		end
	else
		arg_29_0.moveAction = cc.MoveTo:create(xyd.tables.misc.dormGirlsSpeedTime, var_29_0)

		arg_29_0:runAction(arg_29_0.moveAction)
	end
end

function var_0_0.getContentCentrePositon(arg_30_0)
	local var_30_0 = arg_30_0.contentView_:getAnchorPoint()
	local var_30_1 = arg_30_0.contentView_:getContentSize()

	return (cc.p(var_30_1.width * (0.5 - var_30_0.x), var_30_1.height * (0.5 - var_30_0.y)))
end

function var_0_0.getAddPosition(arg_31_0, arg_31_1, arg_31_2)
	local var_31_0 = arg_31_1:getAnchorPoint()
	local var_31_1 = arg_31_1:getContentSize().width

	return cc.p(var_31_1 * var_31_0.x, arg_31_2 * var_0_3)
end

function var_0_0.calculateAnchorPoint(arg_32_0)
	return arg_32_0.dorm:calculateAnchorPoint(arg_32_0.l, arg_32_0.w, arg_32_0.panelType)
end

function var_0_0.calculatePosition(arg_33_0, arg_33_1, arg_33_2)
	return arg_33_0.dorm:calculatePosition(arg_33_1, arg_33_2, arg_33_0.panelType, arg_33_0.basePosition)
end

function var_0_0.getPiexlPosition(arg_34_0, arg_34_1, arg_34_2)
	return arg_34_0.dorm:getPiexlPosition(arg_34_1, arg_34_2, arg_34_0.panelType)
end

function var_0_0.getStandardCoord(arg_35_0, arg_35_1, arg_35_2)
	local var_35_0, var_35_1 = arg_35_0.dorm:getCoordinateByPiexl(arg_35_1, arg_35_2, arg_35_0.panelType)

	return math.floor(var_35_0 + 0.5), math.floor(var_35_1 + 0.5)
end

function var_0_0.removePieceRect(arg_36_0)
	if arg_36_0.pieceRect then
		arg_36_0.pieceRect:removeFromParent()

		arg_36_0.pieceRect = nil
	end

	arg_36_0:setLocalZOrder(arg_36_0:calculateZOrder())
end

function var_0_0.calculateZOrder(arg_37_0)
	local var_37_0 = var_0_1:floor(arg_37_0.tableId)

	if var_37_0 >= 2 then
		return arg_37_0.dorm:calculateZOrder(arg_37_0.coordX, arg_37_0.coordY, arg_37_0.l, arg_37_0.w, arg_37_0.panelType)
	elseif arg_37_0.panelType == var_0_9.Floor then
		return var_37_0 + 1
	else
		return var_37_0
	end
end

function var_0_0.updatePieceRect(arg_38_0, arg_38_1)
	if not arg_38_0.pieceRect then
		arg_38_0.pieceRect = arg_38_0:getPieceRect()

		arg_38_0.pieceRect:addTo(arg_38_0)
	elseif arg_38_0.pieceRect.long ~= arg_38_0.l or arg_38_0.pieceRect.width ~= arg_38_0.w or arg_38_0.pieceRect.panelType ~= arg_38_0.panelType then
		arg_38_0.pieceRect:removeFromParent()

		arg_38_0.pieceRect = arg_38_0:getPieceRect()

		arg_38_0.pieceRect:addTo(arg_38_0)
	end

	arg_38_0.pieceRect:setLocalZOrder(-1)
	arg_38_0.dorm:setPieceRectState(arg_38_0.pieceRect, arg_38_1)
	arg_38_0:setLocalZOrder(200000)
	arg_38_0:updatePieceRectPosition()
end

function var_0_0.updatePieceRectPosition(arg_39_0)
	local var_39_0 = arg_39_0:calculatePosition(math.floor(arg_39_0.coordX + 0.5), math.floor(arg_39_0.coordY + 0.5))
	local var_39_1 = xyd.subPosition(var_39_0, cc.p(arg_39_0:getPosition()))

	arg_39_0.pieceRect:setPosition(var_39_1)
end

function var_0_0.getPieceRect(arg_40_0)
	local var_40_0 = {}

	return (arg_40_0.dorm:createPieceRect(arg_40_0.l, arg_40_0.w, arg_40_0.panelType, var_0_11.OnGround))
end

function var_0_0.resetModelState(arg_41_0)
	arg_41_0.modelState = arg_41_0.modelState or 0

	local var_41_0 = arg_41_0:getHeroModel()

	if arg_41_0.modelState == 8 then
		arg_41_0.modelState = arg_41_0.modelState + 1
	end

	arg_41_0.modelState = arg_41_0.modelState % 8
	arg_41_0.isShow = true

	local var_41_1

	if arg_41_0.modelState == xyd.ModelState.Walk then
		var_41_0:walk(true)

		arg_41_0.isShow = false
		var_41_1 = xyd.tables.model:getMoveSound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Win then
		var_41_0:win(false, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getWinSound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Attack1 then
		var_41_0:attack(1, nil, nil, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getNormalAttackSound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Attack2 then
		var_41_0:attack(2, nil, nil, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getAttack1Sound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Attack3 then
		var_41_0:attack(3, nil, nil, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getAttack2Sound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Attack4 then
		if not var_41_0:hasAnimation("gongji04") then
			arg_41_0.modelState = arg_41_0.modelState + 1

			arg_41_0:resetModelState()

			return
		end

		var_41_0:attack(4, nil, nil, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getAttack4Sound(arg_41_0.hero:getModelID())
	elseif arg_41_0.modelState == xyd.ModelState.Attack5 then
		if not var_41_0:hasAnimation("gongji05") then
			arg_41_0.modelState = arg_41_0.modelState + 1

			arg_41_0:resetModelState()

			return
		end

		var_41_0:attack(5, nil, nil, handler(arg_41_0, arg_41_0.setIsShow))

		var_41_1 = xyd.tables.model:getAttack4Sound(arg_41_0.hero:getModelID())
	else
		arg_41_0:setIsShow()
	end

	if var_41_1 and var_41_1 ~= "" then
		audio.stopAllSounds()
		audio.playSound(var_41_1, false)
	end

	arg_41_0.modelState = arg_41_0.modelState + 1
end

function var_0_0.setIsShow(arg_42_0)
	arg_42_0.isShow = false

	arg_42_0:getHeroModel():idle()
end

function var_0_0.getHeroModel(arg_43_0)
	return arg_43_0.contentView_
end

return var_0_0
