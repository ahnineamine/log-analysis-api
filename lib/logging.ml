module Logging = struct
    let setup_log_level () = 
      Logs.set_reporter (Logs.format_reporter ());
      (*in case LOG_LEVEL was not definied*)
      let _ = Logs.set_level (Some Logs.Info) in 
      let log_level =
        match Sys.getenv_opt "LOG_LEVEL" with
          | Some "DEBUG" -> Logs.Debug
          | Some "INFO" -> Logs.Info
          | Some "WARN" -> Logs.Warning
          | Some "ERROR" -> Logs.Error
          | _ -> Logs.App
      in
      Logs.set_level (Some log_level)

    let log_info msg = Logs.info (fun m -> m "%s" msg)
    let log_debug msg = Logs.debug (fun m -> m "%s" msg)
    let log_error msg = Logs.err (fun m -> m "%s" msg)
    let log_warn msg = Logs.warn (fun m -> m "%s" msg)
end