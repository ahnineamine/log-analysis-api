module Schema = struct

  type log_schema = {
    field_name: string;
    description: string;
    data_type: string;
    possible_values: string list option
  }

  let log_schema_to_json =
    let current_log_schema = [
        {field_name = "level"; description = "Severity level of the log"; data_type = "string"; possible_values = Some ["INFO"; "DEBUG"; "WARN"; "ERROR"]};
        { field_name = "timestamp"; description = "Log entry timestamp (UNIX epoch)"; data_type = "float"; possible_values = None };
        { field_name = "message"; description = "Log message"; data_type = "string"; possible_values = None };
        { field_name = "metadata"; description = "Additional log attributes"; data_type = "object"; possible_values = None };
      ] in
    `List(List.map (fun attribute ->  `Assoc[
      ("field_name", `String attribute.field_name);
      ("description", `String attribute.description);
      ("data_type", `String attribute.data_type);
      ("possible_values", 
        match attribute.possible_values with
          | None -> `Null
          | Some v -> `List(List.map(fun x -> `String x) v)
        )
    ]) current_log_schema)

end