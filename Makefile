# linode
ifeq ($(ruser),)
ruser := root
endif
ifeq ($(rpass),)
rpass := supersecretpass*9
endif
ifeq ($(lport),)
lport := 8888
endif
rpath := /root/nbs
rregion := us-east
rimage := linode/debian9
rtype := g6-standard-1
rlabel := nbs
# virtual env
ifeq ($(vname),)
vname := venv
endif

.DEFAULT_GOAL := help
TARGET_MAX_CHAR_NUM=20
# COLORS
ifneq (,$(findstring xterm,${TERM}))
	BLACK        := $(shell tput -Txterm setaf 0 || exit 0)
	RED          := $(shell tput -Txterm setaf 1 || exit 0)
	GREEN        := $(shell tput -Txterm setaf 2 || exit 0)
	YELLOW       := $(shell tput -Txterm setaf 3 || exit 0)
	LIGHTPURPLE  := $(shell tput -Txterm setaf 4 || exit 0)
	PURPLE       := $(shell tput -Txterm setaf 5 || exit 0)
	BLUE         := $(shell tput -Txterm setaf 6 || exit 0)
	WHITE        := $(shell tput -Txterm setaf 7 || exit 0)
	RESET := $(shell tput -Txterm sgr0)
else
	BLACK        := ""
	RED          := ""
	GREEN        := ""
	YELLOW       := ""
	LIGHTPURPLE  := ""
	PURPLE       := ""
	BLUE         := ""
	WHITE        := ""
	RESET        := ""
endif

## show usage / common commands available
.PHONY: help
help:
	@printf "${RED}cmds:\n\n";

	@awk '{ \
			if ($$0 ~ /^.PHONY: [a-zA-Z\-\_0-9]+$$/) { \
				helpCommand = substr($$0, index($$0, ":") + 2); \
				if (helpMessage) { \
					printf "  ${PURPLE}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n\n", helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^[a-zA-Z\-\_0-9.]+:/) { \
				helpCommand = substr($$0, 0, index($$0, ":")); \
				if (helpMessage) { \
					printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
					helpMessage = ""; \
				} \
			} else if ($$0 ~ /^##/) { \
				if (helpMessage) { \
					helpMessage = helpMessage"\n                     "substr($$0, 3); \
				} else { \
					helpMessage = substr($$0, 3); \
				} \
			} else { \
				if (helpMessage) { \
					print "\n${LIGHTPURPLE}             "helpMessage"\n" \
				} \
				helpMessage = ""; \
			} \
		}' \
		$(MAKEFILE_LIST)

# create should take machine size / location at the very least

## usage instructions
.PHONY: quickstart
quickstart:
	@printf "${YELLOW}nbs${RESET}: simplify provisioning & using remote GPUs on Linode\n\n"
	@printf "${LIGHTPURPLE}setup${RESET}\n\n"
	@echo "${GREEN}1)${RESET}  create a venv & install requirements: "
	@echo
	@echo "	${RED}make cvenv && make deps${RESET}"
	@echo
	@echo "${GREEN}2)${RESET} get a PAT from Linode & configure the CLI (see ${GREEN}notes${RESET}): "
	@echo
	@echo "	${RED}linode-cli configure --token${RESET}"
	@echo
	@echo "${LIGHTPURPLE}usage${RESET}"
	@echo
	@echo "${GREEN}1)${RESET} create a remote Linode instance:"
	@echo
	@echo "	${RED}make create${RESET}"
	@echo
	@echo "${GREEN}2)${RESET} initialize & start ${GREEN}Jupyter${RESET} notebook on the remote host"
	@echo
	@echo "	${RED}make genkey${RESET}		${LIGHTPURPLE} [ only once ]${RESET}"
	@echo "	${RED}make addkey${RESET}		${LIGHTPURPLE} [ only once ]${RESET}"
	@echo "	${RED}make crnb${RESET}			${LIGHTPURPLE} [ only once ]${RESET}"
	@echo
	@echo "${GREEN}3)${RESET} connect to the ${GREEN}Jupyter${RESET} notebook on the remote host"
	@echo
	@echo "	${RED}make rnb${RESET}"
	@echo
	@echo "${GREEN}4)${RESET} delete the remote machine when you are done"
	@echo
	@echo "	${RED}make delete${RESET}"
	@echo
	@echo "${BLUE}notes${RESET}:	- make sure to save your auth token in an ${GREEN}.env${RESET} file as ${GREEN}Linode${RESET} doesn't let you retrieve it later.\n"
	@echo
	@echo "	- make sure to sync your data before and after training models.\n"


# notes: save the token in the .env file as well you can't recover it


## -- python --

