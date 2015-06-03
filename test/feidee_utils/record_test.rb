require "feidee_utils/record"
require 'minitest/autorun'
require 'sqlite3'

class RecordTest < MiniTest::Test
  def setup
    @sqlite_db = SQLite3::Database.new(":memory:")
    @sqlite_db.execute("CREATE TABLE t_record(recordPOID INT PRIMARY KEY, record_key INT, record_value VARCHAR(255));")
    @sqlite_db.execute("INSERT INTO t_record values(1, 1, 'stupid record');")
    @sqlite_db.execute("INSERT INTO t_record values(2, 2, 'base');")
    @sqlite_db.execute("CREATE TABLE t_tag(tagPOID INT PRIMARY KEY, tag_name VARCHAR(255));")
    @sqlite_db.execute("INSERT INTO t_tag values(2, 'base');")

    temp_db = @sqlite_db
    FeideeUtils::Record.class_eval do
      define_singleton_method(:database) { temp_db }
    end

    @fake_tag_table = Class.new(FeideeUtils::Record) do
      def self.entity_name
        'tag'
      end
    end

    @fake_transaction_table = Class.new(FeideeUtils::Record) do
      def self.entity_name
        'transaction'
      end
    end
  end

  def test_id_field_name
    assert_equal 'recordPOID', FeideeUtils::Record.id_field_name
  end

  def test_table_name
    assert_equal 't_record', FeideeUtils::Record.table_name
  end

  def test_subclass_entity_name
    assert_equal 'tag', @fake_tag_table.entity_name
  end

  def test_trash_table_name
    assert_equal 't_record_delete', FeideeUtils::Record.trash_table_name
    assert_equal 't_deleted_transaction', @fake_transaction_table.trash_table_name
  end

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

  def test_subclass_find_by_id
    tag = @fake_tag_table.find_by_id(2)
    assert_equal 2, (tag.send :field)['tagPOID']
    assert_equal 'base', (tag.send :field)['tag_name']
  end
end
