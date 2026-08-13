mod business;

use clap::Parser;

#[derive(Parser)]
#[command(name = "qtcloud-business", version, about = "QtCloud Business CLI")]
struct Cli {
    #[command(subcommand)]
    command: Option<business::BusinessCommands>,
}

fn main() {
    let cli = Cli::parse();
    match &cli.command {
        Some(cmd) => business::dispatch(&business::BusinessArgs {
            command: cmd.clone(),
        }),
        None => {}
    }
}
