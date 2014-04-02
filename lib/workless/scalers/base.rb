require 'delayed_job'

module Delayed
  module Workless
    module Scaler
  
      class Base
        
        cattr_accessor :min_workers, :max_workers, :workers_ratio
        
        def self.reset
          self.min_workers      = 0
          self.max_workers      = 1
          self.workers_ratio    = 1000000
        end

        reset
        
        
        def self.jobs
          if Rails.version >= "3.0.0"
            Delayed::Job.where(:failed_at => nil)
          else
            Delayed::Job.all(:conditions => { :failed_at => nil })
          end
        end
        
        def self.workers_needed
          [[(self.jobs.count.to_f / self.workers_ratio).ceil, self.max_workers].min, self.min_workers].max
        end
        
      end

      module HerokuClient

        def client
          @client ||= ::Heroku::API.new(:api_key => ENV['HEROKU_API_KEY'])
        end

      end

    end
  end
end
