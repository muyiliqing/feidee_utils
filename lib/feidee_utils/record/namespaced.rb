module FeideeUtils
  class Record
    module Namespaced
      module ClassMethods
        attr_reader :child_classes

        def inherited(child_class)
          @child_classes ||= Set.new
          if child_class.name != nil && (child_class.name.start_with? FeideeUtils.name)
            @child_classes.add(child_class)
          end
        end

        # To use Record with different databases, generate a set of classes for each db
        def generate_namespaced_record_classes(db)
          @child_classes ||= Set.new
          this = self
          Module.new do |mod|
            const_set(:Database, Module.new {
              define_method("database") { db }
              define_method("environment") { mod }
            })

            this.child_classes.each do |child_class|
              if child_class.name.start_with? FeideeUtils.name
                class_name = child_class.name.sub(/#{FeideeUtils.name}::/, '')
                # Generate a const for the child class
                const_set(class_name, Class.new(child_class) {
                  extend mod::Database
                })
              end
            end
          end
        end
      end
    end
  end
end