## create virtual environment in the current directory
cvenv:
	@echo "creating virtual environment..."
	@python3 -m venv $(CURDIR)/${vname}

## purge virtual environment in the current directory
pvenv:
	@echo "purging virtual environment..."
	@rm -rf $(CURDIR)/${vname}


## init remote env [pip]
deps: cvenv
	@echo "installing deps..."
	@$(CURDIR)/${vname}/bin/pip3 install --upgrade pip wheel setuptools
	@$(CURDIR)/${vname}/bin/pip3 install -r requirements.txt

## start jupyter notebook locally [jupyter]
nb: deps
	@echo "starting notebook..."
	$(CURDIR)/${vname}/bin/jupyter notebook --allow-root

## -- linode --

## generate SSH key
genkey:
	@echo "generating SSH key..."
	@mkdir -p .ssh
	@ssh-keygen -t rsa -b 4096 -f $(CURDIR)/.ssh/id_rsa

## list available remote machines [linode-cli]
list:
	@echo "getting available remote machines..."
	@linode-cli linodes list

## get id of remote machine [linode-cli + jq]
getid:
	@echo "$(shell linode-cli linodes list --json | jq '.[] | select(.label == "nbs") | {id}' | jq '.id')"

## get ip of remote machine [linode-cli + jq]
getip:
	@echo "$(shell linode-cli linodes list --json | jq '.[] | select(.label == "nbs") | {ipv4}' | jq '.ipv4[]')"

## get status of remote machine [linode-cli + jq]
getstatus:
	@echo "$(shell linode-cli linodes list --json | jq '.[] | select(.label == "nbs") | {status}' | jq '.status')"

## list available remote machine types [linode-cli]
types:
	@echo "getting available remote machine types..."
	@linode-cli linodes types

## create / provision new remote machine [linode-cli]
create:
	@echo "creating remote machine..."
	@linode-cli linodes create --root_pass ${rpass} --type ${rtype} --region ${rregion} --image ${rimage} --label ${rlabel}

## delete remote machine [linode-cli]
delete:
	@echo "deleting remote machine: $(shell make getid)"
	@linode-cli linodes delete $(shell make getid)

## connect to remote machine [ssh]
connect:
	@echo "connecting to remote machine: ${ruser}@$(shell make getip)"
	@ssh -i $(CURDIR)/.ssh/id_rsa -tL ${lport}:localhost:8888 ${ruser}@$(shell make getip) ${rcmd}

## -- remote --

## add SSH key
addkey:
	@linode-cli linodes rebuild $(shell make getid) --root_pass ${rpass} --image ${rimage} --authorized_keys "$(shell cat $(CURDIR)/.ssh/id_rsa.pub)"

## update deps [Linux]
renv:
	@echo "updating remote env [Linux] deps..."
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "apt-get update"
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "apt-get upgrade -y"
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "apt-get install make sudo vim curl -y"
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "apt-get install build-essential libssl-dev libffi-dev python3-dev python3-pip python3-venv -y"

## initialize remote work dir
crpath:
	@echo "creating remote path..."
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "mkdir -p ${rpath}"

## purge remote work dir
prpath:
	@echo "creating remote path..."
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "rm -rf ${rpath}"

## sync local files to remote [ssh]
lsync: crpath
	@echo "syncing files: local -> remote"
	@ssh -tL ${lport}:localhost:8888 -i $(CURDIR)/.ssh/id_rsa ${ruser}@$(shell make getip) "mkdir -p ${rpath}"
	@scp -i $(CURDIR)/.ssh/id_rsa -rC src ${ruser}@$(shell make getip):${rpath}
	@scp -i $(CURDIR)/.ssh/id_rsa -rC storage ${ruser}@$(shell make getip):${rpath}
	@scp -i $(CURDIR)/.ssh/id_rsa Makefile ${ruser}@$(shell make getip):${rpath}
	@scp -i $(CURDIR)/.ssh/id_rsa requirements.txt ${ruser}@$(shell make getip):${rpath}

## sync remote files to local [ssh]
rsync:
	@echo "syncing files: remote -> local"
	@scp -i $(CURDIR)/.ssh/id_rsa -rC ${ruser}@$(shell make getip):${rpath}/* .

## create & start jupyter notebook on remote machine [jupyter]
crnb: renv lsync
	@echo "creating remote notebook..."
	@ssh -i $(CURDIR)/.ssh/id_rsa -tL ${lport}:localhost:8888 ${ruser}@$(shell make getip) "cd ${rpath} && make nb"

## start jupyter notebook on remote machine [jupyter]
rnb:
	@echo "starting remote notebook..."
	@ssh -i $(CURDIR)/.ssh/id_rsa -tL ${lport}:localhost:8888 ${ruser}@$(shell make getip) "cd ${rpath} && make nb"