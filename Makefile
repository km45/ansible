TTY := true
OUT := dest

.PHONY: up
up:
	docker-compose up --build -d

.PHONY: down
down:
	docker-compose down

.PHONY: shell
shell:
	docker-compose exec --user `id -u`:`id -g` $(SERVICE) bash

.PHONY: lint
lint: jsonlint ansiblelint awesome-ci

.PHONY: jsonlint
jsonlint:
ifeq ($(TTY), false)
	docker-compose exec -T node bash -c "find src/playbooks/ -name '*.json' -type f | xargs npx jsonlint -q"
else
	docker-compose exec    node bash -c "find src/playbooks/ -name '*.json' -type f | xargs npx jsonlint -q"
endif

.PHONY: ansiblelint
ansiblelint:
ifeq ($(TTY), false)
	docker-compose exec -T python bash -c "ansible-lint -x 301,305,306,701 src/playbooks/site.yml"
else
	docker-compose exec    python bash -c "ansible-lint -x 301,305,306,701 src/playbooks/site.yml"
endif

.PHONY: awesome-ci
awesome-ci:
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-crlf                    --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-trailing-newline        --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-trailing-single-newline --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-trailing-space          --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-utf8                    --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci file-utf8-bom                --path=/ac --ignore=".git,*/__pycache__"
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci syntax-json                  --path=/ac --ignore=".git,*/__pycache__" --extension=json
	docker run --rm -v $(CURDIR)/src:/ac cytopia/awesome-ci syntax-markdown              --path=/ac --ignore=".git,*/__pycache__" --extension=md

.PHONY: sync
sync:
	poetry install

.PHONY: test
test:
	poetry run bash -c "cd src/playbooks/roles/${ROLE} && molecule test"

.PHONY: test-all
test-all:
	bash test-all.sh

.PHONY: clean
clean:
	rm -rf $(OUT)

.PHONY: package-bionic
package-bionic:
	mkdir -p $(OUT)/ubuntu-bionic-vagrant
	cp -p src/vagrantfiles/ubuntu-bionic/Vagrantfile $(OUT)/ubuntu-bionic-vagrant
	cp -pr src/playbooks $(OUT)/ubuntu-bionic-vagrant

.PHONY: package-opensuse
package-opensuse:
	mkdir -p $(OUT)/opensuse-leap-15-2-vagrant
	cp -p src/vagrantfiles/ubuntu-bionic/Vagrantfile $(OUT)/opensuse-leap-15-2-vagrant
	cp -pr src/playbooks $(OUT)/opensuse-leap-15-2-vagrant

.PHONY: package
package: clean package-bionic package-opensuse

.PHONY: distribute-templates
distribute-templates:
	cp -p templates/DockerfileExtended.j2 src/playbooks/roles/git/molecule/default/DockerfileExtended.j2
	cp -p templates/DockerfileExtended.j2 src/playbooks/roles/python/molecule/default/DockerfileExtended.j2
	cp -p templates/DockerfileExtended.j2 src/playbooks/roles/rust/molecule/default/DockerfileExtended.j2
	cp -p templates/DockerfileExtended.j2 src/playbooks/roles/vscode/molecule/default/DockerfileExtended.j2
