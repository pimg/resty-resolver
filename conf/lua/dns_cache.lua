local _M = {}

-- alternatively: local lrucache = require "resty.lrucache.pureffi"
local lrucache = require "resty.lrucache"

-- we need to initialize the cache on the lua module level so that
-- it can be shared by all the requests served by each nginx worker process:
local dnsCache, err = lrucache.new(200)  -- allow up to 200 items in the cache
if not dnsCache then
    return error("failed to create the cache: " .. (err or "unknown"))
end

function _M.getDnsCache()
  return dnsCache
end

return _M
