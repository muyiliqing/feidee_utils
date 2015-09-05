require 'feidee_utils/kbf_test'
require 'feidee_utils/database_test'
require 'feidee_utils/record_test'
require 'feidee_utils/account_test'
require 'feidee_utils/transaction_test'

require 'pathname'

module FeideeUtils::TestUtils
  def self.open_test_sqlite
    base_path = Pathname.new(File.dirname(__FILE__))
    FeideeUtils::Database.open_file(base_path.join("data/QiQiTest.sqlite"))
  end
end
