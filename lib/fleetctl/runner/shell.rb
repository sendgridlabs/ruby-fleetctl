module Fleetctl
  module Runner
    class Shell < ::Fleetctl::Runner::Runner
      def run(*)
        return @output if @output
        @options.logger.info "#{self.class.name} RUNNING: #{command}"
        @stdout_data = `#{command}`
        @status = $?

        @exit_signal = @status.termsig
        @exit_code = @status.exitstatus
        @options.logger.info "EXIT CODE!: #{@exit_code.inspect}"
        @options.logger.info "STDOUT: #{@output.inspect}"
        @output = @stdout_data
      end
    end
  end
end
