# Installation

```
puppet module install <tarball_of_this_repo>
```

or unpack module directly to
`/etc/puppetlabs/code/environments/production/modules/nfsmounts`.

## Usage

Create a YAML file named

```
/etc/puppetlabs/code/environments/production/data/tortuga-<CLUSTER-PROFILE>.yaml
```

where <CLUSTER-PROFILE> is the uid of the cluster profile obtained from
`navopsctl get clusterprofiles`. Follow the file and mount resource parameters
from

* https://puppet.com/docs/puppet/5.5/types/file.html
* https://puppet.com/docs/puppet/5.5/types/mount.html

to add contents like:

```
classes:
  - nfsmounts

nfsmounts::mounts:
  '/tmp/tasty/yummy':
    device: hostname-that-doesnt-exist.notadomain:/really/not/a/path
    ensure: unmounted
    fstype: nfs
    options: defaults,ro
```
