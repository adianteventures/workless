require 'rush'

module Delayed
  module Workless
    module Scaler
      class Local < Base

        def self.executable_prefix
          if defined? Delayed::Compatibility.executable_prefix
            Delayed::Compatibility.executable_prefix
          else
            'script'
          end
        end
        
        
        def self.up
          # puts ">>>>>>>>>> self.up! jobs:#{jobs.count} | workers:#{self.workers} | needed:#{self.workers_needed}"
          if self.workers_needed > self.min_workers and self.workers < self.workers_needed
            (self.workers+1).upto(self.workers_needed).each do |worker_id|
              Rush::Box.new[Rails.root].bash("#{executable_prefix}/delayed_job start -i workless.#{worker_id}", :background => true)
              sleep 1
            end
          end
          true
        end
        
        def self.down
          # puts ">>>>>>>>>> self.down! jobs:#{jobs.count} | workers:#{self.workers}"
          if (jobs.count == 0)
            if (self.workers > 0)
              # add 5 if pending workers with higher index
              (self.workers+5).downto(1).each do |worker_id|
                Rush::Box.new[Rails.root].bash("#{executable_prefix}/delayed_job stop -i workless.#{worker_id}", :background => true)
              end
            end
          end
          true
        end
        
        def self.workers
          Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless|delayed_job.workless/).size
        end
        
        
        # Returns the number of workers needed based on the current number of pending jobs and the settings defined by:
        #
        # ENV['WORKLESS_WORKERS_RATIO']
        # ENV['WORKLESS_MAX_WORKERS']
        # ENV['WORKLESS_MIN_WORKERS']
        #
        def self.workers_needed
          [[(self.jobs.count.to_f / self.workers_ratio).ceil, self.max_workers].min, self.min_workers].max
        end
        
        def self.workers_ratio
          if ENV['WORKLESS_WORKERS_RATIO'].present? && (ENV['WORKLESS_WORKERS_RATIO'].to_i != 0)
            ENV['WORKLESS_WORKERS_RATIO'].to_i
          else
            100
          end
        end
        
        def self.max_workers
          ENV['WORKLESS_MAX_WORKERS'].present? ? ENV['WORKLESS_MAX_WORKERS'].to_i : 1
        end
        
        def self.min_workers
          ENV['WORKLESS_MIN_WORKERS'].present? ? ENV['WORKLESS_MIN_WORKERS'].to_i : 0
        end
        
        
      end
    end
  end
end
