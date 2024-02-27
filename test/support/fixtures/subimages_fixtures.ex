defmodule LabelRealTime.SubimagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `LabelRealTime.Subimages` context.
  """

  @doc """
  Generate a subimage.
  """
  def subimage_fixture(attrs \\ %{}) do
    {:ok, subimage} =
      attrs
      |> Enum.into(%{
        is_labelled: true,
        label: "some label",
        subimage_location: "some subimage_location"
      })
      |> LabelRealTime.Subimages.create_subimage()

    subimage
  end
end
