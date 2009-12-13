class system::services {
   
    service { "httpd":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }
    
    service { "sendmail":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
    }  
}


class gitorious::services {

    file {"/etc/init.d/git-ultrasphinx":
        source => "/var/www/gitorious/doc/templates/centos/git-ultrasphinx",
        ensure => present,
        owner => "root",
        group => "root",
        mode => 755,
        require => [Notify["dependencies_done"], Exec["git_pull_gitorious"]]
    }

    service {"git-ultrasphinx":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        require => File["/etc/init.d/git-ultrasphinx"],
    }

    file {"/etc/init.d/git-daemon":
        source => "/var/www/gitorious/doc/templates/centos/git-ultrasphinx",
        ensure => present,
        owner => "root",
        group => "root",
        mode => 755,
        require => [Notify["dependencies_done"], Exec["git_pull_gitorious"]]
    }

    service {"git-daemon":
        ensure => running,
        enable => true,
        hasstatus => true,
        hasrestart => true,
        require => File["/etc/init.d/git-daemon"],
    }

    exec {"stompserver start &":
      command => "stompserver start &",
      cwd => "/root/",
      require => Service["git-daemon"],
    }

    exec { "script/poller":
      command => "script/poller start",
      cwd => "/var/www/gitorious",
      require => [Service["git-daemon"], File["/var/www/gitorious/tmp/pids"], Notify["gitorious_configured"]]
    }
}
