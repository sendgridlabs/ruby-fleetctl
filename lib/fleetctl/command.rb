module Fleetctl
  class Command
    attr_accessor :command

    class << self
      def run(options, *cmd, &blk)
        obj = new(options, *cmd, &blk)
        obj.run
      end
    end

    def initialize(options, *cmd)
      @options = options
      @command = cmd
      yield(runner) if block_given?
    end

    def run(*args)
      runner.run(*args)
      runner
    end

    def runner
      klass = "Fleetctl::Runner::#{@options.runner_class}".constantize
      @runner ||= klass.new(@options, expression)
    end

    private

    def global_options
      @options.global.map { |k,v| "--#{k.to_s.gsub('_','-')}=#{v}" }
    end

    def prefix
      @options.command_prefix
    end

    def executable
      @options.executable
    end

    def expression
      [prefix, executable, global_options, command].flatten.compact.join(' ')
    end
  end
end
