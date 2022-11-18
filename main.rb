require 'date'
require 'time'
require 'fileutils'

require_relative 'lib/pdf'
require_relative 'lib/xlsx'

BASE_OUTPUT_DIR = '/media/sf_vm-shared/reports/'

continue = true
while continue
  input = nil
  puts 'This script queries Designstor Clockify for data'
  puts "Please choose what you'd like to do."
  puts 'Output (p)df billing summarys.'
  puts 'Output (s)heet with project/task breakdowns.'
  print 'You can also e(x)it: '
  input = gets.chomp until ['p', 's', 'x'].include?(input)

  abort('Exiting...') if input == 'x'

  default_client = File.open('.defaultclient') { |file| file.readline }

  puts "The base output directory is currently set to: #{BASE_OUTPUT_DIR}"
  print 'Change output directory? (y/n) '
  change_dir = gets.chomp
  output_dir = nil

  if change_dir == 'y'
    puts 'If this directory does not exist, it will be created.'
    print 'Path to write the files: '
    output_dir = gets.chomp
  end

  path = output_dir || BASE_OUTPUT_DIR

  if input == 'p'
    file = OutputPdf.new
    puts 'The PDF, by default, retrieves tasks for the current year.'
    print 'Did you want to retrieve a different year? (y/n) '
    year_change = gets.chomp

    file.change_year if year_change == 'y'
  else
    file = OutputXlsx.new
    week_change = nil
    puts "The spreadsheet retrieves the weekly period from last Monday to last Sunday (Wk##{file.default_range_week}) by default."
    print 'Did you want to change the week being retreived? (y/n) '
    week_change = gets.chomp

    file.custom_range if week_change == 'y'
  end

  puts "#{default_client} is the default client, but we can query others."
  print 'Query different client? (y/n) '
  client_change = gets.chomp

  file.change_client if client_change == 'y'

  file.get_report
  file.output(path)

  print 'Do something else? (y/n) '
  continue = gets.chomp == 'y'
  system('clear') || system('cls') if continue
  puts 'Bye!' unless continue
end
