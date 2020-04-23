use crate::telegram::{
    api,
    outbound::{ParseMode, SendMessage},
};

pub fn send_message(chat_id: u64, text: String) {
    api::send_message(&SendMessage {
        chat_id,
        parse_mode: Some(ParseMode::Markdown),
        disable_web_page_preview: Some(true),
        text,
    })
    .expect("Error during send_message, retry");
}
