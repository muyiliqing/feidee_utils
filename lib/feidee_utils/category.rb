require 'feidee_utils/record'
require 'feidee_utils/mixins/parent_and_path'
require 'feidee_utils/mixins/type'

module FeideeUtils
  class Category < Record
    include FeideeUtils::Mixins::ParentAndPath
    include FeideeUtils::Mixins::Type

    def validate_integrity
      validate_depth_integrity
      validate_one_level_path_integrity
      unless field["usedCount"] == 0
        raise "Category usedCount should always be 0, " +
          "but it's #{field["usedCount"]}.\n" +
          inspect
      end
    end

    ProjectRootTypeCode = 2

    def self.validate_global_integrity
      if TypeEnum[ProjectRootTypeCode] != :project_root
        raise "The type code of project root has been changed," +
          " please update the code."
      end

      rows = self.database.execute <<-SQL
        SELECT #{id_field_name}, #{FieldMappings[:name]} FROM #{table_name}
        WHERE #{FieldMappings[:raw_type]}=#{ProjectRootTypeCode};
      SQL

      if rows.length > 1
        poids = rows.map do |row| row[0] end
        raise "More than one category have type project_root." +
          " IDs are #{poids.inspect}."
      elsif rows.length == 1
        category_name = rows[0][1]
        if category_name != "projectRoot" and category_name != "root"
          raise "Category #{category_name} has type project_root." +
            " ID: #{rows[0][0]}."
        end
      end
    end

    FieldMappings = {
      name:                   "name",
      parent_poid:            "parentCategoryPOID",
      raw_path:               "path",
      depth:                  "depth",
      raw_type:               "type",
      ordered:                "ordered",
    }.freeze

    IgnoredFields = [
      "userTradingEntityPOID", # Foreign key to t_user.
      "_tempIconName",         # Icon name in the app
      "usedCount",             # Always 0.
      "clientID",              # Always equal to poid.
    ].freeze

    define_accessors(FieldMappings)

    define_type_enum({
      0 => :expenditure,
      1 => :income,
      2 => :project_root, # unkown
    })

    def to_s
      "#{name} (Category/#{poid})"
    end

    # Schema
    # categoryPOID LONG NOT NULL
    # name varchar(100) NOT NULL
    # parentCategoryPOID LONG NOT NULL
    # path VARCHAR(200)
    # depth INTEGER
    # lastUpdateTime LONG
    # userTradingEntityPOID LONG
    # _tempIconName VARCHAR(100) DEFAULT defaultIcon,
    # usedCount integer default 0,
    # type integer default 0,
    # ordered integer default 0,
    # clientID LONG default 0,
  end
end
