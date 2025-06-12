Feature: Middleware Database Tracking
  As a developer
  I want to track database activity with the dbwatch=true parameter
  So I can monitor specific requests and their database interactions

  Background:
    Given I have a Rails application with DBWatcher mounted

  Scenario: Request without dbwatch parameter does not track
    When I make a request to "/users" without the dbwatch parameter
    Then database tracking should not be enabled
    And the request should complete successfully

  Scenario: Request with dbwatch=true tracks database activity
    When I make a request to "/users" with "dbwatch=true" parameter
    Then database tracking should be enabled
    And the request should complete successfully
    And a tracking session should be created

  Scenario: Request with dbwatch=false does not track
    When I make a request to "/users" with "dbwatch=false" parameter
    Then database tracking should not be enabled
    And the request should complete successfully

  Scenario: Request with dbwatch=true and other parameters
    When I make a request to "/users" with "dbwatch=true&page=1&sort=name" parameters
    Then database tracking should be enabled
    And the request should complete successfully
    And a tracking session should be created

  Scenario: Different HTTP methods with dbwatch=true
    When I make a "POST" request to "/users" with "dbwatch=true" parameter
    Then database tracking should be enabled
    And the request should complete successfully
    And a tracking session should be created with "POST" method

  Scenario: Middleware handles errors gracefully
    Given the tracking system will raise an error
    When I make a request to "/users" with "dbwatch=true" parameter
    Then the request should still complete successfully
    And an error warning should be logged
