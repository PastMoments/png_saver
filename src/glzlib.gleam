import gleam/erlang/atom.{type Atom}
import gleam/dynamic.{type Dynamic}
import gleam/bytes_builder.{type BytesBuilder}

@external(erlang, "zlib", "open")
pub fn open() -> ZStream

pub fn deflate_init(
  z_stream: ZStream,
  level: ZLevel,
  method: ZMethod,
  window_bits: ZWindowBits,
  mem_level: ZMemLevel,
  strategy: ZStrategy,
) -> void {
  do_deflate_init(
    z_stream,
    zlevel_to_dynamic(level),
    zmethod_to_atom(method),
    window_bits.num_bits,
    mem_level.level,
    zstrategy_to_atom(strategy),
  )
}

@external(erlang, "zlib", "deflateInit")
fn do_deflate_init(
  z: ZStream,
  level: Dynamic,
  method: Atom,
  window_bits: Int,
  mem_level: Int,
  strategy: Atom,
) -> void

pub fn deflate(
  z_stream: ZStream,
  data: BytesBuilder,
  flush: ZFlush,
) -> BytesBuilder {
  do_deflate(z_stream, data, zflush_to_atom(flush))
}

@external(erlang, "zlib", "deflate")
fn do_deflate(
  z_stream: ZStream,
  data: BytesBuilder,
  flush: Atom,
) -> BytesBuilder

@external(erlang, "zlib", "deflateEnd")
pub fn deflate_end(z_stream: ZStream) -> void

@external(erlang, "zlib", "close")
pub fn close(z_stream: ZStream) -> void

pub opaque type ZStream

pub type ZLevel {
  LevelNone
  LevelDefault
  LevelBestCompression
  LevelBestSpeed
  LevelNumber(level: Int)
}

fn zlevel_to_dynamic(level: ZLevel) {
  case level {
    LevelNone ->
      atom.create_from_string("none")
      |> dynamic.from
    LevelDefault ->
      atom.create_from_string("default")
      |> dynamic.from
    LevelBestCompression ->
      atom.create_from_string("best_compression")
      |> dynamic.from
    LevelBestSpeed ->
      atom.create_from_string("best_speed")
      |> dynamic.from
    LevelNumber(level) if level >= 0 && level <= 9 ->
      level
      |> dynamic.from
    _ -> panic as "unknown ZLevel found"
  }
}

pub type ZFlush {
  FlushNone
  FlushSync
  FlushFull
  FlushFinish
}

fn zflush_to_atom(flush: ZFlush) {
  case flush {
    FlushNone -> atom.create_from_string("none")
    FlushSync -> atom.create_from_string("sync")
    FlushFull -> atom.create_from_string("full")
    FlushFinish -> atom.create_from_string("finish")
  }
}

pub type ZMemLevel {
  ZMemLevel(level: Int)
}

pub type ZMethod {
  MethodDeflated
}

fn zmethod_to_atom(method: ZMethod) {
  case method {
    MethodDeflated -> atom.create_from_string("deflated")
  }
}

pub type ZStrategy {
  StrategyDefault
  StrategyFiltered
  StrategyHuffmanOnly
  StrategyRLE
}

fn zstrategy_to_atom(strategy: ZStrategy) {
  case strategy {
    StrategyDefault -> atom.create_from_string("default")
    StrategyFiltered -> atom.create_from_string("filtered")
    StrategyHuffmanOnly -> atom.create_from_string("huffman_only")
    StrategyRLE -> atom.create_from_string("rle")
  }
}

pub type ZWindowBits {
  ZWindowBits(num_bits: Int)
}
