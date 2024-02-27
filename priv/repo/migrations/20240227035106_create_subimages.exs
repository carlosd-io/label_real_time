defmodule LabelRealTime.Repo.Migrations.CreateSubimages do
  use Ecto.Migration

  def change do
    create table(:subimages) do
      add :label, :string
      add :subimage_location, :string
      add :is_labelled, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
