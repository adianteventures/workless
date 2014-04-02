require 'heroku-api'

module Delayed
  module Workless
    module Scaler
      class HerokuCedar < Base
        extend Delayed::Workless::Scaler::HerokuClient

        def self.up
          client.post_ps_scale(ENV['APP_NAME'], 'worker', self.workers_needed) if self.workers_needed > self.min_workers and self.workers < self.workers_needed
        end

        def self.down
          client.post_ps_scale(ENV['APP_NAME'], 'worker', self.min_workers) unless self.jobs.count > 0 or self.workers == self.min_workers
        end

        def self.workers
          client.get_ps(ENV['APP_NAME']).body.count { |p| p["process"] =~ /worker\.\d?/ }
        end
        
      end
    end
  end
end