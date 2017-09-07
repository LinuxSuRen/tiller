@ruby2
Feature: Consul plugin

  Scenario: Download Consul
    When I have downloaded consul "0.6.4" to "/tmp/consul.zip"
    And I have unzipped the archive "/tmp/consul.zip"
    And I have made the file "/tmp/consul" executable"
    Then an absolute file named "/tmp/consul" should exist

  Scenario: Start consul daemon in stand-alone mode
    Given an empty consul data directory
    When I start my daemon with "/tmp/consul agent -server -bootstrap -client=0.0.0.0 -data-dir=/tmp/tiller-consul-data -advertise=127.0.0.1"
    Then a daemon called "consul" should be running

  Scenario: Populate consul with test data
    Given I have populated consul with test data
    Then the consul key "tiller/globals/all/consul_global" should exist

  Scenario: Test consul with curl
    When I successfully run `curl -D - http://127.0.0.1:8500/v1/kv/tiller/globals/all/consul_global`
    Then the output should contain "HTTP/1.1 200 OK"

  Scenario: Test dev environment template generation with Consul
    Given I use a fixture named "consul"
    When I successfully run `tiller -b . -v -n`
    Then a file named "template1.txt" should exist
    And the file "template1.txt" should contain:
    """
    This is template1.
    This is a value from Consul : development value from consul for template1.erb
    This is a global value from Consul : consul global value
    This is a per-environment global : This is over-written for template1 in development
    If we have enabled node and service registration, these follow.
    """
    And the file "template1.txt" should contain "Nodes : {"
    And the file "template1.txt" should contain "ServicePort=8300"
    And a file named "template2.txt" should exist
    And the file "template2.txt" should contain:
    """
    This is template2.
    This is a value from Consul : development value from consul for template2.erb
    This is a global value from Consul : consul global value
    This is a per-environment global : per-env global for development enviroment
    """

  Scenario: Test prod environment template generation with Consul
    Given I use a fixture named "consul"
    When I successfully run `tiller -b . -v -n -e production`
    Then a file named "template1.txt" should exist
    And the file "template1.txt" should contain:
    """
    This is template1.
    This is a value from Consul : production value from consul for template1.erb
    This is a global value from Consul : consul global value
    This is a per-environment global : per-env global for production enviroment
    If we have enabled node and service registration, these follow.
    """
    And the file "template1.txt" should contain "Nodes : {"
    And the file "template1.txt" should contain "ServicePort=8300"

  Scenario: Test environment without Consul block
    Given a file named "common.yaml" with:
    """
    ---
    exec: ["true"]
    data_sources: [ "consul" , "file" ]
    template_sources: [ "consul" , "file" ]

    environments:
      development:
        test.erb:
          target: test.txt
          config:
            test_var: "This is a template var from the development env"
    """
    And a directory named "templates"
    And a file named "templates/test.erb" with:
    """
    test_var: <%= test_var %>
    """
    When I successfully run `tiller -b . -v -n -e development`
    Then a file named "test.txt" should exist
    And the file "test.txt" should contain:
    """
    test_var: This is a template var from the development env
    """
    And the output should contain "No Consul configuration block for this environment"