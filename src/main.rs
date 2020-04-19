mod actions;
mod command;
mod lambda_gateway;
mod telegram;

use crate::telegram::inbound::{Message, MessageEntityType, TelegramUpdate};
use actions::send_message;
use anyhow::Result;
use command::Command;
use lambda_gateway::{LambdaRequest, LambdaResponse, LambdaResponseBuilder};
use lambda_runtime::{error::HandlerError, lambda, Context};
#[allow(unused_imports)]
use log::{error, info, trace, warn};
use simple_logger;

impl Message {
    fn handle(&self) {
        // Get each MessageEntity inside entities key only if the type is a BotCommand
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
            from: User {
                id: 12345678,
                is_bot: false,
                first_name: "Andrea".to_owned(),
                last_name: None,
                username: None,
                language_code: None,
            },
            chat: Chat {
                id: 12345678,
                first_name: None,
                last_name: None,
                username: None,
                chat_type: "private".to_owned(),
            },
            date: 1586743419,
            text: "aa /help bb".to_owned(),
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
