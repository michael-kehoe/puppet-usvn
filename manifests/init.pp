class usvn ($basepath = "/var/www",
	    $svnpath = "/var/www/usvn/files",
	    $viewvc = "false",
	    $managedb = true,
	    $dbserver = "localhost",
	    $dbuser,
	    $dbpassword,
	    $dbname = "usvn")  {

	#Install packages
	package { "subversion":
		ensure => installed;
	}
	
	#install ViewVC
	if($viewvc == true) {
		package { "viewvc":
			ensure => installed;
		}
		file { "viewvc_config":
                	path   => "/etc/viewvc/viewvc.conf",
                	owner  => root,
                	group  => root,
                	mode   => 644,
                	content => template("usvn/viewvc.conf.erb"),
                	require => Package['viewvc'],
        	}
	}

	# Specify dependencies
  	Class['mysql::server'] -> Class['usvn']
  	Class['mysql::config'] -> Class['usvn']
	
	#Enable apache modules
	#include apache::mod::prefork
	#include apache::mod::php
        include apache::mod::rewrite
        include apache::mod::dav_svn
	include apache::mod::dav	
	apache::mod { 'authz_svn':
		lib  => "mod_authz_svn.so",
	}		
	
#	if($managedb == 'true') {
		mysql::db { 'usvn':
  			user     =>  $dbuser,
  			password => $dbpassword,
  			host     => 'localhost',
  			grant    => ['all'],
		}
#	}
	
	#Create apache-vhost(s)
	apache::vhost { "usvn.${fqdn}":
                port        => '80',
		override => ['All'],
                options => '+SymLinksIfOwnerMatch',
		docroot => "$basepath/usvn/public",
		docroot_owner => "www-data",
	}

	apache::vhost { "svn.${fqdn}":
		port => 80,
		docroot => "$basepath/usvn/files/svn",
	 	#aliases =>  [{ alias => '/', path => '/$basepath/usvn/files/svn'}]	
		custom_fragment => template("${module_name}/svn.erb"),
		docroot_owner => "www-data",
	}
	
	exec { "download":
		command => "/usr/bin/git clone https://github.com/usvn/usvn.git usvn",
		cwd => "$basepath",
		creates => "$basepath/usvn/public/index.php",
	}
	
	file { "$basepath/usvn/config":
		ensure => directory,
		owner => www-data,
	}

	file { "$basepath/usvn/files":
		ensure => directory,
		owner => www-data,
	}
	
}
