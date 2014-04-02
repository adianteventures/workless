require 'heroku-api'

module Delayed
  module Workless
    module Scaler
      class HerokuCedar < Base
        extend Delayed::Workless::Scaler::HerokuClient
        
        # must set current workers = workers_needed
        def self.up
          client.post_ps_scale(ENV['APP_NAME'], 'worker', self.workers_needed)
        end
        
        # must set current workers = min_workers
        def self.down
          client.post_ps_scale(ENV['APP_NAME'], 'worker', self.min_workers)
        end
        
        # returns how many workers are currently running
        def self.scaler_workers
          client.get_ps(ENV['APP_NAME']).body.count { |p| p["process"] =~ /worker\.\d?/ }
        end
        
      end
    end
  end
end