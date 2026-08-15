local var_0_0 = class("PetGiftItemShowWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.item
local var_0_3 = 5
local var_0_4 = 100

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.title = arg_1_2.title
	arg_1_0.datas = arg_1_2.data
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:addBlockLayer()
	arg_2_0:initListview()
end

function var_0_0.initListview(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("list")
	local var_3_1 = var_3_0:getContentSize().width
	local var_3_2 = var_3_0:getContentSize().height

	arg_3_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1, var_3_2),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(var_3_0)

	arg_3_0.list:setDelegate(handler(arg_3_0, arg_3_0.delegate))
end

function var_0_0.delegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	local var_4_0 = math.ceil(#arg_4_0.datas / var_0_3) + 1

	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return var_4_0
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_1
		local var_4_2
		local var_4_3
		local var_4_4 = arg_4_0.list:dequeueItem()

		if not var_4_4 then
			var_4_4 = arg_4_0.list:newItem()
		else
			var_4_4:removeAllChildren()
		end

		local var_4_5 = display.newNode()

		var_4_5:setTouchSwallowEnabled(false)

		if arg_4_3 == 1 then
			var_4_3 = display.newNode()

			arg_4_0:initTitle(var_4_3, arg_4_3)
			var_4_5:addChild(var_4_3)
		else
			for iter_4_0 = 1, var_0_3 do
				local var_4_6 = (arg_4_3 - 2) * var_0_3 + iter_4_0

				if var_4_6 > #arg_4_0.datas then
					break
				end

				var_4_3 = display.newNode()

				arg_4_0:initItemCell(var_4_3, var_4_6)
				var_4_5:addChild(var_4_3)
				var_4_3:setPosition((iter_4_0 - 1) * (var_0_4 + 10) + 50, 0)
			end
		end

		var_4_5:setContentSize(cc.size(arg_4_0.list.viewRect_.width, var_4_3:getContentSize().height + 10))
		var_4_4:setItemSize(arg_4_0.list.viewRect_.width, var_4_3:getContentSize().height + 10)
		var_4_4:addContent(var_4_5)

		return var_4_4
	end
end

function var_0_0.initTitle(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1057/list_title.csb")

	var_5_0:addTo(arg_5_1)

	local var_5_1 = var_0_1:translation("CAN_GET") .. arg_5_0.title

	var_5_0:getChildByName("bg_title"):getChildByName("title_txt"):setString(var_5_1)
	arg_5_1:setContentSize(640, 50)

	return arg_5_1
end

function var_0_0.initItemCell(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.datas[arg_6_2]
	local var_6_1 = xyd.tables.item:type(var_6_0)
	local var_6_2 = display.newNode()

	var_6_2:setContentSize(var_0_4, var_0_4)

	if var_6_1 and var_6_1 == -1 then
		xyd.setAvatarBorder(var_6_0, var_6_2, 1, xyd.tables.hero:initialStar(var_6_0))
	elseif var_6_1 then
		xyd.setItemBorder(var_6_2, var_6_0)
	end

	var_6_2:addTo(arg_6_1)

	local var_6_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack():getItemNumByID(var_6_0)

	xyd.addTips(var_6_2, {
		isNotTouchSwallow = true,
		id = var_6_0,
		hasNum = var_6_3
	})
	arg_6_1:setContentSize(var_0_4, var_0_4)

	return arg_6_1
end

function var_0_0.didOpen(arg_7_0, arg_7_1)
	var_0_0.super:didOpen(arg_7_1)
	arg_7_0.list:reload()
end

return var_0_0
