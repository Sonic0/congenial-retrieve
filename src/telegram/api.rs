use crate::telegram::outbound::SendMessage;
use tokio;
use anyhow::Result;
use reqwest;
use reqwest::Url;
use std::env;

const BASE_URL: &str = "https://api.telegram.org/";

#[tokio::main]
pub async fn send_message(msg: &SendMessage) -> Result<()> {
    let url = format!("{}{}/sendMessage", BASE_URL, make_auth());
    let endpoint = Url::parse(&url).unwrap();

    let client = reqwest::Client::new();
    let res = client.post(endpoint).json(msg).send().await?;

    if !res.status().is_success() {
        println!(
            "[ERROR] Telegram API: HTTP {}: {:?}",
            res.status(),
            res.text().await?
        )
    }

    Ok(())
}

fn make_auth() -> String {
    let api_key = env::var_os("TELEGRAM_BOT_TOKEN").unwrap();

    format!("bot{}", api_key.to_str().unwrap())
}
