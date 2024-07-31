local http = require("resty.http")
local cjson = require("cjson.safe")
local parse_url = require("socket.url").parse

local plugin = {
  PRIORITY = 1000,
  VERSION = "0.1",
}

function plugin:access(conf)
  local httpc = http.new()

  -- set auth header if it's specified
  local headers = {}
  if conf.auth_header_name and conf.auth_header_value then
    kong.log.debug("setting auth header with name ", conf.auth_header_name)
    headers[conf.auth_header_name] = conf.auth_header_value
  end

  -- single-shot requests use the `request_uri` interface.
  local res, err = httpc:request_uri(conf.target_url, {
    method = "GET",
    headers = headers,
  })

  if not res then
    ngx.log(ngx.ERR, "request failed: ", err)
    return
  end

  -- decode
  local body_t, err = cjson.decode(res.body)
  if err then
    return kong.response.exit(400, { message = "unable to decode the callout response in http-callout plugin" })
  end

  kong.log.inspect("http-callout response: ", body_t)  -- DEBUGGING

  -- find the detail we want
  for _, v in ipairs(conf.json_locator) do
    if body_t[v] then
      body_t = body_t[v]
    else
      return kong.response.exit(400, { message = "json element " .. v .. " is not next in the tree" })
    end
  end

  -- if it's a flat string, set it to header, otherwise json-encode the table/object
  local result = (type(body_t) == "string" and body_t) or (cjson.encode(body_t))
  kong.service.request.set_header("x-result", result)

  -- kong.service.set_target(result, 443)  -- this is just another example, setting the backend hostname from the response
end

return plugin
