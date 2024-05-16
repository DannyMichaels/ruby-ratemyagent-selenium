require 'selenium-webdriver'
require 'mail';
require 'dotenv/load'

def log(message, logs)
  timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  puts "#{timestamp}: #{message}"
  logs.push("#{timestamp}: #{message}")
end

def update_test(tests, test, result, reason = 'N/A')
  tests[test] = {
    passed: result,
    reason: reason
  }
end

def find_cloudflare(driver, logs, callback)
  cloudflare = "www.rate-my-agent.com needs to review the security of your connection before proceeding."
    
  if driver.page_source.include? cloudflare
    message = "Cannot access the Agent Matching Quiz page: Cloudflare anti-bot protection is blocking access with a 'Are you human?' captcha"
    log(message, logs)
    callback.call(message)
  end
end

def run(driver, logs, tests)
  begin 
  log("Visiting the Rate My Agent homepage", logs)
  driver.get('https://rate-my-agent.com/')
  update_test(tests, "Home Page Visited", true)

  # visitor can read the copy
  log("Reading the homepage headline", logs)
  home_headline = driver.find_element(class: 'home-headline')
  log("Home headline: #{home_headline.text}", logs)
  update_test(tests, "Home Page Headline Read", true)

  # visitor can click on the get matched button
  log("Finding the 'Get Matched' button", logs)
  get_matched_btn = driver.find_element(class: 'btn-home-getmatched')
  log("Get Matched button text: #{get_matched_btn.text}", logs)
  update_test(tests, "Get Matched Button Visible", get_matched_btn.displayed?)

  # click the get matched button
  log("Clicking the 'Get Matched' button", logs)
  get_matched_btn.click 
  

  agent_matching_quiz_passed = true
  agent_matching_quiz_failed_message = "N/A"

  # check that clicking the get matched button navigates to the correct page
  begin 
    wait = Selenium::WebDriver::Wait.new(timeout: 3)
    log("Navigating to the Agent Matching Quiz page", logs)
    wait.until { driver.title.downcase.start_with? "agent matching quiz" }
  rescue StandardError => e
    message = "Navigation error: expected page title 'Agent Matching Quiz' not found"
    log(message, logs)
    agent_matching_quiz_failed_message = message
    agent_matching_quiz_passed = false
  end 

  #  check that the expected element is present on the page
  begin
    log("Checking for the presence of the 'Are you buying or selling?' element", logs)
    expected_element = driver.find_element(:xpath, "//*[contains(text(), 'Are you buying or selling?')]")
  rescue Selenium::WebDriver::Error::NoSuchElementError
    message = "Content mismatch in the Agent Matching Quiz page: expected element ('Are you buying or selling?') not found"
    log(message, logs)
    find_cloudflare(driver, logs, -> { agent_matching_quiz_passed = false, agent_matching_quiz_failed_message = "Cannot access the Agent Matching Quiz page: Cloudflare anti-bot protection is blocking access with a 'Are you human?' captcha" })
  end
  

  update_test(tests, "Get Matched Button Navigates To Quiz", agent_matching_quiz_passed, agent_matching_quiz_failed_message)

  log("Going back to the homepage", logs)
  driver.navigate.to 'https://rate-my-agent.com/'

  search_input = nil;
  
  # visitor can search for an agent
  begin 
    log("Finding the search input field", logs)
    search_input = driver.find_element(id: 'term')
    
  rescue Selenium::WebDriver::Error::NoSuchElementError => e
    log("Error: Search input field not found", logs)
    log("We might've gotten a different version of the homepage")
    update_test(tests, "Searched for Agent", false, "Search input field not found")
    search_input = nil
  end 

  if !search_input.nil? # if the search input field was found
    log("Typing 'Gianna Schiralli' into the search input field", logs)
    search_input.send_keys('Gianna Schiralli')
    
    log("Finding the search submit button", logs)
    search_submit = driver.find_element(class: 'btn-search')
    log("Clicking the search submit button", logs)
    search_submit.click
    update_test(tests, "Searched for Agent", true)

    begin 
      wait = Selenium::WebDriver::Wait.new(timeout: 3)
      log("Waiting for the search results page to load", logs)
      wait.until { driver.title.downcase.start_with? "gianna schiralli" }

    rescue StandardError => e
      message = "Navigation error: expected page title 'Gianna Schiralli' not found"
      log(message, logs)
      find_cloudflare(driver, logs, -> { update_test(tests, "Search for Agent Results Contains Searched Agent", false, message) })
    end 

    begin
      log("Checking for the presence of the 'Gianna Schiralli' element in the search results", logs)
      expected_element = driver.find_element(:xpath, "//*[contains(text(), 'Gianna Schiralli')]")
      update_test(tests, "Search for Agent Results Contains Searched Agent", true)
    rescue Selenium::WebDriver::Error::NoSuchElementError
      message = "Content mismatch in the search results page: expected element ('Gianna Schiralli') not found"
      log(message, logs)
      update_test(tests, "Search for Agent Results Contains Searched Agent", false, message)
    end
  end 

  rescue StandardError => e
    puts "Error: #{e.message}"
  ensure 
    driver.quit
  end
