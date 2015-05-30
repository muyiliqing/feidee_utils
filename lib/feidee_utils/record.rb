module FeideeUtils
  # The implementation here is wired.
  # The goal is to create a class hierachy similar to ActiveRecord, where every table is represented by a
  # subclass of ActiveRecord::Base. Class methods, attribute accessors and almost all other functionalities
  # are provided by ActiveRecord::Base. For example, Base.all(), Base.find_by_id() are tied to a specific
  # table in a specific database.
  # The problem we are solving here is not the same as ActiveRecord. In ActiveRecord, the databases
  # are static, i.e. they won't be changed during runtime. Meanwhile, in our case, new databases can be
  # created at runtime, when a new KBF backup file is uploaded. Furthermore, multiple instances of different databases
  # can co-exist at the same time. To provide the same syntax as ActiveRecord, a standalone "Base" class has
  # to be created for each database.
  # In our implementation, when a new database is created, a subclass of Record is created in a new namepsace.
  # For each subclass of Record, a new class with silimar code is copied to the new namespace. The super
  # class of the new class is set to the namespaced version of Record.
  # There's no such thing as "copy a class and change it's superclass". Thus each subclass of Record must be
  # implemented sololy by modules, so that those modules can be included by the generated classes.
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

    class << self
      # To use Record with different databases, generate a set of classes for each db
      def generate_namespaced_record_classes(db)
        Module.new do |mod|
          const_set(:Record, Class.new(Record) {
            # To get eger evaluation
            define_singleton_method("database") { db }
            def self.database=(value) raise "Cannot reassign the database, create a new Database instead" end
          })

          Record.child_classes.each do |child_class|
            if child_class.name.start_with? FeideeUtils.name
              class_name = child_class.name.sub(/#{FeideeUtils.name}::/, '')
              # Generate a const for the child class
              const_set(class_name, Class.new(mod::Record) {
                # Try mimic the behavior of this sub class
                # That requires all subclasses only implement via modules.
                if child_class.constants.include? :ClassMethods
                  extend child_class::ClassMethods
                end
                child_class.included_modules.each do |sub_mod|
                  include sub_mod
                end
              })
            end
          end
        end
      end
    end
  end
end
