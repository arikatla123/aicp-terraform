variable "kinesis_data_stream_names" {
  type = list(string)
  default = [
    "aicp_data_stream"
  ]
}