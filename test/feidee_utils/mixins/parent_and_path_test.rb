require "feidee_utils/mixins/parent_and_path"
require 'minitest/autorun'

class FeideeUtils::Mixins::ParentAndPathTest < MiniTest::Test
  class TestClass
    include FeideeUtils::Mixins::ParentAndPath

    attr_accessor :raw_path, :depth, :parent_poid, :poid

    class << self
      @instances = {}
      attr_accessor :instances

      def find_by_id id
        return @instances[id]
      end
    end
  end

  def setup
    @child = TestClass.new
    @child.poid = 2
    @child.raw_path = "/1/2"
    @child.parent_poid = 1

    @parent = TestClass.new
    @parent.poid = 1
    @parent.raw_path = "/1"
    @parent.parent_poid = 0

    @other = TestClass.new
    @other.poid = 3
    @other.raw_path = "/3"
    @other.parent_poid = 0

    TestClass.instances = { 1 => @parent, 2 => @child, 3 => @other }
  end

  def test_validate_depth_integrity_errors
    @child.depth = 0
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentDepthException do
      @child.validate_depth_integrity
    end
  end

  def test_validate_depth_integrity
    @child.depth = 1
    @child.validate_depth_integrity
  end

  def test_path
    assert_equal [1, 2], @child.path
    assert_equal [1], @parent.path
  end

  def test_validate_path_integrity_hard_errors
    # Trace is longer.
    @parent.parent_poid = 3
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentPathException do
      @child.validate_path_integrity_hard
    end

    # Path is longer.
    @child.parent_poid = 0
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentPathException do
      @child.validate_path_integrity_hard
    end

    # Trace and path differs.
    @child.parent_poid = 3
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentPathException do
      @child.validate_path_integrity_hard
    end
  end

  def test_validate_path_integrity_hard
    @child.validate_path_integrity_hard
    @parent.validate_path_integrity_hard
  end

  def test_validate_one_level_path_integrity_errors
    @parent.raw_path = "/3"
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentPathException do
      @child.validate_one_level_path_integrity
    end

    # Wrong child POID.
    @child.poid = 3
    assert_raises FeideeUtils::Mixins::ParentAndPath::InconsistentPathException do
      @child.validate_one_level_path_integrity
    end
  end

  def test_validate_one_level_path_integrity
    @child.validate_one_level_path_integrity
    @parent.validate_one_level_path_integrity
  end

  def test_parent
    assert_equal @parent, @child.parent
  end

  def test_has_parent
    assert @child.has_parent?
    refute @parent.has_parent?
  end
end
