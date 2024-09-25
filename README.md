# Anti Server Scanner for Velocity Proxy

Ever having issues with random bots/server scanners pinging your server?

**Here is your solution!**

------------------------------------------------------

# Deployment:

This script has been tested on Ubuntu Server 22.04 LTS, with velocity proxy version 3.3.0-SNAPSHOT (git-52ae735e-b425)


**Cloning:**

```bash
git clone https://github.com/DominicTWHV/Anti_Server_Scanner.git
```

**Preparing Script:**

```bash
cd Anti_Server_Scanner
sudo chmod +x main.sh
```

**Setting Up:**

Use a text editor like nano to view `main.sh`, you should see a couple of config options inside, configure those to your needs.

```bash
nano main.sh
```

**Running:**

You may use

```bash
sudo ./main.sh
```

_iptables requires root permissions_

to run it once, or feel free to install this into a crontab job to run periodically.

# Notes:

Please be aware that this script has only been tested with velocity. If you do not use a proxy, logs such as `[17:29:08] [Netty epoll Worker #1/INFO] [com.velocitypowered.proxy.connection.client.StatusSessionHandler]: [initial connection] /[REDACTED]:57224 is pinging the server with version Unknown` will not show up, rendering everything useless.