end


begin
  options = Selenium::WebDriver::Chrome::Options.new
  # Set the user agent
  options.add_argument('--user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36')

  # Set the window size
  options.add_argument('--window-size=1818,1055')

  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  driver = Selenium::WebDriver.for :chrome, options: options

  tests = {
    "Home Page Visited" => {
      passed: false,
      reason: "The homepage was not visited"
    },
    "Home Page Headline Read" => {
      passed: false,
      reason: "The homepage headline was not read"
    },
    "Get Matched Button Visible" => {
      passed: false,
      reason: "The 'Get Matched' button was not visible"
    },
    "Get Matched Button Navigates To Quiz" => {
      passed: false,
      reason: "The 'Get Matched' button did not navigate to the Agent Matching Quiz page"
    },
    "Quiz Page Contains Expected Element" => {
      passed: false,
      reason: "Quiz page was not visited"
    },
    "Searched for Agent" => {
      passed: false,
      reason: "The search for an agent was not performed"
    },
    "Search for Agent Results Contains Searched Agent" => {
      passed: false,
      reason: "The search for an agent page was not visited"
    },
  }

  logs = []
  run(driver, logs, tests)

  logs.each { |log_entry| puts log_entry }
  puts "\n\n"
  puts "Test Results:"
  tests.each { |test, result| puts "#{test}: #{result[:passed] ? 'Passed' : 'Failed'}" }

  # write to log file (optional)
  # log_file_name = "#{Time.now.strftime('%Y-%m-%d_%H-%M-%S')}_rate_my_agent.txt"
  # log_file = File.open(log_file_name, 'w')
  # logs.each { |log_entry| log_file.puts(log_entry) }

  # mail the results
  if ENV['EMAIL_TO'] and ENV['EMAIL_USERNAME'] and ENV['EMAIL_PASSWORD']
    mail = Mail.new do
      delivery_method :smtp, address: 'smtp.gmail.com', port: 587, user_name: ENV['EMAIL_USERNAME'], password: ENV['EMAIL_PASSWORD'], authentication: 'plain', enable_starttls_auto: true
      from  ENV['EMAIL_USERNAME']
      to ENV['EMAIL_TO']
      subject 'Rate My Agent Test Results'
      content_type 'text/html; charset=UTF-8'
      body """
      <div>
        <h1> Rate My Agent Test Results </h1>

        <p> hello there, </p>
        <p> Here are the results of the Rate My Agent test: </p>

        <ul>
          #{tests.map { |test, result| "<li>#{test}: #{result[:passed] ? 'Passed' : 'Failed: ' + result[:reason]}</li>" }.join("\n")}
        </ul>

        <h2>Logs:</h2>

        <pre>
        #{logs.map { |log_entry | log_entry}.join("\n")}
        </pre>
      </div>
    """    
    end 
    
    mail.deliver!
  end
end