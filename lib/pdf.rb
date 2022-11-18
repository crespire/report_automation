require 'csv'
require 'date'
require 'time'
require 'erb'
require 'wicked_pdf'
require 'fileutils'
require_relative 'clockify'
require_relative 'days'

##
# This class transforms API qeury data into the PDF files for output.

class OutputPdf
  include Days

  ##
  # Initalize all instance variables
  def initialize
    @projects = Hash.new do |hash, key| 
      hash[key] = Hash.new do |projects, week|
        projects[week] = Hash.new do |week, user|
          week[user] = Hash.new do |user, day|
            user[day] = []
          end
        end
      end
    end
    @billed_tasks = Hash.new { |hash, key| hash[key] = [] }
    @end_date = Date.today
    @year_changed = false
    @client = File.open('.defaultclient') { |file| file.readline }
    @api = Clockify.new
  end

  ##
  # Sets the end_date to Dec 31 of the year specified.

  def change_year
    print 'What year would you like to retrieve? '
    input = gets.chomp
    @end_date = Date.new(input.to_i, 12, 31)
    @year_changed = true
  end

  ##
  # Set non-default client
  def change_client
    client_list = @api.get_client_list
    selected_client = nil
    names = client_list.map { |client| client['name'] }
    puts 'Clients available:'
    names.each { |client| puts client }
    until names.include?(selected_client)
      print 'Which client shall we query? '
      selected_client = gets.chomp
    end
    @client = selected_client
  end

  ##
  # Queries API for data
  # If the year has not changed, the report is only pulled to the last Sunday.
  # If the year has changed, the last day is set to December 31 of the specified year.
  def get_report
    api = Clockify.new
    last_day = @year_changed ? @end_date : Days.prior_weekday(@end_date, 'Sunday')
    year_start = Date.ordinal(last_day.year, 1)
    json = api.detailed_report(@client, year_start, last_day)

    abort("JSON: #{json['code']} > #{json['message']}") if json.key?('code')

    json['timeentries'].each do |entry|
      float_time = entry['timeInterval']['duration'] / (60 * 60.0)

      if entry['tags'].any? { |hash| hash.value?('Billed') }
        @billed_tasks[entry['projectName']].push(float_time)
        next
      end

      date = Date.iso8601(entry['timeInterval']['start'])
      week = date.cweek
      @projects[entry['projectName']][week][entry['userName']][date] << float_time
    end

    true
  end

  ##
  # Outputs PDF to spec

  def output(base_dir)
    if @projects.size.positive?
      report_template = File.read("#{__dir__}/report_template.erb")
      erb = ERB.new(report_template, trim_mode: '<>')

      date = Days.prior_weekday(@end_date, 'Friday')
      output_dir = "#{base_dir}#{@end_date.cwyear}/wk#{@end_date.cweek}/pdf-gen-#{Date.today.strftime("%Y%b%d")}"
      puts "Output dir: #{output_dir}"
      FileUtils.mkdir_p output_dir unless Dir.exist?(output_dir)
      puts '-' * 80
      puts 'Each project below will require input on days already billed.'
      @projects.each_key { |proj| puts "-> #{proj}" }

      puts "Enter 'skip' or 's' to skip output for that project."
      puts '-' * 80
      puts
      @projects.each do |proj, weeks|
        print "Total days invoiced on #{proj}: "
        days_billed = gets.chomp
        next if %w[skip s].include?(days_billed)

        days_billed = days_billed.gsub(/\s+/, '').split('+').sum(&:to_f)
        prev_billed_days = @billed_tasks.key?(proj) ? (@billed_tasks[proj].sum / 8).round(1) : 0
        report = erb.result(binding)
        filename = "#{output_dir}/#{@client}_#{proj} Report.pdf"
        pdf = WickedPdf.new.pdf_from_string(report)
        File.open(filename, 'w') { |file| file.puts pdf }
      end
    else
      puts 'No unbilled tasks found, a summary of all the billed tasks processed follows.'
      @billed_tasks.each do |k, v|
        puts "=> Project: #{k} has #{(v.reduce(:+) / 8).round(1)} billed days."
      end
    end

    true
  end
end
