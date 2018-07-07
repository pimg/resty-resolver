local resolveDNS = require("lua.dns_resolver").getResolverFn()
local timer = ngx.timer.at
local log = ngx.log

log(ngx.NOTICE, "starting worker...")
--temp table holding all hostnames that need to be resolved and cached.
--TODO change to better config, like file or env vars, whatever
local hosts = {
  "echo-api.3scale.net:443",
  "postman-echo.com:443",
  "google.com",
}

local backgroundHandler, err = timer(0, resolveDNS, hosts)
if not backgroundHandler then
  log(ngx.ERR, "failed to create backgroudHandler, exiting...")
  return
end
