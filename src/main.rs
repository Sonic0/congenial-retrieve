mod command;
mod lambda_gateway;
mod telegram;

use crate::telegram::{
    inbound::{Message, MessageEntityType, TelegramUpdate},
    outbound::{ParseMode, SendMessage},
};
use anyhow::Result;
use command::Command;
use lambda_runtime::{error::HandlerError, lambda, Context};
#[allow(unused_imports)]
use log::{error, info, trace, warn};
use serde_derive::Serialize;
#[allow(unused_imports)]
use simple_error::bail;
use simple_logger;

use lambda_gateway::{LambdaRequest, LambdaResponse, LambdaResponseBuilder};

// /// This is the JSON payload we expect to be passed to us by the client accessing our lambda.
// #[derive(Deserialize, Debug)]
// struct InputPayload {
//     name: String,
// }

/// This is the JSON payload we will return back to the client if the request was successful.
#[derive(Serialize, Debug)]
struct OutputPayload {
    message: String,
}

impl Message {
    fn handle(&self) {
        let bot_commands = self
            .entities
            .iter()
            .filter(|e| e.entity_type == MessageEntityType::BotCommand);
        for cmd in bot_commands {
            let command_txt = &self.text[cmd.offset..cmd.offset + cmd.length];
            dbg!(command_txt);
            let command = Command::new(&command_txt);
            let message_text = match command {
                Ok(cmd) => cmd.exec(),
                Err(e) => e.to_string(),
            };
            send_message(self.chat.id, message_text);
        }
    }
}

fn send_message(chat_id: u64, text: String) {
    telegram::api::send_message(&SendMessage {
        chat_id,
        parse_mode: Some(ParseMode::Markdown),
        disable_web_page_preview: Some(true),
        text,
    })
    .expect("Error during send_message, retry");
}

fn main() -> Result<()> {
    simple_logger::init_with_level(log::Level::Debug)?;
    lambda!(lambda_handler);

    Ok(())
}

fn lambda_handler(
    event: LambdaRequest<TelegramUpdate>,
    _context: Context,
) -> Result<LambdaResponse, HandlerError> {
    let update = event.body();
    info!("{:#?}", update);

    // Handle the "message" key value inside the input body
    update.message.handle();

    // bot.run_with(payload);

    let response = LambdaResponseBuilder::new().with_status(200).build();
    Ok(response)
}

#[cfg(test)]
mod tests {
    use crate::telegram::inbound::{Chat, Message, MessageEntity, MessageEntityType, User};

    #[test]
    fn handle_messagge() {
        let input_messagge = Message {
            message_id: 6,
            from: User { id: 23617834 },
            chat: Chat { id: 23617834 },
            date: 1586811719,
            text: "aa /help bb".to_string(),
            entities: vec![MessageEntity {
                offset: 3,
                length: 5,
                entity_type: MessageEntityType::BotCommand,
                user: None,
            }],
        };
        input_messagge.handle();
    }
}
