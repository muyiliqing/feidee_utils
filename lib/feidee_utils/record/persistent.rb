
module FeideeUtils
  class Record
    module Persistent
      module ClassMethods
        # Names
        # Must be invoked by Record.inherited
        def genereate_names subclass
          entity_name =
            if i = subclass.name.rindex("::")
              subclass.name[(i+2)..-1]
            else
              subclass.name
            end

          id_field_name = entity_name.sub(/^[A-Z]/) { $&.downcase } + "POID"
          table_name = "t_" + entity_name.gsub(/([a-z\d])([A-Z\d])/, '\1_\2').downcase
          subclass.class_exec do
            define_singleton_method :entity_name do entity_name end
            define_singleton_method :id_field_name do id_field_name end
            define_singleton_method :table_name do table_name end
          end
        end

        # Persistent
        def all
          arr = []
          database.query("SELECT * FROM #{self.table_name}") do |result|
            result.each do |raw_row|
              arr << self.new(result.columns, result.types, raw_row)
            end
          end
          arr
        end

        def find_by_id(id)
          raw_result = database.query("SELECT * FROM #{self.table_name} WHERE #{self.id_field_name} = ?", id)

          raw_row = raw_result.next
          return nil if raw_row == nil

          if raw_result.next != nil
            raise "Getting more than one result with the same ID #{id} in table #{self.table_name}."
          end

          self.new(raw_result.columns, raw_result.types, raw_row)
        end

        def find(id)
          find_by_id(id) or raise "No #{self.name} of poid #{id} found"
        end
      end
    end
  end
end
