PREFIX     ?= ~/local/gazeteer
BIN_PREFIX ?= $(PREFIX)/bin

BIN_SCRIPTS := $(wildcard src/*)

install:
	mkdir -p $(BIN_PREFIX)

	cp $(BIN_SCRIPTS) $(BIN_PREFIX)

	for file in $(BIN_PREFIX)/* ; do mv $$file `echo $$file | cut -d'.' -f1` ; done

	chmod +x $(BIN_PREFIX)/*

	ls $(BIN_PREFIX)

	@echo "Make sure $(BIN_PREFIX) is in your PATH"

uninstall:
	rm -rf $(BIN_PREFIX)
	rm -rf $(PREFIX)

.PHONY: install uninstall