[![Build Status](https://travis-ci.org/openflighthpc/nodeattr-server.svg?branch=master)](https://travis-ci.org/openflighthpc/nodeattr-server)

# Nodeattr Server

Shared micro-service for storing data about about clusters/groups/nodes

## Overview


## Installation

### Preconditions

The following are required to run this application:

* OS:           Centos7
* Ruby:         2.6+
* Yum Packages: gcc
* [Mongodb](https://docs.mongodb.com/manual/installation/)

### Manual installation

Start by cloning the repo, adding the binaries to your path, and install the gems. This guide assumes the `bin` directory is on your `PATH`. If you prefer not to modify your `PATH`, then some of the commands need to be prefixed with `/path/to/app/bin`.

```
git clone https://github.com/openflighthpc/nodeattr-server
cd nodeattr-server

# Add the binaries to your path, which will be used by the remainder of this guide
export PATH=$PATH:$(pwd)/bin
bundle install --without development test --path vendor

# The following command can be ran without modifying the PATH variable by
# prefixing `bin/` to the commands
bin/bundle install --without development test --path vendor
```

The application connects to a `mongodb` server running on localhost by default. [Refer here how to install mongodb](https://docs.mongodb.com/manual/installation/). In short, to install `mongodb` on "redhat" linux:

```
cat <<'EOF' > /etc/yum.repos.d/mongodb-org-4.2.repo
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.2/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.2.asc
EOF

sudo yum install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod
```

### Configuration

The only configuration value required by the server directly is the `jwt_shared_secret`. This must be exported into the environment.

```
export jwt_shared_secret=<keep-this-secret-safe>
```

It is assumed that the `mongodb` server is running on the default port: `localhost:27017`. Refer to the `mongoid` [configuration documentation](https://docs.mongodb.com/mongoid/current/tutorials/mongoid-configuration) to configure the application with a different server. The config should be stored as `config/mongoid.yml`.

### Adding the Indexes to MongoDB

As mongo is nosql database, the indexing is not strictly necessary. Instead it will provide performance enhancements and adds a data integrity checks at the `db` level in addition to `application` logic.

```
# Add the indexes
rake db:mongoid:create_indexes

# Remove the indexes
rake db:mongoid:remove_indexes
```

### Integrating with OpenFlightHPC/FlightRunway

The [provided systemd unit file](support/nodeattr-server.service) has been designed to integrate with the `OpenFlightHPC` [flight-runway](https://github.com/openflighthpc/flight-runway) package. The following preconditions must be satisfied for the unit file to work:
1. `OpenFlightHPC` `flight-runway` must be installed,
2. The server must be installed within `/otp/flight/opt/nodeattr-server`,
3. The log directory must exist: `/opt/flight/log`, and
4. The configuration file must exist: `/opt/flight/etc/nodeattr-server.conf`.

The configuration file will be loaded into the environment by `systemd` and can be used to override values within `config/application.yaml`. This is the recommended way to set the custom configuration values and provides the following benefits:
1. The config will be preserved on update,
2. It keeps the secret keys separate from the code base, and
3. It eliminates the need to source a `bashrc` in order to setup the environment.

## Starting the Server

The `puma` server daemon can be started manually with:

```
bin/puma -p <port> -e production -d \
          --redirect-append \
          --redirect-stdout <stdout-log-file-path> \
          --redirect-stderr <stderr-log-file-path>
```

## Stopping the Server

The `pumactl` command can be used to preform various start/stop/restart actions. Assuming that `systemd` hasn't been setup, the following will stop the server:

```
bin/pumactl stop
```

## Authentication

The API requires all requests to carry with a [jwt](https://jwt.io). Admin tokens must set the `admin` flag to `true` within their body. All other valid tokens are assumed to have `user` level privileges. Admins have full `read`/`write` access, where a `user` only has `read` access.

The following `rake` tasks are used to generate tokens with 30 days expiry. Tokens from other sources will be accepted as long as they:
1. Where signed with the same shared secret,
3. An [expiry claim](https://tools.ietf.org/html/rfc7519#section-4.1.4) has been made.

As the shared secret is environment dependant, the `RACK_ENV` must be set within your environment.

```
# Set the rack environment
export RACK_ENV=production

# Generate a user token
rake token:admin

# Generate a user token
rake token:user
```

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Creative Commons Attribution-ShareAlike 4.0 License, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2019-present Alces Flight Ltd.

You should have received a copy of the license along with this work.
If not, see <http://creativecommons.org/licenses/by-sa/4.0/>.

![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

Nodeattr Server is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).

Based on a work at [https://github.com/openflighthpc/openflight-tools](https://github.com/openflighthpc/openflight-tools).

This content and the accompanying materials are made available available
under the terms of the Creative Commons Attribution-ShareAlike 4.0
International License which is available at [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

Nodeattr Server is distributed in the hope that it will be useful, but
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS OF
TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A PARTICULAR
PURPOSE. See the [Creative Commons Attribution-ShareAlike 4.0
International License](https://creativecommons.org/licenses/by-sa/4.0/) for more
details.
