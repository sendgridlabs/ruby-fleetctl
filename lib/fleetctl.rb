require 'net/ssh'
require 'net/scp'
require 'hashie'

require 'fleetctl/version'
require 'fleetctl/command'
require 'fleetctl/runner/runner'
require 'fleetctl/runner/ssh'
require 'fleetctl/runner/shell'
require 'fleetctl/table_parser'
require 'fleetctl/options'
require 'fleetctl/remote_tempfile'

require 'fleet/item_set'
require 'fleet/unit'
require 'fleet/machine'
require 'fleet/controller'
require 'fleet/discovery'
require 'fleet/cluster'

module Fleetctl
  class << self
    # use if you might need more than one fleet
    def new(*args)
      Fleet::Controller.new(*args)
    end
  end
end
