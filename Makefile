default: elm typescript

elm:
	/usr/local/bin/elm make lib/StateMachine.elm --output=dist/elm/StateMachine.js --optimize
	node_modules/uglify-js/bin/uglifyjs dist/elm/StateMachine.js --compress 'pure_funcs="F2,F3,F4,F5,F6,F7,F8,F9,A2,A3,A4,A5,A6,A7,A8,A9",pure_getters,keep_fargs=false,unsafe_comps,unsafe' | node_modules/uglify-js/bin/uglifyjs --mangle --output=dist/elm/StateMachine.js
	elm-test

elm-debug:
	/usr/local/bin/elm make lib/StateMachine.elm --output=dist/elm/StateMachine.js
	elm-test

typescript:
	npm install
	# for now typescript gets built with atom-typescript.

graph:
	# make graph (svg) of architecture
	node_modules/madge/bin/cli.js --image graph.svg ./dist

test:
	elm-test
	apm test

count:
	rg --files | grep -v \.js$ | grep -v dist | grep -v \.png$ | grep -v \.gif$ | grep -v package-lock.json | xargs wc -l | sort -n
