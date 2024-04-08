# XDB CHAIN Quickstart Docker Image

This docker image provides a simple way to run stellar-core and horizon locally for development and testing using XDB CHAIN network.

**Looking for instructions for how to run stellar-core or horizon in production? Take a look at the docs [here](https://developers.xdbchain.com/posts/network-core/).**

This image provides a default, non-validating, ephemeral configuration that should work for most developers. By configuring a container using this image with a host-based volume (described below in the "Usage" section) an operator gains access to full configuration customization and persistence of data.

The image uses the following software:

- Postgresql 14 is used for storing both stellar-core and horizon data
- [stellar-core](https://github.com/stellar/stellar-core)
- [horizon](https://github.com/stellar/go/tree/master/services/horizon)
- [friendbot](https://github.com/stellar/go/tree/master/services/friendbot)
- Supervisord is used from managing the processes of the services above

## Usage

To use this project successfully, you should first decide a few things:

First, decide whether you want your container to be part of the public, production XDB CHAIN network (referred to as the _pubnet_) or the test network (called futurenet) that we recommend you to use while developing software because yoy won't need to worry about losing money on the futurenet. Alternatively, choose to run a local network (called local) which allows you to run your own acellerated private XDB CHAIN network for testing.

Next, you must decide whether you will use a docker volume or not.  When you are not using a volume, we say that the container is in _ephemeral mode_, and nothing will be persisted between runs of the container. _Persistent mode_ is an alternative that should be used if you need to customize your configuration (such as adding a validation seed) or would like to avoid a slow catch-up to the XDB CHAIN network in the event of a crash or server restart  We recommend using persistent mode for everything except development or test environments.

Finally, you must decide what ports to expose. The software in these images listen to 4 ports, each of which you may or may not want to expose to the network your host system is connected to.  A container that exposes no ports isn't very useful, so we recommend that you, at a minimum, expose the horizon HTTP port.  See the "Ports" section below for a more nuanced discussion regarding the decision about what ports to expose.

After deciding on the questions above, you can setup your container.  Please refer to the appropriate section below based upon what mode you will run the container in.

## Example launch commands

Below is a list of various ways you might want to launch the quickstart container annotated to illustrate what options are enabled.  It's also recommended that you should learn and get familiar with the docker command.

*Launch an ephemeral local only dev/test network:*
```
$ docker run -d -p "8000:8000" --name xdbchain ghcr.io/xdbfoundation/xdbchain-quickstart:latest --local
```

*Launch an ephemeral testnet node in the foreground:*
```
$ docker run --rm -it \
    -p "8000:8000" \
    --name xdbchain \
    ghcr.io/xdbfoundation/xdbchain-quickstart:latest --futurenet
```

*Setup a new persistent node using the host directory `/str`:*
```
$ docker run -it --rm \
    -p "8000:8000" \
    -v "/str:/opt/stellar" \
    --name xdbchain \
    ghcr.io/xdbfoundation/xdbchain-quickstart:latest --futurenet
```

### Network Options

Provide either `--pubnet`, `--futurenet` or `--local` as a command line flag when starting the container to determine which network (and base configuration file) to use.

#### `--pubnet`

In public network mode, the node will join the public, production XDB CHAIN network.

_Note: In pubnet mode the node will consume more disk, memory, and CPU resources because of the size of the network history and frequency of transactions._

#### `--futurenet`

In test network mode, the node will join the network that developers use while developing software. Use the [XDB CHAIN Laboratory](https://laboratory.xdbchain.com/#?network=futurenet) to create an account on the FutureNet network.

#### `--local`

In local network mode, you can optionally pass:

- `--protocol-version {version}` to run a specific protocol version (defaults to latest version).

- `--limits {limits}` to configure specific resource limits of the network to one of:
   - `default` leaves limits set extremely low which is stellar-core's default configuration
   - `futurenet` sets limits to match those used on futurenet (the default quickstart configuration)
   - `unlimited` sets limits to the maximum resources that can be configured

The network passphrase of the local network defaults to:
```
Standalone Network ; February 2017
```

Set the network passphrase in the SDK or tool you're using. Transactions will fail with a bad authentication error if an incorrect network passphrase is used for signing.

The root account of the network is fixed to:
```
Public Key: GBZXN7PIRZGNMHGA7MUUUF4GWPY5AYPV6LY4UV2GL6VJGIQRXFDNMADI
Secret Key: SC5O7VZUXDJ6JBDSZ74DSERXL7W3Y5LTOAMRF7RQRL3TAGAPS7LUVG3L
```

The root account is derived from the network passphrase and if the network passphrase is changed the root account will change. To find out the root account when changing the network passphrase view the logs for stellar-core on its first start. See [Viewing logs](#viewing-logs) for more details.

In local network mode a ledger occurs every one second and so transactions
are finalized faster than on deployed networks.

*Note*: The local network in this container is not suitable for any production use as it has a fixed root account. Any private network intended for production use would also required a unique network passphrase.

### Service Options

The image runs all services available by default, but can be configured to run only certain services as needed. The option for configuring which services run is the `--enable` option.

The option takes a comma-separated list of service names to enable. To enable all services which is the default behavior, use:

```
--enable core,horizon
```

To run only specific services, simply specify only those services. For example, to enable the core, use:

```
--enable core
```

__Note: All services, and in addition friendbot, always run on a local network.__

### Faucet (Friendbot)

XDB CHAIN futurenet network use friendbot as a faucet for the native asset.

When running in local and futurenet modes friendbot is available on `:8000/friendbot` and can be used to fund a new account.

For example:
```
$ curl http://localhost:8000/friendbot?addr=G...
```

_Note: In local mode, a local friendbot is running. In futurenet mode, requests to the local `:8000/friendbot` endpoint will be proxied to the friendbot deployments for the respective network._

### Building Custom Images

To build a quickstart image with custom or specific versions of stellar-core,
horizon, etc, use the `Makefile`. You can specify the following parameters to 
customize the version of each component.

- `TAG`: The docker tag to assign to the build. Default `latest`.
- `CORE_VER`: The version of stellar-core to use.
- `HORIZON_REF`: The version of stellar-horizon to use.
- `FRIENDBOT_REF`: The git reference of stellar-friendbot to build.

For example:
```
make build \
  TAG=future \
  CORE_VER=... \
  HORIZON_VER=... \
  FRIENDBOT_REF=...
```

### Background vs. Interactive containers

Docker containers can be run interactively (using the `-it` flags) or in a detached, background state (using the `-d` flag).  Many of the example commands below use the `-it` flags to aid in debugging but in many cases you will simply want to run a node in the background.  It's recommended that you refer to [the tutorials at docker](https://docs.docker.com/engine/tutorials/usingdocker/) to familiarize yourself with using Docker.

### Ephemeral mode

Ephemeral mode is provided to support development and testing environments.  Every time you start a container in ephemeral mode, the database starts empty and a default configuration file will be used for the appropriate network.

Starting an ephemeral node is simple, just craft a `docker run` command to launch the appropriate image but *do not mount a volume*.  To craft your docker command, you need the network name you intend to run against.  Additionally, make sure to include the necessary flags to expose the desired ports. (Refer to the section named "Ports" below for guidance on exposing ports).  Thus, launching a futurenet node while exposing horizon would be:

```shell
$ docker run --rm -it -p "8000:8000" --name xdbchain ghcr.io/xdbfoundation/xdbchain-quickstart:latest --futurenet
```

As part of the launch process, an ephemeral mode container will generate a random password to secure the PostgreSQL service and output it to standard out. You may use this password (provided you have exposed the PostgreSQL port) to access the running PostgreSQL database (See the section "Accessing Databases" below).


### Persistent mode

In comparison to ephemeral mode, persistent mode is more complicated to operate but also more powerful. Persistent mode utilizes a mounted host volume, which is a directory on the host machine exposed to the running Docker container. This volume stores all database data as well as the configuration files used for running services. This setup enables you to manage and modify these files directly from the host system

It's important to note that the organization of files within the volume may not remain consistent between releases of the image, which occur with every commit to the xdbfoundation/xdbchain-quickstart repository. New files may be added, old files removed, or dependencies and references between them may change. Therefore, persistent mode is primarily intended for running short-lived test instances for development purposes. If consistency is required over any period of time, consider using image digest references to pin to a specific build

[image digest references]: https://docs.docker.com/engine/reference/run/#imagedigest

Starting a persistent mode container is the same as the ephemeral mode with one exception:

```shell
$ docker run --rm -it -p "8000:8000" -v "/home/scott/xdbchain:/opt/stellar" --name xdbchain ghcr.io/xdbfoundation/xdbchain-quickstart:latest --futurenet
```

The `-v` option in the example above tells docker to mount the host directory `/home/scott/xdbchain` into the container at the `/opt/stellar` path.  You may customize the host directory to any location you like, simply make sure to use the same value every time you launch the container.  Also note: an absolute directory path is required.  The second portion of the volume mount (`/opt/stellar`) should never be changed.  This special directory is checked by the container to see if it is mounted from the host system which is used to see if we should launch in ephemeral or persistent mode.

Upon launching a persistent mode container for the first time, the launch script will notice that the mounted volume is empty.  This will trigger an interactive initialization process to populate the initial configuration for the container.  This interactive initialization adds some complications to the setup process because in most cases you won't want to run the container interactively during normal operation, but rather in the background.  We recommend the following steps to setup a persistent mode node:

1.  Run an interactive session of the container at first, ensuring that all services start and run correctly.
2.  Shut down the interactive container (using Ctrl-C).
3.  Start a new container using the same host directory in the background.

## Regarding user accounts

Managing UIDs between a docker container and a host volume can be complicated.  At present, this image simply tries to create a UID that does not conflict with the host system by using a preset UID:  10011001.  Currently there is no way to customize this value.  All data produced in the host volume be owned by 10011001.  If this UID value is inappropriate for your infrastructure we recommend you fork this project and do a find/replace operation to change UIDs.  We may improve this story in the future if enough users request it.

## Ports

The image exposes one main port through which services provide their APIs:

| Port  | Service                         | Description          |
|-------|---------------------------------|----------------------|
| 8000  | horizon, friendbot              | main http port       |

The image also exposes a few other ports that most developers do not need, but area available:

| Port  | Service                         | Description          |
|-------|---------------------------------|----------------------|
| 5432  | postgresql                      | database access port |
| 6060  | horizon                         | admin port           |
| 11625 | stellar-core                    | peer node port       |
| 11626 | stellar-core                    | main http port       |
| 11725 | stellar-core (horizon)          | peer node port       |
| 11726 | stellar-core (horizon)          | main http port       |

### Security Considerations

Exposing the network ports used by your running container comes with potential risks.  While many attacks are preventable due to the nature of the XDB CHAIN network, it is extremely important that you maintain protected access to the postgresql server that runs within a quickstart container.  An attacker who gains write access to this DB will be able to corrupt your view of the XDB CHAIN network, potentially inserting fake transactions, accounts, etc.

It is safe to open the horizon http port.  Horizon is designed to listen on an internet-facing interface and provides no privileged operations on the port. At the same time admin port should only be exposed to a trusted network, as it provides no security itself.

The HTTP port for stellar-core should only be exposed to a trusted network, as it provides no security itself.  An attacker that can make requests to the port will be able to perform administrative commands such as forcing a catchup or changing the logging level and more, many of which could be used to disrupt operations or deny service.

The peer port for stellar-core however can be exposed, and ideally would be routable from the internet.  This would allow external peers to initiate connections to your node, improving connectivity of the overlay network.  However, this is not required as your container will also establish outgoing connections to peers.

## Accessing and debugging a running container

There will come a time when you want to inspect the running container, either to debug one of the services, review logs, or perform other administrative tasks. This can be done by starting a new interactive shell inside the running container:

```
$ docker exec -it xdbchain /bin/bash
```

The command above assumes that you launched your container with the name `xdbchain`. Replace that name with whatever you chose if different. When executed, it will open an interactive shell running as root within the container.

### Restarting services

Services within the quickstart container are managed using [supervisord](http://supervisord.org/index.html) and we recommend you use supervisor's shell to interact with running services.  To launch the supervisor shell, open an interactive shell to the container and then run `supervisorctl`.  You should then see a command prompt that looks like:

```shell
horizon                          RUNNING    pid 143, uptime 0:01:12
postgresql                       RUNNING    pid 126, uptime 0:01:13
stellar-core                     RUNNING    pid 125, uptime 0:01:13
supervisor>
```

From this prompt you can execute any of the supervisord commands:

```shell
# restart horizon
supervisor> restart horizon


# stop stellar-core
supervisor> stop stellar-core
```

You can learn more about what commands are available by using the `help` command.

### Viewing logs

Logs can be found within the container at the path `/var/log/supervisor/`.  A file is kept for both the stdout and stderr of the processes managed by supervisord.  Additionally, you can use the `tail` command provided by supervisorctl.

Alternatively, to tail all logs into the container's output for all services, append the `--logs` option.

### Accessing databases

The point of this project is to make running stellar's software within your own infrastructure easier, so that your software can more easily integrate with the XDB CHAIN network.  In many cases, you can interact with Horizon's REST API. However, there are times when direct access to the database provided by either Horizon or Stellar-core is necessary. This allows you to create custom SQL queries against the XDB CHAIN network data.

This image manages two PostgreSQL databases: `core` for Stellar-core's data and `horizon` for Horizon's data. When connecting with your PostgreSQL client or library, use the username stellar. The password to use depends on the container's mode: Persistent mode requires a password supplied by you, while ephemeral mode generates a password and prints it to the console upon container startup.
