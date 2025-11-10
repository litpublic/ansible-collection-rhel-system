# Podman Role

Installs Podman tooling and prepares the container configuration directory.

## Usage

```yaml
- hosts: all
  roles:
    - role: lit.rhel_system.podman
      vars:
        packages:
          - podman
          - buildah
        registries_conf_dir: /etc/containers
```

## Variables

- `packages`: package list installed via `ansible.builtin.package` (default: `["podman", "buildah"]`)
- `registries_conf_dir`: directory ensured present for registry configuration files (default: `/etc/containers`)
