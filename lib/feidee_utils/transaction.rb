module FeideeUtils
  class Transaction < Record
    module ClassMethods
      def entity_name
        "transaction"
      end
    end

    module Accessors
    end

    extend ClassMethods
    include Accessors
  end
end
