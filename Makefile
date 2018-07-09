PREFIX ?= /usr/local

shellcheck:
	shellcheck i-doit.sh
	shellcheck idoit
	shellcheck idoit-backup
	shellcheck idoit-hotfix
	shellcheck idoit-install
	shellcheck idoit-jobs
	shellcheck idoit-pwd
	shellcheck idoit-restore
	shellcheck idoit-support

deb:
	fpm -s dir -t deb \
	--name idoit-scripts \
	--version 0.10 \
	--architecture all \
	--license AGPLv3+ \
	--maintainer "Benjamin Heisig <benjamin@heisig.name>" \
	--vendor "synetics GmbH <info@i-doit.com>" \
	--description "Useful scripts to maintain i-doit" \
	--url "https://github.com/bheisig/i-doit-scripts" \
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
	idoit-restore=/usr/bin

lintian:
	lintian *.deb

install:
	install idoit* $(PREFIX)/bin/

uninstall:
	rm -f $(PREFIX)/bin/idoit*

clean:
	rm -f *.deb
