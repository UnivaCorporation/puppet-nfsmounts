class nfsmounts(
  Hash[Stdlib::Unixpath, Hash] $mounts,
  String $mountpoint_pkg) {

  if defined('$tortuga_kit_uge::execd::svcname') and
    defined(Service[$tortuga_kit_uge::execd::svcname]) {
    Mount <| tag == 'nfsmounts' |> -> Service <| title == $tortuga_kit_uge::execd::svcname |>
    Systemd::Dropin_file <| tag == 'nfsmounts' |> -> Service <| title == $tortuga_kit_uge::execd::svcname |>
  }

  if defined('$tortuga_kit_uge::qmaster::svcname') and
    defined(Service[$tortuga_kit_uge::qmaster::svcname]) {
    Mount <| tag == 'nfsmounts' |> -> Service <| title == $tortuga_kit_uge::qmaster::svcname |>
    Systemd::Dropin_file <| tag == 'nfsmounts' |> -> Service <| title == $tortuga_kit_uge::qmaster::svcname |>
  }

  # the mount resource has moved to agent in Puppet 6
  # might (not!) require separate installation of
  # https://forge.puppet.com/puppetlabs/mount_core/readme
  $mounts.each |$dir, $opts| {
    # Owner of the mount point
    if has_key($opts, "mount_user") {
      $user = $opts["mount_user"]
      $opts_1 = $opts.delete("mount_user")
    } else {
      $user = "root"
      $opts_1 = $opts
    }

    # Owner of the files in the mounted filesystem
    if has_key($opts, "data_user") {
      $data_user = $opts["data_user"]
      $opts_2 = $opts_1.delete("data_user")
    } else {
      $data_user = ""
      $opts_2 = $opts_1
    }

    # Group of the mount point
    if has_key($opts, "mount_group") {
      $group = $opts["mount_group"]
      $opts_3 = $opts_2.delete("mount_group")
    } else {
      $group = "root"
      $opts_3 = $opts_2
    }

    # Group of the files in the moutned filesystem
    if has_key($opts, "data_group") {
      $data_group = $opts["data_group"]
      $opts_4 = $opts_3.delete("data_group")
    } else {
      $data_group = ""
      $opts_4 = $opts_3
    }

    # Perms of the mount point
    if has_key($opts, "mount_perms") {
      $perms = $opts["mount_perms"]
      $opts_5 = $opts_4.delete("mount_perms")
    } else {
      $perms = "0755"
      $opts_5 = $opts_4
    }

    # Perms on the files in the mounted filesystem
    if has_key($opts, "data_perms") {
      $data_perms = $opts["data_perms"]
      $opts_6 = $opts_5.delete("data_perms")
    } else {
      $data_perms = ""
      $opts_6 = $opts_5
    }

    $opts_final = $opts_6

    # Create the directory, recursively
    exec { "create ${dir}":
      user    => "root",
      command => "mkdir -p ${dir}",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
      creates => $dir,
    }

    # Set the ownership and perms on the directory
    file { $dir:
      ensure => directory,
      owner  => $user,
      group  => $group,
      mode   => $perms,
      require => Exec["create ${dir}"],
    }

    # Mount the filesystem
    mount { $dir:
      *       => $opts_final,
      require => File[$dir],
    }

    # Set the data ownership if required
    if $data_user != "" or $data_group != "" {
      exec { "set ${dir} owner":
        user    => "root",
        command => "chown -R ${data_user}:${data_group} ${dir}/* && touch ${dir}/.data_user_complete",
        path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
        creates => "${dir}/.data_user_complete",
        onlyif  => "ls ${dir}/*",
        require => Mount[$dir],
      }
    }

    # Set the data perms if required
    if $data_perms != "" {
      exec { "set ${dir} perms":
        user    => "root",
        command => "chmod -R ${data_perms} ${dir}/* && touch ${dir}/.data_perms_complete",
        path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
        creates => "${dir}/.data_perms_complete",
        onlyif  => "ls ${dir}/*",
        require => Mount[$dir],
      }
    }

  }

  ensure_packages([$mountpoint_pkg])

  file { '/usr/local/bin/test-uge-mounts':
    ensure  => present,
    content => template("${module_name}/test-uge-mounts.erb"),
    owner   => root,
    group   => root,
    mode    => '0755',
    require => Package[$mountpoint_pkg],
  }

  $execd_service = 'sgeexecd.tortuga.service'
  $qmaster_service = 'sgemaster.tortuga.service'

  systemd::dropin_file { 'execd-test-mounts.conf':
    unit    => $execd_service,
    source  => "puppet:///modules/${module_name}/test-mounts.conf",
    require => File['/usr/local/bin/test-uge-mounts'],
  }

  systemd::dropin_file { 'qmaster-test-mounts.conf':
    unit    => $qmaster_service,
    source  => "puppet:///modules/${module_name}/test-mounts.conf",
    require => File['/usr/local/bin/test-uge-mounts'],
  }
}
