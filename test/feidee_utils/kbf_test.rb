require "feidee_utils/kbf"
require 'minitest/autorun'
require 'pathname'

class KbfTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @fresh_ios_backup = FeideeUtils::Kbf.open_file(base_path.join("../data/QiQi-20150422203954.kbf"))
    @oneline_ios_backup = FeideeUtils::Kbf.open_file(base_path.join("../data/QiQi-20150422204102.kbf"))
  end

  def test_defined_module
    assert @fresh_ios_backup.respond_to? :extract_transactions
    assert @oneline_ios_backup.respond_to? :extract_transactions
    assert @fresh_ios_backup.respond_to? :sqlite_backup
    assert @oneline_ios_backup.respond_to? :sqlite_backup
  end

  def test_deleted_table_name
    assert_equal "t_deleted_transaction", @fresh_ios_backup.send(:to_deleted_table_name, "t_transaction")
    assert_equal "t_profile_delete", @fresh_ios_backup.send(:to_deleted_table_name, "t_profile")
  end

  def test_read_fresh_backup
    empty_rows = @fresh_ios_backup.extract_transactions
    assert empty_rows.empty?
  end

  def test_read_oneline_backup
    one_line = @oneline_ios_backup.extract_transactions
    assert_equal 1, one_line.size()
  end

  def test_paltform
    assert_equal "iOS", @oneline_ios_backup.platform
  end

  def test_timestamp
    assert_equal Time.parse("1970-01-01 10:00:00 +1000"), @fresh_ios_backup.sqlite_timestamp
    assert_equal Time.parse("2015-04-22 20:40:29 +1000"), @oneline_ios_backup.sqlite_timestamp
  end

  def test_backup_name
    assert_equal "QiQi", @fresh_ios_backup.sqlite_name
    assert_equal "QiQi", @oneline_ios_backup.sqlite_name
  end
end
