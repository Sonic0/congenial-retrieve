mod lambda_gateway;
mod telegram;

use crate::telegram::action::send_message;
use crate::telegram::command::GlobalCommand;
use crate::telegram::inbound::TelegramUpdate;
use anyhow::Result;
use lambda_gateway::{LambdaRequest, LambdaResponse, LambdaResponseBuilder};
use lambda_runtime::{error::HandlerError, lambda, Context};
#[allow(unused_imports)]
use log::{info, trace, warn};
use simple_logger;

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

    if update.message.plain_text().is_some() {
        send_message(update.message.chat.id, update.message.text.to_owned());
    }

    if !update.message.commands().is_empty() {
        let commands = update.message.commands();
        for cmd in commands {
            let command = GlobalCommand::new(cmd);
            let message_text = match command {
                Ok(cmd_text) => cmd_text,
                Err(err) => err.to_string(),
            };
            trace!("Message to send back -> {}", message_text);
            send_message(update.message.chat.id, message_text);
        }
    } else {
        warn!("No commands to handle");
        send_message(
            update.message.chat.id,
            "No commands to handle, I sent back your message as reply! \u{1F980}".to_owned(),
        );
    }

    let response = LambdaResponseBuilder::new().with_status(200).build();
    Ok(response)
}

#[cfg(test)]
mod tests {
    use crate::telegram::inbound::{Chat, Message, MessageEntity, MessageEntityType, User};

    #[test]
    fn is_plain_text() {
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
            text: "Plain text".to_owned(),
            entities: None,
        };
        assert_eq!(input_messagge.plain_text().is_none(), false);
        assert_eq!(input_messagge.plain_text(), Some("Plain text".to_owned()))
    }

    #[test]
    fn get_command() {
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
            entities: Some(vec![MessageEntity {
                offset: 3,
                length: 5,
                entity_type: MessageEntityType::BotCommand,
                user: None,
            }]),
        };
        assert_eq!(input_messagge.commands().is_none(), false);
    }
}
