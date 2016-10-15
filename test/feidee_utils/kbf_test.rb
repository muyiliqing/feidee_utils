require "feidee_utils/kbf"
require 'minitest/autorun'
require 'pathname'

class FeideeUtils::KbfTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @fresh_ios_backup = FeideeUtils::Kbf.open_file(
      base_path.join("../data/QiQi-20150422203954.kbf")
    )
    @oneline_ios_backup = FeideeUtils::Kbf.open_file(
      base_path.join("../data/QiQi-20150422204102.kbf")
    )
  end

  def test_parse_zip
    assert @fresh_ios_backup.db.is_a? FeideeUtils::Database
    assert @oneline_ios_backup.db.is_a? FeideeUtils::Database
  end

  def test_extract_sqlite
    backup_file = @oneline_ios_backup.extract_original_sqlite(nil)
    db = SQLite3::Database.new(backup_file.path)
    assert !db.closed?
  end

  def test_read_backup
    empty_rows = @fresh_ios_backup.db.ledger::Transaction.all
    assert empty_rows.empty?
    one_line = @oneline_ios_backup.db.ledger::Account.all
    assert_equal 1, one_line.size()
  end
end
