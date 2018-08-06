default: elm typescript

elm:
	elm-package install
	elm-make lib/state-machine.elm --output=dist/elm/state-machine.js

typescript:
	npm install
	# for now typescript gets built with atom-typescript.

graph:
	# make graph (svg) of architecture
	node_modules/madge/bin/cli.js --image graph.svg ./dist

test:
	apm test
