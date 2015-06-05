module FeideeUtils
  class Record
    module Accessors
      def poid
        @field[self.class.id_field_name]
      end

      def last_update_time
        timestamp_to_time(@field["lastUpdateTime"])
      end

      def last_update_time_str
        # Only date is in the timestamp. (on iOS)
        last_update_time.strftime("%F")
      end
    end
  end
end
