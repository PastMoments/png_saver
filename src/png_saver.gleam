import gleam/int
import gleam/iterator
import png

pub fn main() {
  let image_width = 200
  let image_height = 200
  let colours =
    {
      let width_range = iterator.range(from: 0, to: image_width - 1)
      let height_range = iterator.range(from: 0, to: image_height - 1)
      use y <- iterator.flat_map(height_range)
      use x <- iterator.map(width_range)
      #(
        int.to_float(x) /. int.to_float(image_width),
        int.to_float(y) /. int.to_float(image_height),
        1.0,
      )
    }
    |> iterator.to_list

  colours
  |> png.save_png(#(image_width, image_height), "./test_image.png")
}
