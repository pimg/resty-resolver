local balancer = require "ngx.balancer"
local dnsCache = require("lua.dns_cache").getDnsCache()
local resolveDNSFn = require("lua.dns_resolver").getResolverFn()
local log = ngx.log

local host = ngx.var.upstream_host;
log(ngx.DEBUG, "getting upstream address for: " .. host)

local dnsEntry = dnsCache:get(host)

if not dnsEntry then
  log(ngx.ERR, "could not find IP address for the specified host" .. host)
  ngx.exit(502)
end

log(ngx.DEBUG, "trying to connect to address " .. dnsEntry.ip)

local ok, err = balancer.set_current_peer(dnsEntry.ip, dnsEntry.port)
if not ok then
    log(ngx.ERR, "failed to set the current peer: ", err)
end
