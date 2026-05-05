# Templates

Collection of project templates, some are Nix Flake's based templates.

## 1. Listing Templates

1. Remotely

```bash
nix flake show github:Hugo0Vaz/templates

```

2. Locally

```bash
nix flake show ./<PATH_TO_FLAKE_DIR>

```

## 2. Using Flake Templates

1. Creating template in a existing dir.

```bash
mkdir new_proj && cd new_proj
nix flake init -t temaplates#<NAME_OF_TEMPLATE>

```

2. Creating template in a new dir.

```bash
nix flake new -t templates#<NAME_OF_TEMPLATE>
```
