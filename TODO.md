# TODO

- Secret Scan
  - Create and ADR for GitLeaks
  - Naming convention for customised rules (so as not to conflict with default rules)
  - Write a script to test that the secret scan works as expected
  - Understand what entropy / secret group id  means / and keywords
  - Understand the error status returned from gitleaks (INF / WRN / ERR?)
  - What are the out of the box rules / can out of the box rules be disabled / false positives
  - Which rules to bring in from the existing list in the SEQF
  - Investigate how to prevent triggering multiple executions of GH Actions e.g. on git push when PR is already created
