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
    assert_equal Time.parse("1970-01-01 10:00:00 +1000"), @fresh_ios_backup.last_modified_at
    assert_equal Time.parse("2015-04-22 20:40:29 +1000"), @oneline_ios_backup.last_modified_at
    assert_equal Time.parse("2014-04-01 11:54:44 +1100"), @complex_android_backup.last_modified_at
  end

  def test_ledger_name
    assert_equal "QiQi", @fresh_ios_backup.ledger_name
    assert_equal "QiQi", @oneline_ios_backup.ledger_name
    assert_equal "Daily", @complex_android_backup.ledger_name
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

  def test_open_illegal_private_header
    test_file = Tempfile.new("feidee_test", binmode: true)
    test_file.write("hello world goodbye world")
    test_file.fsync
    test_file.close

    e = assert_raises do
      FeideeUtils::Database.open_file(test_file.path.to_s)
    end
    assert_match (/^Unexpected header .* in private sqlite file\./), e.message
  end

  def test_reopen_
    sqlite_file = Tempfile.new("test_sqlite_backup", binmode: true)
    sqlite_file.close
    @complex_android_backup.sqlite_backup(sqlite_file.path.to_s).close
    FeideeUtils::Database.open_file(sqlite_file.path.to_s)
  end

  def test_trash_table_name
    assert_equal 't_record_delete', (FeideeUtils::Database.trash_table_name "t_record")
    assert_equal 't_deleted_transaction', (FeideeUtils::Database.trash_table_name "t_transaction")
  end

  def test_validate_global_integrity
    @complex_android_backup.validate_global_integrity
  end

  def test_validate_global_integrity_errors
    # TODO: The db versions of complex_android_backup and the default iOS test db are different.
    @complex_android_backup.execute("INSERT INTO t_account VALUES(-1, 'invalid_account', -3, 1271747936000, 0, 3, 0, '', '', 0, 0, 0, 2, 0, 0, '')");
    assert_raises do
      @complex_android_backup.validate_global_integrity
    end
    @complex_android_backup.execute("DELETE FROM t_account WHERE accountPOID = -1");
  end
end
