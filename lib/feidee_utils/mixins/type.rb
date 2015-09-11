module FeideeUtils
  module Mixins
    # Requires:
    #   instance methods: raw_type
    module Type
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

