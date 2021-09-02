PREFIX ?= /usr/local

VERSION ?= $(shell ./idoit-install --version)

deb :
	fpm -s dir -t deb \
		--name idoit-scripts \
		--version $(VERSION) \
		--architecture all \
		--license AGPLv3+ \
		--maintainer "Benjamin Heisig <bheisig@i-doit.com>" \
		--vendor "synetics GmbH <info@i-doit.com>" \
		--description "Useful scripts to maintain i-doit" \
		--url "https://github.com/i-doit/scripts" \
		--deb-no-default-config-files \
		--deb-changelog CHANGELOG.md \
		--no-depends \
		--deb-priority optional \
		i-doit.sh=/etc/i-doit/ \
		idoit=/usr/bin/ \
		idoit-backup=/usr/bin \
		idoit-hotfix=/usr/bin \
		idoit-install=/usr/bin \
		idoit-jobs=/usr/bin \
		idoit-pwd=/usr/bin \
		idoit-restore=/usr/bin \
		idoit-support=/usr/bin

lintian :
	lintian *.deb

lint-markdown :
	npm run test:markdown

lint-shell :
	npm run test:shell

lint-yaml :
	npm run test:yaml

install :
	install idoit* $(PREFIX)/bin/
	mkdir -p /etc/i-doit
	install i-doit.sh /etc/i-doit

uninstall :
	rm -f $(PREFIX)/bin/idoit*
	rm -rf /etc/i-doit/

clean :
	rm -f *.deb
