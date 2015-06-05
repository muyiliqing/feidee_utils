module FeideeUtils
  class Record
    module Utils
      protected
      def timestamp_to_time num
        Time.at(num / 1000.0, num % 1000)
      end

      def self.to_bigdecimal number
        # Be aware of the precision lost from String -> Float -> BigDecimal.
        BigDecimal.new(number, 12).round(2)
      end
    end
  end
end
