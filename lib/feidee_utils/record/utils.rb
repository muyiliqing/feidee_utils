require 'tzinfo'

module FeideeUtils
  class Record
    module Utils
      # Feidee assumes all users are in China and uses China Standard Time.
      # It gets a local time, e.g. 2017-12-09 11:30 DST and treats it as
      # 2017-12-09 11:30 CST, then convert it to UTC time 2017-12-09 03:30 UTC.
      # Timestamp stored in database is the UTC time.
      AssumedTimezone = TZInfo::Timezone.get("Asia/Shanghai")

      protected
      # To get the local time, first we convert timestamp to UTC time
      # 2017-12-09 03:00 UTC, then get the corresponding time in
      # AssumedTimezone.
      # Note utc_to_local() would return 2017-12-09 11:30 UTC, of which the
      # timezone is different from physical timezone CST. The actual timezone
      # has been lost when the timestamp was written to database.
      def timestamp_to_time num
        AssumedTimezone.utc_to_local(Time.at(num / 1000.0, num % 1000).utc)
      end

      def to_bigdecimal number
        # Be aware of the precision lost from String -> Float -> BigDecimal.
        BigDecimal.new(number, 12).round(2)
      end
    end
  end
end
