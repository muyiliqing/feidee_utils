module FeideeUtils
  module Mixins
    # Requires:
    #   instance methods: raw_type
    module Type
      module ClassMethods
        def define_type_enum type_enum, reverse_lookup = true
          const_set :TypeEnum, type_enum.freeze

          if reverse_lookup
            enum_values = type_enum.values
            if enum_values.size != enum_values.uniq.size
              raise "Duplicate values in enum #{type_enum}."
            end

            const_set :TypeCode, type_enum.invert.freeze
            define_singleton_method :type_code do |type_enum_value|
              self::TypeCode[type_enum_value]
            end
          end
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

