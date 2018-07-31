require 'feidee_utils/record/accessors'
require 'feidee_utils/record/computed'
require 'feidee_utils/record/namespaced'
require 'feidee_utils/record/persistent'
require 'feidee_utils/record/utils'
require 'feidee_utils/record/modified_record'

module FeideeUtils
  # The implementation here is wired.
  # The goal is to create a class hierachy similar to ActiveRecord, where every
  # table is represented by a subclass of ActiveRecord::Base. Class methods,
  # attribute accessors and almost all other functionalities are provided by
  # ActiveRecord::Base. For example, Base.all(), Base.find_by_id() are tied to
  # a specific table in a specific database.
  # The problem we are solving here is not the same as ActiveRecord. In
  # ActiveRecord, the databases are static, i.e. they won't be changed at
  # runtime. Meanwhile, in our case, new databases can be created at runtime,
  # when a new KBF backup file is uploaded. Furthermore, multiple instances of
  # different databases can co-exist at the same time. To provide the same
  # syntax as ActiveRecord, a standalone "Base" class has to be created for each
  # database.
  # In our implementation, when a new database is created, a subclass of Record
  # is created in a new namepsace.  For each subclass of Record, a new subclass
  # is copied to the new namespace, with it's database method overloaded.
  class Record
    public
    def initialize(row)
      @row = row.freeze

      validate_integrity
    end

    def validate_integrity
      # Do nothing.
    end

    def self.validate_global_integrity
      # Do nothing.
    end

    def self.generate_subclasses db
      env = generate_namespaced_record_classes db
      env.contained_classes.each do |klass|
        klass.define_indexed_accessors
      end
      env
    end

    class << self
      protected
      def database
        raise NotImplementedError.new("Subclasses must set database")
      end

      private
      def inherited subclass
        if subclass.name != nil and subclass.name.start_with? FeideeUtils.name
          collect_subclass subclass
          subclass.generate_names
        end
      end
    end

    # Basic accessors, poid, last update time, etc.
    include Accessors
    # Helper methods to define accessors
    extend Accessors::ClassMethods
    # Helper methods to define computed fields.
    extend Computed::ClassMethods
    # Helper methods to define new classes in a given namespace.
    extend Namespaced::ClassMethods
    # Helper methods to look up records.
    extend Persistent::ClassMethods
    # Helper methods to convert data types.
    include Utils

    protected
    def column key
      # Looking up index is not as slow as it appears. The size of the array is
      # usually less than 20 and the strings are usually different in the first
      # few characters. The overhead is relatively low.
      # In fact, a downstream benchmark showed that it is faster than building a
      # hash upfront and lookup the hash here.
      index = self.class.column_names.index key
      return nil if index.nil?
      @row[index]
    end

    def column_at_index index
      @row[index]
    end

  end
end
