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
        
        
        # must set current workers = workers_needed
        def self.up
          # puts ">>>>>>>>>> self.up! jobs:#{self.jobs.count} | workers:#{self.workers} | needed:#{self.workers_needed} | min:#{self.min_workers} | max:#{self.max_workers} | ratio:#{self.workers_ratio}"
          (self.scaler_workers+1).upto(self.workers_needed).each do |worker_id|
            Rush::Box.new[Rails.root].bash("#{executable_prefix}/delayed_job start -i workless.#{worker_id}", :background => true)
            sleep 1
          end
        end
        
        # must set current workers = min_workers
        def self.down
          # puts ">>>>>>>>>> self.down! jobs:#{self.jobs.count} | workers:#{self.workers} | needed:#{self.workers_needed} | min:#{self.min_workers} | max:#{self.max_workers} | ratio:#{self.workers_ratio}"
          # add 5 if pending workers with higher index
          (self.scaler_workers+5).downto(self.min_workers+1).each do |worker_id|
            Rush::Box.new[Rails.root].bash("#{executable_prefix}/delayed_job stop -i workless.#{worker_id}", :background => true)
          end
        end
        
        # returns how many workers are currently running
        def self.scaler_workers
          Rush::Box.new.processes.filter(:cmdline => /delayed_job start -i workless|delayed_job.workless/).size
        end
        
      end
    end
  end
end
