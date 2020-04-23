use serde::Deserialize;

#[derive(Debug, Deserialize)]
pub struct User {
    pub id: u64,
    pub is_bot: bool,
    pub first_name: String,
    pub last_name: Option<String>,
    pub username: Option<String>,
    pub language_code: Option<String>,
}

#[derive(Debug, Deserialize)]
pub struct Chat {
    pub id: u64,
    pub first_name: Option<String>,
    pub last_name: Option<String>,
    pub username: Option<String>,
    // Rename is necessary because of type is an built-in Rust param
    #[serde(rename = "type")]
    pub chat_type: String,
}

#[derive(Debug, Deserialize)]
pub struct Message {
    pub date: u64,
    pub chat: Chat,
    pub message_id: u64,
    pub from: User,
    pub text: String,
    pub entities: Option<Vec<MessageEntity>>,
}

#[derive(Debug, Deserialize)]
pub struct MessageEntity {
    #[serde(rename = "type")]
    pub entity_type: MessageEntityType,
    pub offset: usize,
    pub length: usize,
    pub user: Option<User>,
}

#[derive(Debug, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum MessageEntityType {
    Mention,
    Hashtag,
    Cashtag,
    BotCommand,
    Url,
    Email,
    PhoneNumber,
    Bold,
    Italic,
    Code,
    Pre,
    TextLink,
    TextMention,
}

#[derive(Debug, Deserialize)]
pub struct InlineQuery {
    pub id: String,
    pub from: User,
    pub query: String,
    pub offset: String,
}

#[derive(Debug, Deserialize)]
pub struct TelegramUpdate {
    pub update_id: u64,
    pub message: Message,
    pub inline_query: Option<InlineQuery>,
}
