# rcip-openshift-scripts

## monitoring-plugins
Check compatible with Sensu, nagios ...

##openshift/check_openshift.py

Use token to request openshift api (/api/v1beta3/)  with Oauth.
If you didn't have token, use user/pass to perform an "oc login" and get a token.

3 checks are available
  * check_nodes : Request status of nodes through openshift API
  * check_pods : Request status of pods (with deployconfig : docker-registry and router)
  * check_regions : Request regions affected on nodes and return warning if it's  match to your "OFFLINE" region
  * check_scheduling : Find if your nodes have the unschedulable flag (SchedulingDisabledà.

Script help

```bash
usage: check_openshift.py [-h] [-proto PROTOCOL] [-api BASE_API] [-H HOST]
                          [-P PORT] [-u USERNAME] [-p PASSWORD] [-to TOKEN]
                          [-tf TOKENFILE] [--check_nodes] [--check_pods]
                          [--check_scheduling] [--check_labels]
                          [--label_offline LABEL_OFFLINE] [-v]

Openshift check pods

optional arguments:
  -h, --help            show this help message and exit
  -proto PROTOCOL, --protocol PROTOCOL
                        Protocol openshift (Default : https)
  -api BASE_API, --base_api BASE_API
                        Url api and version (Default : /api/v1/)
  -H HOST, --host HOST  Host openshift (Default : 127.0.0.1)
  -P PORT, --port PORT  Port openshift (Default : 8443)
  -u USERNAME, --username USERNAME
                        Username openshift (ex : sensu)
  -p PASSWORD, --password PASSWORD
                        Password openshift
  -to TOKEN, --token TOKEN
                        File with token openshift (like -t)
  -tf TOKENFILE, --tokenfile TOKENFILE
                        Token openshift (use token or user/pass
  --check_nodes         Check status of all nodes
  --check_pods          Check status of pods ose-haproxy-router and ose-
                        docker-registry
  --check_scheduling    Check if your nodes is in SchedulingDisabled stat.
                        Only warning
  --check_labels        Check if your nodes have your "OFFLINE" label. Only
                        warning (define by --label_offline)
  --label_offline LABEL_OFFLINE
                        Your "OFFLINE" label name (Default: retiring)
  -v, --version         Print script version
```

We suggest to use a permanant token from a ServiceAccount. Exemple on how create one

```bash
echo '{
  "apiVersion": "v1",
  "kind": "ServiceAccount",
  "metadata": {
    "name": "metrics"
  }
}' > metricsSA.json
 
oc create -f metricsSA.json

oc describe serviceaccount metrics
oc describe secret metrics-token-bsd4v

oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:metrics
```

For retiring label we suggest to use this predicates line

```bash
{
  "predicates": [
    {"name": "MatchNodeSelector"},
    {"name": "PodFitsResources"},
    {"name": "PodFitsPorts"},
    {"name": "NoDiskConflict"},
    {"name": "Region", "argument": {"serviceAffinity" : {"labels" : ["region"]}}},
    {"name" : "RequireRegion", "argument" : {"labelsPresence" : {"labels" : ["retiring"], "presence" : false}}}
  ],"priorities": [
    {"name": "LeastRequestedPriority", "weight": 1},
    {"name" : "BalancedResourceAllocation", "weight" : 1},
    {"name": "ServiceSpreadingPriority", "weight": 1}
  ]
}
```

And when you need, add the retiring label

```bash
oc edit node mynode
```
##network/check_arp_incomplete.sh

Check if we have some incomplete ARP

Script help

```bash
check_arp_incomplete.sh 1.0 (c) 2015 Florian Lambert (flambert@redhat.com)

Usage: check_arp_incomplete.sh -i

-h Show this page
-v Script version
-i --incomplete check if we have incomplete ARP
```

Script exemples

```bash
bash check_arp_incomplete.sh -i
ARP OK : 0 incomplete

bash check_arp_incomplete.sh -i
CRITICAL OK : 3 incomplete
```

##openshift/check_openshift_rsh.py

Script help
```bash
check_openshift_rsh.py -h
usage: check_openshift_rsh.py [-h] [-proto {http,https}] [-api BASE_API]
                              [-H HOST] [-P PORT] [-pn PODNAME] [-n NAMESPACE]
                              [-w WARNING] [-c CRITICAL] [-u USERNAME]
                              [-p PASSWORD] [-to TOKEN] [-tf TOKENFILE]
                              [--check_df] [-v]

Openshift check pods

optional arguments:
  -h, --help            show this help message and exit
  -proto {http,https}, --protocol {http,https}
                        Protocol openshift (Default : https)
  -api BASE_API, --base_api BASE_API
                        Url api and version (Default : /api/v1)
  -H HOST, --host HOST  Host openshift (Default : 127.0.0.1)
  -P PORT, --port PORT  Port openshift (Default : 8443)
  -pn PODNAME, --podname PODNAME
                        begining of the pods name
  -n NAMESPACE, --namespace NAMESPACE
                        Namespace
  -w WARNING, --warning WARNING
                        Warning value (Default : 85)
  -c CRITICAL, --critical CRITICAL
                        Critical value (Default : 95)
  -u USERNAME, --username USERNAME
                        Username openshift (ex : sensu)
  -p PASSWORD, --password PASSWORD
                        Password openshift
  -to TOKEN, --token TOKEN
                        File with token openshift (like -t)
  -tf TOKENFILE, --tokenfile TOKENFILE
                        Token openshift (use token or user/pass
  --check_df            Check disk usage in the pod
  -v, --version         Print script version

```

###Pre-requisite

A valide kubeconfig need to be present in /root/.kube/config

And allow to exec this script in sudoer file 

```bash
ansible monitoring -m lineinfile -a "line='sensu ALL=(root) NOPASSWD: /usr/bin/python /opt/rcip-openshift-scripts/monitoring-plugins/check_openshift_rsh.py *' dest=/etc/sudoers.d/sensu create=yes"
```

##check_disk.py

Parse the output of df command and check the disk and inode usage of each mounted volumes

Script help

```bash
python check_disk.py -h
usage: check_disk.py [-h] [-b BASE] [-e EXCLUDES [EXCLUDES ...]] [-w WARNING]
                     [-c CRITICAL] [-v]

Disk check recurcive

optional arguments:
  -h, --help            show this help message and exit
  -b BASE, --base BASE  base directory to monitor. For example if you want to
                        monitor only volume mounted under /host/ (Default: /)
  -e EXCLUDES [EXCLUDES ...], --excludes EXCLUDES [EXCLUDES ...]
                        List of mountpoint to recurcively exclude ex:
                        /var/lib/origin /var/lib/docker
  -w WARNING, --warning WARNING
                        Warning value (Default: 85)
  -c CRITICAL, --critical CRITICAL
                        Critical value (Default: 95)
  -v, --version         Print script version
```
