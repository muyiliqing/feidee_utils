require 'sqlite3'

# A thin wrapper around SQLite3
module FeideeUtils
  class Database < SQLite3::Database
    Header = "SQLite format 3\0"

    attr_reader :sqlite_file

    def initialize(private_sqlite)
      # Discard the first a few bytes content.
      private_sqlite.read(Header.length)

      # Write the rest to a tempfile.
      @sqlite_file = Tempfile.new("kingdee_sqlite", binmode: true)
      @sqlite_file.write(Header)
      @sqlite_file.write(private_sqlite.read)
      @sqlite_file.fsync

      super(@sqlite_file.path)
    end

    class << self
      def open_file(file_name)
        Database.new(File.open(file_name))
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
