class gitorious::user {
  package {"ruby-shadow":
    ensure => installed,
  }

  user { "git":
        ensure  => "present",
        comment => "Gitorious user",
        home    => "/home/git",
        shell   => "/bin/bash",
        managehome => true,
        password => '$1$5dZQgQSq$POqlSWnuiYZ7d1VXfgXGo.',
        require => Package["ruby-shadow"]
    }

    file { "/home/git/.ssh":
        ensure => directory,
        owner => "git",
        group => "git",
        mode => 700,
        require => User["git"]
    }

    file {"/home/git/.ssh/authorized_keys":
        ensure => present,
        owner => git,
        group => git,
        mode => 600,
        require => File["/home/git/.ssh"],
    }

#    line {"export RUBY_HOME=/opt/ruby-enterprise":
#        file => "/home/git/.bash_profile",
#        line => "export RUBY_HOME=/opt/ruby-enterprise",
#        ensure => "present",
#        require => User["git"],
#    }

#    line {"export GEM_HOME=$RUBY_HOME/lib/ruby/gems/1.8/gems":
#        file => "/home/git/.bash_profile",
#        line => "export GEM_HOME=$$RUBY_HOME/lib/ruby/gems/1.8/gems",
#        ensure => "present",
#        require => User["git"],
#    }

#    line {"export PATH=$RUBY_HOME/bin:$PATH":
#        file => "/home/git/.bash_profile",
#        line => "export PATH=$RUBY_HOME/bin:$PATH",
#        ensure => "present",
#        require => User["git"],
#    }
}
