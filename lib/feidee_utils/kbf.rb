require 'zip'
require 'sqlite3'
require 'feidee_utils/database'

module FeideeUtils
class Kbf
  DatabaseName = 'mymoney.sqlite'

  UnusedTables = %w(android_metadata t_account_info t_budget_item t_currency t_deleted_tradingEntity
    t_deleted_tag t_deleted_transaction_template t_exchange t_fund t_id_seed t_local_recent t_metadata
    t_message t_profile t_property t_tag t_tradingEntity t_transaction_template t_usage_count t_user)

  MetaTable = "t_metadata"

  Tables = {
    accounts: "t_account",
    account_groups: "t_account_group",
    categories: "t_category",
    transactions: "t_transaction",
  }

  attr_reader :zipfile, :sqlite_db, :extra_tables, :missing_tables
  attr_reader :platform, :sqlite_name, :sqlite_timestamp

  def initialize(input_stream)
    @zipfile = Zip::File.open_buffer(input_stream) do |zipfile|
      zipfile.each do |entry|
        if entry.name == DatabaseName
          # Each call to get_input_stream will create a new stream
          @original_sqlite_db_entry = entry
          @sqlite_db = FeideeUtils::Database.new(entry.get_input_stream)
        end
      end
    end

    extract_metadata

    drop_unused_tables

    @sqlite_module = Module.new do |mod|
      mod.module_eval do
        Tables.each do |table, table_name|
          define_method("extract_" + table.to_s) {
            @sqlite_db.execute("SELECT * FROM #{table_name}");
          }
        end

        define_method(:sqlite_backup) { |dest_file_path|
          @sqlite_db.execute("vacuum;")

          backup_sqlite_db = SQLite3::Database.new(dest_file_path.to_s)
          backup_obj = SQLite3::Backup.new(backup_sqlite_db, "main", @sqlite_db, "main")
          backup_obj.step(-1)
          backup_obj.finish
          backup_sqlite_db.close
        }

        define_method(:original_sqlite_backup) { |dest_file_path|
          File.open(dest_file_path, "wb+").write(@original_sqlite_db_entry.get_input_stream.read);
        }
      end
      mod
    end

    extend @sqlite_module
  end

  class << self
    def open_file(file_name)
      return Kbf.new(File.open(file_name))
    end
  end

  private

  def custom_tables
    rows = @sqlite_db.execute <<-SQL
      SELECT name FROM sqlite_master
      WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%'
      UNION ALL
      SELECT name FROM sqlite_temp_master
      WHERE type IN ('table','view')
      ORDER BY 1
    SQL
    rows.map do |row| row[0] end.sort
  end

  def drop_unused_tables
    useful_tables = (Tables.values + Tables.values.map do |x| Record.trash_table_name(x) end).sort
    tables_empty = (custom_tables - useful_tables).select do |table|
      @sqlite_db.execute("SELECT * FROM #{table};").empty?
    end

    (tables_empty + UnusedTables).each do |table|
      @sqlite_db.execute("DROP TABLE IF EXISTS #{table}");
    end

    # TODO: log this.
    @extra_tables = custom_tables - useful_tables
    @missing_tables = Tables.values - custom_tables
    if !@missing_tables.empty?
      raise "Missing tables: #{@missing_tables} from kbf backup."
    end
  end

  def extract_metadata
    @platform = @sqlite_db.execute("SELECT platform from #{MetaTable}")[0][0];

    @sqlite_name = sqlite_db.get_first_row("SELECT accountBookName FROM t_profile;")[0];

    # This is not recorded in the database, so the lastest lastUpdateTime of all
    # transactions is chosen.
    timestamp = @sqlite_db.get_first_row("SELECT max(lastUpdateTime) FROM #{Tables[:transactions]};")[0]
    @sqlite_timestamp = timestamp == nil ? Time.at(0) : Time.at(timestamp / 1000)
  end
end
end
