#!/bin/sh

set -e

log() {
	printf '[Entrypoint]: %s\n' "$*"
}

error() {
	log "$@" >&2
	exit 1
}

verify_minimum_env() {
	if [ -z "$TITLE" ]; then
		error $'Static is unitialized and options are not specified\n\tYou need to specify TITLE'
	fi
}

static_init() {
	if [ ! -e static.html ]; then
		log "static.html not found in $PWD, creating new one."
		echo "<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>$TITLE</title><style>body{margin:0;height:100vh;background:#111;display:flex;justify-content:center;align-items:center}main{font-family:'Courier New',Courier,monospace;font-size:8rem;font-weight:700;text-align:center;animation:colorchange 5s infinite;background:linear-gradient(45deg,red,orange,#ff0,green,#00f,indigo,violet);background-size:400% 400%;-webkit-background-clip:text;-webkit-text-fill-color:transparent}@keyframes colorchange{0%{background-position:0 50%}50%{background-position:100% 50%}100%{background-position:0 50%}}</style></head><body><main>$TITLE</main></body></html>" > static.html
	fi
}

if [ "$1" = 'true' ]; then
	log "Entrypoint script for static started."

	verify_minimum_env

	static_init
fi

exec "$@"
