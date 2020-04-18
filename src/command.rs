use anyhow::{anyhow, Result};

pub enum Command {
    Start,
    Help,
}

impl Command {
    pub fn new(command: &str) -> Result<Command> {
        match command {
            "/start" => Ok(Command::Start),
            "/help" => Ok(Command::Help),
            _ => Err(anyhow!("Command does not exist")),
        }
    }

    pub fn exec(&self) -> String {
        match self {
            Self::Start => Self::exec_start(),
            Self::Help => Self::exec_help(),
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
}
