# Copyright 2019 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This file was edited by Simon Johansson on 2019-10-13.

abbr -a -g k kubectl
abbr -a -g ksys kubectl --namespace=kube-system
abbr -a -g ka kubectl apply --recursive -f
abbr -a -g ksysa kubectl --namespace=kube-system apply --recursive -f
abbr -a -g kex kubectl exec -i -t
abbr -a -g ksysex kubectl --namespace=kube-system exec -i -t
abbr -a -g klo kubectl logs -f
abbr -a -g ksyslo kubectl --namespace=kube-system logs -f
abbr -a -g klop kubectl logs -f -p
abbr -a -g ksyslop kubectl --namespace=kube-system logs -f -p
abbr -a -g kp kubectl proxy
abbr -a -g kpf kubectl port-forward
abbr -a -g kg kubectl get
abbr -a -g ksysg kubectl --namespace=kube-system get
abbr -a -g kd kubectl describe
abbr -a -g ksysd kubectl --namespace=kube-system describe
abbr -a -g krm kubectl delete
abbr -a -g ksysrm kubectl --namespace=kube-system delete
abbr -a -g krun kubectl run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
abbr -a -g ksysrun kubectl --namespace=kube-system run --rm --restart=Never --image-pull-policy=IfNotPresent -i -t
abbr -a -g kgpo kubectl get pods
abbr -a -g ksysgpo kubectl --namespace=kube-system get pods
abbr -a -g kdpo kubectl describe pods
abbr -a -g ksysdpo kubectl --namespace=kube-system describe pods
abbr -a -g krmpo kubectl delete pods
abbr -a -g ksysrmpo kubectl --namespace=kube-system delete pods
abbr -a -g kgdep kubectl get deployment
abbr -a -g ksysgdep kubectl --namespace=kube-system get deployment
abbr -a -g kddep kubectl describe deployment
abbr -a -g ksysddep kubectl --namespace=kube-system describe deployment
abbr -a -g krmdep kubectl delete deployment
abbr -a -g ksysrmdep kubectl --namespace=kube-system delete deployment
abbr -a -g kgsvc kubectl get service
abbr -a -g ksysgsvc kubectl --namespace=kube-system get service
abbr -a -g kdsvc kubectl describe service
abbr -a -g ksysdsvc kubectl --namespace=kube-system describe service
abbr -a -g krmsvc kubectl delete service
abbr -a -g ksysrmsvc kubectl --namespace=kube-system delete service
abbr -a -g kging kubectl get ingress
abbr -a -g ksysging kubectl --namespace=kube-system get ingress
abbr -a -g kding kubectl describe ingress
abbr -a -g ksysding kubectl --namespace=kube-system describe ingress
abbr -a -g krming kubectl delete ingress
abbr -a -g ksysrming kubectl --namespace=kube-system delete ingress
abbr -a -g kgcm kubectl get configmap
abbr -a -g ksysgcm kubectl --namespace=kube-system get configmap
abbr -a -g kdcm kubectl describe configmap
abbr -a -g ksysdcm kubectl --namespace=kube-system describe configmap
abbr -a -g krmcm kubectl delete configmap
abbr -a -g ksysrmcm kubectl --namespace=kube-system delete configmap
abbr -a -g kgsec kubectl get secret
abbr -a -g ksysgsec kubectl --namespace=kube-system get secret
abbr -a -g kdsec kubectl describe secret
abbr -a -g ksysdsec kubectl --namespace=kube-system describe secret
abbr -a -g krmsec kubectl delete secret
abbr -a -g ksysrmsec kubectl --namespace=kube-system delete secret
abbr -a -g kgno kubectl get nodes
abbr -a -g kdno kubectl describe nodes
abbr -a -g kgns kubectl get namespaces
abbr -a -g kdns kubectl describe namespaces
abbr -a -g krmns kubectl delete namespaces
abbr -a -g kgoyaml kubectl get -o=yaml
abbr -a -g ksysgoyaml kubectl --namespace=kube-system get -o=yaml
abbr -a -g kgpooyaml kubectl get pods -o=yaml
abbr -a -g ksysgpooyaml kubectl --namespace=kube-system get pods -o=yaml
abbr -a -g kgdepoyaml kubectl get deployment -o=yaml
abbr -a -g ksysgdepoyaml kubectl --namespace=kube-system get deployment -o=yaml
abbr -a -g kgsvcoyaml kubectl get service -o=yaml
abbr -a -g ksysgsvcoyaml kubectl --namespace=kube-system get service -o=yaml
abbr -a -g kgingoyaml kubectl get ingress -o=yaml
abbr -a -g ksysgingoyaml kubectl --namespace=kube-system get ingress -o=yaml
abbr -a -g kgcmoyaml kubectl get configmap -o=yaml
abbr -a -g ksysgcmoyaml kubectl --namespace=kube-system get configmap -o=yaml
abbr -a -g kgsecoyaml kubectl get secret -o=yaml
abbr -a -g ksysgsecoyaml kubectl --namespace=kube-system get secret -o=yaml
abbr -a -g kgnooyaml kubectl get nodes -o=yaml
abbr -a -g kgnsoyaml kubectl get namespaces -o=yaml
abbr -a -g kgowide kubectl get -o=wide
abbr -a -g ksysgowide kubectl --namespace=kube-system get -o=wide
abbr -a -g kgpoowide kubectl get pods -o=wide
abbr -a -g ksysgpoowide kubectl --namespace=kube-system get pods -o=wide
abbr -a -g kgdepowide kubectl get deployment -o=wide
abbr -a -g ksysgdepowide kubectl --namespace=kube-system get deployment -o=wide
abbr -a -g kgsvcowide kubectl get service -o=wide
abbr -a -g ksysgsvcowide kubectl --namespace=kube-system get service -o=wide
abbr -a -g kgingowide kubectl get ingress -o=wide
abbr -a -g ksysgingowide kubectl --namespace=kube-system get ingress -o=wide
abbr -a -g kgcmowide kubectl get configmap -o=wide
abbr -a -g ksysgcmowide kubectl --namespace=kube-system get configmap -o=wide
abbr -a -g kgsecowide kubectl get secret -o=wide
abbr -a -g ksysgsecowide kubectl --namespace=kube-system get secret -o=wide
abbr -a -g kgnoowide kubectl get nodes -o=wide
abbr -a -g kgnsowide kubectl get namespaces -o=wide
abbr -a -g kgojson kubectl get -o=json
abbr -a -g ksysgojson kubectl --namespace=kube-system get -o=json
abbr -a -g kgpoojson kubectl get pods -o=json
abbr -a -g ksysgpoojson kubectl --namespace=kube-system get pods -o=json
abbr -a -g kgdepojson kubectl get deployment -o=json
abbr -a -g ksysgdepojson kubectl --namespace=kube-system get deployment -o=json
abbr -a -g kgsvcojson kubectl get service -o=json
abbr -a -g ksysgsvcojson kubectl --namespace=kube-system get service -o=json
abbr -a -g kgingojson kubectl get ingress -o=json
abbr -a -g ksysgingojson kubectl --namespace=kube-system get ingress -o=json
abbr -a -g kgcmojson kubectl get configmap -o=json
abbr -a -g ksysgcmojson kubectl --namespace=kube-system get configmap -o=json
abbr -a -g kgsecojson kubectl get secret -o=json
abbr -a -g ksysgsecojson kubectl --namespace=kube-system get secret -o=json
abbr -a -g kgnoojson kubectl get nodes -o=json
abbr -a -g kgnsojson kubectl get namespaces -o=json
abbr -a -g kgall kubectl get --all-namespaces
abbr -a -g kdall kubectl describe --all-namespaces
abbr -a -g kgpoall kubectl get pods --all-namespaces
abbr -a -g kdpoall kubectl describe pods --all-namespaces
abbr -a -g kgdepall kubectl get deployment --all-namespaces
abbr -a -g kddepall kubectl describe deployment --all-namespaces
abbr -a -g kgsvcall kubectl get service --all-namespaces
abbr -a -g kdsvcall kubectl describe service --all-namespaces
abbr -a -g kgingall kubectl get ingress --all-namespaces
abbr -a -g kdingall kubectl describe ingress --all-namespaces
abbr -a -g kgcmall kubectl get configmap --all-namespaces
abbr -a -g kdcmall kubectl describe configmap --all-namespaces
abbr -a -g kgsecall kubectl get secret --all-namespaces
abbr -a -g kdsecall kubectl describe secret --all-namespaces
abbr -a -g kgnsall kubectl get namespaces --all-namespaces
abbr -a -g kdnsall kubectl describe namespaces --all-namespaces
abbr -a -g kgsl kubectl get --show-labels
abbr -a -g ksysgsl kubectl --namespace=kube-system get --show-labels
abbr -a -g kgposl kubectl get pods --show-labels
abbr -a -g ksysgposl kubectl --namespace=kube-system get pods --show-labels
abbr -a -g kgdepsl kubectl get deployment --show-labels
abbr -a -g ksysgdepsl kubectl --namespace=kube-system get deployment --show-labels
abbr -a -g krmall kubectl delete --all
abbr -a -g ksysrmall kubectl --namespace=kube-system delete --all
abbr -a -g krmpoall kubectl delete pods --all
abbr -a -g ksysrmpoall kubectl --namespace=kube-system delete pods --all
abbr -a -g krmdepall kubectl delete deployment --all
abbr -a -g ksysrmdepall kubectl --namespace=kube-system delete deployment --all
abbr -a -g krmsvcall kubectl delete service --all
abbr -a -g ksysrmsvcall kubectl --namespace=kube-system delete service --all
abbr -a -g krmingall kubectl delete ingress --all
abbr -a -g ksysrmingall kubectl --namespace=kube-system delete ingress --all
abbr -a -g krmcmall kubectl delete configmap --all
abbr -a -g ksysrmcmall kubectl --namespace=kube-system delete configmap --all
abbr -a -g krmsecall kubectl delete secret --all
abbr -a -g ksysrmsecall kubectl --namespace=kube-system delete secret --all
abbr -a -g krmnsall kubectl delete namespaces --all
abbr -a -g kgw kubectl get --watch
abbr -a -g ksysgw kubectl --namespace=kube-system get --watch
abbr -a -g kgpow kubectl get pods --watch
abbr -a -g ksysgpow kubectl --namespace=kube-system get pods --watch
abbr -a -g kgdepw kubectl get deployment --watch
abbr -a -g ksysgdepw kubectl --namespace=kube-system get deployment --watch
abbr -a -g kgsvcw kubectl get service --watch
abbr -a -g ksysgsvcw kubectl --namespace=kube-system get service --watch
abbr -a -g kgingw kubectl get ingress --watch
abbr -a -g ksysgingw kubectl --namespace=kube-system get ingress --watch
abbr -a -g kgcmw kubectl get configmap --watch
abbr -a -g ksysgcmw kubectl --namespace=kube-system get configmap --watch
abbr -a -g kgsecw kubectl get secret --watch
abbr -a -g ksysgsecw kubectl --namespace=kube-system get secret --watch
abbr -a -g kgnow kubectl get nodes --watch
abbr -a -g kgnsw kubectl get namespaces --watch
abbr -a -g kgoyamlall kubectl get -o=yaml --all-namespaces
abbr -a -g kgpooyamlall kubectl get pods -o=yaml --all-namespaces
abbr -a -g kgdepoyamlall kubectl get deployment -o=yaml --all-namespaces
abbr -a -g kgsvcoyamlall kubectl get service -o=yaml --all-namespaces
abbr -a -g kgingoyamlall kubectl get ingress -o=yaml --all-namespaces
abbr -a -g kgcmoyamlall kubectl get configmap -o=yaml --all-namespaces
abbr -a -g kgsecoyamlall kubectl get secret -o=yaml --all-namespaces
abbr -a -g kgnsoyamlall kubectl get namespaces -o=yaml --all-namespaces
abbr -a -g kgalloyaml kubectl get --all-namespaces -o=yaml
abbr -a -g kgpoalloyaml kubectl get pods --all-namespaces -o=yaml
abbr -a -g kgdepalloyaml kubectl get deployment --all-namespaces -o=yaml
abbr -a -g kgsvcalloyaml kubectl get service --all-namespaces -o=yaml
abbr -a -g kgingalloyaml kubectl get ingress --all-namespaces -o=yaml
abbr -a -g kgcmalloyaml kubectl get configmap --all-namespaces -o=yaml
abbr -a -g kgsecalloyaml kubectl get secret --all-namespaces -o=yaml
abbr -a -g kgnsalloyaml kubectl get namespaces --all-namespaces -o=yaml
abbr -a -g kgwoyaml kubectl get --watch -o=yaml
abbr -a -g ksysgwoyaml kubectl --namespace=kube-system get --watch -o=yaml
abbr -a -g kgpowoyaml kubectl get pods --watch -o=yaml
abbr -a -g ksysgpowoyaml kubectl --namespace=kube-system get pods --watch -o=yaml
abbr -a -g kgdepwoyaml kubectl get deployment --watch -o=yaml
abbr -a -g ksysgdepwoyaml kubectl --namespace=kube-system get deployment --watch -o=yaml
abbr -a -g kgsvcwoyaml kubectl get service --watch -o=yaml
abbr -a -g ksysgsvcwoyaml kubectl --namespace=kube-system get service --watch -o=yaml
abbr -a -g kgingwoyaml kubectl get ingress --watch -o=yaml
abbr -a -g ksysgingwoyaml kubectl --namespace=kube-system get ingress --watch -o=yaml
abbr -a -g kgcmwoyaml kubectl get configmap --watch -o=yaml
abbr -a -g ksysgcmwoyaml kubectl --namespace=kube-system get configmap --watch -o=yaml
abbr -a -g kgsecwoyaml kubectl get secret --watch -o=yaml
abbr -a -g ksysgsecwoyaml kubectl --namespace=kube-system get secret --watch -o=yaml
abbr -a -g kgnowoyaml kubectl get nodes --watch -o=yaml
abbr -a -g kgnswoyaml kubectl get namespaces --watch -o=yaml
abbr -a -g kgowideall kubectl get -o=wide --all-namespaces
abbr -a -g kgpoowideall kubectl get pods -o=wide --all-namespaces
abbr -a -g kgdepowideall kubectl get deployment -o=wide --all-namespaces
abbr -a -g kgsvcowideall kubectl get service -o=wide --all-namespaces
abbr -a -g kgingowideall kubectl get ingress -o=wide --all-namespaces
abbr -a -g kgcmowideall kubectl get configmap -o=wide --all-namespaces
abbr -a -g kgsecowideall kubectl get secret -o=wide --all-namespaces
abbr -a -g kgnsowideall kubectl get namespaces -o=wide --all-namespaces
abbr -a -g kgallowide kubectl get --all-namespaces -o=wide
abbr -a -g kgpoallowide kubectl get pods --all-namespaces -o=wide
abbr -a -g kgdepallowide kubectl get deployment --all-namespaces -o=wide
abbr -a -g kgsvcallowide kubectl get service --all-namespaces -o=wide
abbr -a -g kgingallowide kubectl get ingress --all-namespaces -o=wide
abbr -a -g kgcmallowide kubectl get configmap --all-namespaces -o=wide
abbr -a -g kgsecallowide kubectl get secret --all-namespaces -o=wide
abbr -a -g kgnsallowide kubectl get namespaces --all-namespaces -o=wide
abbr -a -g kgowidesl kubectl get -o=wide --show-labels
abbr -a -g ksysgowidesl kubectl --namespace=kube-system get -o=wide --show-labels
abbr -a -g kgpoowidesl kubectl get pods -o=wide --show-labels
abbr -a -g ksysgpoowidesl kubectl --namespace=kube-system get pods -o=wide --show-labels
abbr -a -g kgdepowidesl kubectl get deployment -o=wide --show-labels
abbr -a -g ksysgdepowidesl kubectl --namespace=kube-system get deployment -o=wide --show-labels
abbr -a -g kgslowide kubectl get --show-labels -o=wide
abbr -a -g ksysgslowide kubectl --namespace=kube-system get --show-labels -o=wide
abbr -a -g kgposlowide kubectl get pods --show-labels -o=wide
abbr -a -g ksysgposlowide kubectl --namespace=kube-system get pods --show-labels -o=wide
abbr -a -g kgdepslowide kubectl get deployment --show-labels -o=wide
abbr -a -g ksysgdepslowide kubectl --namespace=kube-system get deployment --show-labels -o=wide
abbr -a -g kgwowide kubectl get --watch -o=wide
abbr -a -g ksysgwowide kubectl --namespace=kube-system get --watch -o=wide
abbr -a -g kgpowowide kubectl get pods --watch -o=wide
abbr -a -g ksysgpowowide kubectl --namespace=kube-system get pods --watch -o=wide
abbr -a -g kgdepwowide kubectl get deployment --watch -o=wide
abbr -a -g ksysgdepwowide kubectl --namespace=kube-system get deployment --watch -o=wide
abbr -a -g kgsvcwowide kubectl get service --watch -o=wide
abbr -a -g ksysgsvcwowide kubectl --namespace=kube-system get service --watch -o=wide
abbr -a -g kgingwowide kubectl get ingress --watch -o=wide
abbr -a -g ksysgingwowide kubectl --namespace=kube-system get ingress --watch -o=wide
abbr -a -g kgcmwowide kubectl get configmap --watch -o=wide
abbr -a -g ksysgcmwowide kubectl --namespace=kube-system get configmap --watch -o=wide
abbr -a -g kgsecwowide kubectl get secret --watch -o=wide
abbr -a -g ksysgsecwowide kubectl --namespace=kube-system get secret --watch -o=wide
abbr -a -g kgnowowide kubectl get nodes --watch -o=wide
abbr -a -g kgnswowide kubectl get namespaces --watch -o=wide
abbr -a -g kgojsonall kubectl get -o=json --all-namespaces
abbr -a -g kgpoojsonall kubectl get pods -o=json --all-namespaces
abbr -a -g kgdepojsonall kubectl get deployment -o=json --all-namespaces
abbr -a -g kgsvcojsonall kubectl get service -o=json --all-namespaces
abbr -a -g kgingojsonall kubectl get ingress -o=json --all-namespaces
abbr -a -g kgcmojsonall kubectl get configmap -o=json --all-namespaces
abbr -a -g kgsecojsonall kubectl get secret -o=json --all-namespaces
abbr -a -g kgnsojsonall kubectl get namespaces -o=json --all-namespaces
abbr -a -g kgallojson kubectl get --all-namespaces -o=json
abbr -a -g kgpoallojson kubectl get pods --all-namespaces -o=json
abbr -a -g kgdepallojson kubectl get deployment --all-namespaces -o=json
abbr -a -g kgsvcallojson kubectl get service --all-namespaces -o=json
abbr -a -g kgingallojson kubectl get ingress --all-namespaces -o=json
abbr -a -g kgcmallojson kubectl get configmap --all-namespaces -o=json
abbr -a -g kgsecallojson kubectl get secret --all-namespaces -o=json
abbr -a -g kgnsallojson kubectl get namespaces --all-namespaces -o=json
abbr -a -g kgwojson kubectl get --watch -o=json
abbr -a -g ksysgwojson kubectl --namespace=kube-system get --watch -o=json
abbr -a -g kgpowojson kubectl get pods --watch -o=json
abbr -a -g ksysgpowojson kubectl --namespace=kube-system get pods --watch -o=json
abbr -a -g kgdepwojson kubectl get deployment --watch -o=json
abbr -a -g ksysgdepwojson kubectl --namespace=kube-system get deployment --watch -o=json
abbr -a -g kgsvcwojson kubectl get service --watch -o=json
abbr -a -g ksysgsvcwojson kubectl --namespace=kube-system get service --watch -o=json
abbr -a -g kgingwojson kubectl get ingress --watch -o=json
abbr -a -g ksysgingwojson kubectl --namespace=kube-system get ingress --watch -o=json
abbr -a -g kgcmwojson kubectl get configmap --watch -o=json
abbr -a -g ksysgcmwojson kubectl --namespace=kube-system get configmap --watch -o=json
abbr -a -g kgsecwojson kubectl get secret --watch -o=json
abbr -a -g ksysgsecwojson kubectl --namespace=kube-system get secret --watch -o=json
abbr -a -g kgnowojson kubectl get nodes --watch -o=json
abbr -a -g kgnswojson kubectl get namespaces --watch -o=json
abbr -a -g kgallsl kubectl get --all-namespaces --show-labels
abbr -a -g kgpoallsl kubectl get pods --all-namespaces --show-labels
abbr -a -g kgdepallsl kubectl get deployment --all-namespaces --show-labels
abbr -a -g kgslall kubectl get --show-labels --all-namespaces
abbr -a -g kgposlall kubectl get pods --show-labels --all-namespaces
abbr -a -g kgdepslall kubectl get deployment --show-labels --all-namespaces
abbr -a -g kgallw kubectl get --all-namespaces --watch
abbr -a -g kgpoallw kubectl get pods --all-namespaces --watch
abbr -a -g kgdepallw kubectl get deployment --all-namespaces --watch
abbr -a -g kgsvcallw kubectl get service --all-namespaces --watch
abbr -a -g kgingallw kubectl get ingress --all-namespaces --watch
abbr -a -g kgcmallw kubectl get configmap --all-namespaces --watch
abbr -a -g kgsecallw kubectl get secret --all-namespaces --watch
abbr -a -g kgnsallw kubectl get namespaces --all-namespaces --watch
abbr -a -g kgwall kubectl get --watch --all-namespaces
abbr -a -g kgpowall kubectl get pods --watch --all-namespaces
abbr -a -g kgdepwall kubectl get deployment --watch --all-namespaces
abbr -a -g kgsvcwall kubectl get service --watch --all-namespaces
abbr -a -g kgingwall kubectl get ingress --watch --all-namespaces
abbr -a -g kgcmwall kubectl get configmap --watch --all-namespaces
abbr -a -g kgsecwall kubectl get secret --watch --all-namespaces
abbr -a -g kgnswall kubectl get namespaces --watch --all-namespaces
abbr -a -g kgslw kubectl get --show-labels --watch
abbr -a -g ksysgslw kubectl --namespace=kube-system get --show-labels --watch
abbr -a -g kgposlw kubectl get pods --show-labels --watch
abbr -a -g ksysgposlw kubectl --namespace=kube-system get pods --show-labels --watch
abbr -a -g kgdepslw kubectl get deployment --show-labels --watch
abbr -a -g ksysgdepslw kubectl --namespace=kube-system get deployment --show-labels --watch
abbr -a -g kgwsl kubectl get --watch --show-labels
abbr -a -g ksysgwsl kubectl --namespace=kube-system get --watch --show-labels
abbr -a -g kgpowsl kubectl get pods --watch --show-labels
abbr -a -g ksysgpowsl kubectl --namespace=kube-system get pods --watch --show-labels
abbr -a -g kgdepwsl kubectl get deployment --watch --show-labels
abbr -a -g ksysgdepwsl kubectl --namespace=kube-system get deployment --watch --show-labels
abbr -a -g kgallwoyaml kubectl get --all-namespaces --watch -o=yaml
abbr -a -g kgpoallwoyaml kubectl get pods --all-namespaces --watch -o=yaml
abbr -a -g kgdepallwoyaml kubectl get deployment --all-namespaces --watch -o=yaml
abbr -a -g kgsvcallwoyaml kubectl get service --all-namespaces --watch -o=yaml
abbr -a -g kgingallwoyaml kubectl get ingress --all-namespaces --watch -o=yaml
abbr -a -g kgcmallwoyaml kubectl get configmap --all-namespaces --watch -o=yaml
abbr -a -g kgsecallwoyaml kubectl get secret --all-namespaces --watch -o=yaml
abbr -a -g kgnsallwoyaml kubectl get namespaces --all-namespaces --watch -o=yaml
abbr -a -g kgwoyamlall kubectl get --watch -o=yaml --all-namespaces
abbr -a -g kgpowoyamlall kubectl get pods --watch -o=yaml --all-namespaces
abbr -a -g kgdepwoyamlall kubectl get deployment --watch -o=yaml --all-namespaces
abbr -a -g kgsvcwoyamlall kubectl get service --watch -o=yaml --all-namespaces
abbr -a -g kgingwoyamlall kubectl get ingress --watch -o=yaml --all-namespaces
abbr -a -g kgcmwoyamlall kubectl get configmap --watch -o=yaml --all-namespaces
abbr -a -g kgsecwoyamlall kubectl get secret --watch -o=yaml --all-namespaces
abbr -a -g kgnswoyamlall kubectl get namespaces --watch -o=yaml --all-namespaces
abbr -a -g kgwalloyaml kubectl get --watch --all-namespaces -o=yaml
abbr -a -g kgpowalloyaml kubectl get pods --watch --all-namespaces -o=yaml
abbr -a -g kgdepwalloyaml kubectl get deployment --watch --all-namespaces -o=yaml
abbr -a -g kgsvcwalloyaml kubectl get service --watch --all-namespaces -o=yaml
abbr -a -g kgingwalloyaml kubectl get ingress --watch --all-namespaces -o=yaml
abbr -a -g kgcmwalloyaml kubectl get configmap --watch --all-namespaces -o=yaml
abbr -a -g kgsecwalloyaml kubectl get secret --watch --all-namespaces -o=yaml
abbr -a -g kgnswalloyaml kubectl get namespaces --watch --all-namespaces -o=yaml
abbr -a -g kgowideallsl kubectl get -o=wide --all-namespaces --show-labels
abbr -a -g kgpoowideallsl kubectl get pods -o=wide --all-namespaces --show-labels
abbr -a -g kgdepowideallsl kubectl get deployment -o=wide --all-namespaces --show-labels
abbr -a -g kgowideslall kubectl get -o=wide --show-labels --all-namespaces
abbr -a -g kgpoowideslall kubectl get pods -o=wide --show-labels --all-namespaces
abbr -a -g kgdepowideslall kubectl get deployment -o=wide --show-labels --all-namespaces
abbr -a -g kgallowidesl kubectl get --all-namespaces -o=wide --show-labels
abbr -a -g kgpoallowidesl kubectl get pods --all-namespaces -o=wide --show-labels
abbr -a -g kgdepallowidesl kubectl get deployment --all-namespaces -o=wide --show-labels
abbr -a -g kgallslowide kubectl get --all-namespaces --show-labels -o=wide
abbr -a -g kgpoallslowide kubectl get pods --all-namespaces --show-labels -o=wide
abbr -a -g kgdepallslowide kubectl get deployment --all-namespaces --show-labels -o=wide
abbr -a -g kgslowideall kubectl get --show-labels -o=wide --all-namespaces
abbr -a -g kgposlowideall kubectl get pods --show-labels -o=wide --all-namespaces
abbr -a -g kgdepslowideall kubectl get deployment --show-labels -o=wide --all-namespaces
abbr -a -g kgslallowide kubectl get --show-labels --all-namespaces -o=wide
abbr -a -g kgposlallowide kubectl get pods --show-labels --all-namespaces -o=wide
abbr -a -g kgdepslallowide kubectl get deployment --show-labels --all-namespaces -o=wide
abbr -a -g kgallwowide kubectl get --all-namespaces --watch -o=wide
abbr -a -g kgpoallwowide kubectl get pods --all-namespaces --watch -o=wide
abbr -a -g kgdepallwowide kubectl get deployment --all-namespaces --watch -o=wide
abbr -a -g kgsvcallwowide kubectl get service --all-namespaces --watch -o=wide
abbr -a -g kgingallwowide kubectl get ingress --all-namespaces --watch -o=wide
abbr -a -g kgcmallwowide kubectl get configmap --all-namespaces --watch -o=wide
abbr -a -g kgsecallwowide kubectl get secret --all-namespaces --watch -o=wide
abbr -a -g kgnsallwowide kubectl get namespaces --all-namespaces --watch -o=wide
abbr -a -g kgwowideall kubectl get --watch -o=wide --all-namespaces
abbr -a -g kgpowowideall kubectl get pods --watch -o=wide --all-namespaces
abbr -a -g kgdepwowideall kubectl get deployment --watch -o=wide --all-namespaces
abbr -a -g kgsvcwowideall kubectl get service --watch -o=wide --all-namespaces
abbr -a -g kgingwowideall kubectl get ingress --watch -o=wide --all-namespaces
abbr -a -g kgcmwowideall kubectl get configmap --watch -o=wide --all-namespaces
abbr -a -g kgsecwowideall kubectl get secret --watch -o=wide --all-namespaces
abbr -a -g kgnswowideall kubectl get namespaces --watch -o=wide --all-namespaces
abbr -a -g kgwallowide kubectl get --watch --all-namespaces -o=wide
abbr -a -g kgpowallowide kubectl get pods --watch --all-namespaces -o=wide
abbr -a -g kgdepwallowide kubectl get deployment --watch --all-namespaces -o=wide
abbr -a -g kgsvcwallowide kubectl get service --watch --all-namespaces -o=wide
abbr -a -g kgingwallowide kubectl get ingress --watch --all-namespaces -o=wide
abbr -a -g kgcmwallowide kubectl get configmap --watch --all-namespaces -o=wide
abbr -a -g kgsecwallowide kubectl get secret --watch --all-namespaces -o=wide
abbr -a -g kgnswallowide kubectl get namespaces --watch --all-namespaces -o=wide
abbr -a -g kgslwowide kubectl get --show-labels --watch -o=wide
abbr -a -g ksysgslwowide kubectl --namespace=kube-system get --show-labels --watch -o=wide
abbr -a -g kgposlwowide kubectl get pods --show-labels --watch -o=wide
abbr -a -g ksysgposlwowide kubectl --namespace=kube-system get pods --show-labels --watch -o=wide
abbr -a -g kgdepslwowide kubectl get deployment --show-labels --watch -o=wide
abbr -a -g ksysgdepslwowide kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide
abbr -a -g kgwowidesl kubectl get --watch -o=wide --show-labels
abbr -a -g ksysgwowidesl kubectl --namespace=kube-system get --watch -o=wide --show-labels
abbr -a -g kgpowowidesl kubectl get pods --watch -o=wide --show-labels
abbr -a -g ksysgpowowidesl kubectl --namespace=kube-system get pods --watch -o=wide --show-labels
abbr -a -g kgdepwowidesl kubectl get deployment --watch -o=wide --show-labels
abbr -a -g ksysgdepwowidesl kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels
abbr -a -g kgwslowide kubectl get --watch --show-labels -o=wide
abbr -a -g ksysgwslowide kubectl --namespace=kube-system get --watch --show-labels -o=wide
abbr -a -g kgpowslowide kubectl get pods --watch --show-labels -o=wide
abbr -a -g ksysgpowslowide kubectl --namespace=kube-system get pods --watch --show-labels -o=wide
abbr -a -g kgdepwslowide kubectl get deployment --watch --show-labels -o=wide
abbr -a -g ksysgdepwslowide kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide
abbr -a -g kgallwojson kubectl get --all-namespaces --watch -o=json
abbr -a -g kgpoallwojson kubectl get pods --all-namespaces --watch -o=json
abbr -a -g kgdepallwojson kubectl get deployment --all-namespaces --watch -o=json
abbr -a -g kgsvcallwojson kubectl get service --all-namespaces --watch -o=json
abbr -a -g kgingallwojson kubectl get ingress --all-namespaces --watch -o=json
abbr -a -g kgcmallwojson kubectl get configmap --all-namespaces --watch -o=json
abbr -a -g kgsecallwojson kubectl get secret --all-namespaces --watch -o=json
abbr -a -g kgnsallwojson kubectl get namespaces --all-namespaces --watch -o=json
abbr -a -g kgwojsonall kubectl get --watch -o=json --all-namespaces
abbr -a -g kgpowojsonall kubectl get pods --watch -o=json --all-namespaces
abbr -a -g kgdepwojsonall kubectl get deployment --watch -o=json --all-namespaces
abbr -a -g kgsvcwojsonall kubectl get service --watch -o=json --all-namespaces
abbr -a -g kgingwojsonall kubectl get ingress --watch -o=json --all-namespaces
abbr -a -g kgcmwojsonall kubectl get configmap --watch -o=json --all-namespaces
abbr -a -g kgsecwojsonall kubectl get secret --watch -o=json --all-namespaces
abbr -a -g kgnswojsonall kubectl get namespaces --watch -o=json --all-namespaces
abbr -a -g kgwallojson kubectl get --watch --all-namespaces -o=json
abbr -a -g kgpowallojson kubectl get pods --watch --all-namespaces -o=json
abbr -a -g kgdepwallojson kubectl get deployment --watch --all-namespaces -o=json
abbr -a -g kgsvcwallojson kubectl get service --watch --all-namespaces -o=json
abbr -a -g kgingwallojson kubectl get ingress --watch --all-namespaces -o=json
abbr -a -g kgcmwallojson kubectl get configmap --watch --all-namespaces -o=json
abbr -a -g kgsecwallojson kubectl get secret --watch --all-namespaces -o=json
abbr -a -g kgnswallojson kubectl get namespaces --watch --all-namespaces -o=json
abbr -a -g kgallslw kubectl get --all-namespaces --show-labels --watch
abbr -a -g kgpoallslw kubectl get pods --all-namespaces --show-labels --watch
abbr -a -g kgdepallslw kubectl get deployment --all-namespaces --show-labels --watch
abbr -a -g kgallwsl kubectl get --all-namespaces --watch --show-labels
abbr -a -g kgpoallwsl kubectl get pods --all-namespaces --watch --show-labels
abbr -a -g kgdepallwsl kubectl get deployment --all-namespaces --watch --show-labels
abbr -a -g kgslallw kubectl get --show-labels --all-namespaces --watch
abbr -a -g kgposlallw kubectl get pods --show-labels --all-namespaces --watch
abbr -a -g kgdepslallw kubectl get deployment --show-labels --all-namespaces --watch
abbr -a -g kgslwall kubectl get --show-labels --watch --all-namespaces
abbr -a -g kgposlwall kubectl get pods --show-labels --watch --all-namespaces
abbr -a -g kgdepslwall kubectl get deployment --show-labels --watch --all-namespaces
abbr -a -g kgwallsl kubectl get --watch --all-namespaces --show-labels
abbr -a -g kgpowallsl kubectl get pods --watch --all-namespaces --show-labels
abbr -a -g kgdepwallsl kubectl get deployment --watch --all-namespaces --show-labels
abbr -a -g kgwslall kubectl get --watch --show-labels --all-namespaces
abbr -a -g kgpowslall kubectl get pods --watch --show-labels --all-namespaces
abbr -a -g kgdepwslall kubectl get deployment --watch --show-labels --all-namespaces
abbr -a -g kgallslwowide kubectl get --all-namespaces --show-labels --watch -o=wide
abbr -a -g kgpoallslwowide kubectl get pods --all-namespaces --show-labels --watch -o=wide
abbr -a -g kgdepallslwowide kubectl get deployment --all-namespaces --show-labels --watch -o=wide
abbr -a -g kgallwowidesl kubectl get --all-namespaces --watch -o=wide --show-labels
abbr -a -g kgpoallwowidesl kubectl get pods --all-namespaces --watch -o=wide --show-labels
abbr -a -g kgdepallwowidesl kubectl get deployment --all-namespaces --watch -o=wide --show-labels
abbr -a -g kgallwslowide kubectl get --all-namespaces --watch --show-labels -o=wide
abbr -a -g kgpoallwslowide kubectl get pods --all-namespaces --watch --show-labels -o=wide
abbr -a -g kgdepallwslowide kubectl get deployment --all-namespaces --watch --show-labels -o=wide
abbr -a -g kgslallwowide kubectl get --show-labels --all-namespaces --watch -o=wide
abbr -a -g kgposlallwowide kubectl get pods --show-labels --all-namespaces --watch -o=wide
abbr -a -g kgdepslallwowide kubectl get deployment --show-labels --all-namespaces --watch -o=wide
abbr -a -g kgslwowideall kubectl get --show-labels --watch -o=wide --all-namespaces
abbr -a -g kgposlwowideall kubectl get pods --show-labels --watch -o=wide --all-namespaces
abbr -a -g kgdepslwowideall kubectl get deployment --show-labels --watch -o=wide --all-namespaces
abbr -a -g kgslwallowide kubectl get --show-labels --watch --all-namespaces -o=wide
abbr -a -g kgposlwallowide kubectl get pods --show-labels --watch --all-namespaces -o=wide
abbr -a -g kgdepslwallowide kubectl get deployment --show-labels --watch --all-namespaces -o=wide
abbr -a -g kgwowideallsl kubectl get --watch -o=wide --all-namespaces --show-labels
abbr -a -g kgpowowideallsl kubectl get pods --watch -o=wide --all-namespaces --show-labels
abbr -a -g kgdepwowideallsl kubectl get deployment --watch -o=wide --all-namespaces --show-labels
abbr -a -g kgwowideslall kubectl get --watch -o=wide --show-labels --all-namespaces
abbr -a -g kgpowowideslall kubectl get pods --watch -o=wide --show-labels --all-namespaces
abbr -a -g kgdepwowideslall kubectl get deployment --watch -o=wide --show-labels --all-namespaces
abbr -a -g kgwallowidesl kubectl get --watch --all-namespaces -o=wide --show-labels
abbr -a -g kgpowallowidesl kubectl get pods --watch --all-namespaces -o=wide --show-labels
abbr -a -g kgdepwallowidesl kubectl get deployment --watch --all-namespaces -o=wide --show-labels
abbr -a -g kgwallslowide kubectl get --watch --all-namespaces --show-labels -o=wide
abbr -a -g kgpowallslowide kubectl get pods --watch --all-namespaces --show-labels -o=wide
abbr -a -g kgdepwallslowide kubectl get deployment --watch --all-namespaces --show-labels -o=wide
abbr -a -g kgwslowideall kubectl get --watch --show-labels -o=wide --all-namespaces
abbr -a -g kgpowslowideall kubectl get pods --watch --show-labels -o=wide --all-namespaces
abbr -a -g kgdepwslowideall kubectl get deployment --watch --show-labels -o=wide --all-namespaces
abbr -a -g kgwslallowide kubectl get --watch --show-labels --all-namespaces -o=wide
abbr -a -g kgpowslallowide kubectl get pods --watch --show-labels --all-namespaces -o=wide
abbr -a -g kgdepwslallowide kubectl get deployment --watch --show-labels --all-namespaces -o=wide
abbr -a -g kgf kubectl get --recursive -f
abbr -a -g kdf kubectl describe --recursive -f
abbr -a -g krmf kubectl delete --recursive -f
abbr -a -g kgoyamlf kubectl get -o=yaml --recursive -f
abbr -a -g kgowidef kubectl get -o=wide --recursive -f
abbr -a -g kgojsonf kubectl get -o=json --recursive -f
abbr -a -g kgslf kubectl get --show-labels --recursive -f
abbr -a -g kgwf kubectl get --watch --recursive -f
abbr -a -g kgwoyamlf kubectl get --watch -o=yaml --recursive -f
abbr -a -g kgowideslf kubectl get -o=wide --show-labels --recursive -f
abbr -a -g kgslowidef kubectl get --show-labels -o=wide --recursive -f
abbr -a -g kgwowidef kubectl get --watch -o=wide --recursive -f
abbr -a -g kgwojsonf kubectl get --watch -o=json --recursive -f
abbr -a -g kgslwf kubectl get --show-labels --watch --recursive -f
abbr -a -g kgwslf kubectl get --watch --show-labels --recursive -f
abbr -a -g kgslwowidef kubectl get --show-labels --watch -o=wide --recursive -f
abbr -a -g kgwowideslf kubectl get --watch -o=wide --show-labels --recursive -f
abbr -a -g kgwslowidef kubectl get --watch --show-labels -o=wide --recursive -f
abbr -a -g kgl kubectl get -l
abbr -a -g ksysgl kubectl --namespace=kube-system get -l
abbr -a -g kdl kubectl describe -l
abbr -a -g ksysdl kubectl --namespace=kube-system describe -l
abbr -a -g krml kubectl delete -l
abbr -a -g ksysrml kubectl --namespace=kube-system delete -l
abbr -a -g kgpol kubectl get pods -l
abbr -a -g ksysgpol kubectl --namespace=kube-system get pods -l
abbr -a -g kdpol kubectl describe pods -l
abbr -a -g ksysdpol kubectl --namespace=kube-system describe pods -l
abbr -a -g krmpol kubectl delete pods -l
abbr -a -g ksysrmpol kubectl --namespace=kube-system delete pods -l
abbr -a -g kgdepl kubectl get deployment -l
abbr -a -g ksysgdepl kubectl --namespace=kube-system get deployment -l
abbr -a -g kddepl kubectl describe deployment -l
abbr -a -g ksysddepl kubectl --namespace=kube-system describe deployment -l
abbr -a -g krmdepl kubectl delete deployment -l
abbr -a -g ksysrmdepl kubectl --namespace=kube-system delete deployment -l
abbr -a -g kgsvcl kubectl get service -l
abbr -a -g ksysgsvcl kubectl --namespace=kube-system get service -l
abbr -a -g kdsvcl kubectl describe service -l
abbr -a -g ksysdsvcl kubectl --namespace=kube-system describe service -l
abbr -a -g krmsvcl kubectl delete service -l
abbr -a -g ksysrmsvcl kubectl --namespace=kube-system delete service -l
abbr -a -g kgingl kubectl get ingress -l
abbr -a -g ksysgingl kubectl --namespace=kube-system get ingress -l
abbr -a -g kdingl kubectl describe ingress -l
abbr -a -g ksysdingl kubectl --namespace=kube-system describe ingress -l
abbr -a -g krmingl kubectl delete ingress -l
abbr -a -g ksysrmingl kubectl --namespace=kube-system delete ingress -l
abbr -a -g kgcml kubectl get configmap -l
abbr -a -g ksysgcml kubectl --namespace=kube-system get configmap -l
abbr -a -g kdcml kubectl describe configmap -l
abbr -a -g ksysdcml kubectl --namespace=kube-system describe configmap -l
abbr -a -g krmcml kubectl delete configmap -l
abbr -a -g ksysrmcml kubectl --namespace=kube-system delete configmap -l
abbr -a -g kgsecl kubectl get secret -l
abbr -a -g ksysgsecl kubectl --namespace=kube-system get secret -l
abbr -a -g kdsecl kubectl describe secret -l
abbr -a -g ksysdsecl kubectl --namespace=kube-system describe secret -l
abbr -a -g krmsecl kubectl delete secret -l
abbr -a -g ksysrmsecl kubectl --namespace=kube-system delete secret -l
abbr -a -g kgnol kubectl get nodes -l
abbr -a -g kdnol kubectl describe nodes -l
abbr -a -g kgnsl kubectl get namespaces -l
abbr -a -g kdnsl kubectl describe namespaces -l
abbr -a -g krmnsl kubectl delete namespaces -l
abbr -a -g kgoyamll kubectl get -o=yaml -l
abbr -a -g ksysgoyamll kubectl --namespace=kube-system get -o=yaml -l
abbr -a -g kgpooyamll kubectl get pods -o=yaml -l
abbr -a -g ksysgpooyamll kubectl --namespace=kube-system get pods -o=yaml -l
abbr -a -g kgdepoyamll kubectl get deployment -o=yaml -l
abbr -a -g ksysgdepoyamll kubectl --namespace=kube-system get deployment -o=yaml -l
abbr -a -g kgsvcoyamll kubectl get service -o=yaml -l
abbr -a -g ksysgsvcoyamll kubectl --namespace=kube-system get service -o=yaml -l
abbr -a -g kgingoyamll kubectl get ingress -o=yaml -l
abbr -a -g ksysgingoyamll kubectl --namespace=kube-system get ingress -o=yaml -l
abbr -a -g kgcmoyamll kubectl get configmap -o=yaml -l
abbr -a -g ksysgcmoyamll kubectl --namespace=kube-system get configmap -o=yaml -l
abbr -a -g kgsecoyamll kubectl get secret -o=yaml -l
abbr -a -g ksysgsecoyamll kubectl --namespace=kube-system get secret -o=yaml -l
abbr -a -g kgnooyamll kubectl get nodes -o=yaml -l
abbr -a -g kgnsoyamll kubectl get namespaces -o=yaml -l
abbr -a -g kgowidel kubectl get -o=wide -l
abbr -a -g ksysgowidel kubectl --namespace=kube-system get -o=wide -l
abbr -a -g kgpoowidel kubectl get pods -o=wide -l
abbr -a -g ksysgpoowidel kubectl --namespace=kube-system get pods -o=wide -l
abbr -a -g kgdepowidel kubectl get deployment -o=wide -l
abbr -a -g ksysgdepowidel kubectl --namespace=kube-system get deployment -o=wide -l
abbr -a -g kgsvcowidel kubectl get service -o=wide -l
abbr -a -g ksysgsvcowidel kubectl --namespace=kube-system get service -o=wide -l
abbr -a -g kgingowidel kubectl get ingress -o=wide -l
abbr -a -g ksysgingowidel kubectl --namespace=kube-system get ingress -o=wide -l
abbr -a -g kgcmowidel kubectl get configmap -o=wide -l
abbr -a -g ksysgcmowidel kubectl --namespace=kube-system get configmap -o=wide -l
abbr -a -g kgsecowidel kubectl get secret -o=wide -l
abbr -a -g ksysgsecowidel kubectl --namespace=kube-system get secret -o=wide -l
abbr -a -g kgnoowidel kubectl get nodes -o=wide -l
abbr -a -g kgnsowidel kubectl get namespaces -o=wide -l
abbr -a -g kgojsonl kubectl get -o=json -l
abbr -a -g ksysgojsonl kubectl --namespace=kube-system get -o=json -l
abbr -a -g kgpoojsonl kubectl get pods -o=json -l
abbr -a -g ksysgpoojsonl kubectl --namespace=kube-system get pods -o=json -l
abbr -a -g kgdepojsonl kubectl get deployment -o=json -l
abbr -a -g ksysgdepojsonl kubectl --namespace=kube-system get deployment -o=json -l
abbr -a -g kgsvcojsonl kubectl get service -o=json -l
abbr -a -g ksysgsvcojsonl kubectl --namespace=kube-system get service -o=json -l
abbr -a -g kgingojsonl kubectl get ingress -o=json -l
abbr -a -g ksysgingojsonl kubectl --namespace=kube-system get ingress -o=json -l
abbr -a -g kgcmojsonl kubectl get configmap -o=json -l
abbr -a -g ksysgcmojsonl kubectl --namespace=kube-system get configmap -o=json -l
abbr -a -g kgsecojsonl kubectl get secret -o=json -l
abbr -a -g ksysgsecojsonl kubectl --namespace=kube-system get secret -o=json -l
abbr -a -g kgnoojsonl kubectl get nodes -o=json -l
abbr -a -g kgnsojsonl kubectl get namespaces -o=json -l
abbr -a -g kgsll kubectl get --show-labels -l
abbr -a -g ksysgsll kubectl --namespace=kube-system get --show-labels -l
abbr -a -g kgposll kubectl get pods --show-labels -l
abbr -a -g ksysgposll kubectl --namespace=kube-system get pods --show-labels -l
abbr -a -g kgdepsll kubectl get deployment --show-labels -l
abbr -a -g ksysgdepsll kubectl --namespace=kube-system get deployment --show-labels -l
abbr -a -g kgwl kubectl get --watch -l
abbr -a -g ksysgwl kubectl --namespace=kube-system get --watch -l
abbr -a -g kgpowl kubectl get pods --watch -l
abbr -a -g ksysgpowl kubectl --namespace=kube-system get pods --watch -l
abbr -a -g kgdepwl kubectl get deployment --watch -l
abbr -a -g ksysgdepwl kubectl --namespace=kube-system get deployment --watch -l
abbr -a -g kgsvcwl kubectl get service --watch -l
abbr -a -g ksysgsvcwl kubectl --namespace=kube-system get service --watch -l
abbr -a -g kgingwl kubectl get ingress --watch -l
abbr -a -g ksysgingwl kubectl --namespace=kube-system get ingress --watch -l
abbr -a -g kgcmwl kubectl get configmap --watch -l
abbr -a -g ksysgcmwl kubectl --namespace=kube-system get configmap --watch -l
abbr -a -g kgsecwl kubectl get secret --watch -l
abbr -a -g ksysgsecwl kubectl --namespace=kube-system get secret --watch -l
abbr -a -g kgnowl kubectl get nodes --watch -l
abbr -a -g kgnswl kubectl get namespaces --watch -l
abbr -a -g kgwoyamll kubectl get --watch -o=yaml -l
abbr -a -g ksysgwoyamll kubectl --namespace=kube-system get --watch -o=yaml -l
abbr -a -g kgpowoyamll kubectl get pods --watch -o=yaml -l
abbr -a -g ksysgpowoyamll kubectl --namespace=kube-system get pods --watch -o=yaml -l
abbr -a -g kgdepwoyamll kubectl get deployment --watch -o=yaml -l
abbr -a -g ksysgdepwoyamll kubectl --namespace=kube-system get deployment --watch -o=yaml -l
abbr -a -g kgsvcwoyamll kubectl get service --watch -o=yaml -l
abbr -a -g ksysgsvcwoyamll kubectl --namespace=kube-system get service --watch -o=yaml -l
abbr -a -g kgingwoyamll kubectl get ingress --watch -o=yaml -l
abbr -a -g ksysgingwoyamll kubectl --namespace=kube-system get ingress --watch -o=yaml -l
abbr -a -g kgcmwoyamll kubectl get configmap --watch -o=yaml -l
abbr -a -g ksysgcmwoyamll kubectl --namespace=kube-system get configmap --watch -o=yaml -l
abbr -a -g kgsecwoyamll kubectl get secret --watch -o=yaml -l
abbr -a -g ksysgsecwoyamll kubectl --namespace=kube-system get secret --watch -o=yaml -l
abbr -a -g kgnowoyamll kubectl get nodes --watch -o=yaml -l
abbr -a -g kgnswoyamll kubectl get namespaces --watch -o=yaml -l
abbr -a -g kgowidesll kubectl get -o=wide --show-labels -l
abbr -a -g ksysgowidesll kubectl --namespace=kube-system get -o=wide --show-labels -l
abbr -a -g kgpoowidesll kubectl get pods -o=wide --show-labels -l
abbr -a -g ksysgpoowidesll kubectl --namespace=kube-system get pods -o=wide --show-labels -l
abbr -a -g kgdepowidesll kubectl get deployment -o=wide --show-labels -l
abbr -a -g ksysgdepowidesll kubectl --namespace=kube-system get deployment -o=wide --show-labels -l
abbr -a -g kgslowidel kubectl get --show-labels -o=wide -l
abbr -a -g ksysgslowidel kubectl --namespace=kube-system get --show-labels -o=wide -l
abbr -a -g kgposlowidel kubectl get pods --show-labels -o=wide -l
abbr -a -g ksysgposlowidel kubectl --namespace=kube-system get pods --show-labels -o=wide -l
abbr -a -g kgdepslowidel kubectl get deployment --show-labels -o=wide -l
abbr -a -g ksysgdepslowidel kubectl --namespace=kube-system get deployment --show-labels -o=wide -l
abbr -a -g kgwowidel kubectl get --watch -o=wide -l
abbr -a -g ksysgwowidel kubectl --namespace=kube-system get --watch -o=wide -l
abbr -a -g kgpowowidel kubectl get pods --watch -o=wide -l
abbr -a -g ksysgpowowidel kubectl --namespace=kube-system get pods --watch -o=wide -l
abbr -a -g kgdepwowidel kubectl get deployment --watch -o=wide -l
abbr -a -g ksysgdepwowidel kubectl --namespace=kube-system get deployment --watch -o=wide -l
abbr -a -g kgsvcwowidel kubectl get service --watch -o=wide -l
abbr -a -g ksysgsvcwowidel kubectl --namespace=kube-system get service --watch -o=wide -l
abbr -a -g kgingwowidel kubectl get ingress --watch -o=wide -l
abbr -a -g ksysgingwowidel kubectl --namespace=kube-system get ingress --watch -o=wide -l
abbr -a -g kgcmwowidel kubectl get configmap --watch -o=wide -l
abbr -a -g ksysgcmwowidel kubectl --namespace=kube-system get configmap --watch -o=wide -l
abbr -a -g kgsecwowidel kubectl get secret --watch -o=wide -l
abbr -a -g ksysgsecwowidel kubectl --namespace=kube-system get secret --watch -o=wide -l
abbr -a -g kgnowowidel kubectl get nodes --watch -o=wide -l
abbr -a -g kgnswowidel kubectl get namespaces --watch -o=wide -l
abbr -a -g kgwojsonl kubectl get --watch -o=json -l
abbr -a -g ksysgwojsonl kubectl --namespace=kube-system get --watch -o=json -l
abbr -a -g kgpowojsonl kubectl get pods --watch -o=json -l
abbr -a -g ksysgpowojsonl kubectl --namespace=kube-system get pods --watch -o=json -l
abbr -a -g kgdepwojsonl kubectl get deployment --watch -o=json -l
abbr -a -g ksysgdepwojsonl kubectl --namespace=kube-system get deployment --watch -o=json -l
abbr -a -g kgsvcwojsonl kubectl get service --watch -o=json -l
abbr -a -g ksysgsvcwojsonl kubectl --namespace=kube-system get service --watch -o=json -l
abbr -a -g kgingwojsonl kubectl get ingress --watch -o=json -l
abbr -a -g ksysgingwojsonl kubectl --namespace=kube-system get ingress --watch -o=json -l
abbr -a -g kgcmwojsonl kubectl get configmap --watch -o=json -l
abbr -a -g ksysgcmwojsonl kubectl --namespace=kube-system get configmap --watch -o=json -l
abbr -a -g kgsecwojsonl kubectl get secret --watch -o=json -l
abbr -a -g ksysgsecwojsonl kubectl --namespace=kube-system get secret --watch -o=json -l
abbr -a -g kgnowojsonl kubectl get nodes --watch -o=json -l
abbr -a -g kgnswojsonl kubectl get namespaces --watch -o=json -l
abbr -a -g kgslwl kubectl get --show-labels --watch -l
abbr -a -g ksysgslwl kubectl --namespace=kube-system get --show-labels --watch -l
abbr -a -g kgposlwl kubectl get pods --show-labels --watch -l
abbr -a -g ksysgposlwl kubectl --namespace=kube-system get pods --show-labels --watch -l
abbr -a -g kgdepslwl kubectl get deployment --show-labels --watch -l
abbr -a -g ksysgdepslwl kubectl --namespace=kube-system get deployment --show-labels --watch -l
abbr -a -g kgwsll kubectl get --watch --show-labels -l
abbr -a -g ksysgwsll kubectl --namespace=kube-system get --watch --show-labels -l
abbr -a -g kgpowsll kubectl get pods --watch --show-labels -l
abbr -a -g ksysgpowsll kubectl --namespace=kube-system get pods --watch --show-labels -l
abbr -a -g kgdepwsll kubectl get deployment --watch --show-labels -l
abbr -a -g ksysgdepwsll kubectl --namespace=kube-system get deployment --watch --show-labels -l
abbr -a -g kgslwowidel kubectl get --show-labels --watch -o=wide -l
abbr -a -g ksysgslwowidel kubectl --namespace=kube-system get --show-labels --watch -o=wide -l
abbr -a -g kgposlwowidel kubectl get pods --show-labels --watch -o=wide -l
abbr -a -g ksysgposlwowidel kubectl --namespace=kube-system get pods --show-labels --watch -o=wide -l
abbr -a -g kgdepslwowidel kubectl get deployment --show-labels --watch -o=wide -l
abbr -a -g ksysgdepslwowidel kubectl --namespace=kube-system get deployment --show-labels --watch -o=wide -l
abbr -a -g kgwowidesll kubectl get --watch -o=wide --show-labels -l
abbr -a -g ksysgwowidesll kubectl --namespace=kube-system get --watch -o=wide --show-labels -l
abbr -a -g kgpowowidesll kubectl get pods --watch -o=wide --show-labels -l
abbr -a -g ksysgpowowidesll kubectl --namespace=kube-system get pods --watch -o=wide --show-labels -l
abbr -a -g kgdepwowidesll kubectl get deployment --watch -o=wide --show-labels -l
abbr -a -g ksysgdepwowidesll kubectl --namespace=kube-system get deployment --watch -o=wide --show-labels -l
abbr -a -g kgwslowidel kubectl get --watch --show-labels -o=wide -l
abbr -a -g ksysgwslowidel kubectl --namespace=kube-system get --watch --show-labels -o=wide -l
abbr -a -g kgpowslowidel kubectl get pods --watch --show-labels -o=wide -l
abbr -a -g ksysgpowslowidel kubectl --namespace=kube-system get pods --watch --show-labels -o=wide -l
abbr -a -g kgdepwslowidel kubectl get deployment --watch --show-labels -o=wide -l
abbr -a -g ksysgdepwslowidel kubectl --namespace=kube-system get deployment --watch --show-labels -o=wide -l
abbr -a -g kexn kubectl exec -i -t --namespace
abbr -a -g klon kubectl logs -f --namespace
abbr -a -g kpfn kubectl port-forward --namespace
abbr -a -g kgn kubectl get --namespace
abbr -a -g kdn kubectl describe --namespace
abbr -a -g krmn kubectl delete --namespace
abbr -a -g kgpon kubectl get pods --namespace
abbr -a -g kdpon kubectl describe pods --namespace
abbr -a -g krmpon kubectl delete pods --namespace
abbr -a -g kgdepn kubectl get deployment --namespace
abbr -a -g kddepn kubectl describe deployment --namespace
abbr -a -g krmdepn kubectl delete deployment --namespace
abbr -a -g kgsvcn kubectl get service --namespace
abbr -a -g kdsvcn kubectl describe service --namespace
abbr -a -g krmsvcn kubectl delete service --namespace
abbr -a -g kgingn kubectl get ingress --namespace
abbr -a -g kdingn kubectl describe ingress --namespace
abbr -a -g krmingn kubectl delete ingress --namespace
abbr -a -g kgcmn kubectl get configmap --namespace
abbr -a -g kdcmn kubectl describe configmap --namespace
abbr -a -g krmcmn kubectl delete configmap --namespace
abbr -a -g kgsecn kubectl get secret --namespace
abbr -a -g kdsecn kubectl describe secret --namespace
abbr -a -g krmsecn kubectl delete secret --namespace
abbr -a -g kgoyamln kubectl get -o=yaml --namespace
abbr -a -g kgpooyamln kubectl get pods -o=yaml --namespace
abbr -a -g kgdepoyamln kubectl get deployment -o=yaml --namespace
abbr -a -g kgsvcoyamln kubectl get service -o=yaml --namespace
abbr -a -g kgingoyamln kubectl get ingress -o=yaml --namespace
abbr -a -g kgcmoyamln kubectl get configmap -o=yaml --namespace
abbr -a -g kgsecoyamln kubectl get secret -o=yaml --namespace
abbr -a -g kgowiden kubectl get -o=wide --namespace
abbr -a -g kgpoowiden kubectl get pods -o=wide --namespace
abbr -a -g kgdepowiden kubectl get deployment -o=wide --namespace
abbr -a -g kgsvcowiden kubectl get service -o=wide --namespace
abbr -a -g kgingowiden kubectl get ingress -o=wide --namespace
abbr -a -g kgcmowiden kubectl get configmap -o=wide --namespace
abbr -a -g kgsecowiden kubectl get secret -o=wide --namespace
abbr -a -g kgojsonn kubectl get -o=json --namespace
abbr -a -g kgpoojsonn kubectl get pods -o=json --namespace
abbr -a -g kgdepojsonn kubectl get deployment -o=json --namespace
abbr -a -g kgsvcojsonn kubectl get service -o=json --namespace
abbr -a -g kgingojsonn kubectl get ingress -o=json --namespace
abbr -a -g kgcmojsonn kubectl get configmap -o=json --namespace
abbr -a -g kgsecojsonn kubectl get secret -o=json --namespace
abbr -a -g kgsln kubectl get --show-labels --namespace
abbr -a -g kgposln kubectl get pods --show-labels --namespace
abbr -a -g kgdepsln kubectl get deployment --show-labels --namespace
abbr -a -g kgwn kubectl get --watch --namespace
abbr -a -g kgpown kubectl get pods --watch --namespace
abbr -a -g kgdepwn kubectl get deployment --watch --namespace
abbr -a -g kgsvcwn kubectl get service --watch --namespace
abbr -a -g kgingwn kubectl get ingress --watch --namespace
abbr -a -g kgcmwn kubectl get configmap --watch --namespace
abbr -a -g kgsecwn kubectl get secret --watch --namespace
abbr -a -g kgwoyamln kubectl get --watch -o=yaml --namespace
abbr -a -g kgpowoyamln kubectl get pods --watch -o=yaml --namespace
abbr -a -g kgdepwoyamln kubectl get deployment --watch -o=yaml --namespace
abbr -a -g kgsvcwoyamln kubectl get service --watch -o=yaml --namespace
abbr -a -g kgingwoyamln kubectl get ingress --watch -o=yaml --namespace
abbr -a -g kgcmwoyamln kubectl get configmap --watch -o=yaml --namespace
abbr -a -g kgsecwoyamln kubectl get secret --watch -o=yaml --namespace
abbr -a -g kgowidesln kubectl get -o=wide --show-labels --namespace
abbr -a -g kgpoowidesln kubectl get pods -o=wide --show-labels --namespace
abbr -a -g kgdepowidesln kubectl get deployment -o=wide --show-labels --namespace
abbr -a -g kgslowiden kubectl get --show-labels -o=wide --namespace
abbr -a -g kgposlowiden kubectl get pods --show-labels -o=wide --namespace
abbr -a -g kgdepslowiden kubectl get deployment --show-labels -o=wide --namespace
abbr -a -g kgwowiden kubectl get --watch -o=wide --namespace
abbr -a -g kgpowowiden kubectl get pods --watch -o=wide --namespace
abbr -a -g kgdepwowiden kubectl get deployment --watch -o=wide --namespace
abbr -a -g kgsvcwowiden kubectl get service --watch -o=wide --namespace
abbr -a -g kgingwowiden kubectl get ingress --watch -o=wide --namespace
abbr -a -g kgcmwowiden kubectl get configmap --watch -o=wide --namespace
abbr -a -g kgsecwowiden kubectl get secret --watch -o=wide --namespace
abbr -a -g kgwojsonn kubectl get --watch -o=json --namespace
abbr -a -g kgpowojsonn kubectl get pods --watch -o=json --namespace
abbr -a -g kgdepwojsonn kubectl get deployment --watch -o=json --namespace
abbr -a -g kgsvcwojsonn kubectl get service --watch -o=json --namespace
abbr -a -g kgingwojsonn kubectl get ingress --watch -o=json --namespace
abbr -a -g kgcmwojsonn kubectl get configmap --watch -o=json --namespace
abbr -a -g kgsecwojsonn kubectl get secret --watch -o=json --namespace
abbr -a -g kgslwn kubectl get --show-labels --watch --namespace
abbr -a -g kgposlwn kubectl get pods --show-labels --watch --namespace
abbr -a -g kgdepslwn kubectl get deployment --show-labels --watch --namespace
abbr -a -g kgwsln kubectl get --watch --show-labels --namespace
abbr -a -g kgpowsln kubectl get pods --watch --show-labels --namespace
abbr -a -g kgdepwsln kubectl get deployment --watch --show-labels --namespace
abbr -a -g kgslwowiden kubectl get --show-labels --watch -o=wide --namespace
abbr -a -g kgposlwowiden kubectl get pods --show-labels --watch -o=wide --namespace
abbr -a -g kgdepslwowiden kubectl get deployment --show-labels --watch -o=wide --namespace
abbr -a -g kgwowidesln kubectl get --watch -o=wide --show-labels --namespace
abbr -a -g kgpowowidesln kubectl get pods --watch -o=wide --show-labels --namespace
abbr -a -g kgdepwowidesln kubectl get deployment --watch -o=wide --show-labels --namespace
abbr -a -g kgwslowiden kubectl get --watch --show-labels -o=wide --namespace
abbr -a -g kgpowslowiden kubectl get pods --watch --show-labels -o=wide --namespace
abbr -a -g kgdepwslowiden kubectl get deployment --watch --show-labels -o=wide --namespace
