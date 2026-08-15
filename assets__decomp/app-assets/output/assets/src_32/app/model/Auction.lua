local var_0_0 = class("Auction", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = 1
local var_0_3 = 2

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.model = var_0_2
	arg_1_0.auctionList = {}
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.getAuctionInfoByType(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_AUCTION_INFO_BY_TYPE, var_3_0, function(arg_4_0, arg_4_1)
		if arg_4_0 == xyd.error.OK then
			arg_3_0.model = var_3_0.auction_type
			arg_3_0.auctionList = arg_4_1.auction_list

			if arg_3_2 then
				arg_3_2(arg_4_0, arg_4_1)
			end
		end
	end)
end

function var_0_0.getAuctionLog(arg_5_0, arg_5_1, arg_5_2)
	local var_5_0 = arg_5_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_AUCTION_LOG, var_5_0, function(arg_6_0, arg_6_1)
		if arg_6_0 == xyd.error.OK and arg_5_2 then
			arg_5_2(arg_6_0, arg_6_1)
		end
	end)
end

function var_0_0.refreshAuctions(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = arg_7_1 or {}

	xyd.Backend.get():request(xyd.mid.GET_AUCTION_INFO_BY_TYPE, var_7_0, function(arg_8_0, arg_8_1)
		if arg_8_0 == xyd.error.OK then
			arg_7_0.model = var_7_0.auction_type
			arg_7_0.auctionList = arg_8_1.auction_list

			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.AUCTION_REFRESH
			})
		end
	end)
end

function var_0_0.bidding(arg_9_0, arg_9_1, arg_9_2)
	local var_9_0 = arg_9_1 or {}

	xyd.Backend.get():request(xyd.mid.AUCTION_BIDDING, var_9_0, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].buyer_info = arg_10_1.auction_info.buyer_info
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].currency_type = arg_10_1.auction_info.currency_type
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].is_done = arg_10_1.auction_info.is_done
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].item_id = arg_10_1.auction_info.item_id
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].now_buyer = arg_10_1.auction_info.now_buyer
			arg_9_0.auctionList[tonumber(var_9_0.auction_pos)].now_price = arg_10_1.auction_info.now_price

			if arg_9_2 then
				arg_9_2(arg_10_0, arg_10_1)
			end
		end
	end)
end

return var_0_0
