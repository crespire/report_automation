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

system('clear') || system('cls')
puts 'Welcome to Designstor report automation.'
puts 'This script generates reports via the Clockify API.'
puts "The default directory is currently configured to: #{CONFIG['output']}"
puts 'You can change this in the config.yml file for future runs.'
puts 'For the current terminal session, this value will be saved.'
print 'Would you like to change the output directory for this session? (y/n) '
change_dir = gets.chomp

if change_dir == 'y'
  puts 'If this directory does not exist, it will be created.'
  print 'Path to write the files: '
  output_dir = gets.chomp
end

path = output_dir || CONFIG['output']

system('clear') || system('cls')

continue = true
while continue
  puts 'You can:'
  puts '> Output (p)df billing summarys (annual).'
  puts '> Output (s)heet with project/task breakdowns (weekly).'
  puts '> E(x)it the program.'

  input = nil
  until %w[p s x].include?(input)
    print 'What would you like to do? '
    input = gets.chomp.downcase
  end

  abort('Exiting...') if input == 'x'

  if input == 'p'
    file = OutputPdf.new(CLOCKIFY_API)
    puts 'The PDF, by default, retrieves tasks for the current year.'
    print 'Did you want to retrieve a different year? (y/n) '
    year_change = gets.chomp

    file.change_year if year_change == 'y'
  else
    file = OutputXlsx.new(CLOCKIFY_API)
    puts "The spreadsheet retrieves the weekly period from last Monday to last Sunday (Wk##{file.current_week} in #{file.current_year}) by default."
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

  print 'Make more reports? (y/n) '
  continue = gets.chomp == 'y'
  system('clear') || system('cls') if continue
  puts 'Bye!' unless continue
end
