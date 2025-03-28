# Detect the operating system and architecture to set TAILWINDCSS_OS_ARCH accordingly
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S),Linux)
	ifeq ($(UNAME_M),x86_64)
		TAILWINDCSS_OS_ARCH := linux-x64
	else ifeq ($(UNAME_M),aarch64)
		TAILWINDCSS_OS_ARCH := linux-arm64
	else
		$(error Unsupported Linux architecture: $(UNAME_M))
	endif
else ifeq ($(UNAME_S),Darwin)
	TAILWINDCSS_OS_ARCH := macos-arm64
else ifeq ($(OS),Windows_NT)
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		TAILWINDCSS_OS_ARCH := windows-x64.exe
	else ifeq ($(PROCESSOR_ARCHITECTURE),ARM64)
		TAILWINDCSS_OS_ARCH := windows-arm64.exe
	else
		$(error Unsupported Windows architecture: $(PROCESSOR_ARCHITECTURE))
	endif
else
	$(error Unsupported operating system: $(UNAME_S))
endif

.PHONY: benchmark
benchmark:
	go test -bench=.

.PHONY: build-css
build-css: tailwindcss
	./tailwindcss -i tailwind.css -o public/styles/app.css --minify

.PHONY: build-docker
build-docker: build-css
	docker build --platform linux/amd64,linux/arm64 .

.PHONY: cover
cover:
	go tool cover -html=cover.out

.PHONY: lint
lint:
	golangci-lint run

.PHONY: start
start: build-css
	go run ./cmd/app

tailwindcss:
	curl -sLO https://github.com/tailwindlabs/tailwindcss/releases/latest/download/tailwindcss-$(TAILWINDCSS_OS_ARCH)
	mv tailwindcss-$(TAILWINDCSS_OS_ARCH) tailwindcss
	chmod a+x tailwindcss
	mkdir -p node_modules/tailwindcss/lib
ifeq ($(OS),Windows_NT)
	cmd /c copy tailwindcss node_modules\tailwindcss\lib\cli.js
else
	ln -sf tailwindcss node_modules/tailwindcss/lib/cli.js
endif
	echo '{"devDependencies": {"tailwindcss": "latest"}}' >package.json

.PHONY: test
test:
	go test -coverprofile=cover.out -shuffle on ./...

.PHONY: watch-css
watch-css: tailwindcss
	./tailwindcss -i tailwind.css -o public/styles/app.css --watch
