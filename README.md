# `rnb`

remote `Jupyter` `n`ote`b`ooks on `r`emote Linode machines

## quickstart

```
rnb: simplify provisioning & using remote GPUs on Linode

setup

1)  create a venv & install requirements: 

        make deps

2) get a PAT from Linode & configure the CLI (see notes): 

        linode-cli configure --token

usage

1) create a remote Linode instance:

        make create

2) initialize & start Jupyter notebook on the remote host

        make crnb                        [ only once ]

3) connect to/run the Jupyter notebook on the remote host

        make rnb

4) delete the remote machine when you are done

        make delete

notes:  - make sure to save your auth token in an .env file as Linode doesn't let you retrieve it later.


        - make sure to sync your data before and after training models.
```

## development
```
cmds:

  help                  show usage / common commands available

  quickstart            usage instructions


              -- python --

  cvenv:                create virtual environment in the current directory
  pvenv:                purge virtual environment in the current directory
  deps:                 init remote env [pip]
  nb:                   start jupyter notebook locally [jupyter]

              -- linode --

  genkey:               generate SSH key
  list:                 list available remote machines [linode-cli]
  getid:                get id of remote machine [linode-cli + jq]
  getip:                get ip of remote machine [linode-cli + jq]
  getstatus:            get status of remote machine [linode-cli + jq]
  types:                list available remote machine types [linode-cli]
  create:               crewate / provision new remote machine [linode-cli]
  delete:               delete remote machine [linode-cli]
  connect:              connect to remote machine [ssh]

              -- remote --

  addkey:               add SSH key
  renv:                 update deps [Linux]
  crpath:               initialize remote work dir
  prpath:               purge remote work dir
  lsync:                sync local files to remote [ssh]
  rsync:                sync remote files to local [ssh]
  crnb:                 create & start jupyter notebook on remote machine [jupyter]
  rnb:                  start jupyter notebook on remote machine [jupyter]
```
