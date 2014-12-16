module Dradis
  module Plugins
    module Nikto
      class FieldProcessor < Dradis::Plugins::Upload::FieldProcessor

        def post_initialize(args={})
          @nikto_object = ::Nikto::Item.new(data)
        end

        def value(args={})
          field = args[:field]
          # fields in the template are of the form <foo>.<field>, where <foo>
          # is common across all fields for a given template (and meaningless).
          _, name = field.split('.')
          @nikto_object.try(name) || 'n/a'
        end

      end
    end
  end
end
