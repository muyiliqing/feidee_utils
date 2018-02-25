module FeideeUtils
  class Record
    module Computed
      module ClassMethods
        def computed field_name, &block
          var_name = ("@" + field_name.to_s).to_sym
          define_method field_name do
            if instance_variable_defined? var_name
              instance_variable_get var_name
            else
              val = instance_exec &block
              instance_variable_set var_name, val
            end
          end
        end
      end
    end
  end
end
