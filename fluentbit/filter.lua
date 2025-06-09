local HEADERS_TO_REDACT = {
    "authorization",
    "x-api-key",
    "x-amz-security-token",
    "cookie",
    "set-cookie",
    "apikey"
}

-- Redact headers defined in HEADERS_TO_REDACT.
-- Define headers in lowercase, and the function below will lowercase check them.
-- Original casing will be kept in log for readability.
function redact_headers(tag, timestamp, record)
    --record._lua_debug = "record: " .. record.request

    if record.request.headers then
       for _, key in ipairs(HEADERS_TO_REDACT) do
            if record.request.headers[string.lower(key)] ~= nil then
                record.request.headers[key] = "***REDACTED***"
            end
        end
    end
    return 1, timestamp, record
end