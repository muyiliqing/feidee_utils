module FeideeUtils
  class Record
    attr_reader :raw_row
    attr_reader :field, :field_type
    def initialize(columns, types, raw_row)
      @raw_row = raw_row

      @field = Hash[ columns.zip(raw_row) ]
      @field_type = Hash[ columns.zip(types) ]
    end

    @entity_name = 'record'

    class << self
      @@database = nil

      def database=(sqlite_db)
        @@database = sqlite_db
      end

      def database
        @@database
      end

      attr_reader :child_classes

      def inherited(child_class)
        @child_classes ||= Set.new
        if child_class.name != nil && (child_class.name.start_with? FeideeUtils.name)
          @child_classes.add(child_class)
        end
      end

      attr_reader :entity_name

      def id_field_name name = nil
        name ||= self.entity_name
        "#{name}POID"
      end

      def table_name name = nil
        name ||= self.entity_name
        "t_#{name}"
      end

      NoDeleteSuffixTables = %w(account category tradingEntity transaction transaction_template)

      def trash_table_name name = nil
        name ||= self.table_name
        NoDeleteSuffixTables.each do |core_name|
          if name == "t_" + core_name then
            return "t_" + "deleted_" + core_name;
          end
        end

        name + "_delete"
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

        if raw_result.next != nil
          raise "Getting more than one result with the same ID #{id} in table #{self.table_name}."
        end

        self.new(raw_result.columns, raw_result.types, raw_row)
      end
    end
  end
end
