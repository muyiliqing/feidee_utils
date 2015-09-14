require 'sqlite3'
require 'feidee_utils/record'

# A thin wrapper around SQLite3
module FeideeUtils
  class Database < SQLite3::Database
    UnusedTables = %w(android_metadata t_account_info t_budget_item t_currency t_deleted_tradingEntity
    t_deleted_tag t_deleted_transaction_template t_exchange t_fund t_id_seed t_local_recent
    t_message t_property t_tag t_tradingEntity t_transaction_template t_usage_count t_user
    t_jct_clientdeviceregist t_jct_clientdevicestatus t_jct_syncbookfilelist t_jct_usergrant t_jct_userlog
    t_account_extra t_accountgrant t_binding t_notification
    t_syncResource t_sync_logs
    t_transaction_projectcategory_map)

    Tables = {
      accounts: "t_account",
      account_groups: "t_account_group",
      categories: "t_category",
      transactions: "t_transaction",

      metadata: "t_metadata",
      profile: "t_profile",
    }

    attr_reader :sqlite_file
    attr_reader :platform, :sqlite_name, :sqlite_timestamp
    attr_reader :extra_tables, :missing_tables
    attr_reader :namespaced

    def initialize(private_sqlite, strip = false)
      @sqlite_file = Database.feidee_to_sqlite(private_sqlite)

      super(@sqlite_file.path)

      extract_metadata
      drop_unused_tables if strip

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
      useful_tables = (Tables.values + Tables.values.map do |x| self.class.trash_table_name(x) end).sort
      tables_empty = (all_tables - useful_tables).select do |table|
        self.execute("SELECT * FROM #{table};").empty?
      end

      # TODO: Document all tables instead of dropping all empty tables.
      (tables_empty + UnusedTables).each do |table|
        self.execute("DROP TABLE IF EXISTS #{table}");
      end

      @extra_tables = all_tables - useful_tables
      @missing_tables = Tables.values - all_tables
      if !@missing_tables.empty?
        raise "Missing tables: #{@missing_tables} from kbf backup."
      end
    end

    def extract_metadata
      @platform = self.execute("SELECT platform from #{Tables[:metadata]}")[0][0];

      @sqlite_name = self.get_first_row("SELECT accountBookName FROM #{Tables[:profile]};")[0];

      # This is not recorded in the database, so the lastest lastUpdateTime of all
      # transactions is chosen.
      timestamp = self.get_first_row("SELECT max(lastUpdateTime) FROM #{Tables[:transactions]};")[0]
      @sqlite_timestamp = timestamp == nil ? Time.at(0) : Time.at(timestamp / 1000)
    end

    class << self
      def open_file(file_name)
        Database.new(File.open(file_name))
      end

      Header = "SQLite format 3\0".force_encoding("binary")
      FeideeHeader_iOS = "%$^#&!@_@- -!F\xff\0".force_encoding('binary')
      FeideeHeader_Android = ("\0" * 13 + "F\xff\0").force_encoding("binary")

      def feidee_to_sqlite(private_sqlite, sqlite_file = nil)
        # Discard the first a few bytes content.
        private_header = private_sqlite.read(Header.length)

        if private_header != FeideeHeader_iOS and private_header != FeideeHeader_Android
          raise "Unexpected header #{private_header.inspect} in private sqlite file."
        end

        # Write the rest to a tempfile.
        sqlite_file ||= Tempfile.new("kingdee_sqlite", binmode: true)
        sqlite_file.binmode
        sqlite_file.write(Header)
        sqlite_file.write(private_sqlite.read)
        sqlite_file.fsync
        sqlite_file
      end
    end

    class << self
      NoDeleteSuffixTables = %w(account category tradingEntity transaction transaction_template)

      def trash_table_name name
        NoDeleteSuffixTables.each do |core_name|
          if name == "t_" + core_name then
            return "t_" + "deleted_" + core_name;
          end
        end

        name + "_delete"
      end
    end

    AllKnownTables = {
      t_account:                "As named",
      t_account_book:           "A group of accounts, travel accounts etc.",
      t_account_extra:          "Extra Feidee account configs, key/value pair.",
      t_account_group:          "A group of accounts, saving/chekcing etc.",
      t_account_info:           "Additional info of accounts: banks etc.",
      t_accountgrant:           "Feidee account VIP related stuff.",
      t_budget_item:            "Used to create budgets. An extension of category.",
      t_binding:                "Netbank / credit card / Taobao bindings.",
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

      # JCT stands for Jia Cai Tong, a software for family book keeping.
      # See http://www.feidee.com/jct/
      # JCT is quite obsolete. All the related tables can be safely ignored.
      t_jct_clientdeviceregist: "Client devices.",
      t_jct_clientdevicestatus: "Client devices status.",
      t_jct_syncbookfilelist:   "Name of files synced from other devices.",
      t_jct_usergrant:          "Maybe if the user has purchased any service.",
      t_jct_userlog:            "As named.",

      t_local_recent:           "Local merchandise used recently",
      t_message:                "Kingdee ads.",
      t_metadata:               "Database version, client version etc.",
      t_module_stock_holding:   "Stock accounts.",
      t_module_stock_info:      "Stock rates.",
      t_module_stock_trans:     "Stock transactions.",
      t_notification:           "If and when a notification has been delivered.",
      t_profile:                "User profile, default stuff when configuring account books.",
      t_property:               "Data collected on user settings, key/value pair.",
      t_syncResource:           "???",
      t_sync_logs:              "As named.",
      t_tag:                    "Other support like roles/merchandise.",
      t_tradingEntity:          "Merchandise. Used together with t_user in Debt Center.",
      t_trans_debt:             "Transactions in Debt Center.",
      t_trans_debt_group:       "Transaction groups in Debt Center.",
      t_transaction:            "As named.",
      t_transaction_projectcategory_map: "Transaction project.",
      t_transaction_template:   "As named. UI.",
      t_user:                   "Multi-user support.",
      t_usage_count:            "As named. Abandoned."
    }
  end
end
