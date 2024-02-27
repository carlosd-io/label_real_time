defmodule LabelRealTime.SubimagesTest do
  use LabelRealTime.DataCase

  alias LabelRealTime.Subimages

  describe "subimages" do
    alias LabelRealTime.Subimages.Subimage

    import LabelRealTime.SubimagesFixtures

    @invalid_attrs %{label: nil, subimage_location: nil, is_labelled: nil}

    test "list_subimages/0 returns all subimages" do
      subimage = subimage_fixture()
      assert Subimages.list_subimages() == [subimage]
    end

    test "get_subimage!/1 returns the subimage with given id" do
      subimage = subimage_fixture()
      assert Subimages.get_subimage!(subimage.id) == subimage
    end

    test "create_subimage/1 with valid data creates a subimage" do
      valid_attrs = %{label: "some label", subimage_location: "some subimage_location", is_labelled: true}

      assert {:ok, %Subimage{} = subimage} = Subimages.create_subimage(valid_attrs)
      assert subimage.label == "some label"
      assert subimage.subimage_location == "some subimage_location"
      assert subimage.is_labelled == true
    end

    test "create_subimage/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Subimages.create_subimage(@invalid_attrs)
    end

    test "update_subimage/2 with valid data updates the subimage" do
      subimage = subimage_fixture()
      update_attrs = %{label: "some updated label", subimage_location: "some updated subimage_location", is_labelled: false}

      assert {:ok, %Subimage{} = subimage} = Subimages.update_subimage(subimage, update_attrs)
      assert subimage.label == "some updated label"
      assert subimage.subimage_location == "some updated subimage_location"
      assert subimage.is_labelled == false
    end

    test "update_subimage/2 with invalid data returns error changeset" do
      subimage = subimage_fixture()
      assert {:error, %Ecto.Changeset{}} = Subimages.update_subimage(subimage, @invalid_attrs)
      assert subimage == Subimages.get_subimage!(subimage.id)
    end

    test "delete_subimage/1 deletes the subimage" do
      subimage = subimage_fixture()
      assert {:ok, %Subimage{}} = Subimages.delete_subimage(subimage)
      assert_raise Ecto.NoResultsError, fn -> Subimages.get_subimage!(subimage.id) end
    end

    test "change_subimage/1 returns a subimage changeset" do
      subimage = subimage_fixture()
      assert %Ecto.Changeset{} = Subimages.change_subimage(subimage)
    end
  end
end
