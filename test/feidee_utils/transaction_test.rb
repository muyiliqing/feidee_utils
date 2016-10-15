require "feidee_utils_test"
require "feidee_utils/transaction"
require "feidee_utils/database"
require 'minitest/autorun'

class FeideeUtils::TransactionTest < MiniTest::Test
  def setup
    @sqlite_db = FeideeUtils::TestUtils.open_test_sqlite

    @all = @sqlite_db.ledger::Transaction.all
    @income = @all.find do |transaction| transaction.poid == -6 end
    @expenditure = @all.find do |transaction| transaction.poid == -5 end
    @transfer_out = @all.find do |transaction| transaction.poid == -9 end
    @transfer_in = @all.find do |transaction| transaction.poid == -10 end
    @debit_init = @all.find do |transaction| transaction.poid == -1 end
    @credit_init = @all.find do |transaction| transaction.poid == -2 end
  end

  def test_fields
    assert_equal 1433311141000, @income.raw_created_at
    assert_equal 1433311126000, @expenditure.raw_created_at

    assert_equal 1433311162000, @income.raw_modified_at
    assert_equal 1433311316000, @expenditure.raw_modified_at

    assert_equal 1433347200000, @income.raw_trade_at
    assert_equal 1433347200000, @expenditure.raw_trade_at

    assert_equal 1, @income.raw_type
    assert_equal 0, @expenditure.raw_type

    assert_equal "", @income.memo
    assert_equal "", @expenditure.memo
    assert_equal "Pay back", @transfer_in.memo

    assert_equal 0, @income.buyer_account_poid
    assert_equal (-18), @expenditure.buyer_account_poid

    assert_equal (-58), @income.buyer_category_poid
    assert_equal 0, @expenditure.buyer_category_poid

    assert_equal (-17), @income.seller_account_poid
    assert_equal 0, @expenditure.seller_account_poid

    assert_equal 0, @income.seller_category_poid
    assert_equal (-16), @expenditure.seller_category_poid

    assert_equal 125, @income.raw_buyer_deduction
    assert_equal 75, @expenditure.raw_buyer_deduction

    assert_equal 125, @income.raw_seller_addition
    assert_equal 75, @expenditure.raw_seller_addition

    assert_nil @income.uuid
    assert_nil @expenditure.uuid
    assert_equal "03886DB7-F1C0-4667-9148-73498FCAE501", @transfer_in.uuid
  end

  def test_type
    assert_equal :expenditure, @expenditure.type
    assert_equal :income, @income.type

    assert_equal 2, @transfer_in.raw_type
    assert_equal 3, @transfer_out.raw_type
    assert_equal :transfer_seller, @transfer_in.type
    assert_equal :transfer_buyer, @transfer_out.type

    assert_equal 8, @debit_init.raw_type
    assert_equal 9, @credit_init.raw_type
    assert_equal :positive_initial_balance, @debit_init.type
    assert_equal :negative_initial_balance, @credit_init.type
  end

  def test_is_transfer
    refute @income.is_transfer?
    refute @expenditure.is_transfer?
    assert @transfer_in.is_transfer?
    assert @transfer_out.is_transfer?
    refute @debit_init.is_transfer?
    refute @credit_init.is_transfer?
  end

  def test_is_initial_balance
    refute @income.is_initial_balance?
    refute @expenditure.is_initial_balance?
    refute @transfer_in.is_initial_balance?
    refute @transfer_out.is_initial_balance?
    assert @debit_init.is_initial_balance?
    assert @credit_init.is_initial_balance?
  end

  def test_validate_global_integrity_errors
    extra_transaction = FeideeUtils::Transaction.new(
      [ "type", "amount", "modifiedTime", "createdTime", "lastUpdateTime",
        "tradeTime", "buyerCategoryPOID", "sellerCategoryPOID", ],
      [ Integer.class, Integer.class, nil, nil, nil, nil, nil, nil, nil ],
      [ 3, 100, 0, 0, 0, 0, 0, 0],
    )

    assert extra_transaction.is_transfer?

    extra_transactions = @all + [ extra_transaction ]
    @sqlite_db.ledger::Transaction.class_eval do
      define_singleton_method :all do
        extra_transactions
      end
    end

    assert_raises FeideeUtils::Transaction::TransfersNotPaired do
      @sqlite_db.ledger::Transaction.validate_global_integrity
    end
  end

  def test_uuid
    transfers = @all.select do |transaction| transaction.is_transfer? end

    refute_empty transfers
    transfers.each do |transfer|
      refute_empty transfer.uuid, "#{transfer.poid} should have a uuid"
    end
  end

  def test_validate_global_integrity
    @sqlite_db.ledger::Transaction.validate_global_integrity
  end

  def test_credit_account_init_amount
    credit_init = @all.select do |transaction|
      transaction.raw_type == 9
    end.map do |transaction| transaction.amount end
    assert_equal [-500, -400], credit_init.sort
  end

  def test_memo
    memo_trans = @all.find do |transaction| transaction.poid == -9 end
    assert_equal "Pay back", memo_trans.memo
    memo_trans = @all.find do |transaction| transaction.poid == -10 end
    assert_equal "Pay back", memo_trans.memo
  end

  def test_timestamps
    @all.each do |transaction|
      assert_equal 2015, transaction.modified_at.year
      assert_equal 2015, transaction.created_at.year
      assert_equal 2015, transaction.trade_at.year
      assert_equal 2015, transaction.last_update_time.year
    end
  end

  def test_seller_account_poid
    assert_equal (-17), @income.seller_account_poid
    assert_equal 0, @expenditure.seller_account_poid
    assert_equal (-19), @transfer_in.seller_account_poid
    assert_equal (-19), @transfer_out.seller_account_poid
    assert_equal (-17), @debit_init.seller_account_poid
    assert_equal (-18), @credit_init.seller_account_poid
  end

  def test_buyer_account_poid
    assert_equal 0, @income.buyer_account_poid
    assert_equal (-18), @expenditure.buyer_account_poid
    assert_equal (-20), @transfer_in.buyer_account_poid
    assert_equal (-20), @transfer_out.buyer_account_poid
    assert_equal 0, @debit_init.buyer_account_poid
    assert_equal 0, @credit_init.buyer_account_poid
  end

  def test_validate_account_integrity_errors
    assert_raises FeideeUtils::Transaction::InconsistentBuyerAndSellerException do # nolint
      FeideeUtils::Transaction.new(
        ["buyerAccountPOID", "sellerAccountPOID"], [nil, nil], [2, 3]
      )
    end
    assert_raises FeideeUtils::Transaction::InconsistentBuyerAndSellerException do # nolint
      FeideeUtils::Transaction.new(
        ["buyerAccountPOID", "sellerAccountPOID"], [nil, nil], [0, 0]
      )
    end
  end

  def test_transfer_validate_account_integrity_errors
    assert_raises FeideeUtils::Transaction::TransferLackBuyerOrSellerException do # nolint
      FeideeUtils::Transaction.new(
        ["type", "buyerAccountPOID"], [nil, nil], [2, 0]
      )
    end
    assert_raises FeideeUtils::Transaction::TransferLackBuyerOrSellerException do # nolint
      FeideeUtils::Transaction.new(
        ["type", "sellerAccountPOID"], [nil, nil], [2, 0]
      )
    end
  end

  def test_has_category
    assert @income.has_category?
    refute @transfer_in.has_category?
    refute @transfer_out.has_category?
  end

  def test_category_poid
    assert_equal (-58), @income.category_poid
    assert_equal (-16), @expenditure.category_poid
  end

  def test_validate_category_integrity_errors
    assert_raises FeideeUtils::Transaction::InconsistentCategoryException do
      FeideeUtils::Transaction.new(
        ["buyerAccountPOID", "buyerCategoryPOID", "sellerCategoryPOID"],
        [nil, nil, nil], [0, 1, 2]
      )
    end
  end

  def test_transfer_validate_category_integrity_errors
    assert_raises FeideeUtils::Transaction::TransferWithCategoryException do
      FeideeUtils::Transaction.new(
        ["type", "buyerCategoryPOID"], [nil, nil], [3, 2]
      )
    end
    assert_raises FeideeUtils::Transaction::TransferWithCategoryException do
      FeideeUtils::Transaction.new(
        ["type", "sellerCategoryPOID"], [nil, nil], [3, 2]
      )
    end
  end

  # ID 1..14, 16..19, 21
  Amounts = [
    100, -400, -500, 200, # Initial balances
    75, 125,              # expenditure and income
    100, 100, 100, 100,   # 2 transfers
    25, 25, 50, 50,       # another 2 transfers
    100, 100, 100, 16,    # 2 more transfers, one is forex.
    200,                  # Initial balance of a claim account.
  ]

  def test_amount
    @all.zip(Amounts).each do |transaction, amount|
      assert_equal amount, transaction.amount,
        "#{transaction.poid} incorrect amount"
    end
  end

  def test_validate_amount_integrity_errors
    assert_raises FeideeUtils::Transaction::InconsistentAmountException do
      FeideeUtils::Transaction.new(
        ["buyerAccountPOID", "buyerCategoryPOID", "sellerCategoryPOID",
         "buyerMoney", "sellerMoney"],
        [nil, nil, nil, nil, nil],
        [0, 0, 0, 0, 1])
    end
  end

  def test_validate_integrity
    FeideeUtils::Transaction.new(
      ["buyerAccountPOID", "sellerAccountPOID",
       "buyerCategoryPOID", "sellerCategoryPOID",
       "buyerMoney", "sellerMoney"],
      [nil, nil, nil, nil, nil, nil],
      [0, 1, 0, 2, 0, 0])

    FeideeUtils::Transaction.new(
      ["buyerAccountPOID", "sellerAccountPOID",
       "buyerCategoryPOID", "sellerCategoryPOID",
       "buyerMoney", "sellerMoney"],
      [nil, nil, nil, nil, nil, nil],
      [2, 0, 2, 0, 0, 0])
  end

  def test_transfer_validate_integrity
    # Type 2
    FeideeUtils::Transaction.new(
      ["buyerAccountPOID", "sellerAccountPOID",
       "buyerCategoryPOID", "sellerCategoryPOID", "type"],
      [nil, nil, nil, nil, nil],
      [2, 1, 0, 0, 2])

    # Type 3
    FeideeUtils::Transaction.new(
      ["buyerAccountPOID", "sellerAccountPOID",
       "buyerCategoryPOID", "sellerCategoryPOID", "type"],
      [nil, nil, nil, nil, nil],
      [2, 1, 0, 0, 3])
  end

  def test_revised_account_poid
    assert_equal (-17), @income.revised_account_poid
    assert_equal (-18), @expenditure.revised_account_poid
    assert_equal (-19), @transfer_in.revised_account_poid
    assert_equal (-20), @transfer_out.revised_account_poid
    assert_equal (-17), @debit_init.revised_account_poid
    assert_equal (-18), @credit_init.revised_account_poid
  end

  def test_revised_amount
    assert_equal @income.amount, @income.revised_amount
    assert_equal (-@expenditure.amount), @expenditure.revised_amount
    assert_equal @transfer_in.amount, @transfer_in.revised_amount
    assert_equal (-@transfer_out.amount), @transfer_out.revised_amount
    assert_equal @debit_init.amount, @debit_init.revised_amount
    # This looks wrong to me.
    assert_equal @credit_init.seller_addition, @credit_init.revised_amount
    # TODO: Add a test for forex transaction where buyer/seller amount are
    # different
  end
end
