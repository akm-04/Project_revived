local var_0_0 = class("WhiteAlbumTotalAttrWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.attr
local var_0_3 = {
	4,
	5,
	6,
	7,
	8,
	9,
	10,
	11,
	12,
	13,
	14,
	15,
	17,
	18,
	19,
	20,
	21,
	22,
	26,
	35,
	37,
	38
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.collectNum = arg_1_2.collectNum
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0:nodeByName("title_txt"):setString(var_0_1:translation("WHITE_ALBUM_TXT11"))
	arg_2_0:nodeByName("lbl_partner"):setString(var_0_1:translation("WHITE_ALBUM_TXT12"))
	arg_2_0:nodeByName("lbl_stage"):setString(var_0_1:translation("WHITE_ALBUM_TXT13"))
	arg_2_0:nodeByName("partner_num"):setString(arg_2_0.collectNum)

	local var_2_0 = 0

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.selfPlayer.heros_) do
		var_2_0 = var_2_0 + (iter_2_1.collectQualityStage or 0)
	end

	arg_2_0:nodeByName("stage_num"):setString(var_2_0)

	arg_2_0.list = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, arg_2_0:nodeByName("list"):getWidth(), arg_2_0:nodeByName("list"):getHeight()),
		direction = cc.ui.UIListView.DIRECTION_VERTICAL,
		alignment = cc.ui.UIListView.ALIGNMENT_HCENTER
	}):addTo(arg_2_0:nodeByName("list"))

	arg_2_0.list:setDelegate(handler(arg_2_0, arg_2_0.listDelegate))
	arg_2_0.list:reload()
end

function var_0_0.didOpen(arg_3_0)
	arg_3_0:addBlockLayer()
end

function var_0_0.listDelegate(arg_4_0, arg_4_1, arg_4_2, arg_4_3)
	if cc.ui.UIListView.COUNT_TAG == arg_4_2 then
		return #var_0_3
	elseif cc.ui.UIListView.CELL_TAG == arg_4_2 then
		local var_4_0
		local var_4_1 = arg_4_1:dequeueItem()

		if not var_4_1 then
			var_4_1 = arg_4_1:newItem()
		else
			var_4_1:removeAllChildren(false)
		end

		local var_4_2 = display.newNode()

		var_4_2:size(427, 45)
		var_4_1:addContent(var_4_2)
		var_4_1:setItemSize(427, 45)

		local var_4_3 = xyd.AssetLoader.get():loadNodeFromJson("windows/white_album/attr_item.csb")
		local var_4_4 = var_4_3:getChildByName("container")
		local var_4_5 = var_0_3[arg_4_3]

		var_4_4:getChildByName("attr_txt"):setString(var_0_2:name(var_4_5))
		var_4_4:getChildByName("attr_num"):setString("+" .. arg_4_0.selfPlayer.albumAttr[var_4_5])
		var_4_4:getChildByName("lbl_bg"):width(var_4_4:getChildByName("attr_txt"):getWidth() + 34)
		var_4_3:addTo(var_4_2)

		return var_4_1
	end
end

return var_0_0
