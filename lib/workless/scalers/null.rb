module Delayed
  module Workless
    module Scaler

      class Null < Base
        
        def self.scaler_workers
          return 0
        end
        
        def self.up
        end

        def self.down
        end

      end
      
    end
  end
end
