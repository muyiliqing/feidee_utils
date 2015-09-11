module FeideeUtils
  class Record
    module Accessors
      def poid
        @field[self.class.id_field_name]
      end

      def last_update_time
        timestamp_to_time(@field["lastUpdateTime"])
      end

      module ClassMethods
        def define_accessors field_mappings
          field_mappings.each do |name, key|
            raise "Accessor #{name} already exists in #{self.name}." if method_defined? name
            define_method name do field[key] end
          end
        end
      end
    end
  end
end
