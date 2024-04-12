---
title:  "Error when connecting Kamailio to a RabbitMQ server"
description: Now that's weird!
date:   2024-04-12
tags: [tech]
---

I've spent yesterday with a RabbitMQ server and its connection to Kamailio's [rabbitmq module](https://www.kamailio.org/docs/modules/devel/modules/rabbitmq.html).
During the connection initialisation, one issue came up regarding the `max_channel` configuration. Kamailio or rather [the `rabbitmq-c` library](https://github.com/alanxz/rabbitmq-c) will ask for the server defaults and negotiate against whatever the library client has configured.

Now, the Kamailio module _always_ [sets the parameter to `0`](https://github.com/kamailio/kamailio/blob/8bc64a9e6820243336387d9cd9acf81f24d89993/src/modules/rabbitmq/rabbitmq.c#L623C39-L623C41) which is apparently used as a signal for "no limit". If the server also sends `0` / "no limit", the [library defaults](https://github.com/alanxz/rabbitmq-c/blob/bc1a30176b49b14f19db6f3526cee322047f5f27/librabbitmq/amqp_socket.c#L1374) to `max_channels = UINT16_MAX`.

But here's where the issue comes in: [A few years ago](https://github.com/rabbitmq/rabbitmq-server/issues/1593), rabbitmq-server set the maximum number of channels per connections to default to 2047. And this leads to the rather confusing log message on the mq-server:

> failed to negotiate connection parameters: negotiated channel_max = 0 (no limit) is higher than the maximum allowed value (2047)

And how do we fix this? Since there is no easy way to reconfigure the Kamailio module code without recompiling Kamailio itself (maybe there is, I'm not sure!), it necessary to change the `channel_max` configuration in RabbitMQ, or at least set it:

```
channel_max = 2047
```
