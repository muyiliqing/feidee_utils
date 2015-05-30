require 'sqlite3'

# A thin wrapper around SQLite3
module FeideeUtils
  class Database < SQLite3::Database
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

    attr_reader :sqlite_file
    attr_reader :platform, :sqlite_name, :sqlite_timestamp
    attr_reader :extra_tables, :missing_tables
    attr_reader :namespaced

    def initialize(private_sqlite, minimal = false)
      @sqlite_file = Database.feidee_to_sqlite(private_sqlite)

      super(@sqlite_file.path)

      extract_metadata
      drop_unused_tables if minimal

      @namespaced = Record.generate_namespaced_record_classes(self)
    end

    def sqlite_backup(dest_file_path)
      self.execute("vacuum;")

      backup_sqlite_db = SQLite3::Database.new(dest_file_path.to_s)
      backup_obj = SQLite3::Backup.new(backup_sqlite_db, "main", self, "main")
      backup_obj.step(-1)
      backup_obj.finish
      backup_sqlite_db.close
    end

    private
    def all_tables
      rows = self.execute <<-SQL
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
      tables_empty = (all_tables - useful_tables).select do |table|
        self.execute("SELECT * FROM #{table};").empty?
      end

      (tables_empty + UnusedTables).each do |table|
        self.execute("DROP TABLE IF EXISTS #{table}");
      end

      # TODO: log this.
      @extra_tables = all_tables - useful_tables
      @missing_tables = Tables.values - all_tables
      if !@missing_tables.empty?
        raise "Missing tables: #{@missing_tables} from kbf backup."
      end
    end

    def extract_metadata
      @platform = self.execute("SELECT platform from #{MetaTable}")[0][0];

      @sqlite_name = self.get_first_row("SELECT accountBookName FROM t_profile;")[0];

      # This is not recorded in the database, so the lastest lastUpdateTime of all
      # transactions is chosen.
      timestamp = self.get_first_row("SELECT max(lastUpdateTime) FROM #{Tables[:transactions]};")[0]
      @sqlite_timestamp = timestamp == nil ? Time.at(0) : Time.at(timestamp / 1000)
    end

    class << self
      def open_file(file_name)
        Database.new(File.open(file_name))
      end

      Header = "SQLite format 3\0"

      def feidee_to_sqlite(private_sqlite, sqlite_file = nil)
        # Discard the first a few bytes content.
        private_sqlite.read(Header.length)

        # Write the rest to a tempfile.
        sqlite_file ||= Tempfile.new("kingdee_sqlite", binmode: true)
        sqlite_file.binmode
        sqlite_file.write(Header)
        sqlite_file.write(private_sqlite.read)
        sqlite_file.fsync
        sqlite_file
      end
    end

    AllKnownTables = {
      t_account:                "As named",
      t_account_book:           "A group of accounts, travel accounts etc.",
      t_account_extra:          "Extra account configs, key/value pair.",
      t_account_group:          "A group of accounts, saving/chekcing etc.",
      t_account_info:           "Additional info of accounts: banks etc.",
      t_accountgrant:           "???",
      t_budget_item:            "Used to create budgets. An extension of category.",
      t_binding:                "???",
      t_category:               "Transaction categories.",
      t_currency:               "Currency types.",
      t_exchange:               "Currency exchange rates.",
      t_fund:                   "List of money manage institute names. Abandoned.",
      t_fund_holding:           "Fund accounts.",
      t_fund_trans:             "Fund transactions.",
      t_fund_price_history:     "Fund price history",
      t_id_seed:                "ID seeds for all tables.",
      t_import_history:         "As named.",
      t_import_source:          "Import data from text messages etc.",
      t_jct_clientdeviceregist: "???",
      t_jct_clientdevicestatus: "???",
      t_jct_syncbookfilelist:   "???",
      t_jct_usergrant:          "??? Maybe if the user has purchased any service.",
      t_jct_userlog:            "As named.",
      t_local_recent:           "Local merchandise used recently",
      t_message:                "Kingdee ads.",
      t_metadata:               "Database version, client version etc.",
      t_module_stock_holding:   "Stock accounts.",
      t_module_stock_info:      "???",
      t_module_stock_trans:     "Stock transactions.",
      t_notification:           "???",
      t_profile:                "User profile, default stuff when configuring account books.",
      t_property:               "Data collected on user settings, key/value pair.",
      t_syncResource:           "???",
      t_sync_logs:              "As named.",
      t_tag:                    "Other support like roles/merchandise.",
      t_tradingEntity:          "Merchandise. Used together with t_user in Debt Center.",
      t_trans_debt:             "Transactions in Debt Center.",
      t_trans_debt_group:       "Transaction groups in Debt Center.",
      t_transaction:            "As named.",
      t_transaction_projectcategory_map: "???",
      t_transaction_template:   "As named. UI.",
      t_user:                   "Multi-user support.",
      t_usage_count:            "As named. Abandoned."
    }
  end
end
