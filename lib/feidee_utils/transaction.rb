require 'feidee_utils/record'
require 'feidee_utils/mixins/type'

module FeideeUtils
  class Transaction < Record
    include FeideeUtils::Mixins::Type

    class TransferLackBuyerOrSellerException < Exception
    end

    class TransferWithCategoryException < Exception
    end

    class InconsistentBuyerAndSellerException < Exception
    end

    class InconsistentCategoryException < Exception
    end

    class InconsistentAmountException < Exception
    end

    def validate_integrity
      if is_transfer?
        unless buyer_account_poid != 0 and seller_account_poid != 0
          raise TransferLackBuyerOrSellerException,
            "Both buyer and seller should be set in a transfer. " +
            "Buyer account POID: #{buyer_account_poid}. Seller account POID: #{seller_account_poid}.\n" +
            inspect
        end
        unless buyer_category_poid == 0 and seller_category_poid == 0
          raise TransferWithCategoryException,
            "Neither buyer or seller category should be set in a transfer. " +
            "Buyer category POID: #{buyer_category_poid}. Seller category POID: #{seller_category_poid}.\n" +
            inspect
        end
      else
        unless (buyer_account_poid == 0) ^ (seller_account_poid == 0)
          raise InconsistentBuyerAndSellerException,
            "Exactly one of buyer and seller should be set in a non-transfer transaction. " +
            "Buyer account POID: #{buyer_account_poid}. Seller account POID: #{seller_account_poid}.\n" +
            inspect
        end

        # We could enforce that category is set to the matching party (buyer or seller) of account.
        # However the implementation could handle all situations, as long as only one of them is set.
        # Thus no extra check is done here.
        unless buyer_category_poid == 0 or seller_category_poid == 0
          raise InconsistentCategoryException,
            "Only one of buyer and seller category should be set in a non-transfer transaction. "
            "Buyer category POID: #{buyer_category_poid}. Seller category POID: #{seller_category_poid}.\n" +
            inspect
        end
      end

      unless buyer_deduction == seller_addition
        raise InconsistentAmountException,
          "Buyer and seller should have the same amount set. " +
          "Buyer deduction: #{buyer_deduction}, seller_addition: #{seller_addition}.\n" +
        inspect
      end
    end

    class TransfersNotPaired < Exception
    end

    def self.validate_global_integrity
      uuids_map = all.inject({}) do |uuids, transaction|
        if transaction.is_transfer?
          uuid = transaction.uuid
          uuids[uuid] ||= [nil, nil]
          uuids[uuid][transaction.raw_type - 2] = transaction
        end
        uuids
      end

      uuids_map.each do |uuid, transfers|
        valid = true
        valid &&= transfers[0] != nil
        valid &&= transfers[1] != nil
        valid &&= transfers[0].buyer_account_poid == transfers[1].buyer_account_poid
        valid &&= transfers[0].seller_account_poid == transfers[1].seller_account_poid
        raise TransfersNotPaired.new([uuid] + transfers) unless valid
      end
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
    }.freeze
    define_entity_accessor :buyer_account_poid, :account
    define_entity_accessor :seller_account_poid, :account

    IgnoredFields = [
      "creatorTradingEntityPOID",
      "modifierTradingEntityPOID",
      "ffrom",                # The signature of the App writting this transaction.
      "photoName",            # To be added
      "photoNeedUpload",      # To be added
      "relationUnitPOID",     # WTF
      "clientID",             # WTF
      "FSourceKey",           # WTF
    ].freeze

    define_accessors(FieldMappings)

    define_type_enum({
      0 => :expenditure,
      1 => :income,
      2 => :transfer_seller,
      3 => :transfer_buyer,
      8 => :positive_initial_balance,
      9 => :negative_initial_balance,
    })

    def created_at
      timestamp_to_time(raw_created_at)
    end

    def modified_at
      timestamp_to_time(raw_modified_at)
    end

    def trade_at
      timestamp_to_time(raw_trade_at)
    end

    def has_category?
      category_poid != 0
    end

    def category_poid
      # At least one of those two must be 0.
      buyer_category_poid + seller_category_poid
    end
    define_entity_accessor :category_poid

    # Amount accessors

    def buyer_deduction
      sign_by_type(raw_buyer_deduction)
    end

    def seller_addition
      sign_by_type(raw_seller_addition)
    end

    def amount
      # Buyer deduction is always equal to seller addition.
      (buyer_deduction + seller_addition) / 2
    end

    def is_transfer?
      type == :transfer_buyer or type == :transfer_seller
    end

    def is_initial_balance?
      type == :positive_initial_balance or type == :negative_initial_balance
    end

    def revised_account_poid
      if type == :transfer_buyer
        buyer_account_poid
      elsif type == :transfer_seller
        seller_account_poid
      else
        buyer_account_poid + seller_account_poid
      end
    end
    define_entity_accessor :revised_account_poid, :account

    def revised_amount
      account_poid = revised_account_poid
      if account_poid == buyer_account_poid
        -buyer_deduction
      elsif account_poid == seller_account_poid
        seller_addition
      else
        raise "Unexpected revised account poid #{account_poid}."
      end
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

    private
    def sign_by_type num
      # This is awkward. For transactions of type positive_initial_balance, the
      # buyer is always 0, but the seller have to **add** the amount shown as
      # sellerMoney, which is consistent with other type of transactions.
      #
      # Whereas for transactions of type negative_initial_balance (9),  the
      # buyer is always 0, and the seller will have to **deduct** the amount
      # shown as sellerMoney from balance. Here the sign of
      # negative_initial_balance is reversed to reflect this awkwardness.
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
