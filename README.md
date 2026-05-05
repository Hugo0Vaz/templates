# Templates

Collection of project templates, some are Nix Flake's based templates.

## Using Flake Templates

1. Listing templates remotely.

```bash
nix flake show github:Hugo0Vaz/templates

```

2. Listing templates locally.

```bash
nix flake show ./<PATH_TO_FLAKE_DIR>

```

3. Creating template in a existing dir.

```bash
mkdir new_proj && cd new_proj
nix flake init -t github:Hugo0Vaz/templates#<NAME_OF_TEMPLATE>

```

4. Creating template in a new dir.

```bash
nix flake new -t github:Hugo0Vaz/templates#<NAME_OF_TEMPLATE>
```
