# Yum

[![Build Status](https://travis-ci.org/voxpupuli/puppet-yum.png?branch=master)](https://travis-ci.org/voxpupuli/puppet-yum)

## Module description

This module provides helpful definitions for dealing with *yum*.

### Requirements

Module has been tested on:

* Puppet 4.6.1 and newer
* CentOS 6, 7

## Usage

### Manage global Yum configuration via the primary class

```puppet
class { 'yum':
  keep_kernel_devel => false|true,
  clean_old_kernels => false|true,
  config_options    => {
      my_cachedir => {
        ensure => '/home/waldo/.local/yum/cache',
        key    => 'cachedir',
      },
      gpgcheck    => true,
      debuglevel  => 5,
      assumeyes   => {
        ensure => 'absent',
      },
    },
  },
}
```

NOTE: The `config_options` parameter takes a Hash where keys are the names of `Yum::Config` resources and the values are either the direct `ensure` value (`gpgcheck` or `debuglevel` in the example above), or a Hash of the resource's attributes (`my_cachedir` or `assumeyes` in the example above).  Values may be Strings, Integers, or Booleans.  Booleans will be converted to either a `1` or `0`; use a quoted string to get a literal `true` or `false`.

If `installonly_limit` is changed, purging of old kernel packages is triggered if `clean_old_kernels` is `true`.

### Manage yum.conf entries via defined types

```puppet
yum::config { 'installonly_limit':
  ensure => 2,
}

yum::config { 'debuglevel':
  ensure => absent,
}
```

### Manage a custom repo via Hiera data

Using Hiera and automatic parameter lookup (APL), this module can manage Yumrepos.  The `repos` parameter takes a hash of hashes, where the first-level keys are the `Yumrepo` resource names and their value hashes contain parameters and values to feed into the resource definition. **On its own, the `repos` parameter does nothing.**  The resource names from the hash must be selected via the `managed_repos` parameter.  This example defines a custom repo.

First, include the class.

```puppet
include 'yum'
```

In Hiera data, add the name of the repo to the `yum::managed_repos` key (an Array), and define the repo in the `yum::repos` key:

```yaml
---
yum::managed_repos:
    - 'example_repo'
yum::repos:
    example_repo:
        ensure: 'present'
        enabled: true
        descr: 'Example Repo'
        baseurl: 'https://repos.example.com/example/'
        gpgcheck: true
        gpgkey: 'file:///etc/pki/gpm-gpg/RPM-GPG-KEY-Example'
        target: '/etc/yum.repos.d/example.repo'
```

### Enable management of one of the pre-defined repos

This module includes several pre-defined Yumrepos for easy management.  This example enables management of the EPEL repository using its default settings.

**NOTE:** This only works if the data for the repository is included with the module.  Please see the `/data` directory of this module for a list of available repos.

```puppet
include 'yum'
```

```yaml
---
yum::managed_repos:
    - 'epel'
```

### Enable management of one of the pre-defined repos AND modify its settings

Here the Extras repository for CentOS is enabled and its settings are modified.  Because the `repos` parameter uses a deep merge strategy when fed via automatic parameter lookup (APL), only the values requiring modification need be defined.

By default, `mirrorlist` contains some data, and `baseurl` is undefined.  To undefine the `mirrorlist`, we pass it the *knockout prefix*, `--`.  This works with any key.

**NOTE:** This only works if the data for the repository is included with the module.  Please see the `/data` directory of this module for a list of available repos.

```puppet
include 'yum'
```

```yaml
---
yum::managed_repos:
    - 'extras'
yum::repos:
    extras:
        enabled: true
        baseurl: 'https://mirror.example.com/extras'
        mirrorlist: '--'
```

### Enable managemnt of multiple repos

The `managed_repos` parameter uses the `unique` Hiera merge strategy, so it's possible to define repos to be managed at multiple levels of the hierarchy.  For example, given the following hierarchy and the following two yaml files, the module would receive the array `['base', 'extras', 'debug']`.

```yaml
---
hierarchy:
    - name: 'Common'
      paths:
        - "%{trusted.certname}"
        - 'common.yaml'
```

```yaml
---
# node01
yum::managed_repos:
    - 'base'
    - 'debug'
```

```yaml
# common
yum::managed_repos:
    - 'base'
    - 'extras'
```

### Negate previously enabled repos

The `repo_exclusions` parameter is used to *exclude* repos from management.  It is mainly useful in complex Hiera hierarchies where repos need to be removed from a baseline.  Here we define a baseline set of repos in `common.yaml`, but disable one of them for a specific node.

```yaml
---
hierarchy:
    - name: 'Common'
      paths:
        - "%{trusted.certname}"
        - 'common.yaml'
```

```yaml
---
# node01
yum::repo_exclusions:
    - 'updates' #yolo
```

```
---
# common
yum::managed_repos:
    - 'base'
    - 'updates'
    - 'extras'
```

### Enable management of the default OS Yumrepos

This module includes the boolean helper parameter `manage_os_default_repos` easily select select OS repos.  It uses module data to add the appropriate repos to the `managed_repos` parameter based on OS facts.  Just like adding them manually, they can be negated via the `repo_exclusions` parameter.

**NOTE:** This only works for operating systems who's Yumrepos are defined in the module's data AND who's default repos are defined in the module's data.

On a CentOS 7 machine these two snippets are functionally equivalent.

```puppet
class { 'yum':
  manage_os_default_repos => true,
}
```

```puppet
class { 'yum':
  managed_repos => [
    'base',
    'updates',
    'extras',
    'centosplus',
    'base-source',
    'updates-source',
    'extras-source',
    'base-debuginfo',
    'centos-media',
    'cr',
  ]
}
```

### Add/remove a GPG RPM signing key using an inline key block


```puppet
yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-puppet-smoketest1':
  ensure  => present,
  content => '-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----',
}
```

### Add/remove a GPGP RPM signing key using a key stored on a Puppet fileserver

```puppet
yum::gpgkey { '/etc/pki/rpm-gpg/RPM-GPG-KEY-elrepo.org':
  ensure => present,
  source => 'puppet:///modules/elrepo/RPM-GPG-KEY-elrepo.org',
}
```

### Install or remove *yum* plugin

```puppet
yum::plugin { 'versionlock':
  ensure => present,
}
```

### Lock a package with the *versionlock* plugin

Locks explicitly specified packages from updates. Package name must be precisely specified in format *`EPOCH:NAME-VERSION-RELEASE.ARCH`*. Wild card in package name is allowed provided it does not span a field seperator.

```puppet
yum::versionlock { '0:bash-4.1.2-9.el6_2.*':
  ensure => present,
}
```

Use the following command to retrieve a properly-formated string:

```sh
PACKAGE_NAME='bash'
rpm -q "$PACKAGE_NAME" --qf '%|EPOCH?{%{EPOCH}}:{0}|:%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}\n'
```

### Install or remove *yum* package group

```puppet
yum::group { 'X Window System':
  ensure  => present,
  timeout => 600,
}
```

### Install or remove packages via `yum install`

This is a workaround for [PUP-3323](https://tickets.puppetlabs.com/browse/PUP-3323).  It enables the installation of packages from non-repo sources while still providing dependency resolution.  For example, say there is a package *foo* that requires the package *bar*.  *bar* is in a Yum repository and *foo* is stored on a stand-alone HTTP server.  Using the standard providers for the `Package` resource type, `rpm` and `yum`, the `rpm` provider would be required to install *foo*, because only it can install from a non-repo source, i.e., a URL.  However, since the `rpm` provider cannot do dependency resolution, it would fail on its own unless *bar* was already installed.  This workaround enables *foo* to be installed without having to define its dependencies in Puppet.

From URL:

```puppet
yum::install { 'package-name':
  ensure => present,
  source => 'http://example.com/path/to/package/filename.rpm',
}
```

From local filesystem:

```puppet
yum::install { 'package-name':
  ensure => present,
  source => 'file:///path/to/package/filename.rpm',
}
```

Please note that resource name must be same as installed package name.

---

This module was donated by CERIT Scientific Cloud, <support@cerit-sc.cz> to Vox Pupuli
