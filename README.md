## SuperMigrate

## Deployments

### If you encounter this error:
Error: "./shell/deploy.base.sh: Permission denied"

Run this command:
```
chmod +x shell/deploy.*.sh
```

### Deploy
```
sh shell/deploy.sh --network=<NETWORK>
```

where <NETWORK> can be anything between ["base", "scroll", "mode", "op"]

### Help in deployment
```
sh shell/deploy.sh ---help
```