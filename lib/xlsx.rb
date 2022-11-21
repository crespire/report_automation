require 'caxlsx'
require 'fileutils'
require_relative 'days'

##
# This class transforms API query data into an XLSX file for output.

class OutputXlsx
  include Days

  ##
  # Initialize instance variables

  def initialize(api)
    @projects = Hash.new { |hash, key| hash[key] = [] }
    @last_start = nil
    @last_end = nil
    @client = nil
    @api = api

    default_range
  end

  ##
  # Generate date range based on last Sunday

  def default_range
    @last_end = Days.prior_weekday(Date.today, 'Sunday')
    @last_start = Days.prior_weekday(@last_end, 'Monday')
  end

  ##
  # Returns week number for current range
  def current_week
    @last_start.cweek
  end

  ##
  # Returns the year for the current range
  def current_year
    @last_start.cwyear
  end

  ##
  # Get input to generate custom week range
  def custom_range
    print 'What year? '
    year = gets.chomp.to_i
    if year > @last_start.cwyear
      puts 'Year selected is in the future, defaulting to current year.'
      year = @last_start.cwyear
      sleep(1)
    end

    new_week = 0
    print 'What week do you want to retrieve? '
    new_week = gets.chomp.to_i until new_week.between?(1, 53)
    if new_week > @last_start.cweek
      puts 'Week selected is in the future, defaulting to current week.'
      sleep(1)
      return
    end

    @last_start, @last_end = Days.get_days(new_week, year)
  end

  ##
  # Set client via API
  def set_client
    @client = @api.set_client
  end

  ##
  # Query API for data

  def get_report
    json = @api.detailed_report(@last_start, @last_end)

    abort("JSON: #{json['code']} > #{json['message']}") if json.key?('code')

    json['timeentries'].each do |entry|
      entry_start = DateTime::iso8601(entry['timeInterval']['start'])
      entry_end = DateTime::iso8601(entry['timeInterval']['end'])
      duration_seconds = entry['timeInterval']['duration']

      @projects[entry['projectName']].push(
        {
          client: entry['clientName'],
          description: entry['description'],
          task: entry['taskID'],
          user: entry['userName'],
          email: entry['userEmail'],
          billable: entry['billable'] ? 'Yes' : 'No',
          start_date: entry_start.strftime('%d/%m/%Y'),
          start_time: entry_start.strftime('%T'),
          end_date: entry_end.strftime('%d/%m/%Y'),
          end_time: entry_end.strftime('%T'),
          duration_h: Time.at(duration_seconds).utc.strftime('%H:%M:%S'),
          duration_d: (duration_seconds / (60.0 * 60.0)).round(2),
          duration_sec: duration_seconds,
          rate: '100.00',
          amount: (100.00 * (duration_seconds / (60.0 * 60.0))).round(2)
        }
      )
    end

    true
  end

  ##
  # Utilize Axlsx to generate output file.

  def output(base_dir)
    date = Date.today
    puts "Generating report for week #{@last_start.cweek}."
    output_dir = "#{base_dir}/#{@last_start.cwyear}/wk#{@last_end.cweek}/xlsx-gen-#{date.strftime("%Y%b%d")}"
    puts "Output dir: #{output_dir}"
    FileUtils.mkdir_p output_dir unless Dir.exist?(output_dir)

    Axlsx::Package.new do |file|
      @projects.each do |project, tasks_array|
        file.workbook.add_worksheet(name: project) do |sheet|
          style = sheet.styles
          money_style = style.add_style num_fmt: 4
          bold_text = style.add_style b: true

          day_start = @last_start.strftime('%B %d')
          day_end = @last_start.month == @last_end.month ? @last_end.strftime('%d') : @last_end.strftime('%B %d')
          sheet.add_row ["Week #{@last_end.cweek} (#{day_start} - #{day_end})".upcase], style: [bold_text]
          sheet.add_row(
            [
              'Project',
              'Client',
              'Description',
              'Task',
              'User',
              'Email',
              'Billable',
              'Start Date',
              'Start Time',
              'End Date',
              'End Time',
              'Duration (h)',
              'Duration (decimal)',
              'Billable Rate (CAD)',
              'Billable Amount (CAD)',
              'User',
              'Full Day',
              'Half Day'
            ],
            style: bold_text
          )

          row_ind = 3
          grouped_tasks = tasks_array.group_by { |task| task[:start_date] }
          grouped_tasks.each do |day, tasks|
            by_user = tasks.group_by { |task| task[:user] }
            by_user.each do |user, user_tasks|
              user_day_hours = 0
              user_tasks.each do |task|
                user_day_hours += task[:duration_d]
                sheet.add_row(
                  [
                    project.to_s,
                    task[:client],
                    task[:description],
                    task[:task],
                    task[:user],
                    task[:email],
                    task[:billable],
                    task[:start_date],
                    task[:start_time],
                    task[:end_date],
                    task[:end_time],
                    task[:duration_h],
                    task[:duration_d],
                    task[:rate],
                    task[:amount],
                    task[:user]
                  ]
                )
                row_ind += 1
              end

              # Summary row per user, per day
              sheet.add_row(
                [
                  nil,
                  nil,
                  "Total for #{user} (#{day})",
                  nil,
                  nil,
                  nil,
                  nil,
                  nil,
                  nil,
                  nil,
                  nil,
                  nil,
                  user_day_hours,
                  nil,
                  nil,
                  nil,
                  "=IF(M#{row_ind}>4,1,0)",
                  "=IF(OR(M#{row_ind}>8,M#{row_ind}<=4),1,0)"
                ],
                style: bold_text
              )
              row_ind += 1
            end

            # Spacer row between days
            sheet.add_row
            row_ind += 1
          end

          sheet.add_row ['TOTAL', "=SUM(Q3:Q#{row_ind - 1})", "=SUM(R3:R#{row_ind - 1})"], offset: 15, style: bold_text
          sheet.column_widths 15, 10, 35, 10, 15, 15, 5, 10, 10, 10, 10, 10, 7, 10, 10, 10, 5, 5
        end

        file.serialize("#{output_dir}/#{@client}_ending_#{@last_end.strftime('%F')}.xlsx")
      end
    end

    true
  end
end