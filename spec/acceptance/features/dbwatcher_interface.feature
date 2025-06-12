Feature: DBWatcher Engine Integration
  As a developer
  I want to access the DBWatcher interface
  So I can monitor database activity

  Scenario: Accessing DBWatcher interface
    Given I have a Rails application with DBWatcher mounted
    When I visit the DBWatcher dashboard
    Then I should see the monitoring interface
    And the page should load successfully
