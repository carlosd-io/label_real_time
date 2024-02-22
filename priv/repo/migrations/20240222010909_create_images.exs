defmodule LabelRealTime.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :name, :string
      add :image_locations, {:array, :string}

      timestamps(type: :utc_datetime)
    end
  end
end
