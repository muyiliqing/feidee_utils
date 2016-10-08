require 'feidee_utils'
require "feidee_utils_test"
require 'minitest/autorun'

require 'pathname'

class FeideeUtils::IntegrationTest < MiniTest::Test
  def setup
    base_path = Pathname.new(File.dirname(__FILE__))
    @sqlite_db = FeideeUtils::Database.open_file(base_path.join("../data/QiQiTest.sqlite"))
    @complex_android_backup = FeideeUtils::Database.open_file(base_path.join("../data/Daily_20140401.sqlite"))
  end

  def do_test_field_coverage sqlite_db
    # All mapped fields must exist. All fields must either be mapped or
    # ignored.
    FeideeUtils::Record.child_classes.each do |klass|
      row = sqlite_db.query("SELECT * FROM #{klass.table_name} LIMIT 1");
      existing_fields = (Set.new row.columns) -
        # Two fields covered by accessors.rb
        [klass.id_field_name, "lastUpdateTime"]

      mapped_fields = Set.new (klass.const_get :FieldMappings).values
      ignored_fields = Set.new (klass.const_get :IgnoredFields)

      # Mapped fields are a subset of exising fields.
      assert mapped_fields.subset?(existing_fields),
        "Mapped fields #{mapped_fields - existing_fields} does not appear."

      # Fields other than those mapped must be a subset of ignored fields.
      non_mapped_fields = existing_fields - mapped_fields
      assert non_mapped_fields.subset?(ignored_fields),
        "Fields #{(non_mapped_fields - ignored_fields).to_a} are not covered."
    end
  end

  def test_field_coverage_android
    do_test_field_coverage @complex_android_backup
  end

  def test_field_coverage_ios
    do_test_field_coverage @sqlite_db
  end
end
