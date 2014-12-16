module Dradis
  module Plugins
    module Nikto
    end
  end
end

require 'dradis/plugins/nikto/engine'
require 'dradis/plugins/nikto/field_processor'
require 'dradis/plugins/nikto/importer'
require 'dradis/plugins/nikto/version'

# This is required while we transition the Upload Manager to use
# Dradis::Plugins only
module Dradis
  module Plugins
    module Nikto
      module Meta
        NAME = "Nikto XML upload plugin"
        EXPECTS = "Nikto results XML. Use the -o switch with a file name ending in .xml"
        module VERSION
          include Dradis::Plugins::Nikto::VERSION
        end
      end
    end
  end
end
