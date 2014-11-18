SRC = $(shell find src -name '*.coffee')
LIB = $(SRC:src/%.coffee=lib/%.js)

define release
    VERSION=`node -pe "require('./package.json').version"` && \
    NEXT_VERSION=`node -pe "require('semver').inc(\"$$VERSION\", '$(1)')"` && \
    node -e "\
        var j = require('./package.json');\
        j.version = \"$$NEXT_VERSION\";\
        var s = JSON.stringify(j, null, 4);\
        require('fs').writeFileSync('./package.json', s);\
	var b = require('./bower.json');\
	b.version = \"$$NEXT_VERSION\";\
	var t = JSON.stringify(b, null, 4);\
	require('fs').writeFileSync('./bower.json', t);" && \
    git commit -m "Version $$NEXT_VERSION" -- package.json bower.json && \
    git tag "$$NEXT_VERSION" -m "Version $$NEXT_VERSION"
endef

all: lib

lib: $(LIB)

watch:
	coffee -bc --watch -o lib src

lib/%.js: src/%.coffee
	@echo `date "+%H:%M:%S"` - compiled $<
	@mkdir -p $(@D)
	@coffee -bcp $< > $@

clean:
	rm -rf $(LIB)

release-patch:
	@$(call release,patch)

release-minor:
	@$(call release,minor)

release-major:
	@$(call release,major)

publish:
	git push
	git push --tags
	npm publish
