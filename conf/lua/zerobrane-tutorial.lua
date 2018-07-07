require('mobdebug').start()
local name = ngx.var.arg_name or "Anonymous"
ngx.say("Hello, ", name, "!")
ngx.say("Done debugging.")
require('mobdebug').done()