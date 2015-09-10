require 'feidee_utils/record'
require 'bigdecimal'

module FeideeUtils
  class Account < Record
    module ClassMethods
      def entity_name
        "account"
      end
    end
    extend ClassMethods

    def validate_integrity
      raise "Account type should always be 0, but it's #{field["type"]}.\n" + inspect unless field["type"] == 0
      raise "Account usedCount should always be 0, but it's #{field["usedCount"]}.\n" + inspect unless field["usedCount"] == 0
      raise "Account uuid should always be empty, but it's #{field["uuid"]}.\n" + inspect unless field["uuid"].to_s.empty?
      raise "Account hierachy contains more than 2 levels.\n" + inspect unless flat_parent_hierachy?
    end

    FieldMappings = {
      name:                 "name",
      raw_balance:          "balance",
      raw_credit:           "amountOfCredit",
      raw_debit:            "amountOfLiability",
      currency:             "currencyType",
      parent_poid:          "parent",
      memo:                 "memo",
      # Examples: saving accounts, credit cards, cash, insurances and so on.
      # TODO: Add support for account groups.
      account_group_poid:   "accountGroupPOID",
      raw_hidden:           "hidden",
    }

    IgnoredFields = [
      "tradingEntityPOID",
      "type",             # Always 0
      "usedCount",        # Always 0
      "uuid",             # Always empty.
      "ordered",          # The sequence number when showing in UI.
      "code",             # WTF
      "clientID",         # WTF
    ]

    define_accessors(FieldMappings)

    # NOTE: balance is not set for credit cards etc. Instead
    # credit/debit are used.
    # Guess: The special behavior is be controlled by
    # account_group_poid.
    def balance
      to_bigdecimal(raw_balance) + credit - debit
    end

    def credit
      to_bigdecimal(raw_credit)
    end

    def debit
      to_bigdecimal(raw_debit)
    end

    def hidden?
      raw_hidden == 1
    end

    # Parent related.
    def parent
      self.class.find_by_id(parent_poid)
    end

    def has_parent?
      parent_poid != 0 && !flagged_as_parent?
    end

    def flagged_as_parent?
      # Account with POID -1 doesn't exist. It's just a special
      # POID used to indicate that this account itself is the parent
      # of some other accounts.
      # TODO: verify this when creating databases.
      parent_poid == -1
    end

    def flat_parent_hierachy?
      !has_parent? or parent.flagged_as_parent?
    end

    def children
      arr = []
      self.class.database.query("SELECT * FROM #{self.class.table_name} WHERE parent = ?", poid) do |result|
        result.each do |raw_row|
          arr << self.class.new(result.columns, result.types, raw_row)
        end
      end
      arr
    end

    class ModifiedAccount < Record::ModifiedRecord
      define_custom_methods([
        :balance,
        :credit,
        :debit,
        :parent,
      ])
      define_default_methods(FieldMappings)
    end

    # Schema:
    # accountPOID LONG NOT NULL,
    # name varchar(100) NOT NULL,
    # tradingEntityPOID integer NOT NULL,
    # lastUpdateTime] LONG,
    # usedCount integer DEFAULT 0,
    # accountGroupPOID integer,
    # balance decimal(12, 2),
    # currencyType varchar(50) default 'CNY',
    # memo varchar(200),
    # type integer DEFAULT 0,
    # amountOfLiability decimal(12, 2)DEFAULT 0,
    # amountOfCredit decimal(12, 2)DEFAULT 0,
    # ordered integer default 0,
    # code VARCHAR(20),
    # parent LONG default 0,
    # hidden integer default 0,
    # clientID LONG default 0,
    # uuid varchar(200),
  end
end
