module FeideeUtils
  module Mixins
    module Type
      # TODO: add tests for this module.
      module ClassMethods
        def define_type_enum type_enum
          const_set :TypeEnum, type_enum.freeze
        end
      end

      def self.included klass
        klass.extend ClassMethods
      end

      def type
       self.class::TypeEnum[raw_type]
      end
    end
  end
end

