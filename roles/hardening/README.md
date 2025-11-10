# Hardening Role

Applies opinionated SSH hardening defaults and restarts the daemon when required.

## Usage

```yaml
- hosts: all
  roles:
    - role: lit.rhel_system.hardening
      vars:
        sshd_hardening:
          PermitRootLogin: "no"
          PasswordAuthentication: "no"
        hardening_sshd_service_name: sshd
```

## Variables

- `sshd_hardening`: key/value pairs enforced in `/etc/ssh/sshd_config` (default disables root and password logins)
- `hardening_sshd_service_name`: service name used for handler restarts (default: `sshd`, remapped to `ssh` on Debian)
