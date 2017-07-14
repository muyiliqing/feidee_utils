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
            if method_defined? name
              raise "Accessor #{name} already exists in #{self.name}."
            end
            define_method name do field[key] end
          end
        end

        def define_entity_accessor poid_callback_name, target_class_name = nil
          accessor_name = poid_callback_name.to_s.chomp!("_poid")
          if accessor_name == nil
            raise "No trailing 'poid' in callback name #{poid_callback_name}."
          end

          if not target_class_name
            target_class_name = accessor_name
          end
          target_class_name = target_class_name.to_s.clone
          target_class_name.gsub!(/(^|_)(.)/) { $2.upcase }

          define_method accessor_name do
            poid = method(poid_callback_name).call
            self.class.environment.const_get(target_class_name).find_by_id(poid)
          end
        end
      end
    end
  end
end
