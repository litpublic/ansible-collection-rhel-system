# Baseline Role

Installs a minimal set of operational packages and configures the system timezone.

## Usage

```yaml
- hosts: all
  roles:
    - role: lit.rhel_system.baseline
      vars:
        packages_baseline:
          - vim
          - curl
        timezone: Europe/Berlin
```

## Variables

- `packages_baseline`: list of packages to ensure are installed (default: `["vim", "curl", "bash-completion", "util-linux-extra"]`)
- `timezone`: IANA timezone string configured via `community.general.timezone` (default: `Etc/UTC`)
