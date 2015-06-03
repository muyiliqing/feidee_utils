require 'feidee_utils/record'

module FeideeUtils
  class Transaction < Record
    module ClassMethods
      def entity_name
        "transaction"
      end
    end

    extend ClassMethods

    TypeEnum = {
      0 => :expenditure,
      1 => :income,
      2 => :transfer,
      3 => :transfer,
      8 => :initial_balance, # Positive.
      9 => :initial_balance, # Negative.
    }

    def created_at
      timestamp_to_time(field["createdTime"])
    end

    def modified_at
      timestamp_to_time(field["modifiedTime"])
    end

    def trade_at
      timestamp_to_time(field["tradeTime"])
    end

    def type
      TypeEnum[raw_type]
    end

    def raw_type
      field["type"]
    end

    def memo
      field["memo"]
    end

    # Account accessors

    def buyer_account_poid
      field["buyerAccountPOID"]
    end

    def seller_account_poid
      field["sellerAccountPOID"]
    end

    # Category accessors

    def buyer_category_poid
      field["buyerCategoryPOID"]
    end

    def seller_category_poid
      field["sellerCategoryPOID"]
    end

    class DifferentCategoryException < Exception
    end

    def category_poid
      raise DifferentCategoryException unless buyer_category_poid == 0 or seller_category_poid == 0
      buyer_category_poid + seller_category_poid
    end

    # Amount accessors

    def buyer_deduction
      field["buyerMoney"]
    end

    def seller_addition
      field["sellerMoney"]
    end

    class DifferentAmountException < Exception
    end

    def amount
      raise DifferentAmountException unless buyer_deduction == seller_addition
      buyer_deduction
    end

    def self.remove_duplications transactions
      # count the number of incomming transfers.
      incomming_count = transactions.inject(Hash.new(0)) do |hash, transaction|
        if transaction.raw_type == 2
          key = transaction.key_parts
          hash[key] += 1
        end
        hash
      end

      # Remove outgoing transfer accordingly.
      transactions.select do |transaction|
        if transaction.raw_type == 3
          key = transaction.key_parts
          if incomming_count.has_key? key and incomming_count[key] > 0
            incomming_count[key] -= 1
            false
          else
            true
          end
        else
          true
        end
      end
    end

    def key_parts
      @key_parts ||= [
        buyer_account_poid,
        seller_account_poid,
        trade_at.to_s,
        created_at.to_s,
        modified_at.to_s,
        buyer_deduction,
        seller_addition,
        memo,
      ]
    end

    # TODO: add support for photos.
    # photoName
    # photoNeedUpload
    # TODO: WTF are those fields?
    # relation            varchar(200) default ''
    # relationUnitPOID    LONG
    # ffrom               varchar(250) default ''
    # clientID            LONG default 0
    # FSourceKey          varchar(100) DEFAULT NULL
    #
    # Ignored:
    # creatorTradingEntityPOID
    # modifierTradingEntityPOID

    # Schema:
    # transactionPOID LONG NOT NULL,
    # createdTime LONG NOT NULL,
    # modifiedTime LONG NOT NULL,
    # tradeTime LONG NOT NULL,
    # memo varchar(100),
    # type integer NOT NULL,
    # creatorTradingEntityPOID LONG,
    # modifierTradingEntityPOID LONG,
    # buyerAccountPOID LONG,
    # buyerCategoryPOID LONG default 0,
    # buyerMoney decimal(12, 2),
    # sellerAccountPOID LONG,
    # sellerCategoryPOID LONG default 0,
    # sellerMoney decimal(12, 2),
    # lastUpdateTime LONG,
    # photoName VARCHAR(100),
    # photoNeedUpload integer default 0,
    # relation varchar(200) default '',
    # relationUnitPOID LONG,
    # ffrom varchar(250) default '',
    # clientID LONG default 0,
    # FSourceKey varchar(100) DEFAULT NULL,
  end
end
