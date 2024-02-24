
# alias jellystart='echo "lets get started"; sudo virsh start --domain jellyfin'
# alias jellyps='ssh jelly "docker-compose -f ~/Documents/docker-media-server/docker-compose.yml ps && echo "DISK SIZE" && df -hT /dev/vda1"'
# alias jellytree='ssh jelly "tree ~/Documents/content/content"'
# alias jellydocker='ssh jelly "docker-compose -f ~/Documents/docker-media-server/docker-compose.yml $@"'
# alias jstart='jellystart; sleep 90; jellyps; jellydocker start traefik'
# alias fixjelly='sudo rmdir /var/lib/libvirt/images && sudo ln -s /data/libvirt/images /var/lib/libvirt/'

abbr jellystart 'echo "lets get started"; sudo virsh start --domain jellyfin'
abbr jellyps 'ssh jelly "docker-compose -f ~/Documents/docker-media-server/docker-compose.yml ps && echo "DISK SIZE" && df -hT /dev/vda1"'
abbr jellytree 'ssh jelly "tree ~/Documents/content/content"'
abbr jellydocker 'ssh jelly "docker-compose -f ~/Documents/docker-media-server/docker-compose.yml $@"'
abbr jstart 'echo "lets get started"; sudo virsh start --domain jellyfin; sleep 90; jellyps; jellydocker start traefik'
# abbr fixjelly 'sudo rmdir /var/lib/libvirt/images && sudo ln -s /data/libvirt/images /var/lib/libvirt/'"' 
