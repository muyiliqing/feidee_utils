require "feidee_utils/record"
require 'minitest/autorun'
require 'sqlite3'
require "tzinfo"

class FeideeUtils::RecordTest < MiniTest::Test
  def setup
    @sqlite_db = SQLite3::Database.new(":memory:")
    @sqlite_db.execute <<-SQL
      CREATE TABLE t_record(
        recordPOID INT PRIMARY KEY, record_key INT, record_value VARCHAR(255)
      );
    SQL
    @sqlite_db.execute("INSERT INTO t_record values(1, 1, 'stupid record');")
    @sqlite_db.execute("INSERT INTO t_record values(2, 2, 'base');")
    @sqlite_db.execute <<-SQL
      CREATE TABLE t_tag(tagPOID INT PRIMARY KEY, tag_name VARCHAR(255));
    SQL
    @sqlite_db.execute("INSERT INTO t_tag values(2, 'base');")

    temp_db = @sqlite_db
    FeideeUtils::Record.class_eval do
      define_singleton_method(:database) { temp_db }
    end
    FeideeUtils::Record.send :genereate_names, FeideeUtils::Record

    @fake_tag_table = Class.new(FeideeUtils::Record) do
      def self.name
        'Tag'
      end
    end
    FeideeUtils::Record.send :genereate_names, @fake_tag_table

    @fake_transaction_table = Class.new(FeideeUtils::Record) do
      def self.name
        'Test::FeideeUtils::Transaction'
      end
    end
    FeideeUtils::Record.send :genereate_names, @fake_transaction_table

    @fake_account_group_table = Class.new(FeideeUtils::Record) do
      def self.name
        'AccountGroup'
      end
    end
    FeideeUtils::Record.send :genereate_names, @fake_account_group_table
  end

  def test_id_field_name
    assert_equal 'recordPOID', FeideeUtils::Record.id_field_name
    assert_equal 'tagPOID', @fake_tag_table.id_field_name
    assert_equal 'transactionPOID', @fake_transaction_table.id_field_name
    assert_equal 'accountGroupPOID', @fake_account_group_table.id_field_name
  end

  def test_table_name
    assert_equal 't_record', FeideeUtils::Record.table_name
    assert_equal 't_tag', @fake_tag_table.table_name
    assert_equal 't_transaction', @fake_transaction_table.table_name
    assert_equal 't_account_group', @fake_account_group_table.table_name
  end

  def test_subclass_entity_name
    assert_equal 'Tag', @fake_tag_table.entity_name
    assert_equal 'Transaction', @fake_transaction_table.entity_name
    assert_equal 'AccountGroup', @fake_account_group_table.entity_name
  end

  # Accessors
  def test_poid
    raw_result = @sqlite_db.query("SELECT * FROM t_record WHERE record_key = 1")
    raw_row = raw_result.next
    record = FeideeUtils::Record.new(
      raw_result.columns,
      raw_result.types,
      raw_row
    )
    assert_equal 1, record.poid
  end

  def test_define_accessors
    assert (FeideeUtils::Record.respond_to? :define_accessors),
        "Record doesn't have define_accessors class method."
    klass = Class.new(FeideeUtils::Record) do
      def field
        { "x" => 2, "y" => 1}
      end

      define_accessors({ xxx: "x", yyy: "y" })
    end
    instance = klass.new([], [], [])
    assert_equal 2, instance.xxx
    assert_equal 1, instance.yyy
  end

  def test_define_entity_accessor
    assert (FeideeUtils::Record.respond_to? :define_entity_accessor),
        "Record doesn't have define_entity_accessor class method."

    klass = Class.new(FeideeUtils::Record) do
      def self.environment
        Module.new do
          const_set :ClassA, (Class.new do
            def self.find_by_id id
              "A find id " + id
            end
          end)
        end
      end

      def class_a_poid
        "a1"
      end

      def b_poid
        "b1"
      end

      define_entity_accessor :class_a_poid
      define_entity_accessor :b_poid, :class_a
    end

    assert_equal "A find id xx", klass.environment::ClassA.find_by_id("xx")
    instance = klass.new([], [], [])
    assert_equal "A find id b1", instance.b
    assert_equal "A find id a1", instance.class_a
  end

  def test_last_update_time
    # See comments in feidee_utils/record/utils.rb
    instance = FeideeUtils::Record.new(
      ["lastUpdateTime"], [nil], [Time.utc(2014, 5, 1).to_i * 1000]
    )

    time = instance.last_update_time
    assert_equal 2014, time.year
    assert_equal 5, time.month
    assert_equal 1, time.day
    assert_equal 8, time.hour
  end

  # Computed
  def test_computed
    assert (FeideeUtils::Record.respond_to? :computed),
        "Record doesn't have computed class method."
    klass = Class.new(FeideeUtils::Record) do
      computed :count do
        @counter ||= 0
        @counter += 1
      end
    end
    instance = klass.new([], [], [])
    assert_nil (instance.instance_variable_get "@counter".to_sym)
    assert_equal 1, instance.count
    assert_equal 1, (instance.instance_variable_get "@counter".to_sym)
    assert_equal 1, instance.count
    assert_equal 1, (instance.instance_variable_get "@counter".to_sym)
    assert_equal 1, instance.count
    assert_equal 1, (instance.instance_variable_get "@counter".to_sym)
  end

  # Persistent
  def test_all
    records = FeideeUtils::Record.all
    assert_equal 2, records.size
    assert records[0].is_a? FeideeUtils::Record
    assert records[1].is_a? FeideeUtils::Record
  end

  def test_find_by_id
    record = FeideeUtils::Record.find_by_id(1)
    assert_equal 1, (record.send :field)['recordPOID']
    assert_equal 1, (record.send :field)['record_key']
    assert_equal 'stupid record', (record.send :field)['record_value']
    assert_equal 'INT', (record.send :field_type)['recordPOID']
    assert_equal 'INT', (record.send :field_type)['record_key']
    assert_equal 'VARCHAR(255)', (record.send :field_type)['record_value']
  end

  def test_find_by_id_not_found
    assert_nil FeideeUtils::Record.find_by_id(-1)
  end

  def test_find_not_found
    e = assert_raises do
      FeideeUtils::Record.find(-1)
    end
    assert_equal "No Record of poid -1 found", e.message
  end

  def test_subclass_find_by_id
    tag = @fake_tag_table.find_by_id(2)
    assert_equal 2, (tag.send :field)['tagPOID']
    assert_equal 'base', (tag.send :field)['tag_name']
  end

  def test_subclass_find
    @fake_tag_table.find(2)
  end
end
