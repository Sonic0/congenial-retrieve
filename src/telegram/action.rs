use crate::telegram::{
    api,
    outbound::{ParseMode, SendMessage},
};
use anyhow::{Context, Result};

pub fn send_message(chat_id: u64, text: String, reply_to_message_id: Option<u64>) -> Result<()> {
    api::send_message(&SendMessage {
        chat_id,
        parse_mode: Some(ParseMode::Markdown),
        disable_web_page_preview: Some(true),
        text: text.clone(),
        reply_to_message_id,
    })
    .with_context(|| {
        format!(
            "Error during send message '{}' to Telegram API",
            text.clone()
        )
    })?;

    Ok(())
}
