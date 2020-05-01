mod lambda_gateway;
mod telegram;

use crate::telegram::action::send_message;
use crate::telegram::command::CommandAction;
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
    let mut lambda_res_code = 200;
    let update = event.body();
    info!("{:#?}", update);

    if update.message.plain_text().is_some() {
        let res = send_message(
            update.message.chat.id,
            update.message.text.clone(),
            Some(update.message.message_id),
        );
        if res.is_err() {
            lambda_res_code = 500;
        }
    }

    if !update.message.get_commands().is_empty() {
        let commands = update.message.get_commands();
        for cmd in commands {
            let res = if cmd.is_global {
                cmd.with_user(update.message.chat.clone()).exec()
            } else {
                cmd.with_user(update.message.chat.clone())
                    .with_action(CommandAction::SendMessage(
                        "Command not implemented".to_owned(),
                    ))
                    .with_description("The command you had specified does not exist")
                    .exec()
            };

            match res {
                Ok(_) => info!("Bot has sended response"),
                Err(_) => lambda_res_code = 500,
            }
        }
    } else {
        warn!("No commands to handle");
        let res = send_message(
            update.message.chat.id,
            "No commands to handle, I sent back your message as reply! \u{1F980}".to_owned(),
            None,
        );
        if res.is_err() {
            lambda_res_code = 500;
        }
    }

    let response = LambdaResponseBuilder::new()
        .with_status(lambda_res_code)
        .build();
    Ok(response)
}

#[cfg(test)]
mod tests {
    use super::*;
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
        assert_eq!(input_messagge.get_commands().is_empty(), false);
    }

    #[test]
    fn command_object_parameters() {
        let bot_cmd = Command::new()
            .with_action(CommandAction::SendMessage("a miao miao".to_owned()))
            .with_command("/miao")
            .with_description("This is the cat noise")
            .is_global();
        assert_eq!(bot_cmd.command, "/miao");
        assert_eq!(bot_cmd.description, "This is the cat noise");
        assert_eq!(bot_cmd.is_global, false);
    }
}
