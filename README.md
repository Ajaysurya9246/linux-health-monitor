# Linux Server Health Monitor with Email Alerts

A Bash script that monitors CPU, memory, and disk usage on a Linux server and
sends a Gmail email alert via SMTP (msmtp) whenever a defined threshold is
breached.

## Why this project

Most beginner monitoring scripts just print warnings to the terminal. This one
actually **notifies you** — useful when you're not logged into the server
24/7. It also documents real debugging issues hit along the way, since
production troubleshooting rarely goes perfectly on the first try.

## What it checks

| Metric | Threshold | Command used |
|---|---|---|
| CPU usage | > 80% | `vmstat` |
| Memory usage | > 1024 MB | `free -m` |
| Disk usage | > 80% | `df -h` |

## Setup

### 1. Install required tools
```bash
sudo dnf install mailx msmtp -y
```

### 2. Configure msmtp (`~/.msmtprc`)
```
defaults
auth on
tls on
tls_starttls on
tls_certcheck off

account gmail
host smtp.gmail.com
port 587
from your_email@gmail.com
user your_email@gmail.com
password your_16_char_app_password

account default : gmail
```

Generate the App Password from **Google Account → Security → App Passwords**
(Gmail no longer accepts your normal account password for third-party tools).

### 3. Secure the config file
```bash
chmod 600 ~/.msmtprc
```
This file contains your Gmail App Password in plain text — restrict it to
owner-only access.

### 4. Run it
```bash
chmod +x healthcheck.sh
./healthcheck.sh
```

**Important:** run it as the user that owns `~/.msmtprc`, **without `sudo`**.
Running with `sudo` switches the script to the `root` user, which looks for
`/root/.msmtprc` instead — and fails with `account gmail not found`.

### 5. (Optional) Automate with cron
```bash
crontab -e
```
```
*/5 * * * * /home/<user>/health_check/healthcheck.sh
```
Use the regular user's crontab (`crontab -e`), **not** `sudo crontab -e`, for
the same reason as above.

## Real issues hit while building this

**1. `mail -s` delivered to local mailbox, not Gmail**
The `mail`/`mailx` command defaults to the local MTA. Messages showed up in
`/var/spool/mail/<user>` instead of reaching Gmail. Fixed by piping directly
into `msmtp` instead.

**2. `awk 'NR==3'` returned empty output**
```bash
# Didn't work:
vmstat 1 2 | tail -1 | awk 'NR==3 {print 100-$15}'

# Fixed:
vmstat 1 2 | tail -1 | awk '{print 100-$15}'
```
`tail -1` had already reduced the input to a single line, so inside `awk`
that line is always `NR==1` — never `NR==3`. Each stage of a pipe only sees
the previous stage's output.

**3. Email variable name mismatch**
```bash
# Bug:
mail="your_email@gmail.com"
...
msmtp -a gmail "$EMAIL"   # $EMAIL was never set — empty recipient

# Fixed:
EMAIL="your_email@gmail.com"
...
msmtp -a gmail "$EMAIL"
```
Bash variable names are case-sensitive. `mail` and `EMAIL` are two different
variables.

**4. `sudo ./healthcheck.sh` failed with "account gmail not found"**
Running with `sudo` executes the script as `root`, which has its own (empty)
home directory and no `~/.msmtprc`. Solution: run without `sudo`, as the
user that owns the msmtp config.

**5. Email arrived with no content**
The first version piped plain text directly into `msmtp` with no `Subject:`
header or blank-line separator, so Gmail couldn't parse it. Fixed with:
```bash
echo -e "Subject: CPU Alert\n\nWarning: CPU usage is above 80%." | msmtp -a gmail "$EMAIL"
```

## Possible extensions

- Add a CPU/memory/disk threshold config file instead of hardcoded values
- Use checksums to verify metric accuracy across multiple readings
- Push alerts to Slack/Discord webhook as an alternative channel
- Wrap this into an Ansible role to deploy across multiple servers at once
