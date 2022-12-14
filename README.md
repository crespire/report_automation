# Report Automation

Ruby 3.0.2

This repository has classes and a script that make it easy to query for information about tasks, etc. The main.rb script takes input and outputs the appropriate files.

The script first determines what report type the user would like to generate, then asks which client is being reported on.

The OutputPdf spits out a report of annual tasks/hours. The user enters the quoted effort on a project proposal. The report queries all tasks for the date range, breaks them down by week and user, and provides a summary against the quoted effort.

The OutputXlsx class queries Clockify for a weekly detailed report and generates a workbook with 1 worksheet per project for the given client. The worksheet lists of all tasks that belong to the project, aggregated by day and user.

## Time definitions
A week runs from Monday @ midnight through to the following Sunday at 23:59:59. Current week query is possible, but data won't be complete (obviously).

A year runs from Jan 1 @ midnight through to either yesterday (if current year) or December 31st if the year has changed. For rationale, consult documentation.

## Billing Standard
The current billing standard is `total hours / 7.0 = effort days`.

# How to Run
In order to run this locally, clone the repository and set up the following:
* `clockify.yml`, a YAML file with a key "auth" - this should be added to the
  `.gitignore` so your API key is not exposed.
* Update `config.yml` to set the base output directory as well as default Clockify workspace.
* Run `bundle install` to install dependencies.
* Access the program by running `ruby main.rb` in the working directory root.