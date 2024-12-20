# Overview

Ever having issues with random bots/server scanners pinging your server?

Here is your solution! This script is a passive server scanner blocker (i.e. the longer you use it, the more IPs you will be blocking). It does not connect and poll an external source, so it's fully private!

How does it work? It reads your velocity logs when ran, and catches IPs pinging your server with different versions. If the version is not whitelisted (see below), then it will be added into an ipset blocklist to refuse traffic from that IP.

**Important:**

If you use docker, swap out all `INPUT` statements for `DOCKER-USER` instead.

Pterodactyl support NOT included.


**Follow this README guide closely to ensure things work!**

**Make sure to whitelist your own IP to prevent lockout! If your script does not include such option, UPDATE IT IMMEDIATELY!**

------------------------------------------------------

# Deployment:

This script has been tested on Ubuntu Server 22.04 LTS, with velocity proxy version 3.3.0-SNAPSHOT (git-2016d148-b436) 


**Cloning:**

```bash
git clone https://github.com/DominicTWHV/Anti_Server_Scanner.git
```

**Preparing Script:**

```bash
sudo apt install ipset iptables iptables-persistent -y
cd Anti_Server_Scanner
sudo chmod +x *.sh
```

Setting up a file to persist ipset rules:

```bash
sudo nano /etc/systemd/system/ipset-restore.service
```

Paste in the following:

```bash
[Unit]
Description=restore ipset rules
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/bin/bash -c '/sbin/ipset restore < /etc/ipset.rules'
Type=oneshot

[Install]
WantedBy=multi-user.target
```

Save and exit, then run:

```bash
sudo systemctl daemon-reload
sudo systemctl enable ipset-restore.service
sudo systemctl enable netfilter-persistent
sudo systemctl start ipset-restore.service
sudo systemctl start netfilter-persistent

sudo systemctl status ipset-restore.service
sudo systemctl status netfilter-persistent
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
```
Use the above if you want to check the logs and block every once per 3 hours.

------------------------------------------------------

Feel free to reboot and test if entries persist after a reboot. They should if you have configured everything correctly.

# Notes:

Please be aware that this script has only been tested with velocity. If you do not use a proxy, logs such as `[17:29:08] [Netty epoll Worker #1/INFO] [com.velocitypowered.proxy.connection.client.StatusSessionHandler]: [initial connection] /[REDACTED]:57224 is pinging the server with version Unknown` will not show up, rendering everything useless.

If you use this for a public server, it's recommended to whitelist all versions except for 1.8/1.9 (unless needed) to prevent false positives and blacklisting your players. Keeping checks for "Unknown" and "Legacy" versions is still recommended, as regular players should not be identified under such categories.
