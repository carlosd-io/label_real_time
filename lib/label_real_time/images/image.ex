defmodule LabelRealTime.Images.Image do
  use Ecto.Schema
  import Ecto.Changeset

  schema "images" do
    field :name, :string
    field :image_locations, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(image, attrs) do
    image
    |> cast(attrs, [:name, :image_locations])
    |> validate_required([:name, :image_locations])
  end
end
