Feature: Session Management
  As a developer
  I want to view database sessions
  So I can track database activity

  Scenario: Viewing session list
    Given I have a Rails application with DBWatcher mounted
    And there are multiple database sessions
    When I visit the sessions index page
    Then I should see all sessions listed

  Scenario: Viewing session details
    Given I have a Rails application with DBWatcher mounted
    And there is a database session with queries
    When I click on a session
    Then I should see the session details page
