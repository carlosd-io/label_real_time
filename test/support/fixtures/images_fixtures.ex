defmodule LabelRealTime.ImagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LabelRealTime.Images` context.
  """

  @doc """
  Generate a image.
  """
  def image_fixture(attrs \\ %{}) do
    {:ok, image} =
      attrs
      |> Enum.into(%{
        image_locations: ["option1", "option2"],
        name: "some name"
      })
      |> LabelRealTime.Images.create_image()

    image
  end
end
