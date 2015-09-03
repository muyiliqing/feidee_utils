require "feidee_utils/category"
require "feidee_utils/database"
require 'minitest/autorun'
require 'pathname'

class CategoryTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @sqlite_db = FeideeUtils::Database.open_file(base_path.join("../data/QiQiTest.sqlite"))

    @expenditure = @sqlite_db.namespaced::Category.find_by_id(-1)
    @meals = @sqlite_db.namespaced::Category.find_by_id(-18)
    @income = @sqlite_db.namespaced::Category.find_by_id(-56)
    @salary = @sqlite_db.namespaced::Category.find_by_id(-57)
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

  def test_parent
    assert_equal @income.poid, @salary.parent_poid
  end

  def test_path
    nodes = @meals.path.split("/")
    assert_equal "", nodes[0]
    assert_equal @expenditure.poid, Integer(nodes[1])
    assert_equal @meals.parent_poid, Integer(nodes[2])
    assert_equal @meals.poid, Integer(nodes[3])
  end

  def test_depth
    assert_equal 2, @meals.depth
    assert_equal 1, @salary.depth
    assert_equal 0, @expenditure.depth
    assert_equal 0, @income.depth
  end
end
