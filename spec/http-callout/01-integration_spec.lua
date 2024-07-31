local helpers = require "spec.helpers"

local PLUGIN_NAME = "http-callout"
local MOCK_PORT = helpers.get_available_port()

for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

      -- set up openai mock fixtures
      local fixtures = {
        http_mock = {},
      }
      
      fixtures.http_mock.openai = [[
        server {
          server_name openai;
          listen ]]..MOCK_PORT..[[;
          
          default_type 'application/json';
    

          location = "/callout-mock" {
            content_by_lua_block {
              ngx.status = 200
              ngx.print('{ "field_we_dont_want": true, "object_we_want": { "field_we_want": "correct_value" }}')
            }
          }
        }
      ]]

      local test = assert(bp.routes:insert {
        protocols = { "http" },
        strip_path = true,
        paths = { "/test" }
      })
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = test.id },
        config = {
          target_url = "http://"..helpers.mock_upstream_host..":"..MOCK_PORT.."/callout-mock",  -- see line 27 for mock server declaration
          json_locator = {
            "object_we_want",
            "field_we_want",
          },
          auth_header_name = "x-auth",
          auth_header_value = "Bearer kong",
        },
      }
      --

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }, nil, nil, fixtures))
    end)
    
    lazy_teardown(function()
      helpers.stop_kong()
    end)

    before_each(function()
      client = helpers.proxy_client()
    end)

    after_each(function()
      if client then client:close() end
    end)

    describe("test general", function()
      it("gets the right value from the mock server", function()
        local r = client:get("/test")

        -- validate that the request succeeded, response status 200
        assert.res_status(200 , r)

        -- validate that the backend got the header
        local header_value = assert.request(r).has.header("x-result")
        -- validate the value of that header
        assert.equal("correct_value", header_value)
      end)
    end)
  end)
end end
