require "feidee_utils/transaction"
require "feidee_utils/database"
require 'minitest/autorun'
require 'pathname'

class FeideeUtils::TransactionTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @sqlite_db = FeideeUtils::Database.open_file(base_path.join("../data/QiQiTest.sqlite"))

    @all = @sqlite_db.namespaced::Transaction.all
    @income = @all.find do |transaction| transaction.poid == -6 end
    @expenditure = @all.find do |transaction| transaction.poid == -5 end
    @transfer_in = @all.find do |transaction| transaction.poid == -9 end
    @transfer_out = @all.find do |transaction| transaction.poid == -10 end
    @debit_init = @all.find do |transaction| transaction.poid == -1 end
    @credit_init = @all.find do |transaction| transaction.poid == -2 end
  end

  def test_type
    assert_equal :expenditure, @expenditure.type
    assert_equal :income, @income.type

    assert_equal 3, @transfer_in.raw_type
    assert_equal 2, @transfer_out.raw_type
    assert_equal :transfer, @transfer_in.type
    assert_equal :transfer, @transfer_out.type

    assert_equal 8, @debit_init.raw_type
    assert_equal 9, @credit_init.raw_type
    assert_equal :initial_balance, @debit_init.type
    assert_equal :initial_balance, @credit_init.type
  end

  def test_self_key_parts
    @all.each do |transaction|
      assert_equal transaction.key_parts, transaction.key_parts
    end
  end

  def test_duplicate_transaction_key_parts
    transfer_in = @all.select do |transaction| transaction.raw_type == 2 end
    transfer_out = @all.select do |transaction| transaction.raw_type == 3 end

    transfer_in_key = transfer_in.map do |transaction| transaction.key_parts end
    transfer_out_key = transfer_out.map do |transaction| transaction.key_parts end
    refute_empty transfer_in_key
    refute_empty transfer_out_key
    assert_equal transfer_in_key.sort, transfer_out_key.sort
  end

  def test_remove_duplications
    removed = @all - FeideeUtils::Transaction.remove_duplications(@all)
    transfer_out = @all.select do |transaction| transaction.raw_type == 3 end

    refute_empty removed
    refute_empty transfer_out
    assert_equal transfer_out, removed
  end

  def test_remove_duplications_extra_one
    extra_transaction = FeideeUtils::Transaction.new(
      [ "type", "amount", "modifiedTime", "createdTime", "lastUpdateTime", "tradeTime", "buyerCategoryPOID", "sellerCategoryPOID", ],
      [ Integer.class, Integer.class, nil, nil, nil, nil, nil, nil, nil ],
      [ 3, 100, 0, 0, 0, 0, 0, 0],
    )

    extra_transactions = @all + [ extra_transaction ]

    rest = FeideeUtils::Transaction.remove_duplications(extra_transactions)
    assert rest.include? extra_transaction
  end

  def test_uuid
    transfers = @all.select do |transaction| transaction.type == :transfer end

    refute_empty transfers
    transfers.each do |transfer|
      refute_empty transfer.uuid, "#{transfer.poid} should have a uuid"
    end
  end

  def test_remove_uuid_duplications
    removed = @all - FeideeUtils::Transaction.remove_uuid_duplications(@all)
    transfer_out = @all.select do |transaction| transaction.raw_type == 3 end

    refute_empty removed
    refute_empty transfer_out
    assert_equal transfer_out, removed
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
    assert_raises FeideeUtils::Transaction::InconsistentBuyerAndSellerSetException do
      FeideeUtils::Transaction.new(["buyerAccountPOID", "sellerAccountPOID"], [nil, nil], [2, 3])
    end
    assert_raises FeideeUtils::Transaction::InconsistentBuyerAndSellerSetException do
      FeideeUtils::Transaction.new(["buyerAccountPOID", "sellerAccountPOID"], [nil, nil], [0, 0])
    end
  end

  def test_transfer_validate_account_integrity_errors
    assert_raises FeideeUtils::Transaction::TransferLackBuyerOrSellerException do
      FeideeUtils::Transaction.new(["type", "buyerAccountPOID"], [nil, nil], [2, 0])
    end
    assert_raises FeideeUtils::Transaction::TransferLackBuyerOrSellerException do
      FeideeUtils::Transaction.new(["type", "sellerAccountPOID"], [nil, nil], [2, 0])
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
      FeideeUtils::Transaction.new(["buyerAccountPOID", "buyerCategoryPOID", "sellerCategoryPOID"], [nil, nil, nil], [0, 1, 2])
    end
  end

  def test_transfer_validate_category_integrity_errors
    assert_raises FeideeUtils::Transaction::TransferWithCategoryException do
      FeideeUtils::Transaction.new(["type", "buyerCategoryPOID"], [nil, nil], [3, 2])
    end
    assert_raises FeideeUtils::Transaction::TransferWithCategoryException do
      FeideeUtils::Transaction.new(["type", "sellerCategoryPOID"], [nil, nil], [3, 2])
    end
  end

  # TODO: test credit transfers.

  # ID 1..14
  Amounts = [
    100, -400, -500, 200, # Initial balances
    75, 125,              # expenditure and income
    100, 100, 100, 100,   # 2 transfers
    25, 25, 50, 50,       # another 2 transfers
  ]

  def test_amount
    @all.zip(Amounts).each do |transaction, amount|
      assert_equal amount, transaction.amount, "#{transaction.poid} incorrect amount"
    end
  end

  def test_validate_amount_integrity_errors
    assert_raises FeideeUtils::Transaction::InconsistentAmountException do
      FeideeUtils::Transaction.new(
        ["buyerAccountPOID", "buyerCategoryPOID", "sellerCategoryPOID", "buyerMoney", "sellerMoney"],
        [nil, nil, nil, nil, nil],
        [0, 0, 0, 0, 1])
    end
  end
end
