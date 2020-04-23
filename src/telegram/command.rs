use anyhow::{anyhow, Result};

pub enum GlobalCommand {
    Start,
    Help,
    Settings,
}

impl GlobalCommand {
    pub fn new(command: &str) -> Result<String> {
        match command {
            "/start" => Ok(GlobalCommand::Start.exec()),
            "/help" => Ok(GlobalCommand::Help.exec()),
            "/settings" => Ok(GlobalCommand::Settings.exec()),
            _ => Err(anyhow!("Command does not exist")),
        }
    }

    fn exec(&self) -> String {
        match self {
            Self::Start => Self::exec_start(),
            Self::Help => Self::exec_help(),
            Self::Settings => Self::exec_settings(),
        }
    }

    fn exec_start() -> String {
        "Welcome to Github bot!

        *Usage*
        [Github here](https://github.com)."
            .to_string()
    }

    fn exec_help() -> String {
        "This is the HELP".to_string()
    }

    fn exec_settings() -> String {
        "Settings command not implemented, yet".to_string()
    }
}
