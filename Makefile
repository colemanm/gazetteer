PREFIX					?= ~/local/gazetteer
BIN_PREFIX			?= $(PREFIX)/bin
SHARE_PREFIX		?= $(PREFIX)/share
CONFIG_PREFIX 	?= ~

BIN_SCRIPTS	 		:= $(wildcard src/*)
SHARE_SCRIPTS		:= $(wildcard share/*)

install:
	mkdir -p $(BIN_PREFIX)
	mkdir -p $(SHARE_PREFIX)

	cp $(BIN_SCRIPTS) $(BIN_PREFIX)
	cp $(SHARE_SCRIPTS) $(SHARE_PREFIX)

	for file in $(BIN_PREFIX)/* ; do mv $$file `echo $$file | cut -d'.' -f1` ; done

	chmod +x $(BIN_PREFIX)/*

	@echo "Make sure $(BIN_PREFIX) is in your PATH"

uninstall:
	rm -rf $(BIN_PREFIX)
	rm -rf $(PREFIX)

.PHONY: install uninstall