defmodule Philomena.ThumbnailWorker do
  alias Philomena.Images.Thumbnailer

  def perform(image_id) do
    Thumbnailer.generate_thumbnails(image_id)
  end
end
