require "feidee_utils/record/modified_record"
require 'minitest/autorun'
require 'sqlite3'

class FeideeUtils::Record::ModifiedRecordTest < MiniTest::Test
  class FakeRecord
    attr_accessor :field, :poid, :field_a
    def initialize(poid, field_a, field)
      @poid = poid
      @field_a = field_a
      @field = field
    end

    def field_b
      "Base.FieldB " + poid.to_s
    end
  end

  class FakeModifiedRecord < FeideeUtils::Record::ModifiedRecord
    define_custom_methods([:field_a, :field_b])
    define_default_methods({
      bname: "base_name",
      btype: "base_type"
    })
  end

  def setup
    poid = 123

    @base = FakeRecord.new(poid, "base", {
      "base_name" => "base123",
      "base_type" => "type123",
    });

    @head = FakeRecord.new(poid, "head", {
      "base_name" => "base421",
      "base_type" => "type123",
    });

    @derive = FakeRecord.new(poid, "base", {
      "base_name" => "base123",
      "base_type" => "type123",
      "others" => "others",
    });

    @fake_modified_record = FakeModifiedRecord.new(poid, @base, @head)
    @fake_untouched_record = FakeModifiedRecord.new(poid, @base, @base)
    @fake_unmodified_record = FakeModifiedRecord.new(poid, @base, @derive)
  end

  def test_custom_methods
    assert @fake_modified_record.field_a_changed?
    assert "base", @fake_modified_record.field_a.old_value
    assert "head", @fake_modified_record.field_a.new_value
    refute @fake_modified_record.field_b_changed?
  end

  def test_default_methods
    assert @fake_modified_record.bname_changed?
    assert "base123", @fake_modified_record.bname.old_value
    assert "base421", @fake_modified_record.bname.new_value
    refute @fake_modified_record.btype_changed?
  end

  def test_changed?
    assert @fake_modified_record.changed?
    refute @fake_unmodified_record.changed?
    refute @fake_untouched_record.changed?
  end

  def test_touched?
    assert @fake_modified_record.touched?
    assert @fake_unmodified_record.touched?
    refute @fake_untouched_record.touched?
  end
end
