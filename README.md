# Overview

Ever having issues with random bots/server scanners pinging your server?

Here is your solution! This script is a passive server scanner blocker (i.e. the longer you use it, the more IPs you will be blocking)

How does it work? It reads your velocity logs when ran, and catches IPs pinging your server with different versions. If the version is not whitelisted (see below), then it will be added into an ipset blocklist to refuse traffic from that IP.

**Important:**

If you use docker, swap out all `INPUT` statements for `DOCKER-USER` instead.

Pterodactyl support NOT included.

------------------------------------------------------

# Deployment:

This script has been tested on Ubuntu Server 22.04 LTS, with velocity proxy version 3.3.0-SNAPSHOT (git-52ae735e-b425)


**Cloning:**

```bash
git clone https://github.com/DominicTWHV/Anti_Server_Scanner.git
```

**Preparing Script:**

```bash
sudo apt install ipset -y
cd Anti_Server_Scanner
sudo chmod +x *.sh
```

Setting up a script to persist ipset rules:

```bash
sudo nano /etc/network/if-pre-up.d/ipset-restore
```

Paste in the following:

```bash
#!/bin/bash
if [ -e /etc/ipset.rules ]; then
    /sbin/ipset restore < /etc/ipset.rules
fi
```

Save and exit, then run:

```bash
sudo chmod +x /etc/network/if-pre-up.d/ipset-restore
sudo ipset save | sudo tee /etc/ipset.rules > /dev/null
```

You may see your ipset entries with:

```bash
sudo ipset list blacklist
```

**Setting Up:**

Use a text editor like nano to view `main.sh`, you should see a couple of config options inside, configure those to your needs.

```bash
nano main.sh
```

or 

```bash
vim main.sh
```

**Running:**

You may use

```bash
sudo ./main.sh
```

_iptables requires root permissions_

to run it once, or feel free to install this into a crontab job to run periodically.


------------------------------------------------------


# Manual Blocking:

If you have set the function to block with iptables to false (create txt file instead), you may run `sudo ./block.sh` manually, enter the path of the file that `main.sh` created, and block those manually.


------------------------------------------------------


# Crontab Job Example:


Note: you MUST use the sudo crontab, not user specific crontab for the following.

```bash
0 */3 * * * /home/ubuntu/Anti_Server_Scanner/main.sh
@reboot /sbin/ipset restore < /etc/ipset.rules
```
Use the above if you want to check the logs and block every once per 3 hours.

**The 2nd entry is needed for your ipset rules to persist after reboot.**

------------------------------------------------------


# Notes:

Please be aware that this script has only been tested with velocity. If you do not use a proxy, logs such as `[17:29:08] [Netty epoll Worker #1/INFO] [com.velocitypowered.proxy.connection.client.StatusSessionHandler]: [initial connection] /[REDACTED]:57224 is pinging the server with version Unknown` will not show up, rendering everything useless.
