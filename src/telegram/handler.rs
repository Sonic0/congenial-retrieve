use crate::telegram::inbound::{Message, MessageEntityType};
use log::info;

impl Message {
    pub fn plain_text(&self) -> Option<String> {
        let text = if self.entities.is_some() {
            return None;
        } else {
            self.text.to_owned()
        };
        info!("Telegram Update is a plain text message");
        Some(text)
    }

    // If no commands return an empty Vec
    pub fn commands(&self) -> Vec<&str> {
        let mut commands = Vec::new();
        let entities_arr = if self.entities.is_some() {
            self.entities.as_ref()
        } else {
            return commands;
        };
        // Filter entities of type bot_command
        let bot_commands = entities_arr
            .unwrap()
            .iter()
            .filter(|e| e.entity_type == MessageEntityType::BotCommand);
        // Get commands from the text key
        for cmd in bot_commands {
            let command_txt = &self.text[cmd.offset..cmd.offset + cmd.length];
            dbg!(command_txt);
            commands.push(command_txt)
        }

        commands
    }
}
