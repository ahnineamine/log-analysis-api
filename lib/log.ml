module Log = struct
  open Unix
  open Logging

  type log_level = INFO | DEBUG | WARN | ERROR

  (*
  {
  timestamp = 1674921200.0;
  level = "INFO";
  message = "User logged in successfully";
  metadata = [
    ("user_id", "1234");
    ("ip_address", "192.168.1.100");
    ("user_agent", "Mozilla/5.0");
    ("endpoint", "/api/login");
    ("status_code", "200");
  ];
}
  *)
  type log_entry = {
    level: log_level;
    timestamp: float;
    message: string;
    metadata: (string*string) list;
  }

  let log_level_from_string = function
    | "INFO" -> Some INFO
    | "DEBUG" -> Some DEBUG
    | "WARN" -> Some WARN
    | "ERROR" -> Some ERROR
    | _ -> None

  let log_level_to_string = function
    | INFO -> "INFO"
    | WARN -> "WARN"
    | ERROR -> "ERROR"
    | DEBUG -> "DEBUG"

  let readdir_opt dir =
    try Some (Unix.readdir dir)
    with End_of_file -> None

  let get_files_from_dir dir =
    let dir_handle = opendir dir in
    let rec read_files acc =
      match readdir_opt dir_handle with 
        | Some filename when filename <> "." && filename <> ".." -> read_files (filename::acc)
        | Some _ -> read_files acc
        | None -> closedir dir_handle; acc
    in read_files []
  let read_file filename =
    let ic = open_in filename in
    let len = in_channel_length ic in
    let content = really_input_string ic len in
    close_in ic;
    content

  let parse_logs_from_file filename =
    let content = read_file filename in
    let json = Yojson.Basic.from_string content in
    Yojson.Basic.Util.to_list json 

  let parse_log json = 
    try 
      let timestamp = Yojson.Basic.Util.(json |> member "timestamp" |> to_float) in
      let level_str = Yojson.Basic.Util.(json |> member "level" |> to_string) in
      let message = Yojson.Basic.Util.(json |> member "message" |> to_string) in
      let metadata = Yojson.Basic.Util.(json |> member "metadata" |> to_assoc |> List.map (fun (k, v) -> (k, to_string v))) in

      match log_level_from_string level_str with
      | Some level -> Some { timestamp; level; message; metadata }
      | None -> Logging.log_error "Invalid log level: Skipped log entry"; None  (* Invalid level: skip log entry *)
    with _ -> 
      Logging.log_error "Failed to read a line from a log file";
      None

  let read_all_logs dir = 
    let files = get_files_from_dir dir in
    files
    |> List.map(fun file -> parse_logs_from_file (Filename.concat dir file))
    |> List.flatten
    |> List.filter_map parse_log
  
  let log_entry_to_json log =
    `Assoc [
      ("timestamp", `Float log.timestamp);
      ("level", `String (match log.level with
        | INFO -> "INFO"
        | DEBUG -> "DEBUG"
        | WARN -> "WARN"
        | ERROR -> "ERROR"));
      ("message", `String log.message);
      ("metadata", `Assoc (List.map (fun (k, v) -> (k, `String v)) log.metadata))
    ]
  
  let logs_to_json logs =
    `List (List.map log_entry_to_json logs) |> Yojson.Basic.to_string

end