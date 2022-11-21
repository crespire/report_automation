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

  attr_reader :projects

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
    @project_budgets = {}
  end

  ##
  # Sets the end_date to Dec 31 of the year specified.

  def change_year(input = nil)
    if input
      if input.cwyear > Date.today.cwyear
        @end_date = Date.today
      else
        @end_date = input
        @year_changed = true
      end

      return
    end

    print 'What year would you like to retrieve? '
    input = gets.chomp
    check_date = Date.new(input.to_i, 12, 31)
    if check_date.cwyear > Date.today.cwyear
      puts 'Year selected is in the future, using current year.'
      sleep(1)
      return
    end

    @end_date = check_date
    @year_changed = true unless @end_date.cwyear == Date.today.cwyear
  end

  ##
  # Set client via API
  def set_client(input)
    @client = @api.set_client(input)
  end

  ##
  # Queries API for data
  # If current year, report runs from Jan 1 to yesterday.
  # If not current year, report runs from Jan 1 to Dec 31 of specified year.
  #
  # The rationale for confining the reports to year is primarily due to the
  # limtiations of the free Clockify API. It is easier for me to query two
  # reports and add them together, rather than deal with overlapping data if a
  # project crosses the annual boundary.
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
  
  def budgets(input = nil)
    return unless input.is_a? Hash

    @project_budgets = input
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
      
      # Only prompt if CLI
      if @project_budgets.length.zero?
        puts '-' * 80
        puts 'Each project below will require input on total effort in proposal.'
        @projects.each_key { |proj| puts "-> #{proj}" }

        puts "Enter nothing, 'skip' or 's' to skip output for that project."
        puts '-' * 80
      end

      @projects.each do |proj, weeks|
        if @project_budgets.key?(proj)
          next if @project_budgets[proj].zero?

          days_proposed = @project_budgets[proj]
        else
          print "Total estimated effort/days on #{proj} proposal: "
          days_proposed = gets.chomp
          next if %w[skip s].include?(days_proposed) || days_proposed.length.zero?

          days_proposed = days_proposed.gsub(/\s+/, '').split('+').sum(&:to_f)
        end

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
