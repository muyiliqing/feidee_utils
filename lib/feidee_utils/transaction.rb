module FeideeUtils
  class Transaction < Record
    module ClassMethods
      def entity_name
        "transaction"
      end
    end

    extend ClassMethods
  end
end
