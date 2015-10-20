module FeideeUtils
  class Record
    # TODO: Reconsider this class and ship full support to all entities.
    class ModifiedRecord
      attr_reader :poid
      attr_reader :base, :head
      attr_reader :modified_fields

      def initialize(poid, base, head)
        raise "Base row doesn't have the given poid." if base.poid != poid
        raise "Head row doesn't have the given poid." if head.poid != poid
        @poid = poid
        @base = base
        @head = head
        @modified_fields = self.class.fields_diff(base.field, head.field)
      end

      class ValuePair
        attr_reader :old, :new
        def initialize(old, new)
          @old = old
          @new = new
        end
      end

      def self.fields_diff base, head
        (base.keys.sort | head.keys.sort).inject({}) do |hash, key|
          if base[key] != head[key]
            hash[key] = ValuePair.new(base[key], head[key])
          end
          hash
        end
      end

      def touched?
        !modified_fields.empty?
      end

      def changed?
        methods.inject(false) do |acc, name|
          if name.to_s.end_with? "_changed?"
            acc ||= send name
          end
          acc
        end
      end

      protected
      def self.define_custom_methods fields
        fields.each do |name|
          if !respond_to? name
            define_method name do
              ValuePair.new((base.send name), (head.send name))
            end
            define_method (name.to_s + "_changed?").to_sym do
              (base.send name) != (head.send name)
            end
          end
        end
      end

      def self.define_default_methods field_mappings
        field_mappings.each do |name, key|
          if !respond_to? name
            define_method name do
              modified_fields[key]
            end
            define_method (name.to_s + "_changed?").to_sym do
              modified_fields.has_key? key
            end
          end
        end
      end
    end
  end
end
