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

Optional attributes can be added to set the ownership/permisisons on the mount point, and perform a one-time (recursive) setting of the ownership/permissions of the mounted files. This can be done by adding one or more of the following attributes to the previous example:

```
classes:
  - nfsmounts

nfsmounts::mounts:
  '/tmp/tasty/yummy':
    user: tasty-user
    group: yummy-group
    perms: 0755
    data_user: tasty-user
    data_group: yummy-group
    data_perms: 0755
    device: hostname-that-doesnt-exist.notadomain:/really/not/a/path
    ensure: unmounted
    fstype: nfs
    options: defaults,ro
```

The setting of data ownership will create an empty flag file called `.data_owner_complete` at the root of the filesystem. The setting of data perms will create an empty file called `.data_perms_complete` at the root of the mounted filesystem. If none of the `data_*` options were specified, these files will not be created. Otherwise, the presence of these files ensures that the chown/chmod operations are only completed once. If you would like to have the owernship or perms set again, simply delete the appropriate flag file and trigger a run of puppet agent. 