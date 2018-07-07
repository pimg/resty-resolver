local resolver = require("resty.dns.resolver")
local cacheManager = require("lua.dns_cache")
local timer = ngx.timer.at
local log = ngx.log

local _M = {}

local function parseAddress(address)

    local host = nil
    local port = nil

    local seperator = address:find(":")

    if not seperator then
        port = 80
        host = address
    else
        port = address:sub(seperator + 1)
        host = address:sub(0, seperator-1)
    end

    return host, port
end

local queryDnsServer = function(host)

  local resolver, err = resolver:new{
      nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
      retrans = 5,  -- 5 retransmissions on receive timeout
      timeout = 2000,  -- 2 sec
  }

  if not resolver then
      log(ngx.DEBUG, "failed to instantiate the resolver: ", err)
      return
  end

  local answers, err, tries = resolver:query(host, nil, {})
  if not answers then
      log(ngx.DEBUG, "failed to query the DNS server: ", err)
      log(ngx.DEBUG, "retry history:\n  ", table.concat(tries, "\n  "))
      return
  end

  if answers.errcode then
      log(ngx.DEBUG, "server returned error code: ", answers.errcode,
              ": ", answers.errstr)
  end

  return answers

end

local function createStruct(host, port, answer)
  dnsEntry = {
    host = host,
    port = port,
    ip = answer.address,
    ttl = answer.ttl,
  }

  return dnsEntry
end


local function parseAnswers(answers, port)

  local dnsCache = cacheManager.getDnsCache()
  local host = answers[1].name

  for i, ans in ipairs(answers) do
      if (ans.address ~= nil) then
        local dnsEntry = createStruct(host, port, ans)

        dnsCache:set(host, dnsEntry)
        log(ngx.DEBUG, "The following DNS entry has been added to the cache: Host=" .. dnsEntry.host .. " IP=" .. dnsEntry.ip .. " TTL=" .. dnsEntry.ttl)

        local hosts = {
          host .. ":" .. dnsEntry.port
        }

        local resolveDNS = require("lua.dns_resolver").getResolverFn()

        local backgroundHandler, err = timer(dnsEntry.ttl, resolveDNS, hosts)
        if not backgroundHandler then
          log(ngx.ERR, "failed to create backgroudHandler, exiting...")
          return
        end

        return host, dnsEntry
      end
  end

end


local resolveDNS = function(isPremature, hosts)

  for _, address in ipairs(hosts) do

    host, port = parseAddress(address)
    local answers = queryDnsServer(host)

    parseAnswers(answers, port)

  end

end

function _M.getResolverFn()
  return resolveDNS
end

function _M.queryDnsServerFn()
  return queryDnsServer
end

return _M
