
module FeideeUtils
  class Record
    module Persistent
      module ClassMethods
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
          raise "No #{self.class.name} of poid #{id} found" if raw_row == nil

          if raw_result.next != nil
            raise "Getting more than one result with the same ID #{id} in table #{self.table_name}."
          end

          self.new(raw_result.columns, raw_result.types, raw_row)
        end
      end
    end
  end
end
