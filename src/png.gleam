import gleam/float
import gleam/list
import gleam/int
import gleam/bytes_builder.{type BytesBuilder}
import glzlib
import crc32
import simplifile

// some values to try to get something working
const bit_depth = 8

// we're just doing truecolour for now
const colour_type = 2

// the same, except for indexed-colour
const sample_depth = bit_depth

// deflate, always this for pngs
const compression_method = 0

// only this is defined
const filter_method = 0

// no interlace
const interlace_method = 0

pub fn save_png(
  data: List(#(Float, Float, Float)),
  width_height: #(Int, Int),
  filename: String,
) {
  let magic_signature =
    <<0x89_504E47_0D0A1A0A:size(8)-unit(8)>>
    |> bytes_builder.from_bit_array()
  let ihdr_chunk: BytesBuilder =
    generate_ihdr_data(width_height)
    |> generate_chunk_from_data(IHDR)
  let idat_chunk: BytesBuilder =
    generate_idat_data(data, width_height)
    |> generate_chunk_from_data(IDAT)
  let iend_chunk: BytesBuilder =
    bytes_builder.new()
    |> generate_chunk_from_data(IEND)

  let png_data =
    magic_signature
    |> bytes_builder.append_builder(ihdr_chunk)
    |> bytes_builder.append_builder(idat_chunk)
    |> bytes_builder.append_builder(iend_chunk)

  let assert Ok(Nil) =
    simplifile.write_bits(
      to: filename,
      bits: bytes_builder.to_bit_array(png_data),
    )
}

fn generate_chunk_from_data(
  chunk_data: BytesBuilder,
  chunk_type: ChunkType,
) -> BytesBuilder {
  let chunk_length: BitArray = <<
    bytes_builder.byte_size(chunk_data):size(8)-unit(4),
  >>
  let chunk_type: BitArray = generate_chunk_header(chunk_type)

  let chunk_type_and_data = bytes_builder.prepend(chunk_data, chunk_type)
  let chunk_crc = <<crc32.compute(chunk_type_and_data):size(8)-unit(4)>>

  chunk_type_and_data
  |> bytes_builder.prepend(chunk_length)
  |> bytes_builder.append(chunk_crc)
}

type ChunkType {
  IHDR
  IEND
  IDAT
}

fn generate_idat_data(
  data: List(#(Float, Float, Float)),
  width_height: #(Int, Int),
) -> BytesBuilder {
  let #(width, _) = width_height
  // 4.6.1 we're going to ignore interlacing

  // 4.6.2 scanline serialization
  let truecolour_data: List(BytesBuilder) =
    data
    |> list.map(fn(rgb) {
      let assert Ok(max_val) = float.power(2.0, int.to_float(bit_depth))
      let max_val = max_val *. 0.9999999999
      let r = float.truncate(rgb.0 *. max_val)
      let g = float.truncate(rgb.1 *. max_val)
      let b = float.truncate(rgb.2 *. max_val)
      <<r:size(bit_depth), g:size(bit_depth), b:size(bit_depth)>>
    })
    |> list.sized_chunk(width)
    |> list.map(bytes_builder.concat_bit_arrays(_))

  // 4.6.3 filtering. just going to do  no filtering for now
  let filtered_data =
    truecolour_data
    // attach filter bit
    |> list.map(bytes_builder.prepend(_, <<0x00:size(8)-unit(1)>>))

  // 4.6.4 compression. zlib compression, TODO check if its right
  let compressed_data =
    filtered_data
    |> bytes_builder.concat
    |> fn(data: BytesBuilder) {
      let z_stream = glzlib.open()
      glzlib.deflate_init(
        z_stream,
        glzlib.LevelDefault,
        glzlib.MethodDeflated,
        glzlib.ZWindowBits(15),
        glzlib.ZMemLevel(8),
        glzlib.StrategyDefault,
      )
      let output = glzlib.deflate(z_stream, data, glzlib.FlushFinish)
      glzlib.deflate_end(z_stream)
      glzlib.close(z_stream)
      output
    }

  compressed_data
}

fn generate_chunk_header(chunk_type: ChunkType) {
  case chunk_type {
    IHDR -> <<0x49_48_44_52:size(8)-unit(4)>>
    IEND -> <<0x49_45_4E_44:size(8)-unit(4)>>
    IDAT -> <<0x49_44_41_54:size(8)-unit(4)>>
  }
}

fn generate_ihdr_data(width_height: #(Int, Int)) {
  let #(width, height) = width_height
  <<
    width:size(8)-unit(4),
    height:size(8)-unit(4),
    bit_depth,
    colour_type,
    compression_method,
    filter_method,
    interlace_method,
  >>
  |> bytes_builder.from_bit_array
}
