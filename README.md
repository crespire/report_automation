# Report Automation

This repository has classes and a script that make it easy to query for information about tasks, etc. The main.rb script takes input and outputs the appropriate files.

The OutputPdf class queries Clockify and spits out a report of unbilled hours that still require reconciliation on the billing side. The user enters hours already invoice which is used to provide a billing summary after the unbilled tasks report.

The OutputXlsx class queries Clockify for the last week's detailed report and generates workbook with 1 worksheet per project, and the list of all tasks that fall into the selection, regardless of its billed status.

A week runs from Monday @ midnight through to the following Sunday at 23:59:59. The API is able to query the current week, but data won't be complete for said week.

The API class has a method to call up detailed reports based on whatever client name you want, and whatever date range you want.

# How to Run
In order to run this locally, clone the repository and set up the following:
* `clockify.yml`, a YAML file with a key "auth" - this should be added to the
  `.gitignore` so your API key is not exposed.
* Update `config.yml` to set the base output directory as well as default Clockify workspace.