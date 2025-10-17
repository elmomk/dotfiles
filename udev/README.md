```bash
[root@] udevadm control --reload-rules
```

```bash
cd ./usr/local/
stow --target=/usr/local bin 
stow --target=/usr/local lib
cd ./etc/udev/rules.d/
# symlink
```
