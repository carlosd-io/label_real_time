defmodule LabelRealTime.Subimages.Subimage do
  use Ecto.Schema
  import Ecto.Changeset

  schema "subimages" do
    field :label, :string
    field :subimage_location, :string
    field :is_labelled, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(subimage, attrs) do
    subimage
    |> cast(attrs, [:label, :subimage_location, :is_labelled])
    # |> validate_required([:label, :subimage_location, :is_labelled])
    # |> validate_required([:label, :subimage_location])
    |> validate_required([:label])
  end
end
