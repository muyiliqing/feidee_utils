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

    FieldMappings = {
      name:                 "name",
      raw_balance:              "balance",
      raw_credit:               "amountOfCredit",
      raw_debit:                "amountOfLiability",
      currency:             "currencyType",
      # NOTE: The parent poid of an orphan is 0.
      # The parent poid of a toplevel parent is -1.
      # Guess: A parent can't have it's parents,
      # i.e. a parent's parent poid is -1.
      parent_poid:          "parent",
      memo:                 "memo",
      # Examples: saving accounts, credit cards, cash, insurances and so on.
      account_group_poid:   "accountGroupPOID",
    }

    IgnoredFields = [
      "tradingEntityPOID", # The opening bank
      "type",             # Always 0
      "usedCount",        # Always 0
      "uuid",             # It's always empty.
      "hidden",           # Field used by UI
      "ordered",          # WTF
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

    class ModifiedAccount < Record::ModifiedRecord
      define_custom_methods([
        :balance,
        :credit,
        :debit
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
