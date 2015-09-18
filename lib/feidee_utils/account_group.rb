require 'feidee_utils/record'
require 'feidee_utils/mixins/parent_and_path'
require 'feidee_utils/mixins/type'

module FeideeUtils
  class AccountGroup < Record
    include FeideeUtils::Mixins::ParentAndPath
    include FeideeUtils::Mixins::Type

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
      ordered:                "ordered",
    }.freeze

    IgnoredFields = [
      "userTradingEntityPOID", # WTF
      "_tempIconName",         # Icon name in the app
      "clientID",              # WTF
    ].freeze

    define_accessors(FieldMappings)

    define_type_enum({
      0 => :asset,
      1 => :liability,
      2 => :claim,
    })

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
