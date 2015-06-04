# Credit Card Service View


This service is one which utilizes the credit-card-api-service at http//creditcard-api.herokuapp.com to store credit card information. The user interface provides to options;  user registration and a log in option. Before a user can log into the service, they must first register. After registering, a verification email will be sent to the user. The user will be redirected to the service from their email account to complete registration. The service uses SENDGRID mailing service, the pony gem, JWT tokens to send the verification email. The user's full name, address, and DOB are all encrypted and password is hashed, before storage into the database.
