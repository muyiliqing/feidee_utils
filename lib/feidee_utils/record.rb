require 'feidee_utils/record/accessors'
require 'feidee_utils/record/namespaced'
require 'feidee_utils/record/persistent'
require 'feidee_utils/record/utils'
require 'feidee_utils/record/modified_record'

module FeideeUtils
  # The implementation here is wired.
  # The goal is to create a class hierachy similar to ActiveRecord, where every table is represented by a
  # subclass of ActiveRecord::Base. Class methods, attribute accessors and almost all other functionalities
  # are provided by ActiveRecord::Base. For example, Base.all(), Base.find_by_id() are tied to a specific
  # table in a specific database.
  # The problem we are solving here is not the same as ActiveRecord. In ActiveRecord, the databases
  # are static, i.e. they won't be changed at runtime. Meanwhile, in our case, new databases can be created
  # at runtime, when a new KBF backup file is uploaded. Furthermore, multiple instances of different databases
  # can co-exist at the same time. To provide the same syntax as ActiveRecord, a standalone "Base" class has
  # to be created for each database.
  # In our implementation, when a new database is created, a subclass of Record is created in a new namepsace.
  # For each subclass of Record, a new subclass is copied to the new namespace, with it's database method
  # overloaded.
  class Record
    attr_reader :field, :field_type

    public
    def initialize(columns, types, raw_row)
      @field = Hash[ columns.zip(raw_row) ]
      @field_type = Hash[ columns.zip(types) ]

      validate_integrity
    end

    def validate_integrity
      # Do nothing.
    end

    class << self
      protected
      def database
        raise NotImplementedError.new("Subclasses must set database")
      end

      private
      def inherited subclass
        collecte_subclass subclass
        genereate_names subclass
      end
    end

    # Basic accessors, poid, last update time, etc.
    include Accessors
    # Helper methods to define accessors
    extend Accessors::ClassMethods
    # Helper methods to define new classes in a given namespace.
    extend Namespaced::ClassMethods
    # Helper methods to look up records.
    extend Persistent::ClassMethods
    # Helper methods to convert data types.
    include Utils
  end
end
