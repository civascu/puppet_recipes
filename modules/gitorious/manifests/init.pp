#deploy gitorious (http://www.gitorious.com) on a server
# based on [gitorious]/doc/recipes/centos5.2 document, with additions
#

import "utils.pp"
import "user.pp"
import "services.pp"
import "dependencies.pp"

class gitorious {

  $rpm_packages = ["gcc", "g++", "ruby", "rubygems"]

  package {$rpm_packages:
    ensure => installed,
    require =>Yumrepo["DAG"]
  }

}

class gitorious::base {

    include gitorious::user

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
        require => [File["/etc/pki/rpm-gpg/RPM-GPG-KEY-rpmforge-dag"]],
    }

    exec {"yum-update":
        command => "yum -y update",
        cwd => "/root/",
        refreshonly => true,
        subscribe => Yumrepo["DAG"],
        timeout => 20000,
    }
}

class gitorious::passenger {
    exec {"passenger-install-apache2-module":
        command => "passenger-install-apache2-module --auto",
        subscribe => Package["passenger"],
        creates => "/usr/lib/ruby/gems/1.8/gems/passenger-2.2.7/ext/apache2/mod_passenger.so",
        require => Notify["dependencies_done"],
    }

    file {"passenger.conf":
        path => "/etc/httpd/conf.d/passenger.conf",
        content => template("gitorious/passenger.conf.erb"),
        ensure => present,
        owner => "root",
        group => "root",
        require => Exec["passenger-install-apache2-module"],
        notify => Service["httpd"]
    }
}

class gitorious::main inherits gitorious::packages {
    include gitorious::passenger
    include system::services
    include gitorious::core
    include gitorious::config
    include gitorious::services
}


class gitorious::core {

    exec {"git_pull_gitorious":
        command => "git clone http://git.gitorious.org/gitorious/mainline.git gitorious",
        cwd => "/var/www",
        creates => "/var/www/gitorious",
        require => [Notify["dependencies_done"], User["git"]],
        timeout => "-1",
    }

    file { "/var/www/gitorious":
        ensure => directory,
        owner => "git",
        group => "git",
        recurse => true,
        require => Exec["git_pull_gitorious"]
    }

    file {"/usr/local/bin/gitorious":
        target => "/var/www/gitorious/script/gitorious",
        ensure => symlink,
        require => Exec["git_pull_gitorious"],
    }

    file {"/var/www/gitorious/public/.htaccess": 
        ensure => absent,
        require => Exec["git_pull_gitorious"],
    }
    
    file {"/var/www/gitorious/log": 
        ensure => directory,
        owner => "git",
        group => "git",
        recurse => true,
        require => Exec["git_pull_gitorious"],
    }
    file {"/var/www/gitorious/tmp": 
        ensure => directory,
        owner => "git",
        group => "git",
        recurse => true,
        require => Exec["git_pull_gitorious"],
    }

    file {"/var/www/gitorious/tmp/tarballs": 
        ensure => directory,
        owner => "git",
        group => "git",
        require => File["/var/www/gitorious/tmp"], 
    }

    file {"/var/www/gitorious/tmp/pids": 
        ensure => directory,
        owner => "git",
        group => "git",
        require => File["/var/www/gitorious/tmp"],
    }
}

class gitorious::config {
    $mysql_password="insfarsit"
    file {"/var/www/gitorious/config/database.yml":
        content => template("gitorious/database.yml.erb"),
        ensure => present,
        require => Exec["git_pull_gitorious"],
        owner => "git",
        group => "git",
    }

    file {"/var/www/gitorious/config/gitorious.yml":
        content => template("gitorious/gitorious.yml.erb"),
        ensure => present,
        owner => "git",
        group => "git",
        require => Exec["git_pull_gitorious"],
    }

    file {"/var/www/gitorious/config/broker.yml":
        content => template("gitorious/broker.yml.erb"),
        ensure => present,
        owner => "git",
        group => "git",
        require => Exec["git_pull_gitorious"],
    }

    $mail_server = "smtp.google.com"
    file {"/var/www/gitorious/config/environments/production.rb":
        content => template("gitorious/production.rb.erb"),
        ensure => present,
        require => Exec["git_pull_gitorious"],
    }

    exec {"create_db":
        command => "rake db:create RAILS_ENV=production",
        cwd => "/var/www/gitorious/",
        require => [Notify["dependencies_done"], Package["mysql-devel"], Package["rake"], File["/var/www/gitorious/config/database.yml"],File["/var/www/gitorious/config/gitorious.yml"]],

    }

    exec {"migrate_db":
        command => "rake db:migrate RAILS_ENV=production",
        cwd => "/var/www/gitorious/",
        path => "/usr/bin",
        require => [Notify["dependencies_done"], Package["mysql-devel"], Package["rake"], Exec["create_db"]],
        #TODO: figure out the unless condition; otherwise the db will get overwritten periodically
    }

    exec {"bootstrap_sphinx":
        command => "rake ultrasphinx:bootstrap RAILS_ENV=production",
        cwd => "/var/www/gitorious/",
        require => [Notify["dependencies_done"], Exec["create_db"]],
        notify => Service["httpd"],
    }

    notify {"gitorious_configured":
}
      message => "Finished configuring Gitorious",
      require => Exec["bootstrap_sphinx"],
    }
