require 'set'

module FeideeUtils
  class Record
    module Namespaced
      module ClassMethods
        attr_reader :child_classes

        # Must be invoked by Record.inherited
        def collect_subclass(child_class)
          @child_classes ||= Set.new
          @child_classes.add(child_class)
        end

        # To use Record with different databases, generate a set of classes for
        # each db
        def generate_namespaced_record_classes(db)
          @child_classes ||= Set.new
          this = self
          Module.new do |mod|
            const_set(:Database, Module.new {
              define_method("database") { db }
              define_method("environment") { mod }
            })

            @contained_classes = this.child_classes.map do |child_class|
              if child_class.name.start_with? FeideeUtils.name
                class_name = child_class.name.sub(/#{FeideeUtils.name}::/, '')
                # Generate a const for the child class
                const_set(class_name, Class.new(child_class) {
                  extend mod::Database
                })
              end
            end

            def self.contained_classes
              @contained_classes
            end
          end
        end
      end
    end
  end
end
