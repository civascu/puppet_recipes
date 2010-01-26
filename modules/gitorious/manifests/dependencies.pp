class gitorious::packages {
    include gitorious::rpm_packages
    include gitorious::gem_packages
    include gitorious::source_packages
}
class gitorious::depends {

    file {"/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag":
        ensure => present,
        source => "puppet:///gitorious/keys/RPM-GPG-KEY-rpmforge-dag",
        owner => "root",
        group => "root",
    }

    yumrepo { "DAG":
        descr => "RPMforge.net - dag",
        baseurl => absent,
        mirrorlist => "http://apt.sw.be/redhat/el5/en/mirrors-rpmforge",
        enabled => "1",
        gpgkey => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag",
        gpgcheck => "1",
        priority => 1,
        require => File["/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag"],
    }

    exec {"yum-update":
        command => "yum -y update",
        cwd => "/root/",
        refreshonly => true,
        subscribe => Yumrepo["DAG"],
        timeout => 20000,
    }

    $package_list = ["ruby-devel", "apg", "httpd-devel", "sqlite-devel", "libjpeg-devel", "readline-devel", "curl-devel", "pcre-devel", "zlib-devel", "openssl-devel", "libyaml-devel", "gcc", "gcc-c++", "autoconf", "automake", "rubygems", "mysql", "mysql-devel", "mysql-server", "git", "ruby-mysql", "httpd"]

    package {$package_list:
      ensure => installed,
      require => [Yumrepo["DAG"], Exec["yum-update"]],
    } 
    
    service { "mysqld":
        ensure => "running",
        require => Package[$package_list],
        enable => true,
    }


    $mysql_password = "insfarsit"
    exec { "Change_MySQL_server_root_password":
        # subscribe => [ Package["mysql-server"], Package["mysql-devel"], Service["mysqld"]],
        # refreshonly => true,
        unless => "mysqladmin -uroot -p$mysql_password status",
        path => "/bin:/usr/bin",
        command => "mysqladmin -uroot password $mysql_password",
        require => Service["mysqld"],
    }


    line { "export_LD_LIBRARY_PATH":
        file => "/etc/profile",
        line => "export LD_LIBRARY_PATH=\"/usr/local/lib\"",
        ensure => present,
    }

    line { "export_LDFLAGS":
        file => "/etc/profile",
        line => "export LDFLAGS=\"-L/usr/local/lib -Wl,-rpath,/usr/local/lib\"",
        ensure => present,
    }

    file {"/etc/ld.so.conf.d/gitorious.conf":
        path => "/etc/ld.so.conf.d/gitorious.conf",
        source => "puppet:///gitorious/gitorious.conf",
        owner => "root",
        group => "root",
    }

    exec {"ldconfig":
        command => "ldconfig",
        cwd => "/root/",
        refreshonly => true,
        require => Package[$package_list],
        subscribe => [File["/etc/ld.so.conf.d/gitorious.conf"]],
    }

    install_from_remote_tarball { "onig-5.9.1":
        url => "http://www.geocities.jp/kosako3/oniguruma/archive/onig-5.9.1.tar.gz",
        cwd => "/root/",
        #unless => "less /usr/local/include/oniguruma.h",
        require => [Exec["ldconfig"], Package[$package_list]],
    }

    install_from_remote_tarball {"sphinx-0.9.8":
        url => "http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz",
        cwd => "/root/",
        #unless => "less /usr/local/etc/sphinx.conf.dist",
        require => [Exec["ldconfig"], Package[$package_list]],
    }

    install_from_remote_tarball {"ImageMagick-6.5.8-4":
        url => "ftp://ftp.imagemagick.net/pub/ImageMagick/ImageMagick-6.5.8-4.tar.gz",
        cwd => "/root/",
        unless => "which imagemagick",
        timeout => "-1",
        require => [Exec["ldconfig"], Package[$package_list]],
    }

  exec {"gem_update":
    command => "gem update --system",
    cwd => "/root",
    timeout => "-1",  
  }
  $gems = ["mime-types", "oniguruma", "textpow", "chronic", "facter", "puppet", "BlueCloth", "ruby-yadis", "ruby-openid", "rmagick", "geoip", "ultrasphinx", "rspec", "rspec-rails", "RedCloth", "daemons",  "diff-lcs", "highline", "fastthread", "hoe", "oauth","rack", "rake", "ruby-hmac"]

  package {$gems:
    ensure => installed,
    provider => gem,
    require => [Package[$package_list], Install_from_remote_tarball["onig-5.9.1"], Install_from_remote_tarball["sphinx-0.9.8"], Install_from_remote_tarball["ImageMagick-6.5.8-4"], Exec["gem_update"]]
  } 

  package {"echoe":
    provider => gem,
    ensure =>"3.2",
    require => Package[$gems],
  }

  package {"rdiscount":
    ensure => "1.3.1.1",
    provider => gem,
    require => Package[$gems]
  }

  package {"stomp":
    ensure => "1.1",
    provider => gem,
    require => Package[$gems]
  }

  package { "passenger":
    ensure => "2.2.7",
    provider => gem,
    require => Package[$gems],
  }

  exec {"install_json":
    command => "gem install json",
    cwd => "/root/",
    require => Package[$gems] 
  }

  notify {"dependencies_done":
    message => "Gitorious dependencies installed. moving on",
    require => [Package[$gems], Package["stomp"], Package["rdiscount"], Exec["install_json"], Package["echoe"], Package["passenger"]],
  }
}
