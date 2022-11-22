require 'glimmer-dsl-libui'
require 'glimmer/rake_task'
require 'date'
require 'time'
require 'fileutils'
require 'yaml'

require_relative 'lib/pdf'
require_relative 'lib/xlsx'
require_relative 'lib/clockify'

##
# Config variables from config.yml
# +output+ defines the base output directory for the script
# +workspace+ defines the workspace for the Clockify API
CONFIG = YAML.load_file('config.yml')

##
# Clockify API instance
CLOCKIFY_API = Clockify.new

##
# Top level GUI class
class Gui
  include Glimmer

  attr_accessor :report_type, :report_range, :report_client, :output, :project_budgets

  def initialize
    @output = CONFIG['output']
    @report_client = 'Marcon'
    @report_type = 0
    @report_range = Date.today
    @clients = CLOCKIFY_API.client_names
    @project_budgets = {}
  end

  def launch
    window {
      title 'DSReportBeaver'
      margined true

      vertical_box {
        label('Output directory') { stretchy false }
        entry {
          text <=> [self, :output, after_write: ->(text) { puts text; $stdout.flush }]
        }

        label('Report Type') { stretchy false }
        combobox {
          items 'Annual PDF', 'Weekly XLSX'
          selected 0

          on_selected do |c|
            @report_type = c.selected
            puts "New report type selection: #{@report_type}"
            $stdout.flush # for Windows
          end
        }

        label('Report period picker') { stretchy false }
        label("For PDF reports, the selected date's year will be used to generate an annual report") { stretchy false }
        label('For XSLX reports, the selected date will be the week used to generate the weekly report') { stretchy false }
        label('Dates too far in the future (after current year) will default the date to today.') { stretchy false }
        date_picker { 
          stretchy false

          on_changed do |d|
            @report_range = Date.new(d.time[:year], d.time[:mon], d.time[:mday])
            @report_range = @report_range.cwyear > Date.today.cwyear ? Date.today : @report_range
            $stdout.flush
          end
        }

        combobox {
          items @clients
          selected 'Marcon'

          on_selected do |c|
            @report_client = c.selected_item
            $stdout.flush # for Windows
          end
        }

        button('Run report') {
          on_clicked do
            if @report_type.zero?
              puts 'Generating annual PDF report...'
              file = OutputPdf.new(CLOCKIFY_API)
              file.set_client(@report_client)
              file.change_year if @report_range.cwyear != Date.today.cwyear
              file.get_report
              data = []
              file.projects.each { |project, _| data.push([project, 's']) }
              window('Project budgets', 600, 600) {
                margined true
                vertical_box {
                  label('Please fill in the project budgets below.') { stretchy false }
                  label("Enter 's' or 'skip' to skip, and no report will be generated for that project.") { stretchy false }
                  label('Once the budgets for the desired projects are filled in, simply close the window to generate the reports requested.') { stretchy false }
                  table {
                    text_column('Project') { editable false }
                    text_column('Budget') { editable true }

                    cell_rows data
                  }
                }

                on_closing do
                  data.each { |item| @project_budgets[item[0]] = item[1].to_f }
                  puts @project_budgets
                  file.budgets(@project_budgets)
                  file.output(@output)
                end
              }.show
            else
              puts 'Generating weekly report...'
              file = OutputXlsx.new(CLOCKIFY_API)
              file.set_client(@report_client)
              file.custom_range(@report_range)
              file.get_report
              file.output(@output)
            end
          end
        }
      }

      on_closing do
        puts 'Bye! Thanks for using the GUI!'
      end
    }.show
  end
end

Gui.new.launch
