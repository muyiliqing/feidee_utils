require "feidee_utils/mixins/parent_and_path"
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

  def test_define_const
    refute_nil TestClass::TypeEnum
    assert_equal :abc, TestClass::TypeEnum[0]
    assert_equal :xyz, TestClass::TypeEnum[1]
  end
end
