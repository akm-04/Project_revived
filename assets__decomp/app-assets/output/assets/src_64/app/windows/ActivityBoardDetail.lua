local var_0_0 = class("ActivityBoardDetail")
local var_0_1 = 30
local var_0_2 = "images/default_board.png"

function var_0_0.ctor(arg_1_0, arg_1_1)
	arg_1_0.parent = arg_1_1.parent
	arg_1_0.title = arg_1_1.title
	arg_1_0.url = arg_1_1.url
	arg_1_0.contentTxt = xyd.luaStringSplit(arg_1_1.content, "|")
end

function var_0_0.show(arg_2_0, arg_2_1)
	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/board/board_detail.csb")

	var_2_0:addTo(arg_2_0.parent)

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("title"):setString(arg_2_0.title)
	var_2_1:getChildByName("title"):enableOutline(cc.c4b(65, 80, 147, 255), 3)

	local var_2_2 = var_2_1:getChildByName("list")
	local var_2_3 = var_2_2:getContentSize()
	local var_2_4 = cc.ui.UIListView.new({
		viewRect = cc.rect(0, 0, var_2_3.width, var_2_3.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_2)

	var_2_4:setBounceable(true)

	if arg_2_0.url and arg_2_0.url ~= "" then
		local var_2_5 = var_2_4:newItem()
		local var_2_6 = arg_2_0.url
		local var_2_7 = xyd.split(var_2_6, "/") or {}
		local var_2_8 = var_2_7[#var_2_7] or ""
		local var_2_9 = {
			md5_code = 1,
			file_name = var_2_8,
			file_path = cc.FileUtils:getInstance():getWritablePath()
		}
		local var_2_10 = import("app.common.ui.OnlineImageSprite").new(var_0_2, var_2_6, 0, 0, var_2_9)
		local var_2_11 = var_2_2:getWidth() / var_2_10:getWidth()

		var_2_10:setScale(var_2_11)

		local var_2_12 = display.newNode()

		var_2_12:addChild(var_2_10)
		var_2_5:addContent(var_2_12)
		var_2_5:setItemSize(var_2_2:getWidth(), var_2_10:getHeight() * var_2_11 + 20)
		var_2_4:addItem(var_2_5)
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0.contentTxt) do
		local var_2_13 = var_2_4:newItem()
		local var_2_14 = xyd.createUrlAndColorTxt(iter_2_1, cc.c3b(221, 245, 255), 22, var_2_3.width)
		local var_2_15 = var_2_14:getContentSize().height

		var_2_14:setContentSize(var_2_3.width, var_2_15)
		var_2_13:addContent(var_2_14)
		var_2_13:setItemSize(var_2_3.width, var_2_15)
		var_2_4:addItem(var_2_13)
	end

	var_2_4:reload()
end

function var_0_0.release(arg_3_0)
	return
end

return var_0_0
