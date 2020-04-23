use crate::telegram::inbound::{Message, MessageEntityType};

impl Message {
    pub fn plain_text(&self) -> String {
        match self.entities.is_some() {
            false => self.text.clone(),
            true => "".to_owned(),
        }
    }

    // If no commands return an empty Vec
    pub fn commands(&self) -> Option<Vec<&str>> {
        let mut commands = Vec::new();
        let entities_arr = &self.entities.as_ref()?;
        // Filter entities of type bot_command
        let bot_commands = entities_arr
            .iter()
            .filter(|e| e.entity_type == MessageEntityType::BotCommand);
        // Get commands from the text key
        for cmd in bot_commands {
            let command_txt = &self.text[cmd.offset..cmd.offset + cmd.length];
            dbg!(command_txt);
            commands.push(command_txt)
        }

        Some(commands)
    }
}
