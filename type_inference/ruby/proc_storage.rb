require 'singleton'
module Archruby
  module Ruby
    module TypeInference
      module Ruby
        
        class ProcStorage
          include Singleton
          attr_reader :proc_definitions, :last_added_proc
          
          def add_proc(proc)
            @proc_definitions ||= {}
            @proc_definitions["Proc##{proc.id}"] = proc
            @last_added_proc = proc
          end
          
          
          
        end
      end
    end
  end
end