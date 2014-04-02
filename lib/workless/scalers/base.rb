require 'delayed_job'

module Delayed
  module Workless
    module Scaler
      
      # configure in initializer like this
      #   Delayed::Job.scaler = :heroku_cedar
      #   Delayed::Workless::Scaler::Base.min_workers = 0
      #   Delayed::Workless::Scaler::Base.max_workers = 2
      #   Delayed::Workless::Scaler::Base.workers_ratio = 50
      #   Delayed::Workless::Scaler::Base.worker_count_sync_max_interval_seconds = 1.minute
      #   Delayed::Workless::Scaler::Base.job_run_at_max_interval_seconds = 2.minutes
      
      
      class Base
        
        cattr_accessor :min_workers, :max_workers, :workers_ratio, :worker_count_sync_max_interval_seconds, :job_run_at_max_interval_seconds
        
        def self.reset
          self.min_workers      = 0
          self.max_workers      = 1
          self.workers_ratio    = 1000000
          # in order to prevent excesive heroku-API calls, 
          #   the number is cached and cache expires after worker_count_sync_max_interval_seconds
          self.worker_count_sync_max_interval_seconds = 1.minute
          # when checking delayed_job table for pending jobs, how much time in-the-future
          #   jobs are considered as pending-for-immediate-execution.
          #   Jobs with run_at further than (NOW + job_run_at_max_interval_seconds) will not be considered
          #   so job-count may be 0, and workers will stop
          # IMPORTANT!
          #   It is application responsibility to restart at least 1 worker in the future to get these
          #   future-jobs done. For example, a cron-task that starts an empty delayed_job-operation
          self.job_run_at_max_interval_seconds = 2.minutes
          
          @_workers = nil
          @_workers_next_sync_at = nil
        end

        reset
        
        
        # consider "jobs" as Delayed::Jobs that MUST be executed immediately or in a "short" amount of time
        #   the period to check for next jobs is configurable through job_run_at_max_interval_seconds
        def self.jobs
          if Rails.version >= "3.0.0"
            Delayed::Job.where("(failed_at IS NULL) AND (run_at < ?)", (DateTime.now + self.job_run_at_max_interval_seconds.seconds) )
          else
            Delayed::Job.all(:conditions => { :failed_at => nil })
          end
        end
        
        # how many workers are required for current "jobs"
        #   MIN: min_workers
        #   MAX: max_workers
        #   1 worker each workers_ratio pending-jobs
        def self.workers_needed
          [[(self.jobs.count.to_f / self.workers_ratio).ceil, self.max_workers].min, self.min_workers].max
        end
        
        # synchronize current running-workers with real implementation
        def self.sync_workers
          @_workers = self.scaler_workers
          @_workers_next_sync_at = DateTime.now + self.worker_count_sync_max_interval_seconds.seconds
        end
        
        # how many workers are currently running
        #   in order to prevent excesive heroku-API calls, 
        #   the number is cached and expired after worker_count_sync_max_interval_seconds
        def self.workers
          if (@_workers.nil? || @_workers_next_sync_at.nil?)
            self.sync_workers
          end
          if (DateTime.now > @_workers_next_sync_at)
            self.sync_workers
          end
          return @_workers
        end
        
        # this is triggered on Delayed::Job table changes (after_commit all)
        #   triggers Scaler.up when workers_needed > workers
        #   triggers Scaler.down when jobs = 0
        def self.up_or_down
          # puts ">>>>>>>>>> self.up_or_down! jobs:#{self.jobs.count} | workers:#{self.workers} | needed:#{self.workers_needed} | min:#{self.min_workers} | max:#{self.max_workers} | ratio:#{self.workers_ratio}"
          if (self.workers_needed > self.workers)
            self.up
            @_workers = self.workers_needed
          elsif (self.jobs.count == 0)
            if (self.workers > self.min_workers)
              self.down
            end
            @_workers = 0
          end
          return true
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
