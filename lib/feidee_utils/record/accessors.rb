module FeideeUtils
  class Record
    module Accessors
      def poid
        column(self.class.id_field_name)
      end

      def last_update_time
        timestamp_to_time(column("lastUpdateTime"))
      end

      module ClassMethods
        def define_accessors field_mappings
          field_mappings.each do |name, key|
            if method_defined? name
              raise "Accessor #{name} already exists in #{self.name}."
            end
            define_method name do column(key) end
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

        attr_reader :indexed_accessor_field_mappings
        def register_indexed_accessors field_mappings
          # The indexes of those columns are unknown until we see the schema.
          @indexed_accessor_field_mappings = field_mappings
        end

        # NOTE: Here we assume the underlaying database schema does not change.
        # The assumption is safe in the sense that it is generally expected to
        # restart and/or recompile your application after updating the schema.
        def define_indexed_accessors
          field_mappings = superclass.indexed_accessor_field_mappings
          return if field_mappings.nil?

          column_names = self.columns.map do |entry| entry["name"] end
          field_mappings.each do |name, column_name|
            if method_defined? name
              raise "Accessor #{name} already exists in #{self.name}."
            end

            index = column_names.index column_name
            if index.nil?
              raise "Cannot find column #{column_name} in #{inspect}."
            end
            define_method name do column_at_index(index) end
          end
        end
      end
    end
  end
end
