# Credit Card Service

This service validates credit numbers using the luhn algorithm. Api can be accessed at http://credit-card-api-service.herokuapp.com.

## Note! Please do before use
  1. Run ```bundle install```
  2. Run ```rake db:migrate```
  3. Create ```config_env.rb``` file in the ```config``` directory. Follow the instructions in ```config_env.rb.example``` file  

## Usage


  * ### GET Paths
    - GET /

      Root route
    - GET /api/v1/credit_card/validate

      The link below is an example of an invalid card number.

      http://credit-card-api-service.herokuapp.com/api/v1/credit_card/validate?card_number=4024097178888052

      The card_number value can be changed to whatever number you would like to validate. The service will return a JSON string containing the number you entered and the card's validation status. e.g.
       ```
       {"card":"4024097178888052","validated":false}
       ```
      If the number you enter is valid then validated will be equal to true.Below is a valid card number that you can try.
      ```
        card_number=4916603231464963
      ```
    - GET /api/v1/get

      Return all credit card data from database in as a JSON string. Simply type the link below in the browser after running local web server using the ```rackup``` command in terminal. This function is not currently available on our online API validation service.
      ```
      http://127.0.0.1:9292/api/v1/get
      ```


  * ### Post paths  

    The Post path allows you to post or save valid credit card numbers to your database. Numbers that do not pass the validation will not be saved to database. Post paths are not currently on the online API and can only be use locally. Before using the post route remember to run the ```rake db:migrate``` command.

    - POST /api/v1/credit_card

      The curl tool is used to test the above POST route. Below is a valid example of how you can insert data into your local database.
      ```
      curl -X POST -d "{\"number\":\"5192234226081802\",\"expiration_date\":\"2017-04-19\",\"owner\":\"Cheng-Yu Hsu\",\"credit_network\":\"Visa\"}" http://127.0.0.1:9292/api/v1/credit_card
      ```

		Curl can also be used to post to the online database of our service. Below is the format.
      ```
      curl -H 'accept: application/json' -H 'content-type: application/json' http://credit-card-api-service.herokuapp.com/api/v1/credit_card -d "{\"number\":\"5192234226081802\",\"expiration_date\":\"2017-04-19\",\"owner\":\"Cheng-Yu Hsu\",\"credit_network\":\"Visa\"}"
      ```
