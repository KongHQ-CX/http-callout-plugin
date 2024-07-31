# Clone repository first, then run 'make install'
.PHONY: install
install:
	@mkdir -p /usr/local/share/lua/5.1/kong/plugins/http-callout
	@cp -R kong/plugins/http-callout/*.lua /usr/local/share/lua/5.1/kong/plugins/http-callout/
