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
cat <<EOF > /etc/yum.repos.d/mongodb-org-4.2.repo
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

The application needs the following configuration values in order to run. These can either be exported into your environment or directly set in `config/application.yaml`.

```
# Either set them into the environment
export jwt_shared_secret=<keep-this-secret-safe>

# Or hard code them in the config file:
vim config/application.yaml
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

### Setting Up Systemd

A basic `systemd` unit file can be found [here](support/nodeattr-server.service). The unit file will need to be tweaked according to where the application has been installed/configured. The unit needs to be stored within `/etc/systemd/system`.

## Starting the Server

The `puma` server daemon can be started manually with:

```
bin/puma -p <port> -e production -d
```

## Stopping the Server

The `puma` server daemon can be stopped manually by sending an interrupt:

```
kill -s SIGINT <puma-pid>
```

## Authentication

The API requires all requests to carry with a [jwt](https://jwt.io). Within the token either `user: true` or `admin: true` needs to be set. This will authenticate with either `user` or `admin` privileges respectively. Admins have full access to the API where users can only make `GET` requests.

The following `rake` tasks are used to generate tokens with 30 days expiry. Tokens from other sources will be accepted as long as they:
1. Where signed with the same shared secret,
3. An [expiry claim](https://tools.ietf.org/html/rfc7519#section-4.1.4) has been made.

As the shared secret is environment dependant, the `RACK_ENV` must be set within your environment.

```
# Set the rack environment
export RACK_ENV=production

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
