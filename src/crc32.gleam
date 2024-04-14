import gleam/bytes_builder.{type BytesBuilder}

@external(erlang, "erlang", "crc32")
pub fn compute(data: BytesBuilder) -> Int
