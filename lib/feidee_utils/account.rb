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

    TypeEnum = {
      0 => :normal
    }

    def name
      field["name"]
    end

    def balance
      self.class.to_bigdecimal(field["balance"]) + credit - debit
    end

    def credit
      self.class.to_bigdecimal(field["amountOfCredit"])
    end

    def debit
      self.class.to_bigdecimal(field["amountOfLiability"])
    end

    def currency
      field["currencyType"]
    end

    def parent_poid
      field["parent"]
    end

    def memo
      field["memo"]
    end

    def type
      TypeEnum[field["type"]]
    end

    def uuid
      field["uuid"]
    end

    # Examples: saving accounts, credit cards, cash, insurances and so on.
    def account_group_poid
      field["accountGroupPOID"]
    end

    private
    def self.to_bigdecimal number
      # Be aware of the precision lost from String -> Float -> BigDecimal.
      BigDecimal.new(number, 12).round(2)
    end

    # Ignored fields:
    # tradingEntityPOID: Then opening bank
    # usedCount
    # hidden
    # TODO: WTF are these fields?
    # ordered
    # code
    # clientID

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
