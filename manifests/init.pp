class nfsmounts(
  Hash[Stdlib::Unixpath, Hash] $mounts,
  String $mountpoint_pkg) {

  Exec <| tag == 'nfsmounts' |> -> Mount <| tag == 'nfsmounts' |>

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
    exec { "create ${dir}":
      user    => root,
      command => "mkdir -m 0755 -p ${dir}",
      path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
      creates => $dir,
    }

    mount { $dir:
      * => $opts
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
