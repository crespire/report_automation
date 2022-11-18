require 'json'
require 'net/http'
require 'yaml'

CLOCKIFY = YAML.load_file('clockify.yml')

##
# This class represents the Clockify API, and has both the base and report endpoints built in.

class Clockify
  ##
  # Provides read access to the current client
  attr_reader :active_client

  ##
  # Creates a new instance of the API and initializes the API key.
  def initialize
    @authkey = CLOCKIFY['auth']
    @workspace = CONFIG['workspace']
    @uri_reports = "https://reports.api.clockify.me/v1"
    @uri_base = "https://api.clockify.me/api/v1"
    @clients = nil
    @active_client = nil
    @client_names = nil
  end

  ##
  # Populates the @clients variable with the JSON API response.
  #
  # The option boolean +force+ can be provided to update from API even if client list is populated. It defaults to false.

  def client_list(force: false)
    return true unless @clients.nil? || force

    endpoint = "#{@uri_base}/#{@workspace}/clients"
    query = '?archived=false&page-size=5000'
    uri = URI(endpoint + query)
    request = Net::HTTP::Get.new(uri, { 'Content-Type': 'application/json', 'X-Api-Key': @authkey })
    response = Net::HTTP::start(uri.hostname, uri.port, use_ssl:true) { |http| http.request(request) }
    @clients = JSON.parse(response.body)
  end

  ##
  # Retreives the client ID based on +search+ name provided.

  def client_id(search)
    client_list if @clients.nil?

    @clients.each do |client|
      return client['id'] if client['name'].include?(search)
    end
  end

  ##
  # Sets the active client for the API instance
  def set_client
    @clients ||= client_list
    selected_client = nil
    list_clients
    puts "There are #{@client_names.length} clients available."
    until @client_names.include?(selected_client)
      print 'Which client shall we query? '
      selected_client = gets.chomp
      puts "Client not found: #{selected_client}" unless @client_names.include?(selected_client)
      puts "You can also enter 'l' if you want to see the client list again." unless selected_client.nil? || @client_names.include?(selected_client)
      list_clients if selected_client == 'l'
    end
    @active_client = selected_client
  end

  ##
  # Creates a detailed report for the current +@active_client+ based on the date range provided.
  #
  # +start_date+ is a string in the number format "%Y-%m-%d"
  #
  # +end_date+ is a string in the number format "%Y-%m-%d"

  def detailed_report(start_date, end_date)
    @active_client ||= set_client
    puts "Requesting data for #{@active_client} from #{start_date} to #{end_date}"
    endpoint = "#{@uri_reports}/#{@workspace}/reports/detailed"
    uri = URI(endpoint)
    request = Net::HTTP::Post.new(uri, { 'Content-Type': 'application/json', 'X-Api-Key': @authkey })
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
        ids: [client_id(@active_client)]
      },
      archived: false
    }.to_json
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    JSON.parse(response.body)
  end

  private

  ##
  # List clients in terminal
  def list_clients
    @client_names ||= @clients.map { |client| client['name'] }
    puts 'Clients available:'
    @client_names.each { |client| puts "> #{client}" }
  end
end
