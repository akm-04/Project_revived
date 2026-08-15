local function var_0_0(arg_1_0, arg_1_1)
	print("\n********** \n" .. arg_1_0 .. " was deprecated please use " .. arg_1_1 .. " instead.\n**********")
end

local var_0_1 = {
	addHandleOfControlEvent = function(arg_2_0, arg_2_1, arg_2_2)
		var_0_0("addHandleOfControlEvent", "registerControlEventHandler")
		print("come in addHandleOfControlEvent")
		arg_2_0:registerControlEventHandler(arg_2_1, arg_2_2)
	end
}

CCControl.addHandleOfControlEvent = var_0_1.addHandleOfControlEvent
CCTableView.kTableViewScroll = cc.SCROLLVIEW_SCRIPT_SCROLL
CCTableView.kTableViewZoom = cc.SCROLLVIEW_SCRIPT_ZOOM
CCTableView.kTableCellTouched = cc.TABLECELL_TOUCHED
CCTableView.kTableCellSizeForIndex = cc.TABLECELL_SIZE_FOR_INDEX
CCTableView.kTableCellSizeAtIndex = cc.TABLECELL_SIZE_AT_INDEX
CCTableView.kNumberOfCellsInTableView = cc.NUMBER_OF_CELLS_IN_TABLEVIEW
CCScrollView.kScrollViewScroll = cc.SCROLLVIEW_SCRIPT_SCROLL
CCScrollView.kScrollViewZoom = cc.SCROLLVIEW_SCRIPT_ZOOM
