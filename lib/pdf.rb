require 'csv'
require 'date'
require 'time'
require 'erb'
require 'wicked_pdf'
require 'fileutils'
require_relative 'days'

##
# This class transforms API qeury data into the PDF files for output.

class OutputPdf
  include Days

  ##
  # Initalize all instance variables
  def initialize(api)
    @api = api
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
    @client = nil
    @last_day = nil
    @first_day = nil
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
  # Set client via API
  def set_client
    @client = @api.set_client
  end

  ##
  # Queries API for data
  # If the year has not changed, the report is pulled to yesterday.
  # If the year has changed, the last day is set to December 31 of the specified year.
  def get_report
    @last_day = @year_changed ? @end_date : Days.yesterday
    @first_day = Date.ordinal(@last_day.year, 1)
    json = @api.detailed_report(@first_day, @last_day)

    abort("JSON: #{json['code']} > #{json['message']}") if json.key?('code')

    json['timeentries'].each do |entry|
      float_time = entry['timeInterval']['duration'] / (60 * 60.0)
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

      output_dir = "#{base_dir}/#{@end_date.cwyear}/wk#{@end_date.cweek}/pdf-gen-#{Date.today.strftime("%Y%b%d")}"
      puts "Output dir: #{output_dir}"
      FileUtils.mkdir_p output_dir unless Dir.exist?(output_dir)
      puts '-' * 80
      puts 'Each project below will require input on total effort in proposal.'
      @projects.each_key { |proj| puts "-> #{proj}" }

      puts "Enter nothing, 'skip' or 's' to skip output for that project."
      puts '-' * 80
      @projects.each do |proj, weeks|
        print "Total estimated effort/days on #{proj} proposal: "
        days_proposed = gets.chomp
        next if %w[skip s].include?(days_proposed) || days_proposed.length.zero?

        days_proposed = days_proposed.gsub(/\s+/, '').split('+').sum(&:to_f)
        report = erb.result(binding)
        filename = "#{output_dir}/#{@client}_#{proj} Report.pdf"
        pdf = WickedPdf.new.pdf_from_string(report)
        File.open(filename, 'w') { |file| file.puts pdf }
        puts "Report written to: #{filename}"
      end
    end

    true
  end
end
