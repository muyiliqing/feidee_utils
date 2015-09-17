require "feidee_utils/category"
require "feidee_utils/database"
require 'minitest/autorun'

class FeideeUtils::CategoryTest < MiniTest::Test
  def setup
    @sqlite_db = FeideeUtils::TestUtils.open_test_sqlite

    @expenditure = @sqlite_db.namespaced::Category.find_by_id(-1)
    @meals = @sqlite_db.namespaced::Category.find_by_id(-16)
    @income = @sqlite_db.namespaced::Category.find_by_id(-56)
    @salary = @sqlite_db.namespaced::Category.find_by_id(-57)

    @fruit = @sqlite_db.namespaced::Category.find_by_id(-18)
  end

  def test_fields
    assert_equal "水果零食", @fruit.name
    assert_equal "职业收入", @salary.name

    assert_equal (-3), @fruit.parent_poid
    assert_equal (-56), @salary.parent_poid

    assert_equal "/-1/-3/-18/", @fruit.raw_path
    assert_equal "/-56/-57/", @salary.raw_path

    assert_equal 2, @fruit.depth
    assert_equal 1, @salary.depth

    assert_equal 0, @fruit.raw_type
    assert_equal 1, @salary.raw_type

    assert_equal 3, @fruit.ordered
    assert_equal 1, @salary.ordered
  end

  def test_name
    assert @meals.name.length > 0
    assert @salary.name.length > 0
  end

  def test_type
    assert_equal :expenditure, @expenditure.type
    assert_equal :expenditure, @meals.type
    assert_equal :income, @income.type
    assert_equal :income, @salary.type
  end

  def test_parent_poid
    assert_equal @income.poid, @salary.parent_poid
  end

  def test_depth
    assert_equal 2, @meals.depth
    assert_equal 1, @salary.depth
    assert_equal 0, @expenditure.depth
    assert_equal 0, @income.depth
  end
end
