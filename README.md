# Description

A script that goes to Rate-My-Agent.com and ensures that the website is working as expected. It will also save the logs and mail them after each run.

## Installation

make sure to install the gems `selenium-webdriver`, `mail` and `dotenv`

```bash
gem install selenium-webdriver
gem install mail
gem install dotenv
```

## Configuration

if you want to use the mail feature, you will have to create a `.env` file in the root directory and add the following variables

```bash
EMAIL_USERNAME=your_email
EMAIL_PASSWORD=your_password
EMAIL_TO=receiver_email
```

## Usage

to run the script, you can use the following command

```bash
ruby rate_my_agent.rb
```

if you want to activate the cron job, you can use the following command

```bash
bash cron.sh
```

## Test cases

- Test case 1: Visitor can browse to the home page and the elements are displayed correctly
- Test case 2: Visitor can click on the "Get Matched Now" button and visit the correct page
- Test case 3: Visitor can search for an agent, and find that agent in the search results

## Current Pitfalls With The Script

- One problem is that we're using selenium and when navigating to pages sometimes we will get a captcha page, which will make the script fail. We can solve this by using [something like this](https://2captcha.com/blog/how-to-use-2captcha-solver-extension-in-puppeteer) in the future.
- Another problem is that sometimes a **different** version of the home pagthat does not contain the search bar will be loaded, I will have to investigate this further to see why this is happening.

## My approach to this script

- I used selenium because it's a headless browser and can be used to test the website as a real user would
- I made a hash that contains the test cases and their expected results, this can be used to check if the script is working as expected and will be used in the mail
- I made a logs array that will contain the logs of the script, these logs can be mentioned in the mail and also saved to file for future reference
- Before and after each test case, I call the `log` function to log the result and push it to the logs array that can then later be mentioned in the mail, I use similar logic for the `update_test` function
- I used mail to send the logs to the user after each run
- I catch any exceptions that might occur and log them to the logs array
- I added dotenv to store the email credentials in a `.env` file for security reasons

## Future improvements

- solve the 2captcha problem
- investigate why the different version of the home page is loaded sometimes
