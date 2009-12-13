define install_from_remote_tarball(
    $url="",
    $file="",
    $cwd="",
    $unless="",
    $build_string="./configure && make && make install",
    $timeout=300) {


    if $url != "" {
        download_file {"${name}.tar.gz":
            site => $url,
            cwd => $cwd,
            unless => $unless,
            timeout => $timeout
        }
    } else {
        file { "${cwd}/${name}.tar.gz":
            source => $file,
            owner => root,
            group => root,
            ensure => present,
        }
    }

    exec { "untar_${name}":
        command => "tar -xzf ${name}.tar.gz",
        cwd => $cwd,
        creates => "${cwd}/${name}",
        refreshonly => true,
        subscribe => Download_file["${name}.tar.gz"],
        timeout => $timeout,
    }

    exec {"build_${name}":
        command => $build_string,
        cwd => "${cwd}/${name}/",
        refreshonly => true,
        subscribe => Exec["untar_${name}"],
        timeout => $timeout,
    }
}

define line($file, $line, $ensure = 'present') {
   case $ensure {
      default : { err ( "unknown ensure value ${ensure}" ) }
      present: {
         exec { "/bin/echo '${line}' >> '${file}'":
            command => "/bin/echo '${line}' >> '${file}'",
            unless => "/bin/grep -qFx '${line}' '${file}'"
         }
      }
      absent: {
         exec { "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'":
            command => "/usr/bin/perl -ni -e 'print unless /^\\Q${line}\\E\$/' '${file}'",
            onlyif => "/bin/grep -qFx '${line}' '${file}'"
         }
      }
   }
}

 define download_file(
         $site="",
         $cwd="",
         $unless="",
         $timeout = 300) {

     exec { $name:
         command => "wget ${site} -O ${name}",
         cwd => $cwd,
         creates => "${cwd}/${name}",
         timeout => $timeout,
         unless => $unless
     }

 }

