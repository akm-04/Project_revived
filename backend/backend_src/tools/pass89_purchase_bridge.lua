-- PASS89 PRESERVATION OTA PURCHASE BRIDGE
-- PRIVATE-SERVER ADAPTER. The original native xydPurchases/xydNewPurchase/
-- xydNPurchase boundary is not recoverable in the canonical bundle.  This
-- override intercepts only the seven direct Crystal charge.lua products and
-- leaves every other purchase path on the original client implementation.
local pass89DirectCharge = {
    [80001002] = true, [80001003] = true, [80001004] = true,
    [80001005] = true, [80001006] = true, [80001007] = true,
    [80001030] = true
}
local pass89OriginalAndroidPurchase = xyd.androidPurchase
local pass89OriginalSdkPurchase = xyd.sdkPurchase
local pass89Sequence = 0

local function pass89PurchaseEndpoint()
    local url = xyd.Backend.get():getWebAPIURL_()
    url = string.gsub(url, "/api/v1/$", "")
    url = string.gsub(url, "/api/v1$", "")
    return url .. "/preservation/v1/purchase-intents"
end

local function pass89PendingKey(chargeID)
    return "__gxb_pass89_purchase_pending_" .. tostring(chargeID)
end

local function pass89GetOrCreateIntent(chargeID)
    local defaults = cc.UserDefault:getInstance()
    local key = pass89PendingKey(chargeID)
    local existing = defaults:getStringForKey(key) or ""
    if #existing > 0 then
        return existing
    end
    pass89Sequence = pass89Sequence + 1
    local player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
    local playerID = player and player.playerID or 0
    local now = xyd.ServerTime and xyd.ServerTime.get():getServerTime() or os.time()
    local intent = "ota89-" .. tostring(playerID) .. "-" .. tostring(now) .. "-" .. tostring(pass89Sequence)
    defaults:setStringForKey(key, intent)
    return intent
end

local function pass89ClearIntent(chargeID, intentID)
    local defaults = cc.UserDefault:getInstance()
    local key = pass89PendingKey(chargeID)
    local existing = defaults:getStringForKey(key) or ""
    if existing == tostring(intentID) then
        defaults:setStringForKey(key, "")
    end
end

function xyd.pass89Purchase(chargeID)
    chargeID = tonumber(chargeID)
    if not chargeID or not pass89DirectCharge[chargeID] then
        return nil
    end
    local intentID = pass89GetOrCreateIntent(chargeID)
    local backend = xyd.Backend.get()
    local token = tostring(backend.token_ or "")
    local region = tostring(backend.region_ or 0)
    if #token == 0 or region == "0" then
        print("[PASS89 OTA] purchase blocked: missing current token/region")
        return intentID
    end

    local function completed(evt)
        if evt.name ~= "completed" and evt.name ~= "failed" then
            return
        end
        if evt.name ~= "completed" then
            -- Keep the durable client intent.  The next tap retries the exact
            -- same server receipt identity instead of risking a double grant.
            print("[PASS89 OTA] transport failure; intent retained=" .. tostring(intentID))
            return
        end
        local code = evt.request:getResponseStatusCode()
        local raw = evt.request:getResponseString()
        print("[PASS89 OTA] purchase code=" .. tostring(code) .. " body=" .. tostring(raw))
        local ok, body = pcall(json.decode, raw or "")
        if not ok or not body then
            return
        end
        if code == 200 and body.ok == 1 and body.recharge_event then
            pass89ClearIntent(chargeID, intentID)
            xyd.EventDispatcher.get():dispatchEvent({
                name = xyd.event.RECHARGE,
                params = body.recharge_event
            })
            return
        end
        -- Explicit client/policy rejection means no transaction committed; a
        -- future click may create a new intent after the operator fixes input.
        if code >= 400 and code < 500 then
            pass89ClearIntent(chargeID, intentID)
        end
    end

    local req = network.createHTTPRequest(completed, pass89PurchaseEndpoint(), "POST")
    local function form(key, value)
        value = tostring(value or "")
        req:addFormContents(key, value, #value)
    end
    form("intent_id", intentID)
    form("charge_id", chargeID)
    form("platform", "lua_preservation")
    form("token", token)
    form("region", region)
    local expectedPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
    if expectedPlayer and expectedPlayer.playerID then
        form("expected_player_id", expectedPlayer.playerID)
    end
    -- local_token is the fixed compatibility credential for the legacy
    -- sandbox account. The live client may intentionally use it, but copied
    -- manual curl examples do not get this opt-in automatically.
    if token == "local_token" then
        form("allow_legacy_sandbox", "1")
    end
    req:start()
    return intentID
end

xyd.androidPurchase = function(arg1, arg2, chargeID, arg4, arg5, arg6, arg7)
    local id = tonumber(chargeID)
    if id and pass89DirectCharge[id] then
        return xyd.pass89Purchase(id)
    end
    return pass89OriginalAndroidPurchase(arg1, arg2, chargeID, arg4, arg5, arg6, arg7)
end

xyd.sdkPurchase = function(productID, canBuy, chargeID, arg4, arg5, arg6)
    local id = tonumber(chargeID)
    if id and pass89DirectCharge[id] then
        return xyd.pass89Purchase(id)
    end
    return pass89OriginalSdkPurchase(productID, canBuy, chargeID, arg4, arg5, arg6)
end

print("[PASS89 OTA] direct Crystal purchase bridge installed")
