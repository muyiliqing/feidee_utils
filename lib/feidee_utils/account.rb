require 'feidee_utils/record'
require 'feidee_utils/account_group'
require 'bigdecimal'

module FeideeUtils
  class Account < Record
    def validate_integrity
      unless not column("type") or column("type") == 0
        raise "Account type should always be 0, but it's #{column("type")}.\n" +
          inspect
      end
      unless column("usedCount") == 0
        raise "Account usedCount should always be 0," +
          " but it's #{column("usedCount")}.\n"+
          inspect
      end
      unless column("uuid").to_s.empty?
        raise "Account uuid should always be empty,"+
          " but it's #{column("uuid")}.\n" +
          inspect
      end
      unless flat_parent_hierachy?
        raise "Account hierachy contains more than 2 levels.\n" + inspect
      end
      unless (raw_hidden == 1 or raw_hidden == 0)
        raise "Account hidden should be either 0 or 1," +
          " but it's #{raw_hidden}.\n" +
          inspect
      end
    end

    def self.validate_global_integrity
      if self.find_by_id(-1) != nil
        raise "-1 is used as the parent POID placeholder of a parent account." +
          " Account of POID -1 should not exist."
      end
    end

    NullPOID = 0

    FieldMappings = {
      name:                 "name",
      raw_balance:          "balance",
      raw_credit:           "amountOfCredit",
      raw_debit:            "amountOfLiability",
      currency:             "currencyType",
      parent_poid:          "parent",
      memo:                 "memo",
      ordered:              "ordered",
      # Examples: saving accounts, credit cards, cash, insurances and so on.
      account_group_poid:   "accountGroupPOID",
      raw_hidden:           "hidden",
    }.freeze
    define_entity_accessor :account_group_poid, :account_group

    IgnoredFields = [
      "tradingEntityPOID", # Foreign key to t_user or maybe t_tradingEntity.
      "type",             # Always 0, removed since database version 73.
      "usedCount",        # Always 0
      "uuid",             # Always empty.
      "code",             # Always 0, removed since database version 73.
      "clientID",         # Always equal to poid.
    ].freeze

    register_indexed_accessors(FieldMappings)

    # NOTE: balance is not set for credit cards etc. Instead
    # credit/debit are used.
    # Guess: The special behavior is be controlled by
    # account_group_poid. Again, the code can work in all cases,
    # thus no check is done.
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
      parent_poid != NullPOID && !flagged_as_parent?
    end

    def flagged_as_parent?
      # Account with POID -1 doesn't exist. It's just a special
      # POID used to indicate that this account itself is the parent
      # of some other accounts.
      parent_poid == -1
    end

    def flat_parent_hierachy?
      !has_parent? or parent.flagged_as_parent?
    end

    def children
      arr = []
      self.class.database.query(
        "SELECT * FROM #{self.class.table_name} WHERE parent = ?", poid
      ) do |result|
        result.each do |raw_row|
          arr << self.class.new(raw_row)
        end
      end
      arr
    end

    def to_s
      "#{name} (Account/#{poid})"
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
