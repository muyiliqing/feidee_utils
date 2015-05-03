
module FeideeUtils
  class Account < Record
    module ClassMethods
      def entity_name
        "account"
      end
    end
    extend ClassMethods
  end
end
