require 'feidee_utils/database'
require 'minitest/autorun'
require 'pathname'

class DatabaseTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @fresh_ios_backup = FeideeUtils::Database.open_file(base_path.join("../data/QiQi-20150422203954.sqlite"))
    @oneline_ios_backup = FeideeUtils::Database.open_file(base_path.join("../data/QiQi-20150422204102.sqlite"))
  end

  def test_paltform
    assert_equal "iOS", @oneline_ios_backup.platform
  end

  def test_timestamp
    assert_equal Time.parse("1970-01-01 10:00:00 +1000"), @fresh_ios_backup.sqlite_timestamp
    assert_equal Time.parse("2015-04-22 20:40:29 +1000"), @oneline_ios_backup.sqlite_timestamp
  end

  def test_sqlite_name
    assert_equal "QiQi", @fresh_ios_backup.sqlite_name
    assert_equal "QiQi", @oneline_ios_backup.sqlite_name
  end

  def test_read_fresh_backup
    empty_rows = @fresh_ios_backup.execute("SELECT * from t_transaction;")
    assert empty_rows.empty?
  end

  def test_read_oneline_backup
    one_line = @oneline_ios_backup.execute("SELECT * from t_transaction;")
    assert_equal 1, one_line.size()
  end
end
