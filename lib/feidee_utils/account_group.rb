require 'feidee_utils/record'
require 'feidee_utils/mixins/parent_and_path'

module FeideeUtils
  class AccountGroup < Record
    include FeideeUtils::Mixins::ParentAndPath

    def validate_integrity
      validate_depth_integrity
      validate_one_level_path_integrity

      unless (poid == 1 and raw_type == -1) or (raw_type >= 0 and raw_type <= 2)
        raise "Unexpected account group type #{raw_type}.\n" + inspect
      end
    end

    FieldMappings = {
      name:                   "name",
      parent_poid:            "parentAccountGroupPOID",
      raw_path:               "path",
      depth:                  "depth",
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
      0 => :asset,
      1 => :liability,
      2 => :claim,
    }

    def type
      TypeEnum[raw_type]
    end

    # Schema
    # accountGroupPOID long not null
    # name varchar(100) not null
    # parentAccountGroupPOID long not null
    # path varchar(200)
    # depth integer
    # lastUpdateTime long
    # userTradingEntityPOID long
    # _tempIconName varchar(100) default defaultAccountGroupIcon
    # type integer default 1
    # ordered integer default 0
  end
end
