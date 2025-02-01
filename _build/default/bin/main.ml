module Main = struct
  open Log_analysis_api.Logging
  open Log_analysis_api.Api

  let () =
    Logging.setup_log_level ();
    Logging.log_info "Starting the Log Analysis API";
    Logging.log_debug "debug message";
    Api.start_server ();

end