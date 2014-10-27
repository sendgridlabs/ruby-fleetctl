module Fleetctl
  module Runner
    class SSH < ::Fleetctl::Runner::Runner
      def run(host: @options.fleet_host, user: @options.fleet_user, ssh_options: {})
        begin
          ssh_options = Fleetctl.options.ssh_options.merge(ssh_options)
          # return @output if @output
          @options.logger.info "#{self.class.name} #{user}@#{host} RUNNING: #{command.inspect}"
          Net::SSH.start(host, user, ssh_options) do |ssh|
            @stdout_data = ''
            @stderr_data = ''
            @exit_code = nil
            @exit_signal = nil
            ssh.open_channel do |channel|
              channel.exec(command) do |ch, success|
                unless success
                  abort "FAILED: couldn't execute command (ssh.channel.exec)"
                end
                channel.on_data do |ch,data|
                  @stdout_data+=data
                end

                channel.on_extended_data do |ch,type,data|
                  @stderr_data+=data
                end

                channel.on_request('exit-status') do |ch,data|
                  @exit_code = data.read_long
                end

                channel.on_request('exit-signal') do |ch, data|
                  @exit_signal = data.read_long
                end
              end
            end
            ssh.loop
            @output = @stdout_data
          end
          @options.logger.info "EXIT CODE!: #{exit_code.inspect}"
          @options.logger.info "STDOUT: #{@output.inspect}"
          @output
        rescue => e
          @options.logger.error 'ERROR in Runner#run'
          @options.logger.error e.message
          @options.logger.error e.backtrace.join("\n")
          raise e
        end
      end
    end
  end
end
