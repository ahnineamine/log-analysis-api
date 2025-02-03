module Api = struct
  open Schema
  open Log
  open Command
  open Logging

  let health_check _request =
    Dream.json ~status:`OK {|"status": "OK"|}

  let expected_schema _request =
    let response = Yojson.Basic.to_string Schema.log_schema_to_json in
    Dream.json ~status:`OK ~headers:["Content-Type", "application/json"] response

  let process_log request =
    let%lwt body = Dream.body request in
    Lwt.catch
      (fun () ->
        let json = Yojson.Basic.from_string body in
        match Command.command_type_of_json json with
        | Some command_request ->
            Lwt.catch
              (fun () ->
                let logs = Log.read_all_logs "data" in
                Logging.log_info "logs fetched";
                Logging.log_info (Printf.sprintf "log size: %s" (List.length logs |> string_of_int));
                let processed_logs = Command.apply_command command_request logs in
                Logging.log_info "logs processed";
                let json_response = Log.logs_to_json processed_logs in
                Dream.respond ~status:`OK ~headers:["Content-Type", "application/json"] json_response)
              (fun exn ->
                Dream.respond ~status:`Internal_Server_Error
                  (Printf.sprintf "Unable to fetch logs: %s" (Printexc.to_string exn)))
        | None ->
            Dream.respond ~status:`Bad_Request "Invalid command format")
      (fun exn ->
        Dream.respond ~status:`Bad_Request
          (Printf.sprintf "Invalid JSON: %s" (Printexc.to_string exn)))
    

  let start_server () =
    Dream.run ~interface:"0.0.0.0" ~port:8080
    @@ Dream.logger
    @@ Dream.router [
      (* POST /health: Health Chec k*)
      Dream.get "/health" health_check;
      (* GET /schema: Returns the structure of the expected log data (timestamp, level, message, etc.). *)
      Dream.get "/schema" expected_schema;
      (* POST /process: Parse and Query log files *)
      Dream.post "/process" process_log;
    ]
end