require 'json'
require 'net/http'

##
# This class represents the Clockify API, and has both the base and report endpoints built in.

class Clockify

  ##
  # Creates a new instance of the API and initializes the API key.

  def initialize
    @authkey = File.open('.clkapi') { |file| file.readline }
    @ds = "workspaces/5d25eb05ee947d28bf3262b7"
    @uri_reports = "https://reports.api.clockify.me/v1"
    @uri_base = "https://api.clockify.me/api/v1"
    @clients = nil
  end

  ##
  # Populates the @clients variable with the API response.
  #
  # The option boolean +force+ can be provided to update from API even if client list is populated. It defaults to false.

  def get_client_list(force: false)
    return true unless @clients.nil? || force

    endpoint = "#{@uri_base}/#{@ds}/clients"
    query = '?archived=false&page-size=5000'
    uri = URI(endpoint + query)
    request = Net::HTTP::Get.new(uri, { 'Content-Type': 'application/json', 'X-Api-Key': @authkey })
    response = Net::HTTP::start(uri.hostname, uri.port, use_ssl:true) { |http| http.request(request) }
    @clients = JSON.parse(response.body)
  end

  ##
  # Retreives the client ID based on +search+ name provided.

  def get_client_id(search)
    get_client_list if @clients.nil?

    @clients.each do |client|
      return client['id'] if client['name'].include?(search)
    end
  end

  ##
  # Creates a detailed report based on the inputs provided.
  #
  # +client+ is a string representation of the client's name.
  #
  # +start_date+ is a string in the number format "%Y-%m-%d"
  #
  # +end_date+ is a string in the number format "%Y-%m-%d"

  def detailed_report(client, start_date, end_date)
    puts "Requesting data for #{client} from #{start_date} to #{end_date}"
    client_id = get_client_id(client)
    endpoint = "#{@uri_reports}/#{@ds}/reports/detailed"
    uri = URI(endpoint)
    request = Net::HTTP::Post.new(uri, {'Content-Type': 'application/json', 'X-Api-Key': @authkey})
    request.body = {
      # Required Info
      dateRangeStart: "#{start_date}T00:00:00.000",
      dateRangeEnd: "#{end_date}T23:59:59.000",
      detailedFilter: {
        page: 1,
        pageSize: 1000
      },

      # Filters
      exportType: 'JSON',
      clients: {
        contains: 'CONTAINS',
        ids: [client_id]
      },
      archived: false
    }.to_json
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    JSON.parse(response.body)
  end
end
