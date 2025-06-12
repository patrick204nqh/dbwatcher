Feature: Browser Testing
  As a developer
  I want to test DBWatcher in a real browser
  So I can verify the user interface works correctly

  @javascript
  Scenario: Basic browser interaction
    Given I have a Rails application with DBWatcher mounted
    When I visit the DBWatcher interface in a browser
    Then I should see the session list
    And the page should be fully loaded
