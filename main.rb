require 'date'
require 'time'
require 'fileutils'

require_relative 'pdf'
require_relative 'xlsx'

b_exit = false
until b_exit
  input = nil
  puts 'This script queries Designstor Clockify for data'
  puts "Please choose what you'd like to do."
  puts 'Output (p)df billing summarys.'
  puts 'Output (s)heet with project/task breakdowns.'
  print 'You can also e(x)it: '
  input = gets.chomp until ['p', 's', 'x'].include?(input)

  abort('Exiting...') if input == 'x'

  default_client = File.open('.defaultclient') { |file| file.readline }

  if input == 'p'
    file = OutputPdf.new
    puts 'The PDF, by default, retrieves tasks for the current year.'
    print 'Did you want to retrieve a different year? (y/n) '
    year_change = gets.chomp

    file.change_year if year_change == 'y'
  else
    file = OutputXlsx.new
    week_change = nil
    puts "The worksheet retrieves the period from last Monday to last Sunday (Wk##{file.default_range_week})."
    print 'Did you want to change the week being retreived? (y/n) '
    week_change = gets.chomp

    file.custom_range if week_change == 'y'

    puts "#{default_client} is the default client, but we can query others."
    print 'Query different client? (y/n) '
    client_change = gets.chomp

    file.change_client if client_change == 'y'
  end

  file.get_report
  file.output

  print 'Do something else? (y/n) '
  b_exit = gets.chomp == 'n'
  system('clear') || system('cls') unless b_exit
end
