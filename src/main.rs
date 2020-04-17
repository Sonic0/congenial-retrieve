mod lambda_gateway;
mod telegram;

use anyhow::Result;
use futures::stream::Stream;
use lambda_runtime::{error::HandlerError, lambda, Context};
use log::{error, info, trace, warn};
use serde_derive::{Deserialize, Serialize};
use simple_error::bail;
use simple_logger;
use std::env;
use std::error::Error;
use telebot::functions::*;
use telebot::Bot;
use crate::telegram::{
    inbound::{MessageEntityType, TelegramUpdate},
};

use lambda_gateway::{LambdaRequest, LambdaResponse, LambdaResponseBuilder};
use futures::StreamExt;

/// This is the JSON payload we expect to be passed to us by the client accessing our lambda.
#[derive(Deserialize, Debug)]
struct InputPayload {
    name: String,
}

/// This is the JSON payload we will return back to the client if the request was successful.
#[derive(Serialize, Debug)]
struct OutputPayload {
    message: String,
}

fn main() -> Result<()> {
    simple_logger::init_with_level(log::Level::Debug)?;
    lambda!(lambda_handler);

    Ok(())
}

fn lambda_handler(
    event: LambdaRequest<TelegramUpdate>,
    _context: Context,
) -> Result<LambdaResponse, HandlerError> {
    let update = event.body();
    trace!("{:#?}", update);

    // Create the bot
    let token = env::var("TELEGRAM_BOT_TOKEN").expect("TELEGRAM_BOT_TOKEN not set");
    trace!("{}", token);
    // let mut bot = Bot::new(&token).update_interval(0);

    // bot.run_with(payload);

    let response = LambdaResponseBuilder::new().with_status(200).build();
    Ok(response)
}
