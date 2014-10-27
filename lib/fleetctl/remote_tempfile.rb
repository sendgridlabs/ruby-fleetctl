module Fleetctl
  class RemoteTempfile
    class << self
      def open(options, local_file)
        remote_path = File.join(options.remote_temp_dir, File.basename(local_file.path))
        Net::SCP.upload!(options.fleet_host, options.fleet_user, local_file.path, remote_path, :ssh => options.ssh_options)
        yield(remote_path)
        Net::SSH.start(options.fleet_host, options.fleet_user, options.ssh_options) { |ssh| ssh.exec!("rm #{remote_path}") }
      end
    end
  end
end
