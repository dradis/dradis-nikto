module Dradis::Plugins::Nikto
  module Mapping
    DEFAULT_MAPPING = {
      evidence: {
        'Request' => 'Request Method: {{ nikto[item.request_method] }}',
        'Links' => "Link: {{ nikto[item.namelink] }}\nIP Based Link: {{ nikto[item.iplink] }}"
      },
      item: {
        'Title' => '{{ nikto[item.description] }}',
        'Details' => '{{ nikto[item.description] }}',
        'References' => '{{ nikto[item.references] }}'
      },
      scan: {
        'Title' => 'Nikto upload: {{ nikto[scan.filename] }}',
        'Details' => "IP: {{ nikto[scan.targetip] }}\nHostname: {{ nikto[scan.targethostname] }}\nPort: {{ nikto[scan.targetport] }}\nBanner: {{ nikto[scan.targetbanner] }}\nStarttime: {{ nikto[scan.starttime] }}\nSite Name: {{ nikto[scan.sitename] }}\nSite IP: {{ nikto[scan.siteip] }}\nHost Header: {{ nikto[scan.hostheader] }}\nErrors: {{ nikto[scan.errors] }}\nTotal Checks: {{ nikto[scan.checks] }}"
      },
      ssl: {
        'Title' => 'SSL Cert Information',
        'Details' => "Ciphers: {{ nikto[ssl.ciphers] }}\nIssuers: {{ nikto[ssl.issuers] }}\nInfo: {{ nikto[ssl.info] }}"
      }
    }.freeze

    SOURCE_FIELDS = {
      evidence: [
        'item.request_method',
        'item.uri',
        'item.namelink',
        'item.iplink'
      ],
      item: [
        'item.description',
        'item.id',
        'item.iplink',
        'item.namelink',
        'item.osvdbid',
        'item.osvdblink',
        'item.references',
        'item.request_method',
        'item.uri'
      ],
      scan: [
        'scan.filename',
        'scan.targetip',
        'scan.targethostname',
        'scan.targetport',
        'scan.targetbanner',
        'scan.starttime',
        'scan.sitename',
        'scan.siteip',
        'scan.hostheader',
        'scan.errors',
        'scan.checks'
      ],
      ssl: [
        'ssl.ciphers',
        'ssl.issuers',
        'ssl.info'
      ]
    }.freeze
  end
end
