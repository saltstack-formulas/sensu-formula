sensu-formula
================

A saltstack formula to install and configure the open source monitoring framework, [Sensu](http://sensuapp.org/).

>Note:
See the full [Salt Formulas installation and usage instructions](http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html). This formula only manages Sensu. You are responsible for installing/configuring RabbitMQ and Redis as appropriate.

Sensu can be configured/scaled with the individual states installed on multiple servers. All states are configured via the pillar file. Sane defaults are set in pillar_map.jinja and can be over-written in the pillar. The `sensu.client` state currently supports Ubuntu, CentOS and Windows. The `sensu.server`, `sensu.api` and `sensu.uchiwa` states currently support Ubuntu and CentOS.

Thank you to the SaltStack community for the continued improvement of this formula!

Available states
================
* [sensu](#sensu)
* [sensu.server](#sensuserver)
* [sensu.client](#sensuclient)
* [sensu.api](#sensuapi)
* [sensu.uchiwa](#sensuuchiwa)

Example top.sls:
```
base:
    '*':
        - sensu.client

    'sensu-server-*':
        - sensu.server

    'sensu-api-*':
        - sensu.api

    'uchiwa-*':
        - sensu.uchiwa
```

`paths`: The `source` path for the handlers/plugins/extentions/etc are configurable in the pillar if you would like to keep these items in a different location. Please note, this directory must be located on the salt master file server and will be prepended with the `salt://` protocol by the formula. If the directory is located on the master in the directory named spam, and is called eggs, the source string is `spam/eggs` and will be converted to `salt://spam/eggs`.

Backward incompatible changes
=============================

**2015-04-15:** The default ``sensu:rabbitmq:port`` value is now 5672 (which is the default port of RabbitMQ) instead of 5671. Port 5671 was used to support SSL/TLS as you cannot configure TLS on port 5672.
* If you happened to have used the default previous value of 5671, you should now set it in your pillar file or change your RabbitMQ configuration.
* If you overrode the previous default value of 5671 with 5672, you can now safely remove it.
* If you set up something else instead, you don't have to change anything :)

**2016-01-08:** The pillar structure for `sensu.uchiwa` has been slightly modified to make it more closely resemble the rendered json and to support multiple users. Please confirm your existing pillar.

``sensu``
------------

Adds the Sensu repository, and installs the Sensu package.

``sensu.server``
------------

Configures sensu-server and starts the service.

Requires minimum rabbitmq configuration.
```
sensu:
  rabbitmq:
    host: RABBITMQ_HOST_IP (Do not use localhost as the clients also use this.)
    user: RABBITMQ_USERNAME
    password: RABBITMQ_USER_PASSWORD
```

If you use SSL, you must enable it and provide the certs. See the [sensu documentation.](http://sensuapp.org/docs/latest/certificates)

Custom check definitions/extentions/mutators/handlers/plugins can be deployed to all Sensu servers by placing the scripts into the corresponding directory in ./sensu/files/.

The included check-procs.rb comes from the [sensu-community-plugins](https://github.com/sensu/sensu-community-plugins) as an example only. There is no guarantee that it up-to-date and it should not be used.

If you are not running your redis server locally, set the following in the pillar:
```
sensu:
  redis:
    host: HOSTNAME
    port: PORT
    password: PASSWORD # Optional
```

If you are adding handlers which have additional gem dependencies, i.e the [mailer](https://github.com/sensu/sensu-community-plugins/blob/master/handlers/notification/mailer.rb) handler. You can add them to the pillar data and they will be installed on your Sensu servers.
```
sensu:
  server:
    install_gems:
      - mail
      - timeout
```

``sensu.client``
------------

Configures sensu-client and starts the service.

Check scripts can be deployed to all clients by placing them into ./sensu/files/plugins.

You can use the embedded ruby or installing nagios plugins by setting:
```
sensu:
  client:
    embedded_ruby: true
    nagios_plugins: true
```

To subscribe your clients to the appropriate checks, you can update the `sensu` pillar with the required subscriptions.  You can also override the client address to another interface or change the name of the client.  In addition, you can also enable Sensu's safe mode (highly recommended, off by default).

```
sensu:
  client:
    name: {{ grains['sensu_id'] }}
    address: {{ grains['ip4_interfaces']['eth0'][0] }}
    subscriptions: ['linux', 'compute']
```

If you would like to use [command tokens](https://sensuapp.org/docs/latest/checks#example-check-command-tokens) in your checks you can add a section under client as shown here:

```
sensu:
  client:
    command_tokens:
      disk:
        warning: 97
        critical: 99
```

If you would like to use the [redact](https://sensuapp.org/docs/latest/clients) feature in your checks you can add a section under client as shown here:

```
sensu:
  client:
    redact:
      - password
```

This will redact any command token value who's key is defined as "password" from check configurations and logs. Command token substitution should be used in check configurations when redacting sensitive information such as passwords.

If you are adding plugins/checks which have additional gem dependencies. You can add them to the pillar data and they will be installed on your Sensu clients.
```
sensu:
  client:
    install_gems:
      - libxml-xmlrpc
```


``sensu.api``
------------

Configures sensu-api and starts the service.



``sensu.uchiwa``
------------
>Note: The Uchiwa pillar structure has changed! If you have previously used this state and are potentially upgrading, please take a minute to review.

Configures [uchiwa](http://docs.uchiwa.io/en/latest/) and starts the service. The pillar defaults are located in the ```pillar_map.jinja```.

The state now supports [multiple users with simple authentication](http://docs.uchiwa.io/en/latest/configuration/uchiwa/#multiple-users-with-simple-authentication). If you are upgrading from a previous version of this state, you will need make some minor modifications to your pillar.

**Site and user definitions**
``` yaml
# new style users and sites
sensu:
    uchiwa:
        users:
            - username: bobby
              password: secret
              role: { readonly: False }
    sites:
        - name: 'Site 1'
          host: '1.1.1.1'
          user: 'bobby'
          pass: secret
        - name: 'Site 2'
          host: localhost
          user: nicky
          pass: secret
          ssl: True
```
