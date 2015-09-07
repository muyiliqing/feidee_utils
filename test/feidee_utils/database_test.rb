require 'feidee_utils/database'
require 'minitest/autorun'
require 'pathname'

class FeideeUtils::DatabaseTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @fresh_ios_backup = FeideeUtils::Database.open_file(base_path.join("../data/QiQi-20150422203954.sqlite"))
    @oneline_ios_backup = FeideeUtils::Database.open_file(base_path.join("../data/QiQi-20150422204102.sqlite"))
    @complex_android_backup = FeideeUtils::Database.open_file(base_path.join("../data/Daily_20140401.sqlite"))
  end

  def test_paltform
    assert_equal "iOS", @fresh_ios_backup.platform
    assert_equal "iOS", @oneline_ios_backup.platform
    assert_equal "Android", @complex_android_backup.platform
  end

  def test_timestamp
    assert_equal Time.parse("1970-01-01 10:00:00 +1000"), @fresh_ios_backup.sqlite_timestamp
    assert_equal Time.parse("2015-04-22 20:40:29 +1000"), @oneline_ios_backup.sqlite_timestamp
    assert_equal Time.parse("2014-04-01 11:54:44 +1100"), @complex_android_backup.sqlite_timestamp
  end

  def test_sqlite_name
    assert_equal "QiQi", @fresh_ios_backup.sqlite_name
    assert_equal "QiQi", @oneline_ios_backup.sqlite_name
    assert_equal "Daily", @complex_android_backup.sqlite_name
  end

  def test_read_fresh_backup
    empty_rows = @fresh_ios_backup.execute("SELECT * from t_transaction;")
    assert empty_rows.empty?
  end

  def test_read_oneline_backup
    one_line = @oneline_ios_backup.execute("SELECT * from t_transaction;")
    assert_equal 1, one_line.size()
  end

  def test_read_complex_backup
    many_lines = @complex_android_backup.execute("SELECT * from t_transaction;")
    assert_equal 308, many_lines.size()
  end

  def test_trash_table_name
    assert_equal 't_record_delete', (FeideeUtils::Database.trash_table_name "t_record")
    assert_equal 't_deleted_transaction', (FeideeUtils::Database.trash_table_name "t_transaction")
  end

end
