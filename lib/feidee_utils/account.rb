
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
      # Be aware of the precision lost from String -> Float -> BigDecimal.
      BigDecimal.new(field["balance"], 12).round(2)
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

    # Ignored fields:
    # tradingEntityPOID:
    # usedCount
    # accountGroupPOID
    # amountOfLiability
    # amountOfCredit
    # ordered
    # code
    # hidden
    # clientID
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
