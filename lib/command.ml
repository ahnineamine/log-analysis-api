module Command = struct
  open Log.Log

  type aggregate_op =
    | CountBy of string   (* e.g., CountBy "level" *)
    | AverageOf of string   (* e.g., Average "duration" *)
    | SumOf of string       (* e.g., Sum "size" *)
    | MaxOf of string       (* e.g., Max "response_time" *)
    | MinOf of string       (* e.g., Min "cpu_usage" *)

  type transform_format =
  | ToJSON of (log_entry list -> string)
  | ToCSV of (log_entry list -> string)

  type filter_criteria = ByLevel of log_level | ByMessage of string

  (* ex: Filter "ERROR" | Aggregate ("level", "count") |  Transform "csv" *)
  type command_type =  Filter of filter_criteria | Aggregate of aggregate_op | Transform of transform_format

  let contains_substring str sub =
    let str_len = String.length str in
    let sub_len = String.length sub in
    
    if sub_len = 0 then true
    else if sub_len > str_len then false
    else
      let rec check_at pos =
        if pos > str_len - sub_len then false
        else 
          try
            String.contains_from str pos sub.[0] &&
            (String.sub str pos sub_len = sub || check_at (pos + 1))
          with _ -> false
      in
      check_at 0

  (** [get_field_value log field] attempts to find [field] in [log.metadata].
    Returns [Some v] if found, or [None] if it doesn't exist. *)
  let get_field_value (log : log_entry) (field : string) : string option =
    List.assoc_opt field log.metadata

  (** [get_float_value log field] converts the metadata field to a float if possible. *)
  let get_float_value (log : log_entry) (field : string) : float option =
    match get_field_value log field with
    | Some s ->
      (try Some (float_of_string s) with _ -> None)
    | None -> None

    let aggregate_logs (logs : log_entry list) (op : aggregate_op) : log_entry list =
      match op with
      | CountBy field ->
          (* Count distinct values of [field]. *)
          let values =
            logs
            |> List.filter_map (fun log -> get_field_value log field)
            |> List.sort_uniq String.compare
          in
          let count = List.length values in
          [{
            timestamp = Unix.time ();
            level = INFO;
            message = Printf.sprintf "Count of distinct '%s': %d" field count;
            metadata = []
          }]
    
      | AverageOf field ->
          (* Compute average of numeric field. *)
          let nums =
            logs
            |> List.filter_map (fun log -> get_float_value log field)
          in
          let sum = List.fold_left ( +. ) 0.0 nums in
          let avg =
            if nums = [] then 0.0
            else sum /. float_of_int (List.length nums)
          in
          [{
            timestamp = Unix.time ();
            level = INFO;
            message = Printf.sprintf "Average of '%s': %.2f" field avg;
            metadata = []
          }]
    
      | SumOf field ->
          (* Sum numeric field. *)
          let nums =
            logs
            |> List.filter_map (fun log -> get_float_value log field)
          in
          let total = List.fold_left ( +. ) 0.0 nums in
          [{
            timestamp = Unix.time ();
            level = INFO;
            message = Printf.sprintf "Sum of '%s': %.2f" field total;
            metadata = []
          }]
    
      | MaxOf field ->
          (* Find max numeric value in a field. *)
          let nums =
            logs
            |> List.filter_map (fun log -> get_float_value log field)
          in
          let max_val = try List.fold_left max (List.hd nums) (List.tl nums)
                        with _ -> 0.0
          in
          [{
            timestamp = Unix.time ();
            level = INFO;
            message = Printf.sprintf "Max of '%s': %.2f" field max_val;
            metadata = []
          }]
    
      | MinOf field ->
          (* Find min numeric value in a field. *)
          let nums =
            logs
            |> List.filter_map (fun log -> get_float_value log field)
          in
          let min_val = try List.fold_left min (List.hd nums) (List.tl nums)
                        with _ -> 0.0
          in
          [{
            timestamp = Unix.time ();
            level = INFO;
            message = Printf.sprintf "Min of '%s': %.2f" field min_val;
            metadata = []
          }]

  let logs_to_json_string (logs : log_entry list) : string =
    `List (List.map log_entry_to_json logs)
    |> Yojson.Basic.to_string
  
  let logs_to_csv_string (logs : log_entry list) : string =
    let header = "timestamp,level,message,metadata" in
    let row log =
      let ts = string_of_float log.timestamp in
      let level_str = log_level_to_string log.level in
      let msg = log.message in
      (* Convert metadata from (key * value) list to a single string, e.g., "k1=v1; k2=v2" *)
      let meta = String.concat "; " (List.map (fun (k, v) -> k ^ "=" ^ v) log.metadata) in
      Printf.sprintf "%s,%s,%s,%s" ts level_str msg meta
    in
    let rows = List.map row logs in
    String.concat "\n" (header :: rows)
          
  let apply_transform (tf : transform_format) (logs : log_entry list) : log_entry list =
    match tf with
    | ToJSON _ ->
        let json_str = logs_to_json_string logs in
        [{
            timestamp = Unix.time ();
            level = INFO;
            message = "Transformed logs to JSON.";
            metadata = [("data", json_str)];
        }]
    | ToCSV _ ->
        let csv_str = logs_to_csv_string logs in
        [{
            timestamp = Unix.time ();
            level = INFO;
            message = "Transformed logs to CSV.";
            metadata = [("data", csv_str)];
        }]
          
  let apply_command (cmd: command_type) (logs: log_entry list) = 
    match cmd with
      | Filter (ByLevel lvl) -> List.filter(fun log -> log.level = lvl) logs
      | Filter (ByMessage sub_str) -> List.filter(fun log ->  contains_substring log.message sub_str ) logs
      | Aggregate operation  -> aggregate_logs logs operation
      | Transform tf_format -> apply_transform tf_format logs

  let aggregate_op_of_json json =
    match Yojson.Basic.Util.(json |> member "operation" |> to_string, json |> member "field" |> to_string_option) with
    | "CountBy", Some field -> Some (CountBy field)
    | "AverageOf", Some field -> Some (AverageOf field)
    | "SumOf", Some field -> Some (SumOf field)
    | "MaxOf", Some field -> Some (MaxOf field)
    | "MinOf", Some field -> Some (MinOf field)
    | _ -> None
  
  let filter_criteria_of_json json =
    match Yojson.Basic.Util.member "level" json |> Yojson.Basic.Util.to_string_option with
    | Some level_str ->
        (match log_level_from_string level_str with
        | Some lvl -> Some (ByLevel lvl)
        | None -> None)
    | None ->
        (match Yojson.Basic.Util.member "message_contains" json |> Yojson.Basic.Util.to_string_option with
        | Some substring -> Some (ByMessage substring)
        | None -> None)
  
  let transform_format_of_json json =
    match Yojson.Basic.Util.(json |> member "format" |> to_string_option) with
    | Some "JSON" -> Some (ToJSON (fun _ -> ""))
    | Some "CSV" -> Some (ToCSV (fun _ -> ""))
    | _ -> None
  
  let command_type_of_json json =
    match Yojson.Basic.Util.(json |> member "type" |> to_string_option) with
    | Some "Filter" ->
        (match filter_criteria_of_json (Yojson.Basic.Util.member "criteria" json) with
        | Some criteria -> Some (Filter criteria)
        | None -> None)
    | Some "Aggregate" ->
        (match aggregate_op_of_json (Yojson.Basic.Util.member "criteria" json) with
        | Some op -> Some (Aggregate op)
        | None -> None)
    | Some "Transform" ->
        (match transform_format_of_json json with
        | Some format -> Some (Transform format)
        | None -> None)
    | _ -> None
end