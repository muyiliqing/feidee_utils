require 'feidee_utils/record'

module FeideeUtils
  class Transaction < Record
    module ClassMethods
      def entity_name
        "transaction"
      end
    end

    extend ClassMethods

    class TransferWithCategoryException < Exception
    end

    class DifferentCategoryException < Exception
    end

    class DifferentAmountException < Exception
    end

    def validate_integrity
      if type == :transfer
        raise TransferWithCategoryException unless buyer_category_poid == 0 and seller_category_poid == 0
      end
      raise DifferentCategoryException unless buyer_category_poid == 0 or seller_category_poid == 0
      raise DifferentAmountException unless buyer_deduction == seller_addition
    end

    FieldMappings = {
      raw_created_at:         "createdTime",
      raw_modified_at:        "modifiedTime",
      raw_trade_at:           "tradeTime",
      raw_type:               "type",
      memo:                   "memo",
      buyer_account_poid:     "buyerAccountPOID",
      buyer_category_poid:    "buyerCategoryPOID",
      seller_account_poid:    "sellerAccountPOID",
      seller_category_poid:   "sellerCategoryPOID",
      raw_buyer_deduction:    "buyerMoney",
      raw_seller_addition:    "sellerMoney",
      uuid:                   "relation",
    }

    IgnoredFields = [
      "creatorTradingEntityPOID",
      "modifierTradingEntityPOID",
      "ffrom",                # The signature of the App writting this transaction.
      "photoName",            # To be added
      "photoNeedUpload",      # To be added
      "relationUnitPOID",     # WTF
      "clientID",             # WTF
      "FSourceKey",           # WTF
    ]

    TypeEnum = {
      0 => :expenditure,
      1 => :income,
      2 => :transfer,
      3 => :transfer,
      8 => :initial_balance, # Positive.
      9 => :initial_balance, # Negative.
    }

    define_accessors(FieldMappings)

    def created_at
      timestamp_to_time(raw_created_at)
    end

    def modified_at
      timestamp_to_time(raw_modified_at)
    end

    def trade_at
      timestamp_to_time(raw_trade_at)
    end

    def type
      TypeEnum[raw_type]
    end

    def has_category?
      category_poid != 0
    end

    def category_poid
      buyer_category_poid + seller_category_poid
    end

    # Amount accessors

    def buyer_deduction
      sign_by_type(raw_buyer_deduction)
    end

    def seller_addition
      sign_by_type(raw_seller_addition)
    end

    def amount
      buyer_deduction
    end

    class ModifiedTransaction < ModifiedRecord
      define_custom_methods([
        :created_at,
        :modified_at,
        :trade_at,
        :type,
        :category_poid,
        :buyer_deduction,
        :seller_addition,
        :amount,
      ])
      define_default_methods(FieldMappings)
    end

    class TransfersNotPaired < Exception
    end

    def self.remove_uuid_duplications transactions
      uuids_map = transactions.inject({}) do |uuids, transaction|
        if transaction.raw_type == 2 or transaction.raw_type == 3
          uuid = transaction.uuid
          uuids[uuid] ||= []
          uuids[uuid] << transaction.poid
        end
        uuids
      end

      uuids_map.each do |uuid, transfers|
        raise TransfersNotPaired.new([uuid] + transfers) if transfers.size != 2
      end

      transactions.select do |transaction|
        !(transaction.raw_type == 3 and uuids_map.has_key? transaction.uuid)
      end
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

    private
    def sign_by_type num
      raw_type == 9 ? -num : num
    end

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
