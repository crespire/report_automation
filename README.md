# Report Automation

This repository has classes and a script that make it easy to query for information about tasks, etc. The main.rb script takes input and outputs the appropriate files.

The OutputPdf spits out a report of annual tasks/hours. The user enters hours already invoice which is used to provide a billing summary at the bottom of the report. Due to a limitation with the free Clockify API access, reporting is only confined to a year.

The OutputXlsx class queries Clockify for a weekly detailed report and generates workbook with 1 worksheet per project for the given client. The worksheet lists of all tasks that belong to the project, aggregated by day and user.

A week runs from Monday @ midnight through to the following Sunday at 23:59:59. The API is able to query the current week, but data won't be complete for said week.

The API class has a method to call up detailed reports based on whatever client name you want, and whatever date range you want.

# Full and Half Day Calculations
Currently, full and half days are calculated as such.
For every user and day, time that:
* totals over 8 hours is recorded as a day and a half
* totals to between 4 and 8 hours (inclusive) is recorded as a day
* totals to less than 4 hours is recorded as a half day

# How to Run
In order to run this locally, clone the repository and set up the following:
* `clockify.yml`, a YAML file with a key "auth" - this should be added to the
  `.gitignore` so your API key is not exposed.
* Update `config.yml` to set the base output directory as well as default Clockify workspace.
* Run `bundle install` to install dependencies.
* Access the program by running `ruby main.rb` in the working directory root.