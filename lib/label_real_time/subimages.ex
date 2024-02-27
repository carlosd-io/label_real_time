defmodule LabelRealTime.Subimages do
  @moduledoc """
  The Subimages context.
  """

  import Ecto.Query, warn: false
  alias LabelRealTime.Repo

  alias LabelRealTime.Subimages.Subimage

  @doc """
  Returns the list of subimages.

  ## Examples

      iex> list_subimages()
      [%Subimage{}, ...]

  """
  def list_subimages do
    Repo.all(Subimage)
  end

  @doc """
  Gets a single subimage.

  Raises `Ecto.NoResultsError` if the Subimage does not exist.

  ## Examples

      iex> get_subimage!(123)
      %Subimage{}

      iex> get_subimage!(456)
      ** (Ecto.NoResultsError)

  """
  def get_subimage!(id), do: Repo.get!(Subimage, id)

  @doc """
  Creates a subimage.

  ## Examples

      iex> create_subimage(%{field: value})
      {:ok, %Subimage{}}

      iex> create_subimage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subimage(attrs \\ %{}) do
    %Subimage{}
    |> Subimage.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subimage.

  ## Examples

      iex> update_subimage(subimage, %{field: new_value})
      {:ok, %Subimage{}}

      iex> update_subimage(subimage, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subimage(%Subimage{} = subimage, attrs) do
    subimage
    |> Subimage.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a subimage.

  ## Examples

      iex> delete_subimage(subimage)
      {:ok, %Subimage{}}

      iex> delete_subimage(subimage)
      {:error, %Ecto.Changeset{}}

  """
  def delete_subimage(%Subimage{} = subimage) do
    Repo.delete(subimage)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking subimage changes.

  ## Examples

      iex> change_subimage(subimage)
      %Ecto.Changeset{data: %Subimage{}}

  """
  def change_subimage(%Subimage{} = subimage, attrs \\ %{}) do
    Subimage.changeset(subimage, attrs)
  end
end
