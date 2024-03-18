module Dradis::Plugins::Nikto
  module Mapping
    DEFAULT_MAPPING = {
      evidence: {
        'Request' => 'Request Method: {{ nikto[item.request_method] }}',
        'Links' => "Link: {{ nikto[item.namelink] }}\n
                    IP Based Link: {{ nikto[item.iplink] }}"
      },
      item: {
        'Title' => '{{ nikto[item.description] }}',
        'Details' => '{{ nikto[item.description] }}',
        'References' => '{{ nikto[item.references] }}'
      },
      scan: {
        'Title' => 'Nikto upload: {{ nikto[scan.filename] }}',
        'Details' => "IP: {{ nikto[scan.targetip] }}\n
                      Hostname: {{ nikto[scan.targethostname] }}\n
                      Port: {{ nikto[scan.targetport] }}\n
                      Banner: {{ nikto[scan.targetbanner] }}\n
                      Starttime: {{ nikto[scan.starttime] }}\n
                      Site Name: {{ nikto[scan.sitename] }}\n
                      Site IP: {{ nikto[scan.siteip] }}\n
                      Host Header: {{ nikto[scan.hostheader] }}\n
                      Errors: {{ nikto[scan.errors] }}\n
                      Total Checks: {{ nikto[scan.checks] }}"
      },
      ssl: {
        'Title' => 'SSL Cert Information',
        'Details' => "Ciphers: {{ nikto[ssl.ciphers] }}\n
                      Issuers: {{ nikto[ssl.issuers] }}\n
                      Info: {{ nikto[ssl.info] }}"
      }
    }.freeze
  end
end
