require "feidee_utils/mixins/type"
require 'minitest/autorun'

class FeideeUtils::Mixins::TypeTest < MiniTest::Test
  class TestClass
    include FeideeUtils::Mixins::Type
    attr_accessor :raw_type

    define_type_enum({
      0 => :abc,
      1 => :xyz,
    })
  end

  def setup
    @type0 = TestClass.new
    @type0.raw_type = 0

    @type1 = TestClass.new
    @type1.raw_type = 1
  end

  def test_type
    assert_equal :abc, @type0.type
    assert_equal :xyz, @type1.type
  end

  def test_type_code
    assert_equal 0, (TestClass.type_code :abc)
    assert_equal 1, (TestClass.type_code :xyz)
  end

  def test_define_const
    refute_nil TestClass::TypeEnum
    refute_nil TestClass::TypeCode
    assert_equal :abc, TestClass::TypeEnum[0]
    assert_equal :xyz, TestClass::TypeEnum[1]
    assert_equal 0, TestClass::TypeCode[:abc]
    assert_equal 1, TestClass::TypeCode[:xyz]
  end

  def test_duplicate_enum
    klass = Class.new do
      include FeideeUtils::Mixins::Type
      define_type_enum({
        0 => :abc,
        1 => :xyz,
        2 => :abc,
      })
    end
    assert_equal ({}), klass::TypeCode
  end
end
