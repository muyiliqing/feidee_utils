require "feidee_utils/account"
require "feidee_utils/database"
require 'minitest/autorun'
require 'pathname'

class FeideeUtils::AccountTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @sqlite_db = FeideeUtils::Database.open_file(base_path.join("../data/QiQiTest.sqlite"))

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
end
