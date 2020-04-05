mod lambda_gateway;

use std::error::Error;
use lambda_runtime::{error::HandlerError, lambda, Context};
use serde_derive::{Deserialize, Serialize};
use serde_json::{Value};
use log::{info, warn, error};
use simple_logger;
use simple_error::bail;

use lambda_gateway::{LambdaRequest, LambdaResponse, LambdaResponseBuilder};

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

fn main() -> Result<(), Box<dyn Error>> {
    simple_logger::init_with_level(log::Level::Debug)?;
    lambda!(lambda_handler);

    Ok(())
}

fn lambda_handler(e: LambdaRequest<InputPayload>, _c: Context, ) -> Result<LambdaResponse, HandlerError> {
    let payload = e.body();
    info!("{:#?}", payload);
    let name = &payload.name.to_uppercase();

    let response = LambdaResponseBuilder::new()
        .with_status(200)
        .with_json(OutputPayload {
            message: format!("Hi, '{}'", name),
        })
        .build();

    Ok(response)
}
