use crate::telegram::action::send_message;
use crate::telegram::inbound::Chat;
use anyhow::{anyhow, Result};

#[derive(Debug)]
pub struct Command {
    pub action: CommandAction,
    pub command: String,
    pub description: String,
    pub is_global: bool,
    pub user: Chat,
}

#[derive(Debug, PartialEq)]
pub enum CommandAction {
    SendMessage(String),
}

impl Command {
    pub fn new() -> Self {
        Command {
            action: CommandAction::SendMessage("Message not defined".to_owned()),
            command: String::from("/start"),
            description: String::from("Description info"), // TODO
            is_global: true,
            user: Chat {
                id: 0,
                first_name: None,
                last_name: None,
                username: None,
                chat_type: String::from("bot_command"),
            },
        }
    }

    pub fn with_action(mut self, action: CommandAction) -> Self {
        self.action = action;
        self
    }

    pub fn with_command(mut self, command: &str) -> Self {
        self.command = command.to_owned();
        self
    }

    pub fn with_description(mut self, description: &str) -> Self {
        self.description = description.to_owned();
        self
    }

    pub fn check_global(mut self) -> Self {
        match self.command.as_str() {
            "/start" | "/help" | "/settings" => self.is_global = true,
            _ => self.is_global = false,
        }
        self
    }

    pub fn with_user(mut self, user: Chat) -> Self {
        self.user = user;
        self
    }

    pub fn exec(mut self) -> Result<()> {
        if self.is_global {
            let global_command = GlobalCommand::new(&self.command)?;
            let text_msg = global_command.get_message();
            self.description = global_command.get_description();
            self.action = CommandAction::SendMessage(text_msg);
        }

        match self.action {
            CommandAction::SendMessage(s) => send_message(self.user.id, s, None)?,
        };

        Ok(())
    }
}

pub enum GlobalCommand {
    Start,
    Help,
    Settings,
}

impl GlobalCommand {
    pub fn new(command: &str) -> Result<GlobalCommand> {
        match command {
            "/start" => Ok(GlobalCommand::Start),
            "/help" => Ok(GlobalCommand::Help),
            "/settings" => Ok(GlobalCommand::Settings),
            _ => Err(anyhow!("Command specified is not of type global")),
        }
    }

    fn get_message(&self) -> String {
        match self {
            Self::Start => Self::start_res(),
            Self::Help => Self::help_res(),
            Self::Settings => Self::settings_res(),
        }
    }

    fn get_description(&self) -> String {
        match self {
            Self::Start => String::from("Start command info"),
            Self::Help => String::from("Help command info"),
            Self::Settings => String::from("Settings command info"),
        }
    }

    fn start_res() -> String {
        "   *Usage*
Crittome ti permette di restare aggiornato sugli ultimi commit che vengono effettuati nei tuoi repository GitHub preferiti.
La prima cosa da fare  è inviare il comando /token per associare il tuo token GitHub.
Successivamente invia il comando /addrepo seguito dalla ulr del repository che vuoi aggiungere ai tuoi preferiti.
Il bot salverà l'hash dell'ultimo commit relativo al repository aggiunto in modo da tenerlo come riferimento.
In ultimo lancia /getupdate per verificare la presenza di aggiornamenti nei repositories.
        
    *Questions, Improvements, Changes*
Crittomane is open source and lives on [Github here](https://github.com/Sonic0/congenial-retrieve).
If you have a great idea, feature request, or bug report, feel free to [open an issue here](https://github.com/Sonic0/congenial-retrieve/issues)
        
    *Legal stuff*
- The code for this bot is licensed under the [GPL-3.0](https://github.com/Sonic0/congenial-retrieve/blob/master/LICENSE)".to_string()
    }

    fn help_res() -> String {
        "   *Help*
- /start
- /help
- /settings
- /token
- /addrepo
- /getupdate
- /rmrepo"
            .to_string()
    }

    fn settings_res() -> String {
        "Settings command not implemented, yet".to_string()
    }
}
