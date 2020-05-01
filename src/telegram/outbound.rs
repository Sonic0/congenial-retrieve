use serde::Serialize;

#[derive(Serialize)]
pub struct SendMessage {
    pub chat_id: u64,
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parse_mode: Option<ParseMode>,
    pub disable_web_page_preview: Option<bool>,
    pub reply_to_message_id: Option<u64>,
}

#[derive(Serialize)]
#[allow(dead_code)]
pub enum ParseMode {
    Markdown,
    MarkdownV2,
    HTML,
}

#[derive(Serialize)]
pub struct AnswerInlineQuery {
    pub inline_query_id: String,
    pub results: Vec<InlineQueryResultArticle>,
}

#[derive(Serialize)]
pub struct InlineQueryResultArticle {
    #[serde(rename = "type")]
    pub query_result_type: String,
    pub id: String,
    pub title: String,
    pub input_message_content: InputTextMessageContent,
    pub url: Option<String>,
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub thumb_url: Option<String>,
    pub hide_url: Option<bool>,
}

#[derive(Serialize)]
pub struct InputTextMessageContent {
    pub message_text: String,
    pub disable_web_page_preview: bool,
}

#[derive(Serialize)]
pub struct SendPhoto {
    pub chat_id: i64,
    pub photo: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub caption: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parse_mode: Option<ParseMode>,
}

#[derive(Serialize)]
pub struct SendMediaGroup {
    pub chat_id: i64,
    pub media: Vec<InputMediaPhoto>,
}

#[derive(Serialize)]
pub struct InputMediaPhoto {
    #[serde(rename = "type")]
    pub media_type: String,
    pub media: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub caption: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub parse_mode: Option<ParseMode>,
}
