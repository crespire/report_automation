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

continue = true
while continue
  puts 'This script queries Designstor Clockify for data'
  puts 'You can:'
  puts '> Output (p)df billing summarys.'
  puts '> Output (s)heet with project/task breakdowns.'
  puts '> E(x)it the program.'

  input = nil
  until %w[p s x].include?(input)
    print 'What would you like to do? '
    input = gets.chomp.downcase
  end

  abort('Exiting...') if input == 'x'

  puts "The base output directory is currently set to: #{CONFIG['output']}"
  print 'Change output directory? (y/n) '
  change_dir = gets.chomp

  if change_dir == 'y'
    puts 'If this directory does not exist, it will be created.'
    print 'Path to write the files: '
    output_dir = gets.chomp
  end

  path = output_dir || CONFIG['output']

  if input == 'p'
    file = OutputPdf.new(CLOCKIFY_API)
    puts 'The PDF, by default, retrieves tasks for the current year.'
    print 'Did you want to retrieve a different year? (y/n) '
    year_change = gets.chomp

    file.change_year if year_change == 'y'
  else
    file = OutputXlsx.new(CLOCKIFY_API)
    puts "The spreadsheet retrieves the weekly period from last Monday to last Sunday (Wk##{file.default_range_week}) by default."
    print 'Did you want to change the week being retreived? (y/n) '
    week_change = gets.chomp

    file.custom_range if week_change == 'y'
  end

  if CLOCKIFY_API.active_client
    puts "The current client is #{CLOCKIFY_API.active_client}."
    print 'Did you want to change clients? (y/n) '
    client_change = gets.chomp
    file.set_client if client_change == 'y'
  else
    file.set_client
  end

  file.get_report
  file.output(path)

  print 'Do something else? (y/n) '
  continue = gets.chomp == 'y'
  system('clear') || system('cls') if continue
  puts 'Bye!' unless continue
end
