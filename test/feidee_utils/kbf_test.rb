require "feidee_utils/kbf"
require 'minitest/autorun'
require 'pathname'

class KbfTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @fresh_ios_backup = FeideeUtils::Kbf.open_file(base_path.join("../data/QiQi-20150422203954.kbf"))
    @oneline_ios_backup = FeideeUtils::Kbf.open_file(base_path.join("../data/QiQi-20150422204102.kbf"))
  end

  def test_read_backup
    assert @fresh_ios_backup.sqlite_db.is_a? FeideeUtils::Database
    assert @oneline_ios_backup.sqlite_db.is_a? FeideeUtils::Database
  end
end
