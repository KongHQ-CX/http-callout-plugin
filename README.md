# Installation

1. Copy all `kong/plugins/http-callout/*.lua` files into `/usr/local/share/lua/5.1/kong/plugins/http-callout/.`
2. Activate the plugin by setting Kong config: `plugins = bundled,http-callout` (or Helm: `plugins: "bundled,http-callout"`)
3. Upload the `kong/plugins/http-callout/schema.lua` to Konnect "Custom Plugins" menu, in each control plane it's required
