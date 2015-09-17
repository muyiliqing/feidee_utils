require "feidee_utils/account"
require "feidee_utils/database"
require 'minitest/autorun'

class FeideeUtils::AccountTest < MiniTest::Test
  def setup
    @sqlite_db = FeideeUtils::TestUtils.open_test_sqlite

    @all = @sqlite_db.namespaced::Account.all

    @cash = @all.find do |account| account.name == "Cash" end
    @debit = @all.find do |account| account.name == "DebitCard" end

    @parent = @all.find do |account| account.name == "Parent" end
    @checking = @all.find do |account| account.name == "Checking" end
    @saving = @all.find do |account| account.name == "Saving" end

    @credit_one = @all.find do |account| account.name == "CreditOne" end
    @credit_two = @all.find do |account| account.name == "CreditTwo" end

    @hidden_cash = @all.find do |account| account.name == "HiddenCash" end

    @accounts = [
      @cash, @debit,
      @parent, @checking, @saving,
      @credit_one, @credit_two,
    ]
  end

  def test_fields
    assert_equal "Cash", @cash.name
    assert_equal "Parent", @parent.name

    assert_equal 250, @cash.raw_balance
    assert_equal 0, @credit_one.raw_balance

    # TODO: create a claim account and test raw_credit
    assert_equal 0, @cash.raw_credit

    assert_equal 0, @cash.raw_debit
    assert_equal 450, @credit_one.raw_debit

    # TODO: create a account with a different currency.
    assert_equal "CNY", @cash.currency

    assert_equal 0, @cash.parent_poid
    assert_equal (-22), @checking.parent_poid

    assert_equal "My precious", @cash.memo
    assert_equal 3, @cash.ordered

    assert_equal 3, @cash.account_group_poid
    assert_equal 14, @credit_one.account_group_poid

    assert_equal 0, @cash.raw_hidden
    assert_equal 1, @hidden_cash.raw_hidden
  end

  def test_name
    @accounts.each do |account| refute_nil account end
  end

  Balances = [
    250, 0,
    0, 100, 0,
    -450, -450,
  ]

  def test_balance
    @accounts.zip(Balances).each do |account, balance|
      assert_equal balance, account.balance, account.name + " balance incorrect: #{account.balance.to_s}."
    end
  end

  def test_currency
    @accounts.each do |account| assert_equal "CNY", account.currency, account.name + " currency incorrect." end
  end

  def test_parent_poid
    assert_equal @parent.poid, @checking.parent_poid
    assert_equal @parent.poid, @saving.parent_poid
    assert_equal (-1), @parent.parent_poid

    assert_equal 0, @cash.parent_poid
    assert_equal 0, @debit.parent_poid

    assert_equal 0, @credit_one.parent_poid
    assert_equal 0, @credit_two.parent_poid
  end

  def test_parent
    assert_equal @parent.poid, @checking.parent.poid
    assert_equal @parent.poid, @saving.parent.poid

    assert @checking.has_parent?
    assert @saving.has_parent?
    refute @parent.has_parent?
    refute @cash.has_parent?
    refute @debit.has_parent?
    refute @credit_one.has_parent?
    refute @credit_two.has_parent?

    assert @parent.flagged_as_parent?
    @accounts.each do |account| refute account.flagged_as_parent? if account.poid != @parent.poid end
  end

  def test_flat_parent_hierachy
    @accounts.each do |account| assert account.flat_parent_hierachy? end
    fake = @saving.clone

    fake.instance_variable_set :@field, fake.field.clone
    fake.field["parent"] = @checking.poid
    assert_equal @parent.poid, @saving.field["parent"]

    refute fake.flat_parent_hierachy?
  end

  def test_children
    assert_equal [@saving.poid, @checking.poid].sort, (@parent.children.map do |x| x.poid end).sort
  end

  def test_account_group_poid
    @accounts.each do |account| refute_nil account.account_group_poid end
  end

  def test_memo
    assert_equal "My precious", @cash.memo
  end

  def test_last_update_time
    @accounts.each do |account|
      assert_equal 2015, account.last_update_time.year
    end
  end

  def test_hidden
    assert @hidden_cash.hidden?
    @accounts.each do |account|
      refute account.hidden?
    end
  end

  def test_account_group
    @all.each do |account|
      assert_equal account.account_group_poid, account.account_group.poid,
        "Account group poid doesn't match at account #{account.inspect}."
    end

    assert_equal :asset, @cash.account_group.type
    assert_equal :asset, @parent.account_group.type
    assert_equal :asset, @checking.account_group.type
    assert_equal :liability, @credit_one.account_group.type
  end

  def test_validate_integrity_errors
    e = assert_raises do
      FeideeUtils::Account.new(["type"], [nil], ["x"])
    end
    assert e.message.start_with? "Account type should always be 0, but it's x."

    e = assert_raises do
      FeideeUtils::Account.new(["type", "usedCount"], [nil, nil], [0, "x"])
    end
    assert e.message.start_with? "Account usedCount should always be 0, but it's x."

    e = assert_raises do
      FeideeUtils::Account.new(["type", "usedCount", "uuid"], [nil, nil, nil], [0, 0, "x"])
    end
    assert e.message.start_with? "Account uuid should always be empty, but it's x."
  end

  def test_validate_integrity_flat_hierachy_errors
    fake = @saving.clone
    fake.instance_variable_set :@field, fake.field.clone
    fake.field["parent"] = @checking.poid
    e = assert_raises do
      fake.validate_integrity
    end

    assert e.message.start_with? "Account hierachy contains more than 2 levels."
  end

  def test_validate_integrity
    FeideeUtils::Account.new(
      ["type", "usedCount", "uuid", "parent"],
      [nil, nil, nil, nil],
      [0, 0, nil, 0])
  end

  def test_validate_integrity_globally_errors
    @sqlite_db.execute("INSERT INTO t_account VALUES(-1, 'invalid_account', -3, 1271747936000, 0, 3, 0, '', '', 0, 0, 0, 2, 0, 0, 0, 0, '')");
    e = assert_raises do
      @sqlite_db.namespaced::Account.validate_integrity_globally
    end
    assert_equal "-1 is used as the parent POID placeholder of a parent account. Account of POID -1 should not exist.", e.message
    @sqlite_db.execute("DELETE FROM t_account WHERE accountPOID = -1");
  end

  def test_validate_integrity_globally
    @sqlite_db.namespaced::Account.validate_integrity_globally
  end
end
