
module FeideeUtils
  class Account < Record
    module ClassMethods
      def entity_name
        "account"
      end
    end
    module Accessors
    end
    extend ClassMethods
    include Accessors
  end
end
