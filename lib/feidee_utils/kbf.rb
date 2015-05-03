require 'zip'
require 'sqlite3'
require 'feidee_utils/database'
require 'feidee_utils/record'
require 'feidee_utils/transaction'
require 'feidee_utils/account'

module FeideeUtils
class Kbf
  DatabaseName = 'mymoney.sqlite'

  attr_reader :zipfile, :sqlite_db

  def initialize(input_stream)
    @zipfile = Zip::File.open_buffer(input_stream) do |zipfile|
      zipfile.each do |entry|
        if entry.name == DatabaseName
          # Each call to get_input_stream will create a new stream
          @original_sqlite_db_entry = entry
          @sqlite_db = FeideeUtils::Database.new(entry.get_input_stream, true)
        end
      end
    end
  end

  def extract_original_sqlite(dest_file_path = nil)
    FeideeUtils::Database.feidee_to_sqlite(@original_sqlite_db_entry.get_input_stream, dest_file_path)
  end

  def extract_transactions
    @sqlite_db.namespaced::Transaction.all
  end

  def extract_accounts
    @sqlite_db.namespaced::Account.all
  end

  class << self
    def open_file(file_name)
      return Kbf.new(File.open(file_name))
    end
  end
end
end
