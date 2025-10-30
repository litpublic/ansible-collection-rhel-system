# Firewall Role

Installs and manages `firewalld`, optionally enabling selected services or ports.

## Usage

```yaml
- hosts: all
  roles:
    - role: litpublic.rhel_system.firewall
      vars:
        firewalld_manage_service: true
        services_enable:
          - ssh
        ports_enable:
          - 8080/tcp
```

## Variables

- `firewalld_manage_service`: toggles whether the role starts/enables the service (default: `true`)
- `services_enable`: list of service names to allow via `ansible.posix.firewalld` (default: `["ssh"]`)
- `ports_enable`: list of `<port>/<proto>` entries to open (default: `[]`)
