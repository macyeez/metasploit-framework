##
# This module requires Metasploit: http//metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

require 'msf/core'
require 'metasploit/framework/credential_collection'
require 'metasploit/framework/login_scanner/mybook_live'

class Metasploit3 < Msf::Auxiliary
  include Msf::Auxiliary::Scanner
  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::Report
  include Msf::Auxiliary::AuthBrute

  def initialize
    super(
      'Name'           => 'Western Digital MyBook Live Login Utility',
      'Description'    => 'This module simply attempts to login to a Western Digital MyBook Live instance using a specific user/pass.',
      'Author'         => [ 'Nicholas Starke <starke.nicholas[at]gmail.com>' ],
      'License'        => MSF_LICENSE
    )

    register_options(
      [
        Opt::RPORT(80)
      ], self.class)

    register_autofilter_ports([ 80 ])
    
    #username is hardcoded into application
    deregister_options('RHOST', 'USERNAME', 'USER_FILE', 'USER_AS_PASS', 'DB_ALL_USERS')
  end

  def run_host(ip)
    cred_collection = Metasploit::Framework::CredentialCollection.new(
            blank_passwords: datastore['BLANK_PASSWORDS'],
            pass_file: datastore['PASS_FILE'],
            password: datastore['PASSWORD'],
            username: 'admin'
    )

    scanner = Metasploit::Framework::LoginScanner::MyBookLive.new(
      host: ip,
      port: rport,
      proxies: datastore['PROXIES'],
      cred_details: cred_collection,
      stop_on_success: datastore['STOP_ON_SUCCESS'],
      connection_timeout: 10,
      user_agent: datastore['UserAgent'],
      vhost: datastore['VHOST']
    )

    if ssl
      scanner.ssl = datastore['SSL']
      scanner.ssl_version = datastore['SSLVERSION']
    end

    scanner.scan! do |result|
      credential_data = result.to_h
      credential_data.merge!(
          module_fullname: fullname,
          workspace_id: myworkspace_id
      )
      if result.success?
        credential_core = create_credential(credential_data)
        credential_data[:core] = credential_core
        create_credential_login(credential_data)

        print_good "#{ip}:#{rport} - LOGIN SUCCESSFUL: #{result.credential}"
      else
        invalidate_login(credential_data)
        print_status "#{ip}:#{rport} - LOGIN FAILED: #{result.credential} (#{result.status})"
      end
    end
  end
end
