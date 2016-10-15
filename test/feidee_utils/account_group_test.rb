require "feidee_utils_test"
require "feidee_utils/account_group"
require "feidee_utils/database"
require 'minitest/autorun'

class FeideeUtils::AccountGroupTest < MiniTest::Test
  def setup
    @sqlite_db = FeideeUtils::TestUtils.open_test_sqlite
    @root = @sqlite_db.ledger::AccountGroup.find_by_id(1)
    @cash = @sqlite_db.ledger::AccountGroup.find_by_id(2)
    @pocket = @sqlite_db.ledger::AccountGroup.find_by_id(3)
    @financial = @sqlite_db.ledger::AccountGroup.find_by_id(4)
    @bank = @sqlite_db.ledger::AccountGroup.find_by_id(6)
    @liability = @sqlite_db.ledger::AccountGroup.find_by_id(12)
    @credit_card = @sqlite_db.ledger::AccountGroup.find_by_id(14)
    @claim = @sqlite_db.ledger::AccountGroup.find_by_id(15)

    @all = [@cash, @pocket, @financial, @bank, @liability, @credit_card, @claim]
  end

  def test_fields
    assert_equal "现金口袋", @pocket.name
    assert_equal "存折", @bank.name

    assert_equal 2, @pocket.parent_poid
    assert_equal 4, @bank.parent_poid

    assert_equal "/0001/0002/0003/", @pocket.raw_path
    assert_equal "/0001/0004/0006/", @bank.raw_path

    assert_equal 2, @pocket.depth
    assert_equal 1, @financial.depth

    assert_equal 0, @pocket.raw_type
    assert_equal 2, @claim.raw_type

    assert_equal 1, @pocket.ordered
    assert_equal 2, @bank.ordered
  end

  def test_name
    @all.each do |account_group| assert account_group.name.length > 0 end
  end

  def test_type
    assert_equal :asset, @cash.type
    assert_equal :asset, @pocket.type
    assert_equal :asset, @financial.type
    assert_equal :asset, @bank.type
    assert_equal :liability, @liability.type
    assert_equal :liability, @credit_card.type
    assert_equal :claim, @claim.type
  end

  def test_parent_poid
    assert_equal @cash.poid, @pocket.parent_poid
    assert_equal @financial.poid, @bank.parent_poid
    assert_equal @liability.poid, @credit_card.parent_poid
  end
end

