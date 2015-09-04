require 'feidee_utils/record'

module FeideeUtils
  class Category < Record
    module ClassMethods
      def entity_name
        "category"
      end
    end

    extend ClassMethods

    class InconsistentDepthException < Exception
    end

    def validate_integrity
      path_depth = path.split("/").length - 2
      raise InconsistentDepthException.new("Path is #{path}, but the given depth is #{depth}") if path_depth != depth
    end

    FieldMappings = {
      name:                   "name",
      parent_poid:            "parentCategoryPOID",
      path:                   "path",
      depth:                  "depth",
      used_count:             "usedCount",
      raw_type:               "type",
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
