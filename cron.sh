#!/bin/bash

# change the ruby path to your path and the path to the rate_my_agent.rb file
CRON_JOB="*/3 * 8-14 * 2 /Users/daniel/.rbenv/shims/ruby /Users/daniel/test/rate-my-agent/rate_my_agent.rb"

# Add the cron job to the crontab
(crontab -l ; echo "$CRON_JOB") | crontab -