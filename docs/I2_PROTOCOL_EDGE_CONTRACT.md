# I2 Protocol Edge Contract

## Source-fixed wire facts
- ordinary HTTP body is literal `payload=<one Lua string.urlencode(JSON(params))>`; native QuickHTTP adds no second encoding layer;
- special zlib multipart MIDs are exactly 279, 2484, 535, 774, 1412, 1570 and 2515;
- MID1844 is the upload path and source may duplicate `mid/token/region/v_`; duplicates normalize only when all values agree;
- source HTTP timeouts are 20s ordinary and 30s multipart/upload;
- source realtime routing is `mid & 0x9000 == 0x8000`, GM is `== 0x9000`;
- native realtime frame is `u32_be payload_len | u16_be MID | u32_be sequence | AMF3`, max payload 65,536;
- Xinyoudi native reader accepts markers 0x00..0x06, 0x09, 0x0A and rejects 0x07, 0x08 and >0x0A;
- ordinary Lua numbers are emitted as AMF3 double marker 0x05; dynamic Params objects use anonymous dynamic trait header 0x0B.

## V2 engineering policy
Body/decode/reference/queue/in-flight budgets are versioned V2 safety configuration, not claimed original-server constants. Unknown HTTP MIDs return small JSON 404, known-unimplemented return 501, malformed/wrong-family 400, size/inflate limits 413, and admission saturation 503 before mutation. TCP unknown/wrong-direction/malformed traffic fails closed; no generic success/error frame is invented.

## Authority boundary
HTTP/TCP packages only normalize transport claims and wire shapes. They never decide account/player/guild/gameplay authority. Numeric MID is canonical protocol identity. Network delivery never occurs inside canonical gameplay transactions. No universal client nonce/contextEpoch is introduced.
