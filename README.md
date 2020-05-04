[![Open Source Saturday Italy](https://img.shields.io/badge/Open%20Source%20Saturday-Italy-green?style=flat-square)](https://oss-italy.github.io/)
[![Terraform](https://img.shields.io/badge/Terraform-0.12-blue?style=flat-square)](https://www.terraform.io)
[![AWS](https://img.shields.io/badge/AWS-ApiGateway&Lambda-orange?style=flat-square)](https://aws.amazon.com/)
[![Telegram](https://img.shields.io/badge/Telegram-bot-blue?style=flat-square)](https://telegram.org)

# congenial-retrieve
This project is in the **development phase** and maybe it will not see an end.


### Register your Telegram Bot 
0. Get the token for your Telegram bot from BotFather.

There are a lot of online example about how to create your bot.
[Here](https://core.telegram.org/bots) the official first (and complete) step to start.

### Export **aws_account_id** and **telegram_bot_token**
1. Export the two shell variables
```sh
> AWS_ACCOUNT_ID="<your_aws_account_id>"
> TELEGRAM_TOKEN="<your_telegram_bot_token>"
```

### Using my local laptop environment to deploy the **Terraform** for AWS.

2. Initialized terraform project
```sh
> cd terraform 
> terraform init
```
3. Make sure everything is coded properly
```sh
> terraform plan
```
4. Deploy the setup
```sh
> terraform apply -var="account_id=${AWS_ACCOUNT_ID}" -var="telegram_bot_token=${TELEGRAM_TOKEN}"
```
5. Enjoy about your Bot
```
https://t.me/<your bot name>
```
6. Clean up everything. NB: This command destroy all AWS services
```sh
> terraform destroy
```
