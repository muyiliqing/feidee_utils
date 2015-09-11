require 'feidee_utils/record'
require 'feidee_utils/mixins/parent_and_path'

module FeideeUtils
  class Category < Record
    include FeideeUtils::Mixins::ParentAndPath

    def validate_integrity
      validate_depth_integrity
      validate_one_level_path_integrity
    end

    FieldMappings = {
      name:                   "name",
      parent_poid:            "parentCategoryPOID",
      raw_path:               "path",
      depth:                  "depth",
      # TODO: used count is always 0. Show this in the code.
      used_count:             "usedCount",
      raw_type:               "type",
      # TODO: add a test and global validation for ordered.
      ordered:                "ordered",
    }

    IgnoredFields = [
      "userTradingEntityPOID", # WTF
      "_tempIconName",         # Icon name in the app
      "clientID",              # WTF
    ]

    define_accessors(FieldMappings)

    TypeEnum = {
      0 => :expenditure,
      1 => :income,
      2 => :project_root, # unkown
    }

    def type
      TypeEnum[raw_type]
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
