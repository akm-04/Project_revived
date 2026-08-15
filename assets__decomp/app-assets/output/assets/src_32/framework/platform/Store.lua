local var_0_0 = {}

local function var_0_1()
	if not cc.Store then
		printError("framework.cc.sdk.Store - cc.Store not exists.")

		return false
	end

	return true
end

function var_0_0.init(arg_2_0)
	if not var_0_1() then
		return false
	end

	if cc.storeProvider then
		printError("Store.init() - store already init")

		return false
	end

	if type(arg_2_0) ~= "function" then
		printError("Store.init() - invalid listener")

		return false
	end

	cc.storeProvider = cc.Store:sharedStore()

	return cc.storeProvider:postInitWithTransactionListener(arg_2_0)
end

function var_0_0.getReceiptVerifyMode()
	if not var_0_1() then
		return false
	end

	return cc.storeProvider:getReceiptVerifyMode()
end

function var_0_0.setReceiptVerifyMode(arg_4_0, arg_4_1)
	if not var_0_1() then
		return false
	end

	if type(arg_4_0) ~= "number" or arg_4_0 ~= cc.CCStoreReceiptVerifyModeNone and arg_4_0 ~= cc.CCStoreReceiptVerifyModeDevice and arg_4_0 ~= cc.CCStoreReceiptVerifyModeServer then
		printError("Store.setReceiptVerifyMode() - invalid mode")

		return false
	end

	if type(arg_4_1) ~= "boolean" then
		arg_4_1 = true
	end

	cc.storeProvider:setReceiptVerifyMode(arg_4_0, arg_4_1)
end

function var_0_0.getReceiptVerifyServerUrl()
	if not var_0_1() then
		return false
	end

	return cc.storeProvider:getReceiptVerifyServerUrl()
end

function var_0_0.setReceiptVerifyServerUrl(arg_6_0)
	if not var_0_1() then
		return false
	end

	if type(arg_6_0) ~= "string" then
		printError("Store.setReceiptVerifyServerUrl() - invalid url")

		return false
	end

	cc.storeProvider:setReceiptVerifyServerUrl(arg_6_0)
end

function var_0_0.canMakePurchases()
	if not var_0_1() then
		return false
	end

	return cc.storeProvider:canMakePurchases()
end

function var_0_0.loadProducts(arg_8_0, arg_8_1)
	if not var_0_1() then
		return false
	end

	if type(arg_8_1) ~= "function" then
		printError("Store.loadProducts() - invalid listener")

		return false
	end

	if type(arg_8_0) ~= "table" then
		printError("Store.loadProducts() - invalid productsId")

		return false
	end

	for iter_8_0 = 1, #arg_8_0 do
		if type(arg_8_0[iter_8_0]) ~= "string" then
			printError("Store.loadProducts() - invalid id[#%d] in productsId", iter_8_0)

			return false
		end
	end

	cc.storeProvider:loadProducts(arg_8_0, arg_8_1)

	return true
end

function var_0_0.cancelLoadProducts()
	if not var_0_1() then
		return false
	end

	cc.storeProvider:cancelLoadProducts()
end

function var_0_0.isProductLoaded(arg_10_0)
	if not var_0_1() then
		return false
	end

	return cc.storeProvider:isProductLoaded(arg_10_0)
end

function var_0_0.purchase(arg_11_0, arg_11_1)
	if not var_0_1() then
		return false
	end

	if not cc.storeProvider then
		printError("Store.purchase() - store not init")

		return false
	end

	if type(arg_11_0) ~= "string" then
		printError("Store.purchase() - invalid productId")

		return false
	end

	return cc.storeProvider:purchase(arg_11_0, arg_11_1 or "")
end

function var_0_0.restore()
	if not var_0_1() then
		return false
	end

	cc.storeProvider:restore()
end

function var_0_0.finishTransaction(arg_13_0)
	if not var_0_1() then
		return false
	end

	if not cc.storeProvider then
		printError("Store.finishTransaction() - store not init")

		return false
	end

	if type(arg_13_0) ~= "table" or type(arg_13_0.transactionIdentifier) ~= "string" then
		printError("Store.finishTransaction() - invalid transaction")

		return false
	end

	return cc.storeProvider:finishTransaction(arg_13_0.transactionIdentifier)
end

cc.iOSPay = var_0_0

return var_0_0
