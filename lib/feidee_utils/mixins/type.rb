module FeideeUtils
  module Mixins
    # Requires:
    #   instance methods: raw_type
    module Type
      module ClassMethods
        def define_type_enum type_enum
          const_set :TypeEnum, type_enum.freeze

          enum_values = type_enum.values
          type_code = if enum_values.size == enum_values.uniq.size
            type_enum.invert
          else
            {}
          end

          const_set :TypeCode, type_code.freeze
        end

        def type_code type_enum
          self::TypeCode[type_enum]
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

