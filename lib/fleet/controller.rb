module Fleet
  class Controller
    attr_writer :units
    attr_accessor :cluster
    attr_reader :options

    def initialize(cfg)
      @options = Fleetctl::Options.new(cfg)
      @cluster = Fleet::Cluster.new(controller: self)
    end

    def logger
      @options.logger
    end

    # returns an array of Fleet::Machine instances
    def machines
      cluster.machines
    end

    # returns an array of Fleet::Unit instances
    def units
      return @units.to_a if @units
      machines
      fetch_units
      @units.to_a
    end

    # refreshes local state to match the fleet cluster
    def sync
      build_fleet
      fetch_units
      true
    end

    # find a unitfile of a specific name
    def [](unit_name)
      units.detect { |u| u.name == unit_name }
    end

    # accepts one or more File objects, or an array of File objects
    def start(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:start, unitfiles)
      clear_units
      out
    end

    # accepts one or more File objects, or an array of File objects
    def submit(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:submit, unitfiles)
      clear_units
      out
    end

    # accepts one or more File objects, or an array of File objects
    def load(*unit_file_or_files)
      unitfiles = [*unit_file_or_files].flatten
      out = unitfile_operation(:load, unitfiles)
      clear_units
      out
    end

    def destroy(*unit_names)
      runner = Fleetctl::Command.run(@options, 'destroy', unit_names)
      clear_units
      runner.exit_code == 0
    end

    private

    def build_fleet
      cluster.discover!
    end

    def fleet_host
      cluster.fleet_host
    end

    def clear_units
      @units = nil
    end

    def unitfile_operation(command, files)
      clear_units
      if @options.runner_class.to_s == 'Shell'
        runner = Fleetctl::Command.run(@options, command.to_s, files.map(&:path))
      else
        runner = nil
        Fleetctl::RemoteTempfile.open(@options, *files) do |*remote_filenames|
          runner = Fleetctl::Command.run(@options, command.to_s, remote_filenames)
        end
      end
      runner.exit_code == 0
    end

    def fetch_units(host: fleet_host)
      logger.info 'Fetching units from host: '+host.inspect
      @units = Fleet::ItemSet.new

      unit_hashes = nil

      Fleetctl::Command.new(@options, 'list-units', '-l', '-fields=unit,load,active,sub,desc,machine') do |runner|
        runner.run(host: host)
        unit_hashes = Fleetctl::TableParser.parse(@options, runner.output)
      end

      Fleetctl::Command.new(@options, 'list-unit-files', '-full', '-fields=unit,state') do |runner|
        runner.run(host: host)
        parse_units(runner.output, unit_hashes)
      end

      @units.to_a
    end

    def parse_units(raw_table, unit_initial_hashes)
      unit_hashes = Fleetctl::TableParser.parse(@options, raw_table)
      unit_initial_hashes.each do |unit_attrs|

        founded_units = unit_hashes.select do |u|
          unit_attrs[:unit] == u[:unit]
        end

        if founded_units.size == 1
          unit_attrs[:state] = founded_units[0][:state]
        end

        if unit_attrs[:machine]
          machine_id, machine_ip = unit_attrs[:machine].split('/')
          unit_attrs[:machine] = cluster.add_or_find(Fleet::Machine.new(id: machine_id, ip: machine_ip))
        end

        unit_attrs[:name] = unit_attrs.delete(:unit)
        unit_attrs[:controller] = self
        @units.add_or_find(Fleet::Unit.new(unit_attrs))
      end
    end


  end
end
