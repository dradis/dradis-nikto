module Dradis
  module Plugins
    module Nikto
      class Engine < ::Rails::Engine
        isolate_namespace Dradis::Plugins::Nikto

        include ::Dradis::Plugins::Base
        description 'Processes Nikto output'
        provides :upload
      end
    end
  end
end
