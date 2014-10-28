module Fleet
  class Discovery
    class << self
      def hosts(options)
        new(options).hosts
      end
    end

    attr_accessor :discovery_url

    def initialize(options)
      @discovery_url = options.discovery_url
      @logger = options.logger
    end

    def data
      @data ||= JSON.parse(Net::HTTP.get(URI.parse(@discovery_url)))
    end

    def hosts
      begin
        data['node']['nodes'].map{|node| node['value'].split(':')[0..1].join(':').split('//').last}
      rescue => e
        @logger.error 'ERROR in Fleet::Discovery#hosts, returning empty set'
        @logger.error e.message
        @logger.error e.backtrace.join("\n")
        []
      end
    end
  end
end
